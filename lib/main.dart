import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audio_cutter/MessageBus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

// https://pub.dev/packages/microphone
import 'package:microphone/microphone.dart';

//https://stackoverflow.com/questions/70241682/flutter-audio-trim
//import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
//import 'package:baseflow_plugin_template/baseflow_plugin_template.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:oktoast/oktoast.dart';
import 'MicrecorderUi.dart';
import 'AudioSegmentManagementUi.dart';
import "MessageBus.dart";
import 'Shared.dart';
import 'AudioPlayerUi.dart';
import 'package:ffi/ffi.dart';
import 'dart:ffi' as ffi;
import 'package:path/path.dart' as path;
import 'dart:io' show Platform, Directory;

// FFI signature of the hello_world C function
typedef HelloWorldFunc = ffi.Void Function();
// Dart type definition for calling the C foreign function
typedef HelloWorld = void Function();

// C sum function - int sum(int a, int b);
//
// Example of how to pass parameters into C and use the returned result
typedef SumFunc = ffi.Int32 Function(ffi.Int32 a, ffi.Int32 b);
typedef Sum = int Function(int a, int b);

Future<void> testFfi() async{
  print("Begin test ffi");
  // Open the dynamic library
  var libraryPath =
  path.join(Directory.current.path, 'helloclang', 'libhello.so');

  if (Platform.isMacOS) {
    libraryPath =
        path.join(Directory.current.path, 'helloclang', 'libhello.dylib');
  }

  if (Platform.isWindows) {
    libraryPath = path.join(
        Directory.current.path, 'helloclang', 'Debug', 'hello.dll');
  }

  //flutter
  libraryPath="libhello.so";

  //load by use build.gradle externalNativeBuild
  final dylib = ffi.DynamicLibrary.open(libraryPath);

  // // load by manual copy to folder android/src/main/jniLibs
  //todo: got error here, may build .so wrong way
  //final dylib1 = ffi.DynamicLibrary.open("libsimpleso.so");
  /*ERR
  /flutter (15498): [ERROR:flutter/runtime/dart_vm_initializer.cc(41)] Unhandled Exception: Invalid argument(s): Failed to load dynamic library 'libsimpleso.so': dlopen failed: library "libc.so.6" not found
E/flutter (15498): #0      _open (dart:ffi-patch/ffi_dynamic_library_patch.dart:11:43)
E/flutter (15498): #1      new DynamicLibrary.open (dart:ffi-patch/ffi_dynamic_library_patch.dart:22:12)
  * */

  // Look up the C function 'hello_world'
  final HelloWorld hello = dylib
      .lookup<ffi.NativeFunction<HelloWorldFunc>>('hello_world')
      .asFunction();
  // Call the function
  hello();

  final sumPointer = dylib.lookup<ffi.NativeFunction<SumFunc>>('sum');
  final sum = sumPointer.asFunction<Sum>();
  print('3 + 5 = ${sum(3, 5)}');

  print("End test ffi");
}

Future<void> main() async {
  await testFfi();
  MessageBus(); //singleton instance
  runApp(MyAppUi());
}

class MyAppUi extends StatefulWidget {
  MyAppUi({super.key});

  @override
  State<StatefulWidget> createState() {
    return MyAppUiState();
  }
}

class MyAppUiState extends State<MyAppUi> {
  MessageBus _messageBus;

  bool _canManipulateFile = false;
  var _currentAudioPathFile = "You audio file here";

  MyAppUiState() : _messageBus = MessageBus() {}

  var isDisposed = false;

  @override
  void dispose() {
    super.dispose();
    //todo: consider use this.mounted
    isDisposed = true;
  }

  @override
  void initState() {
    super.initState();

    //_messageBus.debug_loopStatistic();

    _messageBus.Subscribe(MessageBus.Channel_CurrentAudio_State, "MyAppUiState",
        (data) async {
      var type = data["type"].toString();

      if (type == "File") {
        _canManipulateFile = true;
        _currentAudioPathFile = data["data"].toString();
      }
      if (type == "State") {}
      if (type == "Reset") {
        _canManipulateFile = false;
      }
    });

    //_loopTimeElapsedUsingQueue();
  }

