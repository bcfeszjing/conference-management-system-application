import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:CMSapplication/User/paperReviewRubrics1.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class ReviewPaperDetails extends StatefulWidget {
  final String reviewId;
  final String paperId;

  const ReviewPaperDetails({
    Key? key,
    required this.reviewId,
    required this.paperId,
  }) : super(key: key);

  @override
  State<ReviewPaperDetails> createState() => _ReviewPaperDetailsState();
}

class _ReviewPaperDetailsState extends State<ReviewPaperDetails> {
  Map<String, dynamic>? paperDetails;
  bool isLoading = true;
  bool isDownloading = false;

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
        Uri.parse('https://cmsa.digital/user/get_reviewPaperDetails.php?paper_id=${widget.paperId}&review_id=${widget.reviewId}'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          paperDetails = responseData;
          isLoading = false;
          print("Paper name from server: ${paperDetails!['paper_name']}"); // Debug print for paper_name
        });
      }
    } catch (e) {
      print('Error fetching paper details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _declineReview() async {
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Decline'),
          content: Text('Are you sure you want to decline this review? This action cannot be undone.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Decline', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirm) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    try {
      final response = await http.post(
        Uri.parse('https://cmsa.digital/user/decline_reviewPaper.php'),
        body: {
          'review_id': widget.reviewId,
        },
      );

      // Close loading indicator
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Review declined successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh the current page instead of navigating back
          setState(() {
            isLoading = true;
          });
          await fetchPaperDetails();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(jsonResponse['message'] ?? 'Failed to decline review'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading indicator if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      print('Error declining review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error declining review'),
          backgroundColor: Colors.red,
        ),
      );
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

  Future<void> _downloadPaper() async {
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
      isDownloading = true;
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
            isDownloading = false;
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

      // Get the download directory based on platform (Mobile only code below)
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paper Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Send refresh signal back to previous page
            Navigator.pop(context, true);
          },
        ),
      ),
      body: Container(
        color: Colors.grey[50],
        child: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading paper details...', 
                    style: TextStyle(color: Colors.grey[700]))
                ],
              )
            )
          : paperDetails == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      SizedBox(height: 16),
                      Text('Error loading paper details',
                        style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchPaperDetails,
                        child: Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      )
                    ],
                  )
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: paperDetails!['review_status'] == 'Reviewed'
                      ? _buildReviewedContent()
                      : _buildAssignedContent(),
                ),
      ),
    );
  }

  Widget _buildReviewedContent() {
    return Column(
      children: [
        // Status indicator
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review Complete',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  Text(
                    'You have reviewed this paper',
                    style: TextStyle(color: Colors.green[700]),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Paper details card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Paper Information', Icons.article),
                const SizedBox(height: 16),
                _buildInfoRow('Title', paperDetails!['paper_title']),
                const Divider(height: 24),
                _buildInfoRow('Keywords', paperDetails!['paper_keywords']),
                const SizedBox(height: 24),
                
                _buildSectionHeader('Abstract', Icons.description),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    paperDetails!['paper_abstract'],
                    style: TextStyle(fontSize: 15, height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),
                
                _buildSectionHeader('Review Information', Icons.rate_review),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Total Marks',
                        paperDetails!['review_totalmarks'].toString(),
                        Colors.blue[50]!,
                        Colors.blue,
                        Icons.score
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        'Status',
                        paperDetails!['review_status'],
                        Colors.green[50]!,
                        Colors.green,
                        Icons.check_circle
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedContent() {
    return Column(
      children: [
        // Status indicator
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: paperDetails!['review_status'] == 'Assigned' 
                ? Colors.blue[50]
                : Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: paperDetails!['review_status'] == 'Assigned' 
                    ? Colors.blue[200]!
                    : Colors.red[200]!),
          ),
          child: Row(
            children: [
              Icon(
                paperDetails!['review_status'] == 'Assigned' 
                    ? Icons.assignment
                    : Icons.cancel,
                color: paperDetails!['review_status'] == 'Assigned' 
                    ? Colors.blue
                    : Colors.red,
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paperDetails!['review_status'] == 'Assigned' 
                        ? 'Review Pending'
                        : 'Review Declined',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: paperDetails!['review_status'] == 'Assigned' 
                          ? Colors.blue[800]
                          : Colors.red[800],
                    ),
                  ),
                  Text(
                    paperDetails!['review_status'] == 'Assigned' 
                        ? 'This paper is assigned to you for review'
                        : 'You have declined to review this paper',
                    style: TextStyle(
                      color: paperDetails!['review_status'] == 'Assigned' 
                          ? Colors.blue[700]
                          : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Paper details card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Paper Information', Icons.article),
                const SizedBox(height: 16),
                _buildInfoRow('Title', paperDetails!['paper_title']),
                const Divider(height: 24),
                _buildInfoRow('Keywords', paperDetails!['paper_keywords']),
                const Divider(height: 24),
                _buildInfoRow('Total Marks', paperDetails!['review_totalmarks'].toString()),
                const SizedBox(height: 24),
                
                _buildSectionHeader('Abstract', Icons.description),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    paperDetails!['paper_abstract'],
                    style: TextStyle(fontSize: 15, height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),
                
                _buildSectionHeader('Paper Download', Icons.download),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isDownloading || paperDetails!['file_exists'] == false ? null : _downloadPaper,
                    icon: isDownloading 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.download),
                    label: Text(
                      isDownloading
                        ? 'Downloading...'
                        : (paperDetails!['file_exists'] == true
                            ? 'Download Paper'
                            : 'Paper Not Available')
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: paperDetails!['file_exists'] == true ? Colors.blue : Colors.grey[300],
                      foregroundColor: paperDetails!['file_exists'] == true ? Colors.white : Colors.black54,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.black38,
                    ),
                  ),
                ),
                
                if (paperDetails!['review_status'] == 'Assigned') ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader('Review Action', Icons.rate_review),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaperReviewRubrics1(
                              reviewId: widget.reviewId,
                              paperId: widget.paperId,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.rate_review),
                      label: Text('Review Paper'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        // Decline review card
        if (paperDetails!['review_status'] == 'Assigned') ...[
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Decline Review', Icons.cancel),
                  const SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You can decline to review this paper. Once declined, the paper will no longer be available for review.',
                                style: TextStyle(
                                  color: Colors.red[800],
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _declineReview,
                            icon: Icon(Icons.cancel),
                            label: Text('Decline Review'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        
        // Add some bottom spacing
        SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
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
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoCard(String label, String value, Color bgColor, Color textColor, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: textColor),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: textColor.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}