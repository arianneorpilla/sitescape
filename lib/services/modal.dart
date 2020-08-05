import 'dart:io';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import "package:flutter/material.dart";
import 'package:flutter_screenutil/flutter_screenutil.dart';
import "package:get/get.dart";
import 'package:ntp/ntp.dart';

import "package:sitescape/main.dart";
import 'package:sitescape/pages/home.dart';
import "package:sitescape/pages/root.dart";
import "package:sitescape/services/auth.dart";
import 'package:sitescape/services/classes.dart';
import 'package:sitescape/services/ui.dart';
import 'package:sitescape/services/util.dart';

/* App-wide pop-up menu used in most screens, shows the following options
   in the following order:

   - About this app
   - View data usage
   - Refresh site data
   - Log out

   - context -> BuildContext: Used to construct the menu in the context
   - offset -> Offset: Used to show the pop-up menu where a click action was
*/
Future showPopupMenu(BuildContext context, Offset offset) async {
  double left = offset.dx;
  double top = offset.dy;

  String choice = await showMenu(
    context: context,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    position: RelativeRect.fromLTRB(left, top, 0, 0),
    items: [
      popupOption(
        AssetImage("images/icons/icon_info.png"),
        Colors.black,
        "About this app",
      ),
      popupOption(
        AssetImage("images/icons/icon_storage.png"),
        Colors.black,
        "Free up space",
      ),
      popupOption(
        AssetImage("images/icons/icon_add_issue.png"),
        Theme.of(context).accentColor,
        "Send feedback",
        fontWeight: FontWeight.bold,
      ),
      // popupOption(Icons.settings, Colors.black, "Settings"),
      popupOption(
        AssetImage("images/icons/icon_logout.png"),
        Colors.red,
        "Log out",
        fontWeight: FontWeight.bold,
      ),
    ],
  );

  if (choice == "About this app") {
    Get.to(CreditsScreen(), opaque: false);
  } else if (choice == "Free up space") {
    showFreeUpSpaceDialog(context);
  } else if (choice == "Send feedback") {
    showFeedbackDialog(context);
  } else if (choice == "Log out") {
    showSignoutDialog(context);
  }
}

/* Used in above pop-up menu as a general structure for menu options.
   Takes the following parameters:

   - icon -> IconData: Displayed left in the row 
   - color -> Color: Used in icon and message
   - message -> String: The option and value for the pop-up menu
   - {fontWeight} -> FontWeight: Used to style bold/italic options
*/
PopupMenuItem<String> popupOption(AssetImage image, Color color, String message,
    {FontWeight fontWeight = FontWeight.normal}) {
  return PopupMenuItem<String>(
    value: message,
    child: Container(
      margin: EdgeInsets.only(left: 16, right: 16),
      child: InkWell(
        child: Column(
          children: [
            Row(
              children: [
                ImageIcon(
                  image,
                  color: color,
                  size: ScreenUtil().setSp(40),
                ),
                Text(
                  "   " + message,
                  style: TextStyle(
                    color: color,
                    fontWeight: fontWeight,
                    fontSize: ScreenUtil().setSp(40),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/* Called when 'Log out' is selected in the pop-up menu, triggering a dialog
   with two options:

   - LOG OUT -> Signs out the user
   - CANCEL -> Simply pops the message
*/
void showSignoutDialog(BuildContext context) async {
  Widget logout = FlatButton(
    child: Text(
      "LOG OUT",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.red,
        fontSize: ScreenUtil().setSp(40),
      ),
    ),
    onPressed: () async {
      try {
        // Pop the sign-out dialog.
        Get.back();

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
    },
  );

  Widget cancel = FlatButton(
    child: Text(
      "CANCEL",
      style: TextStyle(
        color: Colors.black,
        fontSize: ScreenUtil().setSp(40),
      ),
    ),
    onPressed: () {
      // Pop the sign-out dialog.
      Get.back();
    },
  );

  // Show the dialog when this function is called, with the above widgets.
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          "Are you sure?",
          style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: ScreenUtil().setSp(42)),
        ),
        content: SingleChildScrollView(
          child: Text(
            "Photos not yet in the cloud will remain on your device " +
                "and can be synced upon your return.",
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: ScreenUtil().setSp(40),
            ),
          ),
        ),
        actions: [logout, cancel],
      );
    },
  );
}

void showFreeUpSpaceDialog(BuildContext context) async {
  Widget free = FlatButton(
    child: Text(
      "FREE UP SPACE",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.red,
        fontSize: ScreenUtil().setSp(40),
      ),
    ),
    onPressed: () async {
      try {
        // Pop the sign-out dialog.
        Get.back();
        freeUpSpace();
        Get.offAll(HomePage(auth: gUserAuth));
      } catch (e) {
        print(e);
      }
    },
  );

  Widget cancel = FlatButton(
    child: Text(
      "CANCEL",
      style: TextStyle(
        color: Colors.black,
        fontSize: ScreenUtil().setSp(40),
      ),
    ),
    onPressed: () {
      // Pop the sign-out dialog.
      Get.back();
    },
  );

  // Show the dialog when this function is called, with the above widgets.
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          "Free up space?",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: ScreenUtil().setSp(42),
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            "This will reload the application and delete all photos present " +
                "in the cloud from your device.\n\nPhotos that have not yet " +
                "been uploaded will remain and task progress will reset " +
                "accordingly.",
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: ScreenUtil().setSp(40),
            ),
          ),
        ),
        actions: [free, cancel],
      );
    },
  );
}

