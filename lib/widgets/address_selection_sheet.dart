import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../screens/location_search_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AddressSelectionSheet extends StatefulWidget {
  const AddressSelectionSheet({Key? key}) : super(key: key);

  @override
  State<AddressSelectionSheet> createState() => _AddressSelectionSheetState();
}

class _AddressSelectionSheetState extends State<AddressSelectionSheet> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().loadSavedLocations();
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = "Current Location";
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final components = [
          if (p.street != null && p.street!.isNotEmpty) p.street,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality,
          if (p.subAdministrativeArea != null &&
              p.subAdministrativeArea!.isNotEmpty)
            p.subAdministrativeArea,
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
            p.administrativeArea,
        ];
        address = components.join(", ");
      }

      if (mounted) {
        context.read<LocationProvider>().updateCurrentAddress(
          address: address,
          latitude: position.latitude,
          longitude: position.longitude,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchNewAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationSearchScreen()),
    );

    if (result != null && result is Map && mounted) {
      final String address = result['address'] ?? '';
      final double? lat = result['latitude'];
      final double? lon = result['longitude'];

      if (address.isNotEmpty) {
        // Offer to save the address
        final bool? wantToSave = await _showSaveDialog(address);

        if (wantToSave == true) {
          final labelController = TextEditingController();
          final houseController = TextEditingController();
          final landmarkController = TextEditingController();

          await showDialog<void>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Save Address'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: labelController,
                        decoration: const InputDecoration(
                          labelText: 'Label (e.g. Home, Work)',
                        ),
                      ),
                      TextField(
                        controller: houseController,
                        decoration: const InputDecoration(
                          labelText: 'House/Flat Number',
                        ),
                      ),
                      TextField(
                        controller: landmarkController,
                        decoration: const InputDecoration(
                          labelText: 'Landmark (Optional)',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (labelController.text.isNotEmpty) {
                          context.read<LocationProvider>().saveLocation(
                            SavedLocation(
                              id:
                                  DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                              label: labelController.text,
                              address: address,
                              houseNumber: houseController.text,
                              landmark: landmarkController.text,
                              latitude: lat ?? 0.0,
                              longitude: lon ?? 0.0,
                            ),
                          );

                          // Also update as current
                          context.read<LocationProvider>().updateCurrentAddress(
                            address: address,
                            houseNumber: houseController.text,
                            landmark: landmarkController.text,
                            latitude: lat,
                            longitude: lon,
                          );

                          Navigator.pop(context); // Close save dialog
                          Navigator.pop(this.context); // Close selection sheet
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
          );
          return; // Fix blank screen by preventing double pop
        }

        if (mounted) {
          context.read<LocationProvider>().updateCurrentAddress(
            address: address,
            latitude: lat,
            longitude: lon,
            houseNumber: '', // Defaulting for search/GPS if not saved
            landmark: '',
          );
          Navigator.pop(context);
        }
      }
    }
  }

  Future<bool?> _showSaveDialog(String address) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Save Address?'),
            content: Text('Would you like to save "$address" for future use?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes, Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final savedLocations = locationProvider.savedLocations;
    print(
      'AddressSelectionSheet: Building with ${savedLocations.length} saved locations',
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Location',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Bar Placeholder
          GestureDetector(
            onTap: _searchNewAddress,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    'Search for a new area...',
                    style: GoogleFonts.inter(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Current Location
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                _isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.my_location, color: Colors.blueAccent),
            title: Text(
              'Use Current Location',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
              ),
            ),
            subtitle: Text(
              'Enable GPS for better accuracy',
              style: GoogleFonts.inter(fontSize: 12),
            ),
            onTap: _isLoading ? null : _useCurrentLocation,
          ),
          const Divider(),

          // Saved Locations Section
          if (savedLocations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'SAVED LOCATIONS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: savedLocations.length,
                itemBuilder: (context, index) {
                  final loc = savedLocations[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.home_outlined),
                    title: Text(
                      loc.label,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${loc.houseNumber}, ${loc.address}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                    onTap: () {
                      context.read<LocationProvider>().updateCurrentAddress(
                        address: loc.address,
                        houseNumber: loc.houseNumber,
                        landmark: loc.landmark,
                        latitude: loc.latitude,
                        longitude: loc.longitude,
                      );
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ] else ...[
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No saved addresses yet',
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
