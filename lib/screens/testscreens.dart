import 'package:app_luyen_de_thpt/providers/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:ionicons/ionicons.dart';
import 'package:nb_utils/nb_utils.dart';
import '../components/question_box.dart';
import '../providers/test.dart';
import '../screens/resultscreens.dart';
import '../utils/Colors.dart';
import '../utils/textstyle.dart';

class TestScreen extends StatefulWidget {
  final AppUser user;
  final Test test;

  const TestScreen({Key? key, required this.test, required this.user})
      : super(key: key);

  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late List<Question> _questions;
  int _currentQuestionIndex = 0;

  late List<dynamic> _selectedAnswers;
  late DateTime _startTime;
  List<bool> _answersCorrectness = [];
  late TextEditingController _shortAnswerController;
  late List<bool> _questionCorrectStatus;

  @override
  void initState() {
    super.initState();
    _initializeTest();
    _shortAnswerController = TextEditingController();
  }

  @override
  void dispose() {
    _shortAnswerController.dispose();
    super.dispose();
  }

  void _initializeTest() {
    if (widget.test.questions.isEmpty) {
      _showErrorDialog('Không tìm thấy câu hỏi trong bài kiểm tra này.');
      return;
    }

    _questions = widget.test.questions;
    _selectedAnswers = List.filled(_questions.length, null);
    _answersCorrectness = List.filled(_questions.length, false);
    _questionCorrectStatus = List.filled(_questions.length, false);
    _startTime = DateTime.now();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAnswerFeedbackDialog(bool isCorrect, String? tutorial) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width *
                  0.8, // Chiều ngang chiếm 80% màn hình
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCorrect ? 'Chính xác!' : 'Chưa chính xác',
                    style: TextStyle(
                      color: isCorrect ? Colors.green : Colors.red,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isCorrect) ...[
                    const Text(
                      'Hãy xem hướng dẫn sau:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildTutorialContent(tutorial),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      child: const Text('Tiếp tục'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTutorialContent(String? tutorial) {
    try {
      return TeXView(
        child: TeXViewDocument(
          tutorial ?? 'Không có hướng dẫn cho câu hỏi này.',
          style: const TeXViewStyle(
            padding: TeXViewPadding.all(10),
          ),
        ),
      );
    } catch (e) {
      print('Lỗi hiển thị LaTeX: $e');
      return const Text(
        'Lỗi hiển thị nội dung.',
        style: TextStyle(color: Colors.red),
      );
    }
  }

  Future<void> _submitQuiz() async {
    try {
      final int totalQuestions = _questions.length;
      int correctAnswers =
          _questionCorrectStatus.where((status) => status).length;
      int incorrectAnswers = totalQuestions - correctAnswers;

      print('Final correct answers: $correctAnswers');
      print('Final incorrect answers: $incorrectAnswers');

      if (widget.user.id == null) {
        _showErrorDialog('Thiếu ID người dùng');
        return;
      }

      Duration timeSpent = DateTime.now().difference(_startTime);

      assert(correctAnswers + incorrectAnswers == totalQuestions,
          'Total of correct and incorrect answers should equal total questions');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TestResultScreen(
            totalQuestions: totalQuestions,
            correctAnswers: correctAnswers,
            incorrectAnswers: incorrectAnswers,
            user: widget.user,
            idTest: widget.test.id,
            titleTest: widget.test.title,
          ),
        ),
      );
    } catch (e) {
      print('Error in _submitQuiz: ${e.toString()}');
      _showErrorDialog('Lỗi khi nộp bài: ${e.toString()}');
    }
  }

  bool _checkAnswer(Question question, dynamic selectedAnswer) {
    if (selectedAnswer == null) return false;

    bool isCorrect = false;

    switch (question.questionType) {
      case 'Chọn câu đúng':
        isCorrect =
            selectedAnswer is int && question.answers[selectedAnswer].isCorrect;
        break;

      case '4 câu đúng/sai':
        if (selectedAnswer is List<int>) {
          isCorrect = question.answers.asMap().entries.every((entry) =>
              selectedAnswer.contains(entry.key) == entry.value.isCorrect);
        }
        break;

      case 'Đúng/Sai':
        isCorrect =
            selectedAnswer is int && question.answers[selectedAnswer].isCorrect;
        break;

      case 'Trắc nghiệm ngắn':
        if (selectedAnswer is String) {
          isCorrect = question.answers[0].text.trim().toLowerCase() ==
              selectedAnswer.trim().toLowerCase();
        }
        break;

      default:
        _showErrorDialog(
            'Loại câu hỏi "${question.questionType}" không được hỗ trợ.');
        break;
    }

    // Cập nhật trạng thái đúng/sai cho câu hỏi hiện tại
    _questionCorrectStatus[_currentQuestionIndex] = isCorrect;

    return isCorrect;
  }

