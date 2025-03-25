import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/gym_provider.dart';
import 'gym_details_page.dart';
import '../widgets/bottom_nav_bar.dart';
import '../theme/theme_colors.dart'; // Import ThemeColors
import '../providers/auth_provider.dart'; // Import AuthProvider
import '../widgets/gym_card.dart';

class GymsListScreen extends StatelessWidget {
  const GymsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###'); // Initialize formatter
    // ignore: unused_local_variable
    final authProvider = Provider.of<AuthProvider>(context);

    // Helper function to format price ranges
    // ignore: unused_element
    String formatPriceRange(String priceRange) {
      final regex = RegExp(r'(\d+(\.\d+)?)'); // Match numeric values
      final matches =
          regex.allMatches(priceRange).map((m) => m.group(0)).toList();

      if (matches.length >= 2) {
        // Format the first and last numeric values for "1 ngày" and "1 tháng"
        final minPrice = formatter.format(double.parse(matches.first!));
        final maxPrice = formatter.format(double.parse(matches.last!));
        return 'từ $minPrice đ 1 ngày đến $maxPrice đ 1 tháng';
      }
      return priceRange; // Return original if no valid range found
    }

    return Scaffold(
      // ignore: deprecated_member_use
      backgroundColor: ThemeColors.grey.withOpacity(0.1),
      appBar: AppBar(
        automaticallyImplyLeading: false, // Bỏ nút quay lại
        title: const Text(
          'Trang chủ',
          style: TextStyle(
            color: ThemeColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ThemeColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: ThemeColors.black),
      ),
      body: Column(
        children: [
          // Banner section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: ThemeColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào mừng bạn đến với Gym Finder!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Khám phá các phòng gym tốt nhất gần bạn và bắt đầu hành trình tập luyện ngay hôm nay.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future:
                  Provider.of<GymProvider>(context, listen: false).fetchGyms(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return Consumer<GymProvider>(
                    builder: (context, gymProvider, child) {
                      if (gymProvider.gyms.isEmpty) {
                        return const Center(
                            child: Text('Không có phòng gym nào.'));
                      }
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: gymProvider.gyms.length,
                          itemBuilder: (context, index) {
                            final gym = gymProvider.gyms[index];
                            return GymCard(
                              gym: gym,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                            secondaryAnimation) =>
                                        GymDetailsPage(gymId: gym.id),
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = Offset(0.0, 1.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeInOut;

                                      var tween = Tween(begin: begin, end: end)
                                          .chain(CurveTween(curve: curve));
                                      var offsetAnimation =
                                          animation.drive(tween);

                                      return SlideTransition(
                                          position: offsetAnimation,
                                          child: child);
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0),
    );
  }
}
