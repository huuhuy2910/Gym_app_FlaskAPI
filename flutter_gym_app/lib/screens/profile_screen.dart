import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../theme/theme_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  String? _username;
  String? _email;
  String? _phone;
  String? _address;
  Future<void>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = await authProvider.getCurrentUserId();
    if (userId != null && userId > 0) {
      await authProvider.fetchProfile(userId);
    } else {
      throw Exception('Invalid user ID');
    }
  }

  Future<void> _updateProfile(
      BuildContext context, AuthProvider authProvider) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        final userId = await authProvider.getCurrentUserId();
        if (userId == null || userId <= 0) {
          throw Exception('Invalid user ID');
        }

        await authProvider.updateProfile(
          userId: userId,
          username: _username,
          email: _email,
          phone: _phone ?? '',
          address: _address ?? '',
        );
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thành công!')),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${error.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return FutureBuilder(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false, // Bỏ nút quay lại
              title: const Text('Thông tin cá nhân',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Thông Tin Cá Nhân')),
            body: const Center(child: Text('Lỗi khi tải dữ liệu.')),
          );
        }

        final user = authProvider.user;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Thông Tin Cá Nhân')),
            body: const Center(child: Text('Không tìm thấy người dùng.')),
          );
        }

        if (!_isEditing) {
          _username = user.username;
          _email = user.email;
          _phone = user.phone;
          _address = user.address;
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false, // Bỏ nút quay lại
            title: const Text('Thông tin cá nhân',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit, color: ThemeColors.black),
                  onPressed: () => setState(() => _isEditing = true),
                ),
              IconButton(
                icon: const Icon(Icons.lock, color: ThemeColors.black),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: ThemeColors.black),
                onPressed: () async {
                  await authProvider.logout();
                  Navigator.of(context).pushReplacementNamed('/auth');
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    // ignore: deprecated_member_use
                    backgroundColor: ThemeColors.grey.withOpacity(0.3),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      // ignore: deprecated_member_use
                      color: ThemeColors.black.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _username ?? '',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(_email ?? '',
                      style: const TextStyle(
                          fontSize: 16, color: ThemeColors.grey)),
                  const SizedBox(height: 20),
                  const Divider(color: ThemeColors.grey),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField('Tên', _username, _isEditing,
                            (value) => _username = value, Icons.person),
                        _buildTextField('Email', _email, _isEditing,
                            (value) => _email = value, Icons.email),
                        _buildTextField('Số điện thoại', _phone, _isEditing,
                            (value) => _phone = value, Icons.phone),
                        _buildTextField('Địa chỉ', _address, _isEditing,
                            (value) => _address = value, Icons.home),
                        if (_isEditing) const SizedBox(height: 20),
                        if (_isEditing)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildButton('Hủy', ThemeColors.grey,
                                  () => setState(() => _isEditing = false)),
                              _buildButton('Lưu', ThemeColors.black,
                                  () => _updateProfile(context, authProvider)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: BottomNavBar(currentIndex: 3),
        );
      },
    );
  }

  Widget _buildTextField(String label, String? initialValue, bool enabled,
      void Function(String?) onSaved, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          prefixIcon: Icon(icon, color: ThemeColors.black),
        ),
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _currentPassword;
  String? _newPassword;
  String? _confirmPassword;
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> _submitChangePassword(AuthProvider authProvider) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await authProvider.changePassword(
          currentPassword: _currentPassword!,
          newPassword: _newPassword!,
          confirmPassword: _confirmPassword!,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully!')),
        );
        Navigator.of(context).pop();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đổi mật khẩu',
            style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildPasswordField(
                'Mật khẩu hiện tại',
                (value) => _currentPassword = value,
                _isCurrentPasswordVisible,
                () => setState(() =>
                    _isCurrentPasswordVisible = !_isCurrentPasswordVisible),
              ),
              _buildPasswordField(
                'Mật khẩu mới',
                (value) => _newPassword = value,
                _isNewPasswordVisible,
                () => setState(
                    () => _isNewPasswordVisible = !_isNewPasswordVisible),
              ),
              _buildPasswordField(
                'Xác nhận mật khẩu',
                (value) => _confirmPassword = value,
                _isConfirmPasswordVisible,
                () => setState(() =>
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _submitChangePassword(authProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeColors.black,
                   // Use theme color
                ),
                child: const Text(
                  'Đổi mật khẩu',
                  style: TextStyle(color: ThemeColors.white), // Set text color to white
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    void Function(String?) onSaved,
    bool isPasswordVisible,
    VoidCallback toggleVisibility,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        obscureText: !isPasswordVisible,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: IconButton(
            icon: Icon(
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: toggleVisibility,
          ),
        ),
        onSaved: onSaved,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }
}
