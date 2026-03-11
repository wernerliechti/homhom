import 'package:flutter/foundation.dart';
import '../providers/hom_provider.dart';

class PurchaseDebug {
  /// Add HOMs for testing (debug only)
  static Future<void> addTestHoms(HomProvider provider, int count) async {
    if (!kDebugMode) {
      print('Test HOM addition only available in debug mode');
      return;
    }
    
    // Simulate successful purchase by directly updating balance
    if (provider.balance != null && !provider.isUnlimited) {
      // This bypasses the normal purchase flow for testing
      await provider.setApiKey(null); // Ensure we're in metered mode
      
      // In a real app, you'd call the purchase flow
      // For testing, we'll add a debug method to HomService
      print('DEBUG: Adding $count test HOMs');
      
      // TODO: Add debug method to HomService to increase balance
      // This is just a placeholder for testing
    }
  }
  
  /// Reset to initial state for testing
  static Future<void> resetToInitial(HomProvider provider) async {
    if (!kDebugMode) {
      print('Reset only available in debug mode');
      return;
    }
    
    await provider.setApiKey(null); // Switch to metered mode with 10 free HOMs
    print('DEBUG: Reset to initial state (10 free HOMs)');
  }
}