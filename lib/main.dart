import 'dart:io';
import 'dart:typed_data';
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

class _MyHomePageState extends State<MyHomePage> {

  String srcdir = "";
  String dstdir = "";
  //late Image img = Image.file(File(""), cacheWidth: 80, errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
  //              return const Text('??');
  //            },);

  void trans(){
    
    try{
      List<FileSystemEntity> plist = Directory(srcdir)?.listSync() ?? [];
      plist.sort((a,b) => a.path.compareTo(b.path));
      for( var p in plist ){
        Uint8List  _imageData = File(p.path).readAsBytesSync();
        imgLib.Image? image = imgLib.decodeImage(_imageData);
        if( image != null ){
          print( "${p.path} -> $dstdir${p.path.substring(srcdir.length)}");
          imgLib.Image rotatedImage = imgLib.copyRotate(image, 180);
          Uint8List _rotated_imageData = Uint8List.fromList(imgLib.encodeJpg(rotatedImage));
          File("$dstdir${p.path.substring(srcdir.length)}").writeAsBytesSync(_rotated_imageData);
        }
      }
    }catch(e){
      print(e);
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
          ],
        ),
      ),
    );
  }
}
