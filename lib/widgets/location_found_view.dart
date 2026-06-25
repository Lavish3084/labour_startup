import 'package:flutter/material.dart';
import 'location_map_circle.dart';
import 'location_address_labels.dart';

class LocationFoundView extends StatelessWidget {
  final String locality;
  final String fullAddress;
  final double latitude;
  final double longitude;

  const LocationFoundView({
    super.key,
    required this.locality,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LocationMapCircle(latitude: latitude, longitude: longitude),
        const SizedBox(height: 28),
        LocationAddressLabels(locality: locality, fullAddress: fullAddress),
      ],
    );
  }
}
