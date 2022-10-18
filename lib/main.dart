import 'dart:io';
import 'dart:typed_data';
import 'dart:isolate';

import 'package:image/image.dart' as imgLib;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'kurukuru.dart';
import 'interactive_image_viewer.dart';
import 'package:image_batch/opencv_ffi.dart';

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
  String? sx;
  String? sy;
  String? ex;
  String? ey;
  
  TransCmd(this.sendport, this.srcdir, this.dstdir, this.rotangl, this.sx, this.sy, this.ex, this.ey);
}

class _MyHomePageState extends State<MyHomePage> {

  String srcdir = "";
  String dstdir = "";
  //late Image img = Image.file(File(""), cacheWidth: 80, errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
  //              return const Text('??');
  //            },);
  String current_file = "";
  String _type = "180";

  static OpenCVFFi _openCVffi = OpenCVFFi();

  List<Widget> fis  = [];

  final tcsx = TextEditingController();
  final tcsy = TextEditingController();
  final tcex = TextEditingController();
  final tcey = TextEditingController();


  String curimage = "";
  InteractiveImageViewer iviewer = InteractiveImageViewer();
  int curno=0;
  List<FileSystemEntity>? filelist ;

  static void iso_trans( TransCmd cmd ){
    String _srcdir = cmd.srcdir ?? "";
    String _dstdir = cmd.dstdir ?? "";

    bool bcrop = true;
    int x=0;
    int y=0;
    int w=0;
    int h=0;
    try {
      x = int.parse(cmd.sx??"");
      y = int.parse(cmd.sy??"");
      int ex = int.parse(cmd.ex??"");
      int ey = int.parse(cmd.ey??"");
      w = ex - x;
      h = ey - y;
    }catch(e){
      bcrop = false;
    }

    try{
      List<FileSystemEntity> plist = Directory(_srcdir).listSync();
      plist.sort((a,b) => a.path.compareTo(b.path));
      int count=0;
      for( var p in plist ){
        cmd.sendport?.send( "${++count} / ${plist.length}");
        /*
        Uint8List  _imageData = File(p.path).readAsBytesSync();

        imgLib.Image? image = imgLib.decodeImage(_imageData);
        if( image != null ){
          //cmd.sendport?.send( "${p.path} -> $_dstdir${p.path.substring(_srcdir.length)}");          
          imgLib.Image rotatedImage = imgLib.copyRotate(image, int.parse(cmd.rotangl??"0"));
          if( bcrop ){
            rotatedImage = imgLib.copyCrop(rotatedImage, x, y, w, h);
          }

          Uint8List _rotated_imageData = Uint8List.fromList(imgLib.encodeJpg(rotatedImage));
          File("$_dstdir${p.path.substring(_srcdir.length)}").writeAsBytesSync(_rotated_imageData);
          
          cmd.sendport?.send( "#$_dstdir${p.path.substring(_srcdir.length)}");
        }
        */
        _openCVffi.RotImg(p.path,"$_dstdir${p.path.substring(_srcdir.length)}",int.parse(cmd.rotangl??"0"));
        cmd.sendport?.send( "#$_dstdir${p.path.substring(_srcdir.length)}");
      }
    }catch(e){
      print(e.toString());
      cmd.sendport?.send(e.toString());
    }
    cmd.sendport?.send("end");
  }

  void trans(){
    final ReceivePort receivePort = ReceivePort();
    var start_time = DateTime.now();

    // 通信側からのコールバック
    receivePort.listen(( message ) {
      //setState(() {
      //  current_file = message;
      //});
      //if(message.toString().startsWith("#")){
      //  setState(() {
      //    curimage = message.toString().substring(1);
      //  });
      //}
      Kurukuru.msg(context, message);
      if( message=="end"){
        Kurukuru.off(context);
        receivePort.close();
        var endtime = DateTime.now();

        var dist = endtime.difference(start_time);
        print( dist.toString());
      }
    });

    Isolate.spawn( iso_trans, TransCmd(receivePort.sendPort, srcdir, dstdir, _type,
                                        tcsx.text, tcsy.text, tcex.text, tcey.text) );
  }

