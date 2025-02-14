import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/widgets/common_text_field.dart';
import 'package:journal_app/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:journal_app/utils/snackbar_utils.dart';
import 'package:journal_app/widgets/user_avatar.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _usernameController = TextEditingController(text: authProvider.userProfile?.username ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    UserAvatar(
                      imageUrl: _imageFile != null 
                          ? _imageFile!.path  // Show picked image
                          : authProvider.userProfile?.avatarUrl,
                      radius: 50,
                      isLocalImage: _imageFile != null,  // Add this flag
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              CommonTextField(
                controller: _usernameController,
                labelText: 'Username',
                prefixIcon: Icon(Icons.person),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(value)) {
                    return 'Username must be 3-20 characters long and contain only letters, numbers, and underscores';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              CustomButton(
                text: 'Update Profile',
                onPressed: _updateProfile,
                isLoading: Provider.of<AuthProvider>(context).isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        String? newAvatarUrl;

        if (_imageFile != null) {
          newAvatarUrl = await authProvider.uploadProfilePicture(_imageFile!.path);
        }

        await authProvider.updateProfile(
          username: _usernameController.text,
          avatarUrl: newAvatarUrl ?? authProvider.userProfile?.avatarUrl,
        );

        showThemedSnackBar(context, 'Profile updated successfully');
        Navigator.pop(context);
      } catch (e) {
        showThemedSnackBar(context, 'Error updating profile: $e', isError: true);
      }
    }
  }
}