  void _moveToNextQuestion() {
    final selectedAnswer = _selectedAnswers[_currentQuestionIndex];
    final currentQuestion = _questions[_currentQuestionIndex];

    if (currentQuestion.questionType == 'Trắc nghiệm ngắn') {
      if (selectedAnswer != null && selectedAnswer.trim().isNotEmpty) {
        final isCorrect = _checkAnswer(currentQuestion, selectedAnswer);
        _showAnswerFeedbackDialog(isCorrect, currentQuestion.tutorial);

        setState(() {
          _selectedAnswers[_currentQuestionIndex] = null;
          if (_currentQuestionIndex < _questions.length - 1) {
            _currentQuestionIndex++;
          } else {
            _submitQuiz();
          }
        });
        return;
      }
    } else {
      if (selectedAnswer != null) {
        final isCorrect = _checkAnswer(currentQuestion, selectedAnswer);
        _showAnswerFeedbackDialog(isCorrect, currentQuestion.tutorial);

        setState(() {
          _selectedAnswers[_currentQuestionIndex] = null;
          if (_currentQuestionIndex < _questions.length - 1) {
            _currentQuestionIndex++;
          } else {
            _submitQuiz();
          }
        });
        return;
      }
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitQuiz();
    }
  }

  void _moveToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      final selectedAnswer = _selectedAnswers[_currentQuestionIndex];
      final currentQuestion = _questions[_currentQuestionIndex];

