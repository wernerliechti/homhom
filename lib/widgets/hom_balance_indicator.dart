import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hom_provider.dart';
import '../theme/app_theme.dart';
import '../screens/purchase_homs_screen.dart';
import '../screens/api_config_screen.dart';

class HomBalanceIndicator extends StatelessWidget {
  final bool compact;

  const HomBalanceIndicator({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HomProvider>(
      builder: (context, provider, child) {
        if (!provider.isInitialized || provider.balance == null) {
          return const SizedBox.shrink();
        }

        final balance = provider.balance!;
        
        return GestureDetector(
          onTap: () => _onTapped(context, balance),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 12,
              vertical: compact ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: balance.isUnlimited 
                  ? AppTheme.success.withAlpha(20)
                  : balance.balance > 5 
                      ? AppTheme.primary.withAlpha(20)
                      : balance.balance > 0
                          ? AppTheme.secondary.withAlpha(20)
                          : AppTheme.error.withAlpha(20),
              borderRadius: BorderRadius.circular(compact ? 12 : 16),
              border: Border.all(
                color: balance.isUnlimited 
                    ? AppTheme.success.withAlpha(100)
                    : balance.balance > 5 
                        ? AppTheme.primary.withAlpha(100)
                        : balance.balance > 0
                            ? AppTheme.secondary.withAlpha(100)
                            : AppTheme.error.withAlpha(100),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  balance.isUnlimited ? Icons.all_inclusive : Icons.restaurant,
                  size: compact ? 14 : 16,
                  color: balance.isUnlimited 
                      ? AppTheme.success
                      : balance.balance > 5 
                          ? AppTheme.primary
                          : balance.balance > 0
                              ? AppTheme.secondary
                              : AppTheme.error,
                ),
                SizedBox(width: compact ? 4 : 6),
                Text(
                  compact 
                      ? balance.displayBalance
                      : 'HOMs: ${balance.displayBalance}',
                  style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: balance.isUnlimited 
                        ? AppTheme.success
                        : balance.balance > 5 
                            ? AppTheme.primary
                            : balance.balance > 0
                                ? AppTheme.secondary
                                : AppTheme.error,
                  ),
                ),
                if (!compact && !balance.isUnlimited) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _onTapped(BuildContext context, balance) {
    if (balance.isUnlimited) {
      // Show API config screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ApiConfigScreen(),
        ),
      );
    } else {
      // Show purchase HOMs screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PurchaseHomsScreen(),
        ),
      );
    }
  }
}

/// Floating version for capture screens
class FloatingHomIndicator extends StatelessWidget {
  const FloatingHomIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      child: const HomBalanceIndicator(compact: true),
    );
  }
}