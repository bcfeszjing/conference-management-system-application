import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'paperPaymentDetails.dart';
import 'package:CMSapplication/Admin/manageConferencePage.dart';
import 'package:CMSapplication/Admin/managePapersPage.dart';
import 'package:CMSapplication/Admin/manageNewsPage.dart';
import 'package:CMSapplication/Admin/manageCameraReadyPage.dart';
import 'package:CMSapplication/Admin/manageMessagesPage.dart';
import 'package:CMSapplication/Admin/manageUserAccountPage.dart';
import 'package:CMSapplication/Admin/manageSettingsPage.dart';
import 'package:CMSapplication/main.dart';
import 'package:CMSapplication/services/conference_state.dart';
import '../config/app_config.dart'; // Import AppConfig

class ManagePaymentsPage extends StatefulWidget {
  @override
  _ManagePaymentsPageState createState() => _ManagePaymentsPageState();
}

class _ManagePaymentsPageState extends State<ManagePaymentsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allPayments = [];
  List<dynamic> _filteredPayments = [];
  bool _isLoading = true;
  String _error = '';
  bool isSearching = false;
  int currentPage = 1;
  int itemsPerPage = 20;
  int totalPages = 1;
  
  // Search and filter values
  String _searchBy = 'Payment ID';
  List<String> _searchOptions = ['Payment ID', 'Paper Title', 'Name', 'Email'];
  
  String _statusFilter = 'All';
  List<String> _statusOptions = [
    'All', 'Incomplete', 'Committed', 'Confirmed', 'Failed', 'Problem', 'Rejected'
  ];
  
  String? selectedConferenceId;
  
  @override
  void initState() {
    super.initState();
    loadSelectedConference();
    _fetchPayments();
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
  
  Future<void> _fetchPayments() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    
    try {
      final searchTerm = _searchController.text.trim();
      
      // Build query parameters
      final queryParams = {
        if (searchTerm.isNotEmpty) 'searchTerm': searchTerm,
        if (searchTerm.isNotEmpty) 'searchBy': _searchBy,
        'status': _statusFilter,
        'conf_id': await ConferenceState.getSelectedConferenceId() ?? '',
      };
      
      final uri = Uri.parse('${AppConfig.baseUrl}admin/get_payments.php')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data.containsKey('error')) {
          setState(() {
            _error = data['error'];
            _isLoading = false;
          });
        } else if (data.containsKey('data')) {
          setState(() {
            _allPayments = data['data'];
            _filterPayments();
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load data: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _filterPayments() {
    if (_searchController.text.isEmpty) {
      _filteredPayments = List.from(_allPayments);
    } else {
      final searchTerm = _searchController.text.toLowerCase();
      _filteredPayments = _allPayments.where((payment) {
        switch (_searchBy) {
          case 'Payment ID':
            return payment['payment_id'].toString().toLowerCase().contains(searchTerm);
          case 'Paper Title':
            return payment['paper_title'].toString().toLowerCase().contains(searchTerm);
          case 'Name':
            return payment['user_name'].toString().toLowerCase().contains(searchTerm);
          case 'Email':
            return payment['user_email'].toString().toLowerCase().contains(searchTerm);
          default:
            return false;
        }
      }).toList();
    }
    
    // Apply status filter if not 'All'
    if (_statusFilter != 'All') {
      _filteredPayments = _filteredPayments.where((payment) => 
        payment['payment_status'] == _statusFilter
      ).toList();
    }
    
    // Calculate total pages
    totalPages = (_filteredPayments.length / itemsPerPage).ceil();
    if (currentPage > totalPages && totalPages > 0) {
      currentPage = totalPages;
    } else if (totalPages == 0) {
      currentPage = 1;
    }
  }

  List<dynamic> getPaginatedPayments() {
    if (_filteredPayments.isEmpty) return [];
    
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage > _filteredPayments.length 
        ? _filteredPayments.length 
        : startIndex + itemsPerPage;
    
    if (startIndex >= _filteredPayments.length) return [];
    return _filteredPayments.sublist(startIndex, endIndex);
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
        title: Text('Payments', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                  _filterPayments();
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
                            _filterPayments();
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
                                value: _searchBy,
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
                                      _searchBy = newValue;
                                      _filterPayments();
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
                        Text('Payment Status:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                value: _statusFilter,
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
                                      _statusFilter = newValue;
                                      _filterPayments();
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
                  'List of Payments',
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ),
            
            // Payments List
            Expanded(
              child: _isLoading
                ? Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffc107)),
                  ))
                : _error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                            SizedBox(height: 16),
                            Text(
                              _error,
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : _filteredPayments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.payment_outlined, size: 64, color: Color(0xFFffc107)),
                                SizedBox(height: 16),
                                Text(
                                  isSearching ? 'No matching payments found' : 'No payments found',
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
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: getPaginatedPayments().length + 1,
                            itemBuilder: (context, index) {
                              if (index == getPaginatedPayments().length) {
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
                              
                              final payments = getPaginatedPayments();
                              final payment = payments[index];
                              
                              return PaymentCard(payment: payment);
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
                  isActive: true,
                  onTap: () {
                    Navigator.pop(context);
                    _fetchPayments();
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

class PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  
  const PaymentCard({
    Key? key,
    required this.payment,
  }) : super(key: key);
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'committed':
        return Colors.blue;
      case 'incomplete':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'problem':
        return Colors.purple;
      case 'rejected':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with ID and status
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFFffa000).withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Color(0xFFffe082)),
                  ),
                  child: Text(
                    'ID: ${payment['payment_id']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFcc9600),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(payment['payment_status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    payment['payment_status'],
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Paper title
                Text(
                  payment['paper_title'] ?? 'No Title',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 16),
                
                // Payment details in a grid layout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User info
                          _buildInfoRow(
                            icon: Icons.person,
                            label: 'Name',
                            value: payment['user_name'] ?? 'N/A',
                          ),
                          
                          SizedBox(height: 8),
                          
                          // Email
                          _buildInfoRow(
                            icon: Icons.email,
                            label: 'Email',
                            value: payment['user_email'] ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Payment amount
                          _buildInfoRow(
                            icon: Icons.attach_money,
                            iconColor: Colors.green,
                            label: 'Amount',
                            value: payment['payment_paid'] ?? '0.00',
                            valueStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          
                          SizedBox(height: 8),
                          
                          // Payment method
                          _buildInfoRow(
                            icon: Icons.payment,
                            label: 'Method',
                            value: payment['payment_method'] ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                // Payment date
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: payment['formatted_date'] ?? payment['payment_date'] ?? 'N/A',
                ),
                
                SizedBox(height: 8),
                
                // View details button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
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
                          builder: (context) => PaperPaymentDetails(
                            paperId: payment['paper_id'].toString(),
                          ),
                        ),
                      );
                      if (context.mounted) {
                        (context.findAncestorStateOfType<_ManagePaymentsPageState>())?._fetchPayments();
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
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    Color? iconColor,
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor ?? Color(0xFFcc9600)),
        SizedBox(width: 8),
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
              SizedBox(height: 2),
              Text(
                value,
                style: valueStyle ?? TextStyle(
                  fontSize: 14,
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
    home: ManagePaymentsPage(),
  ));
}