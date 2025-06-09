import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

class PaperAddCoauthor extends StatefulWidget {
  final String paperId;

  const PaperAddCoauthor({Key? key, required this.paperId}) : super(key: key);

  @override
  _PaperAddCoauthorState createState() => _PaperAddCoauthorState();
}

class _PaperAddCoauthorState extends State<PaperAddCoauthor> {
  List<dynamic> coauthors = [];
  bool isLoading = true;
  String? error;
  String? message;

  @override
  void initState() {
    super.initState();
    fetchCoauthors();
  }

  Future<void> fetchCoauthors() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}admin/get_paperAddCoauthor.php?paper_id=${widget.paperId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is Map && data.containsKey('message')) {
          String msg = data['message'];
          if (msg.contains('No Co-author/s available')) {
            msg = 'No co-authors found';
          }
          setState(() {
            message = msg;
            isLoading = false;
          });
          return;
        }
        
        if (data is List) {
          setState(() {
            coauthors = data;
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load coauthors');
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _deleteCoauthor(String coauthorId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}admin/delete_paperAddCoauthor.php'),
        body: {
          'coauthor_id': coauthorId,
          'paper_id': widget.paperId,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Co-author deleted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          fetchCoauthors();
        } else {
          throw Exception(result['message'] ?? 'Failed to delete co-author');
        }
      } else {
        throw Exception('Failed to connect to server');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); // Send refresh signal
        return false; // Prevent default back behavior
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Co-Authors', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFffc107),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, true); // Send refresh signal back
            },
          ),
      ),
      body: Container(
        color: Colors.grey[50],
        child: isLoading
            ? Center(child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffc107)),
              ))
            : message != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Color(0xFFffb74d), width: 1.5),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 48,
                                      color: Color(0xFFcc9600),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      message!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF757575),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (message!.contains('not available') && 
                                        !message!.contains('No Co-author')) ...[
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
                        ],
                      ),
                    ),
                  )
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48.0,
                              color: Colors.red,
                            ),
                            SizedBox(height: 16),
                            Text(
                              error!,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.red[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          _buildSectionHeader('Co-Author/s List'),
                          Expanded(
                            child: coauthors.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.people_outline,
                                          size: 48.0,
                                          color: Color(0xFFcc9600),
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No co-authors found',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16.0),
                                    itemCount: coauthors.length,
                                    itemBuilder: (context, index) {
                                      final coauthor = coauthors[index];
                                      return Card(
                                        elevation: 2,
                                        margin: const EdgeInsets.only(bottom: 16.0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12.0),
                                          side: BorderSide(color: Color(0xFFFFE082), width: 1),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Container(
                                                              padding: EdgeInsets.all(8),
                                                              decoration: BoxDecoration(
                                                                color: Color(0xFFfff8e1),
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Icon(
                                                                Icons.person,
                                                                size: 24,
                                                                color: Color(0xFFffa000),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 12),
                                                            Expanded(
                                                              child: Text(
                                                                coauthor['coauthor_name'] ?? '',
                                                                style: const TextStyle(
                                                                  fontSize: 20,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Colors.black87,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 16),
                                                        Divider(color: Color(0xFFFFE082), height: 1, thickness: 1),
                                                        const SizedBox(height: 16),
                                                        Row(
                                                          children: [
                                                            Icon(Icons.email, size: 20, color: Color(0xFFffa000)),
                                                            const SizedBox(width: 12),
                                                            Expanded(
                                                              child: Text(
                                                                coauthor['coauthor_email'] ?? '',
                                                                style: const TextStyle(
                                                                  fontSize: 16,
                                                                  color: Colors.black87,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(width: 16),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: IconButton(
                                                      icon: const Icon(Icons.delete),
                                                      color: Colors.red,
                                                      iconSize: 24,
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (BuildContext context) {
                                                            return AlertDialog(
                                                              title: const Text('Confirm Delete'),
                                                              content: const Text('Are you sure you want to delete this co-author?'),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(16),
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  child: Text('Cancel', 
                                                                    style: TextStyle(color: Colors.grey[700])
                                                                  ),
                                                                  onPressed: () {
                                                                    Navigator.of(context).pop();
                                                                  },
                                                                ),
                                                                TextButton(
                                                                  child: Text(
                                                                    'Delete', 
                                                                    style: TextStyle(
                                                                      color: Colors.red,
                                                                      fontWeight: FontWeight.bold
                                                                    )
                                                                  ),
                                                                  onPressed: () {
                                                                    Navigator.of(context).pop();
                                                                    _deleteCoauthor(coauthor['coauthor_id'].toString());
                                                                  },
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                        ),
                      ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
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
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
