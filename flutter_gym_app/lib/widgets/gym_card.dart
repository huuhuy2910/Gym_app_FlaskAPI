import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gym.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart'; // Add this import

class GymCard extends StatelessWidget {
  final Gym gym;
  final VoidCallback onTap;

  const GymCard({required this.gym, required this.onTap, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
// Helper function to format price ranges
    String formatPriceRange(String priceRange) {
      final regex = RegExp(r'(\d+(\.\d+)?)'); // Match numeric values
      final matches =
          regex.allMatches(priceRange).map((m) => m.group(0)).toList();

      if (matches.length >= 2) {
        // Format the first and last numeric values for "1 ngày" and "1 tháng"
        final minPrice = formatter.format(double.parse(matches.first!));
        final maxPrice = formatter.format(double.parse(matches.last!));
        return 'từ $minPrice VNĐ 1 ngày đến $maxPrice VNĐ 1 tháng';
      }
      return priceRange; // Return original if no valid range found
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio:
                        16 / 10, // Adjusted aspect ratio to reduce white space
                    child: gym.imageUrl.isNotEmpty
                        ? Image.network(
                            gym.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: Colors.grey[300],
                              child:
                                  const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gym.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        gym.address,
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Giá: ${formatPriceRange(gym.priceRange)}',
                        style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${gym.rating.toStringAsFixed(2)} (${gym.totalReviews} đánh giá)',
                            style: const TextStyle(color: Colors.black, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return IconButton(
                    icon: Icon(
                      authProvider.favourite.contains(gym.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: authProvider.favourite.contains(gym.id)
                          ? Colors.red
                          : Colors.grey,
                    ),
                    onPressed: () async {
                      if (authProvider.favourite.contains(gym.id)) {
                        await authProvider.removeFromFavourite(gym.id);
                      } else {
                        await authProvider.addToFavourite(gym.id);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
