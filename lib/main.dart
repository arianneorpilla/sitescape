import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:device_preview/device_preview.dart' as dp;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tfsitescape/pages/root.dart';
import 'package:tfsitescape/services/auth.dart';
import 'package:tfsitescape/services/util.dart';
import 'package:tfsitescape/services/classes.dart';

// Background image persistent in the app.

Directory gExtDir;
Directory gTempDir;

String gCloudPath = "/tfcloud";

String gAppName;
String gPackageName;
String gVersion;
String gBuildNumber;
String gVersionAndBuild;

CameraDescription gCam;
List<Site> gSites;

double gUserLatitude;
double gUserLongitude;
Auth gUserAuth = new Auth();

/* App execution starts here. */
Future<void> main() async {
  // Wait for camera and other things to get ready.

  WidgetsFlutterBinding.ensureInitialized();

  PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
    gAppName = packageInfo.appName;
    gPackageName = packageInfo.packageName;
    gVersion = "v" + packageInfo.version;
    gBuildNumber = packageInfo.buildNumber;
    gVersionAndBuild = "v" + gVersion + "-" + gBuildNumber;
  });

  // Pre-cache the login image so it doesn't pop.
  gExtDir = await getExternalStorageDirectory();
  gTempDir = await getTemporaryDirectory();

  await loadImage("images/login/hill.png");
  await loadImage("images/login/tower.png");
  await loadImage("images/login/cloud_top.png");
  await loadImage("images/login/cloud_bottom.png");
  await loadImage("images/login/logo.png");
  await loadLocalSites();

  // Run the application.
  SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(App());
  });

  await [
    Permission.location,
    Permission.storage,
    Permission.camera,
    Permission.microphone,
  ].request();
}

/* App class defining title and visual information. */
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new GetMaterialApp(
      builder: (context, child) {
        ScreenUtil.init(context, height: 2280, width: 1080);
        return ScrollConfiguration(behavior: new NoScroll(), child: child);
      },
      debugShowCheckedModeBanner: false,
      transitionDuration: Duration(milliseconds: 0),
      title: "Sitescape",
      theme: new ThemeData(
          fontFamily: "OpenSans",
          primaryColor: Color.fromRGBO(69, 80, 161, 1.0),
          accentColor: Color.fromRGBO(84, 176, 159, 1.0),
          backgroundColor: Color.fromRGBO(69, 80, 161, 1.0),
          visualDensity: VisualDensity.adaptivePlatformDensity),
      // Home is a root page which depends on Auth status initialised on startup.
      home: new RootPage(auth: gUserAuth),
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
