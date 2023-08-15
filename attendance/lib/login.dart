import 'dart:convert';
//import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
//import 'package:uuid/uuid_util.dart';

import 'main_action.dart';

class ScreenLogin extends StatelessWidget {
  const ScreenLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MY Office',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color.fromRGBO(128, 3, 145, 1),
        hintColor: const Color.fromARGB(255, 251, 192, 0),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(title: 'MY Office'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //For LinearProgressIndicator.
  bool _visible = false;
  bool _otpVisible = false;
  bool _otpSubmit = false;

  bool _userSubmit = true;
  bool _userEnable = true;

  //Textediting Controller for Username and Password Input
  final userController = TextEditingController();
  final pwdController = TextEditingController();
  late String perNoReceived;
  late String otpCoded;
  late String empNameReceived;
  late String mobNoReceived;

  Codec<String, String> stringToBase64 = utf8.fuse(base64);

//-----------userUpdate-------------

  Future userUpdate(perno, uname, mobno) async {
    String url =
        "http://attendance.bsnl.co.in:8080/myOfficeApp_v5/myOffice_flutter.php";
    var uuid = const Uuid();
    String uid = uuid.v4();
    //print(uid);
    var data = {
      'key': 'HbctZB5WB2QW5dxVxVhsxoIb211',
      'action': 'userUpdate',
      'uid': stringToBase64.encode(perno),
      'uname': uname,
      'appkey': uid,
      'deviceid': 'xx',
      'versionCode': '6',
      'versionName': '6.0.0',
      'pushid': 'xx'
    };

    var response = await http.post(Uri.parse(url), body: json.encode(data));
    //print(response.body);
    // print(response.statusCode);
    if (response.statusCode == 200) {
      var resp = jsonDecode(response.body);

      if (resp['status'] == "Success") {
        saveLocal(perno, uname, mobno, uid);
      } else {
        showMessage(resp["msg"]);
      }
    } else if (response.statusCode == 206) {
      var resp = jsonDecode(response.body);

      showMessage(resp["msg"]);
    } else {
      showMessage("Error during connecting to Server.");
    }
  }

//-----------user update end

  Future userLogin() async {
    //Login API URL
    //use your local IP address instead of localhost or use Web API
    //String url = "http://192.168.1.6:80/Attendance/user_login.php";
    //String url = "http://127.0.0.1:80/Attendance/user_login.php";
    String url =
        "http://attendance.bsnl.co.in:8080/myOfficeApp_v5/myOffice_flutter.php";

    // Showing LinearProgressIndicator.
    setState(() {
      _visible = true;
    });

    // Getting username and password from Controller
    var data = {
      'key': 'HbctZB5WB2QW5dxVxVhsxoIb211',
      'action': 'validateUser',
      'userid': userController.text,
      'reqfrom': 'first'
    };

    var response = await http.post(Uri.parse(url), body: json.encode(data));
    // print(response.body);
    // print(response.statusCode);
    if (response.statusCode == 200) {
      var resp = jsonDecode(response.body);

      if (resp['status'] == "Success") {
        setState(() {
          perNoReceived = resp['msg']['perno'].toString();
          empNameReceived = resp['msg']['empname'].toString();
          mobNoReceived = resp['msg']['mobno'].toString();
          otpCoded = resp['msg']['otpcoded'];
          _visible = false;
          _otpVisible = true;
          _userSubmit = false;
          _otpSubmit = true;
          _userEnable = false;
        });
      } else {
        setState(() {
          _visible = false;
          showMessage(resp["msg"]);
        });
      }
    } else if (response.statusCode == 206) {
      var resp = jsonDecode(response.body);
      setState(() {
        _visible = false;
        showMessage(resp["msg"]);
      });
    } else {
      setState(() {
        _visible = false;
        showMessage("Error during connecting to Server.");
      });
    }
  }

  Future<void> saveLocal(perno, name, mobno, appkey) async {
    final sharedPref = await SharedPreferences.getInstance();
    sharedPref.setString('PERNO', perno);
    sharedPref.setString('EMPNAME', name);
    sharedPref.setString('MOBNO', mobno);
    sharedPref.setString('APPKEY', appkey);

    if (sharedPref.getString('PERNO') != null) {
      // ignore: use_build_context_synchronously
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const MyAppAction(),
      ));
    } else {
      setState(() {
        //hide progress indicator

        _otpVisible = false;
        _userSubmit = true;
        _otpSubmit = false;
        _userEnable = true;
      });
    }
  }

  // ignore: no_leading_underscores_for_local_identifiers
  Future<dynamic> showMessage(String _msg) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_msg),
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

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // Fluttertoast.showToast(
    //   msg: 'App Developed and Maintained by BSNL Kerala Circle',
    //   backgroundColor: Colors.grey,
    //   fontSize: 10,
    // );
    return SafeArea(
        child: Scaffold(
      bottomNavigationBar: const BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // Optional
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly, // Change to your own spacing
          children: [
            Text(
              "App Developed and Maintained by BSNL Kerala Circle",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              " ",
              style: TextStyle(fontSize: 60, color: Colors.white),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.center,
          //crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(
              height: 150,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset("assets/images/myofficelogo.png"),
            ),

            // Container(
            //   height: 100.0,
            // ),
            // Icon(
            //   Icons.group,
            //   color: Theme.of(context).primaryColor,
            //   size: 80.0,
            // ),
            // SizedBox(
            //   height: 10.0,
            // ),
            // Text(
            //   'Login Here',
            //   style: TextStyle(
            //       color: Theme.of(context).primaryColor,
            //       fontSize: 25.0,
            //       fontWeight: FontWeight.bold),
            // ),
            // SizedBox(
            //   height: 40.0,
            // ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 8,
                child: Column(
                  children: [
                    Visibility(
                      visible: _visible,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10.0),
                        child: const LinearProgressIndicator(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Theme(
                              data: ThemeData(
                                primaryColor:
                                    const Color.fromRGBO(67, 79, 92, 0.498),
                                primaryColorDark:
                                    const Color.fromRGBO(84, 87, 90, 0.5),
                                hintColor: const Color.fromRGBO(
                                    84, 87, 90, 0.5), //placeholder color
                              ),
                              child: TextFormField(
                                enabled: _userEnable,
                                controller: userController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromRGBO(84, 87, 90, 0.5),
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromRGBO(84, 87, 90, 0.5),
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromARGB(255, 244, 146, 54),
                                      width: 1.0,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  labelText: 'Enter Mobile Number',
                                  prefixIcon: Icon(
                                    Icons.phone,
                                    color: Color.fromRGBO(84, 87, 90, 0.5),
                                  ),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromRGBO(84, 87, 90, 0.5),
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  //hintText: 'Mobile Number',
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty ||
                                      !RegExp(r'^[6-9]\d{9}$')
                                          .hasMatch(value)) {
                                    return 'Please Enter a valid Mobile Number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(
                              height: 20.0,
                            ),
                            Visibility(
                              visible: _userSubmit,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                  onPressed: () => {
                                    // Validate returns true if the form is valid, or false otherwise.
                                    if (_formKey.currentState!.validate())
                                      {userLogin()}
                                  },
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Theme.of(context).primaryColor),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text(
                                      'Get OTP',
                                      style: TextStyle(fontSize: 18.0),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: _otpVisible,
                              child: TextFormField(
                                controller: pwdController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromRGBO(84, 87, 90, 0.5),
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromRGBO(84, 87, 90, 0.5),
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromARGB(218, 107, 199, 1),
                                      width: 1.0,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  labelText: 'Enter O T P',
                                  prefixIcon: Icon(
                                    Icons.message,
                                    color: Color.fromRGBO(84, 87, 90, 0.5),
                                  ),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromRGBO(84, 87, 90, 0.5),
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  //hintText: 'O T P',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter OTP';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            Visibility(
                              visible: _otpSubmit,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                  onPressed: () => {
                                    setState(() {
                                      _otpSubmit = false;
                                      var webOtp = int.parse(
                                              stringToBase64.decode(otpCoded)) -
                                          357899568;
                                      //print(webOtp);
                                      if (webOtp.toString() ==
                                          pwdController.text) {
                                        userUpdate(perNoReceived,
                                            empNameReceived, mobNoReceived);
                                      } else {
                                        _otpSubmit = true;
                                        showMessage("Wrong OTP");
                                      }
                                    }),

                                    // Validate returns true if the form is valid, or false otherwise.
                                    //if (_formKey.currentState!.validate()) {userLogin()}
                                  },
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Theme.of(context).primaryColor),
                                  ),
                                  child: const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'Login',
                                        style: TextStyle(fontSize: 18.0),
                                      )),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Center(
            // Align(
            //   alignment: Alignment.bottomCenter,
            //   child: Text(
            //     "App Developed and Maintained by BSNL Kerala Circle",
            //     style: TextStyle(fontSize: 10, color: Colors.grey),
            //   ),
            // )
            // const SizedBox(height: 250),
            // const Padding(
            //   padding: EdgeInsets.all(10.0),
            //   child: Column(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     crossAxisAlignment: CrossAxisAlignment.center,
            //     mainAxisSize: MainAxisSize.min,
            //     children: <Widget>[
            // ElevatedButton(
            //   style: ButtonStyle(backgroundColor:Colors.white),
            //   onPressed: null,

            //child:

            // Text(
            //   'App Developed and Maintained by BSNL Kerala Circle',
            //   style: TextStyle(fontSize: 10, color: Colors.grey),
            // ),

            // ElevatedButton(
            //   //style: style,
            //   onPressed: () {},
            //   child: const Text('Enabled'),
            //),
            //],
            //),
            //)
          ],
        ),
      ),
    ));
  }
}
