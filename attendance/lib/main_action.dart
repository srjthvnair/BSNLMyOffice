import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
//import 'dart:js';

import 'package:http/http.dart' as http;
//import 'package:myoffice/qr.dart';
import 'package:myoffice/qrscan.dart';
import 'package:myoffice/search_emp.dart';
import 'package:myoffice/webview.dart';
import 'package:safe_device/safe_device.dart';
//import 'package:myoffice/search_emp.dart';
//import 'package:safe_device/safe_device.dart';
//import 'package:safe_device/safe_device.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'login.dart';
//import 'webview.dart';
//import 'package:myoffice/splash.dart';

//import 'package:myoffice/webview.dart';
import 'package:geolocator/geolocator.dart';
//import 'package:permission_handler/permission_handler.dart';

Future<List<Markings>>? _futureMarkings;
final navigatorKey = GlobalKey<NavigatorState>();
dynamic myPerNo;
dynamic myName;
bool dist = false;
bool fabQrVisible = true;
bool fabMarkVisible = true;
bool hasInternet = false;
var _perNumber;
var empName;
var markMethods;

class Album {
  final String img;
  //final int filename;
  final String title;
  final String subtitle;
  final String below;
  final String side;
  final int userid;

  const Album({
    required this.img,
    required this.side,
    required this.title,
    required this.subtitle,
    required this.below,
    required this.userid,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      img: json['img'],
      side: json['side'],
      title: json['title'],
      subtitle: json['subtitle'],
      below: json['below'],
      userid: json['userid'],
    );
  }
}

class Markings {
  //final int filename;
  final String office;
  final dynamic distance;
  final String randno;
  final String perno;
  final String tag;
  final String atttype;
  final List shift;
  final String duration;
  final String msg;
  const Markings({
    //required this.filename,
    required this.office,
    required this.distance,
    required this.randno,
    required this.perno,
    required this.tag,
    required this.atttype,
    required this.shift,
    required this.duration,
    required this.msg,
  });

  factory Markings.fromJson(Map<String, dynamic> json) {
    return Markings(
      office: json['office'],
      distance: json['distance'],
      randno: json['randno'],
      perno: json['perno'],
      tag: json['tag'],
      atttype: json['atttype'],
      shift: json['shift'],
      duration: json['duration'],
      msg: json['msg'],
    );
  }
}

sinOut(BuildContext context) async {
  final sharedPref = await SharedPreferences.getInstance();
  await sharedPref.clear();

  // ignore: use_build_context_synchronously
  Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (ctx1) => const ScreenLogin(),
      ),
      (route) => false);
}

// ----------------user showing first page
Future<List<Album>> getUsers(String action, String userid, String empName,
    String appKey, context) async {
//  final sharedPref= await SharedPreferences.getInstance();
//     myPerNo = sharedPref.getString("PERNO");
//     myName = sharedPref.getString("EMPNAME");
  // print(myPerNo);

  try {
    final Map<String, String> data = ({
      'key': 'HbctZB5WB2QW5dxVxVhsxoIb211',
      'action': action,
      'userid': userid,
      'appkey': appKey
      //'reqfrom':'first',
    });

    final jsonEncoded = json.encode(data);

    try {
      final response = await http.post(
          Uri.parse(
              "http://attendance.bsnl.co.in:8080/myOfficeApp_v5/myOffice_flutter.php"),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncoded);
      // print(response.statusCode);

      if (response.statusCode == 200) {
        // If the call to the server was successful, parse the JSON.
        List jsonResponse = json.decode(response.body);
        //print(jsonResponse);
        return jsonResponse.map((data) => Album.fromJson(data)).toList();
      } else if (response.statusCode == 207) {
        sinOut(context);
        throw 'Logged in another device';
      } else {
        // If that call was not successful, throw an error.
        throw 'Network Error';
      }
    } on Exception catch (_) {
      // make it explicit that this function can throw exceptions
      rethrow;
    }
  } on SocketException {
    Fluttertoast.showToast(
      msg: 'Error: No Internet',
      backgroundColor: Colors.grey,
    );
    throw Exception('No Internet');
  } on HttpException {
    throw ('No Service Found');
  } on FormatException {
    throw ('Invalid Data Format');
  } catch (e) {
    //throw UnknownException(e.message);
    throw ("No Nearby Office");
  }
}
//--------------------user for first page

