import 'dart:convert';
import 'dart:io';
import 'package:app_luyen_de_thpt/providers/cloudinary.dart';
import 'package:app_luyen_de_thpt/screens/createtestscreens.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class SubAnswer {
  final TextEditingController textController;
  bool isCorrect;
  SubAnswer({String? text, this.isCorrect = false})
      : textController = TextEditingController(text: text);
}

class QuestionController {
  final TextEditingController titleController;
  final TextEditingController tutorialController; // Thêm controller mới
  String questionType;
  String? imageUrl;
  List<SubAnswer> subAnswers;
  String? tutorial;
  int? number;
  QuestionController({
    String? title,
    this.questionType = 'Chọn câu đúng',
    int numberOfAnswers = 4,
    this.tutorial,
  })  : titleController = TextEditingController(text: title),
        tutorialController = TextEditingController(text: tutorial),
        subAnswers = List.generate(numberOfAnswers, (index) => SubAnswer()),
        number = QuestionCounterManager.getNextNumber();

  void setImageUrl(String? url) {
    imageUrl = url;
  }
}

class QuestionWidget extends StatefulWidget {
  final String idTest;
  final QuestionController controller;
  final VoidCallback onDelete;

  const QuestionWidget({
    Key? key,
    required this.idTest,
    required this.controller,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  File? _imageFile;

  Future<void> _pickImage(String testId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _clearImage() {
    setState(() {
      _imageFile = null;
      widget.controller.setImageUrl(null);
    });
  }

  Future<void> _uploadImage(String testId) async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first!')),
      );
      return;
    }

    try {
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/${cloudName}/auto/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'img_ques'
        ..fields['folder'] = '$testId' // Tạo folder riêng cho mỗi test
        ..files
            .add(await http.MultipartFile.fromPath('file', _imageFile!.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);

        setState(() {
          widget.controller.setImageUrl(jsonMap['url']);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!')),
        );
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }

  void _adjustSubAnswersBasedOnType(String type) {
    switch (type) {
      case '4 câu đúng/sai':
      case 'Chọn câu đúng':
        widget.controller.subAnswers = List.generate(4, (index) => SubAnswer());
        break;
      case 'Đúng/Sai':
        widget.controller.subAnswers = [
          SubAnswer(text: 'Đúng'),
          SubAnswer(text: 'Sai'),
        ];
        break;
      case 'Trắc nghiệm ngắn':
        widget.controller.subAnswers = [SubAnswer()]; // Chỉ có 1 đáp án
        break;
    }
  }

  Widget _buildAnswersSection() {
    switch (widget.controller.questionType) {
      case '4 câu đúng/sai':
        return _buildFourSubAnswers();
      case 'Chọn câu đúng':
        return _buildSingleChoiceAnswers();
      case 'Đúng/Sai':
        return _buildTrueFalseAnswers();
      case 'Trắc nghiệm ngắn':
        return _buildShortAnswerQuestion();
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //Text('Câu số: ${widget.controller.number ?? ''}'),
                TextButton.icon(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Xóa câu hỏi'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              minLines: 5,
              maxLines: 25,
              controller: widget.controller.titleController,
              decoration: const InputDecoration(
                labelText: 'Câu hỏi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: widget.controller.questionType,
              decoration: const InputDecoration(
                labelText: 'Loại câu hỏi',
                border: OutlineInputBorder(),
              ),
              items: [
                'Chọn câu đúng',
                'Đúng/Sai',
                '4 câu đúng/sai',
                'Trắc nghiệm ngắn'
              ].map((type) {
                return DropdownMenuItem<String>(value: type, child: Text(type));
              }).toList(),
              onChanged: (newType) {
                setState(() {
                  widget.controller.questionType = newType!;
                  _adjustSubAnswersBasedOnType(newType);
                });
              },
            ),
            const SizedBox(height: 16),
            _buildAnswersSection(),
            const SizedBox(height: 16),
            TextField(
              minLines: 5,
              maxLines: 25,
              controller: widget.controller
                  .tutorialController, // Sử dụng controller thay vì onChanged
              decoration: const InputDecoration(
                labelText: 'Hướng dẫn)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _pickImage(widget.idTest),
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Thêm ảnh'),
                ),
                TextButton.icon(
                  onPressed: _imageFile != null
                      ? () => _uploadImage(widget.idTest)
                      : null,
                  icon: const Icon(Icons.upload),
                  label: const Text('Lưu ảnh'),
                ),
                TextButton.icon(
                  onPressed:
                      widget.controller.imageUrl != null || _imageFile != null
                          ? _clearImage
                          : null,
                  icon: const Icon(Icons.delete),
                  label: const Text('Xóa ảnh'),
                ),
              ],
            ),
            if (_imageFile != null || widget.controller.imageUrl != null) ...[
              const SizedBox(height: 16),
              _imageFile != null
                  ? Image.file(
                      _imageFile!,
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      widget.controller.imageUrl!,
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover,
                    ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSingleChoiceAnswers() {
    return Column(
      children: List.generate(4, (index) {
        final subAnswer = widget.controller.subAnswers[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              minLines: 3,
              maxLines: 20,
              controller: subAnswer.textController,
              decoration: InputDecoration(
                labelText: 'Đáp án ${String.fromCharCode(97 + index)})',
                border: const OutlineInputBorder(),
              ),
            ),
            8.height,
            Row(
              children: [
                const Text('Đúng'),
                Radio<bool>(
                  value: true,
                  groupValue: subAnswer.isCorrect,
                  onChanged: (value) {
                    setState(() {
                      for (var answer in widget.controller.subAnswers) {
                        answer.isCorrect = false;
                      }
                      subAnswer.isCorrect = value!;
                    });
                  },
                ),
              ],
            ),
            10.height,
          ],
        );
      }),
    );
  }

  Widget _buildFourSubAnswers() {
    return Column(
      children: List.generate(4, (index) {
        final subAnswer = widget.controller.subAnswers[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              minLines: 3,
              maxLines: 20,
              controller: subAnswer.textController,
              decoration: InputDecoration(
                labelText: 'Đáp án ${String.fromCharCode(97 + index)})',
                border: const OutlineInputBorder(),
              ),
            ),
            8.height,
            Row(
              children: [
                const Text('Đúng'),
                Checkbox(
                  value: subAnswer.isCorrect,
                  onChanged: (value) {
                    setState(() {
                      subAnswer.isCorrect = value!;
                    });
                  },
                ),
              ],
            ),
            10.height,
          ],
        );
      }),
    );
  }

  Widget _buildTrueFalseAnswers() {
    return Column(
      children: List.generate(2, (index) {
        final subAnswer = widget.controller.subAnswers[index];
        return ListTile(
          title: Text(subAnswer.textController.text),
          leading: Radio<bool>(
            value: true,
            groupValue: subAnswer.isCorrect,
            onChanged: (value) {
              setState(() {
                for (var answer in widget.controller.subAnswers) {
                  answer.isCorrect = false;
                }
                subAnswer.isCorrect = value!;
              });
            },
          ),
        );
      }),
    );
  }

  Widget _buildShortAnswerQuestion() {
    final subAnswer = widget.controller.subAnswers[0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          minLines: 3,
          maxLines: 20,
          controller: subAnswer.textController,
          decoration: const InputDecoration(
            labelText: 'Nhập câu trả lời',
            border: OutlineInputBorder(),
          ),
        ),
        8.height,
      ],
    );
  }
}
