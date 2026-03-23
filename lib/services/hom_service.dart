import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/hom_balance.dart';
import 'receipt_validator.dart';
import 'firebase_service.dart';

class HomService {
  static const _storage = FlutterSecureStorage();
  static const String _balanceKey = 'hom_balance';
  static const String _apiKeyKey = 'openai_api_key';
  static const String _rateLimitKey = 'hom_analysis_timestamps';
  static const int _maxRequestsPerHour = 10; // Rate limit: 10 requests per hour

  HomBalance? _currentBalance;
  final StreamController<HomBalance> _balanceController =
      StreamController<HomBalance>.broadcast();

  // In-app purchase setup
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];

  Stream<HomBalance> get balanceStream => _balanceController.stream;
  HomBalance? get currentBalance => _currentBalance;
  bool get isPaymentAvailable => _isAvailable;
  List<ProductDetails> get availableProducts => _products;

  Future<void> initialize() async {
    // Load current balance
    await _loadBalance();

    // Try to sync balance to Firestore if it's out of sync
    // This handles the case where local balance is ahead of Firestore
    if (_currentBalance != null && !_currentBalance!.isUnlimited) {
      try {
        final firebaseBalance = await FirebaseService().getHoMsBalance();
        if (firebaseBalance < _currentBalance!.balance) {
          print(
            '⚠️ Local balance (${_currentBalance!.balance}) is ahead of Firestore ($firebaseBalance)',
          );
          print('🔄 Syncing local balance to Firestore...');
          await FirebaseService().updateHoMsBalance(_currentBalance!.balance);
        }
      } catch (e) {
        print('⚠️ Could not sync balance during init: $e (continuing anyway)');
      }
    }

    // Initialize in-app purchases
    await _initializeInAppPurchases();

    // Start listening to purchase updates
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdate,
      onError: (error) {
        print('Purchase stream error: $error');
      },
    );
  }

  Future<void> _loadBalance() async {
    try {
      final apiKey = await _storage.read(key: _apiKeyKey);

      if (apiKey != null && apiKey.isNotEmpty) {
        // User has their own API key - unlimited mode
        _currentBalance = HomBalance.unlimited(apiKey);
        _balanceController.add(_currentBalance!);
        return;
      }

      // Try to load from Firestore first (source of truth)
      try {
        final firebaseBalance = await FirebaseService().getHoMsBalance();
        _currentBalance = HomBalance(
          balance: firebaseBalance,
          isUnlimited: false,
          userApiKey: null,
          lastUpdated: DateTime.now(),
        );
        print('✅ Loaded HOMs balance from Firestore: $firebaseBalance');
        await _saveBalance(); // Cache locally
        _balanceController.add(_currentBalance!);
        return;
      } catch (firebaseError) {
        print(
          '⚠️ Could not load from Firestore, trying local cache: $firebaseError',
        );
      }

      // Fall back to local storage if Firestore is unavailable
      final balanceData = await _storage.read(key: _balanceKey);
      if (balanceData != null) {
        // Parse stored balance
        final balanceJson = Map<String, dynamic>.from(
          Uri.splitQueryString(balanceData).map(
            (k, v) => MapEntry(
              k,
              v == 'true'
                  ? true
                  : v == 'false'
                  ? false
                  : v,
            ),
          ),
        );
        _currentBalance = HomBalance.fromMap({
          'balance': int.parse(balanceJson['balance'] ?? '0'),
          'isUnlimited': balanceJson['isUnlimited'] == true ? 1 : 0,
          'userApiKey': balanceJson['userApiKey'],
          'lastUpdated':
              balanceJson['lastUpdated'] ?? DateTime.now().toIso8601String(),
        });
        print(
          '⚠️ Using cached HOMs balance (Firestore unavailable): ${_currentBalance!.balance}',
        );
      } else {
        // New user - start with free HOMs
        _currentBalance = HomBalance.initial();
        await _saveBalance();
        print('📱 New user - initialized with free HOMs');
      }

      _balanceController.add(_currentBalance!);
    } catch (e) {
      print('❌ Error loading HOM balance: $e');
      _currentBalance = HomBalance.initial();
      _balanceController.add(_currentBalance!);
    }
  }

  Future<void> _saveBalance() async {
    if (_currentBalance == null) return;

    try {
      final balanceData = Uri(
        queryParameters: {
          'balance': _currentBalance!.balance.toString(),
          'isUnlimited': _currentBalance!.isUnlimited.toString(),
          'userApiKey': _currentBalance!.userApiKey ?? '',
          'lastUpdated': _currentBalance!.lastUpdated.toIso8601String(),
        },
      ).query;

      await _storage.write(key: _balanceKey, value: balanceData);

      // Save API key separately if present
      if (_currentBalance!.userApiKey != null) {
        await _storage.write(
          key: _apiKeyKey,
          value: _currentBalance!.userApiKey!,
        );
      }
    } catch (e) {
      print('Error saving HOM balance: $e');
    }
  }

  Future<void> _initializeInAppPurchases() async {
    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      if (!_isAvailable) {
        print('In-app purchases not available');
        return;
      }

      // Load product details
      final Set<String> productIds = HomPack.availablePacks
          .map((pack) => pack.id)
          .toSet();

      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(productIds);

      if (response.error != null) {
        print('Error querying products: ${response.error}');
        return;
      }

      _products = response.productDetails;
      print('Loaded ${_products.length} products');
    } catch (e) {
      print('Error initializing in-app purchases: $e');
      _isAvailable = false;
    }
  }

  Future<bool> consumeHom() async {
    if (_currentBalance == null || !_currentBalance!.canScan) {
      return false;
    }

    try {
      _currentBalance = _currentBalance!.consumeHom();
      await _saveBalance();

      // Update Firestore with new balance (consumed by local app, Cloud Function will handle via API)
      // Note: Cloud Functions will also consume and return the updated balance
      try {
        await FirebaseService().updateHoMsBalance(_currentBalance!.balance);
        print('✅ Updated Firestore after consuming HOM');
      } catch (e) {
        print('⚠️ Failed to update Firestore balance: $e');
        // Continue anyway - local balance is what matters for the UI
      }

      _balanceController.add(_currentBalance!);
      return true;
    } catch (e) {
      print('Error consuming HOM: $e');
      return false;
    }
  }

  Future<void> setApiKey(String? apiKey) async {
    try {
      if (apiKey != null && apiKey.isNotEmpty) {
        // Switch to unlimited mode
        _currentBalance = HomBalance.unlimited(apiKey);
        await _storage.write(key: _apiKeyKey, value: apiKey);
      } else {
        // Switch to metered mode
        _currentBalance = HomBalance.metered(10); // Start with 10 free HOMs
        await _storage.delete(key: _apiKeyKey);
      }

      await _saveBalance();
      _balanceController.add(_currentBalance!);
    } catch (e) {
      print('Error setting API key: $e');
    }
  }

  Future<void> purchaseHomPack(String productId) async {
    if (!_isAvailable) {
      throw Exception('In-app purchases not available');
    }

    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found: $productId'),
    );

    final purchaseParam = PurchaseParam(productDetails: product);
    await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
  }

  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          print('Purchase pending: ${purchase.productID}');
          break;
        case PurchaseStatus.purchased:
          _completePurchase(purchase);
          break;
        case PurchaseStatus.error:
          print('Purchase error: ${purchase.error}');
          break;
        case PurchaseStatus.canceled:
          print('Purchase canceled: ${purchase.productID}');
          break;
        case PurchaseStatus.restored:
          // Consumables can't be restored
          break;
      }
    }
  }

  Future<void> _completePurchase(PurchaseDetails purchase) async {
    try {
      // Find the corresponding HOM pack
      final pack = HomPack.availablePacks.firstWhere(
        (p) => p.id == purchase.productID,
        orElse: () => throw Exception('Unknown product: ${purchase.productID}'),
      );

      // Verify purchase receipt (for production security)
      // TODO: Replace with proper backend verification in production
      final isValid = await ReceiptValidator.verifyPurchaseLocal(
        productId: purchase.productID,
        purchaseToken: purchase.purchaseID ?? '',
      );

      if (!isValid) {
        print('Purchase verification failed: ${purchase.productID}');
        return;
      }

      // Add HOMs to balance
      if (_currentBalance != null && !_currentBalance!.isUnlimited) {
        _currentBalance = _currentBalance!.addHoms(pack.homs);
        await _saveBalance();

        // IMPORTANT: Also update Firestore (single source of truth)
        try {
          await FirebaseService().updateHoMsBalance(_currentBalance!.balance);
          print('✅ Updated Firestore with new HOMs balance');
        } catch (e) {
          print('⚠️ Failed to update Firestore, but local balance updated: $e');
        }

        _balanceController.add(_currentBalance!);
      }

      // Complete the purchase
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }

      print('Purchase completed: ${pack.homs} HOMs added');
    } catch (e) {
      print('Error completing purchase: $e');
    }
  }

  /// Reload balance from local storage
  Future<void> refreshBalance() async {
    await _loadBalance();
  }

  /// Update balance with value from Firestore (after Cloud Function operations)
  Future<void> updateBalanceFromFirebase(int remainingHoms) async {
    if (_currentBalance == null) return;

    try {
      // Update the balance to match Firestore
      _currentBalance = _currentBalance!.copyWith(balance: remainingHoms);
      await _saveBalance();
      _balanceController.add(_currentBalance!);
      print('✅ Updated HOMs balance from Firebase: $remainingHoms');
    } catch (e) {
      print('Error updating balance from Firebase: $e');
    }
  }

  /// Sync local balance to Firestore (use if out of sync)
  Future<void> syncBalanceToFirestore() async {
    if (_currentBalance == null || _currentBalance!.isUnlimited) {
      return;
    }

    try {
      await FirebaseService().updateHoMsBalance(_currentBalance!.balance);
      print('✅ Synced local balance to Firestore: ${_currentBalance!.balance}');
    } catch (e) {
      print('❌ Error syncing balance to Firestore: $e');
      rethrow;
    }
  }

  /// Check if user has exceeded the 10 requests per hour rate limit
  /// Returns (canMakeRequest, remainingRequests, timeUntilReset)
  Future<
    ({bool canMakeRequest, int remainingRequests, Duration timeUntilReset})
  >
  checkRateLimit() async {
    try {
      final timestampsStr = await _storage.read(key: _rateLimitKey);
      List<int> timestamps = [];

      if (timestampsStr != null && timestampsStr.isNotEmpty) {
        timestamps = timestampsStr
            .split(',')
            .map((ts) => int.tryParse(ts))
            .whereType<int>()
            .toList();
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final oneHourAgo = now - (60 * 60 * 1000); // 1 hour in milliseconds

      // Remove timestamps older than 1 hour
      timestamps.removeWhere((ts) => ts < oneHourAgo);

      final remainingRequests = _maxRequestsPerHour - timestamps.length;
      final canMakeRequest = remainingRequests > 0;

      // Calculate time until the oldest request expires
      Duration timeUntilReset = const Duration(seconds: 0);
      if (timestamps.isNotEmpty) {
        final oldestTimestamp = timestamps.first;
        final timeUntilExpiry = oldestTimestamp + (60 * 60 * 1000) - now;
        timeUntilReset = Duration(milliseconds: timeUntilExpiry);
      }

      print(
        '📊 Rate limit check: $remainingRequests/$_maxRequestsPerHour requests available',
      );

      return (
        canMakeRequest: canMakeRequest,
        remainingRequests: remainingRequests,
        timeUntilReset: timeUntilReset,
      );
    } catch (e) {
      print('⚠️ Error checking rate limit: $e (allowing request to proceed)');
      return (
        canMakeRequest: true,
        remainingRequests: _maxRequestsPerHour,
        timeUntilReset: const Duration(),
      );
    }
  }

  /// Record a successful analysis request (only on success - consumes HOM)
  /// This counts towards both rate limit and HOM deduction
  Future<void> recordSuccessfulAnalysis() async {
    try {
      final timestampsStr = await _storage.read(key: _rateLimitKey);
      List<int> timestamps = [];

      if (timestampsStr != null && timestampsStr.isNotEmpty) {
        timestamps = timestampsStr
            .split(',')
            .map((ts) => int.tryParse(ts))
            .whereType<int>()
            .toList();
      }

      // Add current timestamp
      timestamps.add(DateTime.now().millisecondsSinceEpoch);

      // Keep only timestamps from last hour
      final oneHourAgo =
          DateTime.now().millisecondsSinceEpoch - (60 * 60 * 1000);
      timestamps.removeWhere((ts) => ts < oneHourAgo);

      // Save updated timestamps
      await _storage.write(key: _rateLimitKey, value: timestamps.join(','));

      print(
        '✅ Recorded SUCCESSFUL analysis. Total in last hour: ${timestamps.length}/$_maxRequestsPerHour',
      );
    } catch (e) {
      print('⚠️ Error recording successful analysis: $e');
    }
  }

  void dispose() {
    _purchaseSubscription.cancel();
    _balanceController.close();
  }
}
