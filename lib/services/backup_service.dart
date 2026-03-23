import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/backup_data.dart';
import '../models/meal.dart';
import '../models/goal_period.dart';
import 'database_service.dart';
import 'package:uuid/uuid.dart';

class BackupService {
  final DatabaseService _database = DatabaseService();
  
  static const String backupFileName = 'homhom_backup.json';
  static const String schemaVersion = '1.0';
  static const String appVersion = '1.0.0'; // Update this as needed

  /// Export meal history and goal history as a ZIP file
  Future<File> exportBackup(String fileName) async {
    try {
      // Fetch all data
      final db = await _database.database;
      final meals = await _database.getRecentMeals(limit: 10000); // Get all meals
      final goalPeriods = await _database.getGoalPeriods();

      // Create backup metadata
      final metadata = BackupMetadata(
        appVersion: appVersion,
        schemaVersion: schemaVersion,
        exportedAt: DateTime.now(),
        mealCount: meals.length,
        goalPeriodCount: goalPeriods.length,
      );

      // Create backup data
      final backupData = BackupData(
        metadata: metadata,
        meals: meals,
        goalPeriods: goalPeriods,
      );

      // Convert to JSON
      final jsonString = backupData.toJson();

      // Create archive
      final archive = Archive();
      archive.addFile(ArchiveFile(
        backupFileName,
        jsonString.length,
        jsonString.codeUnits,
      ));

      // Encode to ZIP
      final zipData = ZipEncoder().encode(archive);

      // Get Downloads directory
      final downloadsDir = await _getDownloadsDirectory();
      await downloadsDir.create(recursive: true);

      // Create file with user-specified name
      final backupFile = File('${downloadsDir.path}/$fileName.zip');
      
      // Delete existing file if it exists
      if (await backupFile.exists()) {
        await backupFile.delete();
      }

      // Write ZIP file
      await backupFile.writeAsBytes(zipData!);

      return backupFile;
    } catch (e) {
      throw Exception('Failed to export backup: $e');
    }
  }

  /// Import backup from a ZIP file and restore data
  /// If replace is true, existing data will be deleted first
  Future<BackupData> importBackup(File zipFile, {bool replace = true}) async {
    try {
      // Read ZIP file
      final zipBytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      // Extract JSON file from archive
      ArchiveFile? jsonFile;
      for (final file in archive) {
        if (file.name == backupFileName) {
          jsonFile = file;
          break;
        }
      }

      if (jsonFile == null) {
        throw Exception('Backup file not found in archive. Expected: $backupFileName');
      }

      // Decode JSON
      final jsonString = String.fromCharCodes(jsonFile.content as List<int>);
      final backupData = BackupData.fromJson(jsonString);

      // Validate backup
      _validateBackup(backupData);

      // Restore data to database
      await _restoreBackup(backupData, replace: replace);

      return backupData;
    } catch (e) {
      throw Exception('Failed to import backup: $e');
    }
  }

  /// Validate backup data integrity
  void _validateBackup(BackupData backup) {
    // Check metadata
    if (backup.metadata.mealCount < 0 || backup.metadata.goalPeriodCount < 0) {
      throw Exception('Invalid backup metadata');
    }

    // Check data consistency
    if (backup.meals.length != backup.metadata.mealCount) {
      throw Exception('Meal count mismatch in backup');
    }

    if (backup.goalPeriods.length != backup.metadata.goalPeriodCount) {
      throw Exception('Goal period count mismatch in backup');
    }

    // Validate individual meals
    for (final meal in backup.meals) {
      if (meal.id.isEmpty) {
        throw Exception('Invalid meal: missing ID');
      }
    }

    // Validate goal periods
    for (final goalPeriod in backup.goalPeriods) {
      if (goalPeriod.id.isEmpty) {
        throw Exception('Invalid goal period: missing ID');
      }
    }
  }

