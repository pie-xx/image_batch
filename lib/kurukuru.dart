import 'package:flutter/material.dart';

class Kurukuru {
  static bool onkurukuru = false;
  static String kmsg = "";

  static void on(context, {msg=""}){
    print("kurukuru "+msg); 
    kmsg = msg;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: Duration(milliseconds: 250), // ダイアログフェードインmsec
      barrierColor: Colors.black.withOpacity(0.4), // 画面マスクの透明度
      pageBuilder: (BuildContext context, Animation animation,
          Animation secondaryAnimation) {
        return Center(
            child:Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text( msg,
                  style: TextStyle(
                            fontSize: 18.0,
                            color: Colors.white,
                            decoration: TextDecoration.none),),
                CircularProgressIndicator(), 
              ],                      
          )
        );
      });
    onkurukuru = true;
  }

  static void off(context){
    if( onkurukuru ){
      Navigator.pop(context);
    }
    onkurukuru = false;
  }

  static void msg(context, msg){
    if( msg != kmsg ){
      if( onkurukuru ){
        Navigator.pop(context);
      }
      on(context, msg:msg);
    }
  }
}
