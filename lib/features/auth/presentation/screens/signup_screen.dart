import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/models/user.dart';
import 'package:todo_app/core/services/auth_service.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = User(
      id: 0,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      email: _emailController.text.trim(),
      loginId: _loginIdController.text.trim(),
      password: _passwordController.text,
    );

    try {
      await ref.read(authProvider.notifier).signup(user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signup successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signup failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _getInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                children: [
                  const Icon(Icons.person_add_rounded, size: 70, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Join TaskSphere today',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        brightness: Brightness.light,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: _firstNameController,
                              style: const TextStyle(color: Colors.black87),
                              decoration: _getInputDecoration('First Name', Icons.person_outline),
                              validator: (value) => value == null || value.isEmpty ? 'Please enter first name' : null,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _lastNameController,
                              style: const TextStyle(color: Colors.black87),
                              decoration: _getInputDecoration('Last Name', Icons.person_outline),
                              validator: (value) => value == null || value.isEmpty ? 'Please enter last name' : null,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.black87),
                              decoration: _getInputDecoration('Email', Icons.email_outlined),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter email';
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _mobileController,
                              style: const TextStyle(color: Colors.black87),
                              decoration: _getInputDecoration('Mobile Number', Icons.phone_android),
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter mobile number';
                                if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                                  return 'Enter a valid 10-digit mobile number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _loginIdController,
                              style: const TextStyle(color: Colors.black87),
                              decoration: _getInputDecoration('LoginID (Username)', Icons.badge_outlined),
                              textInputAction: TextInputAction.next,
                              validator: (value) => value == null || value.isEmpty ? 'Please enter LoginID' : null,
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _passwordController,
                              style: const TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: const TextStyle(color: Colors.grey),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter password';
                                if (value.length < 8) return 'Min 8 characters required';
                                if (!RegExp(r'[A-Z]').hasMatch(value)) return 'One uppercase required';
                                if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) return 'One special char required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _confirmPasswordController,
                              style: const TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                labelStyle: const TextStyle(color: Colors.grey),
                                prefixIcon: const Icon(Icons.lock_reset),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _signup(),
                              validator: (value) => value == null || value.isEmpty ? 'Please confirm password' : null,
                            ),
                            const SizedBox(height: 25),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5B86E5),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                        'CREATE ACCOUNT',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: RichText(
                      text: const TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(color: Colors.white70),
                        children: [
                          TextSpan(
                            text: "Login",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
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
}
