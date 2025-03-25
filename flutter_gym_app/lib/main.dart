import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/gym_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/search_provider.dart'; // Import SearchProvider
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final gymProvider = GymProvider();
  await gymProvider.loadCurrentUser(); // Ensure user ID is loaded
  runApp(MyApp(gymProvider: gymProvider));
}

class MyApp extends StatelessWidget {
  final GymProvider gymProvider;

  MyApp({required this.gymProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: gymProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()), // Add this
        // Removed FavoritesProvider
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primaryColor: Colors.black,
              scaffoldBackgroundColor: Colors.white,
              iconTheme:
                  IconThemeData(color: Colors.black), // Set icons to black
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                iconTheme:
                    IconThemeData(color: Colors.black), // Black icons in AppBar
              ),
            ),
            home: SplashScreen(), // Start with SplashScreen
            routes: {
              '/auth': (ctx) => AuthScreen(),
              '/profile': (ctx) => ProfileScreen(),
              '/gyms': (ctx) => GymsListScreen(),
              '/search': (ctx) => SearchScreen(), // Add SearchScreen route
            },
          );
        },
      ),
    );
  }
}
