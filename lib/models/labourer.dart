class LabourerReview {
  final String? userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime date;

  LabourerReview({
    this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory LabourerReview.fromJson(Map<String, dynamic> json) {
    return LabourerReview(
      userId: json['user']?.toString(),
      userName: json['userName'] ?? 'Customer',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'date': date.toIso8601String(),
    };
  }
}

class Labourer {
  final String id;
  final String name;
  final String category;
  final double rating;
  final int jobsCompleted;
  final double hourlyRate;
  final String description;
  final String imageUrl;
  final String location;
  final List<String> skills;
  final int experienceYears;
  final String? upiId;
  final String? phoneNumber;
  final List<LabourerReview> reviews;

  Labourer({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.jobsCompleted,
    required this.hourlyRate,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.skills,
    required this.experienceYears,
    this.upiId,
    this.phoneNumber,
    this.reviews = const [],
  });

  factory Labourer.fromJson(Map<String, dynamic> json) {
    return Labourer(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      jobsCompleted: json['jobsCompleted'] ?? 0,
      hourlyRate: (json['hourlyRate'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      location: json['location'] ?? '',
      skills: List<String>.from(json['skills'] ?? []),
      experienceYears: json['experienceYears'] ?? 0,
      upiId: json['upiId'],
      phoneNumber: (json['user'] is Map) ? json['user']['phoneNumber'] : json['phoneNumber'],
      reviews: json['reviews'] != null
          ? (json['reviews'] as List)
              .map((item) => LabourerReview.fromJson(item))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'rating': rating,
      'jobsCompleted': jobsCompleted,
      'hourlyRate': hourlyRate,
      'description': description,
      'imageUrl': imageUrl,
      'location': location,
      'skills': skills,
      'experienceYears': experienceYears,
      'upiId': upiId,
      'phoneNumber': phoneNumber,
      'reviews': reviews.map((r) => r.toJson()).toList(),
    };
  }
}
