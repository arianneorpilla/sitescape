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

  Weather _currentWeather;

  @override
  void initState() {
    getWeather().then((weather) {
      setState(() {
        _currentWeather = weather;
      });
    });
    // Future.delayed(Duration(seconds: 1))
    //     .then((onValue) => {showWhatsNewModal()});

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      extendBody: true,
      backgroundColor: Theme.of(context).primaryColor,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _showTime(),
          _showWeatherArtwork(),
          _showTower(),
          _showKoalas(),
          _showHill(),
          _showHeader(),
          _showMenu(),
          // Container(
          //   alignment: Alignment.center,
          //   child: showHome(widget.auth, widget.logoutCallback),
          // ),
        ],
      ),
      // floatingActionButton:
      //     FloatingActionButton(child: Icon(Icons.camera_alt, size: 36)),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        notchMargin: 12.0,
        // shape: CircularNotchedRectangle(),
        child: Container(
          padding: EdgeInsets.only(left: 36, right: 36),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                  icon: ImageIcon(AssetImage("images/home/icon_help.png")),
                  color: Colors.white,
                  iconSize: 28,
                  onPressed: () async {
                    _scaffoldKey.currentState.showSnackBar(
                      SnackBar(
                        backgroundColor: Color.fromRGBO(84, 176, 159, 1.0),
                        content: Text(
                          "This feature is under construction.",
                          style: TextStyle(
                            fontSize: ScreenUtil().setSp(36),
                          ),
                        ),
                        duration: Duration(milliseconds: 200),
                      ),
                    );
                  }),
              GestureDetector(
                onTapDown: (TapDownDetails details) {
                  showPopupMenu(context, details.globalPosition);
                },
                child: ImageIcon(
                  AssetImage("images/home/icon_menu.png"),
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
        elevation: 0,
        color: Color.fromRGBO(51, 57, 104, 1),
      ),
    );
  }

  Widget _showMenu() {
    return Container(
      padding: EdgeInsets.only(bottom: 256.h),
      alignment: Alignment.bottomCenter,
      child: Column(
        verticalDirection: VerticalDirection.up,
        children: [
          // showDummySearchBar(),
          showOptions(),
          SizedBox(height: 8),
          // showAccountBanner(),
          showNearestSitesOnLocation(),
          SizedBox(height: 8),
          showPrimarySuggestion(),
          SizedBox(height: 8),
          showDummySearchBar(),
        ],
      ),
    );
  }

  Widget _showWeatherOrLoading() {
    if (_currentWeather == null) {
      return Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.fromLTRB(16, 12, 12, 0),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      );
    } else {
      return showWeather(_currentWeather);
    }
  }

  Widget _showHeader() {
    return Container(
      padding: EdgeInsets.only(
        left: ScreenUtil().setWidth(36),
        top: ScreenUtil().setHeight(244),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _showGreeting(),
          SizedBox(height: ScreenUtil().setHeight(4)),
          _showWeatherOrLoading(),
        ],
      ),
    );
  }

  Widget _showTower() {
    return Container(
      margin: EdgeInsets.only(top: ScreenUtil().setHeight(250)),
      decoration: BoxDecoration(
        image: DecorationImage(
          alignment: Alignment.topCenter,
          fit: BoxFit.contain,
          image: AssetImage('images/home/tower.png'),
        ),
      ),
    );
  }

  Widget _showKoalas() {
    return Container(
      margin: EdgeInsets.only(top: ScreenUtil().setHeight(350)),
      decoration: BoxDecoration(
        image: DecorationImage(
          alignment: Alignment.topCenter,
          fit: BoxFit.contain,
          image: AssetImage('images/home/koalas.png'),
        ),
      ),
    );
  }

  Widget _showTime() {
    bool isDay = false;
    TimeOfDay now = TimeOfDay.now();
    if ((now.hour >= 5 && now.hour < 12) ||
        (now.hour >= 12 && now.hour <= 17)) {
      isDay = true;
    }

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          alignment: Alignment.topCenter,
          fit: BoxFit.contain,
          image: isDay
              ? AssetImage("images/home/day.png")
              : AssetImage("images/home/night.png"),
        ),
      ),
    );
  }

  Widget _showHill() {
    bool isDay = false;
    TimeOfDay now = TimeOfDay.now();
    if ((now.hour >= 5 && now.hour < 12) ||
        (now.hour >= 12 && now.hour <= 17)) {
      isDay = true;
    }

    return Container(
      margin: EdgeInsets.only(top: ScreenUtil().setHeight(500)),
      child: Container(
        child: Column(
          children: [
            Image(
              alignment: Alignment.topCenter,
              fit: BoxFit.contain,
              image: AssetImage('images/home/hill.png'),
            ),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 0,
                    color: Color.fromRGBO(84, 176, 159, 1.0),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(84, 176, 159, 1.0),
                      isDay
                          ? Theme.of(context).primaryColor
                          : Color.fromRGBO(54, 61, 114, 1.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
          _showGreeting(),
          SizedBox(height: MediaQuery.of(context).size.height * 0.005),
          // showWeatherOrLoading(),
        ]),
        Column(children: [
          showOptions(),
          SizedBox(height: 8),
          showDummySearchBar(),
          SizedBox(height: 8),
          showPrimarySuggestion(),
          showNearestSitesOnLocation(),
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
  Widget _showGreeting() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.03,
      width: MediaQuery.of(context).size.width,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: FittedBox(
          alignment: Alignment.centerLeft,
          child: Text(
            getTimeFlavour(),
            style: TextStyle(
              color: Colors.white,
              fontFamily: "Quicksand",
              fontSize: ScreenUtil().setSp(48),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /* Below time greeting, shows loading circle if weather is not ready */
  Widget _showWeatherArtwork() {
    if (_currentWeather == null) {
      return Container();
    } else {
      ImageProvider weatherImage = getWeatherImage(_currentWeather);

      // Weather data and icon
      return FadeInImage(
        alignment: Alignment.topCenter,
        fit: BoxFit.contain,
        placeholder: AssetImage("images/placeholder.png"),
        image: weatherImage,
      );
    }
  }

  /* Shows weather below time greeting
    
     weather -> Weather: Weather obtained from OpenWeather API */
  Widget showWeather(Weather weather) {
    String celsius = weather.temperature.celsius.truncate().toString();
    String icon = weather.weatherIcon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.network(
                "http://openweathermap.org/img/wn/" + icon + "@4x.png",
                height: 48,
                width: 48),
            Text(
              celsius + "°C",
              textAlign: TextAlign.left,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: ScreenUtil().setSp(144),
                  fontWeight: FontWeight.w200),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.only(
            left: 12,
            top: ScreenUtil().setHeight(48),
          ),
          alignment: Alignment.centerLeft,
          width: ScreenUtil().setWidth(750),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  showWeatherParameter(
                      "Wind Speed", weather.windSpeed.toString() + "m/s"),
                  showWeatherParameter(
                      "Humidity", weather.humidity.toString() + "%"),
                  Expanded(child: Container()),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  showWeatherParameter(
                      "Pressure", weather.pressure.round().toString() + "Pa"),
                  showWeatherParameter(
                      "Cloudiness", weather.cloudiness.toString() + "kta"),
                  showWeatherParameter(
                      "Rainfall (1hr)", weather.rainLastHour.toString() + "mm"),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  /* Helper widget for above showWeather function

     parameter -> String: Topical header for data
     data -> String: Actual data with units to shwow
  */
  Widget showWeatherParameter(String parameter, String data) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            parameter + ":",
            textAlign: TextAlign.left,
            style: TextStyle(
              fontFamily: "Quicksand",
              color: Colors.white,
              fontSize: ScreenUtil().setSp(36),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "   " + data,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: Colors.white,
              fontSize: ScreenUtil().setSp(48),
              fontWeight: FontWeight.w200,
            ),
          ),
        ],
      ),
    );
  }

  /* On center of screen, clicking on this will open the search screen */
  Widget showDummySearchBar() {
    return Container(
      margin: EdgeInsets.fromLTRB(
        32,
        ScreenUtil().setHeight(16),
        32,
        ScreenUtil().setHeight(16),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.to(
              SearchPage(),
              transition: Transition.fade,
            );
          },
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
                fontSize: ScreenUtil().setSp(42),
                fontWeight: FontWeight.w400,
              ),
            ),
            style: TextStyle(
              color: Colors.black,
              fontSize: ScreenUtil().setSp(42),
            ),
            // Must be valid entry
          ),
        ),
      ),
    );
  }

  /* For three options on the menu, Calculator, Reports, Scanner */
  Widget iconBox(String name, AssetImage icon, int actionIndex) {
    return Container(
      height: 75,
      width: 104,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            switch (actionIndex) {
              case 1:
                Get.to(CalculatorPage());
                break;
              case 2:
                Get.to(ScannerPage());
                break;
              case 3:
                _scaffoldKey.currentState.showSnackBar(
                  SnackBar(
                    backgroundColor: Color.fromRGBO(84, 176, 159, 1.0),
                    content: Text(
                      "This feature is under construction.",
                      style: TextStyle(
                        fontSize: ScreenUtil().setSp(36),
                      ),
                    ),
                    duration: Duration(milliseconds: 200),
                  ),
                );
                break;
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ImageIcon(
                icon,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(height: 5),
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ScreenUtil().setSp(42),
                  fontWeight: FontWeight.w400,
                  fontFamily: "Quicksand",
                  color: Colors.white,
                ),
              )
            ],
          ),
        ),
      ),
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
            padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: FittedBox(
              child: Container(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        iconBox(
                          "Calculations",
                          AssetImage("images/home/icon_calculations.png"),
                          1,
                        ),
                        iconBox(
                          "Scanner",
                          AssetImage("images/home/icon_scanner.png"),
                          2,
                        ),
                        iconBox(
                          "Reports",
                          AssetImage("images/home/icon_reports.png"),
                          3,
                        ),
                      ],
                    ),
                  ],
                ),
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

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 10,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          margin: EdgeInsets.fromLTRB(
            24,
            ScreenUtil().setHeight(16),
            24,
            ScreenUtil().setHeight(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Get.to(SitePage(site: lastSite))
                    .then((onValue) => setState(() {}));
              },
              child: Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      (lastSite.getSiteThumbnail() != null)
                          ? lastSite.getSiteThumbnail()
                          : Container(
                              height: 96, width: 96, color: Colors.grey[400]),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(left: 16, right: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lastSite.name.toUpperCase(),
                                textAlign: TextAlign.start,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                    fontSize: ScreenUtil().setSp(42),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black),
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
                      ),
                    ],
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        child: Text(
                          " Last accessed site ",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ScreenUtil().setSp(32),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                        color: Color.fromRGBO(84, 176, 159, 1.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /* One of three nearest Sites, polled with getThreeClosestSites()

     site -> Site: Site with info to show
     distance -> String: Distance in km or m with getDistanceText()
  */
  Widget showNearest(Site site, String distance) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        42,
        ScreenUtil().setHeight(16),
        42,
        ScreenUtil().setHeight(16),
      ),
      height: 96.h,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      decoration: BoxDecoration(
        color: Color.fromRGBO(84, 176, 159, 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 16),
              Icon(Icons.location_on, color: Colors.white),
              Expanded(
                child: Text(
                  " " + site.name.toUpperCase(),
                  textAlign: TextAlign.start,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                      fontSize: ScreenUtil().setSp(36),
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[100]),
                ),
              ),
              Text(
                " " + distance + " away ",
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ScreenUtil().setSp(32),
                ),
              ),
              SizedBox(width: 16),
            ],
          ),
          onTap: () async {
            Get.to(SitePage(site: site)).then((onValue) => setState(() {}));
          },
        ),
      ),
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
