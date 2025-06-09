import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:CMSapplication/Admin/manageConferencePage.dart';
import 'package:CMSapplication/Admin/manageNewsPage.dart';
import 'package:CMSapplication/Admin/manageUserAccountPage.dart';
import 'package:CMSapplication/Admin/manageCameraReadyPage.dart';
import 'package:CMSapplication/Admin/managePaymentsPage.dart';
import 'package:CMSapplication/Admin/manageMessagesPage.dart';
import 'package:CMSapplication/Admin/manageSettingsPage.dart';
import 'package:CMSapplication/main.dart';
import 'package:CMSapplication/services/conference_state.dart';
import 'package:CMSapplication/Admin/paperDashboard.dart';
import '../config/app_config.dart'; // Import AppConfig

class ManagePapersPage extends StatefulWidget {
  @override
  _ManagePapersPageState createState() => _ManagePapersPageState();
}

class _ManagePapersPageState extends State<ManagePapersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSearchType = 'Paper Title';
  String _selectedStatus = 'All';
  List<dynamic> _allPapers = [];
  List<dynamic> _filteredPapers = [];
  bool _isLoading = true;
  String? selectedConferenceId;
  bool isSearching = false;
  int currentPage = 1;
  int itemsPerPage = 20;
  int totalPages = 1;

  final List<String> _searchTypes = ['Paper Title', 'Author Name', 'Paper ID'];
  final List<String> _statusTypes = [
    'All',
    'Submitted',
    'Received',
    'Under Review',
    'Accepted',
    'Resubmit',
    'Rejected',
    'Withdrawal',
    'Pre-Camera Ready',
    'Camera Ready'
  ];

  @override
  void initState() {
    super.initState();
    loadSelectedConference();
    _fetchPapers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadSelectedConference() async {
    final confId = await ConferenceState.getSelectedConferenceId();
    setState(() {
      selectedConferenceId = confId;
    });
  }

  Future<void> _fetchPapers() async {
    setState(() {
      _isLoading = true;
    });
    
    final searchTerm = _searchController.text;
    final confId = await ConferenceState.getSelectedConferenceId();
    
    final url = Uri.parse(
        '${AppConfig.baseUrl}admin/get_papers.php?search=$searchTerm&type=$_selectedSearchType&status=$_selectedStatus&conf_id=$confId');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _allPapers = json.decode(response.body);
          _filterPapers();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching papers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPapers() {
    // If there's no search input, don't filter
    if (_searchController.text.isEmpty) {
      _filteredPapers = List.from(_allPapers);
    } else {
      // Filter based on search text and type
      final searchTerm = _searchController.text.toLowerCase();
      _filteredPapers = _allPapers.where((paper) {
        switch (_selectedSearchType) {
          case 'Paper Title':
            return paper['paper_title'].toString().toLowerCase().contains(searchTerm);
          case 'Author Name':
            return paper['user_name'].toString().toLowerCase().contains(searchTerm);
          case 'Paper ID':
            return paper['paper_id'].toString().toLowerCase().contains(searchTerm);
          default:
            return false;
        }
      }).toList();
    }

    // Filter by status if not "All"
    if (_selectedStatus != 'All') {
      _filteredPapers = _filteredPapers.where((paper) {
        return paper['paper_status'] == _selectedStatus;
      }).toList();
    }

    // Calculate total pages
    totalPages = (_filteredPapers.length / itemsPerPage).ceil();
    if (currentPage > totalPages && totalPages > 0) {
      currentPage = totalPages;
    } else if (totalPages == 0) {
      currentPage = 1;
    }
  }

  List<dynamic> getPaginatedPapers() {
    if (_filteredPapers.isEmpty) return [];
    
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage > _filteredPapers.length 
        ? _filteredPapers.length 
        : startIndex + itemsPerPage;
    
    if (startIndex >= _filteredPapers.length) return [];
    return _filteredPapers.sublist(startIndex, endIndex);
  }

  void nextPage() {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
    }
  }

  void previousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() {
        currentPage = page;
      });
    }
  }

  // Add this method to get color based on status
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
        return Colors.amber;
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

  // Add this method to determine text color based on background color brightness
  Color _getTextColor(Color backgroundColor) {
    // If the background color is dark, use white text; otherwise, use the same color but darker
    return backgroundColor.computeLuminance() > 0.5 
        ? backgroundColor.withOpacity(1.0) 
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Papers', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFFffc107),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  _searchController.clear();
                  _selectedStatus = 'All';
                  _fetchPapers();
                }
              });
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          if (isSearching)
            Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Icon(Icons.search, color: Color(0xFFcc9600)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _filterPapers();
                        });
                      },
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Search by dropdown
                  Row(
                    children: [
                      Text('Search by:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF757575))),
                      SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.white,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSearchType,
                              isExpanded: true,
                              items: _searchTypes.map((String option) {
                                return DropdownMenuItem<String>(
                                  value: option,
                                  child: Text(option),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedSearchType = newValue;
                                    _filterPapers();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Status Filter
                  Row(
                    children: [
                      Text('Paper Status:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF757575))),
                      SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.white,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedStatus,
                              isExpanded: true,
                              items: _statusTypes.map((String option) {
                                return DropdownMenuItem<String>(
                                  value: option,
                                  child: Text(option),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedStatus = newValue;
                                    _filterPapers();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
          // Results Title
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Color(0xFFffc107).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFFffc107).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.list_alt, color: Color(0xFFcc9600)),
                SizedBox(width: 8),
                Text(
                  'List of Papers',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFcc9600),
                  ),
                ),
              ],
            ),
          ),
          
          // Papers List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffc107)),
                    ),
                  )
                : _filteredPapers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              isSearching ? 'No matching papers found' : 'No papers found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              isSearching
                                  ? 'Try changing your search criteria'
                                  : 'No papers available for this conference',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: getPaginatedPapers().length + 1,
                        itemBuilder: (context, index) {
                          if (index == getPaginatedPapers().length) {
                            // Add pagination controls inside the ListView
                            return Container(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // First page
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.keyboard_double_arrow_left),
                                      onPressed: currentPage > 1 ? () => goToPage(1) : null,
                                      color: currentPage > 1 ? Color(0xFFffc107) : Colors.grey[400],
                                      iconSize: 18,
                                      padding: EdgeInsets.all(8),
                                      constraints: BoxConstraints(maxWidth: 36, maxHeight: 36),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  
                                  // Previous page
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: Colors.grey[300]!),
                                        bottom: BorderSide(color: Colors.grey[300]!),
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.chevron_left),
                                      onPressed: currentPage > 1 ? previousPage : null,
                                      color: currentPage > 1 ? Color(0xFFffc107) : Colors.grey[400],
                                      iconSize: 18,
                                      padding: EdgeInsets.all(8),
                                      constraints: BoxConstraints(maxWidth: 36, maxHeight: 36),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  
                                  // Page number
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFffc107),
                                      border: Border.all(color: Color(0xFFffc107)),
                                    ),
                                    child: Text(
                                      '$currentPage',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  
                                  // Next page
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: Colors.grey[300]!),
                                        bottom: BorderSide(color: Colors.grey[300]!),
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.chevron_right),
                                      onPressed: currentPage < totalPages ? nextPage : null,
                                      color: currentPage < totalPages ? Color(0xFFffc107) : Colors.grey[400],
                                      iconSize: 18,
                                      padding: EdgeInsets.all(8),
                                      constraints: BoxConstraints(maxWidth: 36, maxHeight: 36),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  
                                  // Last page
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.keyboard_double_arrow_right),
                                      onPressed: currentPage < totalPages ? () => goToPage(totalPages) : null,
                                      color: currentPage < totalPages ? Color(0xFFffc107) : Colors.grey[400],
                                      iconSize: 18,
                                      padding: EdgeInsets.all(8),
                                      constraints: BoxConstraints(maxWidth: 36, maxHeight: 36),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          final papers = getPaginatedPapers();
                          final paper = papers[index];
                          
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
                                          'ID: ${paper['paper_id'] ?? ''}',
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
                                          color: _getStatusColor(paper['paper_status'] ?? '').withOpacity(0.8),
                                          border: Border.all(
                                            color: _getStatusColor(paper['paper_status'] ?? ''),
                                            width: 1.5,
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          paper['paper_status'] ?? '',
                                          style: TextStyle(
                                            color: _getTextColor(_getStatusColor(paper['paper_status'] ?? '')),
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
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 16),
                                        child: Text(
                                          paper['paper_title'] ?? '',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF555555),
                                          ),
                                        ),
                                      ),
                                      _buildInfoRow(
                                        icon: Icons.person,
                                        label: 'Author',
                                        value: paper['user_name'] ?? '',
                                      ),
                                      SizedBox(height: 12),
                                      _buildInfoRow(
                                        icon: Icons.calendar_today,
                                        label: 'Submission Date',
                                        value: _formatDate(paper['paper_date'] ?? ''),
                                      ),
                                      Divider(height: 24),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => PaperDashboard(paperId: paper['paper_id']),
                                                ),
                                              );
                                              if (context.mounted) {
                                                _fetchPapers();
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
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFffc107),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    selectedConferenceId ?? 'No Conference Selected',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Conference Management System',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.list,
                  title: 'Conf/Journal',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ManageConferencePage()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.newspaper,
                  title: 'News',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ManageNewsPage()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.file_copy,
                  title: 'Papers',
                  isActive: true,
                  onTap: () {
                    Navigator.pop(context);
                    _fetchPapers();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'User Account',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ManageUserAccountPage()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.camera,
                  title: 'Camera Ready',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ManageCameraReadyPage()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.money,
                  title: 'Payments',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ManagePaymentsPage()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.message,
                  title: 'Messages',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ManageMessagesPage()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ManageSettingsPage()));
                  },
                ),
                Divider(),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () async {
                    await ConferenceState.clearSelectedConference();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => MainPage()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
    bool isActive = false,
  }) {
    return Container(
      color: isActive ? Color(0xFFffc107).withOpacity(0.1) : null,
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? Color(0xFFcc9600) : iconColor ?? Colors.grey[700],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Color(0xFFcc9600) : textColor ?? Colors.black87,
            fontWeight: isActive ? FontWeight.bold : null,
          ),
        ),
        onTap: onTap,
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/'
             '${date.month.toString().padLeft(2, '0')}/'
             '${date.year.toString().substring(2)}';
    } catch (e) {
      return dateStr;
    }
  }
}

void main() {
  runApp(MaterialApp(
    home: ManagePapersPage(),
  ));
}