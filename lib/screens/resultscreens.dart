import 'package:app_luyen_de_thpt/providers/auth.dart';
import 'package:app_luyen_de_thpt/providers/test.dart';

import 'package:app_luyen_de_thpt/utils/Colors.dart';
import 'package:app_luyen_de_thpt/utils/textstyle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nb_utils/nb_utils.dart';

class TestResultScreen extends StatefulWidget {
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final AppUser user;
  final String idTest;
  final String titleTest;

  const TestResultScreen(
      {Key? key,
      required this.totalQuestions,
      required this.correctAnswers,
      required this.incorrectAnswers,
      required this.user,
      required this.idTest,
      required this.titleTest})
      : super(key: key);

  @override
  State<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen> {
  Future<void> submit(
      String userId,
      String testId,
      String titleTest,
      double score,
      int correctAnswer,
      int incorrectAnswer,
      int totalQuestion,
      String nameUser) async {
    Navigator.pop(context);
    final TestService _quizService = TestService();
    await _quizService.submitTestResult(
        userId,
        testId,
        titleTest,
        score.toDouble(),
        correctAnswer,
        incorrectAnswer,
        totalQuestion,
        nameUser);
  }

  @override
  Widget build(BuildContext context) {
    // Tính điểm
    double score = (widget.correctAnswers / widget.totalQuestions) * 10;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Result test',
          style: textsimplewhitebigger,
        ),
        centerTitle: true,
        backgroundColor: mainColor,
      ),
      body: Container(
        color: backgroundColor,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    score < 5 ? 'Better Luck Next Time!' : 'Congratulations!',
                    style: TextStyle(
                      fontSize: 25,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.user.realname!,
                    style: TextStyle(
                        fontSize: 30,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: SvgPicture.asset(
                    score < 5
                        ? "assets/icons/try_again.svg"
                        : "assets/icons/winner.svg",
                  ),
                ),
                Text(
                  'Score: ${score.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${widget.correctAnswers} / ${widget.totalQuestions} correct',
                  style: TextStyle(fontSize: 18),
                ),
                20.height,
                ElevatedButton(
                  onPressed: () {
                    submit(
                        widget.user.id!,
                        widget.idTest,
                        widget.titleTest,
                        score,
                        widget.correctAnswers,
                        widget.incorrectAnswers,
                        widget.totalQuestions,
                        widget.user.realname!);
                  },
                  child: Text('Back to home'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
