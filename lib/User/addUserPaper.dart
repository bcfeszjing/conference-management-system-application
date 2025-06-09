import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:CMSapplication/services/user_state.dart';
import 'package:CMSapplication/User/manageUserPapersPage.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class AddUserPaper extends StatefulWidget {
  final String confId;
  final String confName;

  const AddUserPaper({
    Key? key,
    required this.confId,
    required this.confName,
  }) : super(key: key);

  @override
  State<AddUserPaper> createState() => _AddUserPaperState();
}

class _AddUserPaperState extends State<AddUserPaper> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _fieldsKey = GlobalKey();
  final _titleKey = GlobalKey();
  final _abstractKey = GlobalKey();
  final _keywordsKey = GlobalKey();
  final _filesKey = GlobalKey();

  List<String> selectedFields = [];
  List<Map<String, dynamic>> availableFields = [];
  String? paperTitle;
  String? abstract;
  String? keywords;
  File? withoutAuthorsFileObj;
  File? withAuthorsFileObj;
  String? withoutAuthorsFile;
  String? withAuthorsFile;
  int abstractWordCount = 0;
  bool isLoading = true;
  String? _fieldsError;
  String? _filesError;
  bool _isNoticeExpanded = false;
  Uint8List? withoutAuthorsBytes;
  Uint8List? withAuthorsBytes;

  @override
  void initState() {
    super.initState();
    fetchFields();
  }

  Future<void> fetchFields() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}user/get_addUserPaper.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            availableFields = List<Map<String, dynamic>>.from(data['fields']);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching fields: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickFile(bool isWithAuthors) async {
    try {
      // Different handling for web vs mobile
      if (kIsWeb) {
        // For web, specify withData: true to properly handle files
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
          allowedExtensions: ['docx'],
          withData: true, // Important for web to get file bytes
      );

      if (result != null) {
          // Check file size - limit to 20MB
          final int fileSize = result.files.single.size;
          final int maxSize = 20 * 1024 * 1024; // 20MB in bytes
          
          if (fileSize > maxSize) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File too large. Maximum size is 20MB.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            return; // Don't save the file
          }
          
          setState(() {
            if (isWithAuthors) {
              // For web, we can't create a File object, just store the name and bytes
              withAuthorsFile = result.files.single.name;
              // Store the bytes for later upload
              withAuthorsFileObj = null; // Clear the File object as it's not applicable for web
              withAuthorsBytes = result.files.single.bytes; // Store the bytes
            } else {
              withoutAuthorsFile = result.files.single.name;
              withoutAuthorsFileObj = null; // Clear the File object as it's not applicable for web
              withoutAuthorsBytes = result.files.single.bytes; // Store the bytes
            }
          });
          
          // Show info about selected file
          final String fileSizeStr = _formatFileSize(fileSize);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected file: $fileSizeStr'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        // Original mobile implementation
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['docx'],
        );

        if (result != null) {
          // Check file size - limit to 20MB
          final int fileSize = result.files.single.size;
          final int maxSize = 20 * 1024 * 1024; // 20MB in bytes
          
          if (fileSize > maxSize) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File too large. Maximum size is 20MB.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            return; // Don't save the file
          }
          
        setState(() {
          if (isWithAuthors) {
            withAuthorsFileObj = File(result.files.single.path!);
            withAuthorsFile = result.files.single.name;
          } else {
            withoutAuthorsFileObj = File(result.files.single.path!);
            withoutAuthorsFile = result.files.single.name;
          }
        });
          
          // Show info about selected file
          final String fileSizeStr = _formatFileSize(fileSize);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected file: $fileSizeStr'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error picking file: $e');
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: ${e.toString()}'),
          backgroundColor: Colors.red,
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

  int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  void _scrollToError() {
    if (_fieldsError != null) {
      Scrollable.ensureVisible(
        _fieldsKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
      return;
    }
    
    if (_formKey.currentState?.validate() == false) {
      // Find the first error field and scroll to it
      for (final key in [_titleKey, _abstractKey, _keywordsKey]) {
        if (key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 500),
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          );
          return;
        }
      }
    }

    if (_filesError != null) {
      Scrollable.ensureVisible(
        _filesKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    }
  }

  Future<void> _submitPaper() async {
    final isValid = _formKey.currentState!.validate() && 
                    _validateFields() && 
                    _validateFiles();
    
    if (!isValid) {
      _scrollToError();
      return;
    }

    try {
      final userId = await UserState.getUserId();
      final userEmail = await UserState.getUserEmail();
      
      if (userId == null || userEmail == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User session expired. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Submitting paper...')
                ],
              ),
            ),
          );
        },
      );

      // Create multipart request for file uploads
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}user/add_userPaper.php'),
      );

      // Add text fields
      request.fields['user_id'] = userId;
      request.fields['user_email'] = userEmail;
      request.fields['conf_id'] = widget.confId;
      request.fields['paper_title'] = paperTitle!;
      request.fields['paper_abstract'] = abstract!;
      request.fields['paper_keywords'] = keywords!;
      request.fields['paper_fields'] = selectedFields.join(',');
      
      // Add files based on platform
      if (kIsWeb) {
        // Web implementation - using bytes
        if (withoutAuthorsBytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'paper_file_no_aff',
            withoutAuthorsBytes!,
            filename: withoutAuthorsFile,
          ));
        }
  
        if (withAuthorsBytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'paper_file_aff',
            withAuthorsBytes!,
            filename: withAuthorsFile,
          ));
        }
      } else {
        // Mobile implementation - using file paths
        if (withoutAuthorsFileObj != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'paper_file_no_aff', 
            withoutAuthorsFileObj!.path,
            filename: withoutAuthorsFile,
          ));
        }
  
        if (withAuthorsFileObj != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'paper_file_aff', 
            withAuthorsFileObj!.path,
            filename: withAuthorsFile,
          ));
        }
      }

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Hide loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // Show success dialog
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text('Success'),
                  ],
                ),
                content: const Text('Your paper has been submitted successfully. A confirmation email has been sent to your registered email address.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );

          // Navigate back to papers page and refresh
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ManageUserPapersPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${data['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // Hide loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _validateFields() {
    if (selectedFields.isEmpty) {
      setState(() {
        _fieldsError = 'Please select at least one field for your paper';
      });
      return false;
    }
    setState(() {
      _fieldsError = null;
    });
    return true;
  }

  bool _validateFiles() {
    if (kIsWeb) {
      // For web, check if bytes are available
      if (withoutAuthorsBytes == null || withAuthorsBytes == null) {
        setState(() {
          _filesError = 'Please upload both paper files';
        });
        return false;
      }
    } else {
      // For mobile, check file objects
      if (withoutAuthorsFileObj == null || withAuthorsFileObj == null) {
        setState(() {
          _filesError = 'Please upload both paper files';
        });
        return false;
      }
    }
    setState(() {
      _filesError = null;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Paper'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[50],
        child: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading fields...', style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description, color: Colors.blue, size: 24),
                              const SizedBox(width: 12),
                              const Text(
                                'Submit New Paper',
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
                            'Submit your paper for ${widget.confName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Paper Fields
                    _buildSectionTitle('Paper Fields', Icons.category),
                    const SizedBox(height: 12),
                    Container(
                      key: _fieldsKey,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _fieldsError != null ? Colors.red : Colors.grey.shade300,
                          width: _fieldsError != null ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selectedFields.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[100]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Selected Fields:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: selectedFields.map((field) => Chip(
                                      label: Text(field),
                                      deleteIcon: const Icon(Icons.cancel, size: 18),
                                      backgroundColor: Colors.blue[50],
                                      labelStyle: TextStyle(color: Colors.blue[700]),
                                      side: BorderSide(color: Colors.blue[200]!),
                                      onDeleted: () {
                                        setState(() {
                                          selectedFields.remove(field);
                                        });
                                      },
                                    )).toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          const Text(
                            'Add Field:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                hint: const Text('Select fields to add'),
                                value: null,
                                icon: const Icon(Icons.arrow_drop_down),
                                items: availableFields
                                    .where((field) => !selectedFields.contains(field['field_title']))
                                    .map((field) {
                                  return DropdownMenuItem<String>(
                                    value: field['field_title'],
                                    child: Text(field['field_title']),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null && !selectedFields.contains(value)) {
                                    setState(() {
                                      selectedFields.add(value);
                                      _fieldsError = null;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          
                          if (_fieldsError != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, size: 18, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _fieldsError!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    // Paper Title
                    _buildSectionTitle('Paper Title', Icons.title),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: _titleKey,
                      decoration: InputDecoration(
                        hintText: 'Enter paper title',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      onChanged: (value) => paperTitle = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),
                    
                    // Conference ID
                    _buildSectionTitle('Conference', Icons.event),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${widget.confId} (${widget.confName})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    // Abstract
                    _buildSectionTitle('Abstract', Icons.subject),
                    const SizedBox(height: 4),
                    Text(
                      'Maximum 500 words',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: _abstractKey,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: 'Enter paper abstract',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      onChanged: (value) {
                        setState(() {
                          abstract = value;
                          abstractWordCount = _countWords(value);
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an abstract';
                        }
                        if (_countWords(value) > 500) {
                          return 'Abstract cannot exceed 500 words';
                        }
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: abstractWordCount > 500 ? Colors.red[50] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: abstractWordCount > 500 ? Colors.red : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          '$abstractWordCount/500 words',
                          style: TextStyle(
                            color: abstractWordCount > 500 ? Colors.red : Colors.grey[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    // Keywords
                    _buildSectionTitle('Keywords', Icons.tag),
                    const SizedBox(height: 4),
                    Text(
                      'Separate keywords with commas',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: _keywordsKey,
                      decoration: InputDecoration(
                        hintText: 'e.g. machine learning, artificial intelligence, blockchain',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      onChanged: (value) => keywords = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter keywords';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),
                    
                    // Important Notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[100]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isNoticeExpanded = !_isNoticeExpanded;
                              });
                            },
                            child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
                              const SizedBox(width: 8),
                              const Text(
                                'Important Notice',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                                Spacer(),
                                Icon(
                                  _isNoticeExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: Colors.red[700],
                                )
                            ],
                          ),
                          ),
                          if (_isNoticeExpanded) ...[
                          const SizedBox(height: 12),
                          const Text(
                              'Please prepare two sets of papers to be submitted. Papers with and without author name/s and affiliation/s. Only Microsoft Word document format (.docx) is accepted. Use the following template Download\n\nIn general, all manuscripts submitted will be vetted by the Technical Committee for quality. Make sure the file size keeps to maximum of 20MB',
                            style: TextStyle(
                              height: 1.5,
                            ),
                          ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    // Paper Files
                    _buildSectionTitle('Upload Files', Icons.upload_file),
                    
                    const SizedBox(height: 24),
                    
                    // Without Authors
                    Container(
                      key: _filesKey,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _filesError != null ? Colors.red : Colors.grey[300]!,
                          width: _filesError != null ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_off, color: Colors.grey[700]),
                              const SizedBox(width: 12),
                              const Text(
                                'Without Author Names and Affiliations',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Row(
                                    children: [
                                      Icon(Icons.insert_drive_file, color: Colors.grey[500], size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          withoutAuthorsFile ?? 'No file chosen',
                                          style: TextStyle(
                                            color: withoutAuthorsFile != null ? Colors.black : Colors.grey[600],
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () => _pickFile(false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.upload_file, size: 18),
                                label: const Text('Choose File'),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          Row(
                            children: [
                              Icon(Icons.people, color: Colors.grey[700]),
                              const SizedBox(width: 12),
                              const Text(
                                'With Author Names and Affiliations',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Row(
                                    children: [
                                      Icon(Icons.insert_drive_file, color: Colors.grey[500], size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          withAuthorsFile ?? 'No file chosen',
                                          style: TextStyle(
                                            color: withAuthorsFile != null ? Colors.black : Colors.grey[600],
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () => _pickFile(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.upload_file, size: 18),
                                label: const Text('Choose File'),
                              ),
                            ],
                          ),
                          
                          if (_filesError != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.error_outline, size: 14, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(
                                  _filesError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    
                    // Submit Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Check fields first
                          if (selectedFields.isEmpty) {
                            setState(() {
                              _fieldsError = 'Please select at least one field for your paper';
                            });
                            // Scroll to the fields section
                            Scrollable.ensureVisible(
                              _fieldsKey.currentContext!,
                              duration: const Duration(milliseconds: 500),
                              alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
                            );
                            return;
                          }
                          
                          // Continue with normal submission
                          _submitPaper();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.upload_file),
                        label: const Text(
                          'Submit Paper',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
