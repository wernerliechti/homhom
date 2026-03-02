import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hom_provider.dart';
import '../theme/app_theme.dart';

import '../screens/purchase_homs_screen.dart';
import '../screens/api_config_screen.dart';

class NewSettingsScreen extends StatelessWidget {
  const NewSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.yellow,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'H',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('HomHom Settings'),
          ],
        ),
        backgroundColor: AppTheme.surface,
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
                  color: balance.isUnlimited ? AppTheme.success : AppTheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      balance.isUnlimited ? 'Unlimited HOMs' : '${balance.balance} HOMs',
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              MaterialPageRoute(
                builder: (context) => const ApiConfigScreen(),
              ),
            );
          },
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
  }) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primary,
          ),
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
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
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
              Icon(
                Icons.camera_alt,
                size: 16,
                color: AppTheme.textSecondary,
              ),
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
}