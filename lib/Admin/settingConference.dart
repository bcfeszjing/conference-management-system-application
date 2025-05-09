import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:CMSapplication/services/conference_state.dart';

class SettingConferencePage extends StatefulWidget {
  @override
  _SettingConferencePageState createState() => _SettingConferencePageState();
}

class _SettingConferencePageState extends State<SettingConferencePage> {
  String? conferenceId;
  TextEditingController nameController = TextEditingController();
  String selectedStatus = 'Active';
  String selectedPubStatus = 'Published';
  DateTime? submitDate;
  DateTime? crSubmitDate;
  DateTime? confDate;
  bool isLoading = true;
  TextEditingController adminPassController = TextEditingController();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    loadConferenceData();
  }

  Future<void> loadConferenceData() async {
    conferenceId = await ConferenceState.getSelectedConferenceId();
    final adminEmail = await ConferenceState.getAdminEmail();
    
    if (conferenceId != null && adminEmail != null) {
      final response = await http.get(
        Uri.parse('https://cmsa.digital/admin/get_settingConference.php?conf_id=$conferenceId&admin_email=$adminEmail'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          nameController.text = data['conf_name'] ?? '';
          selectedStatus = data['conf_status'] ?? 'Active';
          selectedPubStatus = data['conf_pubst'] ?? 'Published';
          adminPassController.text = data['admin_pass'] ?? '';
          submitDate = data['conf_submitdate'] != null 
            ? DateTime.parse(data['conf_submitdate']) 
            : null;
          crSubmitDate = data['conf_crsubmitdate'] != null 
            ? DateTime.parse(data['conf_crsubmitdate']) 
            : null;
          confDate = data['conf_date'] != null 
            ? DateTime.parse(data['conf_date']) 
            : null;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, DateTime? initialDate, Function(DateTime) onSelect) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onSelect(picked);
    }
  }

  Future<void> saveSettings() async {
    final adminEmail = await ConferenceState.getAdminEmail();
    if (conferenceId == null || adminEmail == null) return;

    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Changes'),
          content: Text('Are you sure you want to save these changes?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final response = await http.post(
        Uri.parse('https://cmsa.digital/admin/edit_settingConference.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'conf_id': conferenceId,
          'conf_name': nameController.text,
          'conf_status': selectedStatus,
          'conf_submitdate': submitDate?.toIso8601String().split('T')[0],
          'conf_crsubmitdate': crSubmitDate?.toIso8601String().split('T')[0],
          'conf_date': confDate?.toIso8601String().split('T')[0],
          'conf_pubst': selectedPubStatus,
          'admin_email': adminEmail,
          'admin_pass': adminPassController.text,
        }),
      );

      final data = json.decode(response.body);
      if (data['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Settings saved successfully')),
        );
        
        // Return to previous page
        Navigator.pop(context);
      } else {
        throw Exception(data['error'] ?? 'Failed to save settings');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(0xFFFFC107); // Amber primary color
    final Color accentColor = Color(0xFFFFA000);  // Darker amber for accents
    final Color textColor = Colors.brown[800]!;   // Dark brown for text
    final Color backgroundColor = Color(0xFFFFF8E1); // Light amber background

    return Scaffold(
      appBar: AppBar(
        title: Text('Conference/Journal Settings', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: backgroundColor,
      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: accentColor))
        : SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Conference Information'),
                    SizedBox(height: 16),
                    
                    _buildLabel('Conf/Journal ID'),
                    TextField(
                      readOnly: true,
                      controller: TextEditingController(text: conferenceId),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    SizedBox(height: 20),

                    _buildLabel('Conf/Journal Name'),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    SizedBox(height: 20),

                    _buildLabel('Status'),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: ['Active', 'Inactive'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedStatus = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 20),

                    _buildSectionTitle('Important Dates'),
                    SizedBox(height: 16),

                    _buildLabel('Submission Date'),
                    _buildDatePicker(
                      submitDate,
                      (date) => setState(() => submitDate = date),
                      accentColor,
                    ),
                    SizedBox(height: 20),

                    _buildLabel('Camera Ready Submission Date'),
                    _buildDatePicker(
                      crSubmitDate,
                      (date) => setState(() => crSubmitDate = date),
                      accentColor,
                    ),
                    SizedBox(height: 20),

                    _buildLabel('Conf/Journal Date'),
                    _buildDatePicker(
                      confDate,
                      (date) => setState(() => confDate = date),
                      accentColor,
                    ),
                    SizedBox(height: 20),

                    _buildSectionTitle('Administration'),
                    SizedBox(height: 16),

                    _buildLabel('Admin Password'),
                    TextField(
                      controller: adminPassController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: !_showPassword,
                    ),
                    SizedBox(height: 20),

                    _buildLabel('Published Status'),
                    DropdownButtonFormField<String>(
                      value: selectedPubStatus,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: ['Published', 'Unpublished'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedPubStatus = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 3,
                      ),
                      child: Container(
                        width: double.infinity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildSectionTitle(String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Color(0xFFFFC107),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.brown[700],
        ),
      ),
    );
  }

  Widget _buildDatePicker(DateTime? date, Function(DateTime) onSelect, Color accentColor) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(
        text: date != null ? DateFormat('yyyy-MM-dd').format(date) : '',
      ),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        suffixIcon: Icon(Icons.calendar_today, color: accentColor),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onTap: () => _selectDate(context, date, onSelect),
    );
  }
}
