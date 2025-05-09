import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class PaperPaymentStep extends StatefulWidget {
  final String paperId;

  const PaperPaymentStep({Key? key, required this.paperId}) : super(key: key);

  @override
  State<PaperPaymentStep> createState() => _PaperPaymentStepState();
}

class _PaperPaymentStepState extends State<PaperPaymentStep> {
  bool isLoading = true;
  bool isDownloading = false;
  Map<String, dynamic>? paymentData;
  final paymentController = TextEditingController();
  String? selectedPaymentMethod;
  String? proofFileName;
  Uint8List? proofFileBytes;
  
  final List<String> paymentMethods = [
    'Bank Draft',
    'Debit Card',
    'Credit Card',
    'Cheque',
    'Cash',
    'FPX/Internet Banking',
    'Local Order',
    'Research Grant',
    'Telegraphic Transfer',
    'Others'
  ];

  @override
  void initState() {
    super.initState();
    fetchPaymentData();
    if (!kIsWeb) {
      _checkPermissions();
    }
  }

  Future<void> fetchPaymentData() async {
    try {
      final response = await http.post(
        Uri.parse('https://cmsa.digital/user/get_paperPaymentStep.php'),
        body: {'paper_id': widget.paperId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Paper Payment Data: $data");
        setState(() {
          paymentData = data;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching payment data: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // Ensure we get the file data
    );

    if (result != null) {
      // Check file size (limit to 20MB = 20 * 1024 * 1024 bytes)
      final int maxSize = 20 * 1024 * 1024; // 20MB in bytes
      if (result.files.single.size > maxSize) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('File is too large. Maximum size is 20MB.'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      setState(() {
        proofFileName = result.files.single.name;
        proofFileBytes = result.files.single.bytes;
      });
    }
  }

  Future<void> _submitPayment() async {
    // Validate payment amount
    if (paymentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Please enter payment amount'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate payment method
    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Please select a payment method'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate payment proof file is selected
    if (proofFileBytes == null || proofFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Please upload a payment proof document (PDF)'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show loading
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
                    Text('Processing payment...', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    try {
      // Create a multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://cmsa.digital/user/add_paperPaymentStep.php'),
      );

      // Add fields
      request.fields['paper_id'] = widget.paperId;
      request.fields['payment_amount'] = paymentController.text;
      request.fields['payment_method'] = selectedPaymentMethod!;

      // Add payment proof file
      request.files.add(
        http.MultipartFile.fromBytes(
          'payment_proof_file',
          proofFileBytes!,
          filename: proofFileName,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Close loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // Clear form fields
          setState(() {
            paymentController.clear();
            selectedPaymentMethod = null;
            proofFileName = null;
            proofFileBytes = null;
          });
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(data['message'])),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          
          // Refresh the page
          fetchPaymentData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(data['message'])),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      } else {
        throw Exception('Failed to submit payment');
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://epay.uum.edu.my/payment_form.php');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
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
  
  Future<void> _downloadPaymentProof() async {
    if (paymentData == null || paymentData!['payment_filename'] == null || paymentData!['payment_filename'].toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment proof is not available')),
      );
      return;
    }

    setState(() {
      isDownloading = true;
    });

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading payment proof...')),
      );
      
      final String paymentFilename = paymentData!['payment_filename'];
      final String fileExt = '.pdf'; // Always use PDF for payment proofs
      final String filename = '$paymentFilename$fileExt';
      final String downloadUrl = 'https://cmsa.digital/assets/payments/$filename';
      
      print('Downloading payment proof from: $downloadUrl');

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
          throw Exception('Payment proof file not found on server');
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
              content: Text('Payment proof downloaded successfully'),
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (e) {
          print('Error saving file: $e');
          throw Exception('Could not save the file. Storage access denied.');
        }
      } else {
        if (response.statusCode == 404) {
          throw Exception('Payment proof file not found on server');
        } else {
          throw Exception('Failed to download file: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error downloading payment proof: $e');
      
      setState(() {
        isDownloading = false;
      });
      
      if (!mounted) return;
      
      String errorMessage = e.toString();
      
      // Provide user-friendly error messages
      if (errorMessage.contains('not found')) {
        errorMessage = 'Payment proof file not found on server. Please contact support.';
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

  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                  Icon(Icons.payments, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
          'Payment (in MYR)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
                ],
              ),
              const SizedBox(height: 12),
        TextField(
          controller: paymentController,
          keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: const Icon(Icons.attach_money),
                  hintText: 'Enter payment amount',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
                  Icon(Icons.payment, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
          'Payment Method',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
                ],
              ),
              const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
          ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: selectedPaymentMethod,
            hint: const Text('Select payment method'),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
            items: paymentMethods.map((String method) {
              return DropdownMenuItem<String>(
                value: method,
                child: Text(method),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedPaymentMethod = newValue;
              });
            },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
                  Icon(Icons.receipt_long, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
              'Payment Proof (PDF)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Maximum file size: 20MB',
                style: TextStyle(fontSize: 14, color: Colors.grey[700], fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                  color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
              ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      proofFileName ?? 'No file chosen',
                      style: TextStyle(
                        color: proofFileName != null ? Colors.black : Colors.grey[600],
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Choose File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submitPayment,
            icon: const Icon(Icons.save),
            label: const Text(
              'Submit Payment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    final bool isPaymentConfirmed = paymentData?['payment_status'] == 'Confirmed';
    
    return Column(
      children: [
        Container(
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Payment Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
                _buildDetailRow('Payment ID', paymentData?['payment_id'] ?? ''),
                _buildDetailRow('Paid', paymentData?['payment_paid'] ?? ''),
                _buildDetailRow('Payment Method', paymentData?['payment_method'] ?? ''),
                _buildDetailRow('Payment Status', paymentData?['payment_status'] ?? ''),
                _buildDetailRow('Remarks', paymentData?['payment_remarks'] ?? ''),
                _buildDetailRow('Payment Date', paymentData?['payment_date'] ?? ''),
              const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payment Proof',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ElevatedButton.icon(
                      onPressed: isDownloading || (paymentData != null && (paymentData!['payment_filename'] == null || paymentData!['payment_filename'].toString().isEmpty)) 
                        ? null 
                        : _downloadPaymentProof,
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
                          : (paymentData != null && paymentData!['payment_filename'] != null && paymentData!['payment_filename'].toString().isNotEmpty
                              ? 'Download'
                              : 'Not Available')
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (paymentData != null && paymentData!['payment_filename'] != null && paymentData!['payment_filename'].toString().isNotEmpty) 
                          ? Colors.blue 
                          : Colors.grey[300],
                        foregroundColor: (paymentData != null && paymentData!['payment_filename'] != null && paymentData!['payment_filename'].toString().isNotEmpty) 
                          ? Colors.white 
                          : Colors.black54,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
          ),
        ),
        
        // Only show the additional payment section if payment status is not Confirmed
        if (!isPaymentConfirmed) ...[
          const SizedBox(height: 24),
          Container(
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_card, color: Colors.amber),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Additional Payment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildPaymentForm(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    // Format the date if this is the payment date row
    if (label == 'Payment Date' && value != null && value.toString().isNotEmpty) {
      // The date is already formatted from PHP, just display it
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              value.toString().toLowerCase(), // Convert AM/PM to am/pm
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Handle payment remarks
    if (label == 'Remarks') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              value == null || value.toString().isEmpty ? 'Not Available' : value.toString(),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          ],
        ),
      );
    }

    // Handle payment status with colored box
    if (label == 'Payment Status') {
      Color statusColor;
      switch (value?.toString().toLowerCase()) {
        case 'submitted':
          statusColor = Colors.orange;
          break;
        case 'committed':
          statusColor = Colors.blue;
          break;
        case 'confirmed':
          statusColor = Colors.green;
          break;
        case 'incomplete':
          statusColor = Colors.red;
          break;
        case 'failed':
          statusColor = Colors.red;
          break;
        case 'problem':
          statusColor = Colors.orange;
          break;
        case 'rejected':
          statusColor = Colors.red;
          break;
        default:
          statusColor = Colors.grey;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                value?.toString() ?? '',
                style: TextStyle(
                  fontSize: 15,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // For other rows, keep existing format
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            value?.toString() ?? '',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showPaymentInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
            color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B7C3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12.0),
                      topRight: Radius.circular(12.0),
                    ),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Instruction for Payment',
                          style: TextStyle(
                          color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 16, color: Colors.black),
                              children: [
                                TextSpan(
                                  text: 'Important: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                                TextSpan(
                                  text: 'Please upload a scanned copy of the bank slip/telegraphic transfer receipt for us to verify the transaction. Kindly write down the participant\'s name, date and time of the transfer and country & city of origin.',
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                          
                    const Text(
                      'Local presenters/participants',
                      style: TextStyle(
                              fontSize: 18,
                        fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          const Text(
                            'Payment must be made in Malaysian Ringgit (MYR).',
                            style: TextStyle(fontSize: 16),
                          ),
                          
                    const SizedBox(height: 8),
                    const Text(
                      'Banker\'s cheques',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'All cheques must be made out to "Universiti Utara Malaysia"',
                            style: TextStyle(fontSize: 16),
                          ),
                          
                    const SizedBox(height: 8),
                    const Text(
                      'Bank Transfer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Transfer should be made to the following account:',
                            style: TextStyle(fontSize: 16),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: TextStyle(fontSize: 16)),
                                      Expanded(child: Text('Account No: 0209 301000 0010', style: TextStyle(fontSize: 16))),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: TextStyle(fontSize: 16)),
                                      Expanded(child: Text('Bank Name: Bank Islam Malaysia Berhad (UUM Branch)', style: TextStyle(fontSize: 16))),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: TextStyle(fontSize: 16)),
                                      Expanded(child: Text('Name (Account Holder): Universiti Utara Malaysia', style: TextStyle(fontSize: 16))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                    const SizedBox(height: 8),
                    const Text(
                      'Online Payment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ', style: TextStyle(fontSize: 16)),
                                      const Text('Go to ', style: TextStyle(fontSize: 16)),
                        InkWell(
                          onTap: _launchURL,
                          child: const Text(
                            'Link',
                            style: TextStyle(
                                            fontSize: 16,
                              color: Colors.blue,
                                            decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: TextStyle(fontSize: 16)),
                                      Expanded(
                                        child: Text(
                                          'Select CONFERENCE/TRAINING. Select payment type \'PARTICIPATION FEE – CONFERENCE\'; then select payment for \'OTHERS\'',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: TextStyle(fontSize: 16)),
                                      Expanded(
                                        child: Text(
                                          'Please indicate the description "HFIEJV1(your paper ID)".',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: TextStyle(fontSize: 16)),
                                      Expanded(
                                        child: Text(
                                          'The amount of payment is in Malaysian Ringgit (MYR/RM).',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: TextStyle(fontSize: 16)),
                                      Expanded(
                                        child: Text(
                                          'Follow the instruction given. FPX and credit cards (only Mastercard or Visa) are accepted',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                    const SizedBox(height: 8),
                    const Text(
                      'Local Order',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'If you are using a local order, please provide us:',
                            style: TextStyle(fontSize: 16),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: TextStyle(fontSize: 16)),
                                      Expanded(child: Text('Name of the officer in-charge', style: TextStyle(fontSize: 16))),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: TextStyle(fontSize: 16)),
                                      Expanded(child: Text('Full address of the officer in-charge', style: TextStyle(fontSize: 16))),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: TextStyle(fontSize: 16)),
                                      Expanded(child: Text('A Guarantee Letter (GL) from the department.', style: TextStyle(fontSize: 16))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                    const SizedBox(height: 16),
                    const Text(
                      'International presenters/participants',
                      style: TextStyle(
                              fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                          
                          const SizedBox(height: 8),
                    const Text(
                      'Telegraphic Transfer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: TextStyle(fontSize: 16)),
                                      Expanded(child: Text('Account No: 0209 301000 0010', style: TextStyle(fontSize: 16))),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: TextStyle(fontSize: 16)),
                                      Expanded(child: Text('Bank Name: Bank Islam Malaysia Berhad (UUM Branch)', style: TextStyle(fontSize: 16))),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: TextStyle(fontSize: 16)),
                                      Expanded(child: Text('Name (Account Holder): Universiti Utara Malaysia', style: TextStyle(fontSize: 16))),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: TextStyle(fontSize: 16)),
                                      Expanded(child: Text('Swift Code: BIMBMYKL', style: TextStyle(fontSize: 16))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                    const SizedBox(height: 8),
                    const Text(
                      'Online Payment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ', style: TextStyle(fontSize: 16)),
                                      const Text('Go to ', style: TextStyle(fontSize: 16)),
                        InkWell(
                          onTap: _launchURL,
                          child: const Text(
                            'Link',
                            style: TextStyle(
                                            fontSize: 16,
                              color: Colors.blue,
                                            decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: TextStyle(fontSize: 16)),
                                      Expanded(
                                        child: Text(
                                          'Select CONFERENCE/TRAINING. Select payment type \'PARTICIPATION FEE – CONFERENCE\'; then select payment for \'OTHERS\'',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                  ],
                ),
              ),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: TextStyle(fontSize: 16)),
                                      Expanded(
                                        child: Text(
                                          'Please indicate the description "HFIEJV1(your paper ID)".',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: TextStyle(fontSize: 16)),
                                      Expanded(
                                        child: Text(
                                          'The amount of payment is in Malaysian Ringgit (MYR/RM).',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: TextStyle(fontSize: 16)),
                                      Expanded(
                                        child: Text(
                                          'Follow the instruction given. FPX and credit cards (only Mastercard or Visa) are accepted',
                                          style: TextStyle(fontSize: 16),
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoPayment() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(24.0),
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
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber[800], size: 28),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'No Payment Recorded',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
              const Text(
                'Please proceed with manual payment. Click on the following button for payment details.',
                      style: TextStyle(fontSize: 16, height: 1.5),
              ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                onPressed: () => _showPaymentInstructions(context),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('View Payment Instructions', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Once payment completed, please fill in the following form and submit as proof of payment.',
                              style: TextStyle(fontSize: 15),
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: _buildPaymentForm(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading payment details...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    final status = paymentData?['paper_status'] ?? '';
    print("Paper Status: '$status'");
    
    if (status != 'Camera Ready') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.all(24.0),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.lock_outline, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 16),
            const Text(
              'Payment Not Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This feature will be accessible once your paper has received Camera Ready status.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return paymentData?['payment_id'] != null
        ? _buildPaymentDetails()
        : _buildNoPayment();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildContent(),
              // Add extra padding at the bottom
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}