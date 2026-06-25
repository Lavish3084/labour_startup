import 'package:flutter/material.dart';

import 'service_category.dart';

class CartItem {
  final String id;
  final ServiceCategory category;
  final int durationMinutes;
  final bool isInstant;
  final DateTime? scheduledDate;
  final TimeOfDay? scheduledTime;

  // Instructions
  int workerCount;
  String? workType;
  List<String> taskImagesBase64;
  String? taskAudioBase64;
  String? taskNotes;

  CartItem({
    String? id,
    required this.category,
    required this.durationMinutes,
    required this.isInstant,
    this.scheduledDate,
    this.scheduledTime,
    this.workerCount = 1,
    this.workType,
    List<String>? taskImagesBase64,
    this.taskAudioBase64,
    this.taskNotes,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       taskImagesBase64 = taskImagesBase64 ?? [];

  double get totalPrice {
    final hours = durationMinutes / 60.0;
    return category.hourlyRate * hours * workerCount;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.toJson(),
      'durationMinutes': durationMinutes,
      'isInstant': isInstant,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'scheduledTime': scheduledTime != null ? '${scheduledTime!.hour}:${scheduledTime!.minute}' : null,
      'workerCount': workerCount,
      'workType': workType,
      'taskImagesBase64': taskImagesBase64,
      'taskAudioBase64': taskAudioBase64,
      'taskNotes': taskNotes,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parsedTime;
    if (json['scheduledTime'] != null) {
      final parts = json['scheduledTime'].toString().split(':');
      if (parts.length == 2) {
        parsedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }

    return CartItem(
      id: json['id'],
      category: ServiceCategory.fromJson(json['category']),
      durationMinutes: json['durationMinutes'],
      isInstant: json['isInstant'],
      scheduledDate: json['scheduledDate'] != null ? DateTime.parse(json['scheduledDate']) : null,
      scheduledTime: parsedTime,
      workerCount: json['workerCount'] ?? 1,
      workType: json['workType'],
      taskImagesBase64: List<String>.from(json['taskImagesBase64'] ?? []),
      taskAudioBase64: json['taskAudioBase64'],
      taskNotes: json['taskNotes'],
    );
  }
}
