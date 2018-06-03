import 'package:flutter/material.dart';
import 'package:speech_recognition/transcriptor.dart';

class SytodyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new SytodyAppState();
}

class SytodyAppState extends State<SytodyApp> {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        body: new TranscriptorWidget(),
      ));
  }
}