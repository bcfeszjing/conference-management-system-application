import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:CMSapplication/User/addUserPaper.dart';
import 'package:CMSapplication/services/conference_state.dart';
import 'package:CMSapplication/User/manageUserNewsPage.dart';
import '../config/app_config.dart';

class SelectConference extends StatefulWidget {
  const SelectConference({Key? key}) : super(key: key);

  @override
  State<SelectConference> createState() => _SelectConferenceState();
}

class _SelectConferenceState extends State<SelectConference> {
  List<dynamic> conferences = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchConferences();
  }

  Future<void> fetchConferences() async {
    setState(() => isLoading = true);
    
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}user/get_selectConference.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            conferences = data['conferences'];
            isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load conferences');
        }
      } else {
        throw Exception('Failed to load conferences');
      }
    } catch (e) {
      print('Error fetching conferences: $e');
      setState(() => isLoading = false);
    }
  }

  bool isDatePassed(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return date.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Conference'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[50],
        child: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading conferences...', style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : conferences.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No conferences available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back later for upcoming conferences',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.event_note, color: Colors.blue, size: 24),
                                const SizedBox(width: 12),
                                const Text(
                                  'Available Conferences',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select a conference to submit your paper',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Conference cards
                      ...conferences.map<Widget>((conference) {
                        final bool isExpired = isDatePassed(conference['conf_submitdate']);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.blue.shade100),
                                          ),
                                          child: Text(
                                            conference['conf_id'],
                                            style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            conference['conf_name'],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                          color: isExpired ? Colors.red[400] : Colors.green[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Submission Deadline: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          DateFormat('dd MMM yyyy').format(
                                            DateTime.parse(conference['conf_submitdate']),
                                          ),
                                          style: TextStyle(
                                            color: isExpired ? Colors.red[600] : Colors.green[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Status and action bar
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isExpired ? Colors.grey[50] : Colors.blue[50],
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (isExpired)
                                      Row(
                                        children: [
                                          Icon(Icons.lock, size: 16, color: Colors.red[600]),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Submission Closed',
                                            style: TextStyle(
                                              color: Colors.red[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Row(
                                        children: [
                                          Icon(Icons.check_circle_outline, size: 16, color: Colors.green[600]),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Open for Submissions',
                                            style: TextStyle(
                                              color: Colors.green[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    
                                    if (!isExpired)
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AddUserPaper(
                                                confId: conference['conf_id'],
                                                confName: conference['conf_name'],
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Text('Select'),
                                        label: const Icon(Icons.arrow_forward),
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.blue,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                          minimumSize: const Size(0, 36),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
      ),
    );
  }
}
