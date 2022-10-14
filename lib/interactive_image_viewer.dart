import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;


class InteractiveImageViewer extends StatefulWidget {
  GlobalKey globalKey = GlobalKey(); 
  Image? img;
  late InteractiveImageState stat;
  Offset? pos;
  late Size imgsize;

  Function on_double_tap = (){};
  Function on_long_press = (){};
  Function on_tap = (){};

  @override
  // ignore: no_logic_in_create_state
  State<InteractiveImageViewer> createState() { 
    stat = InteractiveImageState();
    return stat;
  }
  
////////////////////////////////////////////////////////
  void loadimage(Image dimg, {int? width, int? height}) async {
    img = dimg;
    if( width==null || height==null){
      imgsize = Size(dimg.width??-1,dimg.height??-1);
      if( imgsize.width==-1 || imgsize.height==-1){
        imgsize = await getImageSize(dimg);
      }
    }else{
      imgsize = Size(width.toDouble(),height.toDouble());
    }
    print(imgsize);
    //ignore: invalid_use_of_protected_member
    stat?.setState(() {
  
    });
  }
  
  void loadimageStr(String filename) async {
    loadimage(await Image.file(File(filename)));
  }

  Future<Size> getImageSize(Image image) async {

    final Completer<Size> completer = Completer<Size>();
    image.image.resolve(ImageConfiguration.empty).addListener(
      ImageStreamListener(
            (ImageInfo image, bool synchronousCall) {
          final ui.Image myImage = image.image;
          final Size size = Size(
              myImage.width.toDouble(), myImage.height.toDouble());
          completer.complete(size);
        },
      ),
    );
    return completer.future;
  }

  Size calcBaseSize( double ww, double wh, double iw, double ih ){
    
    double dbaseheight = wh;
    double dbasewidth = (iw * wh / ih);
    if( dbasewidth > ww ){
      dbasewidth = ww;
      dbaseheight = (ww * ih / iw);
    }

    if( ww > iw){
      dbasewidth = iw;
    }
    if( wh > ih) {
      dbaseheight = ih;
    }

    return Size(dbasewidth,dbaseheight);
  }


////////////////////////////////////////////////////////
  Size? getWidgetSize(){
    RenderBox? box = globalKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.size;
  }
  Offset getTapPos(){
    return pos ?? Offset(-1, -1);
  }

  Offset getTapImgPos(){
    Size? ws = getWidgetSize();
    if( ws != null ){
      Size ds = calcBaseSize( ws.width , ws.height, imgsize.width, imgsize.height );

      var wm = (ws.width - ds.width)/2;
      var hm = (ws.height - ds.height)/2;
      var spx = (pos?.dx ?? -1) - wm;
      var spy = (pos?.dy ?? -1) - hm;
      var rpx = (spx*imgsize.width/ds.width);
      var rpy = (spy*imgsize.height/ds.height);
      print("pos $pos imgsize $imgsize");
      print("ws $ws, ds $ds, wm $wm, hm $hm, spx $spx, spy $spy, rpx $rpx, rpy $rpy");
      return Offset(rpx,rpy);
    }
    return Offset(-1,-1);
  }

////////////////////////////////////////////////////////
  void setTransformationValue(Matrix4 mat){
    stat.setTransformationValue(mat);
  }
  Matrix4 getTransformationValue(){
    return stat.getTransformationValue();
  }

////////////////////////////////////////////////////////
  void setPanEnabled(bool en){
    stat?.setState(() {
      stat.panEnabled = en;  
    });
  }
  bool getPanEnabled(){
    return stat.panEnabled;
  }

////////////////////////////////////////////////////////
  void setOnDoubleTap( Function func){
    on_double_tap = func;
  }
  void onDoubleTap(){
    on_double_tap();
  }

  void setOnLongPress( Function func){
    on_long_press = func;
  }
  void onLongPress(){
    on_long_press();
  }

  void setOnTap( Function func){
    on_tap = func;
  }
  void onTap(){
    on_tap();
  }

}


class InteractiveImageState extends  State<InteractiveImageViewer> {

  final _transformationController = TransformationController();

  bool panEnabled = true ;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  void setTransformationValue(Matrix4 mat){
    _transformationController.value = mat;
  }
  Matrix4 getTransformationValue() {
    return _transformationController.value;
  }

  @override
  Widget build(BuildContext context){

    var iviewer = GestureDetector(
      onTapDown: (details) {
        widget.pos = _transformationController.toScene(details.localPosition);        
        print("onTapDown ${widget.pos}");        
      },
      onTap: () {
        print("onTap");
        widget.onTap();        
      },
      onLongPressDown: (details) {
        widget.pos = _transformationController.toScene(details.localPosition);
        print("onLongPressDown ${widget.pos}");        
      },
      onLongPress: () {
        print("onLongPress");
        widget.onLongPress();
      },
      onDoubleTapDown:(details) {
        widget.pos = _transformationController.toScene(details.localPosition);
        print("onDoubleTapDown ${widget.pos}");
      },
      onDoubleTap: () {
        print("onDoubleTap");
        widget.onDoubleTap();
      },
      child:
        InteractiveViewer(
          transformationController: _transformationController,
          onInteractionStart: (details) {
            widget.pos = _transformationController.toScene(details.localFocalPoint);
          },
          onInteractionUpdate: (details) {
            widget.pos = _transformationController.toScene(details.localFocalPoint);
          },

          minScale: 0.1,
          maxScale: 64,
          panEnabled: panEnabled,
          child: 
            Container(
              key: widget.globalKey,
              child:
                Center( child: widget.img ?? Text("No Image")),
            )
    ));

    return iviewer;
  }
}
