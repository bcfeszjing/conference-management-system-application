import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaperReviewRubric extends StatefulWidget {
  final String reviewId;
  final String reviewerName;

  const PaperReviewRubric({
    Key? key, 
    required this.reviewId,
    required this.reviewerName,
  }) : super(key: key);

  @override
  _PaperReviewRubricState createState() => _PaperReviewRubricState();
}

class _PaperReviewRubricState extends State<PaperReviewRubric> {
  Map<String, dynamic>? rubricData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRubricData();
  }

  Future<void> fetchRubricData() async {
    try {
      final response = await http.get(
        Uri.parse('https://cmsa.digital/admin/get_paperReviewRubric.php?review_id=${widget.reviewId.toString()}'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          setState(() {
            rubricData = jsonResponse['data'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching rubric data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Review Rubric', style: TextStyle(fontWeight: FontWeight.bold)),
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Review Rubric', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFFffc107),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with reviewer name
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFffa000).withOpacity(0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Evaluation by',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.reviewerName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Rubrics section title
              _buildSectionTitle('Review Rubrics'),
              
              // Total score indicator
              Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFffebc0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFffb74d), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Color(0xFFcc9600), size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Total Score:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF757575),
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFFffc107),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        rubricData?['review_totalmarks'] ?? '0',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Column header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFffc107).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFffc107).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Criteria',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                    Text(
                      'Score (1-5)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Rubrics list
              ...buildRubricsList(),
              
              SizedBox(height: 24),
              
              // Remarks section
              _buildSectionTitle('Reviewer Comments'),
              
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Color(0xFFe0e0e0)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCommentField(
                        'Remarks to Author:',
                        rubricData?['reviewer_remarks'] ?? 'No remarks provided.',
                      ),
                      SizedBox(height: 16),
                      Divider(),
                      SizedBox(height: 16),
                      _buildCommentField(
                        'Remarks to Organizer:',
                        rubricData?['review_confremarks'] ?? 'No remarks provided.',
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
            ],
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentField(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF757575),
          ),
        ),
        SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: Color(0xFF424242),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  List<Widget> buildRubricsList() {
    List<Widget> widgets = [];
    final rubrics = rubricData?['rubrics'] as List? ?? [];

    for (var i = 0; i < rubrics.length; i++) {
      final rubric = rubrics[i];
      widgets.addAll([
        Card(
          elevation: 0,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Color(0xFFe0e0e0)),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rubric['rubric_text'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        rubric['rubric_${i + 1}_remark'] ?? '',
                        style: TextStyle(
                          color: Color(0xFF757575),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _getScoreColor(int.tryParse(rubric['rubric_${i + 1}']?.toString() ?? '0') ?? 0),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    (rubric['rubric_${i + 1}'] ?? '0').toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]);
    }
    return widgets;
  }
  
  Color _getScoreColor(int score) {
    if (score >= 4) return Colors.green;
    if (score >= 3) return Color(0xFFffc107);
    if (score >= 2) return Colors.orange;
    return Colors.red;
  }
}
