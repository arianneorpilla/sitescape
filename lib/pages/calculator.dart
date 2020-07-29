import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import 'package:flutter_screenutil/flutter_screenutil.dart';
import "package:get/get.dart";

import 'package:tfsitescape/services/modal.dart';

class CalculatorPage extends StatefulWidget {
  CalculatorPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new CalculatorPageState();
}

enum CalculatorValues {
  CHR_RSL_VALUE_LER,
  CHR_AGC_VALUE,
  ERIC_RSL_VALUE_LER,
  ERIC_AGC_VALUE
}

/* State for SearchPage */
class CalculatorPageState extends State<CalculatorPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  // For search term, used for filtering
  String chrAGCValue;
  String chrRSLValueLER;

  String eAGCValue;
  String eRSLValueLER;

  TextEditingController chrIV;
  TextEditingController chrSPV;
  TextEditingController chrBPV;
  TextEditingController chrRSLV;

  TextEditingController eIV;
  TextEditingController eSPV;
  TextEditingController eBPV;
  TextEditingController eRSLV;

  @override
  void initState() {
    // Show first 10 Sites alphabetically
    chrAGCValue = "";
    chrRSLValueLER = "";

    chrIV = new TextEditingController();
    chrSPV = new TextEditingController();
    chrBPV = new TextEditingController();
    chrRSLV = new TextEditingController();

    eAGCValue = "";
    eRSLValueLER = "";

    eIV = new TextEditingController();
    eSPV = new TextEditingController();
    eBPV = new TextEditingController();
    eRSLV = new TextEditingController();

    super.initState();
  }

  void updateValues() {
    print(chrAGCValue);

    try {
      double numCHRRSLValueLER = double.parse(chrRSLValueLER);

      chrIV.text = ((numCHRRSLValueLER) / 100 + 1).toStringAsFixed(3);
      chrSPV.text = (((numCHRRSLValueLER) + 1) / 100 + 1).toStringAsFixed(3);
      chrBPV.text = (((numCHRRSLValueLER) + 2) / 100 + 1).toStringAsFixed(3);
    } catch (e) {
      print(e);
      chrIV.clear();
      chrSPV.clear();
      chrBPV.clear();
    }

    try {
      double numCHRAGCVal = double.parse(chrAGCValue);

      chrRSLV.text = ((numCHRAGCVal - 1) * 100).toStringAsFixed(3);
    } catch (e) {
      print(e);
      chrRSLV.clear();
    }

    try {
      double numERSLValueLER = double.parse(eRSLValueLER);

      eIV.text = ((120 - numERSLValueLER) / 40).toStringAsFixed(3);
      eSPV.text = ((120 - (numERSLValueLER + 1)) / 40).toStringAsFixed(3);
      eBPV.text = ((120 - (numERSLValueLER + 2)) / 40).toStringAsFixed(3);
    } catch (e) {
      print(e);
      eIV.clear();
      eSPV.clear();
      eBPV.clear();
    }

    try {
      double numEAGCVal = double.parse(eAGCValue);

      eRSLV.text = (120 - (numEAGCVal * 40)).toStringAsFixed(3);
    } catch (e) {
      print(e);
      eRSLV.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    updateValues();

    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      extendBody: true,
      backgroundColor: Theme.of(context).primaryColor,
      body: Stack(
        children: [
          Expanded(
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
                    Theme.of(context).primaryColor,
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: new ListView(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height / 6),
                Container(
                  child: Text(
                    "Ceragon / Harris / RTN",
                    style: TextStyle(
                      fontSize: ScreenUtil().setSp(72),
                      fontFamily: "Quicksand",
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                showInputBox(
                  CalculatorValues.CHR_RSL_VALUE_LER,
                  Icons.show_chart,
                  "Enter RSL Value from LER",
                  "-dBm",
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(51, 57, 104, 0.7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      showOutput(
                        Icons.exposure_zero,
                        "Ideal Value",
                        "AGC Volts",
                        chrIV,
                      ),
                      showOutput(
                        Icons.exposure_plus_1,
                        "Safe Passing Value",
                        "AGC Volts",
                        chrSPV,
                      ),
                      showOutput(
                        Icons.exposure_plus_2,
                        "Borderline Passing Value",
                        "AGC Volts",
                        chrBPV,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(30, 15, 30, 15),
                ),
                showInputBox(
                  CalculatorValues.CHR_AGC_VALUE,
                  Icons.flash_on,
                  "Enter AGC Value",
                  "AGC Volts",
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(51, 57, 104, 0.7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      showOutput(
                        Icons.show_chart,
                        "RSL Value",
                        "-dBm",
                        chrRSLV,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(30, 15, 30, 15),
                ),
                SizedBox(height: MediaQuery.of(context).size.height / 8),
                Container(
                  child: Text(
                    "Ericsson",
                    style: TextStyle(
                      fontSize: ScreenUtil().setSp(72),
                      fontFamily: "Quicksand",
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                showInputBox(
                  CalculatorValues.ERIC_RSL_VALUE_LER,
                  Icons.show_chart,
                  "Enter RSL Value from LER",
                  "-dBm",
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(51, 57, 104, 0.7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      showOutput(
                        Icons.exposure_zero,
                        "Ideal Value",
                        "AGC Volts",
                        eIV,
                      ),
                      showOutput(
                        Icons.exposure_plus_1,
                        "Safe Passing Value",
                        "AGC Volts",
                        eSPV,
                      ),
                      showOutput(
                        Icons.exposure_plus_2,
                        "Borderline Passing Value",
                        "AGC Volts",
                        eBPV,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(30, 15, 30, 15),
                ),
                showInputBox(
                  CalculatorValues.ERIC_AGC_VALUE,
                  Icons.flash_on,
                  "Enter AGC Value",
                  "AGC Volts",
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(51, 57, 104, 0.7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      showOutput(
                        Icons.show_chart,
                        "RSL Value",
                        "-dBm",
                        eRSLV,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(30, 15, 30, 15),
                ),
                SizedBox(height: MediaQuery.of(context).size.height / 5),
              ],
            ),
          ),
          showBackButton(),
        ],
      ),
      // floatingActionButton: showFloatingActionButton(),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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

  Widget showOutput(IconData icon, String title, String units,
      TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: TextAlign.end,
          style: TextStyle(
            fontFamily: "Quicksand",
            fontSize: ScreenUtil().setSp(36),
            fontWeight: FontWeight.w600,
            color: Colors.grey[300].withOpacity(0.7),
          ),
        ),
        TextField(
          autofocus: false,
          textAlign: TextAlign.center,
          controller: controller,
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
                fontSize: ScreenUtil().setSp(36),
                fontWeight: FontWeight.w600),
            hintText: "Input a proper value",
            hintStyle: TextStyle(
              color: Colors.grey[300].withOpacity(0.5),
              fontSize: ScreenUtil().setSp(42),
              fontWeight: FontWeight.w300,
            ),
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: ScreenUtil().setSp(42),
          ),
          // Must be valid entry
        ),
      ],
    );
  }

  Widget showInputBox(CalculatorValues valueToChange, IconData icon,
      String caption, String suffix) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        0,
        ScreenUtil().setHeight(16),
        0,
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
          onTap: () {},
          child: TextField(
            onChanged: ((val) async {
              setState(() {
                switch (valueToChange) {
                  case CalculatorValues.CHR_RSL_VALUE_LER:
                    chrRSLValueLER = val;
                    break;
                  case CalculatorValues.CHR_AGC_VALUE:
                    chrAGCValue = val;
                    break;
                  case CalculatorValues.ERIC_RSL_VALUE_LER:
                    eRSLValueLER = val;
                    break;
                  case CalculatorValues.ERIC_AGC_VALUE:
                    eAGCValue = val;
                    break;
                }
              });
            }),
            textCapitalization: TextCapitalization.none,
            autofocus: false,

            keyboardType:
                TextInputType.numberWithOptions(decimal: true, signed: false),
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
                icon,
                size: ScreenUtil().setSp(48),
                color: Colors.grey,
              ),
              suffixText: suffix,
              suffixStyle: TextStyle(
                  color: Colors.grey[800],
                  fontSize: ScreenUtil().setSp(42),
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic),
              hintText: caption,
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

  /* Used for cloud sync */
  Widget showFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: Colors.black.withOpacity(0.25),
      child: Icon(Icons.cloud_upload, size: 36),
      elevation: 0,
      onPressed: () {
        setState(() {});
      },
    );
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
}
