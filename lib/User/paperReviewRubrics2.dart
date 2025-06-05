import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:CMSapplication/User/reviewPaperDetails.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class PaperReviewRubrics2 extends StatefulWidget {
  final String reviewId;
  final String paperId;

  const PaperReviewRubrics2({
    Key? key,
    required this.reviewId,
    required this.paperId,
  }) : super(key: key);

  @override
  _PaperReviewRubrics2State createState() => _PaperReviewRubrics2State();
}

class _PaperReviewRubrics2State extends State<PaperReviewRubrics2> {
  final TextEditingController _reviewerRemarksController = TextEditingController();
  final TextEditingController _confRemarksController = TextEditingController();
  final GlobalKey _reviewerRemarksKey = GlobalKey();
  final GlobalKey _confRemarksKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  bool _isBestPaper = false;
  bool _isSubmitting = false;
  
  // File upload variables for web and mobile
  String? _uploadedFileName;
  
  // For mobile platforms
  File? _selectedFileObj;
  
  // For web platform
  Uint8List? _selectedFileBytes;
  
  bool _reviewerRemarksError = false;
  bool _confRemarksError = false;
  bool _formSubmitted = false;

  @override
  void dispose() {
    _reviewerRemarksController.dispose();
    _confRemarksController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  // Scroll to the first error field
  void _scrollToFirstError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_reviewerRemarksError && _reviewerRemarksKey.currentContext != null) {
        Scrollable.ensureVisible(
          _reviewerRemarksKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          curve: Curves.easeInOut,
        );
      } else if (_confRemarksError && _confRemarksKey.currentContext != null) {
        Scrollable.ensureVisible(
          _confRemarksKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _pickFile() async {
    try {
      // For mobile platforms, we need to ensure we get a proper file path
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['docx'],
        withData: true, // Always get bytes for both platforms to be safe
        allowCompression: false,
      );

      if (result != null && result.files.isNotEmpty) {
        // Check file size (limit to 10MB)
        final fileSize = result.files.single.size;
        final maxSize = 10 * 1024 * 1024; // 10MB in bytes
        
        if (fileSize > maxSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File is too large. Maximum size is 10MB.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        // Check file extension
        final fileExt = result.files.single.extension?.toLowerCase();
        if (fileExt != 'docx') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid file format. Please select a DOCX file.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Log file details for debugging
        print('File picked: ${result.files.single.name}');
        print('File size: ${result.files.single.size} bytes');
        print('Has bytes: ${result.files.single.bytes != null}');
        print('Has path: ${result.files.single.path != null}');
        if (result.files.single.path != null) {
          print('Path: ${result.files.single.path}');
        }

        // Always store the file name and bytes
        setState(() {
          _uploadedFileName = result.files.single.name;
          _selectedFileBytes = result.files.single.bytes;
          
          // Only try to create File object on mobile if path is available
          if (!kIsWeb && result.files.single.path != null) {
            try {
              _selectedFileObj = File(result.files.single.path!);
              print('File object created successfully');
            } catch (e) {
              print('Error creating File object: $e');
              // Don't throw here, we'll use bytes as fallback
              _selectedFileObj = null;
            }
          } else {
            _selectedFileObj = null;
          }
        });
        
        // Show confirmation snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File selected: ${result.files.single.name}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _validateForm() {
    // Set form as submitted to show validation errors
    setState(() {
      _formSubmitted = true;
    });
    
    bool isValid = true;
    bool reviewerRemarksError = _reviewerRemarksController.text.trim().isEmpty;
    bool confRemarksError = _countWords(_confRemarksController.text) > 300;
    
    if (reviewerRemarksError || _countWords(_reviewerRemarksController.text) > 300) {
      isValid = false;
      setState(() {
        _reviewerRemarksError = true;
      });
    } else {
      setState(() {
        _reviewerRemarksError = false;
      });
    }
    
    if (confRemarksError) {
      isValid = false;
      setState(() {
        _confRemarksError = true;
      });
    } else {
      setState(() {
        _confRemarksError = false;
      });
    }
    
    if (!isValid) {
      _scrollToFirstError();
    }
    
    return isValid;
  }

  Future<void> _submitReview() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Show uploading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text(_uploadedFileName != null 
              ? 'Uploading review with file...' 
              : 'Submitting review...'),
          ],
        ),
        duration: Duration(seconds: 30), // Long duration as upload might take time
      ),
    );

