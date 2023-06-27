import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import "MessageBus.dart";

class ButtonAnimateIconUi extends StatefulWidget {
  VoidCallback? onPressed;
  int? fromMilisec;
  int? toMilisec;
  double? _iconSize;
  BoxDecoration? _inkDecoration;
  IconData? _iconFrom;
  IconData? _iconTo;
  String? _toolTipText;
  bool? _enable;

  Text? _confirmTitle;
  Text? _confirmContent;

  ButtonAnimateIconUi(
      {VoidCallback? onPressed,
      int? fromMilisec,
      int? toMilisec,
      double? iconSize,
      IconData? iconFrom,
      IconData? iconTo,
      BoxDecoration? inkDecoration,
      String? toolTipText,
      bool? enable,
      Text? confirmTitle,
      Text? confirmContent,
      super.key})
      : this.onPressed = onPressed,
        this.fromMilisec = fromMilisec,
        this.toMilisec = toMilisec,
        _enable = enable {
    _inkDecoration = inkDecoration;
    _iconSize = iconSize;
    if (iconFrom != null && iconTo == null) {
      iconTo = iconFrom;
    }
    if (iconFrom == null && iconTo != null) {
      iconFrom = iconTo;
    }
    _iconFrom = iconFrom ?? Icons.play_arrow;
    _iconTo = iconTo ?? Icons.pause;
    _toolTipText = toolTipText??"Click and see the result";

    _confirmContent = confirmContent;
    _confirmTitle = confirmTitle;
  }

  @override
  State<StatefulWidget> createState() {
    return ButtonAnimateIconUiState(
        onPressed,
        fromMilisec,
        toMilisec,
        _iconSize,
        _iconFrom,
        _iconTo,
        _toolTipText,
        _inkDecoration,
        _enable,
        _confirmTitle,
        _confirmContent);
  }
}

class ButtonAnimateIconUiState extends State<ButtonAnimateIconUi> {
  VoidCallback? _onPressed;
  int? _fromMilisec;
  int? _toMilisec;
  BoxDecoration? _inkDecoration;
  double? _iconSize = 32.0;
  IconData? _iconFrom = Icons.play_arrow;
  IconData? _iconTo = Icons.pause;
  String? _toolTipText;
  bool? _enable;

  ButtonAnimateIconUiState(
      VoidCallback? onPressed,
      int? fromMilisec,
      int? toMilisec,
      double? iconSize,
      IconData? iconFrom,
      IconData? iconTo,
      String? toolTipText,
      BoxDecoration? inkDecoration,
      bool? enable,
      Text? confirmTitle,
      Text? confirmContent)
      : _onPressed = onPressed,
        _enable = enable {
    _fromMilisec = fromMilisec;
    _toMilisec = toMilisec;
    _inkDecoration = inkDecoration;
    _iconSize = iconSize;
    _iconFrom = iconFrom;
    _iconTo = iconTo;
    _toolTipText = toolTipText;

    _confirmContent = confirmContent;
    _confirmTitle = confirmTitle;
  }

  Text? _confirmTitle;
  Text? _confirmContent;

  AlertDialog _buildConfirmWidget() {
    return AlertDialog(
      key: UniqueKey(),
      title: _confirmTitle,
      content: _confirmContent,
      actions: [
        TextButton(
            onPressed: () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text("Cancel")),
        TextButton(
            onPressed: () async {
              //showToast("Reset");
              if (mounted) {
                Navigator.of(context).pop();
                await _doOnPress();
              }
            },
            child: const Text("Confirm")),
      ],
    );
  }

  Future<void> _doOnPress() async {
    try {
      _onPressed!.call();
    } catch (ex) {
      print("ButtonPlayUiState:Error:");
      print(ex);
    }
  }

  var _playState = 0;

  @override
  Widget build(BuildContext context) {
    var confirmBox = _buildConfirmWidget();

    //var btn = ElevatedButton(
    //child:  Icon(_playState == 1 ? _iconTo : _iconFrom),
    var btn = IconButton(
      icon: Icon(_playState == 1 ? _iconTo : _iconFrom),
      iconSize: _iconSize,
      onPressed: (_enable == false)
          ? null
          : () async {
              _playState = 1;
              if (mounted == true) setState(() {});
              await Future.delayed(const Duration(milliseconds: 50));
              if (_confirmTitle == null) {
                await _doOnPress();
              } else {
                showDialog(
                    //barrierDismissible: false,
                    context: context,
                    builder: (ctx) {
                      return confirmBox;
                    });
              }
              await Future.delayed(const Duration(milliseconds: 50));
              _playState = 0;
              if (mounted == true) setState(() {});
            },
    );

    var btnInk = _inkDecoration == null
        ? btn
        : Ink(
            decoration: _buildDisableDecoration(),
            child: btn,
          );

    var toolTipBtnInk = _toolTipText == null
        ? btnInk
        : Tooltip(
            message: _toolTipText,
            child: btnInk,
          );

    return toolTipBtnInk;
  }

