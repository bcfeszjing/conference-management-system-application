import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class PaperCameraReadyUpload extends StatefulWidget {
  final String paperId;

  const PaperCameraReadyUpload({Key? key, required this.paperId}) : super(key: key);

  @override
  State<PaperCameraReadyUpload> createState() => _PaperCameraReadyUploadState();
}

class _PaperCameraReadyUploadState extends State<PaperCameraReadyUpload> {
  Map<String, dynamic>? paperData;
  bool isLoading = true;
  bool isDownloadingTemplate = false;
  String? cameraReadyFileName;
  Uint8List? cameraReadyFileBytes;
  String? rebuttleFileName;
  Uint8List? rebuttleFileBytes;
  String? copyrightFileName;
  Uint8List? copyrightFileBytes;
  final titleController = TextEditingController();
  final abstractController = TextEditingController();
  final keywordsController = TextEditingController();
  final pageNoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPaperData();
    if (!kIsWeb) {
      _checkPermissions();
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    abstractController.dispose();
    keywordsController.dispose();
    pageNoController.dispose();
    super.dispose();
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

  Future<void> _downloadCopyrightTemplate() async {
    setState(() {
      isDownloadingTemplate = true;
    });

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading copyright form template...')),
      );
      
      final String filename = 'Copyright_Form_Template.pdf';
      final String downloadUrl = 'https://cmsa.digital/assets/papers/copyright_form/$filename';
      
      print('Downloading copyright template from: $downloadUrl');

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
            isDownloadingTemplate = false;
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
          throw Exception('Template file not found on server');
        }
        
        try {
          // Save the file
          final file = File(savePath);
          await file.writeAsBytes(response.bodyBytes);
          
          setState(() {
            isDownloadingTemplate = false;
          });
          
          if (!mounted) return;
          
          // Show success dialog instead of just a snackbar
          _showDownloadSuccessDialog(savePath);
          // Also show a brief snackbar to confirm the download
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copyright template downloaded successfully'),
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (e) {
          print('Error saving file: $e');
          throw Exception('Could not save the file. Storage access denied.');
        }
      } else {
        if (response.statusCode == 404) {
          throw Exception('Template file not found on server');
        } else {
          throw Exception('Failed to download file: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error downloading template: $e');
      
      setState(() {
        isDownloadingTemplate = false;
      });
      
      if (!mounted) return;
      
      String errorMessage = e.toString();
      
      // Provide user-friendly error messages
      if (errorMessage.contains('not found')) {
        errorMessage = 'Template file not found on server. Please contact support.';
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

  Future<void> fetchPaperData() async {
    try {
      final response = await http.post(
        Uri.parse('https://cmsa.digital/user/get_paperCameraReadyUpload.php'),
        body: {'paper_id': widget.paperId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          paperData = data;
          titleController.text = data['paper_title'] ?? '';
          abstractController.text = data['paper_abstract'] ?? '';
          keywordsController.text = data['paper_keywords'] ?? '';
          pageNoController.text = data['paper_pageno']?.toString() ?? '';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickFile(String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: type == 'rebuttal' || type == 'copyright' ? ['pdf'] : ['doc', 'docx'],
      withData: true,  // Ensure we get the file data
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
        switch (type) {
          case 'camera':
            cameraReadyFileName = result.files.single.name;
            cameraReadyFileBytes = result.files.single.bytes;
            break;
          case 'rebuttal':
            rebuttleFileName = result.files.single.name;
            rebuttleFileBytes = result.files.single.bytes;
            break;
          case 'copyright':
            copyrightFileName = result.files.single.name;
            copyrightFileBytes = result.files.single.bytes;
            break;
        }
      });
    }
  }

  Future<void> _submitCameraReady() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Submitting...', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://cmsa.digital/user/add_paperCameraReadyUpload.php'),
      );

      // Add common fields
      request.fields['paper_id'] = widget.paperId;
      
      // Add current paper status to maintain it when updating
      request.fields['current_status'] = paperData?['paper_status'] ?? '';

      // Add optional fields for Camera Ready status
      if (paperData?['paper_status'] == 'Camera Ready') {
        request.fields['paper_title'] = titleController.text;
        request.fields['paper_abstract'] = abstractController.text;
        request.fields['paper_keywords'] = keywordsController.text;
        request.fields['paper_pageno'] = pageNoController.text;
        request.fields['maintain_status'] = 'true'; // Add flag to maintain Camera Ready status
      }

      // Add camera ready file if selected
      if (cameraReadyFileBytes != null && cameraReadyFileName != null) {
        var fileExtension = cameraReadyFileName!.split('.').last.toLowerCase();
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'camera_ready_file',
            cameraReadyFileBytes!,
            filename: cameraReadyFileName,
            contentType: MediaType('application', fileExtension == 'pdf' ? 'pdf' : 'vnd.openxmlformats-officedocument.wordprocessingml.document'),
          ),
        );
      }

