import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:io';
import '../services/backup_service.dart';
import '../models/backup_data.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({Key? key}) : super(key: key);

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  bool _isLoading = false;
  String? _message;
  bool _isError = false;
  final TextEditingController _fileNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fileNameController.text = _backupService.generateBackupFileName();
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  Future<void> _handleExport() async {
    if (_fileNameController.text.isEmpty) {
      _showMessage('Please enter a file name', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
      _isError = false;
    });

    try {
      final file = await _backupService.exportBackup(_fileNameController.text);
      
      setState(() {
        _isLoading = false;
        _message = 'Backup exported successfully to: ${file.path}';
        _isError = false;
      });

      // Show success dialog
      if (mounted) {
        _showSuccessDialog('Export Successful', 'Your backup has been saved to:\n\n${file.path}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Export failed: ${e.toString()}';
        _isError = true;
      });
    }
  }

  Future<void> _handleImport() async {
    try {
      // Pick a ZIP file
      const XTypeGroup zipTypeGroup = XTypeGroup(
        label: 'ZIP files',
        extensions: <String>['zip'],
      );
      
      final XFile? file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[zipTypeGroup],
      );

      if (file == null) {
        _showMessage('No file selected', isError: true);
        return;
      }

      final zipFile = File(file.path);

      // Show confirmation dialog
      final confirmed = await _showConfirmDialog(
        'Import Backup',
        'This will replace all existing meal history and goal history with the contents of the backup file.\n\nContinue?',
      );

      if (!confirmed) return;

      setState(() {
        _isLoading = true;
        _message = null;
        _isError = false;
      });

      // Import backup
      final backupData = await _backupService.importBackup(zipFile, replace: true);

      setState(() {
        _isLoading = false;
        _message = 'Backup imported successfully!\nMeals: ${backupData.meals.length}\nGoal Periods: ${backupData.goalPeriods.length}';
        _isError = false;
      });

      if (mounted) {
        _showSuccessDialog(
          'Import Successful',
          'Imported ${backupData.meals.length} meals and ${backupData.goalPeriods.length} goal periods.',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Import failed: ${e.toString()}';
        _isError = true;
      });
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    setState(() {
      _message = message;
      _isError = isError;
    });

    if (isError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showSuccessDialog(String title, String message) async {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Export Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Export Backup',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Export your meal history and goal history as a ZIP file for backup or transfer.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _fileNameController,
                      decoration: InputDecoration(
                        labelText: 'Backup file name',
                        hintText: 'homhom_backup_2024-01-15_10-30-45',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabled: !_isLoading,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleExport,
                        icon: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor,
                                  ),
                                ),
                              )
                            : const Icon(Icons.download),
                        label: Text(
                          _isLoading ? 'Exporting...' : 'Export Backup',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Import Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Import Backup',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Restore your meal history and goal history from a previously exported ZIP file.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        border: Border.all(color: Colors.amber),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.amber),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This will replace all existing data with the contents of the backup file.',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleImport,
                        icon: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor,
                                  ),
                                ),
                              )
                            : const Icon(Icons.upload),
                        label: Text(
                          _isLoading ? 'Importing...' : 'Import from ZIP',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Message Display
            if (_message != null)
              Card(
                color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _isError ? Icons.error : Icons.check_circle,
                        color: _isError ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _isError ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Info Section
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What gets backed up?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• All meal history with food items and nutrition data\n'
                      '• All goal periods and nutrition goals\n'
                      '• Export metadata (app version, export date)\n'
                      '• Complete restoration on import',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
