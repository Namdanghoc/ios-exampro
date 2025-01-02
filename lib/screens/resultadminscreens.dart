import 'package:app_luyen_de_thpt/providers/test.dart';
import 'package:app_luyen_de_thpt/utils/Colors.dart';
import 'package:app_luyen_de_thpt/utils/textstyle.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:nb_utils/nb_utils.dart';

class TestResultsAdminScreen extends StatefulWidget {
  final List<TestResult> testResults;

  const TestResultsAdminScreen({Key? key, required this.testResults})
      : super(key: key);

  @override
  _TestResultsAdminScreenState createState() => _TestResultsAdminScreenState();
}

class _TestResultsAdminScreenState extends State<TestResultsAdminScreen> {
  late Map<String, List<TestResult>> groupedResults;

  @override
  void initState() {
    super.initState();
    groupedResults = _groupResultsByTitle(widget.testResults);
  }

  Map<String, List<TestResult>> _groupResultsByTitle(List<TestResult> results) {
    final Map<String, List<TestResult>> grouped = {};
    for (var result in results) {
      if (!grouped.containsKey(result.title)) {
        grouped[result.title] = [];
      }
      grouped[result.title]!.add(result);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Test Results by Id test',
          style: textsimplewhitebigger,
        ),
        backgroundColor: mainColor,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(color: backgroundColor),
        child: ListView(
          children: groupedResults.keys.map((title) {
            final count = groupedResults[title]!.length;
            return Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.numbers,
                      color: outerSpace,
                    ),
                    4.width,
                    Text(
                      title,
                      style: TextStyle(color: outerSpace),
                    ),
                  ],
                ),
                subtitle: Row(
                  children: [
                    Icon(
                      Ionicons.person,
                      color: outerSpace,
                    ),
                    4.width,
                    Text(
                      'Number person tested: $count',
                      style: TextStyle(color: outerSpace),
                    ),
                  ],
                ),
                trailing: const Icon(
                  Ionicons.eye_outline,
                  color: outerSpace,
                ),
                onTap: () => _showResultsForTitle(context, title),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showResultsForTitle(BuildContext context, String title) {
    final results = groupedResults[title]!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ResultsByTitleScreen(title: title, results: results),
      ),
    );
  }
}

class ResultsByTitleScreen extends StatelessWidget {
  final String title;
  final List<TestResult> results;

  const ResultsByTitleScreen(
      {Key? key, required this.title, required this.results})
      : super(key: key);
  String _formatTimestamp(DateTime timestamp) {
    return "${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Results for "$title"',
          style: textsimplewhitebigger,
        ),
        backgroundColor: mainColor,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(color: backgroundColor),
        child: ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                title: Text('Test ID: ${result.title}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User: ${result.nameUser}'),
                    Text('Score: ${result.score}'),
                    Text('Correct Answers: ${result.correctAnswers}'),
                    Text('Incorrect Answers: ${result.incorrectAnswers}'),
                    Text('Date: ${_formatTimestamp(result.timestamp)}'),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
