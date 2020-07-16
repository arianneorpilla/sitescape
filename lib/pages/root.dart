import 'package:flutter/material.dart';

import 'package:tfsitescapeweb/pages/home.dart';
import 'package:tfsitescapeweb/pages/login.dart';
import 'package:tfsitescapeweb/services/auth.dart';

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

  // If the user ID is not valid, set AuthStatus appropriately.
  @override
  void initState() {
    super.initState();
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
  void loginCallback() {
    widget.auth.getCurrentUser().then((user) {
      setState(() {
        _userId = user.uid.toString();
      });
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
      case AuthStatus.NOT_LOGGED_IN:
        // return new HomePage(auth: widget.auth);
        return new LoginPage(
          auth: widget.auth,
          loginCallback: loginCallback,
        );
        break;
      case AuthStatus.LOGGED_IN:
        if (_userId.length > 0 && _userId != null) {
          return new HomePage(auth: widget.auth);
        } else
          return buildWaitingScreen();
        break;
      default:
        return buildWaitingScreen();
    }
  }
}
