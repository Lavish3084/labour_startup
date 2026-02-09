import '../models/labourer.dart';
import '../models/service_category.dart';
import 'package:flutter/material.dart';

class DummyData {
  static final List<Labourer> labourers = [
    Labourer(
      id: '1',
      name: 'Ramesh Kumar',
      category: 'Plumber',
      rating: 4.8,
      jobsCompleted: 154,
      hourlyRate: 250.0,
      description:
          'Expert plumber with over 10 years of experience in fixing leaks, pipe installation, and bathroom fittings. Reliable and quick service.',
      imageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
      location: 'Andheri East, Mumbai',
      skills: ['Pipe Fitting', 'Leakage Repair', 'Basin Installation'],
      experienceYears: 12,
    ),
    Labourer(
      id: '2',
      name: 'Suresh Patel',
      category: 'Electrician',
      rating: 4.6,
      jobsCompleted: 98,
      hourlyRate: 300.0,
      description:
          'Certified electrician specializing in home wiring, switchboard repairs, and appliance installation. Safety is my priority.',
      imageUrl: 'https://randomuser.me/api/portraits/men/45.jpg',
      location: 'Borivali, Mumbai',
      skills: ['Wiring', 'Switchboard Repair', 'Fan Installation'],
      experienceYears: 8,
    ),
    Labourer(
      id: '3',
      name: 'Anita Devi',
      category: 'Cleaner',
      rating: 4.9,
      jobsCompleted: 210,
      hourlyRate: 150.0,
      description:
          'Professional home cleaner offering deep cleaning services. Punctual and thorough work guaranteed.',
      imageUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
      location: 'Juhu, Mumbai',
      skills: ['Deep Cleaning', 'Kitchen Cleaning', 'Floor Polishing'],
      experienceYears: 5,
    ),
    Labourer(
      id: '4',
      name: 'Mohammad Khan',
      category: 'Carpenter',
      rating: 4.7,
      jobsCompleted: 130,
      hourlyRate: 350.0,
      description:
          'Skilled carpenter for furniture repair, custom cabinets, and door installation. Quality woodwork at affordable rates.',
      imageUrl: 'https://randomuser.me/api/portraits/men/22.jpg',
      location: 'Bandra, Mumbai',
      skills: ['Furniture Repair', 'Door Installation', 'Polishing'],
      experienceYears: 15,
    ),
    Labourer(
      id: '5',
      name: 'Vikram Singh',
      category: 'Painter',
      rating: 4.5,
      jobsCompleted: 85,
      hourlyRate: 200.0,
      description:
          'House painter experienced in interior and exterior painting. Wall putty, texture painting, and clean finish.',
      imageUrl: 'https://randomuser.me/api/portraits/men/12.jpg',
      location: 'Dadar, Mumbai',
      skills: ['Wall Painting', 'Texture Design', 'Waterproofing'],
      experienceYears: 7,
    ),
    Labourer(
      id: '6',
      name: 'Sunita Sharma',
      category: 'Cook',
      rating: 4.8,
      jobsCompleted: 300,
      hourlyRate: 400.0, // per meal/visit approx
      description:
          'Experienced cook specializing in North Indian and Gujarati cuisine. Hygiene and taste are assured.',
      imageUrl: 'https://randomuser.me/api/portraits/women/68.jpg',
      location: 'Ghatkopar, Mumbai',
      skills: ['North Indian', 'Gujarati', 'Jain Food'],
      experienceYears: 10,
    ),
  ];

  static final List<ServiceCategory> serviceCategories = [
    ServiceCategory(
      name: 'Masonry',
      icon: Icons.foundation, // or Icons.home_work
      description: 'Construction and repair.',
    ),
    ServiceCategory(
      name: 'Garden',
      icon: Icons.yard,
      description: 'Gardening and landscaping.',
    ),
    ServiceCategory(
      name: 'Moving',
      icon: Icons.local_shipping,
      description: 'Moving services.',
    ),
    ServiceCategory(
      name: 'Loading',
      icon: Icons.inventory_2, // Icons.inventory_2 looks like packages
      description: 'Loading and unloading.',
    ),
    ServiceCategory(
      name: 'General',
      icon: Icons.engineering, // General labor
      description: 'General labor tasks.',
    ),
    ServiceCategory(
      name: 'Cleanup',
      icon: Icons.cleaning_services,
      description: 'Cleanup services.',
    ),
    ServiceCategory(
      name: 'Plumbing',
      icon: Icons.plumbing,
      description: 'Pipe installation and repairs.',
    ),
    ServiceCategory(
      name: 'Electric',
      icon: Icons.electrical_services,
      description: 'Electrical work.',
    ),
    ServiceCategory(
      name: 'Painting',
      icon: Icons.format_paint,
      description: 'Painting services.',
    ),
  ];
}
