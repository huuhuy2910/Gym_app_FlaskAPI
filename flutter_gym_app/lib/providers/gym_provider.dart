import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/gym.dart';
import '../models/comment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GymProvider with ChangeNotifier {
  List<Gym> _gyms = [];
  Gym? _gymDetails;
// Store comments per gym
  Map<int, bool> _fetchingComments = {}; // Track fetching state
  Map<int, List<Comment>> _comments = {}; // Store comments by gymId

  List<int> _favoriteGyms = [];

  int? _currentUserId; // Store the current user ID

  List<Gym> get gyms => _gyms;
  Gym? get gymDetails => _gymDetails;

  List<int> get favoriteGyms => _favoriteGyms;

  int? get currentUserId => _currentUserId;

  List<Comment> getCommentsForGym(int gymId) {
    return _comments[gymId] ?? [];
  }

  bool isFetchingComments(int gymId) {
    return _fetchingComments[gymId] ?? false;
  }

  Future<void> fetchGyms() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:5000/gyms'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _gyms = data.map((gym) => Gym.fromJson(gym)).toList();
        notifyListeners();
      } else {
        throw Exception(
            'Failed to load gyms. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching gyms: $error');
      throw Exception('Failed to load gyms');
    }
  }

  Future<void> fetchGymDetails(int gymId) async {
    try {
      final response =
          await http.get(Uri.parse('http://127.0.0.1:5000/gyms/$gymId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _gymDetails = Gym.fromJson(data);
        notifyListeners();
      } else {
        _gymDetails = null; // Set to null if response is invalid
        notifyListeners();
        throw Exception(
            'Failed to load gym details. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching gym details: $error');
      _gymDetails = null; // Handle error by resetting gymDetails
      throw Exception('Failed to load gym details. Error: $error');
    }
  }

  Future<void> fetchGymComments(int gymId) async {
    if (_fetchingComments[gymId] == true) return; // Avoid duplicate fetches

    _fetchingComments[gymId] = true;
    notifyListeners();

    try {
      final response = await http
          .get(Uri.parse('http://127.0.0.1:5000/gyms/$gymId/comments'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _comments[gymId] =
            data.map((comment) => Comment.fromJson(comment)).toList();
      } else {
        throw Exception(
            'Failed to load comments. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching comments for gym $gymId: $error');
      _comments[gymId] = [];
      throw Exception('Failed to load comments');
    }

    _fetchingComments[gymId] = false;
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favoriteGyms =
        prefs.getStringList('favoriteGyms')?.map(int.parse).toList() ?? [];
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('currentUserId'); // Retrieve user ID
    print(
        'Loaded current user ID from SharedPreferences: $_currentUserId'); // Debug log
    notifyListeners();
  }

  Future<void> fetchFavorites() async {
    if (_currentUserId == null) {
      throw Exception('No user is currently logged in');
    }
    final url =
        Uri.parse('http://127.0.0.1:5000/favorites?user_id=$_currentUserId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _favoriteGyms = data.cast<int>();
        print('Fetched favorite gyms: $_favoriteGyms'); // Debug log
        notifyListeners();
      } else {
        throw Exception('Failed to fetch favorites for user $_currentUserId');
      }
    } catch (error) {
      print('Error fetching favorites for user $_currentUserId: $error');
    }
  }

  Future<void> toggleFavorite(int gymId) async {
    if (_currentUserId == null) {
      print('Error: No user is currently logged in'); // Debug log
      throw Exception('No user is currently logged in');
    }

    final isCurrentlyFavorite = _favoriteGyms.contains(gymId);

    // Optimistically update the UI
    if (isCurrentlyFavorite) {
      _favoriteGyms.remove(gymId);
    } else {
      _favoriteGyms.add(gymId);
    }
    notifyListeners();

    final url = Uri.parse('http://127.0.0.1:5000/favorites');
    final payload = {
      'user_id': _currentUserId,
      'gym_id': gymId,
      'action': isCurrentlyFavorite ? 'remove' : 'add',
    };
    print('Sending payload to server: $payload'); // Debug log

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 400) {
        final responseData = json.decode(response.body);
        if (responseData['message'] == 'Gym is already in favorites') {
          print('Server response: Gym is already in favorites'); // Debug log
          // Do nothing, as the gym is already in favorites
          return;
        }
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Server response: ${response.body}'); // Debug log
        // Revert the change if the server request fails
        if (isCurrentlyFavorite) {
          _favoriteGyms.add(gymId);
        } else {
          _favoriteGyms.remove(gymId);
        }
        notifyListeners();
        throw Exception(
            'Failed to update favorite status for user $_currentUserId');
      }
    } catch (error) {
      print('Error toggling favorite for user $_currentUserId: $error');
      // Revert the change in case of an error
      if (isCurrentlyFavorite) {
        _favoriteGyms.add(gymId);
      } else {
        _favoriteGyms.remove(gymId);
      }
      notifyListeners();
      rethrow; // Re-throw the error for further handling
    }
  }

  bool isFavorite(int gymId) {
    return _favoriteGyms.contains(gymId);
  }

  Future<void> submitComment(
      int gymId, int rating, String comment, int userId) async {
    final url = Uri.parse('http://127.0.0.1:5000/reviews');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId, // Include user_id in the request body
          'gym_id': gymId,
          'rating': rating,
          'comment': comment,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception(
            'Failed to submit comment. Status code: ${response.statusCode}');
      }

      // Fetch updated comments after submission
      await fetchGymComments(gymId);
    } catch (error) {
      print('Error submitting comment: $error');
      throw Exception('Failed to submit comment. Error: $error');
    }
  }
}
