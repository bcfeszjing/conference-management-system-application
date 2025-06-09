import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:CMSapplication/User/paperReviewRubrics2.dart';
import '../config/app_config.dart';

class PaperReviewRubrics1 extends StatefulWidget {
  final String reviewId;
  final String paperId;

  const PaperReviewRubrics1({
    Key? key,
    required this.reviewId,
    required this.paperId,
  }) : super(key: key);

  @override
  _PaperReviewRubrics1State createState() => _PaperReviewRubrics1State();
}

class _PaperReviewRubrics1State extends State<PaperReviewRubrics1> {
  List<dynamic> rubrics = [];
  bool isLoading = true;
  Map<int, int> selectedMarks = {};
  Map<int, TextEditingController> remarkControllers = {};
  Map<int, GlobalKey> rubricKeys = {};
  final ScrollController _scrollController = ScrollController();
  double totalMarks = 0;
  bool _formSubmitted = false; // Track whether the form has been submitted

  @override
  void initState() {
    super.initState();
    fetchRubrics();
  }

  @override
  void dispose() {
    remarkControllers.values.forEach((controller) => controller.dispose());
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchRubrics() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}user/get_reviewPaperRubrics1.php'),
      );

      if (response.statusCode == 200) {
        setState(() {
          rubrics = json.decode(response.body);
          // Initialize controllers and keys for each rubric
          for (var rubric in rubrics) {
            final rubricId = int.parse(rubric['rubric_id'].toString());
            remarkControllers[rubricId] = TextEditingController();
            rubricKeys[rubricId] = GlobalKey();
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching rubrics: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Calculate the total marks based on the selected values
  double calculateTotalMarks() {
    if (rubrics.isEmpty) return 0;
    
    int sum = 0;
    for (var rubric in rubrics) {
      final rubricId = int.parse(rubric['rubric_id'].toString());
      if (selectedMarks.containsKey(rubricId)) {
        sum += selectedMarks[rubricId]!;
      }
    }
    
    // Formula: (sum / (5 * number of rubrics)) * 100, rounded to integer
    return ((sum / (5 * rubrics.length)) * 100).roundToDouble();
  }

  // Add a method to find and scroll to the first error
  void _scrollToFirstError() {
    // Use post-frame callback to ensure the UI is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Find the first rubric with an error
      for (var rubric in rubrics) {
        final rubricId = int.parse(rubric['rubric_id'].toString());
        bool hasError = selectedMarks[rubricId] == null || 
                       remarkControllers[rubricId]!.text.trim().isEmpty;
        
        if (hasError && rubricKeys[rubricId]?.currentContext != null) {
          // Use the Scrollable widget to scroll to the error
          Scrollable.ensureVisible(
            rubricKeys[rubricId]!.currentContext!,
            duration: const Duration(milliseconds: 500),
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
            curve: Curves.easeInOut,
          );
          break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Rubrics'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        color: Colors.grey[50],
        child: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue),
                  SizedBox(height: 16),
                  Text(
                    'Loading rubrics...',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                    )
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section with instructions
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[700],
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Evaluation Instructions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            'For each rubric, please select a mark from 1 to 5 (5 being the highest) and provide detailed feedback.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[800],
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'All rubrics must be completed to proceed.',
                            style: TextStyle(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Rubrics title
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 8.0),
                    child: Text(
                      'Evaluation Rubrics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  
                  // Rubrics list
                  ...List.generate(
                    rubrics.length,
                    (index) => _buildRubricBox(rubrics[index], index),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Current marks card - moved to after rubrics list
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.score, size: 24, color: Colors.blue),
                              SizedBox(width: 12),
                              Text(
                                'Total Score:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Text(
                              '${totalMarks.toInt()}/100',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Submit button
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_validateForm()) {
                            _saveRubricMarks();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Next',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildRubricBox(Map<String, dynamic> rubric, int index) {
    final rubricId = int.parse(rubric['rubric_id'].toString());
    final hasMarkError = selectedMarks[rubricId] == null && _formSubmitted;
    final hasRemarkError = remarkControllers[rubricId]!.text.trim().isEmpty && _formSubmitted;
    
    return Container(
      key: rubricKeys[rubricId],
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 1,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: (hasMarkError || hasRemarkError) ? Colors.red.shade300 : Colors.grey.shade200,
            width: (hasMarkError || hasRemarkError) ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rubric number tag and title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Rubric ${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rubric['rubric_text'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              
              Divider(height: 32, color: Colors.grey[200]),
              
              // Rating section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rating (1-5):',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasMarkError ? Colors.red.shade200 : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (i) {
                        final mark = i + 1;
                        final isSelected = selectedMarks[rubricId] == mark;
                        return Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue[50] : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected 
                                ? Border.all(color: Colors.blue)
                                : null,
                          ),
                          child: Column(
                            children: [
                              Radio<int>(
                                value: mark,
                                groupValue: selectedMarks[rubricId],
                                activeColor: Colors.blue,
                                onChanged: (value) {
                                  setState(() {
                                    selectedMarks[rubricId] = value!;
                                    totalMarks = calculateTotalMarks();
                                  });
                                },
                              ),
                              Text(
                                mark.toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.blue : Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  if (hasMarkError) 
                    Padding(
                      padding: EdgeInsets.only(left: 4.0, top: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Please select a rating',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Remarks section
              Text(
                'Your Remarks:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: remarkControllers[rubricId],
                decoration: InputDecoration(
                  hintText: 'Enter your detailed feedback for this rubric...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  errorText: hasRemarkError ? 'Please enter remarks' : null,
                  contentPadding: EdgeInsets.all(16),
                ),
                onChanged: (value) {
                  if (_formSubmitted) {
                    setState(() {});
                  }
                },
                maxLines: 4,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validateForm() {
    // Set form as submitted to show error messages
    setState(() {
      _formSubmitted = true;
    });
    
    // Check each rubric for errors
    bool formIsValid = true;
    for (var rubric in rubrics) {
      final rubricId = int.parse(rubric['rubric_id'].toString());
      
      // Check for mark selection
      if (selectedMarks[rubricId] == null) {
        formIsValid = false;
      }
      
      // Check for remarks
      if (remarkControllers[rubricId]!.text.trim().isEmpty) {
        formIsValid = false;
      }
    }
    
    // If there are errors, scroll to the first error
    if (!formIsValid) {
      _scrollToFirstError();
    }
    
    return formIsValid;
  }

  Future<void> _saveRubricMarks() async {
    try {
      Map<String, dynamic> reviewData = {
        'review_id': widget.reviewId,
        'paper_id': widget.paperId,
        'review_totalmarks': totalMarks.toInt().toString(),
      };

      // Add all rubric marks and remarks starting from index 1
      for (var i = 0; i < rubrics.length; i++) {
        final rubric = rubrics[i];
        final rubricId = int.parse(rubric['rubric_id'].toString());
        final rubricNumber = i + 1; // Start from 1 instead of using rubricId
        
        if (selectedMarks.containsKey(rubricId)) {
          reviewData['rubric_$rubricNumber'] = selectedMarks[rubricId].toString();
          reviewData['rubric_${rubricNumber}_remark'] = remarkControllers[rubricId]!.text;
        }
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}user/add_paperReviewRubrics1.php'),
        body: reviewData,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaperReviewRubrics2(
                reviewId: widget.reviewId,
                paperId: widget.paperId,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Error saving review data')),
          );
        }
      }
    } catch (e) {
      print('Error saving rubric marks: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving review data')),
      );
    }
  }
}
