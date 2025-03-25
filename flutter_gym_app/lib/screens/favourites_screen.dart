import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/gym_provider.dart';
import 'gym_details_page.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/gym_card.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  _FavouritesScreenState createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  Future<void>? _favouriteFuture;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;

    if (userId != null) {
      _favouriteFuture = authProvider.fetchFavourite(userId);
    } else {
      // Refresh favorites if user ID is not available
      _favouriteFuture = authProvider.refreshFavourites();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final gymProvider = Provider.of<GymProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Bỏ nút quay lại
        title: const Text(
          'Phòng Gym Yêu Thích',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder(
        future: _favouriteFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Error loading favourites: ${snapshot.error}'); // Debug log
            return const Center(
                child: Text('Đã xảy ra lỗi khi tải danh sách yêu thích.'));
          }

          if (authProvider.favourite.isEmpty) {
            return const Center(child: Text('Danh sách yêu thích trống.'));
          }

          final favouriteGyms = gymProvider.gyms
              .where((gym) => authProvider.favourite.contains(gym.id))
              .toList();

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.8,
              ),
              itemCount: favouriteGyms.length,
              itemBuilder: (context, index) {
                final gym = favouriteGyms[index];
                return GymCard(
                  gym: gym,
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            GymDetailsPage(gymId: gym.id),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;

                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          var offsetAnimation = animation.drive(tween);

                          return SlideTransition(
                              position: offsetAnimation, child: child);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 2),
    );
  }
}
