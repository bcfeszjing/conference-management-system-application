import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:CMSapplication/Admin/manageNewsPage.dart';

class EditNews extends StatefulWidget {
  final String newsId;
  
  const EditNews({Key? key, required this.newsId}) : super(key: key);

  @override
  _EditNewsState createState() => _EditNewsState();
}

class _EditNewsState extends State<EditNews> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _scrollController = ScrollController();
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();
  bool _isLoading = true;
  int _wordCount = 0;
  String? _titleError;
  String? _contentError;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_updateWordCount);
    _fetchNewsDetails();
  }

  void _updateWordCount() {
    setState(() {
      _wordCount = _contentController.text.split(' ').where((word) => word.isNotEmpty).length;
    });
  }

  Future<void> _fetchNewsDetails() async {
    try {
      final response = await http.get(
        Uri.parse('https://cmsa.digital/admin/edit_news.php?news_id=${widget.newsId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _titleController.text = data['news_title'];
          _contentController.text = data['news_content'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching news details: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteNews() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this news?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final response = await http.post(
        Uri.parse('https://cmsa.digital/admin/delete_news.php'),
        body: {'news_id': widget.newsId},
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ManageNewsPage()),
        );
      }
    }
  }

  Future<void> _saveNews() async {
    // Reset previous errors
    setState(() {
      _titleError = null;
      _contentError = null;
    });
    
    // Validate fields manually
    bool isValid = true;
    
    if (_titleController.text.isEmpty) {
      setState(() {
        _titleError = 'Please enter a title';
        isValid = false;
      });
      _scrollToField(_titleFocusNode);
      return;
    }
    
    if (_contentController.text.isEmpty) {
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

    final response = await http.post(
      Uri.parse('https://cmsa.digital/admin/edit_news.php'),
      body: {
        'news_id': widget.newsId,
        'news_title': _titleController.text,
        'news_content': _contentController.text,
      },
    );

    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ManageNewsPage()),
      );
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit News'),
          backgroundColor: Color(0xFFffc107),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffc107)),
          )
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit News', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        Icon(Icons.edit, color: Color(0xFFcc9600), size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Edit News Article',
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
                  
                  // Action Buttons
                  Container(
                    padding: EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.shade200, width: 2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _saveNews,
                          icon: Icon(Icons.save, size: 20),
                          label: Text(
                            'Save Changes',
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
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _deleteNews,
                          icon: Icon(Icons.delete, size: 20, color: Colors.white),
                          label: Text(
                            'Delete News',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
    _titleController.dispose();
    _contentController.dispose();
    _scrollController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }
}
