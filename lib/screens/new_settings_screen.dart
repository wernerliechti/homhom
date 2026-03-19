import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_selector/file_selector.dart';
import '../providers/hom_provider.dart';
import '../theme/app_theme.dart';

import '../screens/purchase_homs_screen.dart';
import '../screens/api_config_screen.dart';
import '../services/backup_service.dart';

class NewSettingsScreen extends StatelessWidget {
  const NewSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: Consumer<HomProvider>(
        builder: (context, homProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HOM Balance Card
                _buildHomBalanceCard(homProvider),

                const SizedBox(height: 24),

                // Settings Options
                _buildSettingsOptions(context, homProvider),

                const SizedBox(height: 24),

                // About Section
                _buildAboutSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomBalanceCard(HomProvider homProvider) {
    if (!homProvider.isInitialized) {
      return Container(
        height: 120,
        decoration: AppTheme.cardDecoration,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final balance = homProvider.balance;
    if (balance == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: balance.isUnlimited
                      ? AppTheme.success.withAlpha(20)
                      : AppTheme.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  balance.isUnlimited ? Icons.all_inclusive : Icons.restaurant,
                  size: 30,
                  color: balance.isUnlimited
                      ? AppTheme.success
                      : AppTheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      balance.isUnlimited
                          ? 'Unlimited HOMs'
                          : '${balance.balance} HOMs',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      balance.isUnlimited
                          ? 'Using your OpenAI API key'
                          : 'Available meal scans',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (balance.canScan) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.success.withAlpha(100)),
                  ),
                  child: const Text(
                    'Ready to scan',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.error.withAlpha(100)),
                  ),
                  child: const Text(
                    'Out of HOMs',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOptions(BuildContext context, HomProvider homProvider) {
    return Column(
      children: [
        // Purchase HOMs
        _buildSettingsTile(
          icon: Icons.shopping_cart,
          title: 'Purchase HOMs',
          subtitle: 'Buy HOM packs to scan more meals',
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PurchaseHomsScreen(),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // API Configuration
        _buildSettingsTile(
          icon: Icons.key,
          title: 'AI API Config',
          subtitle: homProvider.isUnlimited
              ? 'Using your OpenAI key (unlimited)'
              : 'Set up your own OpenAI API key',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (homProvider.isUnlimited) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ApiConfigScreen()),
            );
          },
        ),

        const SizedBox(height: 12),

        // Data & Backup - Export
        _buildSettingsTile(
          icon: Icons.download,
          title: 'Export Backup',
          subtitle: 'Save all meals, goals, and photos',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _handleExport(context),
        ),

        const SizedBox(height: 12),

        // Data & Backup - Import
        _buildSettingsTile(
          icon: Icons.upload,
          title: 'Import Backup',
          subtitle: 'Restore from backup file (replaces all)',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _handleImport(context),
          isDanger: true,
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final color = isDanger ? AppTheme.error : AppTheme.primary;
    
    return Container(
      decoration: AppTheme.cardDecoration,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        trailing: trailing,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What is a HOM?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'A HOM is one AI meal scan. When you take a photo of your meal, our AI analyzes it to identify foods, estimate portions, and calculate calories and macros. Each analysis consumes 1 HOM.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.camera_alt, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              const Text(
                '1 photo → 1 HOM → 1 logged meal',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(BuildContext context) async {
    final backupService = BackupService();
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📦 Creating backup...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Create backup bytes
      final zipBytes = await backupService.exportBackupBytes();

      if (context.mounted) {
        // Let user choose where to save
        final savedPath = await backupService.saveBackupToUserLocation(zipBytes);

        if (savedPath != null && context.mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('✅ Backup Saved'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Your backup has been saved successfully!',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Location:\n$savedPath',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'You can now:\n• Share via email, cloud storage, or messaging apps\n• Keep it safe for restoring on a new device',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Backup failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    final backupService = BackupService();
    
    try {
      final xFile = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'ZIP files',
            mimeTypes: ['application/zip'],
            extensions: ['zip'],
          ),
        ],
      );

      if (xFile == null) {
        return;
      }

      final backupPath = xFile.path;

      if (context.mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ Replace All Data'),
            content: const Text(
              'This will replace all your current meals and goals with the backup data. This action cannot be undone.\n\nAre you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Import',
                  style: TextStyle(color: AppTheme.error),
                ),
              ),
            ],
          ),
        );

        if (confirmed != true) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📥 Restoring backup...'),
            duration: Duration(seconds: 2),
          ),
        );

        final result = await backupService.importBackup(backupPath);

        if (context.mounted) {
          if (result.success) {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('✅ Backup Restored'),
                content: Text(result.message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${result.message}'),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Import failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
