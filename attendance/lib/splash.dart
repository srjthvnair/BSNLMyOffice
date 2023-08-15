//import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:sqflite/sqflite.dart';

import 'login.dart';
import 'main_action.dart';
//import 'package:safe_device/safe_device.dart';

class ScreenSplash extends StatefulWidget {
  const ScreenSplash({super.key});

  @override
  State<ScreenSplash> createState() => _ScreenSplashState();
}

class _ScreenSplashState extends State<ScreenSplash> {
  @override
  void initState() {
    checkUserLogedIn();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/BharatFibre.gif',
          width: 100,
        ),
      ),
    );
  }

  @override
  void dispose() => super.dispose();

  Future goToLogin() async {
    // final subscription = Connectivity()
    //     .onConnectivityChanged
    //     .listen((ConnectivityResult result) {
    //   if (result == ConnectivityResult.mobile ||
    //       result == ConnectivityResult.wifi) {
    //     // reload here

    //     setState(() {
    //       const ScreenSplash();
    //     });
    //   }
    // });
    // bool canMockLocation = await SafeDevice.canMockLocation;
    //if(canMockLocation){
    //  showMessage("Please Disable Mock Location");
    // }else{
    await Future.delayed(const Duration(seconds: 1));
    // ignore: use_build_context_synchronously
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (ctx) => const ScreenLogin()));
    // }
  }

  Future<dynamic> showMessage(String msg) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(msg),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> checkUserLogedIn() async {
    final sharedPref = await SharedPreferences.getInstance();
    final userPerNo = sharedPref.getString('PERNO');
    if (userPerNo == null || userPerNo == "") {
      goToLogin();
    } else {
//var db = await openDatabase('myOffice_local.db');

      await Future.delayed(const Duration(seconds: 1));
      // ignore: use_build_context_synchronously
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (ctx) => const MyAppAction()));
    }
  }
}
