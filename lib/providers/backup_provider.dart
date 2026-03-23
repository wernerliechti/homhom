import 'package:flutter/foundation.dart';
import 'dart:io';
import '../services/backup_service.dart';
import '../models/backup_data.dart';

class BackupProvider with ChangeNotifier {
  final BackupService _backupService = BackupService();

  bool _isLoading = false;
  String? _errorMessage;
  BackupData? _lastBackupData;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  BackupData? get lastBackupData => _lastBackupData;

  /// Export backup and return the file path
  Future<File?> exportBackup(String fileName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final file = await _backupService.exportBackup(fileName);
      _isLoading = false;
      notifyListeners();
      return file;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Import backup from ZIP file
  Future<bool> importBackup(File zipFile, {bool replace = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final backupData = await _backupService.importBackup(zipFile, replace: replace);
      _lastBackupData = backupData;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Generate a backup file name with timestamp
  String generateBackupFileName() {
    return _backupService.generateBackupFileName();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
