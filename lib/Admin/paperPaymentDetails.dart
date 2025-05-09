import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class PaperPaymentDetails extends StatefulWidget {
  final String paperId;

  const PaperPaymentDetails({Key? key, required this.paperId}) : super(key: key);

  @override
  _PaperPaymentDetailsState createState() => _PaperPaymentDetailsState();
}

class _PaperPaymentDetailsState extends State<PaperPaymentDetails> {
  bool _isLoading = true;
  bool _isDownloading = false;
  Map<String, dynamic>? paymentData;
  final _remarkController = TextEditingController();
  String? _selectedStatus;
  String? _errorMessage;
  String? _paymentId;

  @override
  void initState() {
    super.initState();
    _fetchPaymentData();
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

  Future<void> _fetchPaymentData() async {
    try {
      final response = await http.get(
        Uri.parse('https://cmsa.digital/admin/get_paperPaymentDetails.php?paper_id=${widget.paperId}'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Response data: $jsonResponse');
        if (jsonResponse['success'] == true) {
          setState(() {
            paymentData = jsonResponse['data'];
            _paymentId = paymentData?['payment_id']?.toString();
            print('Payment ID: $_paymentId');
            _remarkController.text = paymentData?['payment_remarks'] ?? '';
            _selectedStatus = paymentData?['payment_status'];
            _errorMessage = null;
            _isLoading = false;
          });
        } else {
          setState(() {
            paymentData = null;
            _errorMessage = jsonResponse['message'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching payment data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading payment data';
      });
    }
  }

  Future<void> _updatePaymentStatus() async {
    print('Updating payment with ID: $_paymentId');
    if (_paymentId == null || _paymentId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No payment found to update'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Update'),
          content: Text('Are you sure you want to update this payment status?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Update', style: TextStyle(color: Color(0xFFffc107), fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://cmsa.digital/admin/edit_paperPaymentDetails.php'),
        body: {
          'payment_id': _paymentId,
          'payment_status': _selectedStatus,
          'payment_remarks': _remarkController.text,
        },
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Success', style: TextStyle(color: Color(0xFF388E3C))),
                content: Text('Payment status has been updated successfully.'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                actions: [
                  TextButton(
                    child: Text('OK', style: TextStyle(color: Color(0xFFffc107), fontWeight: FontWeight.bold)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          );
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaperPaymentDetails(paperId: widget.paperId),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(jsonResponse['message'] ?? 'Failed to update status'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error updating payment status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating payment status'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _downloadPaymentFile() async {
    if (paymentData == null || paymentData!['payment_filename'] == null || paymentData!['payment_filename'].isEmpty) {
      print('Payment filename is null or empty in payment data');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Payment file not available')),
            ],
          ),
          width: 400, // Set a maximum width to prevent stretching
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    
    setState(() => _isDownloading = true);
    
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading payment proof...'),
          duration: Duration(seconds: 2),
        ),
      );

      final String paymentFilename = paymentData!['payment_filename'];
      // Check if it's already a complete URL
      final String downloadUrl = paymentFilename.startsWith('http') 
          ? paymentFilename 
          : 'https://cmsa.digital/assets/payments/${paymentFilename}.pdf';
      
      // Get filename from either the URL or use the original name with extension
      final String fileName = paymentFilename.startsWith('http')
          ? downloadUrl.split('/').last
          : '${paymentFilename}.pdf';
      
      print('Downloading payment file from: $downloadUrl');
      print('Will save as: $fileName');

      // Handle web platform viewing/download
      if (kIsWeb) {
        try {
          // Open in a new tab
          html.window.open(downloadUrl, '_blank');
          
          setState(() {
            _isDownloading = false;
          });
          
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF opened in a new tab')),
          );
          
          return;
        } catch (e) {
          print('Error opening PDF in web browser: $e');
          
          // Fallback to download if opening in new tab fails
          try {
            html.AnchorElement anchor = html.AnchorElement(href: downloadUrl);
            anchor.download = fileName;
            anchor.style.display = 'none';
            html.document.body?.children.add(anchor);
            anchor.click();
            html.document.body?.children.remove(anchor);
            
            setState(() {
              _isDownloading = false;
            });
            
            if (!mounted) return;
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Download started. Check your browser downloads folder.')),
            );
          } catch (e2) {
            print('Error in fallback download: $e2');
            setState(() {
              _isDownloading = false;
            });
            
            if (!mounted) return;
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to open PDF. Your browser may be blocking the action.'),
                duration: Duration(seconds: 5),
              ),
            );
          }
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
      Uri uri;
      try {
        uri = Uri.parse(downloadUrl);
      } catch (e) {
        print('Error parsing URL: $downloadUrl, error: $e');
        throw Exception('Invalid URL format for payment file: $downloadUrl');
      }
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        // Check if response is an error page or actual file
        if (response.headers['content-type']?.contains('text/html') == true) {
          throw Exception('Payment proof file not found on server');
        }
        
        try {
          // Save the file
          final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        
        setState(() => _isDownloading = false);
        
          if (!mounted) return;
          
          // Show success dialog
          _showDownloadSuccessDialog(savePath);
        } catch (e) {
          print('Error saving file: $e');
          throw Exception('Could not save the file. Storage access denied.');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Payment proof file not found on server');
      } else {
        throw Exception("Failed to download file: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _isDownloading = false);
      print('Error downloading file: $e');
      
      if (!mounted) return;
      
      String errorMessage = e.toString();
      
      // Provide user-friendly error messages
      if (errorMessage.contains('not found')) {
        errorMessage = 'Payment proof file not found on server. Please contact support.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            width: 400, // Set a maximum width to prevent stretching
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            width: 400, // Set a maximum width to prevent stretching
            backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        _handlePermissionDenied();
      } else {
        // For other errors, show a standard error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error downloading file: $errorMessage')),
              ],
            ),
            width: 400, // Set a maximum width to prevent stretching
          backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
  
  void _handlePermissionDenied() {
    setState(() => _isDownloading = false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Storage Permission Required'),
          content: Text(
            'This app needs storage permission to download files. '
            'Please grant permission in app settings.'
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // Helper method to get the appropriate color for a payment status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'committed':
        return Color(0xFF4CAF50);
      case 'submitted':
        return Color(0xFF2196F3);
      case 'incomplete':
        return Color(0xFFFF9800);
      case 'failed':
      case 'problem':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Payment Details', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFFffc107),
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffc107)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Details', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFffc107),
      ),
      body: Container(
        color: Colors.grey[50],
        child: paymentData == null 
          ? Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Color(0xFFffb74d), width: 1.5),
                ),
                child: Padding(
                  padding: EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Color(0xFFcc9600),
                      ),
                      SizedBox(height: 16),
                      Text(
                        _errorMessage == 'Payment paper is not available'
                            ? 'Payment paper is not available'
                            : 'No payment found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF757575),
                        ),
                      ),
                      if (_errorMessage == 'Payment paper is not available') ...[
                        SizedBox(height: 8),
                        Text(
                          'Please wait until the author uploads the camera ready version',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF757575),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          )
          : SingleChildScrollView(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Payment Information'),
                SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Color(0xFFFFE082), width: 1),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Payment ID', paymentData!['payment_id'].toString()),
                        Divider(color: Color(0xFFFFE082), height: 32, thickness: 1),
                        _buildInfoRow('Amount Paid', paymentData!['payment_paid']),
                        SizedBox(height: 16),
                        _buildStatusRow('Payment Status', paymentData!['payment_status']),
                        SizedBox(height: 16),
                        _buildInfoRow('Payment Method', paymentData!['payment_method']),
                        SizedBox(height: 16),
                        _buildInfoRow('Payment Date', paymentData!['payment_date']),
                        Divider(color: Color(0xFFFFE082), height: 32, thickness: 1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payment File',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isDownloading ? null : _downloadPaymentFile,
                              icon: _isDownloading 
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(Icons.download),
                              label: Text(_isDownloading ? 'Downloading...' : 'Download'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFffc107),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                
                _buildSectionTitle('Update Payment Status'),
                SizedBox(height: 16),
                
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Color(0xFFFFE082), width: 1),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormLabel('Payment Status'),
                        SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color(0xFFffc107), width: 2),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            icon: Icon(Icons.arrow_drop_down, color: Color(0xFFffa000)),
                            dropdownColor: Colors.white,
                            items: ['Incomplete', 'Committed', 'Confirmed', 'Failed', 'Problem', 'Rejected', 'Submitted']
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(status),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text(status),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedStatus = value);
                            },
                          ),
                        ),
                        SizedBox(height: 20),
                        
                        _buildFormLabel('Payment Remarks'),
                        SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _remarkController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Enter remarks here...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color(0xFFffc107), width: 2),
                              ),
                              contentPadding: EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        
                        ElevatedButton(
                          onPressed: _updatePaymentStatus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFffc107),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            elevation: 3,
                            shadowColor: Color(0xFFffc107).withOpacity(0.5),
                            minimumSize: Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 24),
                              SizedBox(width: 10),
                              Text(
                                'UPDATE STATUS',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
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
            ),
          ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Color(0xFFffc107),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Row(
      children: [
        Icon(Icons.label, size: 16, color: Color(0xFFffa000)),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Container(
            alignment: Alignment.centerRight,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _getStatusColor(status), width: 1),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(status),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDownloadSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success', style: TextStyle(color: Color(0xFF388E3C))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File downloaded successfully to:'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  filePath,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              child: Text('Open File', style: TextStyle(color: Color(0xFFffc107))),
              onPressed: () {
                Navigator.of(context).pop();
                OpenFile.open(filePath);
              },
            ),
            TextButton(
              child: Text('OK', style: TextStyle(color: Colors.grey[700])),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}