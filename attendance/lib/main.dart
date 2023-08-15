import 'dart:async';

import 'package:flutter/material.dart';
//import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:connectivity_plus/connectivity_plus.dart';

late SharedPreferences sharedPreferences;
late StreamSubscription subscription;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPreferences = await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Office',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color.fromRGBO(165, 154, 2, 1),
        hintColor: Colors.orange[600],
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      home: const ScreenSplash(),
      //MyHomePage(title: 'Demo Login'),
    );
  }
}
