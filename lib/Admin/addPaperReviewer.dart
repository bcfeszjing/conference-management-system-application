import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart'; // Import AppConfig

class AddPaperReviewer extends StatefulWidget {
  final String paperId;

  const AddPaperReviewer({Key? key, required this.paperId}) : super(key: key);

  @override
  _AddPaperReviewerState createState() => _AddPaperReviewerState();
}

class _AddPaperReviewerState extends State<AddPaperReviewer> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSearchType = 'Name';
  List<dynamic> _reviewers = [];
  bool _isLoading = false;
  String? _selectedReviewer;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchReviewers();
  }

  Future<void> _fetchReviewers() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.baseUrl}admin/get_paperReviewer.php?'
          'paper_id=${widget.paperId}'
          '&search=${Uri.encodeComponent(_searchController.text)}'
          '&type=${Uri.encodeComponent(_selectedSearchType)}'
        ),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          setState(() {
            _reviewers = jsonResponse['data'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching reviewers: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _assignReviewer() async {
    if (_selectedReviewer == null || _selectedReviewer!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a reviewer')),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}admin/add_paperReviewer.php'),
        body: {
          'paper_id': widget.paperId,
          'user_id': _selectedReviewer,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reviewer assigned successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Return to previous screen with refresh signal
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(jsonResponse['message'] ?? 'Failed to assign reviewer'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error assigning reviewer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error assigning reviewer'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Reviewer'),
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.blue),
                      hintText: 'Search reviewers...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    onChanged: (value) => _fetchReviewers(),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSearchType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    items: ['Name', 'Email', 'Expertise', 'Organization']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSearchType = value!;
                        _fetchReviewers();
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchReviewers,
                    child: Text(
                      'Search',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _reviewers.length,
                    itemBuilder: (context, index) {
                      final reviewer = _reviewers[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reviewer['user_name'] ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(reviewer['rev_expert'] ?? ''),
                                    Text('Organization: ${reviewer['user_org'] ?? ''}'),
                                    Text('Assigned: ${reviewer['assigned_count'] ?? '0'}'),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _selectedReviewer = reviewer['user_id'].toString(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFFB800),
                                  foregroundColor: Colors.black,
                                ),
                                child: Text(
                                  'Assign',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _assignReviewer,
            child: Text(
              'Assign Reviewer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
