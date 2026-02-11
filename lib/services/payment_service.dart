import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/services.dart';

class PaymentService {
  late Razorpay _razorpay;
  Function(PaymentSuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onFailure;
  Function(ExternalWalletResponse)? _onExternalWallet;

  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _onSuccess = onSuccess;
    _onFailure = onFailure;
    _onExternalWallet = onExternalWallet;

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void openCheckout({
    required String keyId, // Razorpay Key ID
    required String orderId,
    required String name,
    required String description,
    required String email,
    required String contact, // Phone number
    required int amount, // In paise
  }) {
    var options = {
      'key': keyId,
      'amount': amount,
      'name': name,
      'description': description,
      'order_id': orderId,
      'prefill': {'contact': contact, 'email': email},
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_onSuccess != null) {
      _onSuccess!(response);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (_onFailure != null) {
      _onFailure!(response);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (_onExternalWallet != null) {
      _onExternalWallet!(response);
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
