import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:CMSapplication/services/conference_state.dart';

class AddRubricDialog extends StatefulWidget {
  final Function onRubricAdded;

  const AddRubricDialog({Key? key, required this.onRubricAdded}) : super(key: key);

  @override
  _AddRubricDialogState createState() => _AddRubricDialogState();
}

class _AddRubricDialogState extends State<AddRubricDialog> {
  final TextEditingController _rubricController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _submitRubric() async {
    if (!_formKey.currentState!.validate()) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Add'),
          content: Text('Are you sure you want to add this rubric?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final conferenceId = await ConferenceState.getSelectedConferenceId();
      
      final response = await http.post(
        Uri.parse('https://cmsa.digital/admin/add_rubric.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'rubric_text': _rubricController.text,
          'conf_id': conferenceId,
        }),
      );

      final data = json.decode(response.body);
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rubric added successfully')),
        );
        widget.onRubricAdded();
        Navigator.of(context).pop();
      } else {
        throw Exception(data['error'] ?? 'Failed to add rubric');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppBar(
                title: Text('Add New Rubric'),
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                titleTextStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Rubric',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _rubricController,
                maxLines: null,
                minLines: 3,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter rubric text',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter rubric text';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitRubric,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
    _rubricController.dispose();
    super.dispose();
  }
} 