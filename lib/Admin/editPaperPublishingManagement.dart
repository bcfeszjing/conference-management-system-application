import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/app_config.dart';

class EditPaperPublishingManagement extends StatefulWidget {
  final String paperId;

  const EditPaperPublishingManagement({Key? key, required this.paperId}) : super(key: key);

  @override
  _EditPaperPublishingManagementState createState() => _EditPaperPublishingManagementState();
}

class _EditPaperPublishingManagementState extends State<EditPaperPublishingManagement> {
  bool _isLoading = true;
  final _doiController = TextEditingController();
  final _pageNoController = TextEditingController();
  String? _selectedFileName;
  PlatformFile? _selectedFile;
  Uint8List? _webFileBytes;
  String? _paperName;
  final _maxFileSize = 20 * 1024 * 1024; // 20 MB in bytes

  @override
  void initState() {
    super.initState();
    _fetchPaperData();
  }

  Future<void> _fetchPaperData() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}admin/get_paperPublishingManagement.php?paper_id=${widget.paperId}'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          setState(() {
            _doiController.text = jsonResponse['data']['paper_doi'] ?? '';
            _pageNoController.text = jsonResponse['data']['paper_pageno'] ?? '';
            _paperName = jsonResponse['data']['paper_name'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching paper data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: kIsWeb, // Get file bytes for web
      );

      if (result != null) {
        // Check file size
        if (result.files.first.size > _maxFileSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File size exceeds 20MB limit. Please choose a smaller file.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }
        
        setState(() {
          _selectedFile = result.files.first;
          _selectedFileName = result.files.first.name;
          if (kIsWeb) {
            _webFileBytes = result.files.first.bytes;
          }
        });
        
        // Show info about selected file
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected file: ${_formatFileSize(result.files.first.size)}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      double kb = bytes / 1024;
      return '${kb.toStringAsFixed(2)} KB';
    } else {
      double mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(2)} MB';
    }
  }

  Future<void> _submitChanges() async {
    // Validate required fields
    if (_paperName == null || _paperName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paper name is missing. Please contact support.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Changes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to save these changes?'),
              if (_selectedFile != null) ...[
                SizedBox(height: 12),
                Text('File will be saved as: $_paperName.pdf', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Location: camera_ready directory',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              ],
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Save', style: TextStyle(color: Color(0xFFffc107), fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}admin/edit_paperPublishingManagement.php'),
      );

      request.fields['paper_id'] = widget.paperId;
      request.fields['paper_doi'] = _doiController.text;
      request.fields['paper_pageno'] = _pageNoController.text;

      if (_selectedFile != null) {
        if (kIsWeb && _webFileBytes != null) {
          // For web, create a MultipartFile from bytes
          request.files.add(
            http.MultipartFile.fromBytes(
              'paper_file',
              _webFileBytes!,
              filename: _selectedFileName,
            ),
          );
        } else if (!kIsWeb && _selectedFile!.path != null) {
          // For mobile, create a MultipartFile from file path
        request.files.add(
          await http.MultipartFile.fromPath(
            'paper_file',
            _selectedFile!.path!,
          ),
        );
        }
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      setState(() => _isLoading = false);

      if (jsonResponse['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Changes saved successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jsonResponse['message'] ?? 'Failed to save changes'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error submitting changes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving changes: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Edit Publishing Details', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFFffc107),
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
        title: Text('Edit Publishing Details', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFffc107),
      ),
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Publication Information'),
              SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Color(0xFFFFE082), width: 1),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormLabel('Digital Object Identifier (DOI)'),
                      SizedBox(height: 8),
                      _buildTextField(_doiController, 'Enter DOI for the paper'),
                      SizedBox(height: 24),
                      
                      _buildFormLabel('Page Number'),
                      SizedBox(height: 8),
                      _buildTextField(_pageNoController, 'Enter page number'),
                      SizedBox(height: 24),
                      
                      _buildFormLabel('Final Paper (PDF format)'),
                      SizedBox(height: 12),
                      _buildFilePicker(),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Color(0xFFffc107),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Row(
      children: [
        Icon(Icons.label, size: 16, color: Color(0xFFffa000)),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFFffc107), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildFilePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFFE0E0E0)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFileName ?? 'No file chosen',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _selectedFileName != null ? FontWeight.bold : FontWeight.normal,
                        color: _selectedFileName != null ? Colors.black87 : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_selectedFile != null) ...[
                      SizedBox(height: 4),
                      Text(
                        'Size: ${_formatFileSize(_selectedFile!.size)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: Icon(Icons.upload_file, size: 18),
                label: Text('Choose File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3F51B5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File will be saved as: ${_paperName ?? 'Unknown'}.pdf',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Max file size: 20MB, Format: PDF only',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitChanges,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFffc107),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16),
        elevation: 3,
        shadowColor: Color(0xFFffc107).withOpacity(0.5),
        minimumSize: Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.save, size: 24),
          SizedBox(width: 10),
          Text(
            'SAVE CHANGES',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
