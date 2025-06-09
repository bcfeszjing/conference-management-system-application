import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:CMSapplication/services/conference_state.dart';
import '../config/app_config.dart';

class MessageDetails extends StatefulWidget {
  final String messageId;

  MessageDetails({required this.messageId});

  @override
  _MessageDetailsState createState() => _MessageDetailsState();
}

class _MessageDetailsState extends State<MessageDetails> {
  Map<String, dynamic> messageData = {};
  List<dynamic> replies = [];
  bool isLoading = true;
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchMessageDetails();
  }

  Future<void> fetchMessageDetails() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}admin/get_messageDetails.php?message_id=${widget.messageId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            messageData = data['data']['message'];
            replies = data['data']['replies'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching message details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _sendReply() async {
    if (_replyController.text.isEmpty) return;
    
    setState(() {
      isLoading = true;
    });
    
    try {
      final adminEmail = await ConferenceState.getAdminEmail();
      if (adminEmail == null) {
        print('Admin email not found');
        return;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}admin/add_messageReplies.php'),
        body: {
          'message_id': widget.messageId,
          'reply_message': _replyController.text,
          'author_email': adminEmail,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _replyController.clear();
          fetchMessageDetails(); // Refresh the messages
        } else {
          print('Failed to send reply: ${data['message']}');
        }
      }
    } catch (e) {
      print('Error sending reply: $e');
    }
  }

  Future<void> _deleteMessage() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}admin/delete_message.php'),
        body: {
          'message_id': widget.messageId,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Message deleted successfully')),
          );
          Navigator.pop(context, true); // Return to previous screen with refresh flag
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting message: ${data['message']}')),
          );
        }
      } else {
        throw Exception('Failed to delete message');
      }
    } catch (e) {
      print('Error deleting message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting message: $e')),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Message'),
          content: Text('Are you sure you want to delete this message? This will also delete all replies.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMessage();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Message Details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true); // Return true to indicate refresh is needed
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    messageData['message_date'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  messageData['message_title'] ?? '',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16),
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(color: Colors.black, fontSize: 16),
                                    children: [
                                      TextSpan(
                                        text: 'From: ',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: '${messageData['user_name']} (${messageData['user_email']})',
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 24),
                                Text(
                                  messageData['message_content'] ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        ...replies.map((reply) {
                          final bool isAdmin = reply['is_admin'] == 1;
                          return Align(
                            alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.8,
                              ),
                              margin: EdgeInsets.symmetric(vertical: 8),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isAdmin ? Colors.blue[100] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                   reply['user_name'] ?? 'Unknown User',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isAdmin ? Colors.blue[900] : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    reply['reply_message'],
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    reply['reply_date'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      offset: Offset(0, -2),
                      blurRadius: 4,
                      color: Colors.black12,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        decoration: InputDecoration(
                          hintText: 'Type your reply...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        maxLines: null,
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.blue),
                      onPressed: _sendReply,
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}
