import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:CMSapplication/services/user_state.dart';

class AddUserMessages extends StatefulWidget {
  const AddUserMessages({Key? key}) : super(key: key);

  @override
  State<AddUserMessages> createState() => _AddUserMessagesState();
}

class _AddUserMessagesState extends State<AddUserMessages> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedConference;
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  List<Map<String, dynamic>> _conferences = [];
  bool _isLoading = true;
  int _wordCount = 0;
  static const int _maxWords = 350;

  @override
  void initState() {
    super.initState();
    _fetchConferences();
    _messageController.addListener(_updateWordCount);
  }

  void _updateWordCount() {
    setState(() {
      _wordCount = _messageController.text.split(' ').where((word) => word.isNotEmpty).length;
    });
  }

  Future<void> _fetchConferences() async {
    try {
      final response = await http.get(
        Uri.parse('https://cmsa.digital/user/get_userMessagesConference.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _conferences = List<Map<String, dynamic>>.from(data['conferences']);
            _isLoading = false;
          });
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to load conferences');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show confirmation dialog
    bool? proceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Submission'),
          content: const Text('Are you sure you want to submit this message?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (proceed != true) return;

    try {
      final userEmail = await UserState.getUserEmail();
      if (userEmail == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User email not found')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('https://cmsa.digital/user/add_userMessages.php'),
        body: {
          'conf_id': _selectedConference,
          'message_title': _titleController.text,
          'message_content': _messageController.text,
          'user_email': userEmail,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          // Show success dialog
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Success"),
                content: const Text("Message sent successfully!"),
                actions: [
                  TextButton(
                    child: const Text("OK"),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(true); // Return to previous screen with refresh flag
                    },
                  ),
                ],
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${result['message']}')),
          );
        }
      } else {
        throw Exception('Failed to connect to server');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Message'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Select Conf/Journal'),
                      DropdownButtonFormField<String>(
                        value: _selectedConference,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        isExpanded: true,
                        hint: const Text('Select conference/journal'),
                        items: _conferences.map((conference) {
                          return DropdownMenuItem<String>(
                            value: conference['conf_id'],
                            child: Text('${conference['conf_id']} - ${conference['conf_name']}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedConference = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a conference';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Title'),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Enter title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Message'),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 8,
                        decoration: InputDecoration(
                          hintText: 'Enter your message',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a message';
                          }
                          if (_wordCount > _maxWords) {
                            return 'Message cannot exceed $_maxWords words';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_wordCount/$_maxWords words',
                        style: TextStyle(
                          color: _wordCount > _maxWords ? Colors.red : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _sendMessage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 17,
                              ),
                            ),
                            child: const Text(
                              'Send',
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
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
