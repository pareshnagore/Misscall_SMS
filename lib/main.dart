import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:call_log/call_log.dart';

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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.teal,
              ),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: Icon(Icons.sms_outlined),
              title: Text('SMS Sent Log'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/smsLog');
              },
            ),
          ],
        ),
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
// ...existing code...


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
      routes: {
        '/smsLog': (context) => SmsLogPage(),
      },
    );
  }
}

// Secondary screen to show SMS sent log
class SmsLogPage extends StatefulWidget {
  @override
  _SmsLogPageState createState() => _SmsLogPageState();
}

class _SmsLogPageState extends State<SmsLogPage> {
  static const platform = MethodChannel('misscall_sms/sms_log');
  List<Map<String, dynamic>> smsLog = [];
  List<Map<String, dynamic>> missedCalls = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    // Fetch SMS log from platform channel
    String? logJson;
    try {
      logJson = await platform.invokeMethod('getSmsLog');
    } catch (e) {
      logJson = '[]';
    }
    List<dynamic> logList = json.decode(logJson ?? '[]');
    smsLog = logList.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    smsLog.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

    // Fetch missed calls from call_log plugin
    Iterable<CallLogEntry> entries = await CallLog.query(type: CallType.missed);
    // Only unknown numbers (no name)
    missedCalls = entries
        .where((entry) => entry.name == null && entry.number != null)
        .map((entry) => {
              'number': entry.number,
              'timestamp': entry.timestamp,
            })
        .toList();
    missedCalls.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

    setState(() {
      loading = false;
    });
  }

  String formatTimestamp(int? timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SMS Sent Log'),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : missedCalls.isEmpty
              ? Center(child: Text('No missed calls from unknown numbers.'))
              : ListView.builder(
                  itemCount: missedCalls.length,
                  itemBuilder: (context, index) {
                    final call = missedCalls[index]; // already sorted, latest first
                    final smsEntry = smsLog.firstWhere(
                      (log) => log['number'] == call['number'] && log['timestamp'] == call['timestamp'],
                      orElse: () => {},
                    );
                    final status = smsEntry.isNotEmpty ? smsEntry['status'] : 'not sent';
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          status == 'success'
                              ? Icons.check_circle
                              : (status == 'failure' ? Icons.error : Icons.sms_failed),
                          color: status == 'success'
                              ? Colors.green
                              : (status == 'failure' ? Colors.red : Colors.grey),
                        ),
                        title: Text(call['number'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formatTimestamp(call['timestamp'])),
                            if (status == 'success' && smsEntry['sent_time'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'SMS sent at: ${formatTimestamp(smsEntry['sent_time'])}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                              ),
                          ],
                        ),
                        trailing: Text(status ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
    );
  }
}
