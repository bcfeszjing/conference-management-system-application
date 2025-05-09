import 'package:flutter/material.dart';
import 'package:CMSapplication/Admin/manageConferencePage.dart';
import 'package:CMSapplication/Admin/managePapersPage.dart';
import 'package:CMSapplication/Admin/manageNewsPage.dart';
import 'package:CMSapplication/Admin/manageCameraReadyPage.dart';
import 'package:CMSapplication/Admin/managePaymentsPage.dart';
import 'package:CMSapplication/Admin/manageMessagesPage.dart';
import 'package:CMSapplication/Admin/manageUserAccountPage.dart';
import 'package:CMSapplication/main.dart';
import 'package:CMSapplication/services/conference_state.dart';
import 'package:CMSapplication/Admin/settingConference.dart';
import 'package:CMSapplication/Admin/settingField.dart';
import 'package:CMSapplication/Admin/settingRubricsItem.dart';

class ManageSettingsPage extends StatefulWidget {
  @override
  _ManageSettingsPageState createState() => _ManageSettingsPageState();
}

class _ManageSettingsPageState extends State<ManageSettingsPage> {
  String? selectedConferenceId;
  final Color primaryColor = Color(0xFFFFC107); // Amber primary color
  final Color darkAmber = Color(0xFFFFA000); // Darker amber for contrast
  final Color lightAmber = Color(0xFFFFECB3); // Light amber for backgrounds
  final Color textColor = Color(0xFF5D4037); // Brown text for contrast
  final Color logoutColor = Color(0xFFD32F2F); // Red for logout

  @override
  void initState() {
    super.initState();
    loadSelectedConference();
  }

  Future<void> loadSelectedConference() async {
    final confId = await ConferenceState.getSelectedConferenceId();
    setState(() {
      selectedConferenceId = confId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFFffc107),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        color: Colors.grey[50],
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page header
                Container(
                  margin: EdgeInsets.only(bottom: 24),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.settings,
                          color: primaryColor,
                          size: 22,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'System Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkAmber,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Manage your conference settings and configurations',
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Settings list
                Expanded(
                  child: ListView(
                    children: [
                      _buildSettingButton(
                        title: 'Conference/Journal',
                        subtitle: 'Manage conference and journal settings',
                        icon: Icons.business,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SettingConferencePage()),
                          );
                        },
                      ),
                      _buildSettingButton(
                        title: 'Fields',
                        subtitle: 'Configure research and paper fields',
                        icon: Icons.category,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SettingFieldPage()),
                          );
                        },
                      ),
                      _buildSettingButton(
                        title: 'Rubrics Items',
                        subtitle: 'Set up review criteria and scoring rubrics',
                        icon: Icons.list_alt,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SettingRubricsItemPage()),
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      Divider(
                        color: Colors.grey[300],
                        thickness: 1,
                      ),
                      SizedBox(height: 16),
                      _buildSettingButton(
                        title: 'Logout',
                        subtitle: 'Sign out from the system',
                        icon: Icons.logout,
                        color: logoutColor,
                        onPressed: () async {
                          await ConferenceState.clearSelectedConference();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => MainPage()),
                            (route) => false,
                          );
                        },
                        isLogout: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFffc107),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    selectedConferenceId ?? 'No Conference Selected',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Conference Management System',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.list,
                  title: 'Conf/Journal',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ManageConferencePage()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.newspaper,
                  title: 'News',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ManageNewsPage()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.file_copy,
                  title: 'Papers',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ManagePapersPage()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'User Account',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ManageUserAccountPage()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.camera,
                  title: 'Camera Ready',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ManageCameraReadyPage()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.money,
                  title: 'Payments',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ManagePaymentsPage()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.message,
                  title: 'Messages',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ManageMessagesPage()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  isActive: true,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                Divider(),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () async {
                    await ConferenceState.clearSelectedConference();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => MainPage()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
    bool isActive = false,
  }) {
    return Container(
      color: isActive ? Color(0xFFffc107).withOpacity(0.1) : null,
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? Color(0xFFcc9600) : iconColor ?? Colors.grey[700],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Color(0xFFcc9600) : textColor ?? Colors.black87,
            fontWeight: isActive ? FontWeight.bold : null,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSettingButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    bool isLogout = false,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLogout ? logoutColor.withOpacity(0.2) : primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: isLogout ? Colors.white : Colors.white,
          child: InkWell(
            splashColor: isLogout ? logoutColor.withOpacity(0.1) : primaryColor.withOpacity(0.1),
            highlightColor: isLogout ? logoutColor.withOpacity(0.05) : primaryColor.withOpacity(0.05),
            onTap: onPressed,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Left accent bar
                  Container(
                    width: 4,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isLogout ? logoutColor : primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Icon with circle background
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isLogout ? logoutColor.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: isLogout ? logoutColor : primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isLogout ? logoutColor : darkAmber,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: isLogout ? logoutColor.withOpacity(0.7) : textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow icon
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isLogout ? logoutColor.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: isLogout ? logoutColor : primaryColor,
                        size: 14,
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
}

void main() {
  runApp(MaterialApp(
    theme: ThemeData(
      primaryColor: Color(0xFFFFC107),
      colorScheme: ColorScheme.light(
        primary: Color(0xFFFFC107),
        secondary: Color(0xFFFFD54F),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFFFFA000),
      ),
    ),
    home: ManageSettingsPage(),
  ));
}