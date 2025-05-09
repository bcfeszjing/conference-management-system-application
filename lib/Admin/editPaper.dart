import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:CMSapplication/Admin/paperDetails.dart';

class EditPaper extends StatefulWidget {
  final String paperId;
  
  const EditPaper({Key? key, required this.paperId}) : super(key: key);

  @override
  _EditPaperState createState() => _EditPaperState();
}

class _EditPaperState extends State<EditPaper> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _abstractController = TextEditingController();
  final _keywordsController = TextEditingController();
  final _remarkController = TextEditingController();
  String _selectedStatus = '';
  bool _isLoading = true;
  String _selectedConfId = '';
  List<String> _conferenceIds = [];

  final List<String> _statusTypes = [
    'Submitted',
    'Received',
    'Resubmit',
    'Under Review',
    'Withdraw',
    'Rejected',
    'Accepted',
    'Pre-Camera Ready',
    'Camera Ready'
  ];

  @override
  void initState() {
    super.initState();
    _fetchConferences();
    _fetchPaperDetails();
  }

  Future<void> _fetchConferences() async {
    try {
      final response = await http.get(
        Uri.parse('https://cmsa.digital/admin/get_paperConference.php'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _conferenceIds = data.map((item) => item.toString()).toList();
        });
      }
    } catch (e) {
      print('Error fetching conferences: $e');
    }
  }

  Future<void> _fetchPaperDetails() async {
    try {
      final response = await http.get(
        Uri.parse('https://cmsa.digital/admin/edit_paper.php?paper_id=${widget.paperId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _titleController.text = data['paper_title'];
          _abstractController.text = data['paper_abstract'];
          _keywordsController.text = data['paper_keywords'];
          _remarkController.text = data['paper_remark'] == null || data['paper_remark'].isEmpty ? 'NA' : data['paper_remark'];
          _selectedStatus = data['paper_status'];
          _selectedConfId = data['conf_id'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching paper details: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePaper() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Update'),
          content: const Text('Are you sure you want to update this paper?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Update', style: TextStyle(color: Color(0xFFffc107))),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true && _formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final response = await http.post(
        Uri.parse('https://cmsa.digital/admin/edit_paper.php'),
        body: {
          'paper_id': widget.paperId,
          'paper_title': _titleController.text,
          'paper_abstract': _abstractController.text,
          'paper_keywords': _keywordsController.text,
          'paper_status': _selectedStatus,
          'conf_id': _selectedConfId,
          'paper_remark': _remarkController.text,
        },
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paper updated successfully'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );

        // Pop back to the previous screen
        Navigator.pop(context);
        
        // Wait a moment to ensure the previous page has time to handle the result
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Navigate back to PaperDetails with a fresh instance to refresh the data
        if (mounted && context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaperDetails(paperId: widget.paperId),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update paper'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Edit Paper', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Color(0xFFffc107),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffc107)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Paper', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFFffc107),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Paper Information', Icons.description),
                
                _buildFormLabel('Title'),
                _buildFormField(
                  controller: _titleController,
                  hintText: 'Enter paper title',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                _buildFormLabel('Conference ID'),
                _buildDropdownField(
                  value: _selectedConfId,
                  items: _conferenceIds.map((String confId) {
                    return DropdownMenuItem(
                      value: confId,
                      child: Text(confId),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedConfId = newValue;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a conference';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),
                _buildSectionTitle('Content', Icons.article),
                
                _buildFormLabel('Abstract'),
                _buildFormField(
                  controller: _abstractController,
                  maxLines: 8,
                  hintText: 'Enter paper abstract',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter abstract';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                _buildFormLabel('Keywords'),
                _buildFormField(
                  controller: _keywordsController,
                  maxLines: 3,
                  hintText: 'Enter keywords (separated by commas)',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter keywords';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),
                _buildSectionTitle('Status & Remarks', Icons.feedback),
                
                _buildFormLabel('Paper Status'),
                _buildDropdownField(
                  value: _selectedStatus,
                  items: _statusTypes.map((String status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedStatus = newValue;
                      });
                    }
                  },
                ),

                const SizedBox(height: 20),
                _buildFormLabel('Conference/Journal Remarks'),
                _buildFormField(
                  controller: _remarkController,
                  maxLines: 3,
                  hintText: 'Enter remarks (optional)',
                ),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _updatePaper,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFffc107),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFcc9600), size: 20),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF757575),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    int maxLines = 1,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFe0e0e0)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          contentPadding: EdgeInsets.all(16),
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFe0e0e0)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          border: InputBorder.none,
        ),
        icon: Icon(Icons.arrow_drop_down, color: Color(0xFFcc9600)),
        items: items,
        onChanged: onChanged,
        validator: validator,
        dropdownColor: Colors.white,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _abstractController.dispose();
    _keywordsController.dispose();
    _remarkController.dispose();
    super.dispose();
  }
}
