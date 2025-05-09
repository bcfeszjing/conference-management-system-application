import 'package:flutter/material.dart';
import 'package:CMSapplication/Admin/manageConferencePage.dart';
import 'package:CMSapplication/Admin/managePapersPage.dart';
import 'package:CMSapplication/Admin/manageUserAccountPage.dart';
import 'package:CMSapplication/Admin/manageCameraReadyPage.dart';
import 'package:CMSapplication/Admin/managePaymentsPage.dart';
import 'package:CMSapplication/Admin/manageMessagesPage.dart';
import 'package:CMSapplication/Admin/manageSettingsPage.dart';
import 'package:CMSapplication/main.dart';
import 'package:CMSapplication/Admin/addNews.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Import the intl package for date formatting
import 'package:CMSapplication/services/conference_state.dart';
import 'package:CMSapplication/Admin/editNews.dart';

class ManageNewsPage extends StatefulWidget {
  @override
  _ManageNewsPageState createState() => _ManageNewsPageState();
}

class _ManageNewsPageState extends State<ManageNewsPage> {
  String? selectedConferenceId;
  List<dynamic> allNews = [];
  List<dynamic> filteredNews = [];
  int currentPage = 1;
  int itemsPerPage = 20;
  int totalPages = 1;
  final TextEditingController _searchController = TextEditingController();
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
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

  Future<List<dynamic>> fetchNews() async {
    final response = await http.get(
      Uri.parse('https://cmsa.digital/admin/get_news.php'),
    );

    if (response.statusCode == 200) {
      allNews = json.decode(response.body);
      _filterNews();
      return allNews;
    } else {
      throw Exception('Failed to load news');
    }
  }

  void _filterNews() {
    if (_searchController.text.isEmpty) {
      filteredNews = List.from(allNews);
    } else {
      final searchTerm = _searchController.text.toLowerCase();
      filteredNews = allNews.where((news) {
        return news['news_title'].toString().toLowerCase().contains(searchTerm);
      }).toList();
    }
    totalPages = (filteredNews.length / itemsPerPage).ceil();
    if (currentPage > totalPages && totalPages > 0) {
      currentPage = totalPages;
    } else if (totalPages == 0) {
      currentPage = 1;
    }
  }

  List<dynamic> getPaginatedNews() {
    if (filteredNews.isEmpty) return [];
    
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage > filteredNews.length 
        ? filteredNews.length 
        : startIndex + itemsPerPage;
    
    if (startIndex >= filteredNews.length) return [];
    return filteredNews.sublist(startIndex, endIndex);
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
    print('ManageNewsPage initialized with selectedConference: $selectedConferenceId');

    return Scaffold(
      appBar: AppBar(
        title: Text('News', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  _filterNews();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (isSearching)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
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
                    hintText: 'Search news by title...',
                    prefixIcon: Icon(Icons.search, color: Color(0xFFcc9600)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _filterNews();
                    });
                  },
                ),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
        future: fetchNews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color(0xFFffc107)));
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                  SizedBox(height: 16),
                  Text(
                    'Error loading news',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('${snapshot.error}', style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            );
                } else if (filteredNews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.newspaper, size: 60, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                          isSearching ? 'No matching news found' : 'No news available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                          isSearching 
                              ? 'Try a different search term' 
                              : 'Add your first news item using the button below',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          } else {
                  final paginatedNews = getPaginatedNews();
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
                          itemCount: paginatedNews.length + 1,
              itemBuilder: (context, index) {
                            if (index == paginatedNews.length) {
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
                
                            final news = paginatedNews[index];
                // Format the news date
                DateTime dateTime = DateTime.parse(news['news_date']);
                String formattedDate = DateFormat('MM/dd/yyyy').format(dateTime);
                String formattedTime = DateFormat('hh:mm a').format(dateTime);

                // Shorten title and content
                String title = news['news_title'];
                String content = news['news_content'];
                String shortenedTitle = title.length > 50 ? '${title.substring(0, 50)}...' : title;
                String shortenedContent = content.length > 100 ? '${content.substring(0, 100)}...' : content;

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
                          color: Color(0xFFffa000).withOpacity(0.15),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Color(0xFFffe082)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFcc9600),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    formattedTime,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                shortenedTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFFcc9600),
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
                              shortenedContent,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditNews(newsId: news['news_id']),
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
            );
          }
        },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddNews()),
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
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ManageConferencePage()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.newspaper,
                  title: 'News',
                  isActive: true,
                  onTap: () {
                    Navigator.pop(context);
                    fetchNews();
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
}

void main() {
  runApp(MaterialApp(
    home: ManageNewsPage(),
  ));
}