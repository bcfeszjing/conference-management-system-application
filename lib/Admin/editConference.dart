import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'manageConferencePage.dart';

class EditConferencePage extends StatefulWidget {
  final String conferenceId;

  EditConferencePage({Key? key, required this.conferenceId}) : super(key: key);

  @override
  _EditConferencePageState createState() => _EditConferencePageState();
}

class _EditConferencePageState extends State<EditConferencePage> {
  final TextEditingController submissionDateController = TextEditingController();
  final TextEditingController cameraReadyDateController = TextEditingController();
  final TextEditingController journalFinalDateController = TextEditingController();
  final TextEditingController confIdController = TextEditingController();
  final TextEditingController confNameController = TextEditingController();
  final TextEditingController confDoiController = TextEditingController();
  final TextEditingController ccEmailController = TextEditingController();
  String? confType;
  String? confStatus;

  @override
  void initState() {
    super.initState();
    fetchConferenceDetails();
  }

  Future<void> fetchConferenceDetails() async {
    final response = await http.get(
      Uri.parse('https://cmsa.digital/admin/get_detailsConference.php?conf_id=${widget.conferenceId}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        confIdController.text = data['conf_id'];
        confNameController.text = data['conf_name'];
        confDoiController.text = data['conf_doi'];
        ccEmailController.text = data['cc_email'];
        submissionDateController.text = data['conf_submitdate'];
        cameraReadyDateController.text = data['conf_crsubmitdate'];
        journalFinalDateController.text = data['conf_date'];
        confType = data['conf_type'];
        confStatus = data['conf_status'];
      });
    } else {
      throw Exception('Failed to load conference details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Conference"),
        backgroundColor: Color(0xFFffc107),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
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
                      Icon(Icons.edit_document, color: Color(0xFFcc9600), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Conference Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFcc9600),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Basic Information Section
                _buildSectionTitle('Basic Information'),
                _buildLabel('Conf/Journal ID'),
                TextField(
                  controller: confIdController,
                  decoration: _buildInputDecoration(hintText: 'Enter ID', icon: Icons.numbers),
                ),
                SizedBox(height: 16),

                _buildLabel('Conf/Journal Name'),
                TextField(
                  controller: confNameController,
                  decoration: _buildInputDecoration(hintText: 'Enter name', icon: Icons.title),
                ),
                SizedBox(height: 16),

                _buildLabel('BBC Email (Forward Email)'),
                TextField(
                  controller: ccEmailController,
                  decoration: _buildInputDecoration(hintText: "Enter email", icon: Icons.email),
                ),
                SizedBox(height: 16),

                // Configuration Section
                _buildSectionTitle('Configuration'),
                _buildLabel('Type'),
                DropdownButtonFormField<String>(
                  value: confType,
                  decoration: _buildInputDecoration(icon: Icons.category),
                  items: <String>['Conference', 'Journal'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      confType = newValue;
                    });
                  },
                ),
                SizedBox(height: 16),

                _buildLabel('Status'),
                DropdownButtonFormField<String>(
                  value: confStatus,
                  decoration: _buildInputDecoration(
                    icon: confStatus == 'Active' ? Icons.check_circle_outline : Icons.cancel_outlined
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
                    });
                  },
                ),
                SizedBox(height: 16),

                _buildLabel('DOI'),
                TextField(
                  controller: confDoiController,
                  decoration: _buildInputDecoration(hintText: "i.e. 1234-45X", icon: Icons.tag),
                ),
                SizedBox(height: 24),

                // Dates Section
                _buildSectionTitle('Important Dates'),
                _buildLabel('Submission Date'),
                TextField(
                  controller: submissionDateController,
                  readOnly: true,
                  decoration: _buildInputDecoration(hintText: "Select date", icon: Icons.calendar_today),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      submissionDateController.text = "${pickedDate.toLocal()}".split(' ')[0];
                    }
                  },
                ),
                SizedBox(height: 16),

                _buildLabel('Camera Ready Date'),
                TextField(
                  controller: cameraReadyDateController,
                  readOnly: true,
                  decoration: _buildInputDecoration(hintText: "Select date", icon: Icons.calendar_today),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      cameraReadyDateController.text = "${pickedDate.toLocal()}".split(' ')[0];
                    }
                  },
                ),
                SizedBox(height: 16),

                _buildLabel('Journal Final/ Conference Date'),
                TextField(
                  controller: journalFinalDateController,
                  readOnly: true,
                  decoration: _buildInputDecoration(hintText: "Select date", icon: Icons.calendar_today),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      journalFinalDateController.text = "${pickedDate.toLocal()}".split(' ')[0];
                    }
                  },
                ),
                SizedBox(height: 24),

                // Action Buttons
                Container(
                  padding: EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade200, width: 2)),
                  ),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          _showConfirmationDialog(context);
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
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showDeleteConfirmationDialog(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(double.infinity, 60),
                          elevation: 3,
                        ),
                        icon: Icon(Icons.delete, size: 24),
                        label: Text(
                          'Delete Conference',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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

  InputDecoration _buildInputDecoration({String? hintText, IconData? icon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: icon != null ? Icon(icon, color: Color(0xFFcc9600)) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFFffc107), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

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

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Are you sure?"),
          content: Text("Do you want to save these changes?"),
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
                await _saveConference();
                Navigator.of(context).pop(); // Close the dialog
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
      Uri.parse('https://cmsa.digital/admin/edit_conference.php'),
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
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save conference');
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Success"),
          content: Text("Conference updated successfully!"),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ManageConferencePage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Are you sure?"),
          content: Text("Do you want to delete this conference?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () async {
                await _deleteConference();
                Navigator.of(context).pop(); // Close the dialog
                _showDeleteSuccessDialog(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteConference() async {
    final response = await http.post(
      Uri.parse('https://cmsa.digital/admin/delete_conference.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'conf_id': confIdController.text,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete conference');
    }
  }

  void _showDeleteSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Deleted"),
          content: Text("Conference deleted successfully!"),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ManageConferencePage()),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
