import 'package:flutter/material.dart';

class ServiceCategory {
  final String name;
  final IconData icon;
  final String description;
  final List<String> supportedModes;

  ServiceCategory({
    required this.name,
    required this.icon,
    required this.description,
    required this.supportedModes,
  });
}
