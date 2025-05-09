import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:CMSapplication/User/paperReviewRemark.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class PaperReviewStep extends StatefulWidget {
  final String paperId;

  const PaperReviewStep({Key? key, required this.paperId}) : super(key: key);

  @override
  _PaperReviewStepState createState() => _PaperReviewStepState();
}

class _PaperReviewStepState extends State<PaperReviewStep> {
  bool isLoading = true;
  String paperStatus = '';
  List<dynamic> reviews = [];
  Map<String, bool> isDownloading = {};

  @override
  void initState() {
    super.initState();
    fetchReviewDetails();
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

  Future<void> fetchReviewDetails() async {
    try {
      final response = await http.get(
        Uri.parse('https://cmsa.digital/user/get_paperReviewStep.php?paper_id=${widget.paperId}')
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            paperStatus = data['paper_status'];
            reviews = data['reviews'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching review details: $e');
      setState(() => isLoading = false);
    }
  }

  String _getStatusNote(String status) {
    switch (status) {
      case 'Under Review':
        return 'Review is in progress. Please wait until review process completed. A new menu will appear once the review process has been completed.';
      case 'Accepted':
        return 'Review process has completed. Please proceed to make ammendment based on recomendation by reviewers. Once completed please proceed to step 3 - Pre-Camera/Camera Ready.';
      case 'Pre-Camera Ready':
        return 'Review process has completed.';
      default:
        return '';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Under Review':
        return Colors.blue;
      case 'Accepted':
        return Colors.green;
      case 'Pre-Camera Ready':
        return Colors.amber;
      case 'Camera Ready':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Withdrawal':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Under Review':
        return Icons.pending_actions;
      case 'Accepted':
        return Icons.check_circle;
      case 'Pre-Camera Ready':
        return Icons.description;
      case 'Camera Ready':
        return Icons.task_alt;
      case 'Rejected':
        return Icons.cancel;
      case 'Withdrawal':
        return Icons.restore_from_trash;
      default:
        return Icons.info_outline;
    }
  }

  Future<void> _downloadReviewFile(Map<String, dynamic> review) async {
    final String reviewId = review['review_id'].toString();
    final String? reviewFilename = review['review_filename'];
    
    if (reviewFilename == null || reviewFilename.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No review file available for download'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      isDownloading[reviewId] = true;
    });

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading review file...'), duration: Duration(seconds: 2)),
      );
      
      final String fileExt = '.docx';
      final String filename = '$reviewFilename$fileExt';
      final String downloadUrl = 'https://cmsa.digital/assets/reviews/reviewer_paper/$filename';
      
      print('Downloading review file from: $downloadUrl');
      
      // Handle web platform differently
      if (kIsWeb) {
        try {
          // For web, use html anchor to directly download or open in a new tab
          html.AnchorElement anchor = html.AnchorElement(href: downloadUrl);
          anchor.download = filename; // Set the download attribute for the anchor
          anchor.target = '_blank'; // Open in a new tab
          anchor.click(); // Simulate a click
          
          setState(() {
            isDownloading[reviewId] = false;
          });
          
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
          throw Exception('Review file not found on server');
        }
        
        try {
          // Save the file
          final file = File(savePath);
          await file.writeAsBytes(response.bodyBytes);
          
          setState(() {
            isDownloading[reviewId] = false;
          });
          
          if (!mounted) return;
          
          // Show success dialog instead of just a snackbar
          _showDownloadSuccessDialog(savePath);
          // Also show a brief snackbar to confirm the download
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Review file downloaded successfully'),
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (e) {
          print('Error saving file: $e');
          throw Exception('Could not save the file. Storage access denied.');
        }
      } else {
        if (response.statusCode == 404) {
          throw Exception('Review file not found on server');
        } else {
          throw Exception('Failed to download file: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error downloading review file: $e');
      
      setState(() {
        isDownloading[reviewId] = false;
      });
      
      if (!mounted) return;
      
      String errorMessage = e.toString();
      
      // Provide user-friendly error messages
      if (errorMessage.contains('not found')) {
        errorMessage = 'Review file not found on server. Please contact support.';
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
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Paper Review'),
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
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading review details...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paper Review'),
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
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (['Submitted', 'Received', 'Resubmit'].contains(paperStatus))
                _buildMessageBox('Not available')
              else if (paperStatus == 'Rejected')
                _buildMessageBox('Your paper has been rejected')
              else if (paperStatus == 'Withdrawal')
                _buildMessageBox('You have requested to withdraw your paper from the conference.')
              else if (['Under Review', 'Pre-Camera Ready', 'Camera Ready', 'Accepted'].contains(paperStatus)) ...[
                // Header
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Review Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Review Cards
                ...List.generate(reviews.length, (index) {
                  final review = reviews[index];
                  final bool isReleased = review['user_release'] == 'Yes';
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
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
                            color: Colors.blue[50],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Review #${review['review_id']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isReleased ? Colors.green[100] : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  isReleased ? 'Released' : 'Pending',
                                  style: TextStyle(
                                    color: isReleased ? Colors.green[800] : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.article_outlined, size: 16, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text(
                                          'Details',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (!isReleased || !['Accepted', 'Pre-Camera Ready', 'Camera Ready'].contains(paperStatus))
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Not Available Yet',
                                              style: TextStyle(
                                                color: Colors.grey[800],
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.lock_outline, size: 16, color: Colors.grey[600]),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    !isReleased 
                                                      ? 'This review is pending release' 
                                                      : 'Available once paper is accepted',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PaperReviewRemark(
                                                reviewId: review['review_id'].toString(),
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.visibility),
                                        label: const Text('View'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.download_outlined, size: 16, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text(
                                          'Download',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (!isReleased || !['Accepted', 'Pre-Camera Ready', 'Camera Ready'].contains(paperStatus))
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Not Available Yet',
                                              style: TextStyle(
                                                color: Colors.grey[800],
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.lock_outline, size: 16, color: Colors.grey[600]),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    !isReleased 
                                                      ? 'This review is pending release' 
                                                      : 'Available once paper is accepted',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      ElevatedButton.icon(
                                        onPressed: (review['review_filename'] == null || 
                                                   review['review_filename'] == '') ||
                                                  (isDownloading[review['review_id'].toString()] ?? false) 
                                            ? null 
                                            : () {
                                                _downloadReviewFile(review);
                                              },
                                        icon: (isDownloading[review['review_id'].toString()] ?? false)
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
                                            (isDownloading[review['review_id'].toString()] ?? false)
                                            ? 'Downloading...'
                                            : (review['review_filename'] == null || review['review_filename'] == '')
                                                ? 'No file available'
                                                : 'Download'
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: (review['review_filename'] == null || review['review_filename'] == '')
                                              ? Colors.grey[300]
                                              : Colors.green,
                                          foregroundColor: (review['review_filename'] == null || review['review_filename'] == '')
                                              ? Colors.black54
                                              : Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          disabledBackgroundColor: (isDownloading[review['review_id'].toString()] ?? false)
                                              ? Colors.green.withOpacity(0.7)
                                              : Colors.grey[300],
                                          disabledForegroundColor: (isDownloading[review['review_id'].toString()] ?? false)
                                              ? Colors.white.withOpacity(0.9)
                                              : Colors.black38,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBox(String message) {
    IconData iconData;
    Color iconColor;
    String title;
    String description;
    Color bgColor;
    
    if (message.contains('rejected')) {
      iconData = Icons.cancel_outlined;
      iconColor = Colors.red[700]!;
      title = 'Paper Rejected';
      description = 'Your paper was not accepted for presentation at the conference.';
      bgColor = Colors.red[50]!;
    } else if (message.contains('withdraw')) {
      iconData = Icons.undo;
      iconColor = Colors.orange[700]!;
      title = 'Paper Withdrawn';
      description = 'You have withdrawn your paper from the conference evaluation process.';
      bgColor = Colors.orange[50]!;
    } else {
      // Not available case
      iconData = Icons.pending_outlined;
      iconColor = Colors.blue[700]!;
      title = 'Review Not Available Yet';
      description = 'Reviews will be available once your paper has been evaluated by the conference reviewers.';
      bgColor = Colors.blue[50]!;
    }
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    size: 28,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              children: [
                if (!message.contains('rejected') && !message.contains('withdraw')) ...[
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Please wait until the review process is completed',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.visibility_outlined, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Reviews will become visible here once they are released',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (message.contains('rejected')) ...[
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your paper does not meet the requirements for presentation at this conference',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (message.contains('withdraw')) ...[
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your paper has been removed from the conference review process at your request',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
