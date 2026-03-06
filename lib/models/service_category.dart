import 'package:flutter/material.dart';

class ServiceCategory {
  final String name;
  final IconData icon;
  final String description;
  final List<String> supportedModes;
  final double hourlyRate;
  final double dailyRate;

  ServiceCategory({
    required this.name,
    required this.icon,
    required this.description,
    required this.supportedModes,
    required this.hourlyRate,
    required this.dailyRate,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      name: json['name'],
      icon: _getIconFromName(json['iconName']),
      description: json['description'] ?? '',
      supportedModes: List<String>.from(json['supportedModes']),
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      dailyRate: (json['dailyRate'] as num).toDouble(),
    );
  }

  static IconData _getIconFromName(String name) {
    switch (name) {
      case 'foundation':
        return Icons.foundation;
      case 'yard':
        return Icons.yard;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'inventory_2':
        return Icons.inventory_2;
      case 'engineering':
        return Icons.engineering;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical_services':
        return Icons.electrical_services;
      case 'format_paint':
        return Icons.format_paint;
      default:
        return Icons.category;
    }
  }
}
