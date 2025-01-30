import 'package:flutter/material.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/widgets/common_text_field.dart';
import 'package:journal_app/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:journal_app/utils/snackbar_utils.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool isValidPassword(String password) {
    return RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$').hasMatch(password);
  }

  bool isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 16.0, 16.0, 16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Theme.of(context).platform == TargetPlatform.iOS 
                              ? Icons.arrow_back_ios 
                              : Icons.arrow_back,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(),
                      ),
                      const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommonTextField(
                          controller: _emailController,
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!isValidEmail(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
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
                            if (!isValidUsername(value)) {
                              return 'Username must be 3-20 characters long and contain only letters, numbers, and underscores';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        CommonTextField(
                          controller: _passwordController,
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          obscureText: !_isPasswordVisible,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (!isValidPassword(value)) {
                              return 'Password must contain at least 8 characters, including uppercase, lowercase, number, and special character';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        CommonTextField(
                          controller: _confirmPasswordController,
                          labelText: 'Confirm Password',
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                          obscureText: !_isConfirmPasswordVisible,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),
                        CustomButton(
                          text: 'Sign Up',
                          onPressed: _signUp,
                          isLoading: Provider.of<AuthProvider>(context).isLoading,
                        ),
                        SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Already have an account? Log in'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _signUp() async {
    if (!mounted) return;
    if (_formKey.currentState!.validate()) {
      setState(() {
      });
      try {
        bool isUsernameTaken = await Provider.of<AuthProvider>(context, listen: false)
            .isUsernameTaken(_usernameController.text);
        if (!mounted) return;
        
        if (isUsernameTaken) {
          showThemedSnackBar(
            context, 
            'This username is already taken. Please choose another.',
            isError: true
          );
          return;
        }

        await Provider.of<AuthProvider>(context, listen: false).signUp(
          _emailController.text,
          _passwordController.text,
          _usernameController.text,
        );
        
        if (!mounted) return;
        
        showThemedSnackBar(
          context,
          'Sign up successful. Please check your email for confirmation.'
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        showThemedSnackBar(
          context,
          'Error signing up: ${e.toString()}',
          isError: true
        );
      } finally {
        if (mounted) {
          setState(() {
          });
        }
      }
    }
  }
}

