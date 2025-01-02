import 'package:app_luyen_de_thpt/screens/createtestscreens.dart';
import 'package:app_luyen_de_thpt/utils/Colors.dart';
import 'package:app_luyen_de_thpt/widget/infortestwidget.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:nb_utils/nb_utils.dart';

class MyTextBox extends StatelessWidget {
  final String text;
  final String sectionName;
  final Function? onPressed;
  final IconData icon;
  const MyTextBox(
      {super.key,
      required this.text,
      required this.sectionName,
      required this.onPressed,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.only(left: 15, bottom: 15),
      margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: mainColor),
                  8.width,
                  Text(
                    sectionName,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  if (onPressed != null) {
                    onPressed!();
                  }
                },
                icon: Icon(
                  Ionicons.pencil,
                  color: Colors.grey[400],
                ),
              )
            ],
          ),
          Text(text)
        ],
      ),
    );
  }
}
