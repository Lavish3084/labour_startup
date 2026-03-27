import 'package:flutter/material.dart';

class ServiceCategory {
  final String name;
  final IconData icon;
  final String iconName;
  final String description;
  final List<String> supportedModes;
  final double hourlyRate;
  final double dailyRate;
  final double minHourlyRate;
  final double maxHourlyRate;

  ServiceCategory({
    required this.name,
    required this.icon,
    this.iconName = 'category',
    required this.description,
    required this.supportedModes,
    required this.hourlyRate,
    required this.dailyRate,
    required this.minHourlyRate,
    required this.maxHourlyRate,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    final iconName = json['iconName'] ?? 'category';
    return ServiceCategory(
      name: json['name'],
      icon: _getIconFromName(iconName),
      iconName: iconName,
      description: json['description'] ?? '',
      supportedModes: List<String>.from(json['supportedModes']),
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      dailyRate: (json['dailyRate'] as num).toDouble(),
      minHourlyRate: (json['minHourlyRate'] as num? ?? 0).toDouble(),
      maxHourlyRate: (json['maxHourlyRate'] as num? ?? 1000).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'iconName': iconName,
      'description': description,
      'supportedModes': supportedModes,
      'hourlyRate': hourlyRate,
      'dailyRate': dailyRate,
      'minHourlyRate': minHourlyRate,
      'maxHourlyRate': maxHourlyRate,
    };
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
