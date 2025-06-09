import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:CMSapplication/Admin/paperReviewDetails.dart';
import 'package:CMSapplication/Admin/addPaperReviewer.dart';
import '../config/app_config.dart'; // Import AppConfig

class PaperReview extends StatefulWidget {
  final String paperId;

  const PaperReview({Key? key, required this.paperId}) : super(key: key);

  @override
  _PaperReviewState createState() => _PaperReviewState();
}

class _PaperReviewState extends State<PaperReview> {
  bool _isLoading = true;
  List<dynamic> _reviewers = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchReviewers();
  }

  Future<void> _fetchReviewers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}admin/get_paperReview.php?paper_id=${widget.paperId}'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          setState(() {
            _reviewers = jsonResponse['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = jsonResponse['message'] ?? 'Failed to load reviewers';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      // Parse the date string from the server
      DateTime dateTime = DateTime.parse(dateTimeStr);
      
      // Format the date as DD/MM/YY
      String formattedDate = DateFormat('dd/MM/yy').format(dateTime);
      
      // Format the time as hh:mma
      String formattedTime = DateFormat('hh:mma').format(dateTime);
      
      return '$formattedDate $formattedTime';
    } catch (e) {
      return dateTimeStr; // Return original if parsing fails
    }
  }

  // Method to determine if text should be white or dark based on background
  Color _getTextColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5 
        ? backgroundColor.withOpacity(1.0) 
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); // Send refresh signal
        return false; // Prevent default back behavior
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text('Paper Review', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFFffc107),
        foregroundColor: Colors.white,
        elevation: 2,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, true); // Send refresh signal back
            },
          ),
      ),
      body: Container(
        color: Colors.grey[50],
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffc107)),
                ),
              )
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Container(
                      margin: EdgeInsets.all(20),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFffebc0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Color(0xFFffc107)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFFcc9600),
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No current reviewer assigned. Please assign reviewer/s using the button below.',
                            style: TextStyle(fontSize: 16, color: Color(0xFF424242)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 16.0,
                        left: 16.0,
                        right: 16.0,
                        bottom: 80.0
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Color(0xFFffc107).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(0xFFffc107).withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people, color: Color(0xFFcc9600)),
                                SizedBox(width: 8),
                                Text(
                                  'Current Reviewers',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFcc9600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          _reviewers.isEmpty
                              ? Center(
                                  child: Container(
                                    margin: EdgeInsets.all(20),
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFffebc0),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Color(0xFFffc107)),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Color(0xFFcc9600),
                                          size: 48,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No current reviewer assigned. Please assign reviewer/s using the button below.',
                                          style: TextStyle(fontSize: 16, color: Color(0xFF424242)),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: _reviewers.length,
                                  itemBuilder: (context, index) {
                                    final reviewer = _reviewers[index];
                                    return _buildReviewerCard(reviewer);
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPaperReviewer(paperId: widget.paperId),
            ),
          );
          
          // Refresh the reviewer list if we get a positive result
          if (result == true) {
            setState(() {
              _isLoading = true;
              _errorMessage = '';
            });
            _fetchReviewers();
          }
        },
        backgroundColor: Color(0xFFffc107),
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
        elevation: 2,
        ),
      ),
    );
  }

  Widget _buildReviewerCard(dynamic reviewer) {
    final bool isReviewed = reviewer['review_status'] == 'Reviewed';
    final bool isDeclined = reviewer['review_status'] == 'Declined';
    
    Color statusColor = isDeclined 
        ? Colors.red 
        : (isReviewed ? Colors.green : Color(0xFFffa000));
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFffa000).withOpacity(0.65),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFFffe082)),
                  ),
                  child: Text(
                    'ID: ${reviewer['review_id'].toString()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFcc9600),
                      fontSize: 16,
                    ),
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.8),
                    border: Border.all(
                      color: statusColor,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    reviewer['review_status'],
                    style: TextStyle(
                      color: _getTextColor(statusColor),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  icon: Icons.person,
                  label: 'Reviewer',
                  value: reviewer['user_name'],
                ),
                SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.star,
                  label: 'Marks',
                  value: reviewer['review_totalmarks'] ?? 'Not yet marked',
                ),
                SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: _formatDateTime(reviewer['review_date']),
                ),
                Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaperReviewDetails(
                              reviewId: reviewer['review_id'].toString(),
                            ),
                          ),
                        );
                        if (result == true) {
                          // Refresh the reviewers list if changes were made
                          _fetchReviewers();
                        }
                      },
                      icon: Icon(Icons.visibility),
                      label: Text('View Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFffc107),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Color(0xFFcc9600)),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
