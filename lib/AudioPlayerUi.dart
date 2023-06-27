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

class AudioPlayerUi extends StatefulWidget {
  final MessageBus _messageBus;
  final String _currentAudioPathFile;

  AudioPlayerUi(MessageBus msgBus, String currentAudioPathFile, {super.key})
      : _messageBus = msgBus,
        _currentAudioPathFile = currentAudioPathFile {}

  @override
  State<StatefulWidget> createState() {
    return AudioPlayerUiState(_messageBus, _currentAudioPathFile);
  }
}

class AudioPlayerUiState extends State<AudioPlayerUi> {
  final MessageBus _messageBus;
  int _currentAudioDuration = 0;
  final String _guidText_RecordToFile =
      "Your temp audio file here, click Select or Record";
  String _currentAudioPathFile = "";
  var _canManipulateFile = false;

  AudioPlayerUiState(MessageBus msgBus, String currentAudioPathFile)
      : _messageBus = msgBus,
        _currentAudioPathFile = currentAudioPathFile {
    _currentAudioPathFile = _guidText_RecordToFile;
  }

  final Map<String, AudioPlayer> _mapAudioPlayer = Map<String, AudioPlayer>();
  final Map<String, bool> _mapPlayingAudio = Map<String, bool>();
  final Map<String, bool> _mapPausedAudio = Map<String, bool>();