class MyAppAction extends StatefulWidget {
  const MyAppAction({super.key});

  @override
  State<MyAppAction> createState() {
    return _MyAppActionState();
  }
}

dynamic locationStatus;

class _MyAppActionState extends State<MyAppAction> {
  //final TextEditingController _controller = TextEditingController();
  InternetStatus? _connectionStatus;
  late StreamSubscription<InternetStatus> _subscription;
  Future<List<Album>>? futureAlbum;
  Future<List<Album>> getLocalData() async {
    final sharedPref = await SharedPreferences.getInstance();
    _perNumber = sharedPref.getString('PERNO');
    empName = sharedPref.getString('EMPNAME');
    var appKey = sharedPref.getString('APPKEY');
//print(myPerNo);
//final myName= sharedPref.getInt('EMPNAME');
    // ignore: use_build_context_synchronously
    return getUsers(
        'getFrontPageMessage', _perNumber!, empName!, appKey!, context);
  }

  @override
  void initState() {
    super.initState();
    _subscription = InternetConnection().onStatusChange.listen((status) {
      setState(() {
        _connectionStatus = status;
      });
    });
    initFirst();
    final listener =
        InternetConnection().onStatusChange.listen((InternetStatus status) {
      switch (status) {
        case InternetStatus.connected:
          // The internet is now connected
          refreshPage();

          break;
        case InternetStatus.disconnected:
          // The internet is now disconnected
          break;
      }
    });
    listener.cancel();
  }

  @override
  void dispose() {
    _subscription.cancel();

    super.dispose();
  }

  void initFirst() async {
    //final sharedPref = await SharedPreferences.getInstance();

    setState(() {
      //var empName = sharedPref.getString('EMPNAME');

      futureAlbum = getLocalData();
    });
  }

  void refreshPage() async {
    setState(() {
      futureAlbum = getLocalData();
    });
  }

  //Position? _currentPosition;
  Future<dynamic> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    bool canMockLocation = await SafeDevice.canMockLocation;
    if (!canMockLocation) {
      setState(() {
        locationStatus = "Success";
      });
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disable Mock Location')),
      );
    }
    return "Success";
    // // When we reach here, permissions are granted and we can
    // // continue accessing the position of the device.
//   await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high)
//       .then((Position position) async {
//       //print(position);
// bool canMockLocation = await SafeDevice.canMockLocation;
//  //bool isDevelopmentModeEnable = await SafeDevice.isDevelopmentModeEnable;
//   print(canMockLocation );
//  //print(isDevelopmentModeEnable);
//      setState(()  {
//       locationStatus ="Success";
//   //    // _currentPosition = position;
//   //    //print(perNo);

//   //     //   showPop(sfoldKey);

//   //  //

