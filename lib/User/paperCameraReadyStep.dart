import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:CMSapplication/User/paperCameraReadyUpload.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class PaperCameraReadyStep extends StatefulWidget {
  final String paperId;

  const PaperCameraReadyStep({Key? key, required this.paperId}) : super(key: key);

  @override
  State<PaperCameraReadyStep> createState() => _PaperCameraReadyStepState();
}

class _PaperCameraReadyStepState extends State<PaperCameraReadyStep> {
  Map<String, dynamic>? paperData;
  bool isLoading = true;
  bool isDownloading = false;
  bool _isDownloadingPaper = false;
  bool _isDownloadingCopyright = false;

  @override
  void initState() {
    super.initState();
    fetchPaperData();
    if (!kIsWeb) {
      _checkPermissions();
    }
  }

  Future<void> fetchPaperData() async {
    try {
      final response = await http.post(
        Uri.parse('https://cmsa.digital/user/get_paperCameraReadyStep.php'),
        body: {'paper_id': widget.paperId},
      );

      if (response.statusCode == 200) {
        setState(() {
          paperData = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
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

  Future<void> _downloadFile(String fileType) async {
    if (paperData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paper data not available')),
      );
      return;
    }

    String? fileName;
    String? fileUrl;
    
    if (fileType == 'paper') {
      setState(() => _isDownloadingPaper = true);
      fileName = paperData!['paper_ready'];
      if (fileName != null && fileName.isNotEmpty) {
        fileName = "$fileName.docx"; // Append .docx extension
      }
      fileUrl = 'https://cmsa.digital/assets/papers/camera_ready/$fileName';
    } else if (fileType == 'copyright') {
      setState(() => _isDownloadingCopyright = true);
      fileName = paperData!['paper_copyright'];
      fileUrl = 'https://cmsa.digital/assets/papers/copyright_form/$fileName';
    }
    
    if (fileName == null || fileName.isEmpty || fileUrl == null) {
      String message = fileType == 'paper' 
          ? 'Camera ready paper not available' 
          : 'Copyright form not available';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      
      if (fileType == 'paper') {
        setState(() => _isDownloadingPaper = false);
      } else {
        setState(() => _isDownloadingCopyright = false);
      }
      return;
    }
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading ${fileType == 'paper' ? 'camera ready paper' : 'copyright form'}...')),
      );
      
      // Handle web platform differently
      if (kIsWeb) {
        try {
          // For web, use html anchor to directly download or open in a new tab
          html.AnchorElement anchor = html.AnchorElement(href: fileUrl);
          anchor.download = fileName; // Set the download attribute for the anchor
          anchor.target = '_blank'; // Open in a new tab
          anchor.click(); // Simulate a click
          
          if (fileType == 'paper') {
            setState(() => _isDownloadingPaper = false);
          } else {
            setState(() => _isDownloadingCopyright = false);
          }
          
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File download initiated. Check your downloads folder.'),
              duration: const Duration(seconds: 3),
            ),
          );
          
          return;
        } catch (e) {
          print('Error downloading in web browser: $e');
          throw Exception('Failed to download the file in web browser');
        }
      }

      // Below code only runs on mobile platforms

      // Check if paper_ready exists and is not empty
      final String? paperReady = paperData!['paper_ready'];
      if (paperReady == null || paperReady.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paper file information is missing. Please contact support.')),
        );
        return;
      }

      setState(() {
        isDownloading = true;
      });

      try {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloading paper...'), duration: Duration(seconds: 2)),
        );
        
        final String downloadUrl = fileUrl!;
        
        print('Downloading paper from: $downloadUrl');

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
            
            savePath = '$usablePath/$fileName';
            print('Using save path: $savePath');
          } catch (e) {
            print('Error determining save path: $e');
            throw Exception('Could not determine a location to save the file: ${e.toString()}');
          }
        } else if (Platform.isIOS) {
          final directory = await getApplicationDocumentsDirectory();
          savePath = '${directory.path}/$fileName';
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
              isDownloading = false;
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
          isDownloading = false;
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
    } catch (e) {
      print('Error downloading file: $e');
      
      setState(() {
        isDownloading = false;
      });
      
      if (!mounted) return;
      
      String errorMessage = e.toString();
      
      // Provide user-friendly error messages
      if (errorMessage.contains('not found')) {
        errorMessage = 'File not found on server. Please contact support.';
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

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final status = paperData?['paper_status'] ?? '';
    
    if (['Submitted', 'Received', 'Resubmit', 'Under Review', 'Withdraw', 'Rejected']
        .contains(status)) {
      return _buildNotAvailableBox();
    }

    switch (status) {
      case 'Accepted':
        return _buildAcceptedBox();
      case 'Pre-Camera Ready':
        return _buildPreCameraReadyBox();
      case 'Camera Ready':
        return _buildCameraReadyBox();
      default:
        return _buildNotAvailableBox();
    }
  }

  Widget _buildNotAvailableBox() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Not available',
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAcceptedBox() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status message with icon
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.assignment_turned_in, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your paper status is Accepted',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Congratulations! Your paper has been accepted for the conference.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Instructions section
            Text(
              'Next Steps',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please upload your camera ready paper following the guidelines set by the ${paperData?['conf_id']} organizer. Make sure all the amendments requested by the reviewers have been completed.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Upload button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaperCameraReadyUpload(
                        paperId: widget.paperId,
                      ),
                    ),
                  );
                  
                  // Refresh the page if we get a positive result
                  if (result == true) {
                    fetchPaperData();
                  }
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Camera Ready'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 1,
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Only show remarks if they exist
            if (paperData?['paper_cr_remark'] != null && paperData!['paper_cr_remark'].toString().isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.comment, color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Remarks:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      paperData?['paper_cr_remark'] ?? '',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreCameraReadyBox() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status message with icon
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.hourglass_bottom, color: Colors.amber[700], size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your paper status is Pre-Camera Ready',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your paper is currently under review by organizers',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Instructions section
            Text(
              'Review Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait for the conference organizer to check your submitted pre-camera ready paper. You can still reupload your pre-camera ready paper if needed.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isDownloading || paperData?['paper_ready'] == null || paperData!['paper_ready'].toString().isEmpty
                        ? null
                        : () => _downloadFile('paper'),
                    icon: isDownloading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(
                        isDownloading
                            ? 'Downloading...'
                            : (paperData?['paper_ready'] == null || paperData!['paper_ready'].toString().isEmpty)
                                ? 'No file available'
                                : 'Download'
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (paperData?['paper_ready'] == null || paperData!['paper_ready'].toString().isEmpty)
                          ? Colors.grey[300]
                          : Colors.blue,
                      foregroundColor: (paperData?['paper_ready'] == null || paperData!['paper_ready'].toString().isEmpty)
                          ? Colors.black54
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: isDownloading
                          ? Colors.blue.withOpacity(0.7)
                          : Colors.grey[300],
                      disabledForegroundColor: isDownloading
                          ? Colors.white.withOpacity(0.9)
                          : Colors.black38,
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaperCameraReadyUpload(
                            paperId: widget.paperId,
                          ),
                        ),
                      );
                      
                      // Refresh the page if we get a positive result
                      if (result == true) {
                        fetchPaperData();
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Only show remarks if they exist
            if (paperData?['paper_cr_remark'] != null && paperData!['paper_cr_remark'].toString().isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.comment, color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Remarks:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      paperData?['paper_cr_remark'] ?? '',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCameraReadyBox() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status message with icon
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your paper status is Camera Ready',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Congratulation, your paper is now completed.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Instructions section
            Text(
              'Next Steps',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please continue with the payment to complete your submission process.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isDownloading || paperData?['paper_ready'] == null || paperData!['paper_ready'].toString().isEmpty
                        ? null
                        : () => _downloadFile('paper'),
                    icon: isDownloading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(
                        isDownloading
                            ? 'Downloading...'
                            : (paperData?['paper_ready'] == null || paperData!['paper_ready'].toString().isEmpty)
                                ? 'No file available'
                                : 'Download'
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (paperData?['paper_ready'] == null || paperData!['paper_ready'].toString().isEmpty)
                          ? Colors.grey[300]
                          : Colors.blue,
                      foregroundColor: (paperData?['paper_ready'] == null || paperData!['paper_ready'].toString().isEmpty)
                          ? Colors.black54
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: isDownloading
                          ? Colors.blue.withOpacity(0.7)
                          : Colors.grey[300],
                      disabledForegroundColor: isDownloading
                          ? Colors.white.withOpacity(0.9)
                          : Colors.black38,
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaperCameraReadyUpload(
                            paperId: widget.paperId,
                          ),
                        ),
                      );
                      
                      // Refresh the page if we get a positive result
                      if (result == true) {
                        fetchPaperData();
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Only show remarks if they exist
            if (paperData?['paper_cr_remark'] != null && paperData!['paper_cr_remark'].toString().isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.comment, color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Remarks:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      paperData?['paper_cr_remark'] ?? '',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); // Send refresh signal back
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Camera Ready'),
          elevation: 0,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, true); // Send refresh signal back
            },
          ),
        ),
        body: SingleChildScrollView(
          child: _buildContent(),
        ),
      ),
    );
  }
}
