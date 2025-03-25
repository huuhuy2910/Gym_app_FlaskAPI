import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/gym.dart';

class SearchProvider with ChangeNotifier {
  Future<List<Gym>> searchAndFilterGyms({
    String? name,
    String? location,
    double? minPrice,
    double? maxPrice,
    String? priceType,
  }) async {
    final queryParams = {
      if (name != null && name.isNotEmpty) 'name': name.trim(),
      if (location != null && location.isNotEmpty) 'location': location.trim(),
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
      if (priceType != null) 'price_type': priceType,
    };

    final uri =
        Uri.http('127.0.0.1:5000', '/gyms/search_and_filter', queryParams);
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((gymJson) => Gym.fromJson(gymJson)).toList();
      } else {
        print('Server error: ${response.body}');
        throw Exception(
            'Failed to fetch gyms. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching gyms with filters: $error');
      throw Exception('Failed to fetch gyms');
    }
  }
}
