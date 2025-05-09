import 'package:flutter/material.dart';
import 'package:CMSapplication/main.dart';
import 'package:CMSapplication/User/manageUserNewsPage.dart';
import 'package:CMSapplication/User/manageUserPapersPage.dart';
import 'package:CMSapplication/User/manageUserMessagesPage.dart';
import 'package:CMSapplication/User/manageUserProfilePage.dart';
import 'package:CMSapplication/User/reviewPaperDetails.dart';
import 'package:CMSapplication/User/applyReviewer.dart';
import 'package:CMSapplication/services/user_state.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManageUserReviewerPage extends StatefulWidget {
  const ManageUserReviewerPage({Key? key}) : super(key: key);

  @override
  State<ManageUserReviewerPage> createState() => _ManageUserReviewerPageState();
}

class _ManageUserReviewerPageState extends State<ManageUserReviewerPage> {
  List<dynamic> reviews = [];
  List<dynamic> _filteredReviews = [];
  bool isLoading = true;
  bool isSearching = false;
  String revStatus = "NA";
  final TextEditingController _searchController = TextEditingController();
  String _selectedSearchType = 'Paper Title';
  String _selectedReviewStatus = 'All';
  int currentPage = 1;
  int itemsPerPage = 20;
  int totalPages = 1;

  final List<String> _searchTypes = ['Paper Title', 'Paper ID', 'Conference ID'];
  final List<String> _reviewStatusTypes = ['All', 'Pending', 'Reviewed', 'Declined'];

