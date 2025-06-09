import 'package:flutter/material.dart';
import 'package:CMSapplication/services/user_state.dart';
import 'package:CMSapplication/User/manageUserReviewerPage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../config/app_config.dart';

class ApplyReviewer extends StatefulWidget {
  const ApplyReviewer({Key? key}) : super(key: key);

  @override
  State<ApplyReviewer> createState() => _ApplyReviewerState();
}

class _ApplyReviewerState extends State<ApplyReviewer> {
  final _formKey = GlobalKey<FormState>();
  
  List<String> fields = [];
  Set<String> selectedFields = {};
  
  // File variables for mobile
  File? cvFile;
  // File variables for web
  Uint8List? cvFileBytes;
  
  String? fileName;
  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchFields();
  }

  Future<void> fetchFields() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}user/get_fields.php'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          fields = data.map((item) => item['field_title'].toString()).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load fields');
      }
    } catch (e) {
      print('Error fetching fields: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // Important for web platform
    );

    if (result != null) {
      // Check file size (limit to 20MB = 20 * 1024 * 1024 bytes)
      final int maxSize = 20 * 1024 * 1024; // 20MB in bytes
      if (result.files.single.size > maxSize) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File is too large. Maximum size is 20MB.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() {
        fileName = result.files.single.name;
        
        // Handle differently for web and mobile
        if (kIsWeb) {
          cvFileBytes = result.files.single.bytes;
        } else {
          cvFile = File(result.files.single.path!);
        }
      });
    }
  }

  Future<void> submitApplication() async {
    if (_formKey.currentState!.validate()) {
      // Validate file is selected
      if (cvFile == null && cvFileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload your CV')),
        );
        return;
      }
      
      // Validate expertise is selected
      if (selectedFields.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one area of expertise')),
        );
        return;
      }

      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm Application'),
          content: Text('Are you sure you want to submit your reviewer application?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _submitData();
              },
              child: Text('Submit'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _submitData() async {
    try {
      setState(() {
        isSubmitting = true;
      });
      
      // Get user ID
      final userId = await UserState.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}user/apply_reviewer.php'),
      );

      // Add text fields
      request.fields['user_id'] = userId;
      request.fields['rev_expert'] = selectedFields.join(', ');
      
      // Add CV file - handle web and mobile platforms differently
      if (kIsWeb && cvFileBytes != null) {
        // For web platform
        request.files.add(http.MultipartFile.fromBytes(
          'cv_file',
          cvFileBytes!,
          filename: fileName,
        ));
      } else if (!kIsWeb && cvFile != null) {
        // For mobile platform
        request.files.add(await http.MultipartFile.fromPath(
          'cv_file', 
          cvFile!.path,
        ));
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var responseData = json.decode(response.body);

      // Handle response
      if (responseData['success']) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );
        
        // Navigate back to reviewer page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ManageUserReviewerPage()),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${responseData['message']}')),
        );
        setState(() {
          isSubmitting = false;
        });
      }
    } catch (e) {
      print('Error submitting application: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply as Reviewer'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 30),
                  _buildFormSection(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rate_review, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Become a Reviewer',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Join our team of expert reviewers to evaluate and provide feedback on submitted papers.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Expertise field
        Text(
          'Expertise',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        _buildExpertiseDropdown(),
        const SizedBox(height: 24),

        // CV upload field
        Text(
          'Latest Resume (pdf)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'By uploading your CV file, you agree to your CV being used for evaluation by the journal\'s evaluation panel.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Maximum file size: 20MB',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        _buildFileUpload(),
        const SizedBox(height: 40),

        // Submit button
        Center(
          child: ElevatedButton(
            onPressed: isSubmitting ? null : submitApplication,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isSubmitting
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Submitting...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Submit Application',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpertiseDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedFields.isNotEmpty)
            Text(
              'Selected: ${selectedFields.join(", ")}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              underline: const SizedBox(),
              isExpanded: true,
              hint: const Text('Please select area of expertise'),
              value: null,
              items: fields
                  .where((field) => !selectedFields.contains(field))
                  .map((field) {
                return DropdownMenuItem<String>(
                  value: field,
                  child: Text(field),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedFields.add(value);
                  });
                }
              },
            ),
          ),
          if (selectedFields.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedFields.map((field) => Chip(
                label: Text(
                  field,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 13,
                  ),
                ),
                backgroundColor: Colors.blue.withOpacity(0.1),
                side: BorderSide(color: Colors.blue.withOpacity(0.5)),
                deleteIconColor: Colors.blue,
                onDeleted: () {
                  setState(() {
                    selectedFields.remove(field);
                  });
                },
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileUpload() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file, size: 18, color: Colors.white),
            label: const Text(
              'Choose File',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: pickFile,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              fileName ?? 'No file chosen',
              style: TextStyle(
                color: fileName != null ? Colors.black87 : Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
