import 'dart:convert';
import 'package:http/http.dart' as http;

class ReceiptValidator {
  // In production, this should be your own backend service
  static const String _verificationEndpoint = 'YOUR_BACKEND_VERIFICATION_URL';
  
  /// Verify purchase receipt with your backend
  /// This prevents client-side manipulation and validates with Google Play
  static Future<bool> verifyPurchase({
    required String productId,
    required String purchaseToken,
    required String packageName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_verificationEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'productId': productId,
          'purchaseToken': purchaseToken,
          'packageName': packageName,
        }),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['valid'] == true;
      }
      
      return false;
    } catch (e) {
      print('Receipt verification failed: $e');
      return false;
    }
  }
  
  /// For development/testing: Skip verification
  /// TODO: Remove in production
  static Future<bool> verifyPurchaseLocal({
    required String productId,
    required String purchaseToken,
  }) async {
    // Simple local validation for development
    // In production, this should always call your backend
    return productId.isNotEmpty && purchaseToken.isNotEmpty;
  }
}