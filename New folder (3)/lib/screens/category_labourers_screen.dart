import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/service_category.dart';
import '../models/labourer.dart';
import '../services/api_service.dart';
import '../widgets/labourer_card.dart';

class CategoryLabourersScreen extends StatefulWidget {
  final ServiceCategory category;

  const CategoryLabourersScreen({Key? key, required this.category})
    : super(key: key);

  @override
  State<CategoryLabourersScreen> createState() =>
      _CategoryLabourersScreenState();
}

class _CategoryLabourersScreenState extends State<CategoryLabourersScreen> {
  late Future<List<Labourer>> _labourersFuture;

  @override
  void initState() {
    super.initState();
    _labourersFuture = ApiService.getLabourers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          widget.category.name,
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Labourer>>(
        future: _labourersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No labourers found'));
          }

          final allLabourers = snapshot.data!;
          final filteredLabourers =
              allLabourers
                  .where((l) => l.category == widget.category.name)
                  .toList();

          if (filteredLabourers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No ${widget.category.name}s found nearby',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: filteredLabourers.length,
            itemBuilder: (context, index) {
              return LabourerCard(
                labourer: filteredLabourers[index],
                isHorizontal: false,
              );
            },
          );
        },
      ),
    );
  }
}
