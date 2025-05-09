import 'package:flutter/material.dart';
import 'package:CMSapplication/Admin/editConference.dart';
import 'package:CMSapplication/Admin/addConference.dart';
import 'package:CMSapplication/Admin/manageNewsPage.dart';
import 'package:CMSapplication/Admin/managePapersPage.dart';
import 'package:CMSapplication/Admin/manageUserAccountPage.dart';
import 'package:CMSapplication/Admin/manageCameraReadyPage.dart';
import 'package:CMSapplication/Admin/managePaymentsPage.dart';
import 'package:CMSapplication/Admin/manageMessagesPage.dart';
import 'package:CMSapplication/Admin/manageSettingsPage.dart';
import 'package:CMSapplication/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:CMSapplication/services/conference_state.dart';

class ManageConferencePage extends StatefulWidget {
  final String? selectedConference;

  ManageConferencePage({Key? key, this.selectedConference}) : super(key: key);

  @override
  _ManageConferencePageState createState() => _ManageConferencePageState();
}

class _ManageConferencePageState extends State<ManageConferencePage> {
  final TextEditingController _searchController = TextEditingController();
  String? selectedConferenceId;
  List<Map<String, dynamic>> _allConferences = [];
  List<Map<String, dynamic>> _filteredConferences = [];
  bool isLoading = true;
  bool isSearching = false;
  int currentPage = 1;
  int itemsPerPage = 20;
  int totalPages = 1;
  String _selectedSearchBy = 'Name';
  
  final List<String> _searchOptions = [
    'Name',
    'ID'
  ];

  @override
  void initState() {
    super.initState();
    fetchConferences();
    loadSelectedConference();
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

  Future<void> fetchConferences() async {
    setState(() {
      isLoading = true;
    });
    
    final response = await http.get(Uri.parse('https://cmsa.digital/admin/get_conferences.php'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        _allConferences = data.map((conference) => conference as Map<String, dynamic>).toList();
        _filterConferences();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load conferences');
    }
  }

  void _filterConferences() {
    if (_searchController.text.isEmpty) {
      _filteredConferences = List.from(_allConferences);
    } else {
      final searchTerm = _searchController.text.toLowerCase();
      _filteredConferences = _allConferences.where((conference) {
        switch (_selectedSearchBy) {
          case 'Name':
            return conference['conf_name'].toString().toLowerCase().contains(searchTerm);
          case 'ID':
            return conference['conf_id'].toString().toLowerCase().contains(searchTerm);
          default:
            return false;
        }
      }).toList();
    }
    
    // Calculate total pages
    totalPages = (_filteredConferences.length / itemsPerPage).ceil();
    if (currentPage > totalPages && totalPages > 0) {
      currentPage = totalPages;
    } else if (totalPages == 0) {
      currentPage = 1;
    }
  }

  List<Map<String, dynamic>> getPaginatedConferences() {
    if (_filteredConferences.isEmpty) return [];
    
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage > _filteredConferences.length 
        ? _filteredConferences.length 
        : startIndex + itemsPerPage;
    
    if (startIndex >= _filteredConferences.length) return [];
    return _filteredConferences.sublist(startIndex, endIndex);
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
        title: Text('Conferences/Journal', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  _filterConferences();
                }
              });
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[50],
        child: isLoading
          ? Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffc107)),
            ))
          : Column(
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
                                _filterConferences();
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
                                          _filterConferences();
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
                      'List of Conferences',
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                ),
                
                _filteredConferences.isEmpty
                  ? Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              isSearching ? 'No matching conferences found' : 'No conferences found',
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
                                : 'Add a new conference using the button below',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (!isSearching) ...[
                              SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => AddConferencePage()),
                                  );
                                },
                                icon: Icon(Icons.add),
                                label: Text('Add Conference'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFffc107),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: getPaginatedConferences().length + 1,
                        itemBuilder: (context, index) {
                          if (index == getPaginatedConferences().length) {
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
                          
                          final conferences = getPaginatedConferences();
                          final conference = conferences[index];
                          
                          return Card(
                            margin: EdgeInsets.only(bottom: 16.0),
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
                                          '${conference['conf_id']}',
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
                                          color: conference['conf_status'] == 'Active' 
                                              ? Colors.green[100]
                                              : Colors.red[100],
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: conference['conf_status'] == 'Active'
                                                ? Colors.green[400]!
                                                : Colors.red[400]!,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              conference['conf_status'] == 'Active'
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              size: 16,
                                              color: conference['conf_status'] == 'Active'
                                                  ? Colors.green[700]
                                                  : Colors.red[700],
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              conference['conf_status'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: conference['conf_status'] == 'Active'
                                                    ? Colors.green[700]
                                                    : Colors.red[700],
                                              ),
                                            ),
                                          ],
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
                                      Text(
                                        conference['conf_name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Color(0xFFcc9600),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      _buildInfoRow(
                                        icon: Icons.calendar_today, 
                                        label: 'Submit Date', 
                                        value: conference['conf_submitdate']
                                      ),
                                      SizedBox(height: 12),
                                      _buildInfoRow(
                                        icon: Icons.camera_alt, 
                                        label: 'Camera Ready Date', 
                                        value: conference['conf_crsubmitdate']
                                      ),
                                      Divider(height: 24),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => EditConferencePage(conferenceId: conference['conf_id']),
                                                ),
                                              );
                                            },
                                            icon: Icon(Icons.edit),
                                            label: Text('Edit Details'),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddConferencePage()),
          );
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Color(0xFFffc107),
        elevation: 2,
      ),
      drawer: _buildDrawer(),
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
                  isActive: true,
                  onTap: () {
                    Navigator.pop(context);
                    fetchConferences();
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
}
