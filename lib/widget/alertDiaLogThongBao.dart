import 'package:app_luyen_de_thpt/utils/Colors.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class AlertDiaLogThongBao extends StatefulWidget {
  String noiDungThongBao;
  String tieuDeThongBao;

  AlertDiaLogThongBao({super.key, this.noiDungThongBao = '', this.tieuDeThongBao = ''});

  @override
  State<AlertDiaLogThongBao> createState() => _AlertDiaLogThongBaoState();
}

class _AlertDiaLogThongBaoState extends State<AlertDiaLogThongBao> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.cardColor,
      title: Text('Thông báo',
          style: boldTextStyle(
              color: outerSpace)),
      content: Text(
  
        widget.noiDungThongBao,
        style: secondaryTextStyle(
            color: outerSpace),
      ),
      actions: [
        TextButton(
            child: Text(
              "Có",
              style: primaryTextStyle(
                  color: Colors.red),
            ),
            onPressed: () {
             
            }),
        TextButton(
          child: Text("Không",
              style: primaryTextStyle(
                  color: mainColor)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}
