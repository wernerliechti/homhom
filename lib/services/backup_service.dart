import 'dart:io';
import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/meal.dart';
import '../models/nutrition_goals.dart';
import '../models/goal_period.dart';
import 'database_service.dart';

class BackupService {
  static const String _backupVersion = '1.0';
  
  final DatabaseService _database = DatabaseService();

  /// Export all data (meals, goals, images) to ZIP file
  /// Returns path to created backup file
  Future<String> exportBackup() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final backupDir = Directory('${tempDir.path}/homhom_backup');
      
      // Clean old backups
      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
      }
      await backupDir.create(recursive: true);

      // Get all data
      final meals = await _database.getAllMeals();
      final goals = await _database.getCurrentGoalPeriod();
      final goalHistory = await _database.getGoalPeriods();

      // Create metadata file
      final backupMetadata = {
        'version': _backupVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'mealCount': meals.length,
        'hasGoals': goals != null,
        'goalPeriods': goalHistory.length,
      };

      final metadataFile = File('${backupDir.path}/metadata.json');
      await metadataFile.writeAsString(jsonEncode(backupMetadata));

      // Create meals JSON
      final mealsJson = {
        'meals': meals.map((meal) => meal.toMap()).toList(),
      };
      final mealsFile = File('${backupDir.path}/meals.json');
      await mealsFile.writeAsString(jsonEncode(mealsJson));

      // Create goals JSON
      final goalsJson = {
        'currentGoal': goals?.toMap(),
        'goalHistory': goalHistory.map((gp) => gp.toMap()).toList(),
      };
      final goalsFile = File('${backupDir.path}/goals.json');
      await goalsFile.writeAsString(jsonEncode(goalsJson));

      // Create images directory and copy images
      final imagesDir = Directory('${backupDir.path}/images');
      await imagesDir.create(recursive: true);

      int imageCount = 0;
      for (final meal in meals) {
        if (meal.imagePath != null && await File(meal.imagePath!).exists()) {
          try {
            final imageFile = File(meal.imagePath!);
            final fileName = '${meal.id}.jpg';
            final destinationPath = '${imagesDir.path}/$fileName';
            await imageFile.copy(destinationPath);
            imageCount++;
          } catch (e) {
            print('⚠️ Failed to copy image for meal ${meal.id}: $e');
          }
        }
      }

      print('📦 Prepared backup: $imageCount images, ${meals.length} meals, ${goalHistory.length} goal periods');

      // Create ZIP file
      final zipPath = '${(await getApplicationDocumentsDirectory()).path}/homhom_backup_${_getTimestamp()}.zip';
      final zipFile = File(zipPath);

      final encoder = ZipFileEncoder();
      encoder.zipDirectory(backupDir, filename: zipPath);
      encoder.close();

      // Clean up temp directory
      await backupDir.delete(recursive: true);

      final zipSize = await zipFile.length();
      print('✅ Backup created: $zipPath (${(zipSize / 1024 / 1024).toStringAsFixed(2)} MB)');

      return zipPath;
    } catch (e) {
      print('❌ Backup export failed: $e');
      rethrow;
    }
  }

  /// Import backup ZIP file (REPLACES all existing data)
  Future<BackupImportResult> importBackup(String zipFilePath) async {
    try {
      final zipFile = File(zipFilePath);
      if (!await zipFile.exists()) {
        throw Exception('Backup file not found: $zipFilePath');
      }

      final tempDir = await getTemporaryDirectory();
      final extractDir = Directory('${tempDir.path}/homhom_restore');
      
      // Clean old restores
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }

      // Extract ZIP
      print('📂 Extracting backup...');
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      for (final file in archive) {
        if (file.isFile) {
          final outputPath = '${extractDir.path}/${file.name}';
          await Directory(outputPath).parent.create(recursive: true);
          await File(outputPath).writeAsBytes(file.content as List<int>);
        }
      }

      // Read metadata
      final metadataFile = File('${extractDir.path}/metadata.json');
      final metadata = jsonDecode(await metadataFile.readAsString());

      print('📋 Backup info: ${metadata['mealCount']} meals, ${metadata['goalPeriods']} goal periods');

      // Read meals
      final mealsFile = File('${extractDir.path}/meals.json');
      final mealsData = jsonDecode(await mealsFile.readAsString());
      final mealMaps = List<Map<String, dynamic>>.from(mealsData['meals'] ?? []);

      // Read goals
      final goalsFile = File('${extractDir.path}/goals.json');
      final goalsData = jsonDecode(await goalsFile.readAsString());

      // Get image directory
      final imagesDir = Directory('${extractDir.path}/images');
      final imageFiles = <String, String>{}; // Map: mealId -> imagePath

      if (await imagesDir.exists()) {
        final images = imagesDir.listSync();
        for (final image in images) {
          if (image is File) {
            final fileName = image.path.split('/').last;
            final mealId = fileName.replaceAll('.jpg', '');
            imageFiles[mealId] = image.path;
          }
        }
      }

      // CLEAR existing database (replace all)
      print('🗑️  Clearing existing data...');
      await _database.clearAllData();

      // Import meals with new image paths
      print('📥 Importing meals...');
      int importedMeals = 0;
      for (final mealMap in mealMaps) {
        try {
          final mealId = mealMap['id'];
          
          // Update image path if exists in backup
          if (imageFiles.containsKey(mealId)) {
            final sourceImagePath = imageFiles[mealId]!;
            final appImagesDir = await _getAppImagesDirectory();
            final newImagePath = '${appImagesDir.path}/$mealId.jpg';
            
            // Copy image to app directory
            await File(sourceImagePath).copy(newImagePath);
            mealMap['imagePath'] = newImagePath;
          }

          final meal = Meal.fromMap(mealMap);
          await _database.addMeal(meal);
          importedMeals++;
        } catch (e) {
          print('⚠️ Failed to import meal: $e');
        }
      }

      // Import goals
      print('📥 Importing goals...');
      int importedGoals = 0;
      
      if (goalsData['currentGoal'] != null) {
        try {
          final currentGoal = GoalPeriod.fromMap(goalsData['currentGoal']);
          await _database.setCurrentGoalPeriod(currentGoal);
          importedGoals++;
        } catch (e) {
          print('⚠️ Failed to import current goal: $e');
        }
      }

      // Clean up
      await extractDir.delete(recursive: true);

      print('✅ Backup import complete!');

      return BackupImportResult(
        success: true,
        mealsImported: importedMeals,
        goalsImported: importedGoals,
        imagesImported: imageFiles.length,
        message: 'Imported $importedMeals meals, $importedGoals goals, and ${imageFiles.length} images',
      );
    } catch (e) {
      print('❌ Backup import failed: $e');
      return BackupImportResult(
        success: false,
        message: 'Import failed: $e',
      );
    }
  }

  /// Get app images directory (creates if not exists)
  Future<Directory> _getAppImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/meal_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  /// Generate timestamp for backup filename
  String _getTimestamp() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
  }
}

/// Result of backup import operation
class BackupImportResult {
  final bool success;
  final int mealsImported;
  final int goalsImported;
  final int imagesImported;
  final String message;

  BackupImportResult({
    required this.success,
    this.mealsImported = 0,
    this.goalsImported = 0,
    this.imagesImported = 0,
    required this.message,
  });
}
