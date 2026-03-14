import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/hom_balance.dart';

class FirebaseProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  // State
  User? _currentUser;
  HomBalance? _balance;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _lastError;

  // Getters
  User? get currentUser => _currentUser;
  HomBalance? get balance => _balance;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get isAuthenticated => _firebaseService.isAuthenticated;
  String? get userId => _firebaseService.currentUserId;

  /// Initialize Firebase and check authentication state
  Future<void> initialize() async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      print('🔥 Initializing Firebase...');
      await _firebaseService.initialize();
      print('✅ Firebase core initialized');

      _currentUser = _firebaseService.currentUser;
      print('📱 Current user after init: ${_currentUser?.uid ?? "none"}');

      // If no user is authenticated, sign in anonymously
      if (_currentUser == null) {
        print('🔐 No user authenticated, attempting anonymous sign-in...');
        try {
          await _firebaseService.signInAnonymously();
          _currentUser = _firebaseService.currentUser;
          print('✅ Anonymous sign-in successful, UID: ${_currentUser?.uid}');
        } catch (signInError) {
          print('⚠️ Sign-in error (may be Pigeon deserialization): $signInError');
          // Wait a moment and check if user is actually authenticated
          await Future.delayed(Duration(seconds: 1));
          _currentUser = _firebaseService.currentUser;
          if (_currentUser != null) {
            print('✅ User authenticated despite error, UID: ${_currentUser?.uid}');
          } else {
            throw signInError;
          }
        }
      }

      // Load balance after ensuring authentication
      if (_currentUser != null) {
        print('💰 Loading user balance...');
        await _loadBalance();
        print('✅ Balance loaded: ${_balance?.balance ?? "unknown"}');
      } else {
        throw Exception('No user authenticated after initialization');
      }

      _isInitialized = true;
      print('🎉 Firebase initialization complete');
    } catch (e) {
      _lastError = e.toString();
      print('❌ Error initializing Firebase: $e');
      print('   CRITICAL: Check Firebase Console → Authentication → Sign-in method');
      print('   CRITICAL: Verify Anonymous sign-in is ENABLED');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user's HOM balance
  Future<void> _loadBalance() async {
    try {
      _balance = await _firebaseService.getUserBalance();
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      print('Error loading balance: $e');
    }
  }

  /// Sign up with email and password
  Future<bool> signUp(String email, String password) async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      await _firebaseService.signUp(email, password);
      _currentUser = _firebaseService.currentUser;

      await _loadBalance();

      return true;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      await _firebaseService.signIn(email, password);
      _currentUser = _firebaseService.currentUser;

      await _loadBalance();

      return true;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in anonymously (for testing)
  Future<bool> signInAnonymously() async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      await _firebaseService.signInAnonymously();
      _currentUser = _firebaseService.currentUser;

      await _loadBalance();

      return true;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
      _currentUser = null;
      _balance = null;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  /// Validate Google Play purchase
  Future<bool> validatePlayPurchase({
    required String purchaseToken,
    required String productId,
    required String packageName,
  }) async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      final result = await _firebaseService.validatePlayPurchase(
        purchaseToken: purchaseToken,
        productId: productId,
        packageName: packageName,
      );

      // Refresh balance
      await _loadBalance();

      return result['success'] == true;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Process meal image
  Future<Map<String, dynamic>?> processMeal({
    required String imageBase64,
    Map<String, dynamic>? userPreferences,
  }) async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      final result = await _firebaseService.processMeal(
        imageBase64: imageBase64,
        userPreferences: userPreferences,
      );

      // Refresh balance
      await _loadBalance();

      return result;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set API key
  Future<bool> setApiKey(String? apiKey) async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      final result = await _firebaseService.setApiKey(apiKey);

      // Refresh balance
      await _loadBalance();

      return result['success'] == true;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get transaction history
  Future<List<Map<String, dynamic>>> getTransactionHistory() async {
    try {
      return await _firebaseService.getTransactionHistory();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Get meal history
  Future<List<Map<String, dynamic>>> getMealHistory() async {
    try {
      return await _firebaseService.getMealHistory();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Clear error
  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}