//      });
//      return "Success";
//   }).catchError((e) {
//     return e;
//   });
  }

  // final  _pages=[
  //   const MyApp(),
  //   const WebViewApp() ];

  void showPop(navigatorKey) {
    //  final formKey = GlobalKey<FormState>();
    //final context = navigatorKey.currentState.overlay.context;
    late dynamic shiftSelected;
    showDialog(
        barrierDismissible: false,
        //context: scaffoldKey.currentContext,
        context: navigatorKey.currentContext,
        builder: (BuildContext ctx) {
          return AlertDialog(
            //title: Text('Marking Attendance'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  //overflow: Overflow.visible,

                  children: <Widget>[
                    Positioned(
                      // right: -40.0,
                      // top: -40.0,
                      child: InkResponse(
                        onTap: () {
                          Navigator.of(ctx).pop();
                        },
                        child: const CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close),
                        ),
                      ),
                    ),
                    Form(
                      //  key: formKey,

                      child: Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: FutureBuilder(
                          future: _futureMarkings,
                          builder: (BuildContext context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.deepPurpleAccent,
                                ),
                              );
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              if (snapshot.hasError) {
                                // return Center(
                                //   child: Text(
                                //     'Error: $snapshot.error',
                                //     style: const TextStyle(
                                //         fontSize: 12, color: Colors.red),
                                //   ),
                                // );
                              } else if (snapshot.hasData) {
                                final data = snapshot.data;
                                return Center(
                                    child: Column(
                                  children: <Widget>[
                                    for (var item in data!)
                                      Column(children: <Widget>[
                                        Text(
                                            "You are ${item.distance} away from ${item.office}"),
                                        Text("Total Time : ${item.duration}"),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: DropdownButtonFormField(
                                            hint: const Text("Select Shift"),
                                            //value: item.shift[0],
                                            items: item.shift.map((e) {
                                              return DropdownMenuItem(
                                                  value: e, child: Text(e));
                                            }).toList(),
                                            onChanged: (value) {
                                              shiftSelected = value;
                                            },
                                          ),
                                        ),
                                        Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  TextButton(
                                                    child: const Text("Cancel"),
                                                    onPressed: () {
                                                      // if (_formKey.currentState.validate()) {
                                                      //   _formKey.currentState.save();
                                                      // }
                                                      Navigator.of(ctx).pop();
                                                    },
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            item.atttype == "IN"
                                                                ? Colors.purple
                                                                : Colors.red,
                                                        padding:
                                                            const EdgeInsets
                                                                    .symmetric(
                                                                horizontal: 10,
                                                                vertical: 5),
                                                        textStyle:
                                                            const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                    child: Text(
                                                        "Mark ${item.atttype}"),
                                                    onPressed: () {
                                                      // print(item.distance);
                                                      var postData =
                                                          json.encode({
                                                        'perno': item.perno
                                                            .toString(),
                                                        'tag': item.tag,
                                                        'randno': item.randno,
                                                        'office': item.office,
                                                        'distance': item
                                                            .distance
                                                            .toString()
                                                      });
                                                      postAttendance(
                                                          postData,
                                                          shiftSelected,
                                                          markMethods,
                                                          ctx);
                                                    },
                                                  ),
                                                ]))
                                      ]),
                                  ],
                                ));
                              }
                            }

                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
  }

  Future<bool> _onBackPressed() async {
    // exit(0);
    //SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    // Navigator.of(context).pop(true);
    //return false;
    if (Platform.isAndroid) {
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    } else {
      // MinimizeApp.minimizeApp();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    //var _scaffoldKey = GlobalKey<ScaffoldState>();

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'My Office',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
          //key: _scaffoldKey,

          appBar: AppBar(
            title: Column(
              children: [
                const Text('My Office', style: TextStyle(fontSize: 16)),
                Text("$empName", style: const TextStyle(fontSize: 12))
              ],
            ),
            leading: IconButton(
              onPressed: () {},
              icon: Image.asset("assets/images/bsnl-logo.jpeg"),
            ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(
                  Icons.search,
                  color: Colors.white,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
                ),
                onPressed: () {
                  sinOut(context);
                },
              )
            ],
          ),
          body: SafeArea(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              child: FutureBuilder<List<Album>>(
                future: futureAlbum,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.separated(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          child: Column(
                            children: [
                              ListTile(
                                title: Html(data: snapshot.data![index].title),
                                subtitle: Text(snapshot.data![index].subtitle),
                                leading: snapshot.data![index].img == ''
                                    ? const CircleAvatar(
                                        child: Icon(
                                        Icons.man,
                                      ))
                                    : Base64Image(
                                        base64Image: snapshot.data![index].img,
                                      ),
                                trailing: Text(snapshot.data![index].side),
                              ),
                              Html(data: snapshot.data![index].below),

                              //Text(snapshot.data![index].below)
                            ],
                          ),
                        );

                        // return Container(
                        //   height: 75,
                        //   color: Colors.white,
                        //   child: Center(
                        //     child: Text(snapshot.data![index].title),
                        //   ),
                        // );
                      },
                      separatorBuilder: (context, index) {
                        return const Divider();
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  }
                  // By default show a loading spinner.
                  return const CircularProgressIndicator();
                },
              ),
            ),
          ),
          floatingActionButton: Builder(
            builder: (BuildContext context) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Visibility(
                    visible: fabQrVisible,
                    child: FloatingActionButton(
                      heroTag: "btnQr",
                      tooltip: 'Scan QR code',
                      backgroundColor: Colors.lightGreen,
                      onPressed: () async {
                        //  showPop(_scaffoldKey);
                        if (_connectionStatus == InternetStatus.connected) {
                          //print("Connected");
                          if (dist) {
                            var qrResult = await Navigator.of(context)
                                .push(MaterialPageRoute(
                              builder: (context) => const QRView(),
                            ));

                            // child: const Text('qrView'),
                            if (qrResult == 'qrSuccess') {
                              await Geolocator.getCurrentPosition(
                                      desiredAccuracy: LocationAccuracy.high)
                                  .then((Position position) async {
                                //print(position);

                                //setState(()  {
                                _futureMarkings = getMarkingInfo(
                                    'getMarkingInfo',
                                    _perNumber.toString(),
                                    position.latitude.toString(),
                                    position.longitude.toString(),
                                    'QR',
                                    context);

                                // });
                                setState(() {
                                  _futureMarkings = _futureMarkings;
                                  showPop(navigatorKey);
                                });
                              });
                            } else {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Wrong QR Code ")),
                              );
                            }
                          } else {
                            Fluttertoast.showToast(
                              msg: 'No Nearby Office',
                              backgroundColor: Colors.grey,
                            );
                          }
                        } else {
                          //print("Not Connected");
                          Fluttertoast.showToast(
                            msg: 'No Internet Connection',
                            backgroundColor: Colors.grey,
                          );
                        }
                      },
                      child: const Icon(Icons.qr_code),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Visibility(
                    visible: fabMarkVisible,
                    child: FloatingActionButton(
                      heroTag: "btnAtt",
                      tooltip: 'Mark Attendance',
                      backgroundColor: Colors.orange,
                      onPressed: () async {
                        setState(() {
                          fabQrVisible = true;
                          fabMarkVisible = true;
                        });
                        if (_connectionStatus == InternetStatus.connected) {
                          //print("Connected");

                          locationStatus = "";
                          await determinePosition();

                          // print(locationStatus);
                          if (locationStatus == "Success") {
                            await Geolocator.getCurrentPosition(
                                    desiredAccuracy: LocationAccuracy.high)
                                .then((Position position) async {
                              // print(position);
                              _futureMarkings = getMarkingInfo(
                                  'getMarkingInfo',
                                  _perNumber.toString(),
                                  position.latitude.toString(),
                                  position.longitude.toString(),
                                  'APP',
                                  context);
                              if (dist) {
                                setState(() {
                                  _futureMarkings = _futureMarkings;
                                  showPop(navigatorKey);
                                  fabQrVisible = true;
                                  fabMarkVisible = true;
                                });
                              } else {
                                Fluttertoast.showToast(
                                  msg: 'No Nearby Office',
                                  backgroundColor: Colors.grey,
                                );
                              }
                            });
                          }
                        } else {
                          Fluttertoast.showToast(
                            msg: 'No Internet Connection',
                            backgroundColor: Colors.grey,
                          );
                        }
                      },
                      //else {
                      //print("Not Connected");
                      // Fluttertoast.showToast(
                      //   msg: 'No Internet Connection',
                      //   backgroundColor: Colors.grey,
                      // );
                      // }

                      // print(scaffoldKey);

                      child: const Icon(Icons.fingerprint),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              );
            },
          ),

          bottomNavigationBar: BottomNavigationBar(
            onTap: (value) {
              if (value == 1) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const WebViewExample(),
                ));
              } else if (value == 2) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SearchEmp(),
                ));
              }
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: "Reports",
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.search), label: "Search"),
            ],
          ),
        ),
      ),
    );
  }

  Codec<String, String> stringToBase64 = utf8.fuse(base64);

  Future<List<Markings>> getMarkingInfo(String action, String userid,
      String lat, String lng, String methods, context) async {
    final sharedPref = await SharedPreferences.getInstance();
    _perNumber = sharedPref.getString('PERNO');
    empName = sharedPref.getString('EMPNAME');
    var appkey = sharedPref.getString('APPKEY');
    final Map<String, String> data = ({
      'key': 'HbctZB5WB2QW5dxVxVhsxoIb211',
      'action': action,
      'userid': stringToBase64.encode(userid),
      'lat': lat,
      'lng': lng,
      'methods': methods,
      'appkey': appkey.toString(),
    });
    //print(appkey);
    // print(userid);
    final jsonEncoded = json.encode(data);
    try {
      final response = await http.post(
          Uri.parse(
              "http://attendance.bsnl.co.in:8080/myOfficeApp_v5/myOffice_flutter.php"),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncoded);
      //print(lat);
      //print(response.body);
      var resp = json.decode(response.body);

      if (response.statusCode == 200) {
        // If the call to the server was successful, parse the JSON.
        //print(json.decode(response.body));

        List jsonResponseM = json.decode(response.body);
        //print(json.decode(stringToBase64.decode(jsonResponseM[0]['dataout']) ));

        List jsonDecoded =
            json.decode(stringToBase64.decode(jsonResponseM[0]['dataout']));
        //print(jsonResponseM);
        dist = true;

        return jsonDecoded.map((data) => Markings.fromJson(data)).toList();
      } else if (response.statusCode == 206) {
        dist = false;
        //var resp = json.decode(response.body);
        //print("${resp['msg']}");
        // ignore: use_build_context_synchronously
        Fluttertoast.showToast(
          msg: "${resp['msg']}",
          backgroundColor: Colors.grey,
        );
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text("Error : ${resp['msg']}")),
        // );
        // If that call was not successful, throw an error.
        throw Exception(resp['msg']);
      } else if (response.statusCode == 207) {
        sinOut(context);
        Fluttertoast.showToast(
          msg: "${resp['msg']}",
          backgroundColor: Colors.grey,
        );
        // If that call was not successful, throw an error.
        throw "Logged in another mobile";
      } else {
        Fluttertoast.showToast(
          msg: "${resp['msg']}",
          backgroundColor: Colors.grey,
        );
        // If that call was not successful, throw an error.
        throw Exception('Network Error');
      }
    } on SocketException {
      Fluttertoast.showToast(
        msg: 'No Internet Connection',
        backgroundColor: Colors.grey,
      );
      throw Exception('No Internet');
    } on HttpException {
      Fluttertoast.showToast(
        msg: "Http Exception",
        backgroundColor: Colors.grey,
      );
      throw ('No Service Found');
    } on FormatException {
      Fluttertoast.showToast(
        msg: "Unknown Forma",
        backgroundColor: Colors.grey,
      );
      throw ('Invalid Data Format');
    } catch (e) {
      //throw UnknownException(e.message);
      throw ("UnKnown Exception");
    }
  }

  Future postAttendance(postData, shift, methods, ctx) async {
    late String latd;
    late String long;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      latd = position.latitude.toString();
      long = position.longitude.toString();
    });

    //print(postData);
    //print(shift);
    //print(methods);
    Navigator.of(ctx).pop();

    String url =
        "http://attendance.bsnl.co.in:8080/myOfficeApp_v5/myOffice_flutter.php";
    var data = {
      'key': 'HbctZB5WB2QW5dxVxVhsxoIb211',
      'action': 'appPostAttendance',
      'postdata': stringToBase64.encode(postData),
      'shift': shift,
      'lat': latd,
      'lng': long,
      'versionCode': '6',
      'versionName': '6.0.0',
      'pushid': 'xx'
    };

    try {
      var response = await http.post(Uri.parse(url), body: json.encode(data));
      // print(response.body);
      // print(response.statusCode);
      if (response.statusCode == 200) {
        var resp = jsonDecode(response.body);

        if (resp['status'] == "Success") {
          // print(resp);
          refreshPage();
        } else {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error:")), // $resp['status'] ")),
          );
        }
      } else if (response.statusCode == 206) {
        dist = false;
        //var resp = jsonDecode(response.body);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: ")), //$resp['status'] ")),
        );
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Some thing went wrong")),
        );
      }
    } on SocketException {
      Fluttertoast.showToast(
        msg: 'Error: No Internet',
        backgroundColor: Colors.grey,
      );
      //netAvail = false;
      throw Exception('No Internet');
    } on HttpException {
      throw ('No Service Found');
    } on FormatException {
      throw ('Invalid Data Format');
    } catch (e) {
      //throw UnknownException(e.message);
      throw ("Network Error");
    }
  }
}

class Base64Image extends StatelessWidget {
  final String base64Image;

  const Base64Image({super.key, required this.base64Image});

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      base64Decode(base64Image),
      fit: BoxFit.cover,
    );
  }
}
