import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/conference_state.dart';
import 'package:CMSapplication/Admin/manageNewsPage.dart';
import 'dart:async';
import '../config/app_config.dart';

class AddNews extends StatefulWidget {
  const AddNews({Key? key}) : super(key: key);

  @override
  _AddNewsState createState() => _AddNewsState();
}

class _AddNewsState extends State<AddNews> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _scrollController = ScrollController();
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();
  bool _sendEmail = false;
  bool _isSubmitting = false;
  bool _isCheckingProgress = false;
  String? _referenceId;
  int _emailProgress = 0;
  int _emailTotal = 0;
  int _emailSent = 0;
  int _emailFailed = 0;
  String _emailStatus = '';
  int _wordCount = 0;
  String? _titleError;
  String? _contentError;
  Timer? _progressCheckTimer;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_updateWordCount);
  }

  void _updateWordCount() {
    if (!mounted) return;
    setState(() {
      _wordCount = _contentController.text.split(' ').where((word) => word.isNotEmpty).length;
    });
  }

  void _showSuccessDialog(BuildContext context, {bool emailsInProgress = false}) {
    showDialog(
      context: context,
      barrierDismissible: !emailsInProgress, // Prevent closing if emails are being sent
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => !emailsInProgress, // Prevent back button if emails are being sent
          child: AlertDialog(
            title: Text(emailsInProgress ? "Processing" : "Success"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("News added successfully!"),
                  if (emailsInProgress) ...[
                    SizedBox(height: 16),
                    Text(
                      "Sending email notifications...",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _emailTotal > 0 ? _emailSent / _emailTotal : 0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "$_emailSent of $_emailTotal emails sent" + 
                      (_emailFailed > 0 ? " ($_emailFailed failed)" : ""),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (!emailsInProgress)
                TextButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => ManageNewsPage()), 
                    );
                  },
                )
              else
                TextButton(
                  child: const Text("Continue in background"),
                  onPressed: () {
                    // Stop checking progress when user continues in background
                    _cancelProgressCheck();
                    
                    Navigator.of(context).pop(); // Close the dialog
                    // Show a brief message about background processing
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Emails are being sent in the background.'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                    
                    // Navigate away
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => ManageNewsPage()),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Cancel the progress checking timer
  void _cancelProgressCheck() {
    _progressCheckTimer?.cancel();
    _progressCheckTimer = null;
    _isCheckingProgress = false;
  }

  Future<void> _checkEmailProgress() async {
    if (_referenceId == null || !_isCheckingProgress || !mounted) return;

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}admin/check_email_progress.php?reference_id=$_referenceId'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        final result = json.decode(response.body);
        
        if (result['success'] && mounted) {
          setState(() {
            // Explicitly parse string values to integers to avoid type errors
            _emailTotal = int.tryParse(result['total'].toString()) ?? 0;
            _emailSent = int.tryParse(result['sent'].toString()) ?? 0;
            _emailFailed = int.tryParse(result['failed'].toString()) ?? 0;
            _emailProgress = int.tryParse(result['progress'].toString()) ?? 0;
            _emailStatus = result['status'] ?? '';
          });
          
          // Update the dialog if it's open and we're still mounted
          if (_isCheckingProgress && mounted) {
            // Only rebuild dialog if it's not completed to avoid flickering
            if (_emailStatus != 'completed') {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop(); // Close current dialog
                _showSuccessDialog(context, emailsInProgress: true);
              }
            } else {
              // Cancel the timer when completed
              _cancelProgressCheck();
              
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop(); // Close current dialog
                _showSuccessDialog(context, emailsInProgress: false);
              }
            }
          }
          
          // Continue polling if not completed and still checking
          if (_emailStatus != 'completed' && _isCheckingProgress && mounted) {
            // Use a timer instead of direct recursion for better control
            _progressCheckTimer?.cancel();
            _progressCheckTimer = Timer(Duration(seconds: 2), _checkEmailProgress);
          }
        }
      }
    } catch (e) {
      print("Error checking progress: $e");
      // Continue polling even if there's an error, but only if we're still mounted
      if (_isCheckingProgress && mounted) {
        _progressCheckTimer?.cancel();
        _progressCheckTimer = Timer(Duration(seconds: 3), _checkEmailProgress);
      }
    }
  }

  // Create a separate function for the HTTP request with retry capability
  Future<Map<String, dynamic>> _submitNewsRequest(String confId) async {
    // Prepare request data
    final requestData = {
      'news_title': _titleController.text,
      'news_content': _contentController.text,
      'conf_id': confId,
      'send_email': _sendEmail ? '1' : '0',
    };
    
    // Set a longer timeout for the initial request - especially important when sending emails
    const timeoutDuration = Duration(seconds: 120); // Increase to 2 minutes
    bool hasTimeoutOccurred = false;
    Map<String, dynamic>? resultData;
    
    // Try up to 2 times with increasing timeout
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        // If we already have a successful result, don't try again
        if (resultData != null) {
          return resultData;
        }
        
        // Show extended timeout message on second attempt
        if (attempt > 0 && hasTimeoutOccurred && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Still processing... Please wait a moment.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
        
        final response = await http.post(
          Uri.parse('${AppConfig.baseUrl}admin/add_news.php'),
          body: requestData,
        ).timeout(timeoutDuration);
        
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          return data;
        } else {
          throw Exception('Server error: HTTP ${response.statusCode}');
        }
      } on TimeoutException catch (e) {
        print('Timeout on attempt ${attempt + 1}: $e');
        hasTimeoutOccurred = true;
        
        // On first timeout, try making a request to check if news was created
        if (attempt == 0 && _sendEmail) {
          try {
            // Check if news was actually added despite the timeout
            final checkResponse = await http.get(
              Uri.parse('${AppConfig.baseUrl}admin/get_latest_news.php?conf_id=$confId'),
            ).timeout(Duration(seconds: 10));
            
            if (checkResponse.statusCode == 200) {
              final checkResult = json.decode(checkResponse.body);
              // If we find a news item with our title, assume it was successfully added
              if (checkResult.containsKey('news') && 
                  checkResult['news'].containsKey('news_title') && 
                  checkResult['news']['news_title'] == _titleController.text) {
                
                // Construct a success response
                final Map<String, dynamic> successData = {
                  'success': true,
                  'message': 'News added successfully.',
                  'reference_id': 'unknown_${DateTime.now().millisecondsSinceEpoch}',
                  'total_recipients': '0' // Default value
                };
                
                resultData = successData;
                return resultData;
              }
            }
          } catch (checkError) {
            print('Error checking news status: $checkError');
            // Continue with normal retry flow if check fails
          }
        }
        
        // If this is the last attempt and no success, throw the exception
        if (attempt == 1) throw e;
        
        // Otherwise, wait a bit before retrying
        await Future.delayed(Duration(seconds: 5));
      }
    }
    
    // If we get here, all attempts failed
    throw TimeoutException('All request attempts timed out');
  }

  Future<void> _submitNews() async {
    // Reset previous errors
    if (!mounted) return;
    
    setState(() {
      _titleError = null;
      _contentError = null;
    });
    
    // Validate fields manually
    bool isValid = true;
    
    if (_titleController.text.isEmpty) {
      if (!mounted) return;
      setState(() {
        _titleError = 'Please enter a title';
        isValid = false;
      });
      _scrollToField(_titleFocusNode);
      return;
    }
    
    if (_contentController.text.isEmpty) {
      if (!mounted) return;
      setState(() {
        _contentError = 'Please enter content';
        isValid = false;
      });
      _scrollToField(_contentFocusNode);
      return;
    }
    
    if (!isValid) {
      return;
    }

    // Show confirmation dialog
    bool? proceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Submission'),
          content: const Text('Are you sure you want to submit this news?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (proceed ?? false) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = true;
      });
      
      String? confId = await ConferenceState.getSelectedConferenceId();
      if (confId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Conference ID not found')),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      try {
        // Show a loading indicator while submitting
        if (_sendEmail && mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Submitting"),
                content: Row(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                    SizedBox(width: 16),
                    Text("Posting news...")
                  ],
                ),
              );
            },
          );
        }

        // Use the separate request function with retry capability
        final result = await _submitNewsRequest(confId);

        // Close the loading dialog if it's open
        if (_sendEmail && mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        if (!mounted) return;
        
        if (result['success']) {
          // If sending emails, get the reference ID and start progress checking
          if (_sendEmail && result.containsKey('reference_id')) {
            setState(() {
              _referenceId = result['reference_id'];
              _isCheckingProgress = true;
              _emailTotal = int.tryParse(result['total_recipients'].toString()) ?? 0;
            });
            
            // Show dialog with progress indicator
            _showSuccessDialog(context, emailsInProgress: true);
            
            // Start checking progress
            _checkEmailProgress();
          } else {
            // Normal success dialog
            _showSuccessDialog(context);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${result['message']}')),
          );
        }
      } catch (e) {
        print('Exception occurred: $e');
        
        // Close the loading dialog if it's open
        if (_sendEmail && mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        if (!mounted) return;
        
        if (e is TimeoutException) {
          // If it's a timeout but we're sending emails, the server might still be processing
          // Check if we should show a success message anyway
          if (_sendEmail) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Posting news timed out, but the server may still be processing. Check the news page for confirmation.'),
                duration: Duration(seconds: 8),
              ),
            );
            // Navigate to the news page anyway
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ManageNewsPage()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Request timed out. Please try again.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connection error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  void _scrollToField(FocusNode focusNode) {
    focusNode.requestFocus();
    final RenderObject? renderObject = focusNode.context?.findRenderObject();
    if (renderObject != null) {
      _scrollController.animateTo(
        _scrollController.position.pixels + renderObject.getTransformTo(null).getTranslation().y - 100,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add News', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFFffc107),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.post_add, color: Color(0xFFcc9600), size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Create News Article',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFcc9600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Title Section
                  _buildSectionTitle('News Title'),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFFffe082)),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      focusNode: _titleFocusNode,
                      controller: _titleController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter a descriptive title',
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      ),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  if (_titleError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0, left: 8.0),
                      child: Text(
                        _titleError!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  
                  // Email Options
                  _buildSectionTitle('Email Options'),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Color(0xFFffa000).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFffe082)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.email, color: Color(0xFFcc9600)),
                            SizedBox(width: 8),
                            Text(
                              'Send out news as email?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFcc9600),
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: _sendEmail,
                              onChanged: (bool? value) {
                                setState(() {
                                  _sendEmail = value ?? false;
                                });
                              },
                              activeColor: Color(0xFFffc107),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This feature sends emails to all registered users. You will see a progress indicator during the process and can continue to use the application while emails are being sent. For many recipients, this may take some time.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color.fromARGB(255, 82, 82, 82),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Content Section
                  _buildSectionTitle('Content'),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFFffe082)),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      focusNode: _contentFocusNode,
                      controller: _contentController,
                      maxLines: 12,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter news content',
                        contentPadding: EdgeInsets.all(12),
                      ),
                      style: TextStyle(fontSize: 16, height: 1.4),
                    ),
                  ),
                  if (_contentError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0, left: 8.0),
                      child: Text(
                        _contentError!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: Row(
                      children: [
                        Icon(
                          _wordCount > 800 ? Icons.warning : Icons.format_list_numbered,
                          size: 16,
                          color: _wordCount > 800 ? Colors.red : Color(0xFFcc9600),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Word count: $_wordCount/800',
                          style: TextStyle(
                            color: _wordCount > 800 ? Colors.red : Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Submit Button
                  Container(
                    padding: EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.shade200, width: 2)),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitNews,
                      icon: _isSubmitting 
                          ? SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            ) 
                          : Icon(Icons.send, size: 20),
                      label: Text(
                        _isSubmitting ? 'Publishing...' : 'Publish News',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFffc107),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: Size(double.infinity, 54),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFcc9600),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: Color(0xFFffe082),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Cancel any ongoing timer to prevent setState after dispose
    _cancelProgressCheck();
    
    _titleController.dispose();
    _contentController.dispose();
    _scrollController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }
}
