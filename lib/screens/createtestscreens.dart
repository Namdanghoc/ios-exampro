import 'package:app_luyen_de_thpt/providers/auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nb_utils/nb_utils.dart';
import '../providers/test.dart';
import '../screens/loginscreens.dart';
import '../utils/Colors.dart';
import '../utils/textstyle.dart';
import '../widget/createquestionwidget.dart';
import '../widget/drawerwidget.dart';

class QuestionCounterManager {
  static int _counter = 0;

  static void resetCounter() {
    _counter = 0;
  }

  static int getNextNumber() {
    return ++_counter;
  }
} // Biến toàn cục

class QuestionCreationScreen extends StatefulWidget {
  final AppUser admin;

  const QuestionCreationScreen({Key? key, required this.admin})
      : super(key: key);

  @override
  _QuestionCreationScreenState createState() => _QuestionCreationScreenState();
}

class _QuestionCreationScreenState extends State<QuestionCreationScreen> {
  final TextEditingController _quizTitleController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<QuestionController> _questions = [];
  final List<Map<String, dynamic>> _subjects = [
    {'name': 'Toán Học', 'id': 1},
    {'name': 'Tin Học', 'id': 2},
    {'name': 'Hóa Học', 'id': 3},
    {'name': 'Sinh Học', 'id': 4},
    {'name': 'Vật Lý', 'id': 5},
    {'name': 'Tiếng Anh', 'id': 6},
    {'name': 'Lịch sử', 'id': 7},
    {'name': 'Địa Lý', 'id': 8},
    {'name': 'Công nghệ', 'id': 9},
    {'name': 'Kinh Tế Pháp Luật', 'id': 10},
  ];

  String? _selectedSubject;
  List<String> _schools = [];
  String? _selectedSchool;
  bool _isLoadingSchools = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _fetchSchools();
    QuestionCounterManager.resetCounter();
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

  void _reloadPage() {
    setState(() {
      // Thay đổi dữ liệu hoặc làm mới giao diện ở đây
      QuestionCounterManager.resetCounter();
    });
  }

  Future<void> _fetchSchools() async {
    try {
      final schoolSnapshot = await _firestore.collection('school').get();
      final userSnapshot = await _firestore.collection('users').get();

      final schoolNames =
          schoolSnapshot.docs.map((doc) => doc['nameschool'] as String).toSet();
      final userSchoolNames = userSnapshot.docs
          .map((doc) => doc['namehighschool'] as String)
          .toSet();

      setState(() {
        _schools = [
          'Tất cả trường',
          ...schoolNames.union(userSchoolNames).toList()
        ];
        _selectedSchool = 'Tất cả trường';
        _isLoadingSchools = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSchools = false;
      });
      _showSnackBar('Lỗi tải danh sách trường: ${e.toString()}');
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(QuestionController());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
      QuestionCounterManager.resetCounter();
      for (var question in _questions) {
        question.number = QuestionCounterManager.getNextNumber();
      }
    });
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void hideLoadingDialog(BuildContext context) {
    Navigator.pop(context);
  }

