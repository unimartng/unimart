// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../constants/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _campusController;
  late TextEditingController _emailController;
  bool _loading = false;
  String? _profilePhotoUrl;
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _campusController = TextEditingController(text: user?.campus ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _profilePhotoUrl = user?.profilePhotoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _campusController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final userId = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).currentUser?.id;

      String? uploadedUrl = _profilePhotoUrl;
      if (_pickedImage != null) {
        final fileBytes = await _pickedImage!.readAsBytes();
        uploadedUrl = await SupabaseService.instance.uploadImage(
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}',
          fileBytes,
        );
      }

      await SupabaseService.instance.updateUserProfile(userId!, {
        'name': _nameController.text.trim(),
        'campus': _campusController.text.trim(),
        'email': _emailController.text.trim(),
        'profile_photo_url': uploadedUrl,
      });

      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).refreshCurrentUser();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = pickedFile;
      });
    }
  }

  Widget _buildProfileImage() {
    if (_pickedImage != null) {
      if (kIsWeb) {
        return FutureBuilder<Uint8List>(
          future: _pickedImage!.readAsBytes(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return CircleAvatar(
              radius: 50,
              backgroundImage: MemoryImage(snapshot.data!),
            );
          },
        );
      } else {
        return CircleAvatar(
          radius: 50,
          backgroundImage: FileImage(File(_pickedImage!.path)),
        );
      }
    } else if (_profilePhotoUrl != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage(_profilePhotoUrl!),
      );
    } else {
      return const CircleAvatar(
        radius: 50,
        child: Icon(Icons.person, size: 50),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(onTap: _pickImage, child: _buildProfileImage()),
              const SizedBox(height: 16),
              Padding(padding: const EdgeInsets.all(8.0), child: Text('Name')),
              TextFormField(
                controller: _nameController,

                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Campus'),
              ),
              TextFormField(
                controller: _campusController,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter your campus' : null,
              ),
              const SizedBox(height: 16),
              Padding(padding: const EdgeInsets.all(8.0), child: Text('Email')),
              TextFormField(
                controller: _emailController,

                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter your email' : null,
              ),
              const SizedBox(height: 80), // to avoid overlapping FAB
            ],
          ),
        ),
      ),
      floatingActionButton: !_loading
          ? FloatingActionButton.extended(
              onPressed: _saveProfile,
              label: const Text('Save', style: TextStyle(color: Colors.white)),
              icon: const Icon(Icons.save, color: Colors.white),
              backgroundColor: AppColors.primaryBlue,
            )
          : null,
    );
  }
}
