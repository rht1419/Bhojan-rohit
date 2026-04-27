import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../models/profile_model.dart';

/// Screen 8 — Edit Profile (EP-07, EP-08).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _floorController = TextEditingController();
  final _buildingController = TextEditingController();
  String? _dietaryPreference;
  String _language = 'en';
  bool _notificationsEnabled = true;
  String? _avatarUrl;
  XFile? _selectedAvatar;
  bool _isLoading = true;
  bool _isSaving = false;

  final _picker = ImagePicker();
  final _dietaryOptions = ['Vegetarian', 'Non-Vegetarian', 'Vegan', 'Jain', 'Eggetarian'];
  final _languageOptions = {'en': 'English', 'hi': 'Hindi', 'kn': 'Kannada', 'te': 'Telugu', 'ta': 'Tamil'};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _floorController.dispose();
    _buildingController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final service = ref.read(authServiceProvider);
      final profile = await service.getProfile();
      _nameController.text = profile.fullName;
      _departmentController.text = profile.department ?? '';
      _floorController.text = profile.floor ?? '';
      _buildingController.text = profile.building ?? '';
      _dietaryPreference = profile.dietaryPreference;
      _language = profile.language ?? 'en';
      _notificationsEnabled = profile.notificationsEnabled ?? true;
      _avatarUrl = profile.avatarUrl;
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      }
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        setState(() => _selectedAvatar = image);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final service = ref.read(authServiceProvider);
      await service.updateProfile({
        'full_name': _nameController.text.trim(),
        'department': _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
        'floor': _floorController.text.trim().isEmpty ? null : _floorController.text.trim(),
        'building': _buildingController.text.trim().isEmpty ? null : _buildingController.text.trim(),
        'dietary_preference': _dietaryPreference,
        'language': _language,
        'notifications_enabled': _notificationsEnabled,
      });

      // Simulate avatar upload if selected
      if (_selectedAvatar != null) {
        await Future.delayed(const Duration(milliseconds: 600)); // Mock upload delay
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Edit Profile', style: AppTextStyles.headlineSmall),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => context.pop()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar change area
                    Center(
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              backgroundImage: _selectedAvatar != null
                                  ? (kIsWeb ? NetworkImage(_selectedAvatar!.path) : FileImage(File(_selectedAvatar!.path))) as ImageProvider
                                  : (_avatarUrl != null ? NetworkImage(_avatarUrl!) : null),
                              child: (_selectedAvatar == null && _avatarUrl == null)
                                  ? Text(_nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?',
                                      style: AppTextStyles.headlineLarge.copyWith(color: AppColors.primary))
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _departmentController,
                      decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.business)),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _floorController,
                      decoration: const InputDecoration(labelText: 'Floor', prefixIcon: Icon(Icons.stairs)),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _buildingController,
                      decoration: const InputDecoration(labelText: 'Building', prefixIcon: Icon(Icons.apartment)),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _dietaryPreference,
                      decoration: const InputDecoration(labelText: 'Dietary Preference', prefixIcon: Icon(Icons.restaurant)),
                      items: _dietaryOptions.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                      onChanged: (v) => setState(() => _dietaryPreference = v),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _language,
                      decoration: const InputDecoration(labelText: 'Language', prefixIcon: Icon(Icons.language)),
                      items: _languageOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (v) => setState(() => _language = v ?? 'en'),
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text('Push Notifications'),
                      subtitle: const Text('Receive order updates and offers'),
                      value: _notificationsEnabled,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => _notificationsEnabled = v),
                    ),

                    const SizedBox(height: 40),

                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Changes', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
