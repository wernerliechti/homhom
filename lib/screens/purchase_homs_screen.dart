import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/hom_provider.dart';
import '../models/hom_balance.dart';
import '../theme/app_theme.dart';
import '../widgets/hom_balance_indicator.dart';
import 'api_config_screen.dart';

class PurchaseHomsScreen extends StatefulWidget {
  final bool isPaywall;

  const PurchaseHomsScreen({super.key, this.isPaywall = false});

  @override
  State<PurchaseHomsScreen> createState() => _PurchaseHomsScreenState();
}

class _PurchaseHomsScreenState extends State<PurchaseHomsScreen> {
  String? _selectedPackId;
  bool _isPurchasing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isPaywall ? AppTheme.surface : null,
      appBar: widget.isPaywall
          ? null
          : AppBar(
              title: const Text('Buy HOMs'),
              backgroundColor: AppTheme.surface,
              elevation: 0,
            ),
      body: Consumer<HomProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              if (widget.isPaywall) ...[
                // Paywall header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20,
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppTheme.error.withAlpha(20), AppTheme.surface],
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: AppTheme.error,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Out of HOMs',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A HOM is one AI meal scan.\nTop up to keep scanning meals.',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!widget.isPaywall) ...[
                        const SizedBox(height: 16),
                        const HomBalanceIndicator(),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                // Regular purchase screen header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const HomBalanceIndicator(),
                      const SizedBox(height: 20),
                      const Text(
                        'Buy HOM Packs',
                        style: AppTheme.heading1,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Each HOM lets you scan one meal with AI.\nChoose the pack that works best for you.',
                        style: AppTheme.body2,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],

              // Pack options
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      ...HomPack.availablePacks.map(
                        (pack) => _buildPackCard(pack, provider),
                      ),

                      const SizedBox(height: 20),

                      // Or use your own API key
                      if (widget.isPaywall) ...[
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Maybe later',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPackCard(HomPack pack, HomProvider provider) {
    final isSelected = _selectedPackId == pack.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: isSelected ? 4 : 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectPack(pack.id),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary
                    : pack.isPopular
                    ? AppTheme.secondary.withAlpha(100)
                    : AppTheme.divider,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected ? AppTheme.primary.withAlpha(10) : Colors.white,
            ),
            child: Row(
              children: [
                // HOMs info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${pack.homs} HOMs',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (pack.isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.secondary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Popular',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${(pack.pricePerHom).toStringAsFixed(2)} per HOM',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (pack.savingsPercent > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Save ${pack.savingsPercent}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Price and buy button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      pack.displayPrice,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isPurchasing
                          ? null
                          : () => _purchasePack(pack.id, provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? AppTheme.primary
                            : AppTheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        _isPurchasing && isSelected ? 'Buying...' : 'Buy',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectPack(String packId) {
    setState(() {
      _selectedPackId = packId;
    });
  }

  Future<void> _purchasePack(String packId, HomProvider provider) async {
    setState(() {
      _isPurchasing = true;
    });

    try {
      await provider.purchaseHomPack(packId);

      if (mounted) {
        HapticFeedback.mediumImpact();

        if (widget.isPaywall) {
          // Close paywall after successful purchase
          Navigator.of(context).pop(true);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 HOMs purchased successfully!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }
}
