import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:device_preview/device_preview.dart' as dp;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';

import 'package:tfsitescape/pages/root.dart';
import 'package:tfsitescape/services/auth.dart';
import 'package:tfsitescape/services/classes.dart';
import 'package:tfsitescape/services/util.dart';

// Background image persistent in the app.
ImageProvider bgImage = AssetImage('images/login.jpg');
Directory extDir;
String photosPath;
Directory tempDir;
String cloudDir = "tfcloud/";
String cloudThumbDir = "tfthumb/";
DatabaseReference dbRef = FirebaseDatabase.instance.reference().child("sites");

String appName;
String packageName;
String version;
String buildNumber;
String versionAndBuild;

CameraDescription cam;
List<Site> sites;
double userLat;
double userLong;

Auth userAuth = new Auth();

/* App execution starts here. */
Future<void> main() async {
  // Wait for camera and other things to get ready.
  SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  WidgetsFlutterBinding.ensureInitialized();

  List<CameraDescription> cameras = await availableCameras();
  cam = cameras.first;

  PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
    appName = packageInfo.appName;
    packageName = packageInfo.packageName;
    version = packageInfo.version;
    buildNumber = packageInfo.buildNumber;
    versionAndBuild = "v" + version + "-" + buildNumber;
  });
  // Pre-cache the login image so it doesn't pop.
  extDir = await getExternalStorageDirectory();
  photosPath = await ExtStorage.getExternalStorageDirectory() + "/Sitescape";
  tempDir = await getTemporaryDirectory();

  await loadImage('images/login.jpg');
  await loadLocalSites();

  // Run the application.
  SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: Colors.black.withOpacity(0.4)));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(
      TFApp(),
      //  dp.DevicePreview(
      //   enabled: !kReleaseMode,
      //   builder: (context) => TFApp(),
      //  )
    );
  });

  await [
    Permission.location,
    Permission.storage,
    Permission.camera,
    Permission.microphone,
  ].request();
}

/* App class defining title and visual information. */
class TFApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new GetMaterialApp(
      builder: (context, child) {
        return ScrollConfiguration(behavior: new NoScroll(), child: child);
      },
      debugShowCheckedModeBanner: false,
      transitionDuration: Duration(milliseconds: 0),
      title: "Sitescape",
      theme: new ThemeData(
          // fontFamily: "Montserrat",
          primaryColor: Color.fromRGBO(58, 65, 120, 1.0),
          visualDensity: VisualDensity.adaptivePlatformDensity),
      // Home is a root page which depends on Auth status initialised on startup.
      home: new RootPage(auth: userAuth),
    );
  }
}

/* Prevents scrolling animation in the entirety of the app. */
class NoScroll extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
