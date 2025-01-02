
import 'package:app_luyen_de_thpt/providers/auth.dart';
import 'package:app_luyen_de_thpt/screens/loginscreens.dart';
import 'package:app_luyen_de_thpt/utils/textstyle.dart';
import 'package:app_luyen_de_thpt/widget/drawerwidget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_luyen_de_thpt/providers/test.dart';
import 'package:app_luyen_de_thpt/utils/Colors.dart';
import 'package:nb_utils/nb_utils.dart';

class TestResultsUserScreen extends StatefulWidget {
  final AppUser user;
  final String userId;

  const TestResultsUserScreen(
      {Key? key, required this.user, required this.userId})
      : super(key: key);

  @override
  _TestResultsUserScreenState createState() => _TestResultsUserScreenState();
}

class _TestResultsUserScreenState extends State<TestResultsUserScreen> {
  late Future<List<TestResult>> futureResults;
  final _testService = TestService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    futureResults = _testService.getTestResultsForUser(widget.userId);
  }

  String _formatTimestamp(DateTime timestamp) {
    return "${timestamp.day}/${timestamp.month}/${timestamp.year} - ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  void _signOut() async {
    await _auth.signOut();
    _navigateToLogin();
  }

  Widget _buildResultCard(TestResult result) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: mainColor,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  icon: Icons.check_circle,
                  label: 'Đúng',
                  value: result.correctAnswers.toString(),
                  color: Colors.green,
                ),
                _buildStatItem(
                  icon: Icons.cancel,
                  label: 'Sai',
                  value: result.incorrectAnswers.toString(),
                  color: Colors.red,
                ),
                _buildStatItem(
                  icon: Icons.star,
                  label: 'Điểm',
                  value: result.score.toString(),
                  color: Colors.orange,
                ),
              ],
            ),
            10.height,
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  _formatTimestamp(result.timestamp),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          'My result',
          style: textsimplewhitebigger,
        ),
        backgroundColor: mainColor,
        elevation: 0,
      ),
      drawer: Mydrawer(
        onSignoutTap: _signOut,
        onCreateTap: () {},
        user: widget.user,
      ),
      body: Container(
        color: backgroundColor,
        child: FutureBuilder<List<TestResult>>(
          future: futureResults,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: mainColor),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      'Không thể tải kết quả',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.document_scanner_outlined,
                        color: Colors.grey, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có kết quả bài kiểm tra',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            // Results List
            final testResults = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              itemCount: testResults.length,
              itemBuilder: (context, index) {
                final result = testResults[index];
                return _buildResultCard(result);
              },
            );
          },
        ),
      ),
    );
  }
}
