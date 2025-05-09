import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'manageUserAccountPage.dart';
import '../services/conference_state.dart';

class MemberDetails extends StatefulWidget {
  final String memberId;

  MemberDetails({required this.memberId});

  @override
  _MemberDetailsState createState() => _MemberDetailsState();
}

class _MemberDetailsState extends State<MemberDetails> {
  Map<String, dynamic> memberDetails = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMemberDetails();
  }

  Future<void> fetchMemberDetails() async {
    try {
      final response = await http.get(
        Uri.parse('https://cmsa.digital/admin/get_detailsMember.php?member_id=${widget.memberId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          memberDetails = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password'),
        content: Text('Are you sure you want to reset this member\'s password?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text('Reset'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Get conference ID from shared preferences
        String? confId = await ConferenceState.getSelectedConferenceId();
        
        if (confId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Conference ID not found. Please select a conference first.')),
          );
          return;
        }
        
        final response = await http.get(
          Uri.parse('https://cmsa.digital/admin/reset_memberPassword.php?member_id=${widget.memberId}&conf_id=$confId'),
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseData['message'])),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ManageUserAccountPage()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${responseData['message']}')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reset password. HTTP Error: ${response.statusCode}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resetting password: $e')),
        );
      }
    }
  }

  Future<void> _removeAccount() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Account'),
        content: Text('Are you sure you want to remove this account? This action cannot be undone.'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text('Remove', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.post(
          Uri.parse('https://cmsa.digital/admin/edit_detailsMember.php'),
          body: {
            'action': 'remove_account',
            'member_id': widget.memberId,
          },
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Account removed successfully')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ManageUserAccountPage()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing account: $e')),
        );
      }
    }
  }

  Widget _buildInfoField(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              value ?? 'Not provided',
              style: TextStyle(
                fontSize: 15,
                color: value == null ? Colors.grey : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Member Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Color(0xFFffc107),
        elevation: 2,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffc107)),
            ))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Color(0xFFffc107).withOpacity(0.2),
                              backgroundImage: memberDetails['profile_image'] != null
                                  ? NetworkImage(memberDetails['profile_image'] + '?v=${DateTime.now().millisecondsSinceEpoch}')
                                  : AssetImage('assets/images/NullProfilePicture.png')
                                      as ImageProvider,
                            ),
                            SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${memberDetails['user_title'] ?? ''} ${memberDetails['user_name'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    memberDetails['user_email'] ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                  
                  // Personal Information
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFcc9600),
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildInfoField('Phone', memberDetails['user_phone']),
                        Divider(height: 1, color: Colors.grey[200]),
                        _buildInfoField('Organization', memberDetails['user_org']),
                        Divider(height: 1, color: Colors.grey[200]),
                        _buildInfoField('Mailing Address', memberDetails['user_address']),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  // Reviewer Information
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reviewer Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFcc9600),
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildInfoField('Status', memberDetails['rev_status']),
                        Divider(height: 1, color: Colors.grey[200]),
                        _buildInfoField('Expertise', memberDetails['rev_expert']),
                        Divider(height: 1, color: Colors.grey[200]),
                        _buildInfoField('Registration Date', 
                          memberDetails['user_datereg'] != null 
                            ? DateTime.parse(memberDetails['user_datereg'])
                                .toLocal()
                                .toString()
                                .split(' ')[0]
                                .split('-')
                                .reversed
                                .join('/')
                            : null),
                        Divider(height: 1, color: Colors.grey[200]),
                        _buildInfoField('OTP', memberDetails['user_otp']),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),

                  // Action Buttons
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.lock_reset, size: 18),
                            label: Text(
                              'Reset Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onPressed: _resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFffc107),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: Size(double.infinity, 50),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.delete_outline, size: 18),
                            label: Text(
                              'Remove Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onPressed: _removeAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: Size(double.infinity, 50),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