  Future<void> _playAudioFile(String audioIdxKey, String filepath,
      {int? fromMilisec, int? toMilisec}) async {
    if (filepath == "") return;

    if (File(filepath).existsSync() == false) return;

    print("AudioPlayerUiState audioIdxKey: $audioIdxKey");
    print("AudioPlayerUiState filepath: $filepath");

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

      Timer(Duration(milliseconds: clipTo), () async {
        if (_mapPausedAudio.containsKey(audioIdxKey)) {
          if (_mapPausedAudio[audioIdxKey] == false) {
            //todo: calculate remain to stop inneed
            if (_mapPlayingAudio[audioIdxKey] == true) {
              var currentPos =
                  _mapAudioPlayer[audioIdxKey]?.position?.inMilliseconds ?? 0;
              if (currentPos >= clipTo) {
                await _doStop();
              }
            }
          }
        } else {
          //do not press pause so top when hit end of audio
          await _doStop();
        }
      });
    } catch (ex) {
      print("_playAudioFile warining");
      print(ex);
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted == true) setState(() {});
  }

  var isDisposed = false;

  @override
  void dispose() {
    super.dispose();
    isDisposed = true;
  }

  @override
  void initState() {
    super.initState();
    MetadataRetriever.fromFile(File(_currentAudioPathFile)).then((info) {
      _currentAudioDuration = info.trackDuration ?? 0;
    });

    _messageBus.Subscribe(
        MessageBus.Channel_CurrentAudio_State, "AudioPlayerUiState",
        (data) async {
      var type = data["type"].toString();

      if (type == "File") {
        _mapPlayingAudio.clear();
        _mapAudioPlayer.clear();
        _mapPausedAudio.clear();
        _currentAudioPathFile = data["data"].toString();

        var info =
            await MetadataRetriever.fromFile(File(_currentAudioPathFile));

        _currentAudioDuration = info.trackDuration ?? 0;
        _canManipulateFile = true;

        _playAudioFile(_currentAudioPathFile, _currentAudioPathFile);
        if (mounted) setState(() {});
      }

      if (type == "Duration") {
        _currentAudioDuration = data["data"];
      }

      if (type == "Reset") {
        _canManipulateFile = false;
        _currentAudioPathFile = _guidText_RecordToFile;
        _currentAudioDuration = 0;
        _mapAudioPlayer.clear();
        _mapPlayingAudio.clear();
        _mapPausedAudio.clear();
        if (mounted == true) setState(() {});
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
                    Color.fromARGB(100, 100, 100, 100), BlendMode.saturation),
                child: _buildLayoutView(),
              ),
            ),
          );
  }

  Widget _buildLayoutView() {
    var temp = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
              color: Color.fromARGB(255, 253, 170, 63),
              border: Border.symmetric(
                  horizontal: BorderSide(color: Colors.black54))),
          child: Text(
            "$_currentAudioPathFile",
            style: const TextStyle(color: Colors.black45),
          ),
        ),
        Container(
          color: Colors.transparent,
          padding: const EdgeInsets.fromLTRB(0, 3, 0, 3),
          child: _buildCurrentPlayer(),
        ),
      ],
    );
    return temp;
  }

  bool _isEnableBtnPlay() {
    if (_mapPlayingAudio[_currentAudioPathFile] == null) return true;
    if (_mapPlayingAudio[_currentAudioPathFile] == false) {
      return true;
    } else {
      if (_mapPausedAudio[_currentAudioPathFile] == null) return false;
      if (_mapPausedAudio[_currentAudioPathFile] == true) {
        return true;
      } else {
        return false;
      }
    }
  }

  bool _isEnableBtnPause() {
    if (_mapPlayingAudio[_currentAudioPathFile] == null) return false;
    if (_mapPlayingAudio[_currentAudioPathFile] == true) {
      if (_mapPausedAudio[_currentAudioPathFile] == null) {
        return true;
      }
      if (_mapPausedAudio[_currentAudioPathFile] == false) {
        return true;
      }
    }
    return false;
  }

  Future<void> _doPlay() async {
    _playAudioFile(_currentAudioPathFile, _currentAudioPathFile);
    if(_mapPausedAudio.containsKey(_currentAudioPathFile))
    {
      _mapPausedAudio[_currentAudioPathFile] = false;
    }
    _mapPlayingAudio[_currentAudioPathFile] = true;
    if (mounted) setState(() {});
  }

  Future<void> _doPause() async {
    if (_mapPlayingAudio[_currentAudioPathFile] == true) {
      try {
        await _mapAudioPlayer[_currentAudioPathFile]?.pause();
      } catch (ex) {}
      try {
        _mapPausedAudio[_currentAudioPathFile] = true;
      } catch (ex) {}
      if (mounted) setState(() {});
    }
  }

  Future<void> _doStop() async {
    _mapAudioPlayer.remove(_currentAudioPathFile);
    _mapPausedAudio.remove(_currentAudioPathFile);
    try {
      if(_mapPlayingAudio.containsKey(_currentAudioPathFile))
      {
        _mapPlayingAudio[_currentAudioPathFile] = false;
      }
      if (mounted) setState(() {});
    } catch (ex) {}
    try {
      _mapAudioPlayer[_currentAudioPathFile]?.stop();
    } catch (ex) {}
  }

  Row _buildCurrentPlayer() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 3, 0),
          padding: const EdgeInsets.fromLTRB(3, 0, 3, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Total: "),
              Text(
                  "$_currentAudioDuration ms\r\n${_currentAudioDuration / 1000} s")
            ],
          ),
        ),
        ButtonAnimateIconUi(
          enable: _isEnableBtnPlay(),
          key: UniqueKey(),
          toolTipText: "Play current audio",
          onPressed: () async {
            await _doPlay();
          },
          iconSize: 32.0,
          iconFrom: Icons.play_arrow,
          iconTo: Icons.play_arrow_outlined,
          inkDecoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 2.0),
            color: Colors.orangeAccent,
            shape: BoxShape.circle,
          ),
        ),
        const Text(" "),
        AbsorbPointer(
          absorbing: !(_mapPlayingAudio[_currentAudioPathFile] ?? true),
          child: ButtonAnimateIconUi(
            key: UniqueKey(),
            enable: _isEnableBtnPause(),
            toolTipText: "Pause current audio",
            onPressed: () async {
              await _doPause();
            },
            iconSize: 32.0,
            iconFrom: Icons.pause_circle,
            iconTo: Icons.pause,
            inkDecoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 2.0),
              color: Colors.orangeAccent,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const Text(" "),
        ButtonAnimateIconUi(
          key: UniqueKey(),
          enable: (_mapPlayingAudio[_currentAudioPathFile] ?? false),
          toolTipText: "Stop current audio",
          inkDecoration: BoxDecoration(
              border: Border.all(
                color: Colors.black87,
                width: 2.0,
              ),
              shape: BoxShape.circle,
              color: Colors.orange),
          iconFrom: Icons.stop,
          iconTo: Icons.stop_outlined,
          iconSize: 24.0,
          onPressed: () async {
            await _doStop();
          },
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(5, 0, 0, 0),
          padding: const EdgeInsets.fromLTRB(3, 0, 3, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "${_mapPausedAudio[_currentAudioPathFile] == true ? "Paused" : "${_mapAudioPlayer[_currentAudioPathFile]?.playing == true ? "Playing" : "Stoped"}"}"),
              AudioPlayerShowProgressUi(
                _mapAudioPlayer[_currentAudioPathFile],
                _messageBus,
                key: UniqueKey(),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class AudioPlayerShowProgressUi extends StatefulWidget {
  final AudioPlayer? _audioPlayer;
  MessageBus? _messageBus;

  AudioPlayerShowProgressUi(AudioPlayer? audioPlayer, MessageBus? messageBus,
      {super.key})
      : _audioPlayer = audioPlayer {
    _messageBus = messageBus;
  }

  @override
  State<StatefulWidget> createState() {
    return AudioPlayerShowProgressUiState(_audioPlayer, _messageBus);
  }
}

class AudioPlayerShowProgressUiState extends State<AudioPlayerShowProgressUi> {
  AudioPlayer? _audioPlayer;
  MessageBus? _messageBus;
  int? _currentRecordDuration;
  int _currentPositions = 0;

  AudioPlayerShowProgressUiState(
      AudioPlayer? audioPlayer, MessageBus? messageBus) {
    _audioPlayer = audioPlayer;
    _messageBus = messageBus;
  }

  @override
  void initState() {
    super.initState();

    _messageBus!.Subscribe(
        MessageBus.Channel_CurrentAudio_State, "AudioPlayerShowProgressUiState",
        (data) async {
      var type = data["type"].toString();
      if (type == "Duration") {
        _currentRecordDuration = data["data"];

        if (mounted) setState(() {});
      }
      if (type == "File") {
        _currentRecordDuration = null;
      }
    });

    _loopShowCurrentPlayerPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_getCurrentPlayerPosition());
  }

  var isDisposed = false;

  @override
  void dispose() {
    super.dispose();
    isDisposed = true;
  }

  Future<void> _loopShowCurrentPlayerPosition() async {
    Timer.periodic(const Duration(milliseconds: 100), (t) async {
      try {
        if (_audioPlayer != null) {
          if (mounted) setState(() {});
        }
      } finally {}
    });
    // while (!isDisposed) {
    //   try {
    //     if (_audioPlayer != null) {
    //       _currentPositions = _audioPlayer?.position?.inMilliseconds ?? 0;
    //       if (mounted) setState(() {});
    //     }
    //   } finally {
    //     await Future.delayed(const Duration(milliseconds: 100));
    //   }
    // }
  }

  String _getCurrentPlayerPosition() {
    if (_currentRecordDuration != null) {
      return "${_currentRecordDuration} ms\r\n${_currentRecordDuration! / 1000} s ... recording";
    }
    _currentPositions = _audioPlayer?.position?.inMilliseconds ?? 0;

    return "${_currentPositions} ms\r\n${_currentPositions / 1000} s";
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
