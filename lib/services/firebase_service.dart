import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/hom_balance.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getters
  String? get currentUserId => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;

  /// Initialize Firebase
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization error: $e');
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<UserCredential> signUp(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _createUserDocument(userCredential.user!.uid);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Create user document in Firestore
  Future<void> _createUserDocument(String userId) async {
    await _firestore.collection('users').doc(userId).set({
      'balance': 10, // 10 free HOMs for new users
      'isUnlimited': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get current user's HOM balance
  Future<HomBalance> getUserBalance() async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      final doc =
          await _firestore.collection('users').doc(currentUserId).get();

      if (!doc.exists) {
        // Create document if doesn't exist
        await _createUserDocument(currentUserId!);
        return HomBalance.initial();
      }

      final data = doc.data()!;
      return HomBalance(
        balance: data['balance'] ?? 10,
        isUnlimited: data['isUnlimited'] ?? false,
        userApiKey: null, // API key stored server-side only
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('Error getting user balance: $e');
      rethrow;
    }
  }

  /// Stream user's HOM balance (real-time updates)
  Stream<HomBalance> getUserBalanceStream() {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return HomBalance.initial();
      }

      final data = doc.data()!;
      return HomBalance(
        balance: data['balance'] ?? 10,
        isUnlimited: data['isUnlimited'] ?? false,
        userApiKey: null,
        lastUpdated: DateTime.now(),
      );
    });
  }

  /// Validate Google Play purchase receipt and add HOMs
  Future<Map<String, dynamic>> validatePlayPurchase({
    required String purchaseToken,
    required String productId,
    required String packageName,
  }) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      // Call Cloud Function: validatePlayPurchase
      final response = await _callCloudFunction(
        'validatePlayPurchase',
        {
          'purchaseToken': purchaseToken,
          'productId': productId,
          'packageName': packageName,
        },
      );

      return response;
    } catch (e) {
      print('Purchase validation error: $e');
      rethrow;
    }
  }

  /// Process meal image and get AI analysis (consumes 1 HOM)
  Future<Map<String, dynamic>> processMeal({
    required String imageBase64,
    Map<String, dynamic>? userPreferences,
  }) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await _callCloudFunction(
        'processMeal',
        {
          'imageBase64': imageBase64,
          'userPreferences': userPreferences ?? {},
        },
      );

      return response;
    } catch (e) {
      print('Meal processing error: $e');
      rethrow;
    }
  }

  /// Set API key to enable unlimited mode
  Future<Map<String, dynamic>> setApiKey(String? apiKey) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await _callCloudFunction(
        'setApiKey',
        {
          'apiKey': apiKey ?? '',
        },
      );

      return response;
    } catch (e) {
      print('Set API key error: $e');
      rethrow;
    }
  }

  /// Get user's transaction history
  Future<List<Map<String, dynamic>>> getTransactionHistory({
    int limit = 20,
  }) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();
    } catch (e) {
      print('Error getting transaction history: $e');
      rethrow;
    }
  }

  /// Get user's meal history
  Future<List<Map<String, dynamic>>> getMealHistory({
    int limit = 50,
  }) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('meals')
          .orderBy('processedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();
    } catch (e) {
      print('Error getting meal history: $e');
      rethrow;
    }
  }

  /// Call a Cloud Function using Firebase Cloud Functions SDK
  Future<Map<String, dynamic>> _callCloudFunction(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    try {
      final functions = FirebaseFunctions.instance;
      
      // Call the Cloud Function
      final result = await functions.httpsCallable(functionName).call(data);
      
      // Return the response data
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
      print('Cloud Function error: ${e.code} - ${e.message}');
      throw Exception('${e.code}: ${e.message}');
    } catch (e) {
      print('Error calling Cloud Function $functionName: $e');
      rethrow;
    }
  }

  /// Handle Firebase Auth errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak.';
      case 'email-already-in-use':
        return 'Email is already in use.';
      case 'user-not-found':
        return 'User not found.';
      case 'wrong-password':
        return 'Wrong password.';
      default:
        return e.message ?? 'An error occurred.';
    }
  }

  /// Sign in anonymously
  Future<UserCredential> signInAnonymously() async {
    try {
      print('🔐 Attempting anonymous sign-in with Firebase Auth...');
      final result = await _auth.signInAnonymously();
      print('✅ Anonymous sign-in successful: ${result.user?.uid}');
      return result;
    } on FirebaseAuthException catch (e) {
      final errorMessage = _handleAuthError(e);
      print('❌ Firebase Auth error: ${e.code} - ${e.message}');
      print('   Handled message: $errorMessage');
      throw Exception('Firebase Auth Error (${e.code}): ${e.message}');
    } catch (e) {
      print('❌ Unexpected error during anonymous sign-in: $e');
      throw Exception('Sign-in failed: $e');
    }
  }
}
