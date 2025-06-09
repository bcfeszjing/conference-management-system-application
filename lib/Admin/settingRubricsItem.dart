import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:CMSapplication/services/conference_state.dart';
import 'package:CMSapplication/Admin/addRubric.dart';
import '../config/app_config.dart'; // Import AppConfig

class SettingRubricsItemPage extends StatefulWidget {
  @override
  _SettingRubricsItemPageState createState() => _SettingRubricsItemPageState();
}

class _SettingRubricsItemPageState extends State<SettingRubricsItemPage> {
  bool isLoading = true;
  List<dynamic> rubrics = [];
  String? selectedConferenceId;

  @override
  void initState() {
    super.initState();
    loadRubrics();
  }

  Future<void> loadRubrics() async {
    selectedConferenceId = await ConferenceState.getSelectedConferenceId();
    if (selectedConferenceId != null) {
      try {
        final response = await http.get(
          Uri.parse('${AppConfig.baseUrl}admin/get_settingRubricsItem.php?conf_id=$selectedConferenceId'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            rubrics = data;
            isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading rubrics: $e');
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> deleteRubric(int rubricId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this rubric?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final response = await http.post(
          Uri.parse('${AppConfig.baseUrl}admin/delete_rubric.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'rubric_id': rubricId}),
        );

        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rubric deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          await loadRubrics();
        } else {
          throw Exception(data['error'] ?? 'Failed to delete rubric');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(0xFFFFC107); // Amber primary color
    final Color accentColor = Color(0xFFFFA000);  // Darker amber for accents
    final Color backgroundColor = Color(0xFFFFF8E1); // Light amber background

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rubrics Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: backgroundColor,
      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: accentColor))
        : rubrics.isEmpty
          ? Center(
              child: Container(
                padding: EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.list_alt_outlined,
                      size: 64,
                      color: primaryColor,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No rubrics available',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please add using the Add Rubric button below',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.brown[600],
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AddRubricDialog(
                              onRubricAdded: () {
                                loadRubrics();
                              },
                            );
                          },
                        );
                      },
                      icon: Icon(Icons.add),
                      label: Text('Add Rubric'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Available Rubrics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              padding: EdgeInsets.all(16),
                              itemCount: rubrics.length,
                              separatorBuilder: (context, index) => Divider(height: 1),
                              itemBuilder: (context, index) {
                                return ListTile(
                                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: primaryColor,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.list_alt,
                                      color: accentColor,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    rubrics[index]['rubric_text'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.brown[800],
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red[400],
                                      size: 24,
                                    ),
                                    onPressed: () => deleteRubric(rubrics[index]['rubric_id'] as int),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: rubrics.isEmpty ? null : FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AddRubricDialog(
                onRubricAdded: () {
                  loadRubrics();
                },
              );
            },
          );
        },
        backgroundColor: primaryColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
