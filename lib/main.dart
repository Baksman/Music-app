import 'package:flutter/material.dart';
import 'package:mucicapp/music_player/music_player.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
    
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MusicPlayerScreeen(),
    );
  }
}