  static final List<BottomNavigationBarItem> items = [
        const BottomNavigationBarItem(
          icon: Icon(Icons.start),
          label: "start",
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.zoom_in_map),
          label: "reset",
        ),
  ];

  static String getbasename(String path){
    int bl = path.lastIndexOf("\\");
    int li = path.lastIndexOf("/");
    int sp = 0;
    if( bl > li ){
      sp = bl + 1;      
    }else{
      sp = li + 1;
    }
    return path.substring(sp);
  }

  ListView createListView(String dirname){
    Directory dir = Directory(dirname);
    fis = [];
    int ino = 0;
    filelist = dir.listSync();
    for( FileSystemEntity p in filelist??[]){
      ++ino;
      fis.add(ListTile(
                leading:  Icon(Icons.image),
                title:    Text(getbasename(p.path)),
                subtitle: Text("$ino"),
                selected: curimage==p.path,
                onLongPress: (){ 
                },
                onTap: () async {
                  if( p.statSync().type != FileSystemEntityType.directory) {
                    setState(() {
                      curimage = p.path;
                      curno = ino;
                    });
                  }
                },
              ));
    }

    return ListView(children: fis,);
  }

  int getFno(String fname){
    int fno=0;
    for( FileSystemEntity p in filelist??[]){
      ++fno;
      if( p.path == fname){
        return fno;
      }
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    Text srcdir_box = Text(' $srcdir',style: Theme.of(context).textTheme.bodyText1,);
    Text dstdir_box = Text(' $dstdir',style: Theme.of(context).textTheme.bodyText1,);

    var scwidth = MediaQuery.of(context).size.width;
    var rkBottomNavigationBarHeight = kBottomNavigationBarHeight + 2;
    var scheight = MediaQuery.of(context).size.height - kToolbarHeight -rkBottomNavigationBarHeight -MediaQuery.of(context).padding.top ;

    ListView filelistview = createListView(srcdir);
    if(curimage!=""){
      iviewer.loadimageStr(curimage);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: 
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[   
            SizedBox(
              height: 200,
              child: Column(children: [
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
                      value: '0',
                      groupValue: _type,
                      onChanged: 
                        (v){ setState(() {
                          _type="0";
                        });  },
                    ),
                    Text('0'),
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
            ])),
            /*
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [  
                Text('sx'),
                Container(
                  width: 60.0,
                  child:
                    TextField(
                      controller: tcsx,
                      maxLines: 1,
                    ),
                )
              ]
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [  
                Text('sy'),
                Container(
                  width: 60.0,
                  child:
                    TextField(
                      controller: tcsy,
                      maxLines: 1,
                    )
                ),
                Text('ey'),
                Container(
                  width: 60.0,
                  child:
                    TextField(
                      controller: tcey,
                      maxLines: 1,
                    )
                ),
              ]
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [  
                Text('ex'),
                Container(
                  width: 60.0,
                  child:
                    TextField(
                      controller: tcex,
                      maxLines: 1,
                    )
                ),
              ]
            ),
            */
            Row(children: [
                SizedBox(
                width: scwidth/3,
                height: scheight-200,
                child: filelistview ), 
                Column( children:[
                  SizedBox(
                    height: 32,
                    child: Text("${getFno(curimage)}:${getbasename(curimage)}"),
                  ),
                  SizedBox(
                    width: scwidth*2/3,
                    height: scheight-200-32,
                    child: iviewer
                  ),
                  ]
                ) 
              ],),
              /*
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
            */
          ],
        ),
      bottomNavigationBar:
        SizedBox(
        height: kBottomNavigationBarHeight+2,
        child:
          BottomNavigationBar( 
            items: items,
            onTap:(index) async {  
              switch(index){
                case 0:
                  trans();
                  break;
                case 1:
                default:
                  iviewer.setTransformationValue(Matrix4.identity());
                  break;
              }
            },            
            type: BottomNavigationBarType.fixed,
          )
        )
    );
  }
}
