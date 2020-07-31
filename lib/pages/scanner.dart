import 'dart:io';
import "dart:ui";

import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:file_picker/file_picker.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import "package:get/get.dart";

import 'package:tfsitescape/main.dart';
import 'package:tfsitescape/pages/camera_scan.dart';
import 'package:tfsitescape/services/modal.dart';
import 'package:tfsitescape/services/ui.dart';

class ScannerPage extends StatefulWidget {
  ScannerPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new ScannerPageState();
}

/* State for SearchPage */
class ScannerPageState extends State<ScannerPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  List<ScannerPair> _scannerHistory;
  TextEditingController _controller;

  @override
  void initState() {
    _scannerHistory = getScanner();
    _controller = new TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      extendBody: true,
      backgroundColor: Theme.of(context).primaryColor,
      body: Stack(
        children: [
          showBottomArt(),
          ListView(
            shrinkWrap: true,
            padding: EdgeInsets.fromLTRB(16, 116, 16, 64),
            children: [
              // Search Bar
              showAddEntry(),
              showEntries(),
              // siteDisplay(context, _search)
            ],
          ),
          showTopNavBox(),
          showShareButton(),
          showUploadButton(),
          showBackButton(),
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
    );
  }

  /* On top right offset from share */
  Widget showUploadButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 36, 12, 0),
        height: 96,
        width: 96,
        margin: EdgeInsets.only(right: 64),
        child: FittedBox(
          child: FlatButton(
            onPressed: () async {
              _scannerHistory = await uploadTextFile(_scannerHistory);
              setScanner(_scannerHistory);
              setState(() {});
            },
            color: Colors.transparent,
            child: ImageIcon(
              AssetImage("images/icons/icon_upload.png"),
              size: 32,
              color: Colors.greenAccent,
            ),
            padding: EdgeInsets.all(0.1),
            shape: CircleBorder(),
          ),
        ),
      ),
    );
  }

  /* On top right */
  Widget showShareButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 36, 12, 0),
        height: 96,
        width: 96,
        child: FittedBox(
          child: FlatButton(
            onPressed: () async {
              shareScanner(_scannerHistory);
            },
            color: Colors.transparent,
            child: ImageIcon(
              AssetImage("images/icons/icon_share.png"),
              size: 32,
              color: Colors.blueAccent,
            ),
            padding: EdgeInsets.all(0.1),
            shape: CircleBorder(),
          ),
        ),
      ),
    );
  }

  Widget showOutput(IconData icon, String title, String units,
      TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: TextAlign.end,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[300].withOpacity(0.7),
          ),
        ),
        TextField(
          autofocus: false,
          textAlign: TextAlign.center,
          controller: _controller,
          enabled: false,
          decoration: InputDecoration(
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding:
                EdgeInsets.only(left: 48, right: 16, top: 15, bottom: 11),
            suffixText: units,
            suffixStyle: TextStyle(
                color: Colors.grey[300].withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w600),
            hintText: "Input a proper value",
            hintStyle: TextStyle(
              color: Colors.grey[300].withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          // Must be valid entry
        ),
      ],
    );
  }

  Widget showFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () async {
        bool hasEmpties = false;
        for (int i = 0; i < _scannerHistory.length; i++) {
          if (_scannerHistory[i].value.isEmpty) {
            hasEmpties = true;
          }
        }

        if (hasEmpties) {
          String result = await Get.to(
            CameraScanScreen(camera: gCam),
          );

          if (result != null) {
            for (int i = 0; i < _scannerHistory.length; i++) {
              if (_scannerHistory[i].value.isEmpty) {
                _scannerHistory[i].value = result;
                break;
              }
            }
            setScanner(_scannerHistory);
            setState(() {});
          }
        } else {
          showNoEmpties();
        }
      },
      elevation: 10,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Container(
          padding: EdgeInsets.all(12),
          child: ImageIcon(AssetImage("images/home/icon_scanner.png"),
              size: 48, color: Colors.white),
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
    );
  }

  Widget showScannerCard(int index, ScannerPair pair) {
    return Container(
      margin: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(1),
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
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // Stretch the cards in horizontal axis
                  children: [
                    new Text(
                      pair.key,
                      style: TextStyle(
                        fontSize: ScreenUtil().setSp(42),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5),
                    new Text(
                      (pair.value.isEmpty) ? "Value to be scanned" : pair.value,
                      style: (pair.value.isEmpty)
                          ? new TextStyle(
                              color: Colors.black54,
                              fontStyle: FontStyle.italic,
                              fontSize: ScreenUtil().setSp(36),
                            )
                          : new TextStyle(
                              color: Colors.black54,
                              fontSize: ScreenUtil().setSp(36),
                            ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: ImageIcon(
                      AssetImage("images/icons/icon_delete.png"),
                      size: 24,
                    ),
                    color: Colors.red,
                    onPressed: () {
                      setState(() {
                        _scannerHistory.removeAt(index);
                        setScanner(_scannerHistory);
                      });
                    },
                  ),
                  SizedBox(width: 12),
                  (pair.value.isNotEmpty)
                      ? IconButton(
                          icon: ImageIcon(
                            AssetImage("images/icons/icon_copy.png"),
                            size: 24,
                          ),
                          color: Colors.blue,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: pair.value));
                          })
                      : IconButton(
                          icon: ImageIcon(
                            AssetImage("images/icons/icon_copy.png"),
                            size: 24,
                          ),
                          disabledColor: Colors.grey,
                          onPressed: null,
                        )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showNoEmpties() {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(
          "No empty value entries to start scanning for. " +
              "Add an entry with the field above before you begin " +
              "scanning with your camera.",
        ),
        backgroundColor: Theme.of(context).accentColor,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget showAddEntry() {
    return Container(
      margin: EdgeInsets.only(left: 12, right: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: TextField(
        onSubmitted: (entry) {
          if (entry.isNotEmpty) {
            _controller.clear();
            _scannerHistory.add(new ScannerPair(entry, ""));
            setScanner(_scannerHistory);
            setState(() {});
          }
        },
        controller: _controller,
        textCapitalization: TextCapitalization.none,
        autofocus: false,
        keyboardType: TextInputType.emailAddress,
        cursorColor: Colors.grey,
        obscureText: false,
        showCursor: true,
        decoration: InputDecoration(
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          isDense: true,
          prefixIconConstraints: BoxConstraints(
            minWidth: ScreenUtil().setSp(42),
            minHeight: ScreenUtil().setSp(42),
          ),
          suffixIconConstraints: BoxConstraints(
            minWidth: ScreenUtil().setSp(42),
            minHeight: ScreenUtil().setSp(42),
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(
              left: ScreenUtil().setWidth(42),
              right: ScreenUtil().setWidth(21),
            ),
            child: ImageIcon(
              AssetImage(
                "images/icons/icon_entry.png",
              ),
              color: Colors.grey,
              size: ScreenUtil().setSp(42),
            ),
          ),
          suffixIcon: Padding(
            padding: EdgeInsets.only(
              right: ScreenUtil().setWidth(21),
            ),
            child: new IconButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  _scannerHistory.add(new ScannerPair(_controller.text, ""));
                  setScanner(_scannerHistory);
                  setState(() {});
                  _controller.clear();
                }
              },
              icon: ImageIcon(
                AssetImage(
                  "images/icons/icon_caret_right.png",
                ),
                color: Colors.grey,
                size: ScreenUtil().setSp(42),
              ),
            ),
          ),
          contentPadding:
              EdgeInsets.symmetric(vertical: ScreenUtil().setWidth(26)),
          hintText: 'Add an entry name',
          hintStyle: TextStyle(
            color: Colors.grey,
            fontSize: ScreenUtil().setSp(42),
            fontWeight: FontWeight.w400,
          ),
        ),
        style: TextStyle(
          color: Colors.black,
          fontSize: ScreenUtil().setSp(42),
          fontWeight: FontWeight.w400,
        ),
        // Must be valid entry
      ),
    );
  }

  Widget showEntries() {
    if (_scannerHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height / 3),
            ImageIcon(
              AssetImage("images/icons/icon_entry.png"),
              color: Colors.white.withOpacity(0.8),
              size: ScreenUtil().setSp(96),
            ),
            SizedBox(height: 10),
            Text(
              "Add or import an entry to scan",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontFamily: "Quicksand",
                  fontWeight: FontWeight.w500,
                  fontSize: ScreenUtil().setSp(60)),
            )
          ],
        ),
      );
    } else {
      return Container(
        child: ListView.builder(
          shrinkWrap: true,
          primary: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _scannerHistory.length,
          itemBuilder: (BuildContext context, int index) {
            // Return a card only if the search term is found in name/code.
            return showScannerCard(index, _scannerHistory[index]);
          },
        ),
      );
    }
  }
}

