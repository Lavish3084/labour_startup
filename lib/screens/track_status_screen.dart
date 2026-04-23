import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_screen.dart';
import '../providers/app_state_provider.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
import '../services/error_handler.dart';
import '../models/labourer.dart';
import '../services/notification_service.dart';

import '../services/socket_service.dart';

class TrackStatusScreen extends StatefulWidget {
  final String bookingId;

  const TrackStatusScreen({super.key, required this.bookingId});

  @override
  State<TrackStatusScreen> createState() => _TrackStatusScreenState();
}

class _TrackStatusScreenState extends State<TrackStatusScreen> {
  final SocketService _socketService = SocketService();
  StreamSubscription? _notificationSubscription;
  bool _isLoading = true;
  dynamic _booking;
  final PaymentService _paymentService = PaymentService();
  String? _pendingBookingId;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
    _initSocket();
    _listenForNotifications();
    _paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: (response) {},
    );
  }

  @override
  void dispose() {
    _socketService.leaveBooking(widget.bookingId);
    _socketService.offBookingUpdate();
    _notificationSubscription?.cancel();
    _paymentService.dispose();
    super.dispose();
  }

  void _initSocket() {
    _socketService.connect();
    _socketService.joinBooking(widget.bookingId);
    _socketService.onBookingUpdate((data) {
      if (mounted) {
        debugPrint('[Socket] TrackStatusScreen received update');
        setState(() {
          _booking = data;
        });
      }
    });
  }

  void _listenForNotifications() {
    _notificationSubscription = NotificationService.onNotification.listen((_) {
      if (mounted) {
        debugPrint('TrackStatusScreen: Refreshing due to notification');
        _fetchBookingDetails(showLoading: false);
      }
    });
  }

  Future<void> _fetchBookingDetails({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    try {
      final booking = await ApiService.getBooking(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = booking;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error fetching booking details: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_booking != null) {
      try {
        final success = await ApiService.verifyPayment(
          response.orderId!,
          response.paymentId!,
          response.signature!,
          widget.bookingId,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment Successful!")),
          );
          _fetchBookingDetails();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ErrorHandler.getErrorMessage(e))),
          );
        }
      }
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
  }

  Future<void> _initiatePayment(int amount) async {
    try {
      final String razorpayKeyId = dotenv.get('RAZORPAY_KEY_ID', fallback: '');
      final order = await ApiService.createPaymentOrder(widget.bookingId, amount);

      _paymentService.openCheckout(
        keyId: razorpayKeyId,
        orderId: order['id'],
        name: "Will App",
        description: "Payment for ${_booking['category']}",
        email: "", // Ideally from user state
        contact: "", // Ideally from user state
        amount: order['amount'],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.getErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _booking == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF4A9782))),
      );
    }

    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Status')),
        body: const Center(child: Text('Booking not found')),
      );
    }

    final status = (_booking['status'] as String).toLowerCase();
    final arrivalOTP = _booking['arrivalOTP']?.toString() ?? '----';
    final completionOTP = _booking['completionOTP']?.toString() ?? '----';
    final labourerData = _booking['labourer'];
    final labourer = labourerData != null ? Labourer.fromJson(labourerData) : null;
    final amount = _booking['amount'] ?? (_booking['minAmount'] ?? 0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Track Status',
          style: GoogleFonts.roboto(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProgressBar(status),
            const SizedBox(height: 30),
            _buildOTPCard(status, arrivalOTP, completionOTP),
            const SizedBox(height: 30),
            if (labourer != null) _buildWorkerCard(labourer),
            const SizedBox(height: 20),
            if (status != 'completed') _buildWorkDetailsCard(_booking),
            if (status == 'arrived' || status == 'completed') _buildPaymentSection(status, amount),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String status) {
    bool isArrived = status == 'arrived' || status == 'completed';
    bool isCompleted = status == 'completed';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: isCompleted ? 1.0 : (isArrived ? 0.5 : 0.1),
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A9782),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressDot(true),
              _buildProgressDot(isCompleted, isEnd: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDot(bool active, {bool isEnd = false}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF4A9782) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? const Color(0xFF4A9782) : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: active && (active)
          ? const Icon(Icons.check, size: 14, color: Colors.white) 
          : null,
    );
  }

  Widget _buildOTPCard(String status, String arrivalOTP, String completionOTP) {
    bool isCompletion = status == 'arrived' || status == 'completed';
    String title = isCompletion 
        ? "Share OTP to worker after payment is done" 
        : "Share OTP to worker once he arrives";
    String otp = isCompletion ? completionOTP : arrivalOTP;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4A9782).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A9782).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              color: const Color(0xFF4A9782),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            otp,
            style: GoogleFonts.roboto(
              color: const Color(0xFF4A9782),
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(Labourer labourer) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: labourer.imageUrl.isNotEmpty
                    ? Image.network(labourer.imageUrl, width: 60, height: 60, fit: BoxFit.cover)
                    : Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.person)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labourer.name,
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      labourer.category,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFD700), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    labourer.rating.toStringAsFixed(1),
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          bookingId: widget.bookingId,
                          otherUserName: labourer.name,
                          otherUserPhoto: labourer.imageUrl,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF4A9782)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Message',
                    style: GoogleFonts.roboto(
                      color: const Color(0xFF4A9782),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 70,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A9782),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  icon: const Icon(Icons.call, color: Colors.white),
                  onPressed: () async {
                    // Access phone from nested user object
                    final userData = _booking['labourer']?['user'];
                    final phone = userData?['phoneNumber'];
                    if (phone != null && phone.isNotEmpty) {
                      final url = 'tel:$phone';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Worker's phone number not available")),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkDetailsCard(dynamic booking) {
    final date = DateTime.parse(booking['date']);
    final timeStr = "${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}";
    final dateStr = "${date.day} ${_getMonthName(date.month)}";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Work Details :',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem('Service', booking['category']),
              _buildDetailItem('Duration', '${booking['numberOfHours'] ?? 2} Hours'),
              _buildDetailItem('Date', dateStr),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildDetailItem('Arrival Time', timeStr),
              const SizedBox(width: 40),
              Expanded(child: _buildDetailItem('Location', booking['address'] ?? 'Kharar, India')),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount Due :',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Pay to worker after work completion',
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Text(
                '₹${booking['amount'] ?? 0}',
                style: GoogleFonts.roboto(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4A9782),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection(String status, dynamic amount) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Text(
          'Your Work is Complete :',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Pay Now : ',
                style: GoogleFonts.roboto(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFBDBDBD),
                ),
              ),
              TextSpan(
                text: '₹$amount',
                style: GoogleFonts.roboto(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4A9782),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Choose Payment Option :',
                  style: GoogleFonts.roboto(fontSize: 13, color: Colors.black87),
                ),
              ),
              Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c7/Google_Pay_Logo.svg/2560px-Google_Pay_Logo.svg.png', height: 20),
              const SizedBox(width: 10),
              Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/2/24/Paytm_Logo_%28standalone%29.svg/2560px-Paytm_Logo_%28standalone%29.svg.png', height: 14),
              const SizedBox(width: 10),
              const Icon(Icons.account_balance_wallet_outlined, size: 22, color: Color(0xFF4A9782)),
              const SizedBox(width: 4),
              const Text('COD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _initiatePayment(amount is int ? amount : int.tryParse(amount.toString()) ?? 0),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A9782),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: Text(
                'Pay Now',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
