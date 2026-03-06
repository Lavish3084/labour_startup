import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/app_state_provider.dart';
import 'worker_home_screen.dart';

class WorkerDetailsScreen extends StatefulWidget {
  const WorkerDetailsScreen({Key? key}) : super(key: key);

  @override
  State<WorkerDetailsScreen> createState() => _WorkerDetailsScreenState();
}

class _WorkerDetailsScreenState extends State<WorkerDetailsScreen> {
  final _hourlyRateController = TextEditingController();
  final _experienceController = TextEditingController();
  final _locationController = TextEditingController();
  final _skillsController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppStateProvider>(context, listen: false).loadCategories();
    });
  }

  Future<void> _handleSubmit() async {
    if (_hourlyRateController.text.isEmpty ||
        _experienceController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _skillsController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'category': _selectedCategory,
      'hourlyRate': double.tryParse(_hourlyRateController.text) ?? 0,
      'experienceYears': int.tryParse(_experienceController.text) ?? 0,
      'location': _locationController.text,
      'skills': _skillsController.text, // Backend handles split
    };

    try {
      final success = await ApiService.updateWorkerProfile(data);
      if (success) {
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const WorkerHomeScreen()),
            (route) => false,
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Complete Your Profile',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us about your work',
                style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Category Dropdown
              Text(
                'Category',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Consumer<AppStateProvider>(
                builder: (context, appState, child) {
                  final categories = appState.categories;

                  if (categories.isEmpty && appState.isCategoriesLoading) {
                    return const Center(child: LinearProgressIndicator());
                  }

                  if (_selectedCategory == null && categories.isNotEmpty) {
                    _selectedCategory = categories.first.name;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        hint: const Text('Select Category'),
                        items:
                            categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category.name,
                                child: Text(
                                  category.name,
                                  style: GoogleFonts.inter(),
                                ),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCategory = newValue!;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Hourly Rate
              TextFormField(
                controller: _hourlyRateController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Hourly Rate (₹)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Experience
              TextFormField(
                controller: _experienceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Experience (Years)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location/City',
                  hintText: 'e.g., Andheri, Mumbai',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Skills
              TextFormField(
                controller: _skillsController,
                decoration: InputDecoration(
                  labelText: 'Skills (comma separated)',
                  hintText: 'e.g., Pipe Fitting, Repairs',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            'Save & Continue',
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
    );
  }
}
