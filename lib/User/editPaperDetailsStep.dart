import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:CMSapplication/User/paperDetailsStep.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';
import '../config/app_config.dart';

class EditPaperDetailsStep extends StatefulWidget {
  final String paperId;

  const EditPaperDetailsStep({Key? key, required this.paperId}) : super(key: key);

  @override
  _EditPaperDetailsStepState createState() => _EditPaperDetailsStepState();
}

class _EditPaperDetailsStepState extends State<EditPaperDetailsStep> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = true;
  List<String> allFields = [];
  Set<String> selectedFields = {};
  
  final TextEditingController titleController = TextEditingController();
  final TextEditingController abstractController = TextEditingController();
  final TextEditingController keywordsController = TextEditingController();
  
  // For mobile platforms
  File? noAffFile;
  File? withAffFile;
  
  // For web platform
  List<int>? noAffBytes;
  List<int>? withAffBytes;
  
  String? noAffFileName;
  String? withAffFileName;
  bool isUploadingFiles = false;

  @override
  void initState() {
    super.initState();
    fetchPaperDetails();
  }

  Future<void> fetchPaperDetails() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}user/get_editPaperDetailsStep.php?paper_id=${widget.paperId}')
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            final paper = data['paper'];
            titleController.text = paper['paper_title'] ?? '';
            abstractController.text = paper['paper_abstract'] ?? '';
            keywordsController.text = paper['paper_keywords'] ?? '';
            
            // Convert paper_fields from List<dynamic> to Set<String>
            selectedFields = Set<String>.from(paper['paper_fields'] ?? []);
            allFields = List<String>.from(data['fields']);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching paper details: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> pickFile(bool isNoAff) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['doc', 'docx'],
        allowMultiple: false,
        withData: kIsWeb, // Important for web to get file bytes
      );

      if (result != null) {
        setState(() {
          if (isNoAff) {
            noAffFileName = result.files.single.name;
            if (kIsWeb) {
              // For web, store bytes
              noAffBytes = result.files.single.bytes;
              noAffFile = null;
            } else {
              // For mobile, store file
              noAffFile = File(result.files.single.path!);
              noAffBytes = null;
            }
          } else {
            withAffFileName = result.files.single.name;
            if (kIsWeb) {
              // For web, store bytes
              withAffBytes = result.files.single.bytes;
              withAffFile = null;
            } else {
              // For mobile, store file
              withAffFile = File(result.files.single.path!);
              withAffBytes = null;
            }
          }
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File selected: ${result.files.single.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updatePaper() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Show loading indicator
      setState(() {
        isLoading = true;
      });

      // First, update paper details via JSON request
      final detailsRequest = http.Request('POST', Uri.parse('${AppConfig.baseUrl}user/edit_paperDetailsStep.php'));
      
      // Set headers
      detailsRequest.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });
      
      // Set body
      detailsRequest.body = json.encode({
        'paper_id': widget.paperId,
        'paper_fields': selectedFields.join(', '),
        'paper_title': titleController.text,
        'paper_abstract': abstractController.text,
        'paper_keywords': keywordsController.text,
      });
      
      // Send the request
      final streamedResponse = await detailsRequest.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 || !json.decode(response.body)['success']) {
        throw Exception('Failed to update paper details: ${response.body}');
      }
      
      // Now handle file uploads if files were selected
      bool hasFilesToUpload = false;
      
      if (kIsWeb) {
        hasFilesToUpload = noAffBytes != null || withAffBytes != null;
      } else {
        hasFilesToUpload = noAffFile != null || withAffFile != null;
      }
      
      if (hasFilesToUpload) {
        setState(() {
          isUploadingFiles = true;
        });
        
        // Create multipart request for file uploads
        var uploadRequest = http.MultipartRequest(
          'POST',
          Uri.parse('${AppConfig.baseUrl}user/upload_paperFiles.php'),
        );
        
        // Add paper ID
        uploadRequest.fields['paper_id'] = widget.paperId;
        
        // Add files based on platform
        if (kIsWeb) {
          // Web implementation
          if (noAffBytes != null && noAffFileName != null) {
            uploadRequest.files.add(http.MultipartFile.fromBytes(
              'paper_file_no_aff',
              noAffBytes!,
              filename: noAffFileName,
              contentType: MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document'),
            ));
          }
          
          if (withAffBytes != null && withAffFileName != null) {
            uploadRequest.files.add(http.MultipartFile.fromBytes(
              'paper_file_aff',
              withAffBytes!,
              filename: withAffFileName,
              contentType: MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document'),
            ));
          }
        } else {
          // Mobile implementation
          if (noAffFile != null) {
            uploadRequest.files.add(await http.MultipartFile.fromPath(
              'paper_file_no_aff',
              noAffFile!.path,
              filename: noAffFileName,
              contentType: MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document'),
            ));
          }
          
          if (withAffFile != null) {
            uploadRequest.files.add(await http.MultipartFile.fromPath(
              'paper_file_aff',
              withAffFile!.path,
              filename: withAffFileName,
              contentType: MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document'),
            ));
          }
        }
        
        // Send the file upload request
        final uploadResponse = await uploadRequest.send();
        final uploadResult = await http.Response.fromStream(uploadResponse);
        
        if (uploadResponse.statusCode != 200) {
          throw Exception('Failed to upload files: ${uploadResult.body}');
        }
        
        final uploadData = json.decode(uploadResult.body);
        if (!uploadData['success']) {
          throw Exception('File upload error: ${uploadData['message']}');
        }
      }

      // Hide loading indicator
      setState(() {
        isLoading = false;
        isUploadingFiles = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paper updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Pop and return true to indicate success and trigger refresh
      Navigator.pop(context, true);
      
      // Wait a moment to ensure the previous page has time to handle the result
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Explicitly call fetchPaperDetails on the previous page
      if (mounted && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaperDetailsStep(paperId: widget.paperId),
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator if still showing
      setState(() {
        isLoading = false;
        isUploadingFiles = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Paper'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading paper details...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Paper'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Paper Fields Section
                _buildSectionCard(
                  title: 'Paper Fields',
                  icon: Icons.category,
                  color: Colors.purple,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedFields.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple[100]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selected Fields:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: selectedFields.map((field) => Chip(
                                  label: Text(field),
                                  deleteIcon: const Icon(Icons.cancel, size: 18),
                                  backgroundColor: Colors.purple[50],
                                  labelStyle: TextStyle(color: Colors.purple[700]),
                                  side: BorderSide(color: Colors.purple[200]!),
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
                            items: allFields
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
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                
                // Paper Title Section
                _buildSectionCard(
                  title: 'Paper Title',
                  icon: Icons.title,
                  color: Colors.blue,
                  child: TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Enter your paper title',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter paper title';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 24),
                
                // Abstract Section
                _buildSectionCard(
                  title: 'Abstract',
                  icon: Icons.description,
                  color: Colors.teal,
                  child: TextFormField(
                    controller: abstractController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'Enter your paper abstract',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.teal),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter abstract';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 24),
                
                // Keywords Section
                _buildSectionCard(
                  title: 'Paper Keywords',
                  icon: Icons.tag,
                  color: Colors.amber,
                  child: TextFormField(
                    controller: keywordsController,
                    decoration: InputDecoration(
                      hintText: 'Enter keywords separated by commas',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.amber),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter keywords';
                      }
                      return null;
                    },
                  ),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Important Notice',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.red[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Please prepare two set of papers to be submitted. Papers with and without author name/s and affliation/s. Only Microsoft Words document format is accepted. If you don\'t wish to replace your current paper, you can choose not to upload new paper.',
                              style: TextStyle(color: Colors.black87, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                
                // Upload Files Section
                _buildSectionCard(
                  title: 'Upload Files',
                  icon: Icons.upload_file,
                  color: Colors.indigo,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Without Affiliation
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person_off, color: Colors.grey[700], size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Without Author Name/s and Affliation/s',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
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
                                      color: Colors.white,
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
                                            noAffFileName ?? 'No file chosen',
                                            style: TextStyle(
                                              color: noAffFileName != null ? Colors.black : Colors.grey[600],
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
                                  onPressed: () => pickFile(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
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
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      
                      // With Affiliation
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.people, color: Colors.grey[700], size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'With Author Name/s and Affliation/s',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
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
                                      color: Colors.white,
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
                                            withAffFileName ?? 'No file chosen',
                                            style: TextStyle(
                                              color: withAffFileName != null ? Colors.black : Colors.grey[600],
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
                                  onPressed: () => pickFile(false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                
                // Update Button
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
                    onPressed: isLoading || isUploadingFiles ? null : updatePaper,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: isLoading || isUploadingFiles 
                      ? SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        ) 
                      : const Icon(Icons.save),
                    label: Text(
                      isLoading 
                        ? 'Updating...' 
                        : isUploadingFiles 
                          ? 'Uploading Files...' 
                          : 'Update Paper',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ],
      ),
    );
  }
}
