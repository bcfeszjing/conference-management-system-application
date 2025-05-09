import 'package:shared_preferences/shared_preferences.dart';

class ConferenceState {
  static const String _conferenceIdKey = 'selected_conference_id';
  static const String _adminEmailKey = 'admin_email';

  // Save conference details
  static Future<void> saveSelectedConference(String confId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_conferenceIdKey, confId);
  }

  // Save admin email
  static Future<void> saveAdminEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminEmailKey, email);
  }

  // Get admin email
  static Future<String?> getAdminEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adminEmailKey);
  }

  // Get conference ID
  static Future<String?> getSelectedConferenceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_conferenceIdKey);
  }

  // Clear all data (use during logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_conferenceIdKey);
    await prefs.remove(_adminEmailKey);
  }

  // Clear only conference selection
  static Future<void> clearSelectedConference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_conferenceIdKey);
  }
} 