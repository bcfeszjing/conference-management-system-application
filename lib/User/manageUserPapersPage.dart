import 'package:flutter/material.dart';
import 'package:CMSapplication/main.dart';
import 'package:CMSapplication/User/manageUserNewsPage.dart';
import 'package:CMSapplication/User/manageUserReviewerPage.dart';
import 'package:CMSapplication/User/manageUserMessagesPage.dart';
import 'package:CMSapplication/User/manageUserProfilePage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:CMSapplication/services/user_state.dart';
import 'package:CMSapplication/User/PaperStepDashboard.dart';
import 'package:CMSapplication/User/selectConference.dart';

class ManageUserPapersPage extends StatefulWidget {
  const ManageUserPapersPage({Key? key}) : super(key: key);

  @override
  State<ManageUserPapersPage> createState() => _ManageUserPapersPageState();
}

class _ManageUserPapersPageState extends State<ManageUserPapersPage> {
  List<dynamic> _allPapers = [];
  List<dynamic> _filteredPapers = [];
  bool isLoading = true;
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedSearchType = 'Paper Title';
  String _selectedStatus = 'All';
  int currentPage = 1;
  int itemsPerPage = 20;
  int totalPages = 1;

  final List<String> _searchTypes = ['Paper Title', 'Conference ID', 'Paper ID'];
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
    fetchPapers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchPapers() async {
    try {
      setState(() {
        isLoading = true;
      });

      final userId = await UserState.getUserId();
      if (userId == null) return;

      final response = await http.get(
        Uri.parse('https://cmsa.digital/user/get_userPapers.php?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _allPapers = data['papers'];
            _filterPapers();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching papers: $e');
      setState(() => isLoading = false);
    }
  }

  void _filterPapers() {
    // If there's no search input and status is All, don't filter
    if (_searchController.text.isEmpty && _selectedStatus == 'All') {
      _filteredPapers = List.from(_allPapers);
    } else {
      // Start with all papers
      _filteredPapers = List.from(_allPapers);
      
      // Filter by search text if any
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        _filteredPapers = _filteredPapers.where((paper) {
          switch (_selectedSearchType) {
            case 'Paper Title':
              return paper['paper_title'].toString().toLowerCase().contains(searchTerm);
            case 'Conference ID':
              return paper['conf_id'].toString().toLowerCase().contains(searchTerm);
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

  Color getStatusColor(String status) {
    switch (status) {
      case 'Accepted': return Colors.green;
      case 'Rejected': return Colors.red;
      case 'Under Review': return Colors.orange;
      case 'Submitted': return Colors.blue;
      case 'Received': return Colors.blue;
      case 'Resubmit': return Colors.orange;
      case 'Withdrawal': return Colors.grey;
      case 'Pre-Camera Ready': return Colors.purple;
      case 'Camera Ready': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case 'Accepted': return Icons.check_circle;
      case 'Rejected': return Icons.cancel;
      case 'Under Review': return Icons.pending;
      case 'Submitted': return Icons.upload_file;
      case 'Received': return Icons.mark_email_read;
      case 'Resubmit': return Icons.refresh;
      case 'Withdrawal': return Icons.clear;
      case 'Pre-Camera Ready': return Icons.description;
      case 'Camera Ready': return Icons.task_alt;
      default: return Icons.help_outline;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Papers'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  _searchController.clear();
                  _selectedStatus = 'All';
                  _filterPapers();
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
                        prefixIcon: Icon(Icons.search, color: Colors.blue[600]),
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
          Expanded(
            child: Container(
        color: Colors.grey[50],
        child: _buildContent(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SelectConference()),
          ).then((_) => fetchPapers());
        },
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add),
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
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school,
                    size: 60,
                    color: Colors.white,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'CMSA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Conference Management System',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.newspaper,
                  title: 'News',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageUserNewsPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.file_copy,
                  title: 'Papers',
                  isActive: true,
                  onTap: () {
                    Navigator.pop(context);
                    fetchPapers();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.rate_review,
                  title: 'Reviewer',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageUserReviewerPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.message,
                  title: 'Messages',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageUserMessagesPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.person,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageUserProfilePage()),
                    );
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MainPage()),
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
      color: isActive ? Colors.blue.withOpacity(0.1) : null,
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? Colors.blue : iconColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.blue : textColor,
            fontWeight: isActive ? FontWeight.bold : null,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading papers...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    if (_filteredPapers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.description_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                isSearching ? 'No matching papers found' : 'No Papers Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isSearching
                    ? 'Try changing your search criteria'
                    : 'You have not submitted any papers yet. Click the button below to submit your first paper.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              if (!isSearching) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SelectConference()),
                  ).then((_) => fetchPapers());
                },
                icon: const Icon(Icons.add),
                label: const Text('Submit New Paper'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              ],
            ],
          ),
        ),
      );
    }

    final paginatedPapers = getPaginatedPapers();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: paginatedPapers.length + 2, // +1 for header, +1 for pagination/bottom spacing
      itemBuilder: (context, index) {
        // Header item
        if (index == 0) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.article, size: 24, color: Colors.blue),
                    const SizedBox(width: 12),
                    const Text(
                      'Paper Management',
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
                  'Submit and manage your conference papers',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        // Pagination controls
        if (index == paginatedPapers.length + 1) {
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
                    color: currentPage > 1 ? Colors.blue : Colors.grey[400],
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
                    color: currentPage > 1 ? Colors.blue : Colors.grey[400],
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
                    color: Colors.blue,
                    border: Border.all(color: Colors.blue),
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
                    color: currentPage < totalPages ? Colors.blue : Colors.grey[400],
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
                    color: currentPage < totalPages ? Colors.blue : Colors.grey[400],
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
        
        // Paper items (adjust index to account for header)
        final paper = paginatedPapers[index - 1];
        final status = paper['paper_status'] ?? 'Unknown';
        final paymentStatus = paper['payment_status'] ?? 'Incomplete';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Column(
            children: [
              // Paper status header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: getStatusColor(status).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: getStatusColor(status),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            getStatusIcon(status),
                            size: 14,
                            color: getStatusColor(status),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(
                              color: getStatusColor(status),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      paper['paper_title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Paper details
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Row 1: Paper ID and Submission Date
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Paper ID
                        Expanded(
                          child: _buildInfoRow(
                      icon: Icons.numbers,
                      label: 'Paper ID',
                      value: paper['paper_id']?.toString() ?? '',
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Submission Date
                        Expanded(
                          child: _buildInfoRow(
                            icon: Icons.calendar_today,
                            label: 'Submission Date',
                            value: _formatDate(paper['paper_date'] ?? ''),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Row 2: Conference and Payment Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Conference
                        Expanded(
                          child: _buildInfoRow(
                      icon: Icons.event,
                      label: 'Conference',
                      value: paper['conf_id'] ?? '',
                    ),
                        ),
                        const SizedBox(width: 16),
                        // Payment Status
                        Expanded(
                          child: _buildInfoRow(
                      icon: Icons.payment,
                      label: 'Payment Status',
                      value: paymentStatus,
                      valueColor: paymentStatus == 'Incomplete' ? Colors.red : Colors.green,
                      valueBold: true,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaperStepDashboard(
                                paperId: paper['paper_id'].toString(),
                              ),
                            ),
                          );
                          
                          if (result == true) {
                            setState(() {
                              isLoading = true;
                            });
                            await fetchPapers();
                          }
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('View'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.grey[700]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: valueColor ?? Colors.black87,
                  fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
