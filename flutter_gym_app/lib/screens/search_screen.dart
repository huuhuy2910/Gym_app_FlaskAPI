import 'package:flutter/material.dart';
import 'package:flutter_gym_app/screens/gym_details_page.dart';
import 'package:provider/provider.dart';
import '../models/gym.dart';
import '../widgets/bottom_nav_bar.dart';
import '../theme/theme_colors.dart'; // Import ThemeColors
import '../providers/search_provider.dart'; // Import SearchProvider
import '../widgets/gym_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  String _selectedLocation = '';
  double? _minPrice;
  double? _maxPrice;
  String _selectedPriceType = 'day';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); // Trigger UI update on text change
    });
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Smooth transition duration
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
      if (_showFilters) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Bỏ nút quay lại
        title: const Text(
          'Tìm kiếm phòng gym',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: ThemeColors.black),
        ),
        backgroundColor: ThemeColors.white,
        iconTheme: const IconThemeData(color: ThemeColors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: ThemeColors.black),
            onPressed: _toggleFilters,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _buildSearchBar(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _showFilters ? null : 0, // Collapse when hidden
              child: _showFilters ? _buildFilters() : const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildGymList(searchProvider)),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Nhập tên phòng gym...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.search),
      ),
      onSubmitted: (_) => setState(() {}), // Trigger search on submit
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedLocation.isEmpty ? 'Tất cả' : _selectedLocation,
          items: ['Tất cả', 'Hà Nội', 'Hồ Chí Minh', 'Đà Nẵng']
              .map((location) =>
                  DropdownMenuItem(value: location, child: Text(location)))
              .toList(),
          onChanged: (value) => setState(() {
            if (value == 'Tất cả') {
              _selectedLocation = '';
            } else {
              _selectedLocation = value ?? '';
            }
          }),
          decoration: InputDecoration(
            labelText: 'Lọc theo địa điểm',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildPriceField('Giá tối thiểu',
                    (value) => _minPrice = double.tryParse(value))),
            const SizedBox(width: 12),
            Expanded(
                child: _buildPriceField('Giá tối đa',
                    (value) => _maxPrice = double.tryParse(value))),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedPriceType,
          items: const [
            DropdownMenuItem(value: 'day', child: Text('Giá theo ngày')),
            DropdownMenuItem(value: 'week', child: Text('Giá theo tuần')),
            DropdownMenuItem(value: 'month', child: Text('Giá theo tháng')),
          ],
          onChanged: (value) =>
              setState(() => _selectedPriceType = value ?? 'day'),
          decoration: InputDecoration(
            labelText: 'Lọc theo loại giá',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 20, color: Colors.white),
                label: const Text('Áp dụng bộ lọc',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                onPressed: () => setState(() {}), // Apply filters
              ),
              if (_selectedLocation.isNotEmpty ||
                  _minPrice != null ||
                  _maxPrice != null ||
                  _searchController.text.trim().isNotEmpty)
                const SizedBox(width: 16),
              if (_selectedLocation.isNotEmpty ||
                  _minPrice != null ||
                  _maxPrice != null ||
                  _searchController.text.trim().isNotEmpty)
                ElevatedButton.icon(
                  icon: const Icon(Icons.clear, size: 20, color: Colors.white),
                  label: const Text('Hủy lọc',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                  onPressed: () => setState(() {
                    _selectedLocation = '';
                    _minPrice = null;
                    _maxPrice = null;
                    _selectedPriceType = 'day';
                    _searchController.clear();
                  }), // Clear filters
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceField(String label, Function(String) onChanged) {
    return TextField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildGymList(SearchProvider searchProvider) {
    final hasSearchOrFilter = _searchController.text.trim().isNotEmpty ||
        _selectedLocation.isNotEmpty ||
        _minPrice != null ||
        _maxPrice != null;

    if (!hasSearchOrFilter && !_showFilters) {
      return const Center(
        child: Text(
          'Hãy nhập từ khóa hoặc áp dụng bộ lọc để tìm kiếm phòng gym.',
          style: TextStyle(color: Colors.black, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return FutureBuilder<List<Gym>>(
      future: searchProvider.searchAndFilterGyms(
        name: _searchController.text.trim(),
        location: _selectedLocation == 'Tất cả' ? '' : _selectedLocation,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        priceType: _selectedPriceType,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        } else if (snapshot.hasError) {
          return Center(
              child: Text('Lỗi: ${snapshot.error}',
                  style: const TextStyle(color: Colors.black)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('Không tìm thấy phòng gym nào.',
                  style: TextStyle(color: Colors.black)));
        }

        final gyms = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: gyms.length,
          itemBuilder: (context, index) {
            return GymCard(
              gym: gyms[index],
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        GymDetailsPage(gymId: gyms[index].id),
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
        );
      },
    );
  }
}
