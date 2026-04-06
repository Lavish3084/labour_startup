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
  }

  void _errorListener() {
    if (!mounted || _appState == null) return;
    if (_appState!.bookingsError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_appState!.bookingsError!),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _paymentService.dispose();
    _appState?.removeListener(_errorListener);
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
            SnackBar(content: Text(ErrorHandler.getErrorMessage(e, action: 'Payment verification failed'))),
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
      // Need a key from env or config. Ideally fetched from backend or stored in config.
      // For now we will use a placeholder or ask user to provide it.
      // NOTE: User must provide their Razorpay Key ID here or in a Config file.
      final String razorpayKeyId = dotenv.get(
        'RAZORPAY_KEY_ID',
        fallback: 'rzp_test_YourKeyIDHere',
      );

      // amount is now passed as an argument
      final order = await ApiService.createPaymentOrder(booking['_id'], amount);

      setState(() {
        _pendingBookingId = booking['_id'];
      });

      _paymentService.openCheckout(
        keyId: razorpayKeyId,
        orderId: order['id'],
        name: "Will",
        description: "Booking Fee for ${booking['category']}",
        email: "user@example.com", // Should get from user profile
        contact: "9876543210", // Should get from user profile
        amount: order['amount'],
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.getErrorMessage(e, action: 'Payment initiation failed'))),
        );
      }
    }
  }

  bool _isHistory(dynamic booking) {
    final status = (booking['status'] as String).toLowerCase();
    if (status == 'completed' || status == 'cancelled') return true;

    final date = DateTime.parse(booking['date']);
    final hours = int.tryParse(booking['numberOfHours']?.toString() ?? '2') ?? 2;
    final endTime = date.add(Duration(hours: hours));

    return DateTime.now().isAfter(endTime);
  }

  final Set<String> _expandedBookingIds = {};
  bool _isRefreshing = false;

  Future<void> _refreshBookings() async {
    setState(() => _isRefreshing = true);
    await Provider.of<AppStateProvider>(context, listen: false).fetchBookings();
    if (mounted) setState(() => _isRefreshing = false);
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
                      color: AppTheme.error,
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
                  backgroundColor: AppTheme.error,
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.getErrorMessage(e, action: 'Update failed'))),
        );
      }
    }
  }

  Future<void> _handleConfirmWork(dynamic booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Work Completion', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Are you sure the worker has completed the job? This will release the payout to the worker.', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Yes, Confirm', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      try {
        final success = await ApiService.confirmWork(booking['_id']);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Work confirmed successfully!"), backgroundColor: Colors.green),
          );
          _refreshBookings();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to confirm work"), backgroundColor: AppTheme.error),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ErrorHandler.getErrorMessage(e, action: 'Confirmation failed'))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final allBookings = appState.bookings;
    final bookings = allBookings.where((b) => !_isHistory(b)).toList();
    final isLoading = appState.isBookingsLoading;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'My Bookings',
          style: GoogleFonts.baloo2(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
            icon: const Icon(Icons.history_rounded, color: AppTheme.textPrimary, size: 28),
            tooltip: 'Booking History',
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _refreshBookings();
            },
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textPrimary, size: 28),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Full Background Orange Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryLight,
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),

          // Scrollable Content
          _isRefreshing
              ? _buildLoadingState()
              : (isLoading && bookings.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.saffron))
                  : (bookings.isEmpty
                      ? _buildEmptyState()
                      : _buildbookingsList(bookings))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppTheme.saffron.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.saffron.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      size: 64,
                      color: AppTheme.saffron,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'No Active Bookings',
                    style: GoogleFonts.baloo2(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Looks like you haven't made any bookings yet. Find the right service and get things done today!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () =>
                          Provider.of<AppStateProvider>(context, listen: false)
                              .setTab(0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 8,
                        shadowColor: AppTheme.textPrimary.withValues(alpha: 0.3),
                      ),
                      child: Text(
                        'Explore Services',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _refreshBookings,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppTheme.saffron,
                      size: 20,
                    ),
                    label: Text(
                      'Check for updates',
                      style: GoogleFonts.inter(
                        color: AppTheme.saffron,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.history_rounded,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                    label: Text(
                      'View Past Bookings',
                      style: GoogleFonts.inter(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildbookingsList(List<dynamic> bookings) {
    // Sort bookings by date descending
    final sortedBookings = List.from(bookings);
    sortedBookings.sort((a, b) => b['date'].compareTo(a['date']));

    return RefreshIndicator(
      onRefresh: _refreshBookings,
      displacement: 20,
      color: AppTheme.saffron,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 130, left: 20, right: 20, bottom: 100),
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
                  padding: const EdgeInsets.fromLTRB(4, 5, 0, 16),
                  child: Row(
                    children: [
                      Text(
                        dateHeader.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.divider, AppTheme.divider.withValues(alpha: 0)],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              _buildBookingCard(booking, index == sortedBookings.length - 1),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(dynamic booking, bool isLast) {
    final labourer = booking['labourer'];
    final bookingId = booking['_id'];
    final isExpanded = _expandedBookingIds.contains(bookingId);
    final status = (booking['status'] as String).toLowerCase();
    final date = DateTime.parse(booking['date']);
    final timeString = "${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}";

    String imageUrl;
    String name;
    String category;

    if (labourer != null) {
      imageUrl = labourer['imageUrl'] ?? 'https://randomuser.me/api/portraits/lego/1.jpg';
      name = labourer['name'] ?? 'Worker';
      category = labourer['category'] ?? 'Service';
    } else {
      imageUrl = 'https://ui-avatars.com/api/?name=${booking['category'] ?? 'S'}&background=FF6B00&color=fff';
      name = booking['category'] ?? 'Service Request';
      category = 'Broadcast Request';
    }

    final categories = Provider.of<AppStateProvider>(context, listen: false).categories;
    ServiceCategory? categoryObj;
    try {
      categoryObj = categories.firstWhere((c) => c.name == booking['category']);
    } catch (_) {
      categoryObj = null;
    }
    
    double calculatedFee = 0;
    if (categoryObj != null) {
      if (booking['amount'] != null && (booking['amount'] as num) > 0) {
        calculatedFee = (booking['amount'] as num) * categoryObj.commissionPercentage / 100;
      } else {
        calculatedFee = categoryObj.commissionPercentage;
      }
    } else {
      calculatedFee = 20.0; // Fallback default fee
    }

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule_rounded;
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'arrived':
        statusColor = Colors.indigo;
        statusIcon = Icons.engineering_rounded;
        break;
      case 'completed':
        statusColor = AppTheme.success;
        statusIcon = Icons.stars_rounded;
        break;
      case 'cancelled':
        statusColor = AppTheme.error;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () => setState(() => isExpanded ? _expandedBookingIds.remove(bookingId) : _expandedBookingIds.add(bookingId)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Internal Header with Image & Status
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            image: DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.baloo2(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          category,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          status.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Middle section: Time & Address Mini
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_filled_rounded, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    timeString,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking['address'] ?? 'Check details',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Expanded Content
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildDetailRow('DATE', '${_getMonthName(date.month)} ${date.day}, ${date.year}')),
                        Expanded(child: _buildDetailRow('TOTAL JOB AMOUNT', '₹${(booking['amount'] ?? 0).toInt()}')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildDetailRow('BOOKING FEE (PAY NOW)', '₹${calculatedFee.toInt()}')),
                        Expanded(child: _buildDetailRow('PAY TO WORKER', '₹${((booking['amount'] ?? 0) - calculatedFee).toInt()}')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDetailRow('BOOKING ID', '#${(bookingId as String).substring(bookingId.length - 6).toUpperCase()}')),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // OTP Section
                    if (status == 'confirmed' || status == 'arrived')
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  status == 'confirmed' ? Icons.login_rounded : Icons.task_alt_rounded, 
                                  size: 16, 
                                  color: AppTheme.primary
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  status == 'confirmed' ? 'ARRIVAL OTP' : 'COMPLETION OTP',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  status == 'confirmed' 
                                    ? (booking['arrivalOTP'] ?? '----') 
                                    : (booking['completionOTP'] ?? '----'),
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status == 'confirmed' ? 'Share on Arrival' : 'Share on Completion',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (booking['notes'] != null && booking['notes'].toString().isNotEmpty) ...[
                      _buildDetailRow('NOTES', '${booking['notes']}'),
                      const SizedBox(height: 16),
                    ],
                    
                    // Action Buttons Area
                    Row(
                      children: [
                        if (status == 'confirmed' && (booking['paymentStatus'] != 'paid'))
                          Expanded(
                            child: _buildActionButton('PAY FEE ₹${calculatedFee.toInt()}', Colors.green, () => _initiatePayment(booking, calculatedFee.toInt())),
                          ),
                        if (status == 'confirmed' && booking['paymentStatus'] == 'paid' && booking['isWorkConfirmed'] != true)
                          Expanded(
                            child: _buildActionButton('CONFIRM WORK', AppTheme.saffron, () => _handleConfirmWork(booking)),
                          ),
                        if (status != 'completed' && booking['isWorkConfirmed'] != true) ...[
                           const SizedBox(width: 8),
                           Expanded(
                            child: _buildActionButton('CANCEL', AppTheme.error, () => _handleCancelWithdraw(booking), isOutlined: true),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            
            // Footer Indicator
            const SizedBox(height: 16),
            Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.divider.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: GoogleFonts.inter(
            fontSize: 9, 
            fontWeight: FontWeight.w800, 
            color: AppTheme.textMuted, 
            letterSpacing: 1
          )
        ),
        const SizedBox(height: 4),
        Text(
          value, 
          style: GoogleFonts.inter(
            fontSize: 13, 
            fontWeight: FontWeight.w700, 
            color: AppTheme.textPrimary,
          )
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap, {bool isOutlined = false}) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.white : color,
          foregroundColor: isOutlined ? color : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: isOutlined ? BorderSide(color: color, width: 1.5) : BorderSide.none,
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label, 
          style: GoogleFonts.inter(
            fontSize: 13, 
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          )
        ),
      ),
    );
  }

  String _getMonthName(int month) => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 130, left: 20, right: 20),
      itemCount: 4,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.4),
      highlightColor: Colors.white.withValues(alpha: 0.8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 80,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
