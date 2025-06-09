import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../config/app_config.dart';

class ShowNewsDetails extends StatefulWidget {
  final String newsId;

  const ShowNewsDetails({Key? key, required this.newsId}) : super(key: key);

  @override
  State<ShowNewsDetails> createState() => _ShowNewsDetailsState();
}

class _ShowNewsDetailsState extends State<ShowNewsDetails> {
  bool _isLoading = true;
  Map<String, dynamic>? _newsDetails;

  @override
  void initState() {
    super.initState();
    _fetchNewsDetails();
  }

  Future<void> _fetchNewsDetails() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}user/get_userNewsDetails.php?news_id=${widget.newsId}'),
      );

      final data = json.decode(response.body);
      
      if (data['status'] == 'success') {
        setState(() {
          _newsDetails = data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = '';
    if (_newsDetails?['news_date'] != null) {
      final date = DateTime.parse(_newsDetails!['news_date']);
      formattedDate = DateFormat('MMMM dd, yyyy').format(date);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            _newsDetails?['news_title'] ?? '',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _newsDetails?['news_content'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.8,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
