import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:sitescape/pages/root.dart';
import 'package:sitescape/pages/task.dart';
import 'package:sitescape/services/auth.dart';
import 'package:sitescape/services/util.dart';
import 'package:sitescape/services/classes.dart';

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
bool gTransaction = false;

FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

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

  _initLocalNotifications();
  _initFirebaseMessaging();

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

_initLocalNotifications() {
  var initializationSettingsAndroid =
      new AndroidInitializationSettings('@mipmap/ic_launcher');
  var initializationSettingsIOS = new IOSInitializationSettings();
  var initializationSettings = new InitializationSettings(
      initializationSettingsAndroid, initializationSettingsIOS);
  _flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: onSelectNotification);
}

_initFirebaseMessaging() {
  _firebaseMessaging.configure(
    onMessage: (Map<String, dynamic> message) {
      print('AppPushs onMessage : $message');
      _showNotification(message);
      return;
    },
    onBackgroundMessage: myBackgroundMessageHandler,
    onResume: (Map<String, dynamic> message) {
      print('AppPushs onResume : $message');

      String siteName = message["data"]["sitename"];
      String subName = message["data"]["subname"];
      String secName = message["data"]["secname"];
      String taskName = message["data"]["taskname"];

      Site site = gSites.singleWhere((a) => a.name == siteName);
      Subsite sub = site.subsites.singleWhere((a) => a.name == subName);
      Sector sec = sub.sectors.singleWhere((a) => a.name == secName);
      Task task = sec.tasks.singleWhere((a) => a.name == taskName);

      Get.to(TaskPage(task: task, showNotReq: false, viewCloud: true));

      return;
    },
    onLaunch: (Map<String, dynamic> message) {
      print('AppPushs onLaunch : $message');

      String siteName = message["data"]["sitename"];
      String subName = message["data"]["subname"];
      String secName = message["data"]["secname"];
      String taskName = message["data"]["taskname"];

      Site site = gSites.singleWhere((a) => a.name == siteName);
      Subsite sub = site.subsites.singleWhere((a) => a.name == subName);
      Sector sec = sub.sectors.singleWhere((a) => a.name == secName);
      Task task = sec.tasks.singleWhere((a) => a.name == taskName);

      Get.to(TaskPage(task: task, showNotReq: false, viewCloud: true));

      return;
    },
  );
  _firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(sound: true, badge: true, alert: true));
}

// TOP-LEVEL or STATIC function to handle background messages
Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) {
  print('AppPushs myBackgroundMessageHandler : $message');
  _showNotification(message);
  return Future<void>.value();
}

Future _showNotification(Map<String, dynamic> message) async {
  var nodeData = message['notification'];
  var pushTitle = nodeData['title'];
  var pushText = nodeData['body'];

  var destinationData = message['data'];

  if (pushTitle == "End of Sitescape Technical Test") {
    try {
      // Sign out the user and wipe their AuthStatus.
      await gUserAuth.signOut();
      gUserAuth = new Auth();

      gSites = [];

      String siteCacheDir = gExtDir.path + "/.sites";
      File siteCache = File(siteCacheDir);
      siteCache.deleteSync();
    } catch (e) {
      print(e);
    } finally {
      // Prevent the user from returning to previous screens.
      Get.off(
        RootPage(auth: gUserAuth),
      );
    }
  }

  // @formatter:off
  var platformChannelSpecificsAndroid = new AndroidNotificationDetails(
    'Channel ID',
    'Channel ID',
    'your channel description',
    enableVibration: true,
    importance: Importance.Max,
    priority: Priority.High,
    styleInformation: BigTextStyleInformation(''),
  );
  // @formatter:on
  var platformChannelSpecificsIos =
      new IOSNotificationDetails(presentSound: false);
  var platformChannelSpecifics = new NotificationDetails(
      platformChannelSpecificsAndroid, platformChannelSpecificsIos);

  new Future.delayed(Duration.zero, () {
    _flutterLocalNotificationsPlugin.show(
      (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      pushTitle,
      pushText,
      platformChannelSpecifics,
      payload: json.encode(destinationData),
    );
  });
}

Future onSelectNotification(String payload) async {
  Map<String, dynamic> destinationData = json.decode(payload);

  String siteName = destinationData["sitename"];
  String subName = destinationData["subname"];
  String secName = destinationData["secname"];
  String taskName = destinationData["taskname"];

  Site site = gSites.singleWhere((a) => a.name == siteName);
  Subsite sub = site.subsites.singleWhere((a) => a.name == subName);
  Sector sec = sub.sectors.singleWhere((a) => a.name == secName);
  Task task = sec.tasks.singleWhere((a) => a.name == taskName);

  Get.to(TaskPage(task: task, showNotReq: false, viewCloud: true));
}