    try {
      // Create form data
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://cmsa.digital/user/add_paperReviewRubrics2.php'),
      );

      // Add text fields
      request.fields['review_id'] = widget.reviewId;
      request.fields['paper_id'] = widget.paperId;
      request.fields['reviewer_remarks'] = _reviewerRemarksController.text.trim();
      request.fields['review_confremarks'] = _confRemarksController.text.trim();
      request.fields['rev_bestpaper'] = _isBestPaper ? 'Yes' : 'No';

      // Add file if selected - always try to use bytes first for compatibility
      if (_uploadedFileName != null && _selectedFileBytes != null) {
        // Use bytes for file upload (works on both web and mobile)
        request.files.add(http.MultipartFile.fromBytes(
          'reviewed_file',
          _selectedFileBytes!,
          filename: _uploadedFileName,
          contentType: MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document'),
        ));
        print('Uploading file using bytes: $_uploadedFileName');
      } else if (!kIsWeb && _selectedFileObj != null && _uploadedFileName != null) {
        // Fallback to path for mobile only if bytes are not available
        try {
          request.files.add(await http.MultipartFile.fromPath(
            'reviewed_file',
            _selectedFileObj!.path,
            filename: _uploadedFileName,
            contentType: MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document'),
          ));
          print('Uploading file using path: ${_selectedFileObj!.path}');
        } catch (e) {
          print('Error creating MultipartFile from path: $e');
          throw Exception('Failed to prepare file for upload: $e');
        }
      } else if (_uploadedFileName != null) {
        print('No valid file data available for upload');
        throw Exception('Missing file data for upload');
      }

      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        Duration(minutes: 2),
        onTimeout: () {
          throw TimeoutException('The request timed out. Please try again.');
        },
      );
      
      // Hide any existing snackbars
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      final responseData = await streamedResponse.stream.bytesToString();
      print('Server response: $responseData');
      
      Map<String, dynamic> jsonData;
      try {
        jsonData = json.decode(responseData);
      } catch (e) {
        print('Error parsing response: $e');
        throw Exception('Invalid response from server. Please try again.');
      }

      setState(() {
        _isSubmitting = false;
      });

      if (jsonData['success'] == true) {
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jsonData['message'] ?? 'Review submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Return to details page and refresh
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewPaperDetails(
              reviewId: widget.reviewId,
              paperId: widget.paperId,
            ),
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jsonData['message'] ?? 'Error submitting review'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // Hide any existing snackbars
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      setState(() {
        _isSubmitting = false;
      });
      
      print('Error submitting review: $e');
      
      // Show error with more details
      String errorMessage = 'Error submitting review';
      
      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Connection timed out. Please check your internet and try again.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else {
        errorMessage = 'Error submitting review: ${e.toString()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewerWordsCount = _countWords(_reviewerRemarksController.text);
    final confWordsCount = _countWords(_confRemarksController.text);
    final reviewerWordsExceeded = reviewerWordsCount > 300;
    final confWordsExceeded = confWordsCount > 300;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Final Review'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        color: Colors.grey[50],
        child: _isSubmitting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue),
                  SizedBox(height: 16),
                  Text('Submitting your review...',
                    style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                ],
              )
            )
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reviewer Remarks Section
                  _buildSectionHeader('Your Final Remarks', Icons.rate_review),
                  SizedBox(height: 12),
                  
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'These remarks will be shared with the authors',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(height: 12),
                          Container(
                            key: _reviewerRemarksKey,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _formSubmitted && (_reviewerRemarksError || reviewerWordsExceeded) 
                                    ? Colors.red.shade300 
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _reviewerRemarksController,
                              decoration: InputDecoration(
                                hintText: 'Enter your detailed feedback for the authors...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.blue),
                                ),
                                errorText: _formSubmitted ? (_reviewerRemarksController.text.trim().isEmpty
                                    ? 'This field is required'
                                    : reviewerWordsExceeded
                                        ? 'Remarks must be 300 words or less'
                                        : null) : null,
                                helperText: '$reviewerWordsCount/300 words',
                                contentPadding: EdgeInsets.all(16),
                                helperStyle: TextStyle(
                                  color: _formSubmitted && reviewerWordsExceeded ? Colors.red : Colors.grey[600],
                                ),
                              ),
                              onChanged: (value) {
                                if (_formSubmitted) {
                                  setState(() {
                                    _reviewerRemarksError = value.trim().isEmpty || _countWords(value) > 300;
                                  });
                                }
                              },
                              maxLines: 6,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Conference Organizer Remarks Section
                  _buildSectionHeader('Remarks for Conference Organizer', Icons.people),
                  SizedBox(height: 12),
                  
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'These remarks will only be visible to the conference organizers',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(height: 12),
                          Container(
                            key: _confRemarksKey,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _formSubmitted && (_confRemarksError || confWordsExceeded) 
                                    ? Colors.red.shade300 
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _confRemarksController,
                              decoration: InputDecoration(
                                hintText: 'Enter any additional comments for the conference organizers...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.blue),
                                ),
                                errorText: _formSubmitted && confWordsExceeded
                                    ? 'Remarks must be 300 words or less'
                                    : null,
                                helperText: '$confWordsCount/300 words',
                                contentPadding: EdgeInsets.all(16),
                                helperStyle: TextStyle(
                                  color: _formSubmitted && confWordsExceeded ? Colors.red : Colors.grey[600],
                                ),
                              ),
                              onChanged: (value) {
                                if (_formSubmitted) {
                                  setState(() {
                                    _confRemarksError = _countWords(value) > 300;
                                  });
                                }
                              },
                              maxLines: 6,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Best Paper Recommendation
                  _buildSectionHeader('Paper Award Recommendation', Icons.star),
                  SizedBox(height: 12),
                  
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  color: Colors.amber,
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    'Recommend this paper for best paper award?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          Transform.scale(
                            scale: 1.2,
                            child: Checkbox(
                              value: _isBestPaper,
                              onChanged: (value) {
                                setState(() {
                                  _isBestPaper = value ?? false;
                                });
                              },
                              activeColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // File Upload Section
                  _buildSectionHeader('Attach Reviewed Paper (Optional)', Icons.attach_file),
                  SizedBox(height: 12),
                  
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You can optionally upload a reviewed version of the paper with your annotations',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Supported format: DOCX only',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 16),
                          if (_uploadedFileName != null) ...[
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.description, color: Colors.blue[700], size: 24),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Selected File',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[800],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          _uploadedFileName!,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.blue[700]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.clear, color: Colors.red[400]),
                                    onPressed: () {
                                      setState(() {
                                        _selectedFileObj = null;
                                        _selectedFileBytes = null;
                                        _uploadedFileName = null;
                                      });
                                    },
                                    tooltip: 'Clear selected file',
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickFile,
                                icon: Icon(_uploadedFileName != null ? Icons.change_circle : Icons.upload_file),
                                label: Text(_uploadedFileName != null ? 'Change File' : 'Choose File'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              if (_uploadedFileName == null) ...[
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'No file chosen',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Submit Button
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitReview,
                        icon: Icon(Icons.check_circle),
                        label: Text('Submit Review'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          textStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                ],
              ),
            ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.blue[700]),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
        ],
      ),
    );
  }
}
