import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

//https://flutterawesome.com/flutter-audio-cutter-package-for-flutter/
//import 'package:flutter_audio_cutter/audio_cutter.dart';

//https://pub.dev/packages/flutter_audio_capture
//import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:path_provider/path_provider.dart';

//https://pub.dev/packages/just_audio
import 'package:just_audio/just_audio.dart';
import 'package:oktoast/oktoast.dart';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

//import 'package:flutter_sound_record/flutter_sound_record.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:easy_folder_picker/FolderPicker.dart';
import 'MessageBus.dart';
import 'Shared.dart';
import 'AudioPlayerUi.dart';

class AudioSegmentManagementUi extends StatefulWidget {
  MessageBus _messageBus;

  AudioSegmentManagementUi(MessageBus msgBus, {super.key})
      : _messageBus = msgBus {}

  @override
  State<StatefulWidget> createState() {
    return AudioSegmentManagementUiState(_messageBus);
  }
}

class AudioSegmentManagementUiState extends State<AudioSegmentManagementUi> {
  MessageBus _messageBus;
  int _currentAudioDuration = 0;
  String _currentAudioPathFile = "";

  var _canManipulateFile = false;

  AudioSegmentManagementUiState(MessageBus msgBus) : _messageBus = msgBus {}

  var _listAudioSegment = <AudioSegmentItem>[
    AudioSegmentItem(),
  ];

  final ScrollController _listViewController = ScrollController();

  var isDisposed = false;

  Map<String, AudioPlayer> _mapAudioPlayer = Map<String, AudioPlayer>();
  Map<String, bool> _mapPlayingAudio = Map<String, bool>();
  Map<String, bool> _mapPausedAudio = Map<String, bool>();

  Future<void> _playAudioFile(String audioIdxKey, String filepath,
      {int? fromMilisec, int? toMilisec}) async {
    if (filepath == "") return;

    if (File(filepath).existsSync() == false) return;

    try {
      var player = _mapAudioPlayer[audioIdxKey];
      if (player == null) {
        player = AudioPlayer();

        final duration = await player.setFilePath(filepath!);
      }

      if (_mapPlayingAudio.containsKey(audioIdxKey)) {
        if (_mapPlayingAudio[audioIdxKey] == false) {
          player = AudioPlayer();
          final duration = await player.setFilePath(filepath!);
        }
      }

      int clipFrom = 0;
      int clipTo = _currentAudioDuration;

      clipFrom = fromMilisec ?? 0;
      clipTo = toMilisec ?? _currentAudioDuration;

      if (fromMilisec != null || toMilisec != null) {
        player.setClip(
            start: Duration(milliseconds: clipFrom),
            end: Duration(milliseconds: clipTo));
      }
      _mapAudioPlayer[audioIdxKey] = player;
      _mapPlayingAudio[audioIdxKey] = true;

      player.play();

      Timer(Duration(milliseconds: clipTo - clipFrom), () async {
        if (_mapPausedAudio.containsKey(audioIdxKey)) {
          if (_mapPausedAudio[audioIdxKey] == false) {
            //todo: calculate remain to stop inneed
          }
        } else {
          //do not press pause so top when hit end of audio
          try {
            _mapAudioPlayer[audioIdxKey]?.stop();
          } catch (ex) {}
          try {
            _mapPlayingAudio[audioIdxKey] = false;
            if (mounted) setState(() {});
          } catch (ex) {}
        }
      });
    } catch (ex) {
      print("_playAudioFile warining");
      print(ex);
    }
    if (this.mounted == true) setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    isDisposed = true;
  }

