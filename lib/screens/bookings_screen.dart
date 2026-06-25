import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../services/payment_service.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_theme.dart';
import '../models/service_category.dart';
import 'history_screen.dart';
import 'track_status_screen.dart';
import '../services/notification_service.dart';
import 'dart:async';
import 'dart:ui';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final PaymentService _paymentService = PaymentService();
  String? _pendingBookingId;
  AppStateProvider? _appState;
  final TextEditingController _commentController = TextEditingController();
  double _rating = 5.0;
  String? _lastBookingsError;

  @override
  void initState() {
    super.initState();
    _paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _appState = Provider.of<AppStateProvider>(context, listen: false);
        _appState?.addListener(_errorListener);
      }
    });

    _notificationSubscription = NotificationService.onNotification.listen((_) {
      if (mounted) {
        _refreshBookings();
      }
    });
  }

  StreamSubscription<void>? _notificationSubscription;

  void _errorListener() {
    if (!mounted || _appState == null) return;
    final currentError = _appState!.bookingsError;
    if (currentError != null && currentError != _lastBookingsError) {
      _lastBookingsError = currentError;
      if (_appState!.selectedTab == 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(currentError),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
      }
    } else if (currentError == null) {
      _lastBookingsError = null;
    }
  }

  @override
  void dispose() {
    _paymentService.dispose();
    _appState?.removeListener(_errorListener);
    _notificationSubscription?.cancel();
    _commentController.dispose();
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ErrorHandler.getErrorMessage(
                  e,
                  action: 'Payment verification failed',
                ),
              ),
            ),
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

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("External Wallet Selected: ${response.walletName}"),
      ),
    );
  }

  Future<void> _initiatePayment(dynamic booking, int amount) async {
    try {
      final String razorpayKeyId = dotenv.get(
        'RAZORPAY_KEY_ID',
        fallback: 'rzp_test_YourKeyIDHere',
      );

      final order = await ApiService.createPaymentOrder(booking['_id'], amount);

      setState(() {
        _pendingBookingId = booking['_id'];
      });

      _paymentService.openCheckout(
        keyId: razorpayKeyId,
        orderId: order['id'],
        name: "Will",
        description: "Booking Fee for ${booking['category']}",
        email: "user@example.com",
        contact: "9876543210",
        amount: order['amount'],
      );
    } catch (e) {
      if (e.toString().contains('ALREADY_PAID')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("This booking was already paid. Refreshing..."),
              backgroundColor: Colors.green,
            ),
          );
          _refreshBookings();
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ErrorHandler.getErrorMessage(
                  e,
                  action: 'Payment initiation failed',
                ),
              ),
            ),
          );
        }
      }
    }
  }

  bool _isHistory(dynamic booking) {
    final status = (booking['status'] as String).toLowerCase();
    if (status == 'completed' || status == 'cancelled') return true;

    final date = DateTime.parse(booking['date']).toLocal();
    final hours =
        int.tryParse(booking['numberOfHours']?.toString() ?? '2') ?? 2;
    final endTime = date.add(Duration(hours: hours));

    return DateTime.now().isAfter(endTime);
  }

  Future<void> _refreshBookings() async {
    await Provider.of<AppStateProvider>(context, listen: false).fetchBookings();
  }

  void _showRatingDialog(dynamic booking) {
    _rating = 5.0;
    _commentController.clear();
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    'Rate Service',
                    style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'How was your experience with the service?',
                        style: GoogleFonts.roboto(fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < _rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 32,
                            ),
                            onPressed:
                                () =>
                                    setDialogState(() => _rating = index + 1.0),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.roboto(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final success = await ApiService.rateWorker(
                          booking['_id'],
                          _rating,
                          _commentController.text.trim(),
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Thank you for your rating!'),
                              ),
                            );
                            _refreshBookings();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E876E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Submit',
                        style: GoogleFonts.roboto(color: Colors.white),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  int _selectedTabIndex = 0; // 0 for Active, 1 for Past

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final allBookings = appState.bookings;

    final activeBookings = allBookings.where((b) => !_isHistory(b)).toList();
    final pastBookings = allBookings.where((b) => _isHistory(b)).toList();

    final currentBookings =
        _selectedTabIndex == 0 ? activeBookings : pastBookings;
    final isLoading = appState.isBookingsLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 24,
        automaticallyImplyLeading: false,
        title: Text(
          'Your bookings',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          const SizedBox(height: 24),
          Expanded(
            child:
                isLoading && currentBookings.isEmpty
                    ? _buildLoadingState()
                    : (currentBookings.isEmpty
                        ? _buildEmptyState()
                        : _buildNewBookingsList(currentBookings)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [_buildTabItem(0, 'Upcoming'), _buildTabItem(1, 'Past')],
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    isSelected ? const Color(0xFF4A9782) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.black : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewBookingsList(List<dynamic> bookings) {
    final sortedBookings = List.from(bookings);
    sortedBookings.sort((a, b) => b['date'].compareTo(a['date']));

    return RefreshIndicator(
      onRefresh: _refreshBookings,
      color: const Color(0xFF4A9782),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
        itemCount: sortedBookings.length,
        itemBuilder: (context, index) {
          final appState = Provider.of<AppStateProvider>(context);
          return _buildNewBookingCard(appState, sortedBookings[index]);
        },
      ),
    );
  }

  Widget _buildNewBookingCard(AppStateProvider appState, dynamic booking) {
    final status = (booking['status'] as String).toLowerCase();
    final isHistory = _isHistory(booking);
    final isCompleted = status == 'completed';
    final isRated = booking['isRated'] == true;
    final canRate = isCompleted && !isRated;

    final date = DateTime.parse(booking['date']).toLocal();
    final timeString =
        "${date.day} ${_getMonthName(date.month)}, ${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}";
    final amount = booking['amount'] ?? (booking['minAmount'] ?? 0);
    final location = booking['address'] ?? "No address";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 20,
            bottom: 20,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color:
                    status == 'cancelled'
                        ? Colors.red.shade400
                        : const Color(0xFF2E876E),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isHistory
                          ? (status == 'cancelled'
                              ? 'CANCELLED SERVICE'
                              : 'COMPLETED SERVICE')
                          : 'UPCOMING SERVICE',
                      style: GoogleFonts.roboto(
                        color:
                            status == 'cancelled'
                                ? Colors.red.shade400
                                : (isHistory
                                    ? const Color(0xFF666666)
                                    : const Color(0xFF2E876E)),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isHistory
                                ? const Color(0xFFF2F2F2)
                                : const Color(0xFFE8F3F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.roboto(
                          color:
                              isHistory
                                  ? const Color(0xFF666666)
                                  : const Color(0xFF2E876E),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${booking['category'] ?? 'Service'} service',
                  style: GoogleFonts.roboto(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DATE & TIME',
                            style: GoogleFonts.roboto(
                              color: const Color(0xFF666666),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: Color(0xFF2E876E),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  timeString,
                                  style: GoogleFonts.roboto(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LOCATION',
                            style: GoogleFonts.roboto(
                              color: const Color(0xFF666666),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Color(0xFF2E876E),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.roboto(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF0F0F0)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isHistory ? 'Total Amount:' : 'Amount Due:',
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF666666),
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      '₹$amount',
                      style: GoogleFonts.roboto(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (!isHistory || canRate) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!isHistory) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => TrackStatusScreen(
                                    bookingId: booking['_id'],
                                  ),
                            ),
                          );
                        } else if (canRate) {
                          _showRatingDialog(booking);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            canRate
                                ? Colors.amber[700]
                                : const Color(0xFF136952),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            canRate ? Icons.star_rounded : Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            canRate ? 'Rate Service' : 'Track Status',
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (!isHistory) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed:
                          () => _showCancelConfirmation(
                            context,
                            appState,
                            booking,
                          ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel Booking',
                        style: GoogleFonts.roboto(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_bookings_calendar.png',
            width: 140,
            height: 140,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          Text(
            _selectedTabIndex == 0
                ? 'No upcoming bookings'
                : 'No past bookings',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        itemCount: 3,
        itemBuilder:
            (context, index) => Container(
              height: 200,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
      ),
    );
  }

  void _showCancelConfirmation(
    BuildContext context,
    AppStateProvider appState,
    dynamic booking,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Booking?'),
            content: Text(
              (booking['status'] == 'confirmed' ||
                      booking['status'] == 'arrived')
                  ? 'If you cancel now, a partial refund will be credited to your wallet according to the platform\'s cancellation policy, as a worker has already accepted this job.'
                  : 'If you cancel now, your full payment will be refunded to your wallet.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No, Keep It'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await appState.cancelBooking(booking);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Booking cancelled. Refund added to wallet.'
                              : 'Failed to cancel booking.',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Yes, Cancel',
                  style: TextStyle(color: Colors.red),
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
