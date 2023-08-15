import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
//import 'dart:developer';
import 'dart:io';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_scanner_with_effect/qr_scanner_with_effect.dart';
import 'package:http/http.dart' as http;
import 'package:safe_device/safe_device.dart';
import 'package:shared_preferences/shared_preferences.dart';

// void main(){

//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: ExampleScreen(),
//     );
//   }
// }

class QRView extends StatefulWidget {
  const QRView({super.key});

  @override
  State<QRView> createState() => _QRViewState();
}

class _QRViewState extends State<QRView> {
  String lat = "";
  String lng = "";
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  bool isComplete = false;

  void onQrScannerViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      result = scanData;
      controller.pauseCamera();

      await Future<void>.delayed(const Duration(milliseconds: 300));

      String? myQrCode =
          result?.code != null && result!.code.toString().isNotEmpty
              ? result?.code.toString()
              : '';
      if (myQrCode != null && myQrCode.isNotEmpty) {
        //print(myQrCode);
        manageQRData(myQrCode);
      }
    });
  }

  void manageQRData(String myQrCode) async {
    controller?.stopCamera();
    setState(() {
      isComplete = true;
    });
    checkQr(myQrCode);
  }

//location check

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
    if (canMockLocation) {
      return Future.error('Please disable Mock Location');
    }

    return "Success";
  }

//..............location

  Codec<String, String> stringToBase64 = utf8.fuse(base64);
  Future checkQr(String myQrCode) async {
    String url =
        "http://attendance.bsnl.co.in:8080/myOfficeApp_v5/myOffice_flutter.php";

    final sharedPref = await SharedPreferences.getInstance();
    final userPerNo = sharedPref.getString('PERNO');
    var locStat = await determinePosition();
    if (locStat == 'Success') {
      await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high)
          .then((Position position) async {
        //print(position);

        setState(() {
          lat = position.latitude.toString();
          lng = position.longitude.toString();
        });
      });
    }
    // Getting username and password from Controller
    var data = {
      'key': 'HbctZB5WB2QW5dxVxVhsxoIb211',
      'action': 'checkQR',
      'perno': stringToBase64.encode(userPerNo.toString()),
      'qrcode': myQrCode,
      'lat': lat,
      'lng': lng,
    };
//print(lat);
//print(lng);
    String jsonEncoded = json.encode(data);
    var response = await http.post(Uri.parse(url), body: jsonEncoded);
    // print(response.body);
    if (response.statusCode == 200) {
      var resp = jsonDecode(response.body);
      //print(resp);

      if (resp['status'] == "Success") {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop("qrSuccess");
      } else {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop("qrFailed");
      }
    } else if (response.statusCode == 206) {
      var resp = jsonDecode(response.body);
      setState(() {
        // _visible = false;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $resp['msg'] ")),
        );
      });
    } else {}
  }

  @override
  void reassemble() {
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
    super.reassemble();
  }

  @override
  void dispose() {
    controller?.dispose();
    controller?.stopCamera();
    super.dispose();
  }

  void onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    //log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Permission')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan QR Code'),
        ),
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          return QrScannerWithEffect(
            isScanComplete: isComplete,
            qrKey: qrKey,
            onQrScannerViewCreated: onQrScannerViewCreated,
            qrOverlayBorderColor: Colors.redAccent,
            cutOutSize: (MediaQuery.of(context).size.width < 300 ||
                    MediaQuery.of(context).size.height < 400)
                ? 250.0
                : 300.0,
            onPermissionSet: (ctrl, p) => onPermissionSet(context, ctrl, p),
            effectGradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 1],
              colors: [
                Colors.redAccent,
                Colors.redAccent,
              ],
            ),
          );
        }),
      ),
    );
  }
}
