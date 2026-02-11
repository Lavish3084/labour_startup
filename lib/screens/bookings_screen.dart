import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/payment_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  late Future<List<dynamic>> _bookingsFuture;

  final PaymentService _paymentService = PaymentService();
  String? _pendingBookingId;

  @override
  void initState() {
    super.initState();
    _bookingsFuture = ApiService.getUserBookings();
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

  Future<void> _refreshBookings() async {
    setState(() {
      _bookingsFuture = ApiService.getUserBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final allBookings = snapshot.data!;
          return _buildbookingsList(allBookings);
        },
      ),
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

    return RefreshIndicator(
      onRefresh: _refreshBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    final labourer = booking['labourer'];
    final status = (booking['status'] as String).toLowerCase();
    final date = DateTime.parse(booking['date']); // Assuming ISO format
    final h = date.hour;
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final timeString =
        "$hour:${date.minute.toString().padLeft(2, '0')} ${h >= 12 ? 'PM' : 'AM'}";
    final dateString = "${_getMonthName(date.month)} ${date.day}, ${date.year}";

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
      name = 'Broadcast Request';
      category = booking['category'] ?? 'Pending';
      rate = 'Pending';
    }

    Color statusColor;
    Color statusBgColor;
    String statusText = status.toUpperCase();

    if (status == 'confirmed') {
      statusColor = const Color(0xFF22C55E); // Green
      statusBgColor = const Color(0xFFDCFCE7); // Light Green
    } else if (status == 'pending') {
      statusColor = const Color(0xFFF97316); // Orange
      statusBgColor = const Color(0xFFFFEDD5); // Light Orange
      statusText = "PENDING";
    } else if (status == 'completed') {
      statusColor = Colors.blue;
      statusBgColor = Colors.blue.withOpacity(0.1);
    } else {
      statusColor = Colors.grey;
      statusBgColor = Colors.grey.withOpacity(0.1);
    }

    return Container(
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
          // Header Row
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
                        color: const Color(0xFF64748B), // Slate 500
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Date & Price Row
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Text(
                dateString,
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                timeString,
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                rate,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
              if (status == 'confirmed' && booking['paymentStatus'] == 'paid')
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
                      border: Border.all(color: Colors.green),
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
                  onPressed: () {
                    // Cancel/Withdraw action
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                  ),
                  child: Text(
                    status == 'pending' ? 'Withdraw Request' : 'Cancel',
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