class ScannerPair {
  String key;
  String value;

  ScannerPair(this.key, this.value);
}

List<ScannerPair> getScanner() {
  String scannerDir = gExtDir.path + "/.scanner";
  File scanner = File(scannerDir);

  List<ScannerPair> scannerList = [];
  if (scanner.existsSync()) {
    List<String> scannerValues = scanner.readAsStringSync().split("\n");
    print(scannerValues);
    if (scannerValues.length % 2 == 0) {
      return scannerList;
    } else {
      for (int i = 0; i < scannerValues.length - 1; i += 2) {
        scannerList.add(
          new ScannerPair(scannerValues[i], scannerValues[i + 1]),
        );
      }
    }
  }
  return scannerList;
}

void setScanner(List<ScannerPair> updated) {
  String scannerDir = gExtDir.path + "/.scanner";
  File scanner = File(scannerDir);

  scanner.createSync();

  String toWrite = "";
  for (int i = 0; i < updated.length; i++) {
    String valueToPrint;
    if (updated[i].value == null) {
      valueToPrint = "";
    } else {
      valueToPrint = updated[i].value;
    }

    toWrite = toWrite + updated[i].key + "\n" + valueToPrint + "\n";
  }

  print(toWrite);

  scanner.writeAsStringSync(toWrite);
}

void shareScanner(List<ScannerPair> updated) {
  String scannerDir = gExtDir.path + "/.scanner";
  File scanner = File(scannerDir);

  scanner.createSync();

  String keys = "ITEM ENTRIES";
  String values = "SCANNED VALUES";
  for (int i = 0; i < updated.length; i++) {
    keys = keys + "\n" + updated[i].key;
    values = values + "\n" + updated[i].value;
  }

  Share.text(
      "Sitescape - Share scanner values", keys + "\n\n" + values, "text/plain");
}

Future<List<ScannerPair>> uploadTextFile(List<ScannerPair> entries) async {
  File file = await FilePicker.getFile(
    type: FileType.custom,
    allowedExtensions: ['txt'],
  );

  List<String> keys = file.readAsStringSync().split("\n");
  for (String key in keys) {
    entries.add(
      ScannerPair(key, ""),
    );
  }

  return entries;
}