      // Add rebuttal file if selected
      if (rebuttleFileBytes != null && rebuttleFileName != null) {
        var fileExtension = rebuttleFileName!.split('.').last.toLowerCase();
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'rebuttal_file',
            rebuttleFileBytes!,
            filename: rebuttleFileName,
            contentType: MediaType('application', fileExtension == 'pdf' ? 'pdf' : 'vnd.openxmlformats-officedocument.wordprocessingml.document'),
          ),
        );
      }

      // Add copyright file if selected
      if (copyrightFileBytes != null && copyrightFileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'copyright_file',
            copyrightFileBytes!,
            filename: copyrightFileName,
            contentType: MediaType('application', 'pdf'),
          ),
        );
      }

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Close loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          // Show success dialog
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 28),
                    const SizedBox(width: 8),
                    const Text('Success'),
                  ],
                ),
                content: Text(result['message'] ?? 'Your paper has been updated successfully.'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

          // Navigate back to paperCameraReadyStep and refresh
          Navigator.pop(context, true);
        } else {
          // Show error dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(result['message'] ?? 'Failed to update paper.')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      } else {
        throw Exception('Failed to connect to server');
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Widget _buildPreCameraReadyForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Please upload your camera ready paper along with supporting documents.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildFileUploadSection(
            "Pre/Camera Ready (docx)",
            cameraReadyFileName,
            () => _pickFile('camera'),
            Icons.description,
          ),
          const SizedBox(height: 24),
          _buildFileUploadSection(
            "Rebuttal Table & Turnitin result (pdf only)",
            rebuttleFileName,
            () => _pickFile('rebuttal'),
            Icons.fact_check,
          ),
          const SizedBox(height: 24),
          _buildCopyrightTemplateSection(),
          const SizedBox(height: 16),
          _buildFileUploadSection(
            "Copyright Form (pdf only)",
            copyrightFileName,
            () => _pickFile('copyright'),
            Icons.copyright,
          ),
        ],
      ),
    );
  }

  Widget _buildCopyrightTemplateSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.download_rounded, color: Colors.indigo[700], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Copyright Form Template",
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Download the copyright form template, fill it out with your paper details, sign it, and upload the completed form below.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.indigo[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isDownloadingTemplate ? null : _downloadCopyrightTemplate,
              icon: isDownloadingTemplate 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.file_download, size: 18),
              label: Text(
                isDownloadingTemplate ? 'Downloading...' : 'Download Template',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadSection(String label, String? fileName, VoidCallback onPick, IconData icon) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Maximum file size: 20MB',
            style: TextStyle(fontSize: 14, color: Colors.grey[700], fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fileName != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.insert_drive_file, color: Colors.blue[700], size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName,
                            style: TextStyle(color: Colors.blue[700]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'No file chosen',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.upload_file),
                    label: Text(fileName != null ? 'Change File' : 'Choose File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraReadyForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.task_alt, color: Colors.green[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Camera Ready Complete',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your paper is now Camera Ready. You are no longer allow to upload.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_note, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Please update the paper title, abstract and keywords (if necessary).',
                          style: TextStyle(fontSize: 15, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildInputField('Paper Title', titleController, icon: Icons.title),
          const SizedBox(height: 24),
          _buildAbstractField(),
          const SizedBox(height: 24),
          _buildInputField('Paper Keywords', keywordsController, icon: Icons.tag),
          const SizedBox(height: 24),
          _buildInputField('Number of Pages', pageNoController, keyboardType: TextInputType.number, icon: Icons.format_list_numbered),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {TextInputType? keyboardType, IconData? icon}) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.grey[700]),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
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
                borderSide: BorderSide(color: Colors.blue),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbstractField() {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.subject, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Abstract',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: abstractController,
            maxLines: 5,
            decoration: InputDecoration(
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
                borderSide: BorderSide(color: Colors.blue),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.all(16),
              hintText: 'Enter your paper abstract',
            ),
            onChanged: (value) {
              setState(() {}); // Trigger rebuild to update word count
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.format_list_numbered, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${abstractController.text.split(' ').where((word) => word.isNotEmpty).length}/600 words',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const Spacer(),
              Icon(
                abstractController.text.split(' ').where((word) => word.isNotEmpty).length > 600
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle,
                size: 16,
                color: abstractController.text.split(' ').where((word) => word.isNotEmpty).length > 600
                    ? Colors.orange
                    : Colors.green,
              ),
              const SizedBox(width: 4),
              Text(
                abstractController.text.split(' ').where((word) => word.isNotEmpty).length > 600
                    ? 'Exceeds maximum'
                    : 'Within limit',
                style: TextStyle(
                  color: abstractController.text.split(' ').where((word) => word.isNotEmpty).length > 600
                      ? Colors.orange
                      : Colors.green,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Camera Ready Upload'),
          elevation: 0,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
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
        title: const Text('Camera Ready Upload'),
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey[50],
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: (paperData?['paper_status'] == 'Pre-Camera Ready' || 
                       paperData?['paper_status'] == 'Accepted')
                    ? _buildPreCameraReadyForm()
                    : _buildCameraReadyForm(),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _submitCameraReady,
                icon: const Icon(Icons.send),
                label: const Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
