import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:CMSapplication/main.dart';
import 'package:CMSapplication/User/manageUserNewsPage.dart';
import 'package:CMSapplication/User/manageUserPapersPage.dart';
import 'package:CMSapplication/User/manageUserReviewerPage.dart';
import 'package:CMSapplication/User/manageUserMessagesPage.dart';
import 'package:CMSapplication/services/user_state.dart';
import 'package:CMSapplication/User/editUserProfile.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class ManageUserProfilePage extends StatefulWidget {
  const ManageUserProfilePage({Key? key}) : super(key: key);

  @override
  State<ManageUserProfilePage> createState() => _ManageUserProfilePageState();
}

class _ManageUserProfilePageState extends State<ManageUserProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isDownloadingCV = false;
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _oldPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> fetchUserProfile() async {
    try {
      final userId = await UserState.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final response = await http.get(
        Uri.parse('https://cmsa.digital/user/get_userProfile.php?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          setState(() {
            userData = result['data'];
            isLoading = false;
          });
        } else {
          throw Exception(result['message']);
        }
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
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

  Widget _buildInfoField(String label, String? value) {
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(value ?? 'Not provided'),
          ),
        ],
      ),
    );
  }

  // Update the password validation method
  bool _isPasswordValid(String password) {
    // Check for minimum length of 8 characters
    if (password.length < 8) return false;
    
    // Check for at least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    
    // Check for at least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    
    // Check for at least one number
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    
    return true;
  }

  // Update the change password method to show more specific error messages
  Future<void> _changePassword() async {
    try {
      // Reset all error messages
      setState(() {
        _oldPasswordError = null;
        _newPasswordError = null;
        _confirmPasswordError = null;
      });

      final userId = await UserState.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      String password = _newPasswordController.text;
      
      // Check each requirement separately and set specific error messages
      if (password.length < 8) {
        setState(() {
          _newPasswordError = 'Password must be at least 8 characters long';
        });
        return;
      }
      if (!password.contains(RegExp(r'[A-Z]'))) {
        setState(() {
          _newPasswordError = 'Password must contain at least one uppercase letter';
        });
        return;
      }
      if (!password.contains(RegExp(r'[a-z]'))) {
        setState(() {
          _newPasswordError = 'Password must contain at least one lowercase letter';
        });
        return;
      }
      if (!password.contains(RegExp(r'[0-9]'))) {
        setState(() {
          _newPasswordError = 'Password must contain at least one number';
        });
        return;
      }

      // Check if passwords match
      if (_newPasswordController.text != _confirmPasswordController.text) {
        setState(() {
          _confirmPasswordError = 'New passwords do not match';
        });
        return;
      }

      final response = await http.post(
        Uri.parse('https://cmsa.digital/user/edit_userPassword.php'),
        body: {
          'user_id': userId,
          'old_password': _oldPasswordController.text,
          'new_password': _newPasswordController.text,
        },
      );

      final result = json.decode(response.body);
      print('Server response: $result');
      if (result['success']) {
        if (!mounted) return;
        
        // Clear all text fields
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
      } else {
        setState(() {
          _oldPasswordError = result['message'] ?? 'An error occurred';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _oldPasswordError = 'An error occurred. Please try again.';
      });
    }
  }

  // Add this method to show password change dialog
  Future<void> _showChangePasswordDialog() async {
    // Reset error messages when opening dialog
    setState(() {
      _oldPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> validateAndChangePassword() async {
              try {
                // Reset all error messages
                setDialogState(() {
                  _oldPasswordError = null;
                  _newPasswordError = null;
                  _confirmPasswordError = null;
                });

                // Check if old password is empty
                if (_oldPasswordController.text.isEmpty) {
                  setDialogState(() {
                    _oldPasswordError = 'Please enter your current password';
                  });
                  return;
                }

                // Check if new password is empty
                if (_newPasswordController.text.isEmpty) {
                  setDialogState(() {
                    _newPasswordError = 'Please enter a new password';
                  });
                  return;
                }

                // Check if confirm password is empty
                if (_confirmPasswordController.text.isEmpty) {
                  setDialogState(() {
                    _confirmPasswordError = 'Please re-enter your new password';
                  });
                  return;
                }

                String password = _newPasswordController.text;
                
                // Check each requirement separately and set specific error messages
                if (password.length < 8) {
                  setDialogState(() {
                    _newPasswordError = 'Password must be at least 8 characters long';
                  });
                  return;
                }
                if (!password.contains(RegExp(r'[A-Z]'))) {
                  setDialogState(() {
                    _newPasswordError = 'Password must contain at least one uppercase letter';
                  });
                  return;
                }
                if (!password.contains(RegExp(r'[a-z]'))) {
                  setDialogState(() {
                    _newPasswordError = 'Password must contain at least one lowercase letter';
                  });
                  return;
                }
                if (!password.contains(RegExp(r'[0-9]'))) {
                  setDialogState(() {
                    _newPasswordError = 'Password must contain at least one number';
                  });
                  return;
                }

                // Check if passwords match
                if (_newPasswordController.text != _confirmPasswordController.text) {
                  setDialogState(() {
                    _confirmPasswordError = 'Passwords do not match';
                  });
                  return;
                }

                final userId = await UserState.getUserId();
                if (userId == null) {
                  throw Exception('User ID not found');
                }

                final response = await http.post(
                  Uri.parse('https://cmsa.digital/user/edit_userPassword.php'),
                  body: {
                    'user_id': userId,
                    'old_password': _oldPasswordController.text,
                    'new_password': _newPasswordController.text,
                  },
                );

                final result = json.decode(response.body);
                print('Server response: $result'); // Debug print

                if (!result['success']) {
                  setDialogState(() {
                    _oldPasswordError = result['message'] ?? 'An error occurred';
                  });
                  return;
                }

                if (!mounted) return;
                
                // Clear all text fields
                _oldPasswordController.clear();
                _newPasswordController.clear();
                _confirmPasswordController.clear();
                
                Navigator.of(context).pop(); // Close the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated successfully')),
                );

              } catch (e) {
                print('Error: $e'); // Debug print
                if (!mounted) return;
                setDialogState(() {
                  _oldPasswordError = 'An error occurred. Please try again.';
                });
              }
            }

            return AlertDialog(
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Change Password'),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _oldPasswordController,
                      obscureText: _obscureOldPassword,
                      decoration: InputDecoration(
                        labelText: 'Old Password',
                        border: const OutlineInputBorder(),
                        errorText: _oldPasswordError,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureOldPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setDialogState(() {
                              _obscureOldPassword = !_obscureOldPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: const OutlineInputBorder(),
                        errorText: _newPasswordError,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setDialogState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Re-enter New Password',
                        border: const OutlineInputBorder(),
                        errorText: _confirmPasswordError,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setDialogState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Must contain at least one number and one uppercase and lowercase letter, and at least 8 or more characters',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: validateAndChangePassword,
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
            );
          },
        );
      },
    );
  }

  // Method to show storage settings dialog
  void _showStorageSettingsDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Storage Access Issue'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // Method to show file downloaded dialog
  void _showDownloadSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Download Successful'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File saved to:'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                width: double.infinity,
                child: Text(
                  filePath,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 16),
              Text('You can find the file in your device\'s Downloads folder or the path shown above.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  print('Opening file: $filePath');
                  final result = await OpenFile.open(filePath);
                  print('Open file result: ${result.message}');
                  
                  if (result.type != ResultType.done) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error opening file: ${result.message}')),
                    );
                  }
                } catch (e) {
                  print('Error opening file: $e');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error opening file: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Open File'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _downloadCV() async {
    if (userData?['rev_cv'] == null || userData?['rev_cv'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No CV available for download')),
      );
      return;
    }

    if (userData?['rev_status'] != 'Verified') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only verified reviewers can download CV')),
      );
      return;
    }

    setState(() {
      isDownloadingCV = true;
    });

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading CV...')),
      );
      
      final filename = '${userData!['rev_cv']}.pdf';
      // Using direct URL to the file
      final downloadUrl = 'https://cmsa.digital/assets/profiles/reviewer_cv/$filename';
      
      print('Downloading file from: $downloadUrl');

      // Handle web platform differently
      if (kIsWeb) {
        try {
          // Create an anchor element for browser download
          html.AnchorElement anchor = html.AnchorElement(href: downloadUrl);
          anchor.download = filename; // Set the filename for download
          anchor.target = '_blank'; // Open in a new tab if download doesn't start
          
          // Add the element to the DOM temporarily
          html.document.body?.append(anchor);
          
          // Trigger a click on the element
          anchor.click();
          
          // Remove the element from the DOM
          anchor.remove();
          
          setState(() {
            isDownloadingCV = false;
          });
          
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download started. Check your browser downloads.'),
              duration: Duration(seconds: 3),
            ),
          );
          
          return;
        } catch (e) {
          print('Error downloading in web browser: $e');
          throw Exception('Failed to download the file in web browser: ${e.toString()}');
        }
      }

      // Mobile platform code below
      String savePath;
      
      if (Platform.isAndroid) {
        try {
          // Try multiple approaches to find a suitable download location
          Directory? directory;
          List<String> possiblePaths = [];
          
          // First try to get the external storage directory
          try {
            directory = await getExternalStorageDirectory();
            if (directory != null) {
              possiblePaths.add(directory.path);
            }
          } catch (e) {
            print('Error getting external storage directory: $e');
          }
          
          // Then try to find standard Download directory on different Android versions
          try {
            // Standard Download directory on many Android devices
            possiblePaths.add('/storage/emulated/0/Download');
            
            // For older Android versions
            possiblePaths.add('/sdcard/Download');
            
            // For newer Android versions with external storage restrictions
            Directory? extDir = await getExternalStorageDirectory();
            if (extDir != null) {
              String path = extDir.path;
              if (path.contains('Android/data')) {
                List<String> parts = path.split('Android/data');
                if (parts.isNotEmpty) {
                  possiblePaths.add('${parts[0]}Download');
                }
              }
            }
            
            // Add documents directory as fallback
            final docs = await getApplicationDocumentsDirectory();
            possiblePaths.add(docs.path);
            
            // Add temp directory as last resort
            final temp = await getTemporaryDirectory();
            possiblePaths.add(temp.path);
          } catch (e) {
            print('Error finding alternative storage paths: $e');
          }
          
          // Try each path until we find one that works
          Directory? usableDir;
          String? usablePath;
          
          for (String path in possiblePaths) {
            try {
              Directory dir = Directory(path);
              if (await dir.exists()) {
                // Try to create a test file to check write permissions
                File testFile = File('${dir.path}/test_write_permission.txt');
                try {
                  await testFile.writeAsString('test');
                  await testFile.delete(); // Clean up after testing
                  usableDir = dir;
                  usablePath = path;
                  break;
                } catch (e) {
                  print('Cannot write to $path: $e');
                  continue;
                }
              } else {
                try {
                  // Try to create the directory
                  await dir.create(recursive: true);
                  usableDir = dir;
                  usablePath = path;
                  break;
                } catch (e) {
                  print('Cannot create directory $path: $e');
                  continue;
                }
              }
            } catch (e) {
              print('Error checking directory $path: $e');
              continue;
            }
          }
          
          if (usablePath == null) {
            throw Exception('Could not find a writable storage location on your device');
          }
          
          savePath = '$usablePath/$filename';
          print('Using save path: $savePath');
        } catch (e) {
          print('Error determining save path: $e');
          throw Exception('Could not determine a location to save the file: ${e.toString()}');
        }
      } else if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        savePath = '${directory.path}/$filename';
      } else {
        throw Exception('Unsupported platform for file download');
      }

      try {
        final saveDir = Directory(savePath.substring(0, savePath.lastIndexOf('/')));
        if (!await saveDir.exists()) {
          await saveDir.create(recursive: true);
        }
      } catch (e) {
        print('Error creating save directory: $e');
        throw Exception('Could not create directory to save file. Please check app permissions.');
      }
      
      print('Saving file to: $savePath');

      // Use http package for download
      final response = await http.get(Uri.parse(downloadUrl));
      
      if (response.statusCode == 200) {
        // Check if response is an error page or actual file
        if (response.headers['content-type']?.contains('text/html') == true) {
          throw Exception('CV file not found on server');
        }
        
        try {
          // Save the file
          final file = File(savePath);
          await file.writeAsBytes(response.bodyBytes);
          
          setState(() {
            isDownloadingCV = false;
          });
          
          if (!mounted) return;
          
          // Show success dialog instead of just a snackbar
          _showDownloadSuccessDialog(savePath);
          
          // Also show a brief snackbar to confirm the download
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('CV downloaded successfully'),
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (e) {
          print('Error saving file: $e');
          throw Exception('Could not save the file. Storage access denied.');
        }
      } else {
        if (response.statusCode == 404) {
          throw Exception('CV file not found on server');
        } else {
          throw Exception('Failed to download file: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error downloading CV: $e');
      
      setState(() {
        isDownloadingCV = false;
      });
      
      if (!mounted) return;
      
      String errorMessage = e.toString();
      
      // Provide user-friendly error messages
      if (errorMessage.contains('not found')) {
        errorMessage = 'CV file not found on server. Please contact support.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      } else if (errorMessage.contains('SocketException') || errorMessage.contains('Connection refused')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      } else if (errorMessage.contains('Permission') || errorMessage.contains('access denied') || 
                errorMessage.contains('Could not determine') || errorMessage.contains('Could not create directory') || 
                errorMessage.contains('Could not save')) {
        // Show a more detailed dialog for storage access issues
        _showStorageSettingsDialog(
          'The app cannot access storage to save the file. This could be due to permission restrictions on newer Android versions.\n\n'
          'Please go to Settings > Apps > CMSA > Permissions and enable all Storage permissions.'
        );
      } else {
        // For other errors, show a standard error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading file: $errorMessage'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Center(
                child: Text(
                  'CMSA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.newspaper),
              title: const Text('News'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageUserNewsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_copy),
              title: const Text('Papers'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageUserPapersPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.rate_review),
              title: const Text('Reviewer'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageUserReviewerPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Messages'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageUserMessagesPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageUserProfilePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: userData?['profile_image'] != null
                        ? NetworkImage(userData!['profile_image'])
                        : const AssetImage('assets/images/NullProfilePicture.png')
                            as ImageProvider,
                  ),
                  const SizedBox(height: 24),
                  
                  _buildInfoField('Name', userData?['user_name']),
                  _buildInfoField('Email', userData?['user_email']),
                  _buildInfoField('Phone', userData?['user_phone']),
                  _buildInfoField('Mailing Address', userData?['user_address']),
                  _buildInfoField('Status', userData?['user_status']),
                  _buildInfoField('Expertise', userData?['rev_expert']),
                  _buildInfoField('Reviewer Status', userData?['rev_status']),
                  
                  // Updated CV Download Section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Curriculum Vitae',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              userData?['rev_cv'] != null && userData!['rev_cv'].isNotEmpty
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${userData!['rev_cv']}.pdf',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                userData?['rev_status'] == 'Verified'
                                                  ? Icons.verified_user
                                                  : Icons.pending,
                                                size: 14,
                                                color: userData?['rev_status'] == 'Verified'
                                                  ? Colors.green
                                                  : Colors.orange,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                userData?['rev_status'] ?? 'Pending',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: userData?['rev_status'] == 'Verified'
                                                    ? Colors.green
                                                    : Colors.orange,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.3,
                                        child: Tooltip(
                                          message: userData?['rev_status'] != 'Verified' 
                                            ? 'Only verified reviewers can download CV' 
                                            : 'Download CV',
                                          child: ElevatedButton.icon(
                                            onPressed: isDownloadingCV || userData?['rev_status'] != 'Verified' ? null : _downloadCV,
                                            icon: isDownloadingCV 
                                              ? SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                              : const Icon(Icons.download, color: Colors.white),
                                            label: Text(
                                              isDownloadingCV
                                                ? 'Downloading...'
                                                : 'Download',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              elevation: 2,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              // Disabled button color
                                              disabledBackgroundColor: Colors.grey.shade400,
                                              disabledForegroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'No CV available',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildInfoField('Organization', userData?['user_org']),
                  _buildInfoField('Country', userData?['user_country']),
                  _buildInfoField('Date Register', formatDate(userData?['user_datereg'])),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showChangePasswordDialog,
                          icon: const Icon(Icons.lock, color: Colors.white),
                          label: const Text(
                            'Change Password',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditUserProfile(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: const Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
