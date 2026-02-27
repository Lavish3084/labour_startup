import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({Key? key}) : super(key: key);

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  late Future<List<dynamic>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  void _fetchBookings() {
    setState(() {
      _bookingsFuture = ApiService.getWorkerBookings();
    });
  }

  Future<void> _updateStatus(String bookingId, String status) async {
    try {
      bool success;
      if (status == 'claim') {
        success = await ApiService.claimBooking(bookingId);
      } else {
        success = await ApiService.updateBookingStatus(bookingId, status);
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status == 'claim'
                    ? 'Job Claimed Successfully!'
                    : 'Booking ${status.toUpperCase()}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _fetchBookings(); // Refresh list
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Action failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openMap(String? address, double? lat, double? lng) async {
    Uri url;
    if (lat != null && lng != null) {
      // Use coordinates if available
      url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
      );
    } else if (address != null && address.isNotEmpty) {
      // Fallback to address search
      url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}",
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location available for this job')),
      );
      return;
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Worker Dashboard',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await ApiService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.engineering,
                      size: 64,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome, Worker!',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No job requests yet.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final bookings = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final user = booking['user'];
              final status = booking['status'] as String;
              final date = DateTime.parse(booking['date']);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          user['name'] ?? 'Unknown User',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                status == 'pending'
                                    ? Colors.orange.withOpacity(0.2)
                                    : status == 'confirmed'
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: GoogleFonts.inter(
                              color:
                                  status == 'pending'
                                      ? Colors.orange[800]
                                      : status == 'confirmed'
                                      ? Colors.green[800]
                                      : Colors.grey[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${date.day}/${date.month}/${date.year}',
                          style: GoogleFonts.inter(color: Colors.black87),
                        ),
                      ],
                    ),
                    if (booking['notes'] != null &&
                        booking['notes'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.note, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking['notes'],
                              style: GoogleFonts.inter(color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (booking['address'] != null &&
                        booking['address'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking['address'] ?? 'No Address',
                                  style: GoogleFonts.inter(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (booking['houseNumber'] != null &&
                                    booking['houseNumber'].isNotEmpty)
                                  Text(
                                    'Flat/House: ${booking['houseNumber']}',
                                    style: GoogleFonts.inter(
                                      color: Colors.black87,
                                    ),
                                  ),
                                if (booking['landmark'] != null &&
                                    booking['landmark'].isNotEmpty)
                                  Text(
                                    'Landmark: ${booking['landmark']}',
                                    style: GoogleFonts.inter(
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap:
                                () => _openMap(
                                  booking['address'],
                                  booking['latitude']?.toDouble(),
                                  booking['longitude']?.toDouble(),
                                ),
                            child: const Text(
                              'View on Maps',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Action Buttons (Placeholder for now)
                    if (status == 'pending')
                      booking['labourer'] == null
                          ? // Unassigned Job (Broadcast) -> Claim Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  () => _updateStatus(
                                    booking['_id'],
                                    'claim', // Special status for internal handler or new api
                                  ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Claim Job'),
                            ),
                          )
                          : // Assigned to me -> Accept/Reject
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      () => _updateStatus(
                                        booking['_id'],
                                        'cancelled',
                                      ),
                                  child: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      () => _updateStatus(
                                        booking['_id'],
                                        'confirmed',
                                      ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Accept'),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
