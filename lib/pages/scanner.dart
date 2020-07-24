import 'dart:io';
import "dart:ui";

import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flushbar/flushbar.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import "package:get/get.dart";

import 'package:tfsitescape/main.dart';
import 'package:tfsitescape/pages/camera_scan.dart';
import 'package:tfsitescape/services/modal.dart';

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
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/login.jpg'),
                colorFilter: new ColorFilter.mode(
                    Colors.indigo.withOpacity(0.7), BlendMode.dstATop),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Container(color: Colors.indigo.withOpacity(0.7)),
            ),
          ),
          ListView(
            shrinkWrap: true,
            padding: EdgeInsets.fromLTRB(16, 96, 16, 64),
            children: [
              // Search Bar
              showAddEntry(),
              showEntries(),
              // siteDisplay(context, _search)
            ],
          ),
          showShareButton(),
          showUploadButton(),
          showBackButton(),
        ],
      ),
      floatingActionButton: showFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
                      content: Text("This feature is under construction."),
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
        shape: CircularNotchedRectangle(),
        elevation: 0,
        color: Colors.black.withOpacity(0.25),
      ),
    );
  }

  /* On top right offset from share */
  Widget showUploadButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 36, 16, 0),
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
            color: Colors.black.withOpacity(0.25),
            child: Icon(
              Icons.file_upload,
              size: 28,
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
        padding: EdgeInsets.fromLTRB(16, 36, 16, 0),
        height: 96,
        width: 96,
        child: FittedBox(
          child: FlatButton(
            onPressed: () async {
              shareScanner(_scannerHistory);
            },
            color: Colors.black.withOpacity(0.25),
            child: Icon(
              Icons.share,
              size: 28,
              color: Colors.blueAccent[400],
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
        backgroundColor: Colors.black.withOpacity(0.25),
        child: Icon(
          Icons.center_focus_weak,
          color: Colors.white,
          size: 36,
        ),
        elevation: 0,
        onPressed: () async {
          bool hasEmpties = false;
          for (int i = 0; i < _scannerHistory.length; i++) {
            if (_scannerHistory[i].value.isEmpty) {
              hasEmpties = true;
            }
          }

          if (hasEmpties) {
            String result = await Get.to(
              CameraScanScreen(camera: cam),
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
        });
  }

  /* On top left */
  Widget showBackButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 36, 16, 0),
      height: 96,
      width: 96,
      child: FittedBox(
        child: FlatButton(
          color: Colors.black.withOpacity(0.25),
          child: Icon(
            Icons.arrow_back,
            size: 28,
            color: Colors.white,
          ),
          padding: EdgeInsets.all(0.1),
          shape: CircleBorder(),
          onPressed: () {
            Get.back();
          },
        ),
      ),
    );
  }

  Widget showScannerCard(int index, ScannerPair pair) {
    return InkWell(
      child: new Card(
        elevation: 5,
        child: new Container(
          padding: const EdgeInsets.all(15.0),
          child: new Row(
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
                        fontSize: 20,
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
                            )
                          : new TextStyle(
                              color: Colors.black54,
                            ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                    ),
                    color: Colors.red,
                    onPressed: () {
                      setState(() {
                        _scannerHistory.removeAt(index);
                        setScanner(_scannerHistory);
                      });
                    },
                  ),
                  (pair.value.isNotEmpty)
                      ? IconButton(
                          icon: Icon(
                            Icons.content_copy,
                            size: 20,
                          ),
                          color: Colors.blue,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: pair.value));
                          })
                      : IconButton(
                          icon: Icon(
                            Icons.content_copy,
                            size: 20,
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
    Flushbar(
      title: "Need to add entry",
      message: "No empty value entries to start scanning for. " +
          "Add an entry with the field above before you begin " +
          "scanning with your camera.",
      duration: Duration(seconds: 5),
      flushbarPosition: FlushbarPosition.TOP,
      animationDuration: Duration(milliseconds: 500),
      shouldIconPulse: false,
    )..show(context);
  }

  Widget showAddEntry() {
    return Card(
      child: Container(
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
            contentPadding: EdgeInsets.all(12.0),
            prefixIcon: Icon(
              Icons.insert_comment,
              color: Colors.grey,
            ),
            suffixIcon: Icon(
              Icons.keyboard_return,
              color: Colors.grey,
            ),
            hintText: "Add an entry name",
            hintStyle: TextStyle(
              color: Colors.grey,
              fontSize: 20,
              fontWeight: FontWeight.w300,
            ),
          ),
          style: TextStyle(color: Colors.black, fontSize: 20),
          // Must be valid entry
        ),
      ),
      elevation: 10,
      color: Colors.white.withOpacity(0.9),
    );
  }

  Widget showEntries() {
    if (_scannerHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height / 3),
            Icon(Icons.insert_comment, color: Colors.white70, size: 36),
            SizedBox(height: 10),
            Text(
              "Add or import an entry to scan",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  fontSize: 24),
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
  String scannerDir = extDir.path + "/.scanner";
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
  String scannerDir = extDir.path + "/.scanner";
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
  String scannerDir = extDir.path + "/.scanner";
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