/* A translucent screen called when the user selects 'About this app',
   showing a scrollable credits screen. This should also lead to additional
   screens, like licenses for legal compliance. A similar modal design will
   be used for the Help screens. */
class CreditsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(51, 57, 104, 0.8),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.all(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Stack(
            children: [
              showAllCredits(),
              showBackButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget showAllCredits() {
    return Center(
      child: FittedBox(
        alignment: Alignment.center,
        child: new Column(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  alignment: Alignment.topCenter,
                  fit: BoxFit.contain,
                  image: AssetImage('images/login/logo.png'),
                ),
              ),
            ),
            new Text("sitescape",
                style: TextStyle(
                    fontFamily: "Quicksand",
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                    fontSize: ScreenUtil().setSp(288))),
            new Text(
              "H A N D O V E R  T O O L  P A C K",
              style: TextStyle(
                fontFamily: "Quicksand",
                color: Colors.white,
                fontSize: ScreenUtil().setSp(72),
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.justify,
            ),
            Text("", style: TextStyle(fontSize: ScreenUtil().setSp(36))),
            new Text(
              gVersion,
              style: TextStyle(
                color: Colors.white,
                fontSize: ScreenUtil().setSp(48),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.justify,
            ),
            showCreditColumn(
              "Programming and Systems Design",
              "Leo Rafael Orpilla",
            ),
            showCreditColumn(
              "Graphic Design",
              "Aaron Marbella",
            ),
            // showCreditColumn(
            //   "Powered by",
            //   "TOWERFORCE PTY LTD.",
            // ),
            showCreditColumn(
              "Data Sources",
              "Weather Forecast from OpenWeatherMap",
            ),
            new Text(
              "Maps and Navigation from Mapbox",
              style: TextStyle(
                color: Colors.white,
                fontSize: ScreenUtil().setSp(60),
                fontWeight: FontWeight.w200,
              ),
            ),
            Text("", style: TextStyle(fontSize: ScreenUtil().setSp(36))),
            new Text(
              "Sitescape is built with open source software.",
              style: TextStyle(
                color: Colors.white,
                fontSize: ScreenUtil().setSp(60),
                fontWeight: FontWeight.w400,
                fontFamily: "Quicksand",
              ),
              textAlign: TextAlign.center,
            ),
            new Text(""),
            new RaisedButton(
              elevation: 20,
              shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(20.0),
              ),
              color: Colors.white.withOpacity(0.4),
              child: new Text(
                "Licenses",
                style: new TextStyle(
                    fontSize: ScreenUtil().setSp(72),
                    color: Colors.white,
                    fontWeight: FontWeight.w200),
              ),
              onPressed: () {
                Get.to(
                  LicensePage(
                    applicationName: "Sitescape",
                    applicationVersion: gVersion,
                    applicationLegalese: "© Sitescape 2020",
                  ),
                );
              },
            ),
          ],
        ),
        fit: BoxFit.contain,
      ),
    );
  }

  /* Used to cleanly structure the credits screen into modular pieces.

  - header -> String: Smaller size text, semi-bold weight
  - caption -> String: Bigger size text, semi-light weight
  */
  Widget showCreditColumn(String header, String caption) {
    return Column(
      children: [
        Text("", style: TextStyle(fontSize: ScreenUtil().setSp(36))),
        Text("", style: TextStyle(fontSize: ScreenUtil().setSp(36))),
        new Text(
          header,
          style: TextStyle(
            color: Colors.white,
            fontSize: ScreenUtil().setSp(60),
            fontWeight: FontWeight.w600,
            fontFamily: "Quicksand",
          ),
        ),
        new Text(
          caption,
          style: TextStyle(
            color: Colors.white,
            fontSize: ScreenUtil().setSp(60),
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}

void showFeedbackDialog(BuildContext context) async {
  TextEditingController _controller = new TextEditingController();

  Widget logout = FlatButton(
    child: Text(
      "SUBMIT",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).accentColor,
        fontSize: ScreenUtil().setSp(40),
      ),
    ),
    onPressed: () async {
      try {
        if (_controller.text.isNotEmpty) {
          DateTime now = await NTP.now();
          FirebaseUser user = await gUserAuth.getCurrentUser();

          SiteNote note = SiteNote.create(
              _controller.text, user.uid, now.millisecondsSinceEpoch);

          Site site = Site(
            "Feedback Technical Test",
            "Feedback Name",
            "Feedback Address",
            "Feedback Build",
            "Feedback Network",
            0,
            0,
            {},
          );

          site.addIssue(note);
        }

        Get.back();

        // Prevent the user from returning to previous screens.
      } catch (e) {
        print(e);
      }
    },
  );

  Widget cancel = FlatButton(
    child: Text(
      "CANCEL",
      style: TextStyle(
        color: Colors.black,
        fontSize: ScreenUtil().setSp(40),
      ),
    ),
    onPressed: () {
      // Pop the sign-out dialog.
      Get.back();
    },
  );

  // Show the dialog when this function is called, with the above widgets.
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          "We appreciate your feedback",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: ScreenUtil().setSp(42),
          ),
        ),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          child: TextField(
            autofocus: true,
            controller: _controller,
            maxLines: 4,
            maxLengthEnforced: true,
            maxLength: 300,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            decoration: new InputDecoration(
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 1.0),
                borderRadius: BorderRadius.zero,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 1.0),
                borderRadius: BorderRadius.zero,
              ),
              hintText: 'Enter any comments and suggestions',
              hintStyle: TextStyle(
                fontSize: ScreenUtil().setSp(40),
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        actions: [logout, cancel],
      );
    },
  );
}
