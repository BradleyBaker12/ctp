import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:ctp/components/custom_app_bar.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/services/notification_service.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({Key? key}) : super(key: key);

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  List<Map<String, dynamic>> users = [];
  String? selectedUserId;
  bool isLoading = false;
  String resultMessage = '';
  bool isSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      setState(() {
        users = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
            'role': data['userRole'] ?? 'unknown',
            'fcmToken': data['fcmToken'],
          };
        }).toList();

        isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _sendTestNotification() async {
    if (selectedUserId == null) {
      setState(() {
        resultMessage = 'Please select a user to send notification to';
        isSuccess = false;
      });
      return;
    }

    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      setState(() {
        resultMessage =
            'Please provide both title and body for the notification';
        isSuccess = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      resultMessage = '';
    });

    try {
      // Get the user's FCM token directly for debugging
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(selectedUserId)
          .get();

      if (!userDoc.exists) {
        setState(() {
          resultMessage = 'Error: User document does not exist';
          isSuccess = false;
          isLoading = false;
        });
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmToken = userData['fcmToken'];

      if (fcmToken == null || fcmToken.toString().isEmpty) {
        setState(() {
          resultMessage = 'Error: User does not have an FCM token registered';
          isSuccess = false;
          isLoading = false;
        });
        return;
      }

      print('DEBUG: Attempting to send notification to token: $fcmToken');

      // Call the Firebase Function with App Check disabled
      final HttpsCallable callable = FirebaseFunctions.instance
          .httpsCallable('sendDirectNotificationNoAppCheck');

      final result = await callable.call({
        'userId': selectedUserId,
        'title': _titleController.text,
        'body': _bodyController.text,
        'dataPayload': {
          'type': 'test',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        }
      });

      print('DEBUG: Function result: ${result.data}');

      // Also trigger a local notification for redundancy
      await NotificationService.showNotification(
        title: _titleController.text,
        body: _bodyController.text,
        payload: 'test_notification',
      );

      setState(() {
        resultMessage =
            'Notification sent via both methods: Firebase Cloud Messaging and local notification.\nCheck your device notifications.\nToken: ${fcmToken.toString().substring(0, 15)}...';
        isSuccess = true;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        resultMessage = 'Error sending notification: ${e.toString()}';
        isSuccess = false;
        isLoading = false;
      });
      print('DEBUG: Error calling function: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUserRole = userProvider.getUserRole;

    // Only allow admin or sales rep to access this page
    if (currentUserRole != 'admin' &&
        currentUserRole != 'sales representative') {
      return Scaffold(
        appBar: CustomAppBar(),
        body: const Center(
          child: Text(
            'Access Denied: Admin privileges required',
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Test Panel',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use this panel to test notifications and diagnose issues',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // User selection dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2F7FFF)),
                borderRadius: BorderRadius.circular(8),
                color: Colors.black45,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: Colors.black87,
                  hint: Text(
                    'Select user to notify',
                    style: GoogleFonts.montserrat(color: Colors.white70),
                  ),
                  value: selectedUserId,
                  onChanged: (String? value) {
                    setState(() {
                      selectedUserId = value;
                    });
                  },
                  items: users.map<DropdownMenuItem<String>>((user) {
                    bool hasToken = user['fcmToken'] != null &&
                        user['fcmToken'].toString().isNotEmpty;

                    return DropdownMenuItem<String>(
                      value: user['id'],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${user['name']} (${user['role']})',
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                          Icon(
                            hasToken ? Icons.check_circle : Icons.error_outline,
                            color: hasToken ? Colors.green : Colors.red,
                            size: 16,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notification title
            TextField(
              controller: _titleController,
              style: GoogleFonts.montserrat(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Notification Title',
                labelStyle: GoogleFonts.montserrat(color: Colors.white70),
                hintText: 'Enter notification title',
                hintStyle: GoogleFonts.montserrat(color: Colors.white30),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2F7FFF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2F7FFF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFFFF4E00), width: 2),
                ),
                filled: true,
                fillColor: Colors.black45,
              ),
            ),
            const SizedBox(height: 16),

            // Notification body
            TextField(
              controller: _bodyController,
              style: GoogleFonts.montserrat(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notification Body',
                labelStyle: GoogleFonts.montserrat(color: Colors.white70),
                hintText: 'Enter notification message',
                hintStyle: GoogleFonts.montserrat(color: Colors.white30),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2F7FFF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2F7FFF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFFFF4E00), width: 2),
                ),
                filled: true,
                fillColor: Colors.black45,
              ),
            ),
            const SizedBox(height: 24),

            // Send button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _sendTestNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F7FFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'SEND TEST NOTIFICATION',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Direct local notification test (bypasses Firebase)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_titleController.text.isEmpty ||
                      _bodyController.text.isEmpty) {
                    setState(() {
                      resultMessage =
                          'Please provide both title and body for the local notification';
                      isSuccess = false;
                    });
                    return;
                  }

                  try {
                    print('DEBUG: Showing direct local notification');
                    await NotificationService.showNotification(
                      title: _titleController.text,
                      body: _bodyController.text,
                      payload: 'local_test',
                    );

                    setState(() {
                      resultMessage =
                          'Local notification triggered. If you don\'t see it, check your device notification settings.';
                      isSuccess = true;
                    });

                    print('DEBUG: Local notification display attempted');
                  } catch (e) {
                    setState(() {
                      resultMessage =
                          'Error showing local notification: ${e.toString()}';
                      isSuccess = false;
                    });
                    print('DEBUG: Error showing local notification: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'TEST LOCAL NOTIFICATION ONLY',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status message
            if (resultMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSuccess
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  border: Border.all(
                    color: isSuccess ? Colors.green : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  resultMessage,
                  style: GoogleFonts.montserrat(
                    color: isSuccess ? Colors.green : Colors.red,
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // FCM Token section for troubleshooting
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.black38,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Troubleshooting',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If notifications are not working:',
                    style: GoogleFonts.montserrat(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Make sure the device has granted notification permissions',
                    style: GoogleFonts.montserrat(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '2. Check that the selected user has a valid FCM token',
                    style: GoogleFonts.montserrat(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '3. Verify that Firebase Cloud Messaging is properly set up',
                    style: GoogleFonts.montserrat(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),

                  // Refresh button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loadUsers,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: Text(
                        'RELOAD USERS',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
