import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/labourer.dart';
import '../services/api_service.dart';
import '../data/dummy_data.dart';
import '../models/service_category.dart';

class LabourerDetailScreen extends StatefulWidget {
  final Labourer labourer;

  const LabourerDetailScreen({Key? key, required this.labourer})
    : super(key: key);

  @override
  State<LabourerDetailScreen> createState() => _LabourerDetailScreenState();
}

class _LabourerDetailScreenState extends State<LabourerDetailScreen> {
  bool _isLoading = false;
  late String _selectedMode;
  int _numberOfHours = 1;

  @override
  void initState() {
    super.initState();
    // Find category to get default modes
    final category = DummyData.serviceCategories.firstWhere(
      (c) => c.name == widget.labourer.category,
      orElse:
          () => ServiceCategory(
            name: widget.labourer.category,
            icon: Icons.work,
            description: '',
            supportedModes: ['Hourly'],
          ),
    );
    _selectedMode = category.supportedModes.first;
  }

  Future<void> _showBookingDialog() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate != null && mounted) {
      final notesController = TextEditingController();

      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(
                'Confirm Booking',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Book ${widget.labourer.name} on ${pickedDate.day}/${pickedDate.month}/${pickedDate.year}?',
                    style: GoogleFonts.inter(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Booking Type',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  StatefulBuilder(
                    builder: (context, setDialogState) {
                      final category = DummyData.serviceCategories.firstWhere(
                        (c) => c.name == widget.labourer.category,
                        orElse:
                            () => ServiceCategory(
                              name: widget.labourer.category,
                              icon: Icons.work,
                              description: '',
                              supportedModes: ['Hourly'],
                            ),
                      );
                      return Row(
                        children:
                            category.supportedModes.map((mode) {
                              final isSelected = _selectedMode == mode;
                              return Expanded(
                                child: ChoiceChip(
                                  label: Text(
                                    mode,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.black,
                                      fontSize: 12,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) {
                                      setDialogState(() {
                                        _selectedMode = mode;
                                      });
                                      setState(() {
                                        _selectedMode = mode;
                                      });
                                    }
                                  },
                                  selectedColor: Colors.blueAccent,
                                  backgroundColor: Colors.grey[200],
                                ),
                              );
                            }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedMode == 'Hourly') ...[
                    Text(
                      'Duration (Hours)',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    StatefulBuilder(
                      builder: (context, setDialogState) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$_numberOfHours ${_numberOfHours == 1 ? 'Hour' : 'Hours'}',
                              style: GoogleFonts.inter(fontSize: 16),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    if (_numberOfHours > 1) {
                                      setDialogState(() {
                                        _numberOfHours--;
                                      });
                                      setState(() {
                                        _numberOfHours--;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                IconButton(
                                  onPressed: () {
                                    if (_numberOfHours < 24) {
                                      setDialogState(() {
                                        _numberOfHours++;
                                      });
                                      setState(() {
                                        _numberOfHours++;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close dialog
                    _createBooking(pickedDate, notesController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
      );
    }
  }

  Future<void> _createBooking(DateTime date, String notes) async {
    setState(() => _isLoading = true);
    try {
      final success = await ApiService.createBooking(
        labourerId: widget.labourer.id,
        category: widget.labourer.category,
        date: date,
        bookingMode: _selectedMode,
        numberOfHours: _selectedMode == 'Hourly' ? _numberOfHours : null,
        notes: notes,
        address:
            null, // Specific worker booking usually uses current location or user profile default
        houseNumber: null,
        landmark: null,
        latitude: null,
        longitude: null,
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking Confirmed!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Go back to Home
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking Failed'),
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Clear App Bar with Image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: Colors.blueAccent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.network(
                    widget.labourer.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.person,
                              size: 100,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                  ),
                ),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                    onPressed: () {},
                  ),
                ],
              ),

              // Content Body
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  transform: Matrix4.translationValues(0, -20, 0),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.labourer.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.labourer.category,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.labourer.rating.toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Experience',
                              '${widget.labourer.experienceYears} Years',
                            ),
                            _buildVerticalDivider(),
                            _buildStatItem(
                              'Jobs',
                              '${widget.labourer.jobsCompleted}+',
                            ),
                            _buildVerticalDivider(),
                            _buildStatItem(
                              'Rate',
                              '₹${widget.labourer.hourlyRate.toInt()}/hr',
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // About Section
                        Text(
                          'About',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.labourer.description,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Location
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.blueAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.labourer.location,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Skills
                        Text(
                          'Skills',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              widget.labourer.skills.map((skill) {
                                return Chip(
                                  label: Text(skill),
                                  backgroundColor: Colors.grey[100],
                                  labelStyle: GoogleFonts.inter(
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                );
                              }).toList(),
                        ),

                        const SizedBox(height: 100), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Price',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '₹${widget.labourer.hourlyRate.toInt()}/hr',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _showBookingDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _isLoading ? 'Processing...' : 'Book Now',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.grey[300]);
  }
}
