import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'manageReviewerPage.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddReviewer extends StatefulWidget {
  @override
  _AddReviewerState createState() => _AddReviewerState();
}

class _AddReviewerState extends State<AddReviewer> {
  final _formKey = GlobalKey<FormState>();
  List<String> fields = [];
  Set<String> selectedFields = {};
  String? selectedTitle;
  String? selectedCountry;
  File? cvFile;
  Uint8List? webCvBytes;
  String? fileName;
  
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController orgController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  final List<String> titles = ['Professor', 'Associate Professor', 'Dr', 'Mr', 'Ms'];

  @override
  void initState() {
    super.initState();
    fetchFields();
  }

  Future<void> fetchFields() async {
    try {
      final response = await http.get(
        Uri.parse('https://cmsa.digital/admin/get_fields.php'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          fields = data.map((item) => item['field_title'].toString()).toList();
        });
      }
    } catch (e) {
      print('Error fetching fields: $e');
    }
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb, // Get file bytes for web
    );

    if (result != null) {
      // Check file size - limit to 20MB
      final int fileSize = result.files.single.size;
      final int maxSize = 20 * 1024 * 1024; // 20MB in bytes
      
      if (fileSize > maxSize) {
        // File too large - show error
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
        fileName = result.files.single.name;
        if (kIsWeb) {
          // On web, we store the file bytes
          webCvBytes = result.files.single.bytes;
        } else {
          // On mobile, we store the file path
          cvFile = File(result.files.single.path!);
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

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Submission'),
        content: Text('Are you sure you want to add this reviewer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _submitData();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitData() async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://cmsa.digital/admin/add_reviewer.php'),
      );

      request.fields.addAll({
        'rev_expert': selectedFields.join(', '),
        'user_title': selectedTitle!,
        'user_name': nameController.text,
        'user_email': emailController.text,
        'user_phone': phoneController.text,
        'user_org': orgController.text,
        'user_address': addressController.text,
        'user_country': selectedCountry!,
      });

      if (kIsWeb && webCvBytes != null && fileName != null) {
        // For web, create a MultipartFile from bytes
        request.files.add(
          http.MultipartFile.fromBytes(
            'rev_cv',
            webCvBytes!,
            filename: fileName,
          ),
        );
      } else if (!kIsWeb && cvFile != null) {
        // For mobile, create a MultipartFile from file path
        request.files.add(
          await http.MultipartFile.fromPath(
            'rev_cv',
            cvFile!.path,
          ),
        );
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (jsonResponse['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reviewer added successfully')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ManageReviewerPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${jsonResponse['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Reviewer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Color(0xFFffc107),
        elevation: 2,
      ),
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormSection(
                    title: 'Personal Information',
                    children: [
                      _buildSectionTitle('Title'),
                      _buildTitleDropdown(),
                      SizedBox(height: 16),
                      
                      _buildSectionTitle('Name'),
                      _buildInputField(nameController, 'Enter name'),
                      SizedBox(height: 16),
                      
                      _buildSectionTitle('Email'),
                      _buildInputField(emailController, 'Enter email', isEmail: true),
                      SizedBox(height: 16),
                      
                      _buildSectionTitle('Phone'),
                      _buildInputField(phoneController, 'Enter phone number'),
                      SizedBox(height: 16),
                      
                      _buildSectionTitle('Organization'),
                      _buildInputField(orgController, 'Enter organization'),
                      SizedBox(height: 16),
                      
                      _buildSectionTitle('Mailing Address'),
                      _buildInputField(addressController, 'Enter mailing address'),
                      SizedBox(height: 16),
                      
                      _buildSectionTitle('Country'),
                      _buildCountryDropdown(),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  _buildFormSection(
                    title: 'Professional Details',
                    children: [
                      _buildSectionTitle('Expertise'),
                      _buildFieldsDropdown(),
                      SizedBox(height: 16),
                      
                      _buildSectionTitle('CV if available (pdf format)'),
                      _buildFileUpload(),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFffebc3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFffc107), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFFcc9600)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Password will be automatically generated and sent to the reviewer email.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  
                  Center(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.add_circle_outline, color: Colors.white),
                      label: Text(
                        'Add Reviewer',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFffc107),
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: submitForm,
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFFffc107).withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFFffc107), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  margin: EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFFffc107),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFcc9600),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets...
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF555555),
        ),
      ),
    );
  }

  Widget _buildFieldsDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedFields.isNotEmpty) 
            Text(
              'Selected: ${selectedFields.join(", ")}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              underline: SizedBox(),
              isExpanded: true,
              hint: Text('Please select area of expertise'),
              value: null,
              items: fields.where((field) => !selectedFields.contains(field)).map((field) {
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
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedFields.map((field) => Chip(
                label: Text(
                  field,
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 13,
                  ),
                ),
                backgroundColor: Color(0xFFffebc3),
                side: BorderSide(color: Color(0xFFffd54f)),
                deleteIconColor: Color(0xFFcc9600),
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

  Widget _buildTitleDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFffc107)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: Colors.white,
      ),
      isExpanded: true,
      hint: Text('Select title'),
      value: selectedTitle,
      items: titles.map((title) {
        return DropdownMenuItem(
          value: title,
          child: Text(title),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedTitle = value;
        });
      },
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, {bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFffc107)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        if (isEmail && !value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildCountryDropdown() {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        hintText: selectedCountry ?? 'Select country',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFffc107)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      onTap: () {
        showCountryPicker(
          context: context,
          onSelect: (Country country) {
            setState(() => selectedCountry = country.name);
          },
        );
      },
      validator: (value) => selectedCountry == null ? 'Please select a country' : null,
    );
  }

  Widget _buildFileUpload() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ElevatedButton.icon(
            icon: Icon(Icons.upload_file, size: 18, color: Colors.white),
            label: Text(
              'Choose File',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFffc107),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: pickFile,
          ),
          SizedBox(width: 16),
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

class SearchableDropdown<T> extends StatelessWidget {
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final Widget hint;
  final Widget searchHint;
  final ValueChanged<T?> onChanged;
  final bool isExpanded;

  SearchableDropdown({
    required this.items,
    required this.value,
    required this.hint,
    required this.searchHint,
    required this.onChanged,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      items: items,
      value: value,
      hint: hint,
      onChanged: onChanged,
      isExpanded: isExpanded,
      menuMaxHeight: 350, // Makes the dropdown scrollable
      decoration: InputDecoration(
        border: InputBorder.none,
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
    );
  }
}



