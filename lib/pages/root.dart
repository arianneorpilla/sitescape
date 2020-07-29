import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:tfsitescape/pages/home.dart';
import 'package:tfsitescape/pages/login.dart';
import 'package:tfsitescape/services/auth.dart';

/* The root page is called on app startup, and changes based on Auth.

   auth -> Auth: The authentication status or whether user logged in, etc. */
class RootPage extends StatefulWidget {
  RootPage({this.auth});

  final Auth auth;

  @override
  State<StatefulWidget> createState() => new _RootPageState();
}

/* State for Root Page */
class _RootPageState extends State<RootPage> {
  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;
  String _userId = "";

  static FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  // If the user ID is not valid, set AuthStatus appropriately.
  @override
  void initState() {
    super.initState();
    _initLocalNotifications();
    _initFirebaseMessaging();

    widget.auth.getCurrentUser().then((user) {
      setState(() {
        if (user != null) {
          _userId = user?.uid;
        }
        authStatus =
            user?.uid == null ? AuthStatus.NOT_LOGGED_IN : AuthStatus.LOGGED_IN;
      });
    });
  }

  // On login, change the auth status to reflect this.
  Future loginCallback() async {
    String fcmToken = await FirebaseMessaging().getToken();
    FirebaseUser user = await widget.auth.getCurrentUser();

    final DatabaseReference usersRef =
        FirebaseDatabase.instance.reference().child("users");

    if (fcmToken != null) {
      await usersRef.child(user.uid).child("tokens").child(fcmToken).set({
        'token': fcmToken,
        'createdAt': ServerValue.timestamp,
        'platform': Platform.operatingSystem // optional
      });
    }

    setState(() {
      _userId = user.uid;
    });

    setState(() {
      authStatus = AuthStatus.LOGGED_IN;
    });
  }

  // On logout, set auth status to reflect this.
  void logoutCallback() {
    setState(() {
      authStatus = AuthStatus.NOT_LOGGED_IN;
      _userId = "";
    });
  }

  // Do nothing while waiting for Auth
  Widget buildWaitingScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: Center(),
      ),
    );
  }

  // Based on Auth, build into different pages, login or main activity.
  @override
  Widget build(BuildContext context) {
    switch (authStatus) {
      case AuthStatus.NOT_DETERMINED:
        return buildWaitingScreen();
        break;
      case AuthStatus.NOT_LOGGED_IN:
        return new LoginPage(
          auth: widget.auth,
          loginCallback: loginCallback,
        );
        break;
      case AuthStatus.LOGGED_IN:
        if (_userId.length > 0 && _userId != null) {
          return new HomePage(
            userId: _userId,
            auth: widget.auth,
            logoutCallback: logoutCallback,
          );
        } else
          return buildWaitingScreen();
        break;
      default:
        return buildWaitingScreen();
    }
  }

  _initLocalNotifications() {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  _initFirebaseMessaging() {
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) {
        print('AppPushs onMessage : $message');
        _showNotification(message);
        return;
      },
      onBackgroundMessage: Platform.isIOS ? null : myBackgroundMessageHandler,
      onResume: (Map<String, dynamic> message) {
        print('AppPushs onResume : $message');
        if (Platform.isIOS) {
          _showNotification(message);
        }
        return;
      },
      onLaunch: (Map<String, dynamic> message) {
        print('AppPushs onLaunch : $message');
        return;
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
  }

  // TOP-LEVEL or STATIC function to handle background messages
  static Future<dynamic> myBackgroundMessageHandler(
      Map<String, dynamic> message) {
    print('AppPushs myBackgroundMessageHandler : $message');
    _showNotification(message);
    return Future<void>.value();
  }

  static Future _showNotification(Map<String, dynamic> message) async {
    var nodeData = message['notification'];
    var pushTitle = nodeData['title'];
    var pushText = nodeData['body'];

    // @formatter:off
    var platformChannelSpecificsAndroid = new AndroidNotificationDetails(
      'your channel id',
      'your channel name',
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
        0,
        pushTitle,
        pushText,
        platformChannelSpecifics,
        payload: 'No_Sound',
      );
    });
  }
}
