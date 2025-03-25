// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Add this import
import 'package:shared_preferences/shared_preferences.dart'; // Add this import
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../providers/gym_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../providers/auth_provider.dart';

class GymDetailsPage extends StatefulWidget {
  final int gymId;

  const GymDetailsPage({super.key, required this.gymId});

  @override
  _GymDetailsPageState createState() => _GymDetailsPageState();
}

class _GymDetailsPageState extends State<GymDetailsPage> {
  bool _showAllComments = false; // Track whether to show all comments

  void _showImageGallery(
      BuildContext context, List<String> gallery, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Thư viện ảnh',
                style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: PhotoViewGallery.builder(
            itemCount: gallery.length,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(gallery[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            pageController: PageController(initialPage: initialIndex),
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###'); // Initialize formatter
    final gymProvider = Provider.of<GymProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Helper function to format price ranges
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Chi tiết phòng gym',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: FutureBuilder(
        future: Provider.of<GymProvider>(context, listen: false)
            .fetchGymDetails(widget.gymId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final gym = Provider.of<GymProvider>(context).gymDetails;
            if (gym == null) {
              return const Center(child: Text('Gym details not available.'));
            }
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(gym.imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(gym.name,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                              const SizedBox(height: 8),
                              Text(gym.address,
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      'Giá: ${formatPriceRange(gym.priceRange)}',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green)),
                                  IconButton(
                                    icon: Icon(
                                      authProvider.favourite
                                              .contains(widget.gymId)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: authProvider.favourite
                                              .contains(widget.gymId)
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                    onPressed: () async {
                                      if (authProvider.favourite
                                          .contains(widget.gymId)) {
                                        await authProvider
                                            .removeFromFavourite(widget.gymId);
                                      } else {
                                        await authProvider
                                            .addToFavourite(widget.gymId);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text('Mô tả:',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                              const SizedBox(height: 8),
                              Text(gym.description,
                                  style: const TextStyle(color: Colors.black)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Text('Đánh giá trung bình:',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: List.generate(
                                      gym.rating.round(),
                                      (index) => const Icon(Icons.star,
                                          color: Colors.amber, size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('(${gym.rating.toStringAsFixed(1)} sao)',
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.grey)),
                                  const SizedBox(width: 8),
                                  Text('- ${gym.totalReviews} đánh giá',
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text('Thư viện ảnh:',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children:
                                      gym.gallery.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final imageUrl = entry.value;
                                    return GestureDetector(
                                      onTap: () => _showImageGallery(
                                          context, gym.gallery, index),
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: Image.network(imageUrl,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text('Chi tiết bảng giá:',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                              const SizedBox(height: 8),
                              Table(
                                border: TableBorder.all(color: Colors.grey),
                                children: [
                                  TableRow(children: [
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Ngày',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                          '${formatter.format(gym.pricePerDay)}'),
                                    ),
                                  ]),
                                  TableRow(children: [
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Tuần',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                          '${formatter.format(gym.pricePerWeek)}'),
                                    ),
                                  ]),
                                  TableRow(children: [
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Tháng',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                          '${formatter.format(gym.pricePerMonth)}'),
                                    ),
                                  ]),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text('Bình luận:',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Consumer<GymProvider>(
                                builder: (context, gymProvider, child) {
                                  final comments = gymProvider
                                      .getCommentsForGym(widget.gymId);

                                  if (comments.isNotEmpty) {
                                    final displayedComments = _showAllComments
                                        ? comments
                                        : comments.take(3).toList();

                                    return Column(
                                      children: [
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: displayedComments.length,
                                          itemBuilder: (context, index) {
                                            final comment =
                                                displayedComments[index];
                                            return Card(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              child: ListTile(
                                                leading: const CircleAvatar(
                                                  child: Icon(Icons.person,
                                                      color: Colors.white),
                                                  backgroundColor: Colors.grey,
                                                ),
                                                title: Text(comment.user,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(comment.content),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: List.generate(
                                                        comment.rating,
                                                        (index) => const Icon(
                                                            Icons.star,
                                                            color: Colors.amber,
                                                            size: 16),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      comment.createdAt,
                                                      style: const TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        if (comments.length > 3)
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _showAllComments =
                                                    !_showAllComments;
                                              });
                                            },
                                            child: Text(_showAllComments
                                                ? 'Ẩn bớt bình luận'
                                                : 'Xem tất cả bình luận'),
                                          ),
                                      ],
                                    );
                                  }

                                  return FutureBuilder(
                                    future: comments.isEmpty
                                        ? Provider.of<GymProvider>(context,
                                                listen: false)
                                            .fetchGymComments(widget
                                                .gymId) // Fetch only if empty
                                        : null,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      } else if (snapshot.hasError) {
                                        return const Center(
                                            child: Text(
                                                'Không có bình luận nào.'));
                                      } else {
                                        final fetchedComments = gymProvider
                                            .getCommentsForGym(widget.gymId);
                                        if (fetchedComments.isEmpty) {
                                          return const Center(
                                            child: Text(
                                                'Không có bình luận nào.',
                                                style: TextStyle(
                                                    color: Colors.grey)),
                                          );
                                        }
                                        final displayedComments =
                                            _showAllComments
                                                ? fetchedComments
                                                : fetchedComments
                                                    .take(3)
                                                    .toList();

                                        return Column(
                                          children: [
                                            ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount:
                                                  displayedComments.length,
                                              itemBuilder: (context, index) {
                                                final comment =
                                                    displayedComments[index];
                                                return Card(
                                                  margin: const EdgeInsets
                                                      .symmetric(vertical: 8),
                                                  child: ListTile(
                                                    leading: const CircleAvatar(
                                                      child: Icon(Icons.person,
                                                          color: Colors.white),
                                                      backgroundColor:
                                                          Colors.grey,
                                                    ),
                                                    title: Text(comment.user,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    subtitle: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(comment.content),
                                                        const SizedBox(
                                                            height: 4),
                                                        Row(
                                                          children:
                                                              List.generate(
                                                            comment.rating,
                                                            (index) =>
                                                                const Icon(
                                                                    Icons.star,
                                                                    color: Colors
                                                                        .amber,
                                                                    size: 16),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          comment.createdAt,
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                  fontSize: 12),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            if (fetchedComments.length > 3)
                                              TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _showAllComments =
                                                        !_showAllComments;
                                                  });
                                                },
                                                child: Text(_showAllComments
                                                    ? 'Ẩn bớt bình luận'
                                                    : 'Xem tất cả bình luận'),
                                              ),
                                          ],
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              const Text('Đánh giá và bình luận:',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              _buildCommentForm(context, widget.gymId),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0), // Add BottomNavBar
    );
  }

  Widget _buildCommentForm(BuildContext context, int gymId) {
    final _commentController = TextEditingController();
    ValueNotifier<int> _selectedRating =
        ValueNotifier<int>(5); // Default to 5 stars

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đánh giá của bạn:',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<int>(
              valueListenable: _selectedRating,
              builder: (context, value, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < value ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 28,
                      ),
                      onPressed: () {
                        _selectedRating.value =
                            index + 1; // Update selected rating
                      },
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Viết bình luận...',
                labelStyle: TextStyle(color: Colors.grey[700]),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
              maxLines: 3,
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_selectedRating.value == 0 ||
                      _commentController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Vui lòng chọn sao và nhập bình luận.')),
                    );
                    return;
                  }

                  try {
                    final prefs = await SharedPreferences.getInstance();
                    final userId = prefs.getInt('userId'); // Retrieve user ID
                    if (userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Không tìm thấy thông tin người dùng.')),
                      );
                      return;
                    }

                    await Provider.of<GymProvider>(context, listen: false)
                        .submitComment(
                      gymId,
                      _selectedRating.value,
                      _commentController.text,
                      userId,
                    );
                    _commentController.clear();
                    _selectedRating.value = 5; // Reset to default 5 stars
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Đã gửi đánh giá thành công!')),
                    );
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Gửi đánh giá thất bại. Vui lòng thử lại.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Button background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Bình luận',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
