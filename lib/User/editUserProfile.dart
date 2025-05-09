import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:CMSapplication/services/user_state.dart';
import 'manageUserProfilePage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class EditUserProfile extends StatefulWidget {
  const EditUserProfile({Key? key}) : super(key: key);

  @override
  State<EditUserProfile> createState() => _EditUserProfileState();
}

class _EditUserProfileState extends State<EditUserProfile> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = true;
  List<String> fields = [];
  Set<String> selectedFields = {};
  
  // File variables for mobile
  File? cvFile;
  File? profileImageFile;
  
  // File variables for web
  Uint8List? cvFileBytes;
  Uint8List? profileImageBytes;
  
  String? fileName;
  String? profileImageName;
  String? userTitle;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController orgController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController dateRegController = TextEditingController();
  final TextEditingController revStatusController = TextEditingController();

  String? selectedStatus;
  String? selectedCountry;
  String? currentProfileImage;

  final List<String> statusOptions = ['Student', 'Non-Student'];
  final List<String> countries = [
    'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola', 'Antigua and Barbuda', 'Argentina', 'Armenia', 'Australia', 'Austria', 'Azerbaijan',
    'Bahamas', 'Bahrain', 'Bangladesh', 'Barbados', 'Belarus', 'Belgium', 'Belize', 'Benin', 'Bhutan', 'Bolivia', 'Bosnia and Herzegovina', 'Botswana', 'Brazil', 'Brunei', 'Bulgaria', 'Burkina Faso', 'Burundi',
    'Cabo Verde', 'Cambodia', 'Cameroon', 'Canada', 'Central African Republic', 'Chad', 'Chile', 'China', 'Colombia', 'Comoros', 'Congo', 'Costa Rica', 'Croatia', 'Cuba', 'Cyprus', 'Czech Republic',
    'Democratic Republic of the Congo', 'Denmark', 'Djibouti', 'Dominica', 'Dominican Republic',
    'Ecuador', 'Egypt', 'El Salvador', 'Equatorial Guinea', 'Eritrea', 'Estonia', 'Eswatini', 'Ethiopia',
    'Fiji', 'Finland', 'France',
    'Gabon', 'Gambia', 'Georgia', 'Germany', 'Ghana', 'Greece', 'Grenada', 'Guatemala', 'Guinea', 'Guinea-Bissau', 'Guyana',
    'Haiti', 'Honduras', 'Hungary',
    'Iceland', 'India', 'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Israel', 'Italy', 'Ivory Coast',
    'Jamaica', 'Japan', 'Jordan',
    'Kazakhstan', 'Kenya', 'Kiribati', 'Kuwait', 'Kyrgyzstan',
    'Laos', 'Latvia', 'Lebanon', 'Lesotho', 'Liberia', 'Libya', 'Liechtenstein', 'Lithuania', 'Luxembourg',
    'Madagascar', 'Malawi', 'Malaysia', 'Maldives', 'Mali', 'Malta', 'Marshall Islands', 'Mauritania', 'Mauritius', 'Mexico', 'Micronesia', 'Moldova', 'Monaco', 'Mongolia', 'Montenegro', 'Morocco', 'Mozambique', 'Myanmar',
    'Namibia', 'Nauru', 'Nepal', 'Netherlands', 'New Zealand', 'Nicaragua', 'Niger', 'Nigeria', 'North Korea', 'North Macedonia', 'Norway',
    'Oman',
    'Pakistan', 'Palau', 'Palestine', 'Panama', 'Papua New Guinea', 'Paraguay', 'Peru', 'Philippines', 'Poland', 'Portugal',
    'Qatar',
    'Romania', 'Russia', 'Rwanda',
    'Saint Kitts and Nevis', 'Saint Lucia', 'Saint Vincent and the Grenadines', 'Samoa', 'San Marino', 'Sao Tome and Principe', 'Saudi Arabia', 'Senegal', 'Serbia', 'Seychelles', 'Sierra Leone', 'Singapore', 'Slovakia', 'Slovenia', 'Solomon Islands', 'Somalia', 'South Africa', 'South Korea', 'South Sudan', 'Spain', 'Sri Lanka', 'Sudan', 'Suriname', 'Sweden', 'Switzerland', 'Syria',
    'Taiwan', 'Tajikistan', 'Tanzania', 'Thailand', 'Timor-Leste', 'Togo', 'Tonga', 'Trinidad and Tobago', 'Tunisia', 'Turkey', 'Turkmenistan', 'Tuvalu',
    'Uganda', 'Ukraine', 'United Arab Emirates', 'United Kingdom', 'United States', 'Uruguay', 'Uzbekistan',
    'Vanuatu', 'Vatican City', 'Venezuela', 'Vietnam',
    'Yemen',
    'Zambia', 'Zimbabwe'
  ];

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    fetchFields();
  }

  Future<void> fetchFields() async {
    try {
      final response = await http.get(
        Uri.parse('https://cmsa.digital/user/get_fields.php'),
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

  Future<void> fetchUserProfile() async {
    try {
      final userId = await UserState.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final response = await http.get(
        Uri.parse('https://cmsa.digital/user/get_userProfileDetails.php?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          final userData = result['data'];
          setState(() {
            nameController.text = userData['user_name'] ?? '';
            emailController.text = userData['user_email'] ?? '';
            phoneController.text = userData['user_phone'] ?? '';
            addressController.text = userData['user_address'] ?? '';
            orgController.text = userData['user_org'] ?? '';
            revStatusController.text = userData['rev_status'] ?? '';
            dateRegController.text = formatDate(userData['user_datereg']);
            selectedStatus = userData['user_status'];
            selectedCountry = userData['user_country'];
            currentProfileImage = userData['profile_image'];
            userTitle = userData['user_title'] ?? '';
            
            // Handle rev_expert string
            String? expertiseValue = userData['rev_expert'];
            if (expertiseValue != null && 
                expertiseValue.trim().isNotEmpty && 
                expertiseValue.toLowerCase() != 'na') {
              // Split the string and trim each value
              selectedFields = expertiseValue
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty && e.toLowerCase() != 'na')
                  .toSet();
            } else {
              selectedFields = {};
            }
            
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy hh:mm a').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // Important for web platform
    );

    if (result != null) {
      // Check file size (limit to 20MB)
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

  Future<void> pickProfileImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg'],
      withData: true, // Important for web
    );

    if (result != null) {
      // Check file extension to ensure it's a JPG/JPEG
      String extension = result.files.single.name.split('.').last.toLowerCase();
      if (extension != 'jpg' && extension != 'jpeg') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only JPG/JPEG files are allowed for profile picture')),
        );
        return;
      }
      
      setState(() {
        profileImageName = result.files.single.name;
        
        // Handle differently for web and mobile
        if (kIsWeb) {
          profileImageBytes = result.files.single.bytes;
        } else {
          profileImageFile = File(result.files.single.path!);
        }
      });
    }
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final userId = await UserState.getUserId();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://cmsa.digital/user/edit_userProfile.php'),
      );

      // Add form fields
      request.fields.addAll({
        'user_id': userId!,
        'user_name': nameController.text,
        'user_email': emailController.text,
        'user_phone': phoneController.text,
        'user_address': addressController.text,
        'user_status': selectedStatus ?? '',
        'rev_expert': selectedFields.isEmpty ? '' : selectedFields.join(', '),
        'user_org': orgController.text,
        'user_country': selectedCountry ?? '',
        'user_title': userTitle ?? '',
      });

      // Add profile image if selected
      if (kIsWeb) {
        // Web implementation
        if (profileImageBytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'profile_image',
            profileImageBytes!,
            filename: profileImageName,
          ));
        }
        
        if (cvFileBytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'rev_cv',
            cvFileBytes!,
            filename: fileName,
          ));
        }
      } else {
        // Mobile implementation
        if (profileImageFile != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'profile_image',
            profileImageFile!.path,
          ));
        }

        if (cvFile != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'rev_cv',
            cvFile!.path,
          ));
        }
      }

      // Send the request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (jsonResponse['success']) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ManageUserProfilePage()),
        );
      } else {
        throw Exception(jsonResponse['message']);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    }
  }

  Widget _buildInfoField(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, {bool enabled = true}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          border: InputBorder.none,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildFieldsDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedFields.isNotEmpty) ...[
            const Text(
              'Selected Expertise:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedFields.map((field) => Chip(
                label: Text(field),
                onDeleted: () {
                  setState(() {
                    selectedFields.remove(field);
                  });
                },
                deleteIconColor: Colors.red,
                backgroundColor: Colors.blue.shade50,
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],
          DropdownButton<String>(
            isExpanded: true,
            hint: const Text('Add area of expertise'),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: currentProfileImage != null
                          ? NetworkImage(currentProfileImage! + '?v=${DateTime.now().millisecondsSinceEpoch}')
                          : const AssetImage('assets/images/NullProfilePicture.png')
                              as ImageProvider,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: pickProfileImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Choose Picture'),
                        ),
                      ],
                    ),
                    if (profileImageName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        profileImageName ?? 'No file chosen',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        'No file chosen',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    _buildInfoField('Name',
                      _buildInputField(nameController, 'Enter name')),
                    
                    _buildInfoField('Email',
                      _buildInputField(emailController, 'Enter email')),
                    
                    _buildInfoField('Phone',
                      _buildInputField(phoneController, 'Enter phone number')),
                    
                    _buildInfoField('Mailing Address',
                      _buildInputField(addressController, 'Enter mailing address')),
                    
                    _buildInfoField('Status',
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            border: InputBorder.none,
                          ),
                          value: selectedStatus,
                          items: statusOptions.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedStatus = value;
                            });
                          },
                        ),
                      )),
                    
                    _buildInfoField('Expertise', _buildFieldsDropdown()),
                    
                    _buildInfoField('Reviewer Status',
                      _buildInputField(revStatusController, '', enabled: false)),
                    
                    _buildInfoField('Curriculum Vitae (pdf)',
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Maximum file size: 20MB',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: pickFile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[200],
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text('Choose File'),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    fileName ?? 'No file chosen',
                                    style: TextStyle(
                                      color: fileName != null ? Colors.black : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                    
                    _buildInfoField('Organization',
                      _buildInputField(orgController, 'Enter organization')),
                    
                    _buildInfoField('Country',
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            border: InputBorder.none,
                          ),
                          value: selectedCountry,
                          items: countries.map((country) {
                            return DropdownMenuItem(
                              value: country,
                              child: Text(country),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCountry = value;
                            });
                          },
                          menuMaxHeight: 350,
                        ),
                      )),
                    
                    _buildInfoField('Date Register',
                      _buildInputField(dateRegController, '', enabled: false)),
                    
                    const SizedBox(height: 24),
                    
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
