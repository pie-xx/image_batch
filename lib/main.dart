import 'dart:io';
import 'dart:typed_data';
import 'dart:isolate';

import 'package:image/image.dart' as imgLib;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'kurukuru.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Batch',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Image Batch'),
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
  String? rotangl;
  TransCmd(this.sendport, this.srcdir, this.dstdir, this.rotangl);
}

class _MyHomePageState extends State<MyHomePage> {

  String srcdir = "";
  String dstdir = "";
  //late Image img = Image.file(File(""), cacheWidth: 80, errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
  //              return const Text('??');
  //            },);
  String current_file = "";
  String _type = "180";

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
          imgLib.Image rotatedImage = imgLib.copyRotate(image, int.parse(cmd.rotangl??"0"));
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
      Kurukuru.msg(context, message);
      if( message=="end"){
        Kurukuru.off(context);
        receivePort.close();
      }
    });

    Isolate.spawn( iso_trans, TransCmd(receivePort.sendPort, srcdir, dstdir, _type) );
  }


  @override
  Widget build(BuildContext context) {
    Text srcdir_box = Text(' $srcdir',style: Theme.of(context).textTheme.bodyText1,);
    Text dstdir_box = Text(' $dstdir',style: Theme.of(context).textTheme.bodyText1,);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: 

        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[   
            Text(' '),   
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(' '),
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
              srcdir_box,
            ],),    
            Text(' '),    
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(' '),
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
              dstdir_box,
            ],), 
            const Divider(
              height: 20,
              thickness: 2,
              indent: 20,
              endIndent: 10,
              color: Colors.blue,
            ),       
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('  rotate angle '),
                Radio(
                  activeColor: Colors.blue,
                  value: '90',
                  groupValue: _type,
                  onChanged: 
                    (v){ setState(() {
                      _type="90";
                    });  },
                ),
                Text('→90'),
                Radio(
                  activeColor: Colors.blue,
                  value: '180',
                  groupValue: _type,
                  onChanged:
                    (v){ setState(() {
                      _type="180";
                    });  },
                ),
                Text('↓180'),
                Radio(
                  activeColor: Colors.blue,
                  value: '270',
                  groupValue: _type,
                  onChanged:
                    (v){ setState(() {
                      _type="270";
                    });  },
                ),
                Text('←270'),
            ],), 
  
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [  
                TextButton(
                  onPressed: ()async{
                    print("$_type");
                    trans();
                  }, 
                  child: Text("start"),
                  style: TextButton.styleFrom( primary: Colors.white, backgroundColor: Colors.red, ),
                ),
                Text(' '),
            Text(current_file)
            ]),
          ],
        )
    );
  }
}
