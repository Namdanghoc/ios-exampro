import 'package:app_luyen_de_thpt/providers/auth.dart';
import 'package:app_luyen_de_thpt/screens/resultadminscreens.dart';
import 'package:app_luyen_de_thpt/screens/listtestadmin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nb_utils/nb_utils.dart';
import '../providers/test.dart';
import '../screens/createtestscreens.dart';
import '../screens/loginscreens.dart';
import '../utils/Colors.dart';
import '../widget/drawerwidget.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AppUser admin;
  const AdminDashboardScreen({Key? key, required this.admin}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _auth = FirebaseAuth.instance;
  final _testService = TestService();
  int sumTestCreate = 0;
  int sumPersonToday = 0;
  late List<TestResult> testResults = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _checkAuthStatus();
    await _fetchTestCount();
    await _fetchTestResults();
    await _fetchPersonToday();
  }

  void _checkAuthStatus() {
    if (_auth.currentUser == null) {
      _navigateToLogin();
    }
  }

  Future<void> _fetchTestCount() async {
    try {
      int testCount = await _testService.getTestCountByAuthor(widget.admin.id!);
      setState(() {
        sumTestCreate = testCount;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching test count: $e')),
      );
    }
  }

  Future<void> _fetchTestResults() async {
    try {
      final results =
          await _testService.getTestResultsForAdmin(widget.admin.id!);
      setState(() {
        testResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching test results: $e')),
      );
    }
  }

  Future<void> _fetchPersonToday() async {
    try {
      int results =
          await _testService.getUniqueTestTakersCountToday(widget.admin.id!);
      setState(() {
        sumPersonToday = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching test results: $e')),
      );
    }
  }

  void _signOut() {
    _auth.signOut();
    _navigateToLogin();
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _createQuiz() {
    if (_auth.currentUser == null) {
      _navigateToLogin();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionCreationScreen(admin: widget.admin),
      ),
    );
  }

  void createCloneTest() async {
    // Hiển thị dialog để nhập title
    String? searchTitle = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String inputText = '';
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            'Clone Test',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: TextField(
              onChanged: (value) {
                inputText = value;
              },
              decoration: InputDecoration(
                hintText: 'Enter test title to clone',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: mainColor),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, inputText),
              child: Text('Clone'),
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (searchTitle != null && searchTitle.isNotEmpty) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Center(child: CircularProgressIndicator());
          },
        );
        final duplicatedTest = await _testService.copyTest(searchTitle);
        Navigator.pop(context);
        if (duplicatedTest != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Test clone successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          _fetchTestCount();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No test found with that title'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clone test: $e'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      drawer: Mydrawer(
        onSignoutTap: _signOut,
        onCreateTap: _createQuiz,
        user: widget.admin,
      ),
      body:
          // testResults.isEmpty
          //     ? Center(child: CircularProgressIndicator())
          //:
          _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        'Welcome, ${widget.admin.realname}',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      backgroundColor: mainColor,
      elevation: 4,
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTestSummaryCard(),
            20.height,
            _buildPersonTodaySummaryCard(),
            20.height,
            _buildQuickActionSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildTestIllustration(),
            20.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: outerSpace,
                    ),
                  ),
                  10.height,
                  Text(
                    'You have created $sumTestCreate test(s)',
                    style: TextStyle(
                      color: outerSpace,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  10.height,
                  Text(
                    'Keep up the great work!',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonTodaySummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPersonIllustration(),
            20.height,
            Text(
              sumPersonToday < 2
                  ? '$sumPersonToday person has done your test today.'
                  : '$sumPersonToday people have done your test today.',
              style: TextStyle(
                color: outerSpace,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              sumPersonToday > 10 ? 'Perfect !' : 'Nice try',
              style: TextStyle(
                color: outerSpace,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestIllustration() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: SvgPicture.asset(
          "assets/icons/sharing.svg",
          width: 80,
          height: 80,
          fit: BoxFit.contain,
          placeholderBuilder: (BuildContext context) =>
              const CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildPersonIllustration() {
    return Container(
      width: 350,
      height: 350,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: SvgPicture.asset(
          "assets/icons/users_monthly.svg",
          width: 280,
          height: 280,
          fit: BoxFit.contain,
          placeholderBuilder: (BuildContext context) =>
              const CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildQuickActionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: mainColor,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            _buildActionButton(
              icon: Icons.add_circle_outline,
              label: 'Create Test',
              onTap: _createQuiz,
            ),
            const SizedBox(width: 15),
            _buildActionButton(
              icon: Icons.list_alt_rounded,
              label: 'My Tests',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ListTestAdminScreen(admin: widget.admin),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            _buildActionButton(
              icon: Icons.assessment,
              label: 'View Results',
              onTap: () {
                if (testResults.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No test results available to display.'),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TestResultsAdminScreen(testResults: testResults),
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 15),
            _buildActionButton(
              icon: Icons.copy_all,
              label: 'Clone Test',
              onTap: createCloneTest,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: mainColor.withOpacity(0.1),
          foregroundColor: mainColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
        child: Column(
          children: [
            Icon(icon, color: mainColor, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: mainColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
