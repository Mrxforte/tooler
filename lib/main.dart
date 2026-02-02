import 'package:flutter/material.dart';
import 'package:tooler/views/main/main_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tooler app',
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
