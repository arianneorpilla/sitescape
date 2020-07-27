import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:weather/weather_library.dart';

import 'package:tfsitescape/pages/calculator.dart';
import 'package:tfsitescape/pages/scanner.dart';
import 'package:tfsitescape/pages/search.dart';
import 'package:tfsitescape/pages/site.dart';
import 'package:tfsitescape/services/auth.dart';
import 'package:tfsitescape/services/modal.dart';
import 'package:tfsitescape/services/classes.dart';
import 'package:tfsitescape/services/util.dart';

/* The HomePage is the main screen upon login, and has the Auth passed
   from login. Or if the login was skipped, it could be invalid, but
   that's how we determine if sync functionality is available or not. 
   
   auth -> Auth: For checking if user should be logged out or not, perms
   userId -> String: For checking if user is verified, etc. 
   logoutCallback -> void: Operation to perform if user should be logged out 
*/
class HomePage extends StatefulWidget {
  HomePage({Key key, this.auth, this.userId, this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;

  @override
  State<StatefulWidget> createState() => new _HomePageState();
}

/* State for HomePage */
class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 1))
        .then((onValue) => {showWhatsNewModal()});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      extendBody: true,
      backgroundColor: Theme.of(context).primaryColor,
      body: Stack(
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/login.jpg'),
                colorFilter: new ColorFilter.mode(
                    Colors.black.withOpacity(0.2), BlendMode.dstATop),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Container(color: Colors.indigo.withOpacity(0.7)),
            ),
          ),
          Container(
            alignment: Alignment.center,
            child: showHome(widget.auth, widget.logoutCallback),
          )
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        notchMargin: 12.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
                icon: Icon(Icons.help_outline),
                color: Colors.white,
                iconSize: 36,
                onPressed: () async {
                  _scaffoldKey.currentState.showSnackBar(
                    SnackBar(
                      content: Text(
                        "This feature is under construction.",
                        style: TextStyle(
                          fontSize: ScreenUtil().setSp(36),
                        ),
                      ),
                      duration: Duration(milliseconds: 500),
                    ),
                  );
                }),
            GestureDetector(
              onTapDown: (TapDownDetails details) {
                showPopupMenu(context, details.globalPosition);
              },
              child: Icon(
                Icons.more_vert,
                color: Colors.white,
                size: 36,
              ),
            ),
          ],
        ),
        elevation: 0,
        color: Colors.black.withOpacity(0.25),
      ),
    );
  }

  /* Main layout for Home */
  Widget showHome(Auth auth, void logoutCallback) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 36, 12, 72),
      child:
          Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Column(children: [
          showGreeting(),
          SizedBox(height: MediaQuery.of(context).size.height * 0.005),
          showWeatherOrLoading(),
        ]),
        Column(children: [
          showOptions(),
          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          showDummySearchBar(),
          // showAccountBanner(),
          showPrimarySuggestion(),
          showNearestSitesOnLocation(),
          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
        ]),
      ]),
    );
  }

  /* Used for cloud sync */
  Widget showFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: Colors.black.withOpacity(0.4),
      child: Icon(Icons.refresh, size: 36),
      elevation: 0,
      onPressed: () {
        setState(() {});
      },
    );
  }

  /* Appropriate time greeting on top right of page */
  Widget showGreeting() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.03,
      width: MediaQuery.of(context).size.width,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: FittedBox(
          alignment: Alignment.centerRight,
          child: Text(
            getTimeFlavour(),
            style: TextStyle(
              color: Colors.white,
              fontSize: ScreenUtil().setSp(48),
              fontWeight: FontWeight.w200,
            ),
          ),
        ),
      ),
    );
  }

  /* Below time greeting, shows loading circle if weather is not ready */
  Widget showWeatherOrLoading() {
    return FutureBuilder(
        future: getWeather(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            return Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: CircularProgressIndicator(
                strokeWidth: 1,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            );
          }
          // Weather data and icon
          return Align(
            alignment: Alignment.center,
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: FittedBox(
                child: showWeather(snapshot.data),
              ),
            ),
          );
        });
  }

  /* Shows weather below time greeting
    
     weather -> Weather: Weather obtained from OpenWeather API */
  Widget showWeather(Weather weather) {
    String celsius = weather.temperature.celsius.truncate().toString();
    String icon = weather.weatherIcon;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image.network(
                      "http://openweathermap.org/img/wn/" + icon + "@4x.png",
                      height: 48,
                      width: 48),
                  Text(
                    celsius + "°C",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: ScreenUtil().setSp(128),
                        fontWeight: FontWeight.w200),
                  ),
                ],
              )
            ],
          ),
          Text("                        "),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              showWeatherParameter(
                  "Wind Speed", weather.windSpeed.toString() + "m/s"),
              showWeatherParameter(
                  "Cloudiness", weather.cloudiness.toString() + "kta"),
              showWeatherParameter(
                  "Pressure", weather.pressure.round().toString() + "Pa"),
              showWeatherParameter(
                  "Humidity", weather.windSpeed.toString() + "%"),
              showWeatherParameter(
                  "Rain", weather.rainLastHour.toString() + "mm"),
            ],
          )
        ],
      ),
    );
  }

  /* Helper widget for above showWeather function

     parameter -> String: Topical header for data
     data -> String: Actual data with units to shwow
  */
  Widget showWeatherParameter(String parameter, String data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          parameter + ":",
          textAlign: TextAlign.right,
          style: TextStyle(
            color: Colors.white,
            fontSize: ScreenUtil().setSp(36),
            fontWeight: FontWeight.w300,
          ),
        ),
        Text(
          " " + data,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: Colors.white,
            fontSize: ScreenUtil().setSp(36),
            fontWeight: FontWeight.w200,
          ),
        ),
      ],
    );
  }

  /* On center of screen, clicking on this will open the search screen */
  Widget showDummySearchBar() {
    return GestureDetector(
      child: Card(
        child: Container(
          child: TextField(
            textCapitalization: TextCapitalization.none,
            autofocus: false,
            keyboardType: TextInputType.emailAddress,
            cursorColor: Colors.grey,
            obscureText: false,
            showCursor: true,
            enabled: false,
            decoration: InputDecoration(
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.all(12.0),
              prefixIcon: Icon(
                Icons.search,
                size: ScreenUtil().setSp(48),
                color: Colors.grey,
              ),
              hintText: 'Search for site',
              hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: ScreenUtil().setSp(48),
                  fontWeight: FontWeight.w300),
            ),
            style: TextStyle(color: Colors.black, fontSize: 20),
            // Must be valid entry
          ),
        ),
        elevation: 10,
        color: Colors.white.withOpacity(0.9),
      ),
      onTap: () {
        Get.to(
          SearchPage(),
          transition: Transition.fade,
        );
      },
    );
  }

  /* For three options on the menu, Calculator, Reports, Scanner */
  Widget iconBox(String name, IconData icon, int actionIndex) {
    return InkWell(
      child: Container(
        height: 69,
        width: 96,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(height: 5),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: ScreenUtil().setSp(42),
                  fontWeight: FontWeight.w200,
                  color: Colors.white),
            )
          ],
        ),
      ),
      onTap: () {
        switch (actionIndex) {
          case 1:
            Get.to(CalculatorPage());
            break;
          case 2:
            _scaffoldKey.currentState.showSnackBar(
              SnackBar(
                content: Text(
                  "This feature is under construction.",
                  style: TextStyle(
                    fontSize: ScreenUtil().setSp(36),
                  ),
                ),
                duration: Duration(milliseconds: 500),
              ),
            );
            break;
          case 3:
            Get.to(ScannerPage());
            break;
        }
      },
    );
  }

  /* Spawns three equal sized icon boxes in middle of screen above search */
  Widget showOptions() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: FittedBox(
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: FittedBox(
              child: Container(
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      iconBox("Calculations", Icons.iso, 1),
                      iconBox("Reports", Icons.chrome_reader_mode, 2),
                      iconBox("Scanner", Icons.center_focus_weak, 3)
                    ],
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /* Below search, shows the last site accessed by the user for convenience */
  Widget showPrimarySuggestion() {
    return FutureBuilder(
      future: getLastSiteAccessed(),
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.data == null) {
          return Container();
        }

        Site lastSite = snapshot.data;

        return InkWell(
          child: Card(
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your last accessed site",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: ScreenUtil().setSp(36),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          lastSite.name.toUpperCase(),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                              fontSize: ScreenUtil().setSp(48),
                              fontWeight: FontWeight.w600,
                              color: Colors.black54),
                        ),
                        Text(
                          lastSite.code.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                              fontSize: ScreenUtil().setSp(36),
                              fontWeight: FontWeight.w400,
                              color: Colors.black54),
                        )
                      ],
                    ),
                  ),
                  (lastSite.getSiteThumbnail() != null)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(5.0),
                          child: lastSite.getSiteThumbnail(),
                        )
                      : Icon(Icons.photo_library,
                          size: 64.0, color: Colors.grey),
                ],
              ),
              padding: const EdgeInsets.all(15.0),
            ),
            elevation: 10,
          ),
          onTap: () {
            Get.to(SitePage(site: lastSite)).then((onValue) => setState(() {}));
          },
        );
      },
    );
  }

  /* One of three nearest Sites, polled with getThreeClosestSites()

     site -> Site: Site with info to show
     distance -> String: Distance in km or m with getDistanceText()
  */
  Widget showNearest(Site site, String distance) {
    return InkWell(
      child: Card(
        child: Container(
          height: 96.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  site.name.toUpperCase(),
                  textAlign: TextAlign.start,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                      fontSize: ScreenUtil().setSp(42),
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[100]),
                ),
              ),
              Row(
                children: [
                  Text(
                    distance + " away ",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ScreenUtil().setSp(36),
                    ),
                  ),
                  Icon(Icons.location_on, color: Colors.white)
                ],
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
        ),
        elevation: 10,
        color: Colors.green[400],
      ),
      onTap: () async {
        Get.to(SitePage(site: site)).then((onValue) => setState(() {}));
      },
    );
  }

  /* Checks if it is appropriate to check the location, does not show the
     nearest three Sites if not */
  Widget showNearestSitesOnLocation() {
    return FutureBuilder(
      future: isLocationAvailable(),
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.data == true) {
          return showNearestThreeSites();
        } else {
          return Container();
        }
      },
    );
  }

  /* Shows nearest three Sites by calling getThreeClosestThreeSites() to
     get closest Sites from all site data */
  Widget showNearestThreeSites() {
    return FutureBuilder(
      future: getThreeClosestSites(),
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.data == null) {
          return Container();
        }

        // Extract array outputs from getThreeClosestSites().
        var closestSites = snapshot.data[0];
        var closestDistances = snapshot.data[1];

        // Produce the proper unit suffix for the distance texts.
        List<String> closestText = [];
        for (var i in closestDistances) {
          closestText.add(
            getDistanceText(i),
          );
        }

        // Show the closest Sites and their distances in order.
        return Column(
          children: [
            showNearest(closestSites[0], closestText[0]),
            showNearest(closestSites[1], closestText[1]),
            showNearest(closestSites[2], closestText[2]),
          ],
        );
      },
    );
  }

  void showWhatsNewModal() {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // String getVersion = prefs.getString('version') ?? null;

    Widget dismiss = FlatButton(
      child: Text(
        "DISMISS",
        style: TextStyle(
          color: Colors.blue,
          fontSize: ScreenUtil().setSp(42),
        ),
      ),
      onPressed: () {
        // Pop the sign-out dialog.
        Get.back();
      },
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Welcome to the Technical Test",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: ScreenUtil().setSp(48),
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              "Thank you for participating in the Sitescape Technical Test. This message will appear with each startup." +
                  " Your objective as a pre-production tester is as follows:\n\n"
                      "- As a basic tutorial, attempt to access the Technical Test 00 site, where every tester is instructed to dump any number of photos.\n" +
                  "- Make sure to sync your items to the cloud.\n" +
                  "- Find a Technical Test site that is empty (not 00) and perform the tasks in it as your individual folder.\n" +
                  "- Complete every sector until progression is complete.\n" +
                  "- No additional instructions are available to you as a tester as the tests are intended to gauge the effectiveness of the application and user interface design.\n\n" +
                  "The following are what we expect to gain from this Technical Test:\n\n" +
                  "- Knowledge of bugs present in the application.\n" +
                  "- User's tendencies and any aversions towards the user interface.\n" +
                  "- Stability of the client software in different devices.\n" +
                  "- Reliability of cloud upload and presence of any undesired or undefined behaviour.\n" +
                  "- Server load, cost and bandwidth from each cloud task performed with increased traffic.\n",
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: ScreenUtil().setSp(42),
              ),
            ),
          ),
          actions: [dismiss],
        );
      },
    );
  }
}
