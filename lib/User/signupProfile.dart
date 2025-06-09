import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:country_picker/country_picker.dart';
import 'manageUserNewsPage.dart';
import '../services/user_state.dart';
import '../config/app_config.dart';

class SignupProfilePage extends StatefulWidget {
  const SignupProfilePage({super.key});

  @override
  State<SignupProfilePage> createState() => _SignupProfilePageState();
}

class _SignupProfilePageState extends State<SignupProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTitle;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedStatus;
  final _orgController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedCountry;
  bool _isLoading = false;

  final List<String> _titles = [
    'Dato',
    'Professor',
    'Assoc. Professor',
    'Dr',
    'Ir',
    'Ts',
    'Mr',
    'Mrs'
  ];

  final List<String> _statuses = ['Student', 'Non-Student'];

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final userId = await UserState.getUserId();
        final response = await http.post(
          Uri.parse('${AppConfig.baseUrl}user/signup_profile.php'),
          body: {
            'user_id': userId,
            'user_title': _selectedTitle,
            'user_name': _nameController.text,
            'user_phone': _phoneController.text,
            'user_status': _selectedStatus,
            'user_org': _orgController.text,
            'user_address': _addressController.text,
            'user_country': _selectedCountry,
          },
        );

        final data = json.decode(response.body);
        
        if (data['status'] == 'success') {
          if (mounted) {
            _showSuccessDialog();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'])),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Success"),
          content: const Text("Profile updated successfully!"),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageUserNewsPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Highest Title'),
              DropdownButtonFormField<String>(
                value: _selectedTitle,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: _titles.map((title) {
                  return DropdownMenuItem(value: title, child: Text(title));
                }).toList(),
                onChanged: (value) => setState(() => _selectedTitle = value),
                validator: (value) => value == null ? 'Please select a title' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Name'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Phone'),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g +60123456789',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter your phone number' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Current Status'),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: _statuses.map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (value) => setState(() => _selectedStatus = value),
                validator: (value) => value == null ? 'Please select your status' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Organization'),
              TextFormField(
                controller: _orgController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter your organization' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Mailing Address'),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter your address' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Country'),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: _selectedCountry ?? 'Select your country',
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onTap: () {
                  showCountryPicker(
                    context: context,
                    onSelect: (Country country) {
                      setState(() => _selectedCountry = country.name);
                    },
                  );
                },
                validator: (value) => _selectedCountry == null ? 'Please select your country' : null,
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _orgController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