  Future<void> _createTest() async {
    final quizTitle = _quizTitleController.text.trim();

    if (_selectedSubject == null) {
      _showSnackBar('Vui lòng chọn môn học trước khi tạo đề thi.');
      return;
    }

    if (quizTitle.isEmpty) {
      _showSnackBar('Vui lòng nhập mã đề thi.');
      return;
    }

    try {
      // Hiển thị màn hình tải
      showLoadingDialog(context);

      final existingQuizzes = await FirebaseFirestore.instance
          .collection('dethi')
          .where('title', isEqualTo: quizTitle)
          .get();

      if (existingQuizzes.docs.isNotEmpty) {
        hideLoadingDialog(context);
        _showSnackBar(
            'Tiêu đề "$quizTitle" đã tồn tại. Vui lòng chọn tiêu đề khác.');
        return;
      }

      final isValid = _questions.every((q) {
        if (q.titleController.text.trim().isEmpty) return false;

        switch (q.questionType) {
          case 'Chọn câu đúng':
            return q.subAnswers
                        .where((a) => a.textController.text.trim().isNotEmpty)
                        .length ==
                    4 &&
                q.subAnswers.where((a) => a.isCorrect).length == 1;

          case '4 câu đúng/sai':
            return q.subAnswers
                        .where((a) => a.textController.text.trim().isNotEmpty)
                        .length ==
                    4 &&
                q.subAnswers.where((a) => a.isCorrect).isNotEmpty;

          case 'Đúng/Sai':
            return q.subAnswers.where((a) => a.isCorrect).length == 1;

          case 'Trắc nghiệm ngắn':
            return q.subAnswers[0].textController.text.trim().isNotEmpty;

          default:
            return false;
        }
      });

      if (!isValid) {
        hideLoadingDialog(context);
        _showSnackBar('Vui lòng điền đầy đủ thông tin cho tất cả câu hỏi.');
        return;
      }

      final questions = _questions.map((q) {
        List<Answer> answers = [];

        switch (q.questionType) {
          case 'Chọn câu đúng':
          case '4 câu đúng/sai':
          case 'Đúng/Sai':
            answers = q.subAnswers
                .where((a) => a.textController.text.trim().isNotEmpty)
                .map((a) {
              return Answer(
                text: a.textController.text.trim(),
                isCorrect: a.isCorrect,
              );
            }).toList();
            break;

          case 'Trắc nghiệm ngắn':
            answers = [
              Answer(
                text: q.subAnswers[0].textController.text.trim(),
                isCorrect: true,
              )
            ];
            break;
        }

        return Question(
            id: '',
            title: q.titleController.text.trim(),
            questionType: q.questionType,
            imgUrl: q.imageUrl,
            answers: answers,
            tutorial: q.tutorialController.text.trim(),
            number: q.number);
      }).toList();

      final subject = _subjects
          .firstWhere((subject) => subject['name'] == _selectedSubject);

      final quiz = Test(
        id: '',
        title: quizTitle,
        subject: subject['name'],
        subjectId: subject['id'],
        author: widget.admin.realname ?? '',
        idAthor: widget.admin.id!,
        school: _selectedSchool == 'Tất cả trường'
            ? widget.admin.namehighschool
            : _selectedSchool ?? '',
        questions: questions,
      );

      final quizService = TestService();
      final createdQuiz = await quizService.createTest(quiz, widget.admin.id!);

      hideLoadingDialog(context);

      if (createdQuiz != null) {
        _showSnackBar('Tạo đề thi thành công!');
        _clearForm();
      } else {
        _showSnackBar('Lỗi khi tạo đề thi. Vui lòng thử lại.');
      }
    } catch (e) {
      hideLoadingDialog(context);
      _showSnackBar('Lỗi xảy ra khi tạo đề thi: ${e.toString()}');
    }
  }

  void _clearForm() {
    setState(() {
      _quizTitleController.clear();
      _selectedSubject = null;
      _questions.clear();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Create new test', style: textsimplewhitebigger),
        centerTitle: true,
        backgroundColor: mainColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _createTest,
          ),
        ],
      ),
      drawer: Mydrawer(
        onSignoutTap: _navigateToLogin,
        onCreateTap: _reloadPage,
        user: widget.admin,
      ),
      body: Container(
        decoration: BoxDecoration(color: backgroundColor),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _quizTitleController,
                    decoration: InputDecoration(
                      labelText: 'ID Test',
                      prefixIcon: Icon(Icons.numbers, color: Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: mainColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: mainColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: green_darker!, width: 2),
                      ),
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                  20.height,
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: mainColor),
                    ),
                    child: DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedSubject != null
                          ? _subjects.firstWhere(
                              (subject) => subject['name'] == _selectedSubject)
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Môn học',
                        labelStyle: const TextStyle(color: Colors.black),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      isExpanded: true,
                      hint: const Text(
                        'Chọn môn học',
                        style: TextStyle(color: Colors.black54),
                      ),
                      icon: Icon(Icons.school, color: green_darker),
                      items: _subjects.map((subject) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: subject,
                          child: Text(
                            subject['name'],
                            style: const TextStyle(color: Colors.black),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubject = value?['name'];
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _isLoadingSchools
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(mainColor),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: mainColor),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedSchool,
                            decoration: InputDecoration(
                              labelText: 'Trường học',
                              labelStyle: const TextStyle(color: Colors.black),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            isExpanded: true,
                            hint: const Text(
                              'Chọn trường học',
                              style: TextStyle(color: Colors.black54),
                            ),
                            icon: Icon(Icons.business, color: green_darker),
                            items: _schools.map((school) {
                              return DropdownMenuItem<String>(
                                value: school,
                                child: Text(
                                  school,
                                  style: const TextStyle(color: Colors.black),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSchool = value;
                              });
                            },
                          ),
                        ),
                ],
              ),
              20.height,
              ..._questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                return QuestionWidget(
                  idTest: _quizTitleController.text.trim(),
                  controller: question,
                  onDelete: () => _removeQuestion(index),
                );
              }).toList(),
              ElevatedButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(
                  Icons.add,
                  color: mainColor,
                ),
                label: const Text(
                  'Add more question',
                  style: TextStyle(color: mainColor, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
