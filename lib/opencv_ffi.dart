import 'dart:io';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';


class OpenCVFFi {
  
  late DynamicLibrary  dylib ;
  late String outjpg;

  String filter_name = "NON";
  static List<String> filter_list = [];

  late Pointer<Uint32> s;
  late Pointer<Uint32> w;
  late Pointer<Uint32> h;
  late Pointer<Uint32> cr;
  late Pointer<Uint32> cg;
  late Pointer<Uint32> cb;

  int imgwidth=0;
  int imgheight=0;

  OpenCVFFi(){

    s = malloc.allocate(1);
    w = malloc.allocate(1);
    h = malloc.allocate(1);

    dylib = Platform.isAndroid
      ? DynamicLibrary.open("OpenCV_ffi.so")
      : DynamicLibrary.open("OpenCVProc.dll");
    if(Platform.isAndroid){
      dylib = DynamicLibrary.open("OpenCV_ffi.so");
    }
    if(Platform.isWindows){
      dylib = DynamicLibrary.open("OpenCVProc.dll");
    }
    if(Platform.isIOS){
      dylib = DynamicLibrary.process();
    }
  }

  void RotImg( String infile, String outfile, int rotangle ) {
    final outPath = outfile.toNativeUtf8().cast<Uint8>();
    final inPath = infile.toNativeUtf8().cast<Uint8>();
    try {
      s[0] = rotangle;

      final dllfunc = dylib.lookupFunction<
        Void Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint32>, Pointer<Uint32>),
        void Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint32>, Pointer<Uint32>)
        >("RotImg");

      dllfunc(inPath, outPath, s, w);

    }catch(e){
      print(e.toString());
    }
  }
}
