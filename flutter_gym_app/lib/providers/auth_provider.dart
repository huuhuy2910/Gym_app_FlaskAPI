import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';
// Import for logging
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  User? _user;

  AuthProvider() {
    _initializeAuth(); // Automatically attempt auto-login on initialization
  }

  Future<void> _initializeAuth() async {
    print('Initializing AuthProvider and attempting auto-login'); // Debug log
    await tryAutoLogin();
  }

  bool get isAuth => _user != null;
  User? get user => _user;

  List<int> _favourite = [];

  List<int> get favourite => _favourite;

  Future<void> login(
      String username, String password, String phone, String address) async {
    final url = Uri.parse('http://localhost:5000/login');
    try {
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'username': username,
            'password': password,
            'phone': phone,
            'address': address
          }));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        _user = User(
          id: responseData['id'],
          username: responseData['username'],
          email: responseData['email'],
          phone:
              responseData['phone'] ?? '', // Provide a default value if missing
          address: responseData['address'] ??
              '', // Provide a default value if missing
        );

        // Save user ID to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final isSaved = await prefs.setInt(
            'userId', responseData['id']); // Save under 'userId'
        if (isSaved) {
          print(
              'User ID successfully saved to SharedPreferences: ${responseData['id']}'); // Debug log
        } else {
          print('Failed to save User ID to SharedPreferences'); // Debug log
        }

        // Fetch the favorite list after login
        await fetchFavourite(responseData['id']);

        notifyListeners(); // Notify listeners about the updated user
      } else {
        throw Exception(json.decode(response.body)['message']);
      }
    } catch (error) {
      print('Error during login: $error');
      rethrow;
    }
  }

  Future<void> register(String username, String email, String password,
      {String? phone, String? address}) async {
    final url = Uri.parse('http://localhost:5000/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
        'phone': phone ?? '',
        'address': address ?? '',
      }),
    );

    if (response.statusCode == 409) {
      throw Exception('Username or email already exists!');
    } else if (response.statusCode != 201) {
      throw Exception('Registration failed!');
    } else {
      notifyListeners(); // Notify listeners about the updated state
    }
  }

  Future<void> fetchProfile(int userId) async {
    final url = Uri.parse('http://localhost:5000/profile?user_id=$userId');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      _user = User.fromJson(responseData);

      notifyListeners(); // Notify listeners about the updated user
    } else {
      throw Exception('Failed to fetch profile!');
    }
  }

  Future<void> updateProfile({
    required int userId,
    required String? username,
    required String? email,
    required String phone, // Made non-nullable
    required String address, // Made non-nullable
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId =
        prefs.getInt('userId'); // Retrieve user ID from SharedPreferences

    if (storedUserId == null || storedUserId <= 0) {
      throw Exception('Invalid user ID');
    }

    final url = Uri.parse('http://127.0.0.1:5000/profile');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': storedUserId, // Use the stored user ID
          'username': username,
          'email': email,
          'phone': phone,
          'address': address,
        }),
      );

      if (response.statusCode == 200) {
        // Fetch the updated user data from the backend
        final responseData = json.decode(response.body);
        _user = User.fromJson(responseData); // Update the local user state
        notifyListeners(); // Notify listeners about the updated user
      } else if (response.statusCode == 404) {
        throw Exception('User not found!');
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ?? 'Failed to update profile');
      }
    } catch (error) {
      print('Error updating profile: $error'); // Debug log
      throw Exception('Failed to update profile');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId'); // Remove user ID from SharedPreferences
    _user = null;
    print(
        'User logged out and user ID removed from SharedPreferences'); // Debug log
    notifyListeners(); // Notify listeners about the cleared user
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userId')) {
      print('No user ID found in SharedPreferences'); // Debug log
      return;
    }

    final userId = prefs.getInt('userId');
    if (userId == null || userId <= 0) {
      print('Invalid user ID in SharedPreferences: $userId'); // Debug log
      return;
    }

    print(
        'Loaded current user ID from SharedPreferences: $userId'); // Debug log

    // Fetch user profile using the stored user ID
    try {
      await fetchProfile(userId); // Fetch and set the user profile
      print('Auto-logged in with user ID: $userId'); // Debug log
    } catch (error) {
      print('Error during auto-login: $error'); // Debug log
      _user = null; // Clear user data if fetching profile fails
    }

    notifyListeners(); // Notify listeners about the updated user state
  }

  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    print('Retrieved user ID from SharedPreferences: $userId'); // Debug log
    return userId;
  }

  Future<void> fetchFavourite(int userId) async {
    if (userId <= 0) {
      print('Invalid user ID: $userId'); // Debug log
      return; // Avoid resetting the favorites list unnecessarily
    }

    final url = Uri.parse('http://localhost:5000/favourite?user_id=$userId');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Fetched favourite data: $responseData'); // Debug log
        _favourite = List<int>.from(responseData.toSet()); // Remove duplicates
        notifyListeners();
      } else {
        throw Exception('Failed to fetch favourite!');
      }
    } catch (error) {
      print('Error fetching favourite: $error');
    }
  }

  Future<void> refreshFavourites() async {
    final userId = await getCurrentUserId();
    if (userId != null && userId > 0) {
      await fetchFavourite(userId);
    }
  }

  Future<void> addToFavourite(int gymId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId =
        prefs.getInt('userId'); // Retrieve user ID from SharedPreferences

    if (userId == null || userId <= 0) {
      print('Invalid user ID: $userId'); // Debug log
      throw Exception('User not logged in');
    }

    if (_favourite.contains(gymId)) {
      print('Gym $gymId is already in favourites'); // Debug log
      return; // Avoid adding duplicates
    }

    final url = Uri.parse('http://localhost:5000/favourite');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId, 'gym_id': gymId}),
      );

      if (response.statusCode == 201) {
        _favourite.add(gymId);
        _favourite = _favourite.toSet().toList(); // Ensure no duplicates
        notifyListeners();
      } else if (response.statusCode == 400) {
        final responseData = json.decode(response.body);
        if (responseData['message'] == 'Gym is already in favorites') {
          print(
              'Gym $gymId is already in favorites for user $userId'); // Debug log
        } else {
          throw Exception('Failed to add to favourite!');
        }
      } else {
        throw Exception('Failed to add to favourite!');
      }
    } catch (error) {
      print('Error adding to favourite: $error');
      throw Exception('Error adding to favourite');
    }
  }

  Future<void> removeFromFavourite(int gymId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId =
        prefs.getInt('userId'); // Retrieve user ID from SharedPreferences

    if (userId == null || userId <= 0) {
      print('Invalid user ID: $userId'); // Debug log
      throw Exception('User not logged in');
    }

    final url = Uri.parse('http://localhost:5000/favourite');
    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId, 'gym_id': gymId}),
      );

      if (response.statusCode == 200) {
        _favourite.remove(gymId);
        notifyListeners();
      } else {
        throw Exception('Failed to remove from favourite!');
      }
    } catch (error) {
      print('Error removing from favourite: $error');
      throw Exception('Error removing from favourite');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final userId = await getCurrentUserId();
    if (userId == null || userId <= 0) {
      throw Exception('User not logged in');
    }

    final url = Uri.parse('http://localhost:5000/change_password');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      if (response.statusCode == 200) {
        print('Password changed successfully'); // Debug log
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(
            errorResponse['message'] ?? 'Failed to change password');
      }
    } catch (error) {
      print('Error changing password: $error'); // Debug log
      throw Exception('Failed to change password');
    }
  }
}
