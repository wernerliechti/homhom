import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseErrorHandler {
  static String getErrorMessage(IAPError error) {
    switch (error.code) {
      case 'purchase_error':
        return 'Purchase failed. Please try again.';
      case 'user_cancelled':
        return 'Purchase cancelled by user.';
      case 'network_error':
        return 'Network error. Check your connection and try again.';
      case 'item_unavailable':
        return 'This item is currently unavailable.';
      case 'item_already_owned':
        return 'You already own this item.';
      case 'billing_unavailable':
        return 'In-app purchases are not available on this device.';
      case 'developer_error':
        return 'Purchase configuration error. Please contact support.';
      case 'service_unavailable':
        return 'Google Play service is unavailable. Try again later.';
      default:
        return 'Purchase failed: ${error.message}';
    }
  }
  
  static bool isRetryableError(IAPError error) {
    const retryableCodes = [
      'network_error',
      'service_unavailable',
      'unknown_error',
    ];
    return retryableCodes.contains(error.code);
  }
  
  static bool isUserCancellation(IAPError error) {
    return error.code == 'user_cancelled';
  }
}