import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http package for API calls
import 'dart:convert'; // Import for JSON encoding
import 'manageConferencePage.dart'; // Import the ManageConferencePage
import '../config/app_config.dart'; // Import AppConfig

class AddConferencePage extends StatefulWidget {
  @override
  _AddConferencePageState createState() => _AddConferencePageState();
}

class _AddConferencePageState extends State<AddConferencePage> {
  final TextEditingController submissionDateController = TextEditingController();
  final TextEditingController cameraReadyDateController = TextEditingController();
  final TextEditingController journalFinalDateController = TextEditingController();
  final TextEditingController confIdController = TextEditingController();
  final TextEditingController confNameController = TextEditingController();
  final TextEditingController confDoiController = TextEditingController();
  final TextEditingController ccEmailController = TextEditingController();
  String? confType;
  String? confStatus;
  
  // Map to store validation errors for each field
  Map<String, String?> _errors = {};
  
  // ScrollController to scroll to error fields
  final ScrollController _scrollController = ScrollController();
  
  // Key references to form fields for scrolling
  final Map<String, GlobalKey> _fieldKeys = {
    'confId': GlobalKey(),
    'confName': GlobalKey(),
    'ccEmail': GlobalKey(),
    'confType': GlobalKey(),
    'confStatus': GlobalKey(),
    'confDoi': GlobalKey(),
    'submissionDate': GlobalKey(),
    'cameraReadyDate': GlobalKey(),
    'journalFinalDate': GlobalKey(),
  };

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }
  
  // Validate all fields and return true if valid
  bool _validateFields() {
    bool isValid = true;
    _errors.clear();
    
    // Check Conference ID
    if (confIdController.text.isEmpty) {
      _errors['confId'] = 'Conference ID is required';
      isValid = false;
    }
    
    // Check Conference Name
    if (confNameController.text.isEmpty) {
      _errors['confName'] = 'Conference name is required';
      isValid = false;
    }
    
    // Check Email
    if (ccEmailController.text.isEmpty) {
      _errors['ccEmail'] = 'Email is required';
      isValid = false;
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(ccEmailController.text)) {
      _errors['ccEmail'] = 'Please enter a valid email address';
      isValid = false;
    }
    
    // Check Type
    if (confType == null) {
      _errors['confType'] = 'Please select a type';
      isValid = false;
    }
    
    // Check Status
    if (confStatus == null) {
      _errors['confStatus'] = 'Please select a status';
      isValid = false;
    }
    
    // Check DOI
    if (confDoiController.text.isEmpty) {
      _errors['confDoi'] = 'DOI is required';
      isValid = false;
    }
    
    // Check Submission Date
    if (submissionDateController.text.isEmpty) {
      _errors['submissionDate'] = 'Submission date is required';
      isValid = false;
    }
    
    // Check Camera Ready Date
    if (cameraReadyDateController.text.isEmpty) {
      _errors['cameraReadyDate'] = 'Camera ready date is required';
      isValid = false;
    }
    
    // Check Journal Final Date
    if (journalFinalDateController.text.isEmpty) {
      _errors['journalFinalDate'] = 'Journal final date is required';
      isValid = false;
    }
    
    // If there are errors, scroll to the first error field
    if (!isValid) {
      _scrollToFirstError();
    }
    
    setState(() {}); // Rebuild to show error messages
    return isValid;
  }
  
  // Scroll to the first field with an error
  void _scrollToFirstError() {
    for (String fieldKey in _fieldKeys.keys) {
      if (_errors.containsKey(fieldKey) && _errors[fieldKey] != null) {
        // Find the position of the field and scroll to it
        Scrollable.ensureVisible(
          _fieldKeys[fieldKey]!.currentContext!,
          alignment: 0.2, // Position error field at 20% from the top
          duration: Duration(milliseconds: 600),
        );
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Conference"),
        backgroundColor: Color(0xFFffc107),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: Color(0xFFe6a700), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'New Conference',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFe6a700),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Basic Information Section
                _buildSectionTitle('Basic Information'),
                _buildLabel('Conf/Journal ID'),
                Column(
                  key: _fieldKeys['confId'],
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: confIdController,
                      decoration: _buildInputDecoration(
                        hintText: "i.e. ABCv1", 
                        icon: Icons.numbers,
                        error: _errors['confId'],
                      ),
                    ),
                    if (_errors['confId'] != null)
                      _buildErrorText(_errors['confId']!),
                  ],
                ),
                SizedBox(height: 16),

                _buildLabel('Conf/Journal Name'),
                Column(
                  key: _fieldKeys['confName'],
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: confNameController,
                      decoration: _buildInputDecoration(
                        hintText: "Enter conference name", 
                        icon: Icons.title,
                        error: _errors['confName'],
                      ),
                    ),
                    if (_errors['confName'] != null)
                      _buildErrorText(_errors['confName']!),
                  ],
                ),
                SizedBox(height: 16),

                _buildLabel('BBC Email (Forward Email)'),
                Column(
                  key: _fieldKeys['ccEmail'],
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: ccEmailController,
                      decoration: _buildInputDecoration(
                        hintText: "Enter your email", 
                        icon: Icons.email,
                        error: _errors['ccEmail'],
                      ),
                    ),
                    if (_errors['ccEmail'] != null)
                      _buildErrorText(_errors['ccEmail']!),
                  ],
                ),
                SizedBox(height: 16),

                // Configuration Section
                _buildSectionTitle('Configuration'),
                _buildLabel('Type'),
                Column(
                  key: _fieldKeys['confType'],
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: confType,
                      decoration: _buildInputDecoration(
                        icon: Icons.category,
                        error: _errors['confType'],
                      ),
                      items: <String>['Conference', 'Journal'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          confType = newValue;
                          _errors.remove('confType');
                        });
                      },
                    ),
                    if (_errors['confType'] != null)
                      _buildErrorText(_errors['confType']!),
                  ],
                ),
                SizedBox(height: 16),

                _buildLabel('Status'),
                Column(
                  key: _fieldKeys['confStatus'],
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: confStatus,
                      decoration: _buildInputDecoration(
                        icon: confStatus == 'Active' ? Icons.check_circle_outline : Icons.cancel_outlined,
                        error: _errors['confStatus'],
                      ),
                      items: <String>['Active', 'Inactive'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          confStatus = newValue;
                          _errors.remove('confStatus');
                        });
                      },
                    ),
                    if (_errors['confStatus'] != null)
                      _buildErrorText(_errors['confStatus']!),
                  ],
                ),
                SizedBox(height: 16),

                _buildLabel('DOI'),
                Column(
                  key: _fieldKeys['confDoi'],
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: confDoiController,
                      decoration: _buildInputDecoration(
                        hintText: "i.e. 1234-45X", 
                        icon: Icons.tag,
                        error: _errors['confDoi'],
                      ),
                    ),
                    if (_errors['confDoi'] != null)
                      _buildErrorText(_errors['confDoi']!),
                  ],
                ),
                SizedBox(height: 24),

                // Dates Section
                _buildSectionTitle('Important Dates'),
                _buildLabel('Submission Date'),
                Column(
                  key: _fieldKeys['submissionDate'],
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: submissionDateController,
                      readOnly: true,
                      decoration: _buildInputDecoration(
                        hintText: "Select date", 
                        icon: Icons.calendar_today,
                        error: _errors['submissionDate'],
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            submissionDateController.text = "${pickedDate.toLocal()}".split(' ')[0];
                            _errors.remove('submissionDate');
                          });
                        }
                      },
                    ),
                    if (_errors['submissionDate'] != null)
                      _buildErrorText(_errors['submissionDate']!),
                  ],
                ),
                SizedBox(height: 16),

                _buildLabel('Camera Ready Date'),
                Column(
                  key: _fieldKeys['cameraReadyDate'],
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: cameraReadyDateController,
                      readOnly: true,
                      decoration: _buildInputDecoration(
                        hintText: "Select date", 
                        icon: Icons.calendar_today,
                        error: _errors['cameraReadyDate'],
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            cameraReadyDateController.text = "${pickedDate.toLocal()}".split(' ')[0];
                            _errors.remove('cameraReadyDate');
                          });
                        }
                      },
                    ),
                    if (_errors['cameraReadyDate'] != null)
                      _buildErrorText(_errors['cameraReadyDate']!),
                  ],
                ),
                SizedBox(height: 16),

                _buildLabel('Journal Final/ Conference Date'),
                Column(
                  key: _fieldKeys['journalFinalDate'],
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: journalFinalDateController,
                      readOnly: true,
                      decoration: _buildInputDecoration(
                        hintText: "Select date", 
                        icon: Icons.calendar_today,
                        error: _errors['journalFinalDate'],
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            journalFinalDateController.text = "${pickedDate.toLocal()}".split(' ')[0];
                            _errors.remove('journalFinalDate');
                          });
                        }
                      },
                    ),
                    if (_errors['journalFinalDate'] != null)
                      _buildErrorText(_errors['journalFinalDate']!),
                  ],
                ),
                SizedBox(height: 24),

                // Action Button
                Container(
                  padding: EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade200, width: 2)),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_validateFields()) {
                        // All fields are valid, show confirmation dialog
                        _showConfirmationDialog(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFffc107),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(double.infinity, 60),
                      elevation: 3,
                    ),
                    icon: Icon(Icons.save, size: 24),
                    label: Text(
                      'Create Conference',
                      style: TextStyle(
                        fontSize: 18,
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
    );
  }
  
  // Widget to display error message
  Widget _buildErrorText(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0, left: 12.0),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 14, color: Colors.red[700]),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({String? hintText, IconData? icon, String? error}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: icon != null ? Icon(icon, color: Color(0xFFcc9600)) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: error != null ? Colors.red : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: error != null ? Colors.red : Color(0xFFcc9600), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorStyle: TextStyle(height: 0), // Hide default error text since we're using custom ones
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFcc9600),
            ),
          ),
          SizedBox(height: 4),
          Divider(height: 1, thickness: 1, color: Color(0xFFffe082)),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Are you sure?"),
          content: Text("Do you want to save this conference?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("OK"),
              onPressed: () async {
                // Save to database
                await _saveConference();
                Navigator.of(context).pop(); // Close the dialog
                // Show success message
                _showSuccessDialog(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveConference() async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}admin/add_conference.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'conf_id': confIdController.text,
        'conf_name': confNameController.text,
        'conf_status': confStatus!,
        'conf_type': confType!,
        'conf_doi': confDoiController.text,
        'cc_email': ccEmailController.text,
        'conf_submitdate': submissionDateController.text,
        'conf_crsubmitdate': cameraReadyDateController.text,
        'conf_date': journalFinalDateController.text,
        'conf_pubst': "Published",
      }),
    );

    if (response.statusCode == 200) {
      // Successfully saved
    } else {
      // Handle error
      throw Exception('Failed to save conference');
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Success"),
          content: Text("Conference added successfully!"),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ManageConferencePage()), // Navigate directly to ManageConferencePage
                );
              },
            ),
          ],
        );
      },
    );
  }
}
