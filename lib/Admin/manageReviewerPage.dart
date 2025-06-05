import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'manageUserAccountPage.dart';
import 'package:CMSapplication/Admin/manageConferencePage.dart';
import 'package:CMSapplication/Admin/managePapersPage.dart';
import 'package:CMSapplication/Admin/manageNewsPage.dart';
import 'package:CMSapplication/Admin/manageCameraReadyPage.dart';
import 'package:CMSapplication/Admin/managePaymentsPage.dart';
import 'package:CMSapplication/Admin/manageMessagesPage.dart';
import 'package:CMSapplication/Admin/manageSettingsPage.dart';
import 'package:CMSapplication/main.dart';
import 'package:CMSapplication/services/conference_state.dart';
import 'package:CMSapplication/Admin/reviewerDetails.dart';
import 'addReviewer.dart';

class ManageReviewerPage extends StatefulWidget {
  @override
  _ManageReviewerPageState createState() => _ManageReviewerPageState();
}

class _ManageReviewerPageState extends State<ManageReviewerPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSearchBy = 'Name';
  String _selectedStatus = 'All';
  List<dynamic> _allReviewers = [];
  List<dynamic> _filteredReviewers = [];
  bool _isLoading = false;
  String? selectedConferenceId;
  bool isSearching = false;
  int currentPage = 1;
  int itemsPerPage = 20;
  int totalPages = 1;

  final List<String> _searchOptions = [
    'Name',
    'Expertise',
    'Email',
    'Country'
  ];

  final List<String> _statusOptions = [
    'All',
    'Verified',
    'Unverified'
  ];

  @override
  void initState() {
    super.initState();
    loadSelectedConference();
    _fetchReviewers();
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

  Future<void> _fetchReviewers() async {
    setState(() => _isLoading = true);
    try {
      final searchTerm = _searchController.text;
      final response = await http.get(
        Uri.parse('https://cmsa.digital/admin/get_detailsReviewer.php'
            '?search=${Uri.encodeComponent(searchTerm)}'
            '&searchBy=${Uri.encodeComponent(_selectedSearchBy)}'
            '&status=${Uri.encodeComponent(_selectedStatus)}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _allReviewers = json.decode(response.body);
          _filterReviewers();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reviewers: $e')),
      );
    }
  }

  void _filterReviewers() {
    if (_searchController.text.isEmpty) {
      _filteredReviewers = List.from(_allReviewers);
    } else {
      final searchTerm = _searchController.text.toLowerCase();
      _filteredReviewers = _allReviewers.where((reviewer) {
        switch (_selectedSearchBy) {
          case 'Name':
            return reviewer['user_name'].toString().toLowerCase().contains(searchTerm);
          case 'Expertise':
            return reviewer['rev_expert'].toString().toLowerCase().contains(searchTerm);
          case 'Email':
            return reviewer['user_email'].toString().toLowerCase().contains(searchTerm);
          case 'Country':
            return reviewer['user_country'].toString().toLowerCase().contains(searchTerm);
          default:
            return false;
        }
      }).toList();
    }
    
    // Apply status filter if not 'All'
    if (_selectedStatus != 'All') {
      _filteredReviewers = _filteredReviewers.where((reviewer) => 
        reviewer['rev_status'] == _selectedStatus
      ).toList();
    }
    
    // Calculate total pages
    totalPages = (_filteredReviewers.length / itemsPerPage).ceil();
    if (currentPage > totalPages && totalPages > 0) {
      currentPage = totalPages;
    } else if (totalPages == 0) {
      currentPage = 1;
    }
  }

  List<dynamic> getPaginatedReviewers() {
    if (_filteredReviewers.isEmpty) return [];
    
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage > _filteredReviewers.length 
        ? _filteredReviewers.length 
        : startIndex + itemsPerPage;
    
    if (startIndex >= _filteredReviewers.length) return [];
    return _filteredReviewers.sublist(startIndex, endIndex);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviewers', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFffc107),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  _searchController.clear();
                  _filterReviewers();
                }
              });
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSearching)
            Padding(
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
                        prefixIcon: Icon(Icons.search, color: Color(0xFFffc107)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _filterReviewers();
                        });
                      },
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Search by dropdown
                  Row(
                    children: [
                      Text('Search by:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSearchBy,
                              isExpanded: true,
                              items: _searchOptions.map((String option) {
                                return DropdownMenuItem<String>(
                                  value: option,
                                  child: Text(option),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedSearchBy = newValue;
                                    _filterReviewers();
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
                      Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedStatus,
                              isExpanded: true,
                              items: _statusOptions.map((String option) {
                                return DropdownMenuItem<String>(
                                  value: option,
                                  child: Text(option),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedStatus = newValue;
                                    _filterReviewers();
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
            
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Results Title
                SizedBox(height: 16),
                Text(
                  'List of Reviewers',
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Toggle buttons for Member/Reviewer
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ManageUserAccountPage(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Member',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Reviewer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFffc107),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
            
          // Reviewers List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffc107)),
                  ))
                : _filteredReviewers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search, size: 64, color: Color(0xFFffc107)),
                            SizedBox(height: 16),
                            Text(
                              isSearching ? 'No matching reviewers found.' : 'No reviewers found.',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            if (isSearching)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Try changing your search criteria.',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(8, 8, 8, 60),
                        itemCount: getPaginatedReviewers().length + 1,
                        itemBuilder: (context, index) {
                          if (index == getPaginatedReviewers().length) {
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
                          
                          final reviewers = getPaginatedReviewers();
                          final reviewer = reviewers[index];
                          
                          return Card(
                            margin: EdgeInsets.only(bottom: 12, left: 4, right: 4),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row with status on the right
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: MediaQuery.of(context).size.width * 0.5,
                                        child: Text(
                                          reviewer['user_name'] ?? '',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: reviewer['rev_status'] == 'Verified'
                                              ? Colors.green[100]
                                              : Colors.orange[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          reviewer['rev_status'] ?? '',
                                          style: TextStyle(
                                            color: reviewer['rev_status'] == 'Verified'
                                                ? Colors.green[900]
                                                : Colors.orange[900],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 12),
                                  
                                  // Middle section with avatar and info
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundImage: reviewer['profile_image'] != null
                                            ? NetworkImage(reviewer['profile_image'])
                                            : AssetImage('assets/images/NullProfilePicture.png')
                                                as ImageProvider,
                                      ),
                                      SizedBox(width: 16),
                                      
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(reviewer['rev_expert'] ?? ''),
                                            SizedBox(height: 4),
                                            Text(
                                              reviewer['user_email'] ?? '',
                                              style: TextStyle(color: Colors.blue),
                                            ),
                                            SizedBox(height: 4),
                                            Text(reviewer['user_country'] ?? ''),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 8),
                                  
                                  // Bottom section with arrow button
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: IconButton(
                                      icon: Icon(Icons.arrow_forward_ios, color: Color(0xFFffc107)),
                                      onPressed: () async {
                                        if (reviewer['user_id'] != null) {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ReviewerDetails(
                                                reviewerId: reviewer['user_id'].toString(),
                                              ),
                                            ),
                                          );
                                          if (context.mounted) {
                                            _fetchReviewers();
                                          }
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: Reviewer ID not found')),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddReviewer()),
          );
        },
        backgroundColor: Color(0xFFffc107),
        child: Icon(Icons.add, color: Colors.white),
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
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ManagePapersPage()));
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
                  icon: Icons.person_outline,
                  title: 'Reviewers',
                  isActive: true,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _allReviewers = [];
                      _filteredReviewers = [];
                    });
                    _fetchReviewers();
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
}
