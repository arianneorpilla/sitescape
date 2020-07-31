import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart'
    as fmn;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:ntp/ntp.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:tfsitescape/main.dart';
import 'package:tfsitescape/pages/sector.dart';
import 'package:tfsitescape/services/cloud.dart';
import 'package:path/path.dart' as ph;
import 'package:http/http.dart' as http;

import 'package:tfsitescape/services/modal.dart';
import 'package:tfsitescape/services/classes.dart';
import 'package:tfsitescape/services/tabs.dart';
import 'package:tfsitescape/services/ui.dart';
import 'package:tfsitescape/services/util.dart';

/* Page upon Site selection, where user can pick a sector and scroll through
   subsites. Also has a map of the site pulled from GPS coordinates, with
   option to get directions or download the site.
   
   site -> Site: The site pertaining to the page */
class SitePage extends StatefulWidget {
  SitePage({Key key, this.site}) : super(key: key);

  final Site site;

  @override
  State<StatefulWidget> createState() => new _SitePageState(this.site);
}

/* State for SitePage */
class _SitePageState extends State<SitePage> {
  final Site site;

  _SitePageState(this.site);

  final _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _tabKey = new GlobalKey<CustomTabsState>();

  bool _downloading = false;
  bool _uploading = false;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    setLastSiteAccessed(widget.site);
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        extendBody: true,
        backgroundColor: Theme.of(context).primaryColor,
        body: Stack(
          children: <Widget>[
            ColorFiltered(
              child: showBottomArtFaded(),
              colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColor, BlendMode.color),
            ),
            Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              color: Colors.white.withOpacity(0.4),
            ),
            Column(children: [
              showMapCard(),
              showSiteInfo(),
              showTabs(),
            ]),
            showBackFloatButton(),
            showStatusBarBox(),
          ],
        ),
        floatingActionButton: showFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          notchMargin: 12.0,
          shape: CircularNotchedRectangle(),
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
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_downloading || _uploading) {
      Widget logout = FlatButton(
        child: Text(
          "CANCEL OPERATION",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
            fontSize: ScreenUtil().setSp(40),
          ),
        ),
        onPressed: () {
          _downloading = false;
          _uploading = false;
          for (Subsite sub in widget.site.subsites) {
            for (Sector sec in sub.sectors) {
              sec.downloading = false;
              sec.uploading = false;
            }
          }
          Get.back();
          Get.back();
        },
      );

      Widget cancel = FlatButton(
        child: Text(
          "RESUME",
          style: TextStyle(
            color: Colors.blue,
            fontSize: ScreenUtil().setSp(40),
          ),
        ),
        onPressed: () {
          // Pop the sign-out dialog.
          Get.back();
        },
      );

      return (await showDialog(
            context: context,
            builder: (context) => new AlertDialog(
              title: Text(
                "Operation In Progress",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: ScreenUtil().setSp(42),
                ),
              ),
              content: SingleChildScrollView(
                child: Text(
                  "Exiting past this site screen will abruptly terminate the " +
                      "ongoing download or upload.\n\nPartial progress will " +
                      "be retained and you may restart the task wherever you " +
                      "left off later.",
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: ScreenUtil().setSp(40),
                  ),
                ),
              ),
              actions: [logout, cancel],
            ),
          )) ??
          false;
    } else {
      Get.back();
      return false;
    }
  }

  /* Upon clicking the icon button to navigate, this uses Mapbox Navigation
     to start turn-by-turn navigation, might need to check if this is a 
     realistic feature to have given the cost of Mapbox. */
  Future startSiteNavigation() async {
    setState(() {
      _navigating = true;
    });

    fmn.MapboxNavigation _directions;

    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    double myLat = position.latitude;
    double myLong = position.longitude;

    _directions = fmn.MapboxNavigation(onRouteProgress: (arrived) async {
      if (arrived) await _directions.finishNavigation();
    });

    final userLocation =
        fmn.Location(name: "My location", latitude: myLat, longitude: myLong);

    final selectedLocation = fmn.Location(
        name: widget.site.name,
        latitude: widget.site.latitude,
        longitude: widget.site.longitude);

    _directions.startNavigation(
        origin: userLocation,
        destination: selectedLocation,
        mode: fmn.NavigationMode.drivingWithTraffic,
        simulateRoute: false,
        units: fmn.VoiceUnits.metric);

    Future.delayed(Duration(seconds: 10)).then((onValue) {
      setState(() {
        _navigating = false;
      });
    });
  }

  Widget showFloatingActionButton() {
    if (_downloading || _navigating) {
      return FloatingActionButton(
        onPressed: () async {},
        elevation: 10,
        child: SizedBox(
          width: 56,
          height: 56,
          child: InkWell(
            child: Container(
              padding: EdgeInsets.all(12),
              child: ImageIcon(AssetImage("images/icons/icon_cloud_upload.png"),
                  size: 48, color: Colors.white.withOpacity(0.5)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromRGBO(84, 176, 159, 1.0),
                    Theme.of(context).primaryColor,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    switch (getSyncStatus()) {
      case SyncStatus.SITE_NO_ADDITIONS:
      case SyncStatus.SITE_SYNCED:
        return FloatingActionButton(
          onPressed: () async {
            syncSite(widget.site, false);
          },
          elevation: 10,
          child: SizedBox(
            width: 56,
            height: 56,
            child: InkWell(
              child: Container(
                padding: EdgeInsets.all(12),
                child: ImageIcon(
                    AssetImage("images/icons/icon_cloud_upload.png"),
                    size: 48,
                    color: Colors.white),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromRGBO(84, 176, 159, 1.0),
                      Theme.of(context).primaryColor,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      case SyncStatus.SITE_HAS_UNUPLOADED:
        return FloatingActionButton(
          onPressed: () async {
            syncSite(widget.site, false);
          },
          elevation: 10,
          child: SizedBox(
            width: 56,
            height: 56,
            child: InkWell(
              child: Container(
                padding: EdgeInsets.all(12),
                child: ImageIcon(
                    AssetImage("images/icons/icon_cloud_upload.png"),
                    size: 48,
                    color: Colors.yellow[700]),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromRGBO(84, 176, 159, 1.0),
                      Theme.of(context).primaryColor,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        break;
      case SyncStatus.SITE_UPLOADING:
        return FloatingActionButton(
          onPressed: () async {},
          elevation: 10,
          child: SizedBox(
            width: 56,
            height: 56,
            child: InkWell(
              child: Container(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.greenAccent),
                      strokeWidth: 2),
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromRGBO(84, 176, 159, 1.0),
                      Theme.of(context).primaryColor,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        break;
    }

    return Container();
  }

  SyncStatus getSyncStatus() {
    bool unuploaded = false;
    // bool done = false;

    for (Subsite sub in site.subsites) {
      for (Sector sec in sub.sectors) {
        if (sec.getUnsynced()) {
          unuploaded = true;
        }
      }
    }

    if (_uploading) {
      return SyncStatus.SITE_UPLOADING;
    } else if (unuploaded) {
      return SyncStatus.SITE_HAS_UNUPLOADED;
      // } else if (done) {
      // return SyncStatus.SITE_SYNCED;
    } else {
      return SyncStatus.SITE_NO_ADDITIONS;
    }
  }

  /* On top center below map card */
  Widget showSiteInfo() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.site.name.toUpperCase(),
            style: TextStyle(
              color: Colors.black,
              fontSize: ScreenUtil().setSp(42),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            widget.site.code.toUpperCase(),
            style: TextStyle(
              fontSize: ScreenUtil().setSp(36),
              color: Colors.black54,
              fontWeight: FontWeight.w400,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(""),
                    Row(
                      children: [
                        ImageIcon(widget.site.getIconFromNetwork(),
                            size: 18, color: Colors.black54),
                        Text(
                          " " + widget.site.network + " • " + widget.site.build,
                          style: TextStyle(
                            fontSize: ScreenUtil().setSp(36),
                            color: Colors.black54,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      widget.site.address,
                      maxLines: 5,
                      overflow: TextOverflow.fade,
                      style: TextStyle(
                        fontSize: ScreenUtil().setSp(36),
                        color: Colors.black54,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  showDirectionsButton(),
                  showDownloadButton(),
                  showReportButton(),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget showDirectionsButton() {
    if (_navigating) {
      return Container(
        height: 48,
        width: 48,
        child: Center(
          child: SizedBox(
            height: 30,
            width: 30,
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.greenAccent),
                strokeWidth: 2.0),
          ),
        ),
      );
    } else if (_downloading || _uploading) {
      return Container(
        width: 48,
        child: Center(
          child: IconButton(
            icon: ImageIcon(AssetImage("images/icons/icon_directions.png")),
            iconSize: 36,
            color: Colors.grey,
            onPressed: () async {},
          ),
        ),
      );
    } else {
      return Container(
        width: 48,
        child: Center(
          child: IconButton(
            icon: ImageIcon(AssetImage("images/icons/icon_directions.png")),
            iconSize: 36,
            color: Colors.greenAccent,
            onPressed: () async {
              startSiteNavigation();
            },
          ),
        ),
      );
    }
  }

  Widget showDownloadButton() {
    if (_downloading) {
      return Container(
        height: 48,
        width: 48,
        child: Center(
          child: SizedBox(
            height: 30,
            width: 30,
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.blue),
                strokeWidth: 2.0),
          ),
        ),
      );
    } else if (_uploading || _navigating) {
      return Container(
        width: 48,
        child: Center(
          child: ImageIcon(
            AssetImage("images/icons/icon_cloud_download.png"),
            size: 36,
            color: Colors.grey,
          ),
        ),
      );
    } else
      return Container(
        height: 48,
        width: 48,
        child: Center(
          child: IconButton(
            icon: ImageIcon(
              AssetImage("images/icons/icon_cloud_download.png"),
              size: 36,
              color: Colors.blue,
            ),
            onPressed: () async {
              await downloadSite(widget.site, false);
            },
          ),
        ),
      );
  }

  Widget showReportButton() {
    if (_downloading || _uploading || _navigating) {
      return Container(
        width: 48,
        child: Center(
          child: IconButton(
            icon: ImageIcon(AssetImage("images/icons/icon_add_issue.png")),
            iconSize: 36,
            color: Colors.grey,
            onPressed: () async {},
          ),
        ),
      );
    }
    return Container(
      width: 48,
      child: Center(
        child: IconButton(
          icon: ImageIcon(AssetImage("images/icons/icon_add_issue.png")),
          iconSize: 36,
          color: Colors.red[400],
          onPressed: () async {
            showReportDialog(context);
          },
        ),
      ),
    );
  }

  /* On top center clipping through the notification shade */
  Widget showMapCard() {
    return Container(
      height: ScreenUtil().setHeight(2280) * 0.25,
      child: Stack(
        alignment: Alignment.center,
        children: [
          MapboxMap(
            logoViewMargins: Point(5, 5),
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            myLocationEnabled: false,
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.site.latitude, widget.site.longitude),
              zoom: 14,
            ),
          ),
        ],
      ),
      color: Colors.white,
    );
  }

  /* Below the site info, tabs are scrollable subsite list with
     a ListView of sectors under each page */
  Widget showTabs() {
    Widget buildPages(int index) {
      if (index < widget.site.subsites.length) {
        return MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: ListView(
            children: [
              showSectorList(widget.site, widget.site.subsites[index]),
              SizedBox(height: 256.h),
            ],
          ),
        );
      } else {
        return MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: ListView(
            children: [
              showNoteList(widget.site),
              SizedBox(height: 256.h),
            ],
          ),
        );
      }
    }

    Widget buildTabs(int index) {
      if (index < widget.site.subsites.length) {
        return Tab(
          child: Text(
            widget.site.subsites[index].name,
            style: TextStyle(
              fontSize: ScreenUtil().setSp(34),
            ),
          ),
        );
      } else {
        return Tab(
          child: Text(
            "Issues",
            style: TextStyle(
              fontSize: ScreenUtil().setSp(34),
            ),
          ),
        );
      }
    }

    return Flexible(
      child: Container(
        child: CustomTabView(
          key: _tabKey,
          alignment: Alignment.center,
          backgroundColor: Colors.white,
          initPosition: 0,
          itemCount: widget.site.subsites.length + 1,
          tabBuilder: (context, index) => buildTabs(index),
          pageBuilder: (context, index) => buildPages(index),
        ),
      ),
    );
  }

  /* Constructed from showTabs, builds a list of sectors given a Site and Sub,
   this is where a UserSelection is also initially constructed.

   site -> Site: For passing site to the sector list as UserSelection
   sub -> Subsite: For passing subsite to the sector list UserSelection
  */
  Widget showSectorList(Site site, Subsite sub) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
        alignment: Alignment.topCenter,
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: sub.sectors.length,
            itemBuilder: (BuildContext context, int index) {
              // Return a card only if the search term is found in name/code.
              return SectorCard(
                key: sub.sectors[index].key,
                sector: sub.sectors[index],
                callback: refresh,
                working: _downloading || _uploading,
              );
            },
          ),
        ),
      ),
    );
  }

  Future downloadSite(Site site, bool partial) async {
    bool foundStop = true;
    int leftOff = _tabKey.currentState.getCurrentPosition();
    _tabKey.currentState.toggleScrollable();

    setState(() {
      _downloading = true;
    });

    for (Subsite sub in site.subsites) {
      await Future.delayed(Duration(milliseconds: 200));
      _tabKey.currentState.animateTo(site.subsites.indexOf(sub));
      await Future.delayed(Duration(milliseconds: 500));
      for (Sector sec in sub.sectors) {
        if (partial && foundStop) {
          if (sec.downloading != true) {
            continue;
          } else {
            foundStop = false;
          }
        }

        sec.downloading = true;
        sec.key.currentState.refresh();

        List<String> images = await getPhotosInCloudFolder(sec.getCloudPath());

        sec.key.currentState.setDownloadCount(images.length);
        sec.key.currentState.refresh();

        for (String imageBasename in images) {
          String localPath = ph.join(sec.getDirectory().path, imageBasename);
          String cloudPath = ph.join(sec.getCloudPath(), imageBasename);

          bool fileExists = await File(localPath).exists();

          final StorageReference storageRef =
              FirebaseStorage.instance.ref().child(cloudPath);

          String url = "";
          url = await storageRef.getDownloadURL();

          if (!fileExists) {
            var imageBytes = await http.get(url);
            File file = new File(localPath);
            file.createSync(recursive: true);
            file.writeAsBytesSync(imageBytes.bodyBytes);
          }
          sec.key.currentState
              .setDownloadCount(sec.key.currentState.getDownloadCount() - 1);

          sec.key.currentState.refresh();
          await Future.delayed(Duration(milliseconds: 200));
        }

        sec.downloading = false;
        sec.key.currentState.refreshProgress();
      }
    }

    _tabKey.currentState.animateTo(leftOff);
    _tabKey.currentState.toggleScrollable();

    setState(() {
      _downloading = false;
    });
  }

  Future syncSite(Site site, bool partial) async {
    bool foundStop = true;
    int leftOff = _tabKey.currentState.getCurrentPosition();
    _tabKey.currentState.toggleScrollable();

    setState(() {
      _uploading = true;
    });

    for (Subsite sub in site.subsites) {
      await Future.delayed(Duration(milliseconds: 200));
      _tabKey.currentState.animateTo(site.subsites.indexOf(sub));
      await Future.delayed(Duration(milliseconds: 500));
      for (Sector sec in sub.sectors) {
        if (partial && foundStop) {
          if (sec.uploading != true) {
            continue;
          } else {
            foundStop = false;
          }
        }

        sec.uploading = true;
        sec.key.currentState.refresh();

        List<TaskImage> sectorPhotos = sec.getLocalPhotos();

        for (TaskImage k in sectorPhotos) {
          if (!k.isCloud) {
            await syncPhoto(k, showTransactionError);
          }

          setState(() {});
        }

        sec.uploading = false;
        sec.key.currentState.refreshProgress();
      }
    }

    _tabKey.currentState.animateTo(leftOff);
    _tabKey.currentState.toggleScrollable();

    setState(() {
      _uploading = false;
    });
  }

  void showTransactionError() {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        backgroundColor: Color.fromRGBO(209, 25, 62, 1),
        content: Text(
          "There was an issue performing a cloud operation.",
          style: TextStyle(
            fontSize: ScreenUtil().setSp(36),
          ),
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget showNoteList(Site site) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
        alignment: Alignment.center,
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: FutureBuilder(
            future: site.getIssues(),
            builder: (context, AsyncSnapshot snapshot) {
              List<SiteNote> notes = snapshot.data;

              if (snapshot.data == null) {
                return Container(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                  alignment: Alignment.center,
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height / 6),
                          ImageIcon(
                            AssetImage("images/icons/icon_add_issue.png"),
                            color: Colors.white.withOpacity(0.8),
                            size: ScreenUtil().setSp(96),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "No reported issues fetched",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                              fontSize: ScreenUtil().setSp(60),
                              fontFamily: "Quicksand",
                            ),
                          ),
                          SizedBox(height: 96),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.connectionState != ConnectionState.done) {
                return Container(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                  alignment: Alignment.center,
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height / 6),
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white70),
                            strokeWidth: 2,
                          ),
                          SizedBox(height: 96),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: notes.length,
                itemBuilder: (BuildContext context, int index) {
                  // Return a card only if the search term is found in name/code.
                  return NoteCard(
                    site: site,
                    note: notes[index],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void showReportDialog(BuildContext context) async {
    TextEditingController _controller = new TextEditingController();

    Widget logout = FlatButton(
      child: Text(
        "REPORT ISSUE",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.red,
          fontSize: 16,
        ),
      ),
      onPressed: () async {
        try {
          _tabKey.currentState.animateTo(site.subsites.length);
          // Pop the sign-out dialog.

          if (_controller.text.isNotEmpty) {
            DateTime now = await NTP.now();
            FirebaseUser user = await gUserAuth.getCurrentUser();

            SiteNote note = SiteNote.create(
                _controller.text, user.uid, now.millisecondsSinceEpoch);

            await widget.site.addIssue(note);
            setState(() {});
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
            "Report a site issue",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
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
                  borderSide: BorderSide(
                    color: Colors.black,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.zero,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.zero,
                ),
                hintText: 'Enter details',
                hintStyle: TextStyle(
                  fontSize: 16,
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

  void refresh() {
    setState(() {});
  }
}

/* Populates showSectorList(), contains sector progress bar 

   selection -> UserSelection: Site, sub and sec for passing parameters */
class SectorCard extends StatefulWidget {
  final Sector sector;
  final VoidCallback callback;
  final bool working;

  const SectorCard({
    Key key,
    @required this.sector,
    this.callback,
    this.working,
  }) : super(key: key);

  @override
  SectorCardState createState() => SectorCardState(this.sector);
}

/* State for SectorCard */
class SectorCardState extends State<SectorCard> {
  final Sector sector;
  int _downloadCount;
  double _sectorProgress;
  Color _sectorProgressColor;
  List<int> _cloudPhotos;

  SectorCardState(this.sector);

  void refreshProgress() {
    setState(() {
      double localProgress = sector.getSectorProgress();

      if (_sectorProgress < localProgress) {
        _sectorProgress = localProgress;
      }

      updateSectorCloudProgress();
    });
  }

  void refresh() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _downloadCount = 0;
    _sectorProgress = sector.getSectorProgress();
    _sectorProgressColor = sector.getSectorProgressColor();

    updateSectorCloudProgress();
  }

  void updateSectorCloudProgress() {
    sector.getSectorCloudProgress().then(
          (onValue) => {
            if (mounted)
              {
                setState(() {
                  _cloudPhotos = onValue;
                  List<int> localPhotos = sector.getSectorLocalProgress();

                  _sectorProgress =
                      sector.getSectorProgressUpdate(localPhotos, _cloudPhotos);

                  if (_sectorProgress == 1.0 &&
                      sector.getUnsyncedPhotos() == 0) {
                    _sectorProgressColor = Colors.greenAccent[700];
                  } else {
                    _sectorProgressColor = Colors.yellow[700];
                  }
                })
              }
          },
        );
  }

  void setDownloadCount(int count) {
    _downloadCount = count;
  }

  int getDownloadCount() {
    return _downloadCount;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: widget.working && !sector.inTransaction()
            ? Colors.grey[300]
            : Colors.white,
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
            if (!widget.working) {
              Get.to(
                SectorPage(
                  sector: sector,
                  photos: _cloudPhotos,
                  progress: _sectorProgress,
                  color: _sectorProgressColor,
                ),
              ).then((onValue) {
                refreshProgress();
                widget.callback();
              });
            }
          },
          child: Stack(
            alignment: AlignmentDirectional.bottomStart,
            children: [
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        sector.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: ScreenUtil().setSp(42),
                            fontWeight: FontWeight.w600,
                            color: Colors.black),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        sector.getUnsynced() || sector.downloading
                            ? showUnsyncedCount()
                            : Container(),
                        sector.inTransaction()
                            ? showLoading(sector.downloading)
                            : Icon(
                                Icons.chevron_right,
                                color: Colors.black54,
                                size: ScreenUtil().setSp(42),
                              )
                      ],
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: LinearPercentIndicator(
                  animateFromLastPercent: true,
                  animation: true,
                  lineHeight: 4.0,
                  animationDuration: 300,
                  padding: EdgeInsets.zero,
                  linearStrokeCap: LinearStrokeCap.butt,
                  percent: _sectorProgress,
                  progressColor: _sectorProgressColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget showUnsyncedCount() {
    IconData unsyncIcon;
    int unsynced;
    Color unsyncColor;

    if (sector.downloading) {
      unsyncIcon = Icons.cloud_download;
      unsynced = _downloadCount;
      unsyncColor = Colors.blue;
    } else {
      unsyncIcon = Icons.cloud_off;
      unsynced = sector.getUnsyncedPhotos();
      unsyncColor = Colors.yellow[700];
    }

    String suffix;

    if (unsynced == 1) {
      suffix = " photo ";
    } else {
      suffix = " photos ";
    }

    if (unsynced == 0) {
      return Container();
    } else {
      return Row(
        children: [
          Icon(
            unsyncIcon,
            color: unsyncColor,
            size: ScreenUtil().setSp(42),
          ),
          Text(
            " " + unsynced.toString() + suffix,
            style: TextStyle(
              fontSize: ScreenUtil().setSp(42),
              color: unsyncColor,
            ),
          ),
        ],
      );
    }
  }

  Widget showLoading(bool downloading) {
    return Container(
      height: 24,
      width: 24,
      child: Center(
        child: SizedBox(
          height: 12,
          width: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: downloading
                ? AlwaysStoppedAnimation(Colors.blue)
                : AlwaysStoppedAnimation(Colors.greenAccent),
          ),
        ),
      ),
    );
  }
}

class NoteCard extends StatefulWidget {
  final Site site;
  final SiteNote note;

  const NoteCard({Key key, @required this.site, this.note}) : super(key: key);

  @override
  NoteCardState createState() => NoteCardState(this.site, this.note);
}

/* State for SectorCard */
class NoteCardState extends State<NoteCard> {
  final Site site;
  final SiteNote note;

  NoteCardState(this.site, this.note);

  @override
  Widget build(BuildContext context) {
    if (note.resolved) {
      return Container(
        margin: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.green[300],
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
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '"' + note.contents + '"',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Reported on " + note.getTimeString(note.reportTime),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: ScreenUtil().setSp(24),
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.64),
                    ),
                    textAlign: TextAlign.right,
                  ),
                  Text(
                    "Resolved on " + note.getTimeString(note.resolveTime),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: ScreenUtil().setSp(24),
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.36),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return Container(
        margin: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.red[300],
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
              showResolveDialog();
            },
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '"' + note.contents + '"',
                    style: TextStyle(
                      fontSize: ScreenUtil().setSp(36),
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Reported on " + note.getTimeString(note.reportTime),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: ScreenUtil().setSp(24),
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.64),
                    ),
                    textAlign: TextAlign.right,
                  ),
                  Text(
                    "Click to resolve this issue",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: ScreenUtil().setSp(24),
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.36),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  void showResolveDialog() async {
    Widget resolve = FlatButton(
      child: Text(
        "RESOLVE ISSUE",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.green,
          fontSize: ScreenUtil().setSp(40),
        ),
      ),
      onPressed: () async {
        try {
          // Pop the sign-out dialog.
          Site site = widget.site;
          SiteNote note = widget.note;

          DateTime now = await NTP.now();

          note.resolveTime = now.millisecondsSinceEpoch;
          note.resolved = true;

          site.addIssue(note);

          setState(() {});
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
            "Resolve this issue?",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: ScreenUtil().setSp(42),
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              widget.note.contents,
              style: TextStyle(
                fontSize: ScreenUtil().setSp(40),
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          actions: [resolve, cancel],
        );
      },
    );
  }
}
