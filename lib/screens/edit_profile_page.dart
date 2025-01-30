import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/widgets/common_text_field.dart';
import 'package:journal_app/widgets/custom_button.dart';
import 'package:provider/provider.dart';

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
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (authProvider.userProfile?.avatarUrl != null
                          ? CachedNetworkImageProvider(authProvider.userProfile!.avatarUrl!)
                          : null) as ImageProvider?,
                  child: _imageFile == null && authProvider.userProfile?.avatarUrl == null
                      ? Icon(Icons.person, size: 50)
                      : null,
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }
}