  @override
  void initState() {
    super.initState();
    fetchUserAndReviews();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchUserAndReviews() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      final userId = await UserState.getUserId();
      if (userId == null) return;

      // First get the user's reviewer status
      final userResponse = await http.get(
        Uri.parse('https://cmsa.digital/user/get_userProfile.php?user_id=$userId'),
      );

      if (userResponse.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(userResponse.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final userData = responseData['data'];
          setState(() {
            revStatus = userData['rev_status'] ?? "NA";
          });
          print('Reviewer status: $revStatus'); // For debugging
        }
      }

      // Then get the reviews if the reviewer is verified
      if (revStatus == "Verified") {
        final reviewsResponse = await http.get(
          Uri.parse('https://cmsa.digital/user/get_userReview.php?user_id=$userId'),
        );

        if (reviewsResponse.statusCode == 200) {
          setState(() {
            reviews = json.decode(reviewsResponse.body);
            _filterReviews();
          });
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  
  void _filterReviews() {
    // If there's no search input and status is All, don't filter
    if (_searchController.text.isEmpty && _selectedReviewStatus == 'All') {
      _filteredReviews = List.from(reviews);
    } else {
      // Start with all reviews
      _filteredReviews = List.from(reviews);
      
      // Filter by search text if any
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        _filteredReviews = _filteredReviews.where((review) {
          switch (_selectedSearchType) {
            case 'Paper Title':
              return review['paper_title'].toString().toLowerCase().contains(searchTerm);
            case 'Paper ID':
              return review['paper_id'].toString().toLowerCase().contains(searchTerm);
            case 'Conference ID':
              return review['conf_id'].toString().toLowerCase().contains(searchTerm);
            default:
              return false;
          }
        }).toList();
      }

      // Filter by review status if not "All"
      if (_selectedReviewStatus != 'All') {
        _filteredReviews = _filteredReviews.where((review) {
          return review['review_status'] == _selectedReviewStatus;
        }).toList();
      }
    }

    // Calculate total pages
    totalPages = (_filteredReviews.length / itemsPerPage).ceil();
    if (currentPage > totalPages && totalPages > 0) {
      currentPage = totalPages;
    } else if (totalPages == 0) {
      currentPage = 1;
    }
  }

  List<dynamic> getPaginatedReviews() {
    if (_filteredReviews.isEmpty) return [];
    
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage > _filteredReviews.length 
        ? _filteredReviews.length 
        : startIndex + itemsPerPage;
    
    if (startIndex >= _filteredReviews.length) return [];
    return _filteredReviews.sublist(startIndex, endIndex);
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
        title: const Text('Reviewer'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (revStatus == "Verified")
            IconButton(
              icon: Icon(isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  isSearching = !isSearching;
                  if (!isSearching) {
                    _searchController.clear();
                    _selectedReviewStatus = 'All';
                    _filterReviews();
                  }
                });
              },
            ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          if (isSearching && revStatus == "Verified")
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
                          _filterReviews();
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
                                    _filterReviews();
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
                      Text('Review Status:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF757575))),
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
                              value: _selectedReviewStatus,
                              isExpanded: true,
                              items: _reviewStatusTypes.map((String option) {
                                return DropdownMenuItem<String>(
                                  value: option,
                                  child: Text(option),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedReviewStatus = newValue;
                                    _filterReviews();
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
            child: _buildContent(),
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
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageUserPapersPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.rate_review,
                  title: 'Reviewer',
                  isActive: true,
                  onTap: () {
                    Navigator.pop(context);
                    fetchUserAndReviews();
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
            Text('Loading...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    // Different content based on reviewer status
    if (revStatus == "NA" || revStatus == "") {
      return _buildNonReviewerContent();
    } else if (revStatus == "Unverified") {
      return _buildPendingReviewerContent();
    } else if (revStatus == "Verified" && (reviews.isEmpty || _filteredReviews.isEmpty)) {
      return _buildNoReviewsContent();
    } else {
      return _buildReviewsListContent();
    }
  }

  Widget _buildNonReviewerContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'Join Our Reviewer Team',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'You are currently not a reviewer. To become one, please submit an application to join our reviewer team.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.app_registration, color: Colors.white),
            label: const Text(
              'Apply Here',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ApplyReviewer()),
              );
              
              // Refresh the page when returning from ApplyReviewer
              setState(() {
                isLoading = true;
              });
              await fetchUserAndReviews();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReviewerContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_top, size: 80, color: Colors.orange[300]),
          const SizedBox(height: 24),
          Text(
            'Application Pending',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Your request has been submitted and is awaiting approval from the committee.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoReviewsContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            isSearching && _filteredReviews.isEmpty 
                ? 'No Matching Reviews Found'
                : 'No Reviews Found',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isSearching && _filteredReviews.isEmpty
                  ? 'Try changing your search criteria'
                  : 'No current review available at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsListContent() {
    final paginatedReviews = getPaginatedReviews();
    
    return Container(
      color: Colors.grey[50],
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: paginatedReviews.length + 2, // +1 for header, +1 for pagination controls
        itemBuilder: (context, index) {
          // Header
          if (index == 0) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.rate_review, size: 24, color: Colors.blue),
                      const SizedBox(width: 12),
                      const Text(
                        'Paper Reviews',
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
                    'Papers assigned to you for review',
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
          if (index == paginatedReviews.length + 1) {
            if (_filteredReviews.isEmpty) {
              return SizedBox.shrink();
            }
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

          // Review items (adjust index to account for header)
          final reviewIndex = index - 1;
          final review = paginatedReviews[reviewIndex];
          final reviewStatus = review['review_status'] ?? 'Pending';
          
          // Choose status color
          Color statusColor;
          IconData statusIcon;
          
          switch(reviewStatus) {
            case 'Reviewed':
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
              break;
            case 'Declined':
              statusColor = Colors.red;
              statusIcon = Icons.cancel;
              break;
            default:
              statusColor = Colors.orange;
              statusIcon = Icons.pending;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Column(
              children: [
                // Paper title and status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
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
                                color: statusColor,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusIcon,
                                  size: 14,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  reviewStatus,
                                  style: TextStyle(
                                    color: statusColor,
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
                        review['paper_title'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Review details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Row 1: Review ID and Conference
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Review ID
                          Expanded(
                            child: _buildInfoRow(
                              icon: Icons.numbers,
                              label: 'Review ID',
                              value: review['review_id']?.toString() ?? '',
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Conference
                          Expanded(
                            child: _buildInfoRow(
                              icon: Icons.event,
                              label: 'Conference',
                              value: review['conf_id'] ?? '',
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Row 2: Paper ID and Total Marks (if reviewed)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Paper ID
                          Expanded(
                            child: _buildInfoRow(
                              icon: Icons.description,
                              label: 'Paper ID',
                              value: review['paper_id']?.toString() ?? '',
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Total Marks (if reviewed)
                          Expanded(
                            child: reviewStatus == 'Reviewed' 
                              ? _buildInfoRow(
                                  icon: Icons.star,
                                  label: 'Total Marks',
                                  value: review['review_totalmarks']?.toString() ?? '0',
                                  valueColor: double.parse(review['review_totalmarks']?.toString() ?? '0') > 70 
                                      ? Colors.green 
                                      : double.parse(review['review_totalmarks']?.toString() ?? '0') > 40 
                                          ? Colors.orange 
                                          : Colors.red,
                                  valueBold: true,
                                )
                              : SizedBox(), // Empty if not reviewed
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
                                builder: (context) => ReviewPaperDetails(
                                  reviewId: review['review_id'].toString(),
                                  paperId: review['paper_id'].toString(),
                                ),
                              ),
                            );
                            
                            if (result == true) {
                              setState(() {
                                isLoading = true;
                              });
                              await fetchUserAndReviews();
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
      ),
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
