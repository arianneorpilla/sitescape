import 'dart:io';

import "package:flutter/material.dart";
import "package:get/get.dart";

import "package:tfsitescape/main.dart";
import "package:tfsitescape/pages/root.dart";
import "package:tfsitescape/services/auth.dart";
import 'package:tfsitescape/services/util.dart';

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
    position: RelativeRect.fromLTRB(left, top, 0, 0),
    items: [
      popupOption(Icons.info, Colors.black, "About this app"),
      popupOption(Icons.storage, Colors.black, "Free up space"),
      // popupOption(Icons.settings, Colors.black, "Settings"),
      popupOption(Icons.exit_to_app, Colors.red, "Log out",
          fontWeight: FontWeight.bold),
    ],
  );

  if (choice == "About this app") {
    Get.to(CreditsScreen(), opaque: false);
  } else if (choice == "Free up space") {
    showFreeUpSpaceDialog(context);
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
PopupMenuItem<String> popupOption(IconData icon, Color color, String message,
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
                Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
                Text(
                  "   " + message,
                  style: TextStyle(
                    color: color,
                    fontWeight: fontWeight,
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
        fontSize: 16,
      ),
    ),
    onPressed: () async {
      try {
        // Pop the sign-out dialog.
        Get.back();

        // Sign out the user and wipe their AuthStatus.
        await userAuth.signOut();
        userAuth = new Auth();

        sites = [];
        String siteCacheDir = extDir.path + "/.sites";
        File siteCache = File(siteCacheDir);
        siteCache.deleteSync();

        // Prevent the user from returning to previous screens.
        Get.off(
          RootPage(auth: userAuth),
        );
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
        fontSize: 16,
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
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        content: SingleChildScrollView(
          child: Text(
            "Photos not yet in the cloud will remain on your device " +
                "and can be synced upon your return.",
            textAlign: TextAlign.justify,
            style: TextStyle(fontWeight: FontWeight.w400),
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
        fontSize: 16,
      ),
    ),
    onPressed: () async {
      try {
        // Pop the sign-out dialog.
        Get.back();
        freeUpSpace();
        Get.offAll(RootPage(auth: userAuth));
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
        fontSize: 16,
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
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        content: SingleChildScrollView(
          child: Text(
            "This will reload the application and delete all photos present " +
                "in the cloud from your device.\n\nPhotos that have not yet " +
                "been uploaded will remain and task progress will reset " +
                "accordingly.",
            textAlign: TextAlign.justify,
            style: TextStyle(fontWeight: FontWeight.w400),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: FloatingActionButton(
          backgroundColor: Colors.grey,
          child: Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Get.back(closeOverlays: true);
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      backgroundColor: Colors.black.withOpacity(0.75),
      body: new Container(
        height: MediaQuery.of(context).size.height,
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: new FittedBox(
          alignment: Alignment.center,
          child: new Column(
            children: [
              new Text("SITESCAPE",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                      fontSize: 72)),
              new Text(
                "H A N D O V E R  T O O L  P A C K",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                ),
                textAlign: TextAlign.justify,
              ),
              new Text(""),
              new Text(
                versionAndBuild,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.justify,
              ),
              showCreditColumn(
                "Programming and Design",
                "Leo Rafael Orpilla",
              ),
              showCreditColumn(
                "Technical and Planning",
                "Leodegario Orpilla Jr.",
              ),
              // showCreditColumn(
              //   "Powered by",
              //   "TOWERFORCE PTY LTD.",
              // ),
              showCreditColumn(
                "Data Sources",
                "Weather forecast from OpenWeatherMap",
              ),
              new Text(
                "Maps and navigation from Mapbox",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                ),
              ),
              new Text(""),
              new Text(""),
              new Text(
                "Sitescape is built with open source software.",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w300),
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
                      fontSize: 24.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w200),
                ),
                onPressed: () {
                  Get.to(
                    LicensePage(
                      applicationName: "Sitescape",
                      applicationVersion: versionAndBuild,
                      applicationLegalese: "© Sitescape 2020",
                    ),
                  );
                },
              ),
            ],
          ),
          fit: BoxFit.contain,
        ),
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
        new Text(""),
        new Text(""),
        new Text(
          header,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        new Text(
          caption,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}