  Future<void> _loopTimeElapsedUsingQueue() async {
    // while (isDisposed == false) {
    //   await _messageBus.Enqueue<DateTime>(
    //       MessageBus.Queue_App_Time_Elapsed, DateTime.now());
    //   await Future.delayed(const Duration(milliseconds: 1));
    // }
    Timer.periodic(const Duration(milliseconds: 100), (t) async {
      await _messageBus.Enqueue<DateTime>(
          MessageBus.Queue_App_Time_Elapsed, DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
      [
        //Permission.bluetooth,
        //Permission.location,
        //Permission.accessNotificationPolicy,
        Permission.notification,
        Permission.mediaLibrary,
        Permission.microphone,
        //Permission.manageExternalStorage,
        Permission.storage,
        //add more permission to request here.
      ].request().then((statuses) async {
        var isDenied =
            statuses.values.any((p) => (p.isDenied || p.isPermanentlyDenied
                //||
                //p.isLimited ||
                //p.isRestricted
                ));
        if (isDenied) {
          showToast(
              "You have allow access microphone and storage, quiting ..." +
                  "\r\n\r\nIf you see message again and again should re-install application" +
                  "\r\nThen allow permission to access microphone and storage",
              duration: const Duration(seconds: 5),
              textAlign: TextAlign.left);
          await Future.delayed(const Duration(seconds: 5));
          try {
            if (mounted) Navigator.of(context).pop();
          } catch (ex) {}
          try {
            if (mounted) SystemNavigator.pop();
          } catch (ex) {}
        }
      });
    }

    return MaterialApp(
        builder: (_, Widget? child) => OKToast(child: child!),
        home: Scaffold(
          // resizeToAvoidBottomInset: false,
          body: SafeArea(
              child: Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.black)),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                  //margin: EdgeInsets.fromLTRB(0, 0, 0, 5),
                  child: MicrecorderUi(_messageBus),
                ),
                Container(
                  color: Colors.transparent,
                  child: AudioPlayerUi(
                    _messageBus,
                    _currentAudioPathFile,
                    key: UniqueKey(),
                  ),
                ),
                Expanded(
                  child: AudioSegmentManagementUi(_messageBus),
                ),
              ],
            ),
          )),
        ));
  }
}

class TestAsyncAwait {
  Future<bool> nau_nuoc() async {
    try {
      await Future.delayed(const Duration(seconds: 5));
      return true;
    } catch (ex) {
      return false;
    }
  }

  Future<bool> cat_gia_vi() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (ex) {
      return false;
    }
  }

  Future<bool> cat_rau() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (ex) {
      return false;
    }
  }

  Future<bool> bo_my() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (ex) {
      return false;
    }
  }

  Future<bool> tron_deu() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (ex) {
      return false;
    }
  }

  Future<void> run() async {
    var dtsart = DateTime.now();
    print(dtsart);
    var step1 = nau_nuoc(); //var step1= await nau_nuoc();
    var step2 = cat_gia_vi(); // neu de await tung` line 1 thi
    var step3 = cat_rau(); // se ko phai la dong thoi
    var step4 = bo_my();

    // var listWaitAll=[step1,step2,step3,step4];
    // for(var t in listWaitAll){
    //   await t;
    // }
    //sau khi start concurrent het cac job
    // //-> done all task can thi moi dc tron_deu de an
    var res = await Future.wait([step1, step2, step3, step4]);

    if (res.any((element) => element == false)) {
      print("Error");
    } else {
      var step5 = await tron_deu();
      print("done");
    }
    var dtstop = DateTime.now();
    print(dtstop);
    print(dtstop.millisecondsSinceEpoch - dtsart.millisecondsSinceEpoch);
  }
}
