import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:CMSapplication/services/conference_state.dart';

class AddFieldDialog extends StatefulWidget {
  final Function onFieldAdded;

  const AddFieldDialog({Key? key, required this.onFieldAdded}) : super(key: key);

  @override
  _AddFieldDialogState createState() => _AddFieldDialogState();
}

class _AddFieldDialogState extends State<AddFieldDialog> {
  final TextEditingController _fieldController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _submitField() async {
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Add'),
          content: Text('Are you sure you want to add this field?'),
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
        Uri.parse('https://cmsa.digital/admin/add_field.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'field_title': _fieldController.text,
          'conf_id': conferenceId,
        }),
      );

      final data = json.decode(response.body);
      if (data['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Field added successfully')),
        );
        
        // Call the callback to refresh the fields list
        widget.onFieldAdded();
        
        // Close the dialog
        Navigator.of(context).pop();
      } else {
        throw Exception(data['error'] ?? 'Failed to add field');
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
                title: Text('Add New Field'),
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
                'Field',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _fieldController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter field title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a field title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitField,
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
    _fieldController.dispose();
    super.dispose();
  }
}

