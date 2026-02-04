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
    );
  }
}
