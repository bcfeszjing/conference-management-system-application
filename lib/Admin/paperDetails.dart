import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:CMSapplication/Admin/editPaper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Use universal_html for web platform safety
import 'package:universal_html/html.dart' as html;

class PaperDetails extends StatefulWidget {
  final String paperId;

  const PaperDetails({Key? key, required this.paperId}) : super(key: key);

  @override
  _PaperDetailsState createState() => _PaperDetailsState();
}

class _PaperDetailsState extends State<PaperDetails> {
  Map<String, dynamic>? paperDetails;
  bool isLoading = true;
  bool isDownloadingNoAff = false;
  bool isDownloadingWithAff = false;

  @override
  void initState() {
    super.initState();
    fetchPaperDetails();
    if (!kIsWeb) {
      _checkPermissions();
    }
  }
  
  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      // For Android 10 (API 29) and above, we need different approach
      if (await Permission.storage.status.isDenied) {
        await Permission.storage.request();
      }
      
      // For Android 11 (API 30) and above
      if (await Permission.manageExternalStorage.status.isDenied) {
        await Permission.manageExternalStorage.request();
      }
      
      // For Android 13 (API 33) and above
      if (await Permission.photos.status.isDenied) {
        await Permission.photos.request();
      }
    }
  }

  Future<void> fetchPaperDetails() async {
    try {
      final response = await http.get(
        Uri.parse('https://cmsa.digital/admin/get_detailsPaper.php?paper_id=${widget.paperId}')
      );
      
      if (response.statusCode == 200) {
        setState(() {
          paperDetails = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching paper details: $e');
      setState(() {
        isLoading = false;
      });
    }
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

  Future<void> _downloadPaperNoAff() async {
    if (paperDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paper details not available')),
      );
      return;
    }

    // Check if paper_name exists and is not empty
    final String? paperName = paperDetails!['paper_name'];
    if (paperName == null || paperName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paper name is missing. Please contact support.')),
      );
      return;
    }
    
    // Check if file exists
    if (paperDetails!['file_exists'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paper file is not available on the server. Please contact support.'),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    setState(() {
      isDownloadingNoAff = true;
    });

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading paper...')),
      );
      
      final String fileExt = '.docx'; // Default to .docx
      final String filename = '$paperName$fileExt';
      final String downloadUrl = 'https://cmsa.digital/assets/papers/no_aff/$filename';
      
      print('Downloading file from: $downloadUrl');

      // Handle web platform download
      if (kIsWeb) {
        try {
          // Create a download anchor and trigger click
          html.AnchorElement anchor = html.AnchorElement(href: downloadUrl);
          anchor.download = filename; // Set download attribute
          anchor.style.display = 'none'; // Hide the element
          
          // Add to document body, trigger click, and remove
          html.document.body?.children.add(anchor);
          anchor.click();
          html.document.body?.children.remove(anchor);
          
          setState(() {
            isDownloadingNoAff = false;
          });
          
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download started. Check your browser downloads folder.')),
          );
          
          return;
        } catch (e) {
          print('Error downloading in web browser: $e');
          setState(() {
            isDownloadingNoAff = false;
          });
          
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download failed. Your browser may be blocking the download.'),
              duration: Duration(seconds: 5),
            ),
          );
          
          return;
        }
      }
      
      // Mobile platform implementation
      // Get the download directory based on platform
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
          throw Exception('Paper file not found on server');
        }
        
        try {
          // Save the file
          final file = File(savePath);
          await file.writeAsBytes(response.bodyBytes);
          
          setState(() {
            isDownloadingNoAff = false;
          });
          
          if (!mounted) return;
          
          // Show success dialog instead of just a snackbar
          _showDownloadSuccessDialog(savePath);
          // Also show a brief snackbar to confirm the download
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Paper downloaded successfully'),
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (e) {
          print('Error saving file: $e');
          throw Exception('Could not save the file. Storage access denied.');
        }
      } else {
        if (response.statusCode == 404) {
          throw Exception('Paper file not found on server');
        } else {
          throw Exception('Failed to download file: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error downloading paper: $e');
      
      setState(() {
        isDownloadingNoAff = false;
      });
      
      if (!mounted) return;
      
      String errorMessage = e.toString();
      
      // Provide user-friendly error messages
      if (errorMessage.contains('not found')) {
        errorMessage = 'Paper file not found on server. Please contact support.';
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

  Future<void> _downloadPaperWithAff() async {
    if (paperDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paper details not available')),
      );
      return;
    }

    // Check if paper_name exists and is not empty
    final String? paperName = paperDetails!['paper_name'];
    if (paperName == null || paperName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paper name is missing. Please contact support.')),
      );
      return;
    }
    
    // Check if file exists
    if (paperDetails!['file_aff_exists'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paper file with affiliations is not available on the server. Please contact support.'),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    setState(() {
      isDownloadingWithAff = true;
    });

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading paper with affiliations...')),
      );
      
      final String fileExt = '.docx'; // Default to .docx
      final String filename = '$paperName-fullaff$fileExt';
      final String downloadUrl = 'https://cmsa.digital/assets/papers/aff/$filename';
      
      print('Downloading file from: $downloadUrl');

      // Handle web platform download
      if (kIsWeb) {
        try {
          // Create a download anchor and trigger click
          html.AnchorElement anchor = html.AnchorElement(href: downloadUrl);
          anchor.download = filename; // Set download attribute
          anchor.style.display = 'none'; // Hide the element
          
          // Add to document body, trigger click, and remove
          html.document.body?.children.add(anchor);
          anchor.click();
          html.document.body?.children.remove(anchor);
          
          setState(() {
            isDownloadingWithAff = false;
          });
          
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download started. Check your browser downloads folder.')),
          );
          
          return;
        } catch (e) {
          print('Error downloading in web browser: $e');
          setState(() {
            isDownloadingWithAff = false;
          });
          
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download failed. Your browser may be blocking the download.'),
              duration: Duration(seconds: 5),
            ),
          );
          
          return;
        }
      }
      
      // Mobile platform implementation
      // Get the download directory based on platform
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
          throw Exception('Paper file with affiliations not found on server');
        }
        
        try {
          // Save the file
          final file = File(savePath);
          await file.writeAsBytes(response.bodyBytes);
          
          setState(() {
            isDownloadingWithAff = false;
          });
          
          if (!mounted) return;
          
          // Show success dialog instead of just a snackbar
          _showDownloadSuccessDialog(savePath);
          // Also show a brief snackbar to confirm the download
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Paper with affiliations downloaded successfully'),
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (e) {
          print('Error saving file: $e');
          throw Exception('Could not save the file. Storage access denied.');
        }
      } else {
        if (response.statusCode == 404) {
          throw Exception('Paper file with affiliations not found on server');
        } else {
          throw Exception('Failed to download file: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error downloading paper: $e');
      
      setState(() {
        isDownloadingWithAff = false;
      });
      
      if (!mounted) return;
      
      String errorMessage = e.toString();
      
      // Provide user-friendly error messages
      if (errorMessage.contains('not found')) {
        errorMessage = 'Paper file with affiliations not found on server. Please contact support.';
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Submitted':
        return Colors.orange;
      case 'Received':
        return Colors.blue;
      case 'Under Review':
        return Colors.purple;
      case 'Accepted':
        return Colors.green;
      case 'Resubmit':
        return Color(0xFFE65100); // Changed from amber to dark orange for better visibility
      case 'Rejected':
        return Colors.red;
      case 'Withdrawal':
        return Colors.grey;
      case 'Pre-Camera Ready':
        return Colors.teal;
      case 'Camera Ready':
        return Colors.indigo;
      default:
        return Colors.blue;
    }
  }

  // Method to determine if text should be white or dark based on background
  Color _getTextColor(Color backgroundColor) {
    // Force white text for certain status colors to ensure visibility
    if (backgroundColor == Color(0xFFE65100) || // Resubmit
        backgroundColor == Colors.amber) {
      return Colors.white;
    }
    
    // For other colors, calculate based on luminance
    return backgroundColor.computeLuminance() > 0.5 
        ? Colors.black 
        : Colors.white;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yy hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _deletePaper() async {
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this paper?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      try {
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
                    Text('Deleting paper...')
                  ],
                ),
              ),
            );
          },
        );

        // Make API call to delete paper
        final response = await http.post(
          Uri.parse('https://cmsa.digital/admin/delete_paper.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'paper_id': widget.paperId,
          }),
        );

        // Close loading dialog
        Navigator.pop(context);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Paper deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Pop twice to go back to ManagePapersPage - once from paperDetails, once from paperDashboard
            Navigator.of(context).pop(true); // Pop PaperDetails with refresh signal
            Navigator.of(context).pop(true); // Pop PaperDashboard with refresh signal
          } else {
            throw Exception(data['error'] ?? 'Failed to delete paper');
          }
        } else {
          throw Exception('Server error: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Paper Details', style: TextStyle(fontWeight: FontWeight.bold)),
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

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); // Send refresh signal
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Paper Details', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Color(0xFFffc107),
          foregroundColor: Colors.white,
          elevation: 2,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, true); // Send refresh signal back
            },
          ),
        ),
        body: Container(
          color: Colors.grey[50],
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Paper Header with Title and Status
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFFffa000).withOpacity(0.65),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(0xFFffe082)),
                            ),
                            child: Text(
                              'ID: ${paperDetails?['paper_id'] ?? ''}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFcc9600),
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(paperDetails?['paper_status'] ?? '').withOpacity(0.8),
                              border: Border.all(
                                color: _getStatusColor(paperDetails?['paper_status'] ?? ''),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              paperDetails?['paper_status'] ?? '',
                              style: TextStyle(
                                color: _getTextColor(_getStatusColor(paperDetails?['paper_status'] ?? '')),
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        paperDetails?['paper_title'] ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Main Content Card
                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    side: BorderSide(color: Color(0xFFffb74d), width: 1.5),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author Section
                        _buildSectionTitle('Author Information'),
                        _buildInfoRow(
                          'Author', 
                          paperDetails?['user_name'] ?? '', 
                          icon: Icons.person,
                        ),
                        _buildInfoRow(
                          'Email', 
                          paperDetails?['user_email'] ?? '', 
                          icon: Icons.email,
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Paper Details Section
                        _buildSectionTitle('Paper Details'),
                        _buildInfoRow(
                          'Submission Date', 
                          _formatDate(paperDetails?['paper_date']),
                          icon: Icons.calendar_today,
                        ),
                        _buildInfoRow(
                          'Fields', 
                          paperDetails?['paper_fields'] ?? '', 
                          icon: Icons.category,
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Abstract Section
                        _buildSectionTitle('Abstract'),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFFffebc0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            paperDetails?['paper_abstract'] ?? '',
                            style: TextStyle(
                              color: Color(0xFF555555),
                              height: 1.5,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Keywords Section
                        _buildSectionTitle('Keywords'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (paperDetails?['paper_keywords'] ?? '')
                              .split(',')
                              .map<Widget>((keyword) => Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFffc107).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Color(0xFFffc107).withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      keyword.trim(),
                                      style: TextStyle(
                                        color: Color(0xFFcc9600),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Remarks Section
                        _buildSectionTitle('Conference/Journal Remarks'),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFFffc107).withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                            color: Color(0xFFffebc0).withOpacity(0.5),
                          ),
                          child: Text(
                            paperDetails?['paper_remark'] ?? 'No remarks',
                            style: TextStyle(
                              color: Color(0xFF555555),
                              height: 1.5,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 32),
                        
                        // Download Buttons Section
                        _buildSectionTitle('Download Options'),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              onPressed: isDownloadingNoAff || (paperDetails != null && paperDetails!['file_exists'] == false) 
                                ? null 
                                : _downloadPaperNoAff,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFffc107),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  isDownloadingNoAff
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Icon(Icons.download, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    isDownloadingNoAff
                                      ? 'Downloading...'
                                      : (paperDetails != null && paperDetails!['file_exists'] == false
                                          ? 'Not Available'
                                          : 'Download - No Aff'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: isDownloadingWithAff || (paperDetails != null && paperDetails!['file_aff_exists'] == false) 
                                ? null 
                                : _downloadPaperWithAff,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF2196F3), // Changed to blue
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  isDownloadingWithAff
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Icon(Icons.download, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    isDownloadingWithAff
                                      ? 'Downloading...'
                                      : (paperDetails != null && paperDetails!['file_aff_exists'] == false
                                          ? 'Not Available'
                                          : 'Download - With Aff'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Actions Buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditPaper(paperId: widget.paperId),
                          ),
                        );
                        if (result == true) {
                          // Refresh the paper details
                          fetchPaperDetails();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFffc107),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Edit Paper',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _deletePaper,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Delete Paper',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: Color(0xFFffc107),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Color(0xFFcc9600)),
            SizedBox(width: 8),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF757575),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value, 
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF424242),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

