import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:CMSapplication/services/conference_state.dart';
import 'package:CMSapplication/Admin/paperCameraReady.dart';
import 'package:CMSapplication/Admin/manageConferencePage.dart';
import 'package:CMSapplication/Admin/managePapersPage.dart';
import 'package:CMSapplication/Admin/manageNewsPage.dart';
import 'package:CMSapplication/Admin/managePaymentsPage.dart';
import 'package:CMSapplication/Admin/manageMessagesPage.dart';
import 'package:CMSapplication/Admin/manageUserAccountPage.dart';
import 'package:CMSapplication/Admin/manageSettingsPage.dart';
import 'package:CMSapplication/main.dart';
import '../config/app_config.dart';

class ManageCameraReadyPage extends StatefulWidget {
  @override
  _ManageCameraReadyPageState createState() => _ManageCameraReadyPageState();
}

class _ManageCameraReadyPageState extends State<ManageCameraReadyPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSearchType = 'Paper Title';
  String _selectedUserStatus = 'All';
  List<dynamic> _allPapers = [];
  List<dynamic> _filteredPapers = [];
  bool _isLoading = true;
  String? selectedConferenceId;
  bool isSearching = false;
  int currentPage = 1;
  int itemsPerPage = 20;
  int totalPages = 1;

  final List<String> _searchTypes = ['Paper Title', 'Author Name', 'Paper ID'];
  final List<String> _userStatusTypes = ['All', 'Student', 'Non-Student'];

  @override
  void initState() {
    super.initState();
    loadSelectedConference().then((_) => _fetchPapers());
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
        '${AppConfig.baseUrl}admin/get_cameraReadyPapers.php?search=$searchTerm&type=$_selectedSearchType&status=$_selectedUserStatus&conf_id=$confId');
    
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
    if (_searchController.text.isEmpty) {
      _filteredPapers = List.from(_allPapers);
    } else {
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
    
    // Apply status filter if not 'All'
    if (_selectedUserStatus != 'All') {
      _filteredPapers = _filteredPapers.where((paper) => 
        paper['user_type'] == _selectedUserStatus
      ).toList();
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

  Future<List<dynamic>> _fetchCoauthors(String paperId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}admin/get_cameraReadyCoauthor.php?paper_id=$paperId'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load co-authors');
      }
    } catch (e) {
      print('Error fetching co-authors: $e');
      return [];
    }
  }

  void _showCoauthorsDialog(String paperId) async {
    final coauthors = await _fetchCoauthors(paperId);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          child: Container(
            padding: EdgeInsets.all(24),
            constraints: BoxConstraints(maxWidth: 500, maxHeight: 600),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient background
                Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people, color: Colors.blue, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Co-Authors List',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        onPressed: () => Navigator.of(context).pop(),
                        hoverColor: Colors.red[50],
                      ),
                    ],
                  ),
                ),
                Divider(thickness: 1, color: Colors.grey[300]),
                SizedBox(height: 16),
                // Co-authors list
                Expanded(
                  child: coauthors.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_off,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No co-authors found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: coauthors.length,
                          itemBuilder: (context, index) {
                            final coauthor = coauthors[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.person, 
                                            color: Colors.blue[700],
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            coauthor['coauthor_name'] ?? '',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue[900],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.email, 
                                            color: Colors.blue[400],
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            coauthor['coauthor_email'] ?? '',
                                            style: TextStyle(
                                              color: Colors.blue[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.business, 
                                            color: Colors.blue[400],
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              coauthor['coauthor_organization'] ?? '',
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Ready Papers', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Color(0xFFffc107),
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  _searchController.clear();
                  _filterPapers();
                }
              });
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Container(
        color: Colors.grey[50],
        child: Column(
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
                    
                    // User Status Filter
                    Row(
                      children: [
                        Text('User Status:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                value: _selectedUserStatus,
                                isExpanded: true,
                                items: _userStatusTypes.map((String option) {
                                  return DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(option),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedUserStatus = newValue;
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
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Color(0xFFffc107), width: 4),
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                child: Text(
                  'List of Camera Ready Papers',
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ),
            
            // Papers List
            Expanded(
              child: _isLoading
                ? Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffc107)),
                  ))
                : _filteredPapers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description_outlined, size: 64, color: Color(0xFFffc107)),
                            SizedBox(height: 16),
                            Text(
                              isSearching ? 'No matching papers found' : 'No camera ready papers found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
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
                        padding: EdgeInsets.fromLTRB(20, 8, 20, 80),
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
                            margin: EdgeInsets.only(bottom: 12, left: 4, right: 4),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFffa000).withOpacity(0.1),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Color(0xFFffe082)),
                                        ),
                                        child: Text(
                                          'ID: ${paper['paper_id'] ?? ''}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFcc9600),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          paper['paper_title'] ?? '',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF333333),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                      _buildInfoRow(
                                        icon: Icons.person,
                                        label: 'Author',
                                        value: paper['user_name'] ?? '',
                                      ),
                                      SizedBox(height: 8),
                                      _buildInfoRow(
                                        icon: Icons.file_copy,
                                        label: 'Page No',
                                        value: paper['paper_pageno'] ?? '',
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Color(0xFFffc107)),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            constraints: BoxConstraints(
                                              maxWidth: 36,
                                              maxHeight: 36,
                                            ),
                                            child: IconButton(
                                              icon: Icon(Icons.remove_red_eye, color: Color(0xFFffc107), size: 20),
                                              padding: EdgeInsets.zero,
                                              onPressed: () {
                                                _showCoauthorsDialog(paper['paper_id']);
                                              },
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            icon: Icon(Icons.visibility, size: 18),
                                            label: Text('View Details'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(0xFFffc107),
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            ),
                                            onPressed: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => PaperCameraReady(
                                                    paperId: paper['paper_id'],
                                                  ),
                                                ),
                                              );
                                              if (context.mounted) {
                                                _fetchPapers();
                                              }
                                            },
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
                  icon: Icons.camera,
                  title: 'Camera Ready',
                  isActive: true,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _allPapers = [];
                      _filteredPapers = [];
                      _isLoading = true;
                    });
                    _fetchPapers();
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
}

void main() {
  runApp(MaterialApp(
    home: ManageCameraReadyPage(),
  ));
}