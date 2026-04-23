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
import 'booking_complete_screen.dart';
import 'main_screen.dart';

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
  bool _isWorkerCardExpanded = false;

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
        _checkCompletionStatus();
      }
    });
  }

  void _checkCompletionStatus() {
    if (_booking != null && _booking['status']?.toString().toLowerCase() == 'completed') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BookingCompleteScreen(booking: _booking),
            ),
          );
        }
      });
    }
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
        _checkCompletionStatus();
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
    final labourerData = _booking['labourer'];
    final upiId = labourerData?['upiId']?.toString();
    final workerName = labourerData?['name']?.toString() ?? "Worker";

    if (upiId != null && upiId.isNotEmpty) {
      // Launch UPI Intent
      final String upiUri = 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(workerName)}&am=$amount&cu=INR&tn=${Uri.encodeComponent("Payment for ${_booking['category']} via WILL App")}';
      
      try {
        if (await canLaunchUrl(Uri.parse(upiUri))) {
          await launchUrl(Uri.parse(upiUri));
        } else {
          // Fallback if no UPI app
          _showPaymentDialog(amount, isUpi: true, upiId: upiId);
        }
      } catch (e) {
        _showPaymentDialog(amount, isUpi: true, upiId: upiId);
      }
    } else {
      // Show Cash Payment Dialog
      _showPaymentDialog(amount, isUpi: false);
    }
  }

  void _showPaymentDialog(int amount, {bool isUpi = false, String? upiId}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isUpi ? 'Pay via UPI' : 'Pay in Cash', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUpi 
                ? 'We couldn\'t open your UPI app automatically. You can pay manually to:'
                : 'The worker hasn\'t set up online payments. Please pay them directly.',
              style: GoogleFonts.roboto(fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (isUpi && upiId != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(upiId, style: const TextStyle(fontWeight: FontWeight.bold))),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        // Copy to clipboard logic could go here
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Amount: ₹$amount',
              style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF4A9782)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (isUpi)
            ElevatedButton(
              onPressed: () {
                // If we show this dialog, user probably already tried opening the app
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A9782)),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
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
    final bool hasUpi = labourerData?['upiId'] != null && labourerData!['upiId'].toString().isNotEmpty;

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
            fontSize: 22,
            fontWeight: FontWeight.w400,
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
            const SizedBox(height: 40),
            _buildProgressBar(status),
            const SizedBox(height: 12),
            _buildOTPCard(status, arrivalOTP, completionOTP),
            const SizedBox(height: 40),
            // Main Content Grey Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: ShapeDecoration(
                color: const Color(0xFFF2F2F2),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 1, color: Color(0xFFD2D2D2)),
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  if (labourer != null) _buildWorkerCard(labourer),
                  if (status != 'arrived' && status != 'completed') ...[
                    const SizedBox(height: 12),
                    _buildWorkDetailsCard(_booking),
                    _buildPaymentSection(status, amount),
                  ] else ...[
                    if (_isWorkerCardExpanded) ...[
                      const SizedBox(height: 12),
                      _buildWorkDetailsCard(_booking),
                    ],
                    const SizedBox(height: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isWorkerCardExpanded = !_isWorkerCardExpanded;
                        });
                      },
                      icon: Icon(
                        _isWorkerCardExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.black,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            if (status == 'arrived' || status == 'completed') ...[
              const SizedBox(height: 60),
              Text(
                'Your Work is Complete :',
                style: GoogleFonts.roboto(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Pay Now : ',
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF8F8F8F),
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: '₹${amount.toInt()}',
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF4A9782),
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (!hasUpi) ...[
                const SizedBox(height: 16),
                Text(
                  'Pay directly to worker',
                  style: GoogleFonts.roboto(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
              const SizedBox(height: 60),
              if (hasUpi) _buildPaymentOptionsBar(),
              const SizedBox(height: 32),
              if (hasUpi)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 100),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _initiatePayment(
                        amount is int ? amount : int.tryParse(amount.toString()) ?? 0,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF529A87),
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String status) {
    bool isArrived = status == 'arrived' || status == 'completed';
    bool isCompleted = status == 'completed';
    double progress = isCompleted ? 1.0 : (isArrived ? 0.5 : 0.05);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36.0),
      child: Stack(
        alignment: Alignment.centerLeft,
        clipBehavior: Clip.none,
        children: [
          // Background Bar
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFB6B6B6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Active Bar
          FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF4A9782),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Start Dot
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFF4A9782),
              shape: BoxShape.circle,
            ),
          ),
          // End Checkmark (only visible if completed or at the end of the visual line)
          Positioned(
            right: -6,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF4A9782) : const Color(0xFF4A9782).withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.check,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPCard(String status, String arrivalOTP, String completionOTP) {
    bool isCompletion = status == 'arrived' || status == 'completed';
    String title = isCompletion 
        ? "Share OTP to worker\nafter payment is done" 
        : "Share OTP to worker\nonce he arrives";
    String otp = isCompletion ? completionOTP : arrivalOTP;

    return Align(
      alignment: isCompletion ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: isCompletion ? const EdgeInsets.only(right: 36) : const EdgeInsets.only(left: 36),
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0xFF4A9782)),
            borderRadius: BorderRadius.only(
              topLeft: isCompletion ? const Radius.circular(16) : Radius.zero,
              topRight: isCompletion ? Radius.zero : const Radius.circular(16),
              bottomLeft: const Radius.circular(16),
              bottomRight: const Radius.circular(16),
            ),
          ),
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.roboto(
                color: const Color(0xFF2B7F68),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.33,
                letterSpacing: 0.40,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              otp,
              style: GoogleFonts.roboto(
                color: const Color(0xFF4A9782),
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.27,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerCard(Labourer labourer) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x3F000000),
                blurRadius: 4,
                offset: Offset(0, 4),
                spreadRadius: 0,
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 63,
                height: 63,
                decoration: ShapeDecoration(
                  image: DecorationImage(
                    image: labourer.imageUrl.isNotEmpty
                        ? NetworkImage(labourer.imageUrl)
                        : const NetworkImage("https://placehold.co/63x63"),
                    fit: BoxFit.cover,
                  ),
                  shape: const OvalBorder(
                    side: BorderSide(width: 1, color: Color(0xFF4A9782)),
                  ),
                ),
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
                        height: 0.80,
                        letterSpacing: 0.40,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      labourer.category,
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.40,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFD700), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${labourer.rating} ',
                    style: GoogleFonts.roboto(
                      color: const Color(0xFF595959),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFF5FFFC),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(width: 1, color: Color(0xFF4A9782)),
                      borderRadius: BorderRadius.circular(25.50),
                    ),
                  ),
                  child: TextButton(
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
                    child: Text(
                      'Message',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF4A9782),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 124,
                height: 48,
                decoration: ShapeDecoration(
                  color: const Color(0xFF539987),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.50),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.call_outlined, color: Colors.white, size: 24),
                  onPressed: () async {
                    final userData = _booking['labourer']?['user'];
                    final phone = userData?['phoneNumber'];
                    if (phone != null && phone.isNotEmpty) {
                      final url = 'tel:$phone';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkDetailsCard(dynamic booking) {
    final date = DateTime.parse(booking['date']).toLocal();
    final timeStr = "${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}";
    final dateStr = "${date.day} ${_getMonthName(date.month)}";

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Work Details :',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: 0.40,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem('Service', booking['category']),
              _buildVerticalDivider(),
              _buildDetailItem('Duration', '${booking['numberOfHours'] ?? 2} Hours'),
              _buildVerticalDivider(),
              _buildDetailItem('Date', dateStr),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildDetailItem('Arrival Time', timeStr),
              const SizedBox(width: 24),
              _buildVerticalDivider(),
              const SizedBox(width: 24),
              Expanded(
                child: _buildDetailItem(
                  'Location',
                  booking['address'] ?? 'Kharar, India',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 33,
      color: const Color(0xFFCCCCCC),
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
            fontWeight: FontWeight.w400,
            color: Colors.black,
            height: 1.60,
            letterSpacing: 0.40,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black,
            height: 1.43,
            letterSpacing: 0.25,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection(String status, dynamic amount) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 0),
          child: Divider(color: Color(0xFFD0D0D0), thickness: 1, height: 1),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount Due :',
                    style: GoogleFonts.roboto(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: 0.40,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pay to worker after work completion',
                    style: GoogleFonts.roboto(
                      color: const Color(0xFF2D2D2D),
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Text(
                '₹$amount',
                style: GoogleFonts.roboto(
                  color: const Color(0xFF47907D),
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.29,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        if (status == 'arrived' || status == 'completed') ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _initiatePayment(
                  amount is int ? amount : int.tryParse(amount.toString()) ?? 0,
                ),
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

  Widget _buildPaymentOptionsBar() {
    final labourerData = _booking['labourer'];
    final bool hasUpi = labourerData?['upiId'] != null && labourerData!['upiId'].toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              hasUpi ? 'Choose Payment\nOption :' : 'Pay Worker\nDirectly :',
              style: GoogleFonts.roboto(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (hasUpi) ...[
            Image.asset('assets/images/gpay_logo.png', height: 16, errorBuilder: (c, e, s) => const Text('GPay', style: TextStyle(fontSize: 10))),
            const SizedBox(width: 12),
            Image.asset('assets/images/paytm_logo.png', height: 16, errorBuilder: (c, e, s) => const Text('Paytm', style: TextStyle(fontSize: 10))),
            const SizedBox(width: 12),
            const Icon(Icons.account_balance_wallet_outlined, size: 20, color: Color(0xFF4A9782)),
            const SizedBox(width: 4),
          ],
          Text(
            'COD',
            style: GoogleFonts.roboto(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: Colors.black),
        ],
      ),
    );
  }
}