  /// Restore backup data to database
  Future<void> _restoreBackup(BackupData backup, {bool replace = true}) async {
    final db = await _database.database;

    try {
      await db.transaction((txn) async {
        // Clear existing data if replace is true
        if (replace) {
          await txn.delete('meals');
          await txn.delete('goal_periods');
          await txn.delete('daily_summaries');
        }

        // Insert meals
        for (final meal in backup.meals) {
          // Check if meal already exists
          final existing = await txn.query(
            'meals',
            where: 'id = ?',
            whereArgs: [meal.id],
          );

          if (existing.isEmpty) {
            await txn.insert('meals', {
              'id': meal.id,
              'timestamp': meal.timestamp.toIso8601String(),
              'type': meal.type.index,
              'imagePath': meal.imagePath,
              'foodItems': jsonEncode(meal.foodItems.map((f) => f.toMap()).toList()),
              'notes': meal.notes,
              'plateDiameter': meal.plateDiameter,
              'dishWeight': meal.dishWeight,
              'analysisMetadata': meal.analysisMetadata != null 
                  ? jsonEncode(meal.analysisMetadata) 
                  : null,
              'createdAt': meal.createdAt.toIso8601String(),
              'updatedAt': meal.updatedAt.toIso8601String(),
            });
          }
        }

        // Insert goal periods
        for (final goalPeriod in backup.goalPeriods) {
          // Check if goal period already exists
          final existing = await txn.query(
            'goal_periods',
            where: 'id = ?',
            whereArgs: [goalPeriod.id],
          );

          if (existing.isEmpty) {
            await txn.insert('goal_periods', {
              'id': goalPeriod.id,
              'startDate': goalPeriod.startDate.toIso8601String(),
              'endDate': goalPeriod.endDate?.toIso8601String(),
              'goals': jsonEncode(goalPeriod.goals.toMap()),
              'notes': goalPeriod.notes,
              'createdAt': goalPeriod.createdAt.toIso8601String(),
              'updatedAt': goalPeriod.updatedAt.toIso8601String(),
            });
          }
        }

        // Rebuild daily summaries from meals
        await _rebuildDailySummaries(txn, backup.meals);
      });
    } catch (e) {
      throw Exception('Failed to restore backup: $e');
    }
  }

  /// Rebuild daily summaries from meals
  Future<void> _rebuildDailySummaries(
    Transaction txn,
    List<Meal> meals,
  ) async {
    // Clear existing summaries
    await txn.delete('daily_summaries');

    // Group meals by date
    final Map<String, List<Meal>> mealsByDate = {};
    for (final meal in meals) {
      final dateKey = '${meal.timestamp.year}-${meal.timestamp.month.toString().padLeft(2, '0')}-${meal.timestamp.day.toString().padLeft(2, '0')}';
      mealsByDate.putIfAbsent(dateKey, () => []).add(meal);
    }

    // Create summaries for each date
    for (final dateEntry in mealsByDate.entries) {
      final mealsForDate = dateEntry.value;
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (final meal in mealsForDate) {
        final nutrition = meal.totalNutrition;
        totalCalories += nutrition.calories;
        totalProtein += nutrition.protein;
        totalCarbs += nutrition.carbs;
        totalFat += nutrition.fat;
      }

      await txn.insert('daily_summaries', {
        'date': dateEntry.key,
        'totalCalories': totalCalories,
        'totalProtein': totalProtein,
        'totalCarbs': totalCarbs,
        'totalFat': totalFat,
        'mealCount': mealsForDate.length,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Get the Downloads directory
  Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // For Android, use the Downloads directory
      final result = await _getDownloadsDirectoryAndroid();
      if (result != null) return result;
    } else if (Platform.isIOS) {
      // For iOS, use Documents directory as iOS doesn't have a public Downloads folder
      final dir = await getApplicationDocumentsDirectory();
      final backupsDir = Directory('${dir.path}/Backups');
      return backupsDir;
    }

    // Fallback to application support directory
    return await getApplicationSupportDirectory();
  }

  /// Get Android Downloads directory using path_provider
  Future<Directory?> _getDownloadsDirectoryAndroid() async {
    try {
      // Try using getExternalStorageDirectory (requires WRITE_EXTERNAL_STORAGE)
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        // Navigate up to the Downloads folder
        // External storage structure: /storage/emulated/0/Android/data/app-package/files
        // We want: /storage/emulated/0/Downloads
        final parts = externalDir.path.split('/');
        final storageRoot = '/${parts[1]}/${parts[2]}'; // /storage/emulated
        final downloadsPath = '$storageRoot/Downloads';
        return Directory(downloadsPath);
      }
    } catch (e) {
      print('Could not access Downloads via getExternalStorageDirectory: $e');
    }

    return null;
  }

  /// Generate a backup file name with timestamp
  String generateBackupFileName() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
    return 'homhom_backup_${formatter.format(now)}';
  }

  /// Pick a file from device storage (for import)
  /// Note: This would typically be called from UI using file_picker package
  /// Returns the selected ZIP file or null if cancelled
  Future<File?> pickBackupFile() async {
    // This is a placeholder - the actual implementation should use file_picker
    // Example usage in UI:
    // final FilePicker filePicker = FilePicker();
    // final PlatformFile? file = await FilePicker.platform.pickFiles(
    //   type: FileType.custom,
    //   allowedExtensions: ['zip'],
    //   allowMultiple: false,
    // );
    // if (file != null) {
    //   return File(file.files.single.path!);
    // }
    return null;
  }
}
