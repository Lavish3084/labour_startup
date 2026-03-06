import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/payment_service.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final PaymentService _paymentService = PaymentService();
  String? _pendingBookingId;

  @override
  void initState() {
    super.initState();
    // Data is fetched in MainScreen or via RefreshIndicator
    _paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingBookingId != null) {
      try {
        final success = await ApiService.verifyPayment(
          response.orderId!,
          response.paymentId!,
          response.signature!,
          _pendingBookingId!,
        );

        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Payment Successful!")));
          _refreshBookings();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment Verification Failed")),
          );
        }
      } catch (e) {
        print("Payment verification error: $e");
      }
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("External Wallet Selected: ${response.walletName}"),
      ),
    );
  }

  Future<void> _initiatePayment(dynamic booking) async {
    try {
      // Need a key from env or config. Ideally fetched from backend or stored in config.
      // For now we will use a placeholder or ask user to provide it.
      // NOTE: User must provide their Razorpay Key ID here or in a Config file.
      final String razorpayKeyId = dotenv.get(
        'RAZORPAY_KEY_ID',
        fallback: 'rzp_test_YourKeyIDHere',
      );

      // Calculate amount (labourer hourly rate * 8 hours usually, or custom)
      // For MVP we assume standard rate for now or 500 fixed.
      // Using labourer rate if available.
      int amount = 500;
      if (booking['labourer'] != null &&
          booking['labourer']['hourlyRate'] != null) {
        amount = booking['labourer']['hourlyRate'];
      }

      final order = await ApiService.createPaymentOrder(booking['_id'], amount);

      setState(() {
        _pendingBookingId = booking['_id'];
      });

      _paymentService.openCheckout(
        keyId: razorpayKeyId,
        orderId: order['id'],
        name: "Labour Application",
        description: "Payment for ${booking['category']}",
        email: "user@example.com", // Should get from user profile
        contact: "9876543210", // Should get from user profile
        amount: order['amount'],
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to initiate payment: $e")));
    }
  }

  final Set<String> _expandedBookingIds = {};

  Future<void> _refreshBookings() async {
    await Provider.of<AppStateProvider>(context, listen: false).fetchBookings();
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) return 'Today';
    if (dateToCheck == yesterday) return 'Yesterday';
    return "${_getMonthName(date.month)} ${date.day}, ${date.year}";
  }

  Future<void> _handleCancelWithdraw(dynamic booking) async {
    // ... (rest of the existing _handleCancelWithdraw code)
    final status = (booking['status'] as String).toLowerCase();

    if (status == 'pending') {
      // Direct withdrawal for pending requests
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(
                'Withdraw Request?',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Are you sure you want to withdraw this job request?',
                style: GoogleFonts.inter(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Keep Request',
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'Withdraw',
                    style: GoogleFonts.inter(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
      );

      if (confirmed == true) {
        await _performStatusUpdate(booking['_id'], 'cancelled');
      }
    } else if (status == 'confirmed') {
      // Show fee warning for confirmed/accepted bookings
      _showCancellationFeeDialog(booking);
    }
  }

  void _showCancellationFeeDialog(dynamic booking) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Cancellation Fee',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A cancellation fee may apply since a worker has already accepted this booking.',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Text(
                  '• Standard fee: ₹50\n• Notice: This fee compensates the worker for their time and travel commitment.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Keep Booking',
                  style: GoogleFonts.inter(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _performStatusUpdate(booking['_id'], 'cancelled');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Confirm Cancel',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _performStatusUpdate(String bookingId, String status) async {
    try {
      final success = await ApiService.updateBookingStatus(bookingId, status);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Booking ${status == 'cancelled' ? 'cancelled' : 'updated'} successfuly",
            ),
          ),
        );
        _refreshBookings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update booking status")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final bookings = appState.bookings;
    final isLoading = appState.isBookingsLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'My Bookings',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body:
          isLoading && bookings.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : (bookings.isEmpty
                  ? _buildEmptyState()
                  : _buildbookingsList(bookings)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Bookings Yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your bookings will appear here.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildbookingsList(List<dynamic> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(
          'No bookings in this category',
          style: GoogleFonts.inter(color: Colors.grey[500]),
        ),
      );
    }

    // Sort bookings by date descending
    final sortedBookings = List.from(bookings);
    sortedBookings.sort((a, b) => b['date'].compareTo(a['date']));

    return RefreshIndicator(
      onRefresh: _refreshBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedBookings.length,
        itemBuilder: (context, index) {
          final booking = sortedBookings[index];
          final date = DateTime.parse(booking['date']);
          final dateHeader = _getDateHeader(date);

          bool showHeader = false;
          if (index == 0) {
            showHeader = true;
          } else {
            final prevBooking = sortedBookings[index - 1];
            final prevDate = DateTime.parse(prevBooking['date']);
            if (_getDateHeader(prevDate) != dateHeader) {
              showHeader = true;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 12, left: 4),
                  child: Text(
                    dateHeader.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[400],
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              _buildBookingCard(booking),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    final labourer = booking['labourer'];
    final bookingId = booking['_id'];
    final isExpanded = _expandedBookingIds.contains(bookingId);
    final status = (booking['status'] as String).toLowerCase();
    final date = DateTime.parse(booking['date']); // Assuming ISO format
    final h = date.hour;
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final timeString =
        "$hour:${date.minute.toString().padLeft(2, '0')} ${h >= 12 ? 'PM' : 'AM'}";

    String imageUrl;
    String name;
    String category;
    String rate;

    if (labourer != null) {
      imageUrl =
          labourer['imageUrl'] ??
          'https://randomuser.me/api/portraits/lego/1.jpg';
      name = labourer['name'] ?? 'Unknown';
      category = labourer['category'] ?? 'Service';
      rate = '₹${labourer['hourlyRate']}.00'; // Formatting to match UI
    } else {
      imageUrl = 'https://ui-avatars.com/api/?name=Request&background=random';
      name = booking['category'] ?? 'Service Request';
      category = 'Broadcast Request';
      rate = 'Pending';
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_expandedBookingIds.contains(bookingId)) {
            _expandedBookingIds.remove(bookingId);
          } else {
            _expandedBookingIds.add(bookingId);
          }
        });
      },
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header Row (Always visible)
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            category,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Small Duration Badge
                    if (booking['bookingMode'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          booking['bookingMode'] == 'Hourly' &&
                                  booking['numberOfHours'] != null
                              ? '${booking['numberOfHours']} ${booking['numberOfHours'] == 1 ? 'hr' : 'hrs'}'
                              : booking['bookingMode'],
                          style: GoogleFonts.inter(
                            color: Colors.black87,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                // Animated Details Section
                // Animated Details Section
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity, height: 0),
                  secondChild: Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC), // Slate 50
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ), // Slate 200
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Booking Details',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              timeString,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1E293B),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Total Rate',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  rate,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Actions Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (status == 'confirmed' &&
                                (booking['paymentStatus'] == 'pending' ||
                                    booking['paymentStatus'] == null))
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: SizedBox(
                                  height: 32,
                                  child: ElevatedButton(
                                    onPressed: () => _initiatePayment(booking),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                    ),
                                    child: Text(
                                      'Pay Now',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (status == 'confirmed' &&
                                booking['paymentStatus'] == 'paid')
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Paid',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            SizedBox(
                              height: 32,
                              child: OutlinedButton(
                                onPressed: () => _handleCancelWithdraw(booking),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(
                                    color: Colors.red.withOpacity(0.5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 0,
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  crossFadeState:
                      isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                  sizeCurve: Curves.easeInOut,
                ),
              ],
            ),
          ),
          // Status Dot
          if (status == 'pending' || status == 'confirmed')
            Positioned(
              top: 24,
              right: 8,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      status == 'confirmed'
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFF97316),
                  boxShadow: [
                    BoxShadow(
                      color: (status == 'confirmed'
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFF97316))
                          .withOpacity(0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
