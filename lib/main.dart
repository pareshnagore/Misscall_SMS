import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MissCallApp());
}

class MissCallApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Missed Call SMS',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Color(0xFFF2F2F2),
      ),
      home: PermissionRequestPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PermissionRequestPage extends StatefulWidget {
  @override
  _PermissionRequestPageState createState() => _PermissionRequestPageState();
}

class _PermissionRequestPageState extends State<PermissionRequestPage> {
  bool permissionsGranted = false;
  TextEditingController smsController = TextEditingController();
  String savedMessage = "I missed your call, will get back soon.";

  @override
  void initState() {
    super.initState();
    loadSavedMessage();
    requestPermissions();
  }

  Future<void> loadSavedMessage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? msg = prefs.getString('sms_text');
    if (msg != null) {
      smsController.text = msg;
      savedMessage = msg;
    } else {
      smsController.text = savedMessage;
    }
  }

  Future<void> saveMessage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('sms_text', smsController.text);
    setState(() {
      savedMessage = smsController.text;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('SMS message saved!')),
    );
  }

  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.sms,
      Permission.contacts,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);
    setState(() {
      permissionsGranted = allGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Missed Call SMS'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: permissionsGranted
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      color: Colors.teal[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.sms, color: Colors.teal, size: 36),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Background SMS service is active',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set your SMS message:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: smsController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                hintText: 'Enter your SMS message',
                              ),
                            ),
                            SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: saveMessage,
                                icon: Icon(Icons.save),
                                label: Text('Save Message'),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Card(
                      color: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current SMS text:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 6),
                            Text(savedMessage),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: ElevatedButton(
                  onPressed: requestPermissions,
                  child: Text('Grant Permissions'),
                ),
              ),
      ),
    );
  }
}