  @override
  void initState() {
    super.initState();

    _messageBus.Subscribe(
        MessageBus.Channel_CurrentAudio_State, "AudioSegmentManagementUiState",
        (data) async {
      var type = data["type"].toString();

      if (type == "File") {
        _canManipulateFile = true;

        _listAudioSegment = [];
        _mapAudioPlayer.clear();
        _mapPausedAudio.clear();

        _currentAudioPathFile = data["data"].toString();

        var info =
            await MetadataRetriever.fromFile(File(_currentAudioPathFile));
        _currentAudioDuration = info.trackDuration ?? 0;

        _listAudioSegment
            .add(AudioSegmentItem(from: 0, to: _currentAudioDuration));

        if (this.mounted == true) setState(() {});
      }

      if (type == "Duration") {
        _currentAudioDuration = data["data"];
      }

      if (type == "Reset") {
        _canManipulateFile = false;
        _currentAudioPathFile = "Your temp audio file here";
        _currentAudioDuration = 0;
        _listAudioSegment = [AudioSegmentItem()];
        _mapAudioPlayer.clear();
        _mapPlayingAudio.clear();
        _mapPausedAudio.clear();
        if (this.mounted == true) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _canManipulateFile
        ? _buildLayoutView()
        : GestureDetector(
            onTap: () {
              showToast("Please select file or record you voice first");
            },
            child: AbsorbPointer(
                child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                        Color.fromARGB(100, 100, 100, 100),
                        BlendMode.saturation),
                    child: _buildLayoutView())));
  }

  Widget _buildLayoutView() {
    var temp = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
            child: Container(
          padding: const EdgeInsets.fromLTRB(0, 3, 0, 3),
          decoration: const BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(
                color: Colors.black54,
              ),
            ),
            color: Colors.transparent,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildListView()),
              Container(
                padding: const EdgeInsets.fromLTRB(0, 5, 10, 2),
                child: _buildRightTools(),
              )
            ],
          ),
        )),
      ],
    );
    return temp;
  }

  Widget _buildRightTools() {
    var alertReset = _buildAlertReset();
    var alertExport = _buildAlertExport();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ButtonAnimateIconUi(
          toolTipText: "Add line segment",
          inkDecoration: BoxDecoration(
            border: Border.all(
              color: Colors.black87,
              width: 2.0,
            ),
            shape: BoxShape.circle,
            color: Colors.orange,
          ),
          iconFrom: Icons.add_box,
          iconTo: Icons.add,
          iconSize: 24.0,
          onPressed: () async {
            _listAudioSegment.add(AudioSegmentItem());

            if (mounted == true) setState(() {});
            _listViewController.animateTo(
              _listViewController.position.maxScrollExtent + 1000,
              duration: const Duration(seconds: 2),
              curve: Curves.ease,
            );
          },
        ),
        const Text(" "),
        ButtonAnimateIconUi(
          toolTipText: "Export all",
          inkDecoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 2.0),
              shape: BoxShape.circle,
              color: Colors.green),
          iconFrom: Icons.add_to_home_screen,
          iconTo: Icons.arrow_forward,
          iconSize: 32.0,
          onPressed: () async {
            if (_listAudioSegment.any((s) => s.FromMilisec >= s.ToMilisec)) {
              showToast("From must be less than To",
                  duration: const Duration(seconds: 3));
              return;
            }

            showDialog(
              //barrierDismissible: false,
              context: context,
              builder: (ctx) {
                return alertExport;
              },
            );
          },
        ),
        const Text(" "),
        ButtonAnimateIconUi(
          key: UniqueKey(),
          toolTipText: "Reset",
          onPressed: () async {
            showDialog(
              //barrierDismissible: false,
              context: context,
              builder: (ctx) {
                return alertReset;
              },
            );
          },
          iconFrom: Icons.ac_unit,
          iconTo: Icons.access_time,
          inkDecoration: BoxDecoration(
            border: Border.all(color: Colors.orange, width: 2.0),
            color: Colors.redAccent,
            shape: BoxShape.rectangle,
          ),
        )
      ],
    );
  }

  ListView _buildListView() {
    var listView = ListView.builder(
        //key: UniqueKey(),
        controller: _listViewController,
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(10, 2, 0, 2),
        itemCount: _listAudioSegment.length,
        itemBuilder: (BuildContext context, int idx) {
          var data = _listAudioSegment[idx];
          var audioKey = "audio_croped_$idx";
          return Row(
            key: UniqueKey(),
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                child: Text(
                  "$idx",
                  style: TextStyle(
                      backgroundColor:
                          data.PathFile != "" ? Colors.green : null),
                ),
              ),
              Visibility(
                visible: !(_mapPlayingAudio[audioKey] ?? false),
                child: ButtonAnimateIconUi(
                  key: UniqueKey(),
                  toolTipText: "Play audio cropped",
                  onPressed: () async {
                    var dataToPlay = _listAudioSegment[idx];

                    _playAudioFile(audioKey, _currentAudioPathFile,
                        fromMilisec: dataToPlay.FromMilisec,
                        toMilisec: dataToPlay.ToMilisec);

                    if (mounted) setState(() {});
                  },
                  fromMilisec: data.FromMilisec,
                  toMilisec: data.ToMilisec,
                  iconFrom: Icons.play_circle,
                  iconTo: Icons.play_circle_outline,
                ),
              ),
              Visibility(
                visible: (_mapPlayingAudio[audioKey] ?? false),
                child: ButtonAnimateIconUi(
                  key: UniqueKey(),
                  toolTipText: "Stop audio cropped",
                  onPressed: () async {
                    try {
                      _mapAudioPlayer[audioKey]?.stop();
                    } catch (ex) {}
                    try {
                      _mapPlayingAudio[audioKey] = false;
                      if (mounted) setState(() {});
                    } catch (ex) {}
                  },
                  iconFrom: Icons.stop,
                  iconTo: Icons.stop_outlined,
                  fromMilisec: data.FromMilisec,
                  toMilisec: data.ToMilisec,
                ),
              ),
              const Text(" "),
              Flexible(
                child: TextFormFieldUi(
                  validator: (val) {
                    var tempFrom = int.tryParse(val ?? "0") ?? 0;
                    var dataToTest = _listAudioSegment[idx];

                    if (dataToTest.ToMilisec <= tempFrom) {
                      return "From must less than To";
                    }

                    return null;
                  },
                  onChanged: (val) {
                    data.FromMilisec = int.tryParse(val ?? "0") ?? 0;
                    //if (this.mounted) setState(() {});
                  },
                  initialValue: data.FromMilisec.toString(),
                  // controller: TextEditingController(
                  //     text: data.FromMilisec.toString()),
                  decoration: const InputDecoration(
                      //hintText: "From sec",
                      labelText: "From Milisec",
                      border: UnderlineInputBorder()),
                ),
              ),
              const Text("    "),
              const Text("    "),
              Flexible(
                child: TextFormFieldUi(
                  validator: (val) {
                    var tempTo = int.tryParse(val ?? "0") ?? 0;
                    var dataToTest = _listAudioSegment[idx];

                    if (dataToTest.FromMilisec <= tempTo) {
                      return "From must less than To";
                    }
                    return null;
                  },
                  onChanged: (val) {
                    data.ToMilisec = int.tryParse(val ?? "0") ?? 0;
                    //if (this.mounted) setState(() {});
                  },
                  initialValue: data.ToMilisec.toString(),
                  // controller: TextEditingController(
                  //     text: data.ToMilisec.toString()),
                  decoration: const InputDecoration(
                      //hintText: "To sec",
                      labelText: "To Milisec",
                      border: UnderlineInputBorder()),
                ),
              ),
              ButtonAnimateIconUi(
                key: UniqueKey(),
                confirmTitle: Text("Remove line: $idx"),
                confirmContent:
                    Text(" From ${data.FromMilisec} To: ${data.ToMilisec}"),
                iconFrom: Icons.delete_forever,
                iconTo: Icons.delete_forever_outlined,
                iconSize: 24.0,
                onPressed: () async {
                  try {
                    _mapAudioPlayer[audioKey]?.stop();
                  } catch (ex) {}
                  try {
                    _mapPlayingAudio[audioKey] = false;
                  } catch (ex) {}

                  _mapAudioPlayer.remove(audioKey);
                  _mapPlayingAudio.remove(audioKey);
                  _mapPausedAudio.remove(audioKey);
                  _listAudioSegment.remove(_listAudioSegment[idx]);
                  if (mounted) setState(() {});
                },
              ),
            ],
          );
        });

    return listView;
  }

  AlertDialog _buildAlertReset() {
    return AlertDialog(
      key: UniqueKey(),
      title: const Text("Reset all"),
      content: const Text("All segment will clear, you have to do from begin"),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel")),
        TextButton(
            onPressed: () async {
              //showToast("Reset");
              Navigator.pop(context);
              _listAudioSegment = [];

              await Future.delayed(const Duration(milliseconds: 500));

              _messageBus.Publish(MessageBus.Channel_CurrentAudio_State,
                  {"type": "Reset", "data": "", "state": -1});

              if (mounted == true) setState(() {});

              showToast("Reset done", duration: const Duration(seconds: 2));
            },
            child: const Text("Ok - reset")),
      ],
    );
  }

  AlertDialog _buildAlertExport() {
    return AlertDialog(
      key: UniqueKey(),
      title: const Text("Export all"),
      content: const Text("You will pick folder to save"),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel")),
        TextButton(
            onPressed: () async {

              // if(_listAudioSegment.isEmpty){
              //   showToast("No segment to export");
              //   return;
              // }

              Navigator.pop(context);
              Directory dirToSave = await _pickDirectory();

              var fileOrgWav = "$_currentAudioPathFile.wav";
              showToast("Preparing to split");
              await _ffmpeg_m4a_to_wav(_currentAudioPathFile, fileOrgWav);

              var fileNameWithoutExt =
                  _getFileNameWithoutExt(_currentAudioPathFile);

              var dtNow = DateTime.now().toIso8601String().replaceAll(":", "-");
              await Future.delayed(const Duration(milliseconds: 500));
              showToast("Converting ...");

              for (AudioSegmentItem s in _listAudioSegment) {
                double startPoint = s.FromMilisec / 1000;
                double endPoint = s.ToMilisec / 1000;

                var filePathToSave =
                    "${dirToSave.path}/${fileNameWithoutExt} ${dtNow}_${s.FromMilisec}_${s.ToMilisec}.wav";
                //_${s.hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0')

                var result = await _ffmpeg_crop_audio(
                    fileOrgWav, filePathToSave, startPoint, endPoint);

                print(result);

                //showToast(filePathToSave);
                s.PathFile = filePathToSave;

                if (this.mounted == true) setState(() {});

                await Future.delayed(const Duration(milliseconds: 500));
                showToast("-> ${s.FromMilisec} - ${s.ToMilisec}");
              }

              File fileOrg = File(_currentAudioPathFile);
              await fileOrg.copy(
                  "${dirToSave.path}/${_getFileName(_currentAudioPathFile)}");

              //showToast("Saved all to: ${dirToSave.path}");

              _messageBus.Publish(MessageBus.Channel_CurrentAudio_State,
                  {"type": "Reset", "data": "", "state": -1});

              _listAudioSegment = [];
              try {
                await File(_currentAudioPathFile).delete(recursive: true);
              } catch (ex) {}
              try {
                await File(fileOrgWav).delete(recursive: true);
              } catch (ex) {}

              if (this.mounted == true) setState(() {});

              showToast("Export done all to: ${dirToSave.path}",
                  duration: const Duration(seconds: 3));
            },
            child: const Text("Ok - export")),
      ],
    );
  }

  String _getFileName(String filePath) {
    return filePath.replaceAll("\\", "/").split('/').last;
  }

  String _getFileNameWithoutExt(String filePath) {
    var temp = filePath.replaceAll("\\", "/").split('/').last;
    var idx = temp.indexOf(".");
    if (idx > 0) {
      temp = temp.substring(0, idx);
    }
    return temp;
  }

  Future<String?> _ffmpeg_m4a_to_wav(String pathFileOrg, String outPath) async {
    var cmd = "-y -i \"$pathFileOrg\" \"$outPath\"";
    var r = await FFmpegKit.execute(cmd);
    return await r.getAllLogsAsString();
  }

  Future<String?> _ffmpeg_crop_audio(
      String pathFileOrg, String outPath, double start, double end) async {
    if (start < 0 || end < 0) {
      throw ArgumentError('The starting and ending points cannot be negative');
    }
    if (start > end) {
      throw ArgumentError(
          'The starting point cannot be greater than the ending point');
    }
    //final Directory dir = await getTemporaryDirectory();
    //final outPath = "${dir.path}/audio_cutter/output.mp3";
    //await File(outPath).create(recursive: true);

    // var cmd =
    //     "-y -i \"$pathFileOrg\" -vn -ss $start -to $end -ar 16k -ac 2 -b:a 96k -acodec copy $outPath";
    var cmd = "-y -i \"$pathFileOrg\" -ss $start -to $end -c copy \"$outPath\"";

    var r = await FFmpegKit.execute(cmd);

    return await r.getAllLogsAsString();
  }

  Directory? selectedDirectory;

  Future<Directory> _pickDirectory() async {
    Directory directory = selectedDirectory ?? Directory(FolderPicker.rootPath);

    Directory? newDirectory = await FolderPicker.pick(
        allowFolderCreation: true,
        context: context,
        rootDirectory: directory,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))));

    selectedDirectory = newDirectory;

    return newDirectory ?? Directory(FolderPicker.rootPath);
  }
}

//     Expanded(
//       child: SingleChildScrollView(
//           controller: _listViewController,
//           padding: const EdgeInsets.fromLTRB(30, 0, 30, 2),
//           scrollDirection: Axis.vertical,
//           child: Column(
//             children: [
//               Row(children: [
//                 Expanded(
//                   child: SizedBox(
//                     //height: 300.0,
//                     child:
// null
//                   ),
//                 ),
//               ]),
//             ],
//           )),
//     ),
