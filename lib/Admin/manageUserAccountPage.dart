import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'manageReviewerPage.dart';
import 'package:CMSapplication/Admin/manageConferencePage.dart';
import 'package:CMSapplication/Admin/managePapersPage.dart';
import 'package:CMSapplication/Admin/manageNewsPage.dart';
import 'package:CMSapplication/Admin/manageCameraReadyPage.dart';
import 'package:CMSapplication/Admin/managePaymentsPage.dart';
import 'package:CMSapplication/Admin/manageMessagesPage.dart';
import 'package:CMSapplication/Admin/manageSettingsPage.dart';
import 'package:CMSapplication/main.dart';
import 'package:CMSapplication/services/conference_state.dart';
import 'package:CMSapplication/Admin/memberDetails.dart';
import '../config/app_config.dart';

class ManageUserAccountPage extends StatefulWidget {
  @override
  _ManageUserAccountPageState createState() => _ManageUserAccountPageState();
}

class _ManageUserAccountPageState extends State<ManageUserAccountPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSearchBy = 'Name';
  List<dynamic> _allMembers = [];
  List<dynamic> _filteredMembers = [];
  bool _isLoading = false;
  String? selectedConferenceId;
  bool isSearching = false;
  int currentPage = 1;
  int itemsPerPage = 20;
  int totalPages = 1;

  final List<String> _searchOptions = [
    'Name',
    'Email',
    'Organization',
    'Country'
  ];

  @override
  void initState() {
    super.initState();
    loadSelectedConference();
    _fetchMembers();
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

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      final searchTerm = _searchController.text;
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}admin/get_detailsMember.php'
            '?search=${Uri.encodeComponent(searchTerm)}'
            '&searchBy=${Uri.encodeComponent(_selectedSearchBy)}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _allMembers = json.decode(response.body);
          _filterMembers();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading members: $e')),
      );
    }
  }

  void _filterMembers() {
    if (_searchController.text.isEmpty) {
      _filteredMembers = List.from(_allMembers);
    } else {
      final searchTerm = _searchController.text.toLowerCase();
      _filteredMembers = _allMembers.where((member) {
        switch (_selectedSearchBy) {
          case 'Name':
            return member['user_name'].toString().toLowerCase().contains(searchTerm);
          case 'Email':
            return member['user_email'].toString().toLowerCase().contains(searchTerm);
          case 'Organization':
            return member['user_org'].toString().toLowerCase().contains(searchTerm);
          case 'Country':
            return member['user_country'].toString().toLowerCase().contains(searchTerm);
          default:
            return false;
        }
      }).toList();
    }
    
    // Calculate total pages
    totalPages = (_filteredMembers.length / itemsPerPage).ceil();
    if (currentPage > totalPages && totalPages > 0) {
      currentPage = totalPages;
    } else if (totalPages == 0) {
      currentPage = 1;
    }
  }

  List<dynamic> getPaginatedMembers() {
    if (_filteredMembers.isEmpty) return [];
    
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage > _filteredMembers.length 
        ? _filteredMembers.length 
        : startIndex + itemsPerPage;
    
    if (startIndex >= _filteredMembers.length) return [];
    return _filteredMembers.sublist(startIndex, endIndex);
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

  Widget _buildPageNumbers() {
    // Show up to 5 page numbers, centered around the current page
    List<Widget> pageWidgets = [];
    int startPage = currentPage - 1;
    int endPage = currentPage + 1;
    
    if (startPage < 1) {
      endPage = endPage + (1 - startPage);
      startPage = 1;
    }
    
    if (endPage > totalPages) {
      startPage = startPage - (endPage - totalPages);
      endPage = totalPages;
    }
    
    startPage = startPage < 1 ? 1 : startPage;
    
    if (startPage > 1) {
      pageWidgets.add(
        InkWell(
          onTap: () => goToPage(1),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            margin: EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text('1', style: TextStyle(fontSize: 11)),
          ),
        ),
      );
      
      if (startPage > 2) {
        pageWidgets.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 1),
            child: Text('...', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ),
        );
      }
    }
    
    for (int i = startPage; i <= endPage; i++) {
      pageWidgets.add(
        InkWell(
          onTap: () => goToPage(i),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            margin: EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: i == currentPage ? Color(0xFFffc107) : null,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: i == currentPage ? Color(0xFFffc107) : Colors.grey[300]!),
            ),
            child: Text(
              '$i',
              style: TextStyle(
                fontSize: 11,
                fontWeight: i == currentPage ? FontWeight.bold : FontWeight.normal,
                color: i == currentPage ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      );
    }
    
    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        pageWidgets.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 1),
            child: Text('...', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ),
        );
      }
      
      pageWidgets.add(
        InkWell(
          onTap: () => goToPage(totalPages),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            margin: EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text('$totalPages', style: TextStyle(fontSize: 11)),
          ),
        ),
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: pageWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Accounts', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFffc107),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  _searchController.clear();
                  _filterMembers();
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
                          _filterMembers();
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
                                    _filterMembers();
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
              'List of Members',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Member/Reviewer toggle buttons
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
                      onPressed: () {},
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
                        backgroundColor: Color(0xFFffc107),
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManageReviewerPage(),
                          ),
                        );
                      },
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
                        backgroundColor: Colors.grey,
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
            
            // Member List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffc107)),
                  ))
                : _filteredMembers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Color(0xFFffc107)),
                            SizedBox(height: 16),
                            Text(
                              isSearching ? 'No matching members found.' : 'No members found.',
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
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        itemCount: getPaginatedMembers().length + 1,
                          itemBuilder: (context, index) {
                          if (index == getPaginatedMembers().length) {
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
                          
                          final members = getPaginatedMembers();
                          final member = members[index];
                          
                            return Card(
                              margin: EdgeInsets.only(bottom: 12, left: 4, right: 4),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Profile picture
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundImage: member['profile_image'] != null
                                          ? NetworkImage(member['profile_image'])
                                          : AssetImage('assets/images/NullProfilePicture.png')
                                              as ImageProvider,
                                    ),
                                    SizedBox(width: 16),
                                    
                                    // Member details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            member['user_name'] ?? '',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            member['user_email'] ?? '',
                                            style: TextStyle(
                                              color: Colors.blue,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                member['user_org'] ?? '',
                                                style: TextStyle(fontSize: 13),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8),
                                                child: Icon(Icons.circle, size: 6),
                                              ),
                                              Text(
                                                member['user_country'] ?? '',
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Arrow icon
                                    IconButton(
                                      icon: Icon(Icons.arrow_forward_ios, color: Color(0xFFffc107)),
                                      onPressed: () async {
                                        if (member['user_id'] != null) {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => MemberDetails(memberId: member['user_id'].toString()),
                                            ),
                                          );
                                          if (context.mounted) {
                                            _fetchMembers();
                                          }
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: Member ID not found')),
                                          );
                                        }
                                      },
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
                  isActive: true,
                  onTap: () {
                    Navigator.pop(context);
                    _fetchMembers();
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
