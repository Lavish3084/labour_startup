import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../providers/app_state_provider.dart';
import '../utils/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isRefreshing = false;
  final Set<String> _expandedBookingIds = {};
  AppStateProvider? _appState;
  String? _lastBookingsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _appState = Provider.of<AppStateProvider>(context, listen: false);
        _appState?.addListener(_errorListener);
      }
    });
  }

  void _errorListener() {
    if (!mounted || _appState == null) return;
    final currentError = _appState!.bookingsError;
    if (currentError != null && currentError != _lastBookingsError) {
      _lastBookingsError = currentError;
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
    } else if (currentError == null) {
      _lastBookingsError = null;
    }
  }

  @override
  void dispose() {
    _appState?.removeListener(_errorListener);
    super.dispose();
  }

  Future<void> _refreshBookings() async {
    setState(() => _isRefreshing = true);
    await Provider.of<AppStateProvider>(context, listen: false).fetchBookings();
    if (mounted) setState(() => _isRefreshing = false);
  }

  bool _isHistory(dynamic booking) {
    final status = (booking['status'] as String).toLowerCase();
    if (status == 'completed' || status == 'cancelled') return true;

    final date = DateTime.parse(booking['date']).toLocal();
    final hours = int.tryParse(booking['numberOfHours']?.toString() ?? '2') ?? 2;
    final endTime = date.add(Duration(hours: hours));

    return DateTime.now().isAfter(endTime);
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

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final allBookings = appState.bookings;
    final historyBookings = allBookings.where((b) => _isHistory(b)).toList();
    final isLoading = appState.isBookingsLoading;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Booking History',
          style: GoogleFonts.baloo2(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
          
          _isRefreshing || (isLoading && historyBookings.isEmpty)
              ? const Center(child: CircularProgressIndicator(color: AppTheme.saffron))
              : (historyBookings.isEmpty
                  ? _buildEmptyState()
                  : _buildHistoryList(historyBookings)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No History Found',
            style: GoogleFonts.baloo2(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            'Completed or expired bookings appear here.',
            style: GoogleFonts.inter(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<dynamic> bookings) {
    final sortedBookings = List.from(bookings);
    sortedBookings.sort((a, b) => b['date'].compareTo(a['date']));

    return RefreshIndicator(
      onRefresh: _refreshBookings,
      color: AppTheme.saffron,
      child: ListView.builder(
        padding: EdgeInsets.only(top: 120, left: 20, right: 20, bottom: MediaQuery.of(context).padding.bottom + 24),
        itemCount: sortedBookings.length,
        itemBuilder: (context, index) {
          final booking = sortedBookings[index];
          final date = DateTime.parse(booking['date']).toLocal();
          final dateHeader = _getDateHeader(date);

          bool showHeader = false;
          if (index == 0) {
            showHeader = true;
          } else {
            final prevBooking = sortedBookings[index - 1];
            final prevDate = DateTime.parse(prevBooking['date']).toLocal();
            showHeader = _getDateHeader(prevDate) != dateHeader;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 16, 0, 12),
                  child: Text(
                    dateHeader.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1.2),
                  ),
                ),
              _buildHistoryCard(booking),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(dynamic booking) {
    final bookingId = booking['_id'];
    final isExpanded = _expandedBookingIds.contains(bookingId);
    final status = (booking['status'] as String).toLowerCase();
    final date = DateTime.parse(booking['date']).toLocal();
    final timeString = "${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}";
    
    // Determine display status for expired bookings
    String displayStatus = status;
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline_rounded;

    if (_isHistory(booking) && status == 'pending') {
      displayStatus = 'expired';
      statusColor = AppTheme.error;
      statusIcon = Icons.timer_off_rounded;
    } else {
      switch (status) {
        case 'completed':
          statusColor = AppTheme.success;
          statusIcon = Icons.stars_rounded;
          break;
        case 'cancelled':
          statusColor = Colors.grey;
          statusIcon = Icons.cancel_rounded;
          break;
        default:
          statusColor = Colors.blueGrey;
          statusIcon = Icons.history_rounded;
      }
    }

    return GestureDetector(
      onTap: () => setState(() => isExpanded ? _expandedBookingIds.remove(bookingId) : _expandedBookingIds.add(bookingId)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['category'] ?? 'Service',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                        ),
                        Text(
                          '$timeString • ${booking['bookingMode'] ?? 'On-demand'}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        displayStatus.toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor),
                      ),
                      if (booking['amount'] != null)
                        Text(
                          '₹${booking['amount']}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDetailRow('BOOKING ID', '#${(bookingId as String).substring(bookingId.length - 6).toUpperCase()}')),
                        Expanded(
                          child: InkWell(
                            onTap: booking['labourer'] != null ? () => _showWorkerProfile(booking['labourer']) : null,
                            child: _buildDetailRow('WORKER', booking['labourer']?['name'] ?? 'Not assigned'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('ADDRESS', '${booking['houseNumber'] ?? ''}, ${booking['address'] ?? 'No address'}'),
                    if (booking['landmark'] != null && booking['landmark'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Landmark: ${booking['landmark']}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                    if (booking['notes'] != null && booking['notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow('REQUIREMENTS', '${booking['notes']}'),
                    ],
                  ],
                ),
              ),
            // Indicator
            Container(
              width: 30,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkerProfile(dynamic worker) {
    final reviews = (worker['reviews'] as List<dynamic>?) ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 24),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: NetworkImage(
                        (worker['imageUrl'] != null && worker['imageUrl'].toString().isNotEmpty)
                          ? worker['imageUrl']
                          : 'https://randomuser.me/api/portraits/lego/1.jpg'
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(worker['name'] ?? 'Worker', style: GoogleFonts.baloo2(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          Text(worker['category'] ?? '', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              (worker['rating']?.toDouble() ?? 0.0) > 0 
                                  ? (worker['rating']?.toDouble() ?? 0.0).toStringAsFixed(1) 
                                  : 'New',
                              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text('Rating', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            Icon(Icons.work_rounded, color: Colors.blue.shade700, size: 28),
                            const SizedBox(height: 8),
                            Text('${worker['jobsCompleted'] ?? 0}', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Jobs Done', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Reviews
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Customer Reviews (${reviews.length})', style: GoogleFonts.baloo2(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: reviews.isEmpty 
                  ? Center(child: Text('No reviews yet', style: GoogleFonts.inter(color: AppTheme.textMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: reviews.length,
                      separatorBuilder: (context, index) => const Divider(height: 32),
                      itemBuilder: (context, index) {
                        final rev = reviews[index];
                        final rDate = rev['date'] != null ? DateTime.parse(rev['date']).toLocal() : DateTime.now();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(rev['userName'] ?? 'Customer', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text('${rDate.day}/${rDate.month}/${rDate.year}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(5, (i) => Icon(
                                i < (rev['rating'] ?? 0) ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 14, color: Colors.amber,
                              )),
                            ),
                            if (rev['comment'] != null && rev['comment'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(rev['comment'], style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                            ]
                          ],
                        );
                      },
                    ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}
