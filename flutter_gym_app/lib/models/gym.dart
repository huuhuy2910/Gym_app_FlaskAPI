class Gym {
  final int id;
  final String name;
  final String address;
  final String imageUrl;
  final String description;
  final double pricePerDay;
  final double pricePerWeek;
  final double pricePerMonth;
  final String priceRange;
  final double rating;
  final int totalReviews; // Add totalReviews property
  List<String> gallery;

  Gym({
    required this.id,
    required this.name,
    required this.address,
    required this.imageUrl,
    required this.description,
    required this.pricePerDay,
    required this.pricePerWeek,
    required this.pricePerMonth,
    required this.priceRange,
    required this.rating,
    required this.totalReviews, // Initialize totalReviews
    required this.gallery,
  });

  factory Gym.fromJson(Map<String, dynamic> json) {
    return Gym(
      id: json['id'] ?? 0, // Default to 0 if null
      name: json['name'] ?? 'Unknown', // Default to 'Unknown' if null
      address: json['address'] ?? 'Unknown',
      imageUrl: json['image_url'] ?? '',
      description: json['description'] ?? '',
      pricePerDay: (json['price_per_day'] ?? 0).toDouble(),
      pricePerWeek: (json['price_per_week'] ?? 0).toDouble(),
      pricePerMonth: (json['price_per_month'] ?? 0).toDouble(),
      priceRange: json['price_range'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0, // Parse totalReviews
      gallery: List<String>.from(json['gallery'] ?? []),
    );
  }
}