      if (currentQuestion.questionType == 'Trắc nghiệm ngắn') {
        if (selectedAnswer != null && selectedAnswer.trim().isNotEmpty) {
          final isCorrect = _checkAnswer(currentQuestion, selectedAnswer);
          _showAnswerFeedbackDialog(isCorrect, currentQuestion.tutorial);

          setState(() {
            _selectedAnswers[_currentQuestionIndex] = null;
            _currentQuestionIndex--;
          });
          return;
        }
      } else {
        if (selectedAnswer != null) {
          final isCorrect = _checkAnswer(currentQuestion, selectedAnswer);
          _showAnswerFeedbackDialog(isCorrect, currentQuestion.tutorial);

          setState(() {
            _selectedAnswers[_currentQuestionIndex] = null;
            _currentQuestionIndex--;
          });
          return;
        }
      }
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Widget _buildQuestionWidget() {
    if (_questions.isEmpty) {
      return const Center(child: Text('Không có câu hỏi'));
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    switch (currentQuestion.questionType) {
      case 'Chọn câu đúng':
        return _buildSingleChoiceQuestion(currentQuestion);
      case '4 câu đúng/sai':
        return _buildMultipleChoiceQuestion(currentQuestion);
      case 'Đúng/Sai':
        return _buildTrueFalseQuestion(currentQuestion);
      case 'Trắc nghiệm ngắn':
        return _buildShortAnswerQuestion(currentQuestion);
      default:
        return Center(
          child: Text(
              'Không hỗ trợ loại câu hỏi: ${currentQuestion.questionType}'),
        );
    }
  }

  Widget _renderAnswer(String answerText) {
    try {
      return TeXView(
        child: TeXViewDocument(
          '''
        <!DOCTYPE html>
        <html>
        <head>
          <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.0/dist/katex.min.css" />
          <script src="https://cdnjs.cloudflare.com/ajax/libs/katex/0.15.6/katex.min.js"></script>
        </head>
        <body>
          ${answerText}
        </body>
        </html>
        ''',
          style: TeXViewStyle(
            padding: TeXViewPadding.all(10),
          ),
        ),
      );
    } catch (e) {
      print('Lỗi hiển thị LaTeX: $e');
      return Text(
        'Lỗi hiển thị nội dung',
        style: TextStyle(color: Colors.red),
      );
    }
  }

  Color _getAnswerColor(int index, bool isSelected) {
    if (!isSelected) return Colors.white;
    if (_answersCorrectness[_currentQuestionIndex]) {
      return mainColor;
    }
    return Colors.red.shade100;
  }

  Widget _buildSingleChoiceQuestion(Question question) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuestionBox(
            text: question.title,
            sectionName: '',
            questionType: question.questionType,
            icon: Ionicons.help,
            isMath: ['toán', 'vật lý', 'hóa'].any((subject) =>
                widget.test.subject!.toLowerCase().contains(subject)),
            imgUrl: question.imgUrl ?? '',
          ),
          const SizedBox(height: 20),
          ...List.generate(
            question.answers.length,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAnswers[_currentQuestionIndex] = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: _getAnswerColor(
                      index,
                      _selectedAnswers[_currentQuestionIndex] == index,
                    ),
                    border: Border.all(
                      color: _selectedAnswers[_currentQuestionIndex] == index
                          ? (_answersCorrectness[_currentQuestionIndex]
                              ? mainColor
                              : Colors.red)
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      if (_selectedAnswers[_currentQuestionIndex] == index)
                        BoxShadow(
                          color: (_answersCorrectness[_currentQuestionIndex]
                                  ? mainColor
                                  : Colors.red)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 12.0),
                  child: Row(
                    children: [
                      Icon(
                        _selectedAnswers[_currentQuestionIndex] == index
                            ? (_answersCorrectness[_currentQuestionIndex]
                                ? Ionicons.checkmark_circle
                                : Ionicons.close_circle)
                            : Ionicons.radio_button_off,
                        color: _selectedAnswers[_currentQuestionIndex] == index
                            ? (_answersCorrectness[_currentQuestionIndex]
                                ? Colors.white
                                : Colors.red)
                            : mainColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DefaultTextStyle(
                          style: TextStyle(
                            color: _selectedAnswers[_currentQuestionIndex] ==
                                    index
                                ? (_answersCorrectness[_currentQuestionIndex]
                                    ? Colors.white
                                    : Colors.black)
                                : Colors.black,
                            fontSize: 16,
                          ),
                          child: _renderAnswer(question.answers[index].text),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Multiple Choice Question Methods
  Color _getMultipleChoiceColor(int index) {
    final selectedList = _selectedAnswers[_currentQuestionIndex] as List<int>?;
    if (!(selectedList?.contains(index) ?? false)) {
      return Colors.white;
    }
    if (_answersCorrectness[_currentQuestionIndex] ?? false) {
      return mainColor.withOpacity(0.1);
    }
    return Colors.red.shade100;
  }

  Color _getMultipleChoiceBorderColor(int index) {
    final selectedList = _selectedAnswers[_currentQuestionIndex] as List<int>?;
    if (!(selectedList?.contains(index) ?? false)) {
      return Colors.grey.shade300;
    }
    if (_answersCorrectness[_currentQuestionIndex] ?? false) {
      return mainColor;
    }
    return Colors.red;
  }

  IconData _getMultipleChoiceIcon(int index) {
    final isSelected = (_selectedAnswers[_currentQuestionIndex] as List<int>?)
            ?.contains(index) ??
        false;
    if (!isSelected) {
      return Ionicons.square_outline;
    }
    if (_answersCorrectness[_currentQuestionIndex] ?? false) {
      return Ionicons.checkbox;
    }
    return Ionicons.close;
  }

  Color _getMultipleChoiceIconColor(int index) {
    final selectedList = _selectedAnswers[_currentQuestionIndex] as List<int>?;
    if (!(selectedList?.contains(index) ?? false)) {
      return mainColor;
    }
    if (_answersCorrectness[_currentQuestionIndex] ?? false) {
      return Colors.white;
    }
    return Colors.red;
  }

  Color _getMultipleChoiceTextColor(int index) {
    final selectedList = _selectedAnswers[_currentQuestionIndex] as List<int>?;
    if (!(selectedList?.contains(index) ?? false)) {
      return Colors.black;
    }
    if (_answersCorrectness[_currentQuestionIndex] ?? false) {
      return mainColor;
    }
    return Colors.red;
  }

  Widget _buildMultipleChoiceQuestion(Question question) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuestionBox(
            text: question.title,
            sectionName: '',
            questionType: '${question.questionType} nếu đúng thì chọn vào ô.',
            icon: Ionicons.help,
            isMath: ['toán', 'vật lý', 'hóa'].any((subject) =>
                widget.test.subject?.toLowerCase().contains(subject) ?? false),
            imgUrl: question.imgUrl ?? '',
          ),
          const SizedBox(height: 20),
          ...List.generate(
            question.answers.length,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAnswers[_currentQuestionIndex] ??= <int>[];
                    final selectedList =
                        _selectedAnswers[_currentQuestionIndex] as List<int>;
                    if (selectedList.contains(index)) {
                      selectedList.remove(index);
                    } else {
                      selectedList.add(index);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: _getMultipleChoiceColor(index),
                    border: Border.all(
                      color: _getMultipleChoiceBorderColor(index),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 12.0),
                  child: Row(
                    children: [
                      Icon(
                        _getMultipleChoiceIcon(index),
                        color: _getMultipleChoiceIconColor(index),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DefaultTextStyle(
                          style: TextStyle(
                            color: _getMultipleChoiceTextColor(index),
                            fontSize: 16,
                          ),
                          child: _renderAnswer(question.answers[index].text),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrueFalseQuestion(Question question) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuestionBox(
            text: question.title,
            sectionName: '',
            questionType: question.questionType,
            icon: Ionicons.help,
            isMath: ['toán', 'vật lý', 'hóa'].any((subject) =>
                widget.test.subject!.toLowerCase().contains(subject)),
            imgUrl: question.imgUrl ?? '',
          ),
          20.height,
          ...List.generate(
            question.answers.length,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAnswers[_currentQuestionIndex] = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: _getAnswerColor(
                      index,
                      _selectedAnswers[_currentQuestionIndex] == index,
                    ),
                    border: Border.all(
                      color: _selectedAnswers[_currentQuestionIndex] == index
                          ? (_answersCorrectness[_currentQuestionIndex]
                              ? mainColor
                              : Colors.red)
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 12.0),
                  child: Row(
                    children: [
                      Icon(
                        _selectedAnswers[_currentQuestionIndex] == index
                            ? (_answersCorrectness[_currentQuestionIndex]
                                ? Ionicons.checkmark_circle
                                : Ionicons.close_circle)
                            : Ionicons.radio_button_off,
                        color: _selectedAnswers[_currentQuestionIndex] == index
                            ? (_answersCorrectness[_currentQuestionIndex]
                                ? Colors.white
                                : Colors.red)
                            : mainColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DefaultTextStyle(
                          style: TextStyle(
                            color: _selectedAnswers[_currentQuestionIndex] ==
                                    index
                                ? (_answersCorrectness[_currentQuestionIndex]
                                    ? Colors.white
                                    : Colors.black)
                                : Colors.black,
                            fontSize: 16,
                          ),
                          child: _renderAnswer(question.answers[index].text),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getShortAnswerBorderColor() {
    if (_selectedAnswers[_currentQuestionIndex] == null ||
        _selectedAnswers[_currentQuestionIndex].isEmpty) {
      return Colors.grey.shade300;
    }
    if (_answersCorrectness[_currentQuestionIndex]) {
      return Colors.green;
    }
    return Colors.red;
  }

  Widget _buildShortAnswerQuestion(Question question) {
    _selectedAnswers[_currentQuestionIndex] ??= '';
    _shortAnswerController.text = _selectedAnswers[_currentQuestionIndex];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuestionBox(
            text: question.title,
            sectionName: '',
            questionType: question.questionType,
            icon: Ionicons.help,
            isMath: ['toán', 'vật lý', 'hóa'].any((subject) =>
                widget.test.subject!.toLowerCase().contains(subject)),
            imgUrl: question.imgUrl ?? '',
          ),
          20.height,
          TextField(
            controller: _shortAnswerController,
            minLines: 5,
            maxLines: 20,
            decoration: InputDecoration(
              hintText: 'Nhập câu trả lời của bạn',
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _getShortAnswerBorderColor(),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _getShortAnswerBorderColor(),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _getShortAnswerBorderColor(),
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _selectedAnswers[_currentQuestionIndex] = value;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: const Center(
            child: Text('Không tìm thấy câu hỏi trong bài kiểm tra này')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: mainColor,
        title: Text(
          widget.test.title,
          style: textsimplewhitebigger,
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(10),
          child: LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.white.withOpacity(0.5),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      body: Container(
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: _buildQuestionWidget(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _currentQuestionIndex > 0
                        ? _moveToPreviousQuestion
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: const Text(
                      'Quay lại',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _moveToNextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: Text(
                      _currentQuestionIndex < _questions.length - 1
                          ? 'Câu tiếp theo'
                          : 'Nộp bài',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
