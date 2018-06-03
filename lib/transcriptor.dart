import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:speech_recognition/recognizer.dart';


class Task {
  int taskId;
  String label;
  bool complete;

  Task({this.taskId, this.label, this.complete = false});
}

class TaskWidget extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;
  final VoidCallback onComplete;

  TaskWidget({this.label, this.onDelete, this.onComplete});

  Widget _buildDissmissibleBackground(
    {Color color,
      IconData icon,
      FractionalOffset align = FractionalOffset.centerLeft}) =>
    new Container(
      height: 42.0,
      color: color,
      child: new Icon(icon, color: Colors.white70),
      alignment: align,
    );

  @override
  Widget build(BuildContext context) {
    return new Container(
      height: 42.0,
      child: new Dismissible(
        direction: DismissDirection.horizontal,
        child: new Align(
          alignment: FractionalOffset.centerLeft,
          child: new Padding(
            padding: new EdgeInsets.all(10.0), child: new Text(label))),
        key: new Key(label),
        background: _buildDissmissibleBackground(
          color: Colors.lime, icon: Icons.check),
        secondaryBackground: _buildDissmissibleBackground(
          color: Colors.red,
          icon: Icons.delete,
          align: FractionalOffset.centerRight),
        onDismissed: (direction) => direction == DismissDirection.startToEnd
          ? onComplete()
          : onDelete()));
  }
}

class TranscriptorWidget extends StatefulWidget {
  @override
  _TranscriptorAppState createState() => new _TranscriptorAppState();
}

class _TranscriptorAppState extends State<TranscriptorWidget> {
  String transcription = '';

  bool authorized = false;

  bool isListening = false;

  List<Task> todos = [];

  bool get isNotEmpty => transcription != '';

  get numArchived => todos.where((t) => t.complete).length;
  Iterable<Task> get incompleteTasks => todos.where((t) => !t.complete);

  @override
  void initState() {
    super.initState();
    SpeechRecognizer.setMethodCallHandler(_platformCallHandler);
    _activateRecognition();
  }

  @override
  void dispose() {
    super.dispose();
    if (isListening) _cancelRecognitionHandler();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    List<Widget> blocks = [
      new Expanded(
          flex: 2,
          child: new ListView(
              children: incompleteTasks
                  .map((t) => _buildTaskWidgets(
                      task: t,
                      onDelete: () => _deleteTaskHandler(t),
                      onComplete: () => _completeTaskHandler(t)))
                  .toList())),
      _buildButtonBar(),
    ];
    if (isListening || transcription != '')
      blocks.insert(
          1,
          _buildTranscriptionBox(
              text: transcription,
              onCancel: _cancelRecognitionHandler,
              width: size.width - 20.0));
    return new Center(
        child: new Column(mainAxisSize: MainAxisSize.min, children: blocks));
  }

  void _saveTranscription() {
    if (transcription.isEmpty) return;
    setState(() {
      todos.add(new Task(
          taskId: new DateTime.now().millisecondsSinceEpoch,
          label: transcription));
      transcription = '';
    });
    _cancelRecognitionHandler();
  }

  Future _startRecognition() async {
    final res = await SpeechRecognizer.start('en_US');
    if (!res)
      showDialog(
          context: context,
          child: new SimpleDialog(title: new Text("Error"), children: [
            new Padding(
                padding: new EdgeInsets.all(12.0),
                child: const Text('Recognition not started'))
          ]));
  }

  Future _cancelRecognitionHandler() async {
    final res = await SpeechRecognizer.cancel();

    setState(() {
      transcription = '';
      isListening = res;
    });
  }

  Future _activateRecognition() async {
    final res = await SpeechRecognizer.activate();
    setState(() => authorized = res);
  }

  Future _platformCallHandler(MethodCall call) async {
    switch (call.method) {
      case "onSpeechAvailability":
        setState(() => isListening = call.arguments);
        break;
      case "onSpeech":
        if (todos.isNotEmpty) if (transcription == todos.last.label) return;
        setState(() => transcription = call.arguments);
        break;
      case "onRecognitionStarted":
        setState(() => isListening = true);
        break;
      case "onRecognitionComplete":
        setState(() {
          if (todos.isEmpty) {
            transcription = call.arguments;
          } else if (call.arguments == todos.last?.label)
            // on ios user can have correct partial recognition
            // => if user add it before complete recognition just clear the transcription
            transcription = '';
          else
            transcription = call.arguments;
        });
        break;
      default:
        print('Unknowm method ${call.method} ');
    }
  }

  void _deleteTaskHandler(Task t) {
    setState(() {
      todos.remove(t);
      _showStatus("cancelled");
    });
  }

  void _completeTaskHandler(Task completed) {
    setState(() {
      todos =
          todos.map((t) => completed == t ? (t..complete = true) : t).toList();
      _showStatus("completed");
    });
  }

  Widget _buildButtonBar() {
    List<Widget> buttons = [
      !isListening
          ? _buildIconButton(authorized ? Icons.mic : Icons.mic_off,
              authorized ? _startRecognition : null,
              color: Colors.white, fab: true)
          : _buildIconButton(Icons.add, isListening ? _saveTranscription : null,
              color: Colors.white,
              backgroundColor: Colors.greenAccent,
              fab: true),
    ];
    Row buttonBar = new Row(mainAxisSize: MainAxisSize.min, children: buttons);
    return buttonBar;
  }

  Widget _buildTranscriptionBox(
          {String text, VoidCallback onCancel, double width}) =>
      new Container(
          width: width,
          color: Colors.grey.shade200,
          child: new Row(children: [
            new Expanded(
                child: new Padding(
                    padding: new EdgeInsets.all(8.0), child: new Text(text))),
            new IconButton(
                icon: new Icon(Icons.close, color: Colors.grey.shade600),
                onPressed: text != '' ? () => onCancel() : null),
          ]));

  Widget _buildIconButton(IconData icon, VoidCallback onPress,
      {Color color: Colors.grey,
      Color backgroundColor: Colors.pinkAccent,
      bool fab = false}) {
    return new Padding(
      padding: new EdgeInsets.all(12.0),
      child: fab
          ? new FloatingActionButton(
              child: new Icon(icon),
              onPressed: onPress,
              backgroundColor: backgroundColor)
          : new IconButton(
              icon: new Icon(icon, size: 32.0),
              color: color,
              onPressed: onPress),
    );
  }

  Widget _buildTaskWidgets(
      {Task task, VoidCallback onDelete, VoidCallback onComplete}) {
    return new TaskWidget(
        label: task.label, onDelete: onDelete, onComplete: onComplete);
  }

  void _showStatus(String action) {
    final label = "Task $action : ${incompleteTasks.length} left "
        "/ ${numArchived} archived";
    Scaffold.of(context).showSnackBar(new SnackBar(content: new Text(label)));
  }
}
