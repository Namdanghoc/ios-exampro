import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Question {
  final String id;
  final String title;
  String questionType;
  final String? imgUrl;
  final List<Answer> answers;
  final String? tutorial;
  final int? number;

  Question(
      {required this.id,
      required this.title,
      this.questionType = 'Chọn câu đúng',
      this.imgUrl,
      required this.answers,
      required this.tutorial,
      required this.number});
}

class Answer {
  final String text;
  final bool isCorrect;

  const Answer({
    required this.text,
    required this.isCorrect,
  });
}

class Test {
  final String id;
  final String title;
  final String subject;
  final String author;
  final String idAthor;
  late String? create;
  late String? school = "";
  late int? subjectId;
  final List<Question> questions;

  Test({
    required this.id,
    required this.title,
    required this.subject,
    this.subjectId,
    required this.author,
    required this.idAthor,
    this.create,
    this.school,
    required this.questions,
  });
}

class TestResult {
  final String userId;
  final String nameUser;
  final String testId;
  final String title;
  final double score;
  final DateTime timestamp;
  final int? correctAnswers;
  final int? incorrectAnswers;
  //final Duration? timeSpent;
  final int? questionsAnswered;

  TestResult({
    required this.userId,
    required this.nameUser,
    required this.testId,
    required this.title,
    required this.score,
    required this.timestamp,
    this.correctAnswers,
    this.incorrectAnswers,
    //this.timeSpent,
    this.questionsAnswered,
  });
}

class TestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getTodayAsString() {
    DateTime now = DateTime.now();
    // Định dạng ngày thành chuỗi kiểu `dd/MM/yyyy`
    String formattedDate = DateFormat('dd/MM/yyyy').format(now);
    return formattedDate;
  }

  Future<Test?> createTest(Test quiz, String idAdmin) async {
    String today = getTodayAsString();
    print(today);

    try {
      DocumentReference quizRef = await _firestore.collection('dethi').add({
        'title': quiz.title,
        'createdAt': FieldValue.serverTimestamp(),
        'subject': quiz.subject,
        'author': quiz.author,
        'idAuthor': idAdmin,
        'create': today,
        'subjectId': quiz.subjectId,
        'school': quiz.school
      });
      print(quiz.id);
      await quizRef.update({'id': quizRef.id});

      for (var question in quiz.questions) {
        DocumentReference questionRef = quizRef.collection('questions').doc();
        await questionRef.set({
          'title': question.title,
          'questionType': question.questionType ?? 'Chọn câu đúng',
          'imgUrl': question.imgUrl,
          'number': question.number ?? 0,
          'tutorial': question.tutorial ?? 'Hướng dẫn',
          'answers': question.answers.map((a) {
            return {'text': a.text, 'isCorrect': a.isCorrect};
          }).toList(),
        });
      }

      return Test(
          id: quizRef.id,
          title: quiz.title,
          subject: quiz.subject,
          author: quiz.author,
          idAthor: quiz.idAthor,
          create: today,
          questions: quiz.questions);
    } catch (e) {
      print('Create Test Error: $e');
      return null;
    }
  }

  Future<Test?> copyTest(String searchTitle) async {
    try {
      QuerySnapshot testQuery = await _firestore
          .collection('dethi')
          .where('title', isEqualTo: searchTitle)
          .limit(1)
          .get();

      if (testQuery.docs.isEmpty) {
        print('No test found with title: $searchTitle');
        return null;
      }
      DocumentSnapshot testDoc = testQuery.docs.first;
      QuerySnapshot questionsSnapshot = await _firestore
          .collection('dethi')
          .doc(testDoc.id)
          .collection('questions')
          .orderBy('number')
          .get();

      List<Question> questions = [];
      for (var questionDoc in questionsSnapshot.docs) {
        List<Answer> answers = (questionDoc['answers'] as List).map((a) {
          return Answer(text: a['text'], isCorrect: a['isCorrect']);
        }).toList();

        questions.add(Question(
          id: questionDoc.id,
          title: questionDoc['title'],
          imgUrl: questionDoc['imgUrl'],
          number: questionDoc['number'],
          tutorial: questionDoc['tutorial'] ?? 'Hướng dẫn',
          questionType: questionDoc['questionType'] ?? 'Chọn câu đúng',
          answers: answers,
        ));
      }

      Test duplicateTest = Test(
        id: '',
        title: '${testDoc['title']} (Sao chép)',
        subject: testDoc['subject'],
        subjectId: testDoc['subjectId'],
        author: testDoc['author'],
        idAthor: testDoc['idAuthor'],
        school: testDoc['school'],
        questions: questions,
      );
      return await createTest(duplicateTest, testDoc['idAuthor']);
    } catch (e) {
      print('Save and Duplicate Test Error: $e');
      return null;
    }
  }

  Future<void> deleteTest(String testId) async {
    try {
      DocumentReference testRef = _firestore.collection('dethi').doc(testId);
      DocumentSnapshot snapshot = await testRef.get();

      if (!snapshot.exists) {
        print('Test does not exist');
        return;
      }

      QuerySnapshot questionsSnapshot =
          await testRef.collection('questions').get();
      for (var doc in questionsSnapshot.docs) {
        await doc.reference.delete();
      }
      await testRef.delete();

      print('Test deleted successfully');
    } catch (e) {
      print('Delete Test Error: $e');
    }
  }

  Future<List<Test>> getAllTests() async {
    try {
      QuerySnapshot listTest = await _firestore
          .collection('dethi')
          .orderBy('createdAt', descending: true)
          .get();

      List<Test> tests = [];

      for (var doc in listTest.docs) {
        QuerySnapshot questionsSnapshot = await _firestore
            .collection('dethi')
            .doc(doc.id)
            .collection('questions')
            .orderBy('number')
            .get();
        List<Question> questions = [];
        int questionIndex = 1;
        for (var questionDoc in questionsSnapshot.docs) {
          List<Answer> answers = (questionDoc['answers'] as List).map((a) {
            return Answer(text: a['text'], isCorrect: a['isCorrect']);
          }).toList();
          questions.add(Question(
            id: questionDoc.id,
            title: questionDoc['title'],
            imgUrl: questionDoc['imgUrl'],
            number: questionDoc['number'] ?? questionIndex,
            tutorial: questionDoc['tutorial'] ?? 'Hướng dẫn',
            questionType: questionDoc['questionType'] ?? 'Chọn câu đúng',
            answers: answers,
          ));

          questionIndex++;
        }
        tests.add(Test(
          id: doc['id'],
          title: doc['title'],
          subject: doc['subject'],
          subjectId: doc['subjectId'],
          author: doc['author'],
          idAthor: doc['idAuthor'],
          create: doc['create'],
          school: doc['school'],
          questions: questions,
        ));
      }
      return tests;
    } catch (e) {
      print('Fetch All Tests Error: $e');
      return [];
    }
  }

  Future<List<Test>> getDataTestBySchool(String schoolName) async {
    try {
      QuerySnapshot listTest = await _firestore
          .collection('dethi')
          .where('school', isEqualTo: schoolName)
          .orderBy('createdAt', descending: true)
          .get();

      List<Test> tests = [];

      for (var doc in listTest.docs) {
        QuerySnapshot questionsSnapshot = await _firestore
            .collection('dethi')
            .doc(doc.id)
            .collection('questions')
            .orderBy('number')
            .get();

        List<Question> questions = [];
        int questionIndex = 1;

        for (var questionDoc in questionsSnapshot.docs) {
          List<Answer> answers = (questionDoc['answers'] as List).map((a) {
            return Answer(text: a['text'], isCorrect: a['isCorrect']);
          }).toList();

          Question question = Question(
            id: questionDoc.id,
            title: '${questionDoc['title']}',
            imgUrl: questionDoc['imgUrl'],
            number: questionDoc['number'] ??
                questionIndex, // Use 'number' if present, otherwise use questionIndex
            tutorial: questionDoc['tutorial'] ?? 'Hướng dẫn',
            questionType: questionDoc['questionType'] ?? 'Chọn câu đúng',
            answers: answers,
          );

          questions.add(question);
          questionIndex++;
        }

        tests.add(Test(
          id: doc['id'],
          title: doc['title'],
          subject: doc['subject'],
          subjectId: doc['subjectId'],
          author: doc['author'],
          idAthor: doc['idAuthor'],
          create: doc['create'],
          school: doc['school'],
          questions: questions,
        ));
      }

      return tests;
    } catch (e) {
      print('Fetch Quizzes Error: $e');
      return [];
    }
  }

  Future<List<Test>> getDataTestAdmin(String idAdmin) async {
    try {
      QuerySnapshot listTest = await _firestore
          .collection('dethi')
          .where('idAuthor', isEqualTo: idAdmin)
          .orderBy('createdAt', descending: true)
          .get();

      List<Test> tests = [];

      for (var doc in listTest.docs) {
        QuerySnapshot questionsSnapshot = await _firestore
            .collection('dethi')
            .doc(doc.id)
            .collection('questions')
            .orderBy('number')
            .get();

        List<Question> questions = [];
        int questionIndex = 1;

        for (var questionDoc in questionsSnapshot.docs) {
          List<Answer> answers = (questionDoc['answers'] as List).map((a) {
            return Answer(text: a['text'], isCorrect: a['isCorrect']);
          }).toList();
          questions.add(Question(
            id: questionDoc.id,
            title: '${questionDoc['title']}',
            imgUrl: questionDoc['imgUrl'],
            number: questionDoc['number'] ?? questionIndex,
            tutorial: questionDoc['tutorial'] ?? 'Hướng dẫn',
            questionType: questionDoc['questionType'] ?? 'Chọn câu đúng',
            answers: answers,
          ));

          questionIndex++;
        }
        tests.add(Test(
          id: doc['id'],
          title: doc['title'],
          subject: doc['subject'],
          subjectId: doc['subjectId'],
          author: doc['author'],
          idAthor: doc['idAuthor'],
          create: doc['create'],
          school: doc['school'],
          questions: questions,
        ));
      }

      return tests;
    } catch (e) {
      print('Fetch Quizzes Error: $e');
      return [];
    }
  }

  Future<void> submitTestResult(
      String userId,
      String testId,
      String title,
      double score,
      int correctAnswer,
      int incorrectAnswer,
      int totalQuestion,
      String nameUser) async {
    try {
      QuerySnapshot existingResults = await _firestore
          .collection('test_results')
          .where('userId', isEqualTo: userId)
          .where('testId', isEqualTo: testId)
          .get();
      final resultData = {
        'userId': userId,
        'nameUser': nameUser,
        'testId': testId,
        'title': title,
        'correctAnswer': correctAnswer,
        'incorrectAnswer': incorrectAnswer,
        'totalQuestion': totalQuestion,
        'score': score,
        'timestamp': FieldValue.serverTimestamp()
      };

      if (existingResults.docs.isEmpty) {
        await _firestore.collection('test_results').add(resultData);
        print('New test result added');
      } else {
        DocumentReference docRef = existingResults.docs.first.reference;
        await docRef.update(resultData);
        print('Existing test result updated');
      }
    } catch (e) {
      print('Submit Quiz Result Error: $e');
    }
  }

  Future<List<TestResult>> getTestResultsForAdmin(String adminId) async {
    try {
      QuerySnapshot testSnapshot = await _firestore
          .collection('dethi')
          .where('idAuthor', isEqualTo: adminId)
          .get();

      if (testSnapshot.docs.isEmpty) {
        print('Admin này chưa tạo bài kiểm tra nào.');
        return [];
      }

      List<String> testId =
          testSnapshot.docs.map((doc) => doc['id'] as String).toList();
      print(testId);

      QuerySnapshot resultSnapshot = await _firestore
          .collection('test_results')
          .where('testId', whereIn: testId)
          .get();
      print(resultSnapshot.size);
      List<TestResult> results = resultSnapshot.docs.map((doc) {
        return TestResult(
          userId: doc['userId'],
          nameUser: doc['nameUser'],
          testId: doc['testId'],
          title: doc['title'],
          score: doc['score'],
          timestamp: (doc['timestamp'] as Timestamp).toDate(),
          correctAnswers: doc['correctAnswer'],
          incorrectAnswers: doc['incorrectAnswer'],
          questionsAnswered: doc['totalQuestion'],
        );
      }).toList();

      print('Tổng số kết quả nhận được: ${results.length}');
      return results;
    } catch (e) {
      print('Lỗi khi lấy danh sách kết quả: $e');
      return [];
    }
  }

  Future<List<TestResult>> getTestResultsForUser(String userId) async {
    try {
      QuerySnapshot resultSnapshot = await _firestore
          .collection('test_results')
          .where('userId', isEqualTo: userId)
          .get();

      if (resultSnapshot.docs.isEmpty) {
        print('Người dùng chưa có kết quả bài kiểm tra nào.');
        return [];
      }
      List<TestResult> results = resultSnapshot.docs.map((doc) {
        return TestResult(
          userId: doc['userId'],
          nameUser: doc['nameUser'],
          testId: doc['testId'],
          title: doc['title'],
          score: doc['score'],
          timestamp: (doc['timestamp'] as Timestamp).toDate(),
          correctAnswers: doc['correctAnswer'],
          incorrectAnswers: doc['incorrectAnswer'],
          questionsAnswered: doc['totalQuestion'],
        );
      }).toList();

      // Sort results by timestamp in descending order (most recent first)
      results.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      print('Tổng số kết quả của người dùng: ${results.length}');
      return results;
    } catch (e) {
      print('Lỗi khi lấy danh sách kết quả người dùng: $e');
      return [];
    }
  }

  Future<int> getTestCountByAuthor(String idAuthor) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('dethi')
          .where('idAuthor', isEqualTo: idAuthor)
          .get();
      print('Total tests created by author $idAuthor: ${snapshot.size}');

      return snapshot.size;
    } catch (e) {
      print('Get Test Count Error: $e');
      return 0;
    }
  }

  Future<int> getUniqueTestTakersCountToday(String adminId) async {
    try {
      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day);
      DateTime endOfDay = startOfDay
          .add(const Duration(days: 1))
          .subtract(const Duration(seconds: 1));

      // Create a map to store user IDs and their test counts
      final Map<String, int> userTestCounts = {};

      // Query tests created by the admin
      QuerySnapshot testSnapshot = await FirebaseFirestore.instance
          .collection('dethi')
          .where('idAuthor', isEqualTo: adminId)
          .get();

      if (testSnapshot.docs.isEmpty) {
        print('This admin has no tests created.');
        return 0;
      }

      // Extract test IDs
      List<String> testIds =
          testSnapshot.docs.map((doc) => doc['id'] as String).toList();

      // Query test results with filtering
      QuerySnapshot resultSnapshot = await FirebaseFirestore.instance
          .collection('test_results')
          .where('testId', whereIn: testIds)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      // Process each result, incrementing user test counts
      for (var doc in resultSnapshot.docs) {
        String userId = doc['userId'];
        userTestCounts[userId] = (userTestCounts[userId] ?? 0) + 1;
      }

      // Count unique test takers (users who took at least one test)
      int uniqueTakersCount =
          userTestCounts.values.where((count) => count > 0).length;

      print('So luong nguoi THAM GIA KIEM TRA hom nay ${uniqueTakersCount}');
      return uniqueTakersCount;
    } catch (e) {
      print('Error fetching unique test takers count: $e');
      return 0;
    }
  }
}
