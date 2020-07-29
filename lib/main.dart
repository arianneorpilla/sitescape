import 'package:flutter/material.dart';
import 'package:tfsitescapeweb/pages/root.dart';
import 'package:tfsitescapeweb/services/auth.dart';

import 'services/classes.dart';

Auth userAuth = new Auth();
List<Site> sites = [];

bool isAdmin = false;

String cloudDir = "tfcloud/";

void main() {
  runApp(WebApp());
}

class WebApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sitescape',
      theme: new ThemeData(
          // fontFamily: "Montserrat",
          primaryColor: Color.fromRGBO(58, 65, 120, 1.0),
          visualDensity: VisualDensity.adaptivePlatformDensity),
      home: RootPage(auth: userAuth),
    );
  }
}
