import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;

var val = false;

class SearchEmp extends StatefulWidget {
  const SearchEmp({super.key});

  @override
  State<SearchEmp> createState() => _SearchEmpState();
}

class Album {
  final String img;
  //final int filename;
  final String title;
  final String subtitle;
  final String below;
  final String side;
  final String userid;

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

final userController = TextEditingController();
Future<List<Album>>? searchResult;

class _SearchEmpState extends State<SearchEmp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //backgroundColor: const Color.fromARGB(255, 209, 241, 210),
        appBar: AppBar(
          title: const Text('Search Employees'),
          // This drop down menu demonstrates that Flutter widgets can be shown over the web view.
        ),
        body: Builder(builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  // child: DropdownButtonFormField(
                  //     items: const [DropdownMenuItem(child: Text("child"))],
                  //     onChanged: (value) {}),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          // enabled: _userEnable,
                          controller: userController,
                          //keyboardType: TextInputType.phone,
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
                            labelText: 'Search ',
                            prefixIcon: Icon(
                              Icons.search,
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
                            if (value == null || value.isEmpty) {
                              return 'Please Enter search value';
                            }
                            return null;
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => {
                          FocusScope.of(context).requestFocus(FocusNode()),

                          searchResult = getUsers(userController.text, 'test'),
                          //print(searchResult);
                          setState(() {}),

                          // Validate returns true if the form is valid, or false otherwise.
                          //if (_formKey.currentState!.validate()) {userLogin()}
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              Theme.of(context).primaryColor),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Search',
                            style: TextStyle(fontSize: 18.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Album>>(
                    future: searchResult,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ListView.separated(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Card(
                              child: Column(
                                children: [
                                  ListTile(
                                    title:
                                        Html(data: snapshot.data![index].title),
                                    subtitle: Html(
                                        data: snapshot.data![index].subtitle),
                                    leading: snapshot.data![index].img == ''
                                        ? const CircleAvatar(
                                            child: Icon(
                                            Icons.man,
                                          ))
                                        : Base64Image(
                                            base64Image:
                                                snapshot.data![index].img,
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
                        //return Text(snapshot.error.toString());
                      }
                      // By default show a loading spinner.
                      //return const CircularProgressIndicator();
                      return const CircularProgressIndicator(strokeWidth: 0);
                    },
                  ),
                )
              ],
            ),
          );
        }));
    //MyHomePage(title: 'Demo Login'),
  }

  Future<List<Album>> getUsers(String searchkey, String appKey) async {
//  final sharedPref= await SharedPreferences.getInstance();
//     myPerNo = sharedPref.getString("PERNO");
//     myName = sharedPref.getString("EMPNAME");
    // print(myPerNo);

    final Map<String, String> data = ({
      'key': 'HbctZB5WB2QW5dxVxVhsxoIb211',
      'action': 'searchEmployee',
      'searchKey': searchkey,
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
      // print(response.body);

      if (response.statusCode == 200) {
        // If the call to the server was successful, parse the JSON.
        List jsonResponse = json.decode(response.body);
        val = true;
        //print(jsonResponse);
        return jsonResponse.map((data) => Album.fromJson(data)).toList();
      } else if (response.statusCode == 207) {
        throw Exception('Logged in another device');
      } else {
        // If that call was not successful, throw an error.
        throw Exception('Network Error');
      }
    } on Exception catch (_) {
      // make it explicit that this function can throw exceptions
      //rethrow;
      throw Exception('Network Error');
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
