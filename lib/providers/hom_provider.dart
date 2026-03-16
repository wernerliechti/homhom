import 'package:flutter/foundation.dart';
import '../models/hom_balance.dart';
import '../services/hom_service.dart';

class HomProvider with ChangeNotifier {
  final HomService _homService = HomService();
  
  HomBalance? _balance;
  bool _isInitialized = false;
  String? _lastError;

  // Getters
  HomBalance? get balance => _balance;
  bool get isInitialized => _isInitialized;
  String? get lastError => _lastError;
  
  bool get canScan => _balance?.canScan ?? false;
  bool get isUnlimited => _balance?.isUnlimited ?? false;
  String get displayBalance => _balance?.displayBalance ?? '0';
  bool get isPaymentAvailable => _homService.isPaymentAvailable;

  Future<void> initialize() async {
    try {
      await _homService.initialize();
      
      // Listen to balance changes
      _homService.balanceStream.listen((balance) {
        _balance = balance;
        notifyListeners();
      });
      
      _balance = _homService.currentBalance;
      _isInitialized = true;
      _lastError = null;
      
    } catch (e) {
      _lastError = e.toString();
      print('Error initializing HomProvider: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Attempt to consume one HOM for a meal scan
  Future<bool> consumeHomForScan() async {
    if (!canScan) {
      _lastError = 'No HOMs remaining';
      notifyListeners();
      return false;
    }

    try {
      final success = await _homService.consumeHom();
      if (!success) {
        _lastError = 'Failed to consume HOM';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Set user's OpenAI API key (switches to unlimited mode)
  Future<void> setApiKey(String? apiKey) async {
    try {
      await _homService.setApiKey(apiKey);
      _lastError = null;
    } catch (e) {
      _lastError = e.toString();
    } finally {
      notifyListeners();
    }
  }

  /// Purchase a HOM pack
  Future<void> purchaseHomPack(String productId) async {
    try {
      await _homService.purchaseHomPack(productId);
      _lastError = null;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  /// Get available HOM packs for purchase
  List<HomPack> get availableHomPacks => HomPack.availablePacks;

  /// Refresh balance from Firestore (useful after Cloud Function operations)
  Future<void> refreshBalance() async {
    try {
      await _homService.refreshBalance();
      _balance = _homService.currentBalance;
      _lastError = null;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  /// Update balance from Firestore value (called after Cloud Function analysis)
  Future<void> updateBalanceFromFirebase(int remainingHoms) async {
    try {
      await _homService.updateBalanceFromFirebase(remainingHoms);
      _balance = _homService.currentBalance;
      _lastError = null;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  /// Clear any error messages
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _homService.dispose();
    super.dispose();
  }
}