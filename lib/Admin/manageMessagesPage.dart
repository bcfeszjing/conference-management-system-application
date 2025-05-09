import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:CMSapplication/Admin/manageConferencePage.dart';
import 'package:CMSapplication/Admin/managePapersPage.dart';
import 'package:CMSapplication/Admin/manageNewsPage.dart';
import 'package:CMSapplication/Admin/manageCameraReadyPage.dart';
import 'package:CMSapplication/Admin/managePaymentsPage.dart';
import 'package:CMSapplication/Admin/manageUserAccountPage.dart';
import 'package:CMSapplication/Admin/manageSettingsPage.dart';
import 'package:CMSapplication/main.dart';
import 'package:CMSapplication/services/conference_state.dart';
import 'package:CMSapplication/Admin/messageDetails.dart';

class ManageMessagesPage extends StatefulWidget {
  @override
  _ManageMessagesPageState createState() => _ManageMessagesPageState();
}

class _ManageMessagesPageState extends State<ManageMessagesPage> {
  final TextEditingController _searchController = TextEditingController();
  List _allMessages = [];
  List _filteredMessages = [];
  bool isLoading = true;
  String? selectedConferenceId;
  bool isSearching = false;
  int currentPage = 1;
  int itemsPerPage = 20;
  int totalPages = 1;
  String _selectedSearchBy = 'Name';
  
  final List<String> _searchOptions = [
    'Name',
    'Title'
  ];

  @override
  void initState() {
    super.initState();
    loadSelectedConference();
    fetchMessages();
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

  Future<void> fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse('https://cmsa.digital/admin/get_messages.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _allMessages = data['data'];
            _filterMessages();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching messages: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterMessages() {
    if (_searchController.text.isEmpty) {
      _filteredMessages = List.from(_allMessages);
    } else {
      final searchTerm = _searchController.text.toLowerCase();
      _filteredMessages = _allMessages.where((message) {
        switch (_selectedSearchBy) {
          case 'Name':
            return message['user_name'].toString().toLowerCase().contains(searchTerm);
          case 'Title':
            return message['message_title'].toString().toLowerCase().contains(searchTerm);
          default:
            return false;
        }
      }).toList();
    }
    
    // Calculate total pages
    totalPages = (_filteredMessages.length / itemsPerPage).ceil();
    if (currentPage > totalPages && totalPages > 0) {
      currentPage = totalPages;
    } else if (totalPages == 0) {
      currentPage = 1;
    }
  }

  List getPaginatedMessages() {
    if (_filteredMessages.isEmpty) return [];
    
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage > _filteredMessages.length 
        ? _filteredMessages.length 
        : startIndex + itemsPerPage;
    
    if (startIndex >= _filteredMessages.length) return [];
    return _filteredMessages.sublist(startIndex, endIndex);
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
        title: Text('Messages', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                  _filterMessages();
                }
              });
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
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
                                  _filterMessages();
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
                                            _filterMessages();
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
                        'List of Messages',
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                  ),
                  
                  _filteredMessages.isEmpty
                      ? Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.message_outlined, size: 64, color: Color(0xFFffc107)),
                                SizedBox(height: 16),
                                Text(
                                  isSearching ? 'No matching messages found' : 'No messages found',
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
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: getPaginatedMessages().length + 1,
                            itemBuilder: (context, index) {
                              if (index == getPaginatedMessages().length) {
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
                              
                              final messages = getPaginatedMessages();
                              final message = messages[index];
                              
                              return Card(
                                margin: EdgeInsets.only(bottom: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(16),
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
                                              message['message_date'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFcc9600),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              message['user_name'],
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF333333),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: message['message_status'] == 'Replied'
                                                  ? Colors.green
                                                  : Colors.red,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              message['message_status'],
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
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
                                          Text(
                                            message['message_title'],
                                            style: TextStyle(
                                              color: Color(0xFFcc9600),
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '${message['message_content'].substring(0, message['message_content'].length > 100 ? 100 : message['message_content'].length)}...',
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontSize: 15,
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: ElevatedButton.icon(
                                              icon: Icon(Icons.visibility, size: 18),
                                              label: Text('View'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(0xFFffc107),
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              ),
                                              onPressed: () async {
                                                final result = await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => MessageDetails(messageId: message['message_id']),
                                                  ),
                                                );
                                                
                                                // Refresh messages if result is true
                                                if (result == true) {
                                                  fetchMessages();
                                                }
                                              },
                                            ),
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
                  isActive: true,
                  onTap: () {
                    Navigator.pop(context);
                    fetchMessages();
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

void main() {
  runApp(MaterialApp(
    home: ManageMessagesPage(),
  ));
}