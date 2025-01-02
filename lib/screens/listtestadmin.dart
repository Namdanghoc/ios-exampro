import 'package:app_luyen_de_thpt/providers/auth.dart';
import 'package:app_luyen_de_thpt/providers/test.dart';

import 'package:app_luyen_de_thpt/screens/loginscreens.dart';
import 'package:app_luyen_de_thpt/screens/testscreens.dart';
import 'package:app_luyen_de_thpt/utils/Colors.dart';
import 'package:app_luyen_de_thpt/utils/textstyle.dart';
import 'package:app_luyen_de_thpt/widget/infortestwidget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListTestAdminScreen extends StatefulWidget {
  final AppUser admin;
  const ListTestAdminScreen({super.key, required this.admin});

  @override
  _ListTestAdminScreenState createState() => _ListTestAdminScreenState();
}

class _ListTestAdminScreenState extends State<ListTestAdminScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TestService _quizService = TestService();
  List<Test> tests = [];
  bool _isLoading = true;

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
      final data = await _quizService.getDataTestAdmin(widget.admin.id!);
      setState(() {
        tests = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải danh sách đề thi: $e')),
      );
    }
  }

  Future<void> _deleteTest(String testId) async {
    try {
      await _quizService.deleteTest(testId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa đề thi thành công!')),
      );
      _loadTests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xóa đề thi: $e')),
      );
    }
  }

  void _signOut() async {
    await _auth.signOut();
    _navigateToLogin();
  }

  void _startTest(Test quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestScreen(
          test: quiz,
          user: widget.admin,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('List test created', style: textsimplewhitebigger),
        backgroundColor: mainColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : tests.isEmpty
              ? const Center(child: Text('No have test now !'))
              : Container(
                  color: backgroundColor,
                  child: ListView.builder(
                    itemCount: tests.length,
                    itemBuilder: (context, index) {
                      final quiz = tests[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(
                            maxLines: 5,
                            quiz.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${quiz.questions.length} câu hỏi'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_arrow),
                                onPressed: () => _startTest(quiz),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Xác nhận'),
                                      content: const Text(
                                          'Bạn có chắc chắn muốn xóa đề thi này không?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Hủy'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text('Xóa'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    _deleteTest(quiz.id);
                                  }
                                },
                              ),
                            ],
                          ),
                          onTap: () =>
                              Infortest.show(context, quiz, widget.admin),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
