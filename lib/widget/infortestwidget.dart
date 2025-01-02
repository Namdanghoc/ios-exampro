import 'package:app_luyen_de_thpt/providers/auth.dart';
import 'package:app_luyen_de_thpt/providers/test.dart';
import 'package:app_luyen_de_thpt/providers/subject.dart';
import 'package:app_luyen_de_thpt/screens/testscreens.dart';
import 'package:app_luyen_de_thpt/utils/Colors.dart';
import 'package:app_luyen_de_thpt/utils/textstyle.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:nb_utils/nb_utils.dart';

class Infortest extends StatelessWidget {
  final AppUser user;
  final Test inforTest;
  const Infortest({super.key, required this.inforTest, required this.user});

  void starTest(BuildContext context, Test quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestScreen(
          test: quiz,
          user: user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: backgroundColor_darker,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Ionicons.document_text_outline,
                  size: 18,
                  color: mainColor,
                ),
                8.width,
                Flexible(
                  child: Text(
                    'Mã đề: ${inforTest.title}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: mainColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            8.height,
            Center(
              child: SubjectIconProvider.getSubjectIcon(inforTest.subjectId!),
            ),
            8.height,
            Row(
              children: [
                Icon(
                  Ionicons.book,
                  size: 18,
                  color: mainColor,
                ),
                8.width,
                Text('Môn học: ${inforTest.subject}', style: textsimpleblack),
              ],
            ),
            Row(
              children: [
                Icon(
                  Ionicons.reader,
                  size: 18,
                  color: mainColor,
                ),
                8.width,
                Text('Số câu hỏi: ${inforTest.questions.length}',
                    style: textsimpleblack),
              ],
            ),
            Row(
              children: [
                Icon(
                  Ionicons.person,
                  size: 18,
                  color: mainColor,
                ),
                8.width,
                Text('Tác giả: ${inforTest.author}', style: textsimpleblack),
              ],
            ),
            Row(
              children: [
                Icon(
                  Ionicons.calendar,
                  size: 18,
                  color: mainColor,
                ),
                8.width,
                Text('Ngày tạo: ${inforTest.create}', style: textsimpleblack),
              ],
            ),
            Row(
              children: [
                Icon(
                  Ionicons.school,
                  size: 18,
                  color: mainColor,
                ),
                8.width,
                Text('Trường: ${inforTest.school}', style: textsimpleblack),
              ],
            ),
            Center(
              child: SizedBox(
                width: 150,
                child: ElevatedButton(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Ionicons.play_circle_outline,
                        color: Colors.white,
                      ),
                      8.width,
                      Text(
                        'Begin Test',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    starTest(context, inforTest);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> show(
      BuildContext context, Test quiz, AppUser user) async {
    await showDialog(
      context: context,
      builder: (context) => Infortest(inforTest: quiz, user: user),
    );
  }
}

