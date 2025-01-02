import 'dart:convert';
import 'dart:io';
import 'package:app_luyen_de_thpt/components/text_box.dart';
import 'package:app_luyen_de_thpt/providers/auth.dart';
import 'package:app_luyen_de_thpt/screens/createtestscreens.dart';
import 'package:app_luyen_de_thpt/screens/loginscreens.dart';
import 'package:app_luyen_de_thpt/utils/Colors.dart';
import 'package:app_luyen_de_thpt/utils/textstyle.dart';
import 'package:app_luyen_de_thpt/widget/drawerwidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ionicons/ionicons.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class Profilescreens extends StatefulWidget {
  final AppUser user;
  const Profilescreens({super.key, required this.user});

  @override
  State<Profilescreens> createState() => _ProfilescreensState();
}

class _ProfilescreensState extends State<Profilescreens> {
  final _auth = FirebaseAuth.instance;
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool isLoading = true;
  File? _imageFile;
  String? _imageUrl;

  void _checkAuthStatus() {
    if (_auth.currentUser == null) {
      _navigateToLogin();
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

  void _loadScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      isLoading = false;
    });
  }

  void _createQuiz() {
    if (_auth.currentUser == null) {
      _navigateToLogin();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionCreationScreen(
          admin: widget.user,
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    print(widget.user.avatarUrl);
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image first!')),
      );
      return;
    }
    final url = Uri.parse('https://api.cloudinary.com/v1_1/dsbivhlhf/upload');
    print(url);
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'avatars'
      ..files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonMap = jsonDecode(responseString);
      setState(() {
        final url = jsonMap['url'];
        _imageUrl = url;
        widget.user.avatarUrl = _imageUrl;
      });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({'avatarUrl': _imageUrl});
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  Future<void> editInfor(String Infor) async {
    print('Click on the edit');
    String newText = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: mainColor,
        title: Text('Edit $Infor', style: textsimplewhite),
        content: TextField(
          autofocus: true,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter new $Infor",
            hintStyle: TextStyle(color: Colors.white),
          ),
          onChanged: (value) {
            newText = value;
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _loadScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Profile page',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: mainColor,
        elevation: 4,
      ),
      drawer: Mydrawer(
        onSignoutTap: _signOut,
        onCreateTap: _createQuiz,
        user: widget.user,
      ),
      body: Stack(
        children: [
          Container(
            color: backgroundColor,
            child: ListView(
              children: [
                50.height,
                Center(
                  child: widget.user.avatarUrl != null
                      ? CircleAvatar(
                          radius: 80,
                          backgroundImage: NetworkImage(widget.user.avatarUrl!),
                          backgroundColor: Colors.grey[300],
                        )
                      : const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 72,
                        ),
                ),
                10.height,
                Text(
                  currentUser.email!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mainColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                10.height,
                Padding(
                  padding: const EdgeInsets.only(left: 25),
                  child: Text(
                    'My detail',
                    style: TextStyle(color: mainColor, fontSize: 16),
                  ),
                ),
                MyTextBox(
                  text: widget.user.realname!,
                  sectionName: 'Real name',
                  onPressed: () => editInfor('Name'),
                  icon: Ionicons.person_circle_outline,
                ),
                MyTextBox(
                  text: widget.user.gender != null
                      ? widget.user.gender!
                      : 'Unknow',
                  sectionName: 'Gender',
                  onPressed: () => editInfor('Gender'),
                  icon: Ionicons.male_female_outline,
                ),
                MyTextBox(
                  text: widget.user.dateOfBirth != null
                      ? formatDate(widget.user.dateOfBirth!)
                      : 'Unknown',
                  sectionName: 'Date of Birth',
                  onPressed: () => editInfor('dateofbirth'),
                  icon: Icons.cake,
                ),
                MyTextBox(
                  text: widget.user.namehighschool!,
                  sectionName: 'Name school',
                  onPressed: () => editInfor('Name school'),
                  icon: Ionicons.school,
                ),
                MyTextBox(
                  text:
                      widget.user.group != null ? widget.user.group! : 'Unknow',
                  sectionName: 'Name group',
                  onPressed: () => editInfor('Name group'),
                  icon: Ionicons.people,
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Change Avatar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Lớp phủ loading
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  color: mainColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
