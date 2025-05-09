import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:CMSapplication/Admin/paperDetails.dart';
import 'package:CMSapplication/Admin/paperReview.dart';
import 'package:CMSapplication/Admin/paperCameraReady.dart';
import 'package:CMSapplication/Admin/paperPublishingManagement.dart';
import 'package:CMSapplication/Admin/paperPaymentDetails.dart';
import 'package:CMSapplication/Admin/paperAddCoauthor.dart';

class PaperDashboard extends StatefulWidget {
  final String paperId;

  const PaperDashboard({Key? key, required this.paperId}) : super(key: key);

  @override
  _PaperDashboardState createState() => _PaperDashboardState();
}

class _PaperDashboardState extends State<PaperDashboard> {
  bool _isLoading = true;
  String? _paperStatus;

  @override
  void initState() {
    super.initState();
    _fetchPaperStatus();
  }

  Future<void> _fetchPaperStatus() async {
    try {
      final response = await http.get(
        Uri.parse('https://cmsa.digital/admin/get_detailsPaper.php?paper_id=${widget.paperId}'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          _paperStatus = jsonData['paper_status'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching paper status: $e');
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Submitted':
        return Colors.orange;
      case 'Received':
        return Colors.blue;
      case 'Under Review':
        return Colors.purple;
      case 'Accepted':
        return Colors.green;
      case 'Resubmit':
        return Color(0xFFE65100);
      case 'Rejected':
        return Colors.red;
      case 'Withdrawal':
        return Colors.grey;
      case 'Pre-Camera Ready':
        return Colors.teal;
      case 'Camera Ready':
        return Colors.indigo;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if running on a larger screen (tablet or web)
    final bool isLargeScreen = MediaQuery.of(context).size.width > 600;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Paper Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        elevation:
            0, // Removes shadow for a cleaner look, matching modern design trends
        backgroundColor: Color(0xFFffc107),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true); // Send refresh signal back
          },
        ),
      ),
      backgroundColor: Color(0xFFF5F5F5), // Subtle background color
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffc107)),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0, left: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Color(0xFFffc107),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Paper Management',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Paper ID and Status display
                    Row(
                      children: [
                        // Paper ID
                        Container(
                          margin: EdgeInsets.only(bottom: 20, left: 4, right: 12),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFFE0E0E0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.label,
                                size: 16,
                                color: Color(0xFFffc107),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'ID: ${widget.paperId}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Paper Status
                        if (_paperStatus != null)
                          Container(
                            margin: EdgeInsets.only(bottom: 20),
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_paperStatus!).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getStatusColor(_paperStatus!).withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: _getStatusColor(_paperStatus!),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Status: $_paperStatus',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(_paperStatus!),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    // Grid
                    Expanded(
                      child: GridView.count(
                        physics: BouncingScrollPhysics(),
                        crossAxisCount: isLargeScreen ? 3 : 2, // More columns on larger screens
                        mainAxisSpacing: 16.0, // Reduced spacing
                        crossAxisSpacing: 16.0, // Reduced spacing
                        childAspectRatio: isLargeScreen ? 1.3 : 1.1, // Adjusted aspect ratio
                        children: [
                          _buildDashboardButton(
                            context,
                            'Paper Details',
                            Icons.description,
                            Colors.blueAccent,
                            'Manage basic paper information and details',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaperDetails(paperId: widget.paperId),
                                ),
                              ).then((value) {
                                if (value == true) {
                                  // Refresh data when coming back
                                  setState(() => _isLoading = true);
                                  _fetchPaperStatus();
                                }
                              });
                            },
                            isLargeScreen,
                          ),
                          _buildDashboardButton(
                            context,
                            'Paper Review',
                            Icons.rate_review,
                            Colors.green,
                            'Manage reviewer assignments and review comments',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaperReview(paperId: widget.paperId),
                                ),
                              ).then((value) {
                                if (value == true) {
                                  // Refresh data when coming back
                                  setState(() => _isLoading = true);
                                  _fetchPaperStatus();
                                }
                              });
                            },
                            isLargeScreen,
                          ),
                          _buildDashboardButton(
                            context,
                            'Camera Ready',
                            Icons.camera_alt,
                            Colors.deepPurple,
                            'Manage camera ready submissions',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PaperCameraReady(paperId: widget.paperId),
                                ),
                              ).then((value) {
                                if (value == true) {
                                  // Refresh data when coming back
                                  setState(() => _isLoading = true);
                                  _fetchPaperStatus();
                                }
                              });
                            },
                            isLargeScreen,
                          ),
                          _buildDashboardButton(
                            context,
                            'Publishing',
                            Icons.upload_file,
                            Colors.orange,
                            'Manage DOI, page numbers and publishing information',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PaperPublishingManagement(paperId: widget.paperId),
                                ),
                              ).then((value) {
                                if (value == true) {
                                  // Refresh data when coming back
                                  setState(() => _isLoading = true);
                                  _fetchPaperStatus();
                                }
                              });
                            },
                            isLargeScreen,
                          ),
                          _buildDashboardButton(
                            context,
                            'Payment',
                            Icons.payment,
                            Colors.redAccent,
                            'Manage payment status and transaction details',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PaperPaymentDetails(paperId: widget.paperId),
                                ),
                              ).then((value) {
                                if (value == true) {
                                  // Refresh data when coming back
                                  setState(() => _isLoading = true);
                                  _fetchPaperStatus();
                                }
                              });
                            },
                            isLargeScreen,
                          ),
                          _buildDashboardButton(
                            context,
                            'Co-Authors',
                            Icons.person_add,
                            Colors.teal,
                            'Add or manage paper co-authors',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PaperAddCoauthor(paperId: widget.paperId),
                                ),
                              ).then((value) {
                                if (value == true) {
                                  // Refresh data when coming back
                                  setState(() => _isLoading = true);
                                  _fetchPaperStatus();
                                }
                              });
                            },
                            isLargeScreen,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDashboardButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onPressed,
    bool isLargeScreen,
  ) {
    return Card(
      elevation: 2,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                color.withOpacity(0.1),
              ],
              stops: [0.6, 1.0], // Gradient is more subtle
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isLargeScreen ? 12.0 : 8.0), // Smaller padding on larger screens
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular icon background
                Container(
                  padding: EdgeInsets.all(isLargeScreen ? 10 : 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: isLargeScreen ? 24 : 20, // Smaller icon on larger screens
                    color: color,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 8 : 6),
                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: isLargeScreen ? 14 : 15, // Slightly smaller text on larger screens
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 4),
                // Subtitle - show condensed version on larger screens
                if (isLargeScreen || MediaQuery.of(context).size.width > 400)
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isLargeScreen ? 10 : 11,
                      height: 1.2,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}