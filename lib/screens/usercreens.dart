import 'package:flutter/material.dart';
import 'package:app_luyen_de_thpt/providers/auth.dart';
import 'package:app_luyen_de_thpt/providers/test.dart';
import 'package:app_luyen_de_thpt/screens/loginscreens.dart';
import 'package:app_luyen_de_thpt/screens/testscreens.dart';
import 'package:app_luyen_de_thpt/utils/Colors.dart';
import 'package:app_luyen_de_thpt/utils/textstyle.dart';
import 'package:app_luyen_de_thpt/widget/drawerwidget.dart';
import 'package:app_luyen_de_thpt/widget/infortestwidget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ionicons/ionicons.dart';
import 'package:nb_utils/nb_utils.dart';

class UserScreen extends StatefulWidget {
  final AppUser user;
  const UserScreen({super.key, required this.user});

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TestService _quizService = TestService();

  List<Test> tests = [];
  Map<String, List<Test>> testsBySubject = {};
  bool _isLoading = true;

  String? _selectedSubject;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _loadTests();
  }

  void _checkAuthStatus() {
    if (_auth.currentUser == null) {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _loadTests() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final data = await _quizService.getAllTests();

      testsBySubject = {};
      for (var test in data) {
        String subject = test.subject ?? 'Không xác định';

        if (!testsBySubject.containsKey(subject)) {
          testsBySubject[subject] = [];
        }
        testsBySubject[subject]!.add(test);
      }

      setState(() {
        tests = data;
        _isLoading = false;
      });

      // Create a list of subjects
      List<String> subjects = testsBySubject.keys.toList();
      print(subjects); // Print the list of subjects (can be displayed in UI)
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải danh sách đề thi: $e')),
      );
    }
  }

  void _signOut() async {
    await _auth.signOut();
    _navigateToLogin();
  }

  void _selectSubject(String subject) {
    setState(() {
      _selectedSubject = subject;
    });
  }

  void _startTest(Test quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestScreen(
          test: quiz,
          user: widget.user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Hi ${widget.user.realname}', style: textsimplewhitebigger),
        backgroundColor: mainColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTests,
          ),
        ],
      ),
      drawer: Mydrawer(
        onSignoutTap: _signOut,
        onCreateTap: () {},
        user: widget.user,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: backgroundColor,
              child: Column(
                children: [
                  16.height,
                  SizedBox(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(), // Tắt cuộn riêng cho GridView
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // 3 cột
                        childAspectRatio:
                            2, // Tỉ lệ giữa chiều rộng và chiều cao
                        crossAxisSpacing: 4, // Khoảng cách ngang
                        mainAxisSpacing: 4, // Khoảng cách dọc
                      ),
                      itemCount: testsBySubject.keys.length,
                      itemBuilder: (context, index) {
                        String subject = testsBySubject.keys.elementAt(index);
                        return GestureDetector(
                          onTap: () => _selectSubject(subject),
                          child: Card(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getIconForSubject(subject),
                                  size: 20, // Kích thước icon nhỏ lại
                                  color: mainColor,
                                ),
                                Text(
                                  subject,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  16.height,
                  _selectedSubject == null
                      ? const Center(
                          child: Text(
                            'Chọn môn học để hiển thị danh sách đề thi',
                            style: TextStyle(fontSize: 14),
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: testsBySubject[_selectedSubject]!.length,
                            itemBuilder: (context, index) {
                              final test =
                                  testsBySubject[_selectedSubject]![index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 4.0),
                                child: ListTile(
                                  title: Text(
                                    test.title,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    '${test.questions.length} câu hỏi',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.play_arrow),
                                    onPressed: () => _startTest(test),
                                  ),
                                  onTap: () => Infortest.show(
                                      context, test, widget.user),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  IconData _getIconForSubject(String subject) {
    switch (subject) {
      case 'Tiếng Anh':
        return Icons.language;
      case 'Toán Học':
        return Icons.calculate;
      case 'Vật Lý':
        return Ionicons.flash;
      case 'Tin Học':
        return Icons.computer;
      case 'Hóa Học':
        return Ionicons.flask;
      case 'Lịch sử':
        return Icons.history;
      case 'Sinh Học':
        return Icons.biotech;
      case 'Địa Lý':
        return Icons.public;
      case 'Công Nghệ':
        return Icons.build;
      case 'Kinh Tế Pháp Luật':
        return Icons.balance;
      default:
        return Icons.subject;
    }
  }
}
