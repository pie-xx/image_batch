import 'dart:io';
import 'dart:typed_data';
import 'dart:isolate';

import 'package:image/image.dart' as imgLib;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class TransCmd {
  SendPort? sendport;
  String? srcdir;
  String? dstdir;
  TransCmd(this.sendport, this.srcdir, this.dstdir);
}

class _MyHomePageState extends State<MyHomePage> {

  String srcdir = "";
  String dstdir = "";
  //late Image img = Image.file(File(""), cacheWidth: 80, errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
  //              return const Text('??');
  //            },);
  String current_file = "";

  static void iso_trans( TransCmd cmd ){
    String _srcdir = cmd.srcdir ?? "";
    String _dstdir = cmd.dstdir ?? "";

    try{
      List<FileSystemEntity> plist = Directory(_srcdir).listSync();
      plist.sort((a,b) => a.path.compareTo(b.path));
      int count=0;
      for( var p in plist ){
        cmd.sendport?.send( "${++count} / ${plist.length}");
        Uint8List  _imageData = File(p.path).readAsBytesSync();
        imgLib.Image? image = imgLib.decodeImage(_imageData);
        if( image != null ){
          //cmd.sendport?.send( "${p.path} -> $_dstdir${p.path.substring(_srcdir.length)}");          
          imgLib.Image rotatedImage = imgLib.copyRotate(image, 180);
          Uint8List _rotated_imageData = Uint8List.fromList(imgLib.encodeJpg(rotatedImage));
          File("$_dstdir${p.path.substring(_srcdir.length)}").writeAsBytesSync(_rotated_imageData);
        }
      }
    }catch(e){
      print(e.toString());
      cmd.sendport?.send(e.toString());
    }
    cmd.sendport?.send("end");
  }

  void trans(){
    final ReceivePort receivePort = ReceivePort();

    // 通信側からのコールバック
    receivePort.listen(( message ) {
      //setState(() {
      //  current_file = message;
      //});
      kurukuru_msg(context, message);
      if( message=="end"){
        kurukuruOff(context);
        receivePort.close();
      }
    });

    Isolate.spawn( iso_trans, TransCmd(receivePort.sendPort, srcdir, dstdir) );
  }

  static bool onkurukuru = false;
  static String kmsg = "";

  static void kurukuru(context, {msg=""}){
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

  static void kurukuruOff(context){
    if( onkurukuru ){
      Navigator.pop(context);
    }
    onkurukuru = false;
  }

  static void kurukuru_msg(context, msg){
    if( msg != kmsg ){
      if( onkurukuru ){
        Navigator.pop(context);
      }
      kurukuru(context, msg:msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    Text srcdir_box = Text('$srcdir',style: Theme.of(context).textTheme.headline4,);
    Text dstdir_box = Text('$dstdir',style: Theme.of(context).textTheme.headline4,);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[   
            Column(children: [
              srcdir_box,
              TextButton(
                onPressed: ()async{
                  var res = await FilePicker.platform.getDirectoryPath();
                  setState(() {
                    srcdir = res ?? "";
                  });
                }, 
                child: Text("src"),
                style: TextButton.styleFrom( backgroundColor: Colors.orange, ),
              ),
            ],),        
            Column(children: [
              dstdir_box,
              TextButton(
                onPressed: ()async{
                  var res = await FilePicker.platform.getDirectoryPath();
                  setState(() {
                    dstdir = res ?? "";
                  });
                }, 
                child: Text("dst"),
                style: TextButton.styleFrom( backgroundColor: Colors.orange, ),
              ),
            ],),        
            TextButton(
              onPressed: ()async{
                trans();
              }, 
              child: Text("go"),
              style: TextButton.styleFrom( backgroundColor: Colors.red, ),
            ),
            //img
            Text(current_file)
          ],
        ),
      ),
    );
  }
}