  BoxDecoration? _buildDisableDecoration() {
    if (_inkDecoration == null) return null;

    return BoxDecoration(
      border: _inkDecoration?.border,
      backgroundBlendMode: _inkDecoration?.backgroundBlendMode,
      borderRadius: _inkDecoration?.borderRadius,
      boxShadow: _inkDecoration?.boxShadow,
      color: _enable == false
          ? const Color.fromARGB(200, 128, 74, 20)
          : _inkDecoration?.color,
      gradient: _inkDecoration?.gradient,
      image: _inkDecoration?.image,
      shape: _inkDecoration!.shape,
    );
  }
}

class TextFormFieldUi extends StatefulWidget {
  FormFieldValidator? _validator;
  ValueChanged? _onChanged;
  InputDecoration? _decoration;
  String? _initialValue;
  bool? _selectOnFocus;

  TextFormFieldUi(
      {FormFieldValidator? validator,
      ValueChanged? onChanged,
      InputDecoration? decoration,
      String? initialValue,
      bool? selectOnFocus}) {
    _validator = validator;
    _onChanged = onChanged;
    _decoration = decoration;
    _initialValue = initialValue;
    _selectOnFocus = selectOnFocus;
  }

  @override
  State<StatefulWidget> createState() {
    return TextFormFieldUiSate(
        validator: _validator,
        onChanged: _onChanged,
        decoration: _decoration,
        initialValue: _initialValue,
        selectOnFocus: _selectOnFocus);
  }
}

class TextFormFieldUiSate extends State<TextFormFieldUi> {
  FormFieldValidator? _validator;
  ValueChanged? _onChanged;
  InputDecoration? _decoration;
  String? _initialValue;

  final _focusNode = FocusNode();
  TextEditingController? _controller;

  bool _selectOnFocus = true;

  TextFormFieldUiSate(
      {FormFieldValidator? validator,
      ValueChanged? onChanged,
      InputDecoration? decoration,
      String? initialValue,
      bool? selectOnFocus}) {
    _validator = validator;
    _onChanged = onChanged;
    _decoration = decoration;
    _initialValue = initialValue;
    _selectOnFocus = selectOnFocus ?? true;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _controller = TextEditingController(text: _initialValue);
    if (_selectOnFocus) {
      _focusNode.addListener(() {
        if (_focusNode.hasFocus) {
          var text = _controller?.text;
          _controller?.selection = TextSelection(
              baseOffset: 0, extentOffset: text == null ? 0 : text.length);
        }
      });
    }
    return TextFormField(
      validator: _validator,
      onChanged: _onChanged,
      //initialValue: data.ToMilisec.toString(),
      controller: _controller,
      decoration: _decoration,
      focusNode: _focusNode,
    );
  }
}

class AppTimeElapsedUi extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AppTimeElapsedUiState();
  }
}

class AppTimeElapsedUiState extends State<AppTimeElapsedUi> {
  AppTimeElapsedUiState() {}

  DateTime _elapsed = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loopTimeElapsedUsingDequeue();
  }

  @override
  Widget build(BuildContext context) {
    return Text("Time now: ${_elapsed.toIso8601String()}");
  }

  var isDisposed = false;

  @override
  void dispose() {
    super.dispose();
    isDisposed = true;
    print("AppTimeElapsedUiState.dispose: ${DateTime.now()}");
  }

  Timer? _timerAppElapsed;

  Future<void> _loopTimeElapsedUsingDequeue() async {
    var msgBus =
        MessageBus(); //cause singleton can code like this :))) factory constructor
    // while (isDisposed == false) {
    //   var data =
    //       await msgBus.Dequeue<DateTime>(MessageBus.Queue_App_Time_Elapsed);
    //
    //   _elapsed = data ?? _elapsed;
    //
    //   if (mounted) setState(() {});
    //
    //   await Future.delayed(const Duration(microseconds: 1));
    // }

    Timer.periodic(const Duration(milliseconds: 100), (t) async {
      var data =
          await msgBus.Dequeue<DateTime>(MessageBus.Queue_App_Time_Elapsed);

      _elapsed = data ?? _elapsed;

      if (mounted) setState(() {});
    });
  }
}

class AudioSegmentItem {
  AudioSegmentItem({int from = 0, int to = 0, String filepath = ""}) {
    PathFile = filepath;
    FromMilisec = from;
    ToMilisec = to;
  }

  static AudioSegmentItem fromJson(Map<String, dynamic> val) {
    return AudioSegmentItem(
        from: val["FromSec"],
        to: val["ToSec"],
        filepath: val["PathFile"].toString());
  }

  static Map<String, dynamic> toJson(AudioSegmentItem val) {
    return {
      "PathFile": val.PathFile,
      "FromSec": val.FromMilisec,
      "ToSec": val.ToMilisec
    };
  }

  String PathFile = "";
  int FromMilisec = 0;
  int ToMilisec = 0;
}
