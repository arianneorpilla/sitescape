import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
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
    super.initState();
    // Show first 10 sites alphabetically
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
            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: new ListView(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height / 4),
                Container(
                  child: Text(
                    "Ceragon / Harris / RTN",
                    style: TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.w100,
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
                InkWell(
                  child: Card(
                    color: Colors.black.withOpacity(0.4),
                    child: Container(
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
                    elevation: 10,
                  ),
                  onTap: () {},
                ),
                showInputBox(
                  CalculatorValues.CHR_AGC_VALUE,
                  Icons.flash_on,
                  "Enter AGC Value",
                  "AGC Volts",
                ),
                InkWell(
                  child: Card(
                    color: Colors.black.withOpacity(0.4),
                    child: Container(
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
                    elevation: 10,
                  ),
                  onTap: () {},
                ),
                SizedBox(height: MediaQuery.of(context).size.height / 8),
                Container(
                  child: Text(
                    "Ericsson",
                    style: TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.w100,
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
                InkWell(
                  child: Card(
                    color: Colors.black.withOpacity(0.4),
                    child: Container(
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
                    elevation: 10,
                  ),
                  onTap: () {},
                ),
                showInputBox(
                  CalculatorValues.ERIC_AGC_VALUE,
                  Icons.flash_on,
                  "Enter AGC Value",
                  "AGC Volts",
                ),
                InkWell(
                  child: Card(
                    color: Colors.black.withOpacity(0.35),
                    child: Container(
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
                    elevation: 10,
                  ),
                  onTap: () {},
                ),
                SizedBox(height: MediaQuery.of(context).size.height / 3),
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
        // shape: CircularNotchedRectangle(),
        elevation: 0,
        color: Colors.black.withOpacity(0.25),
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

  Widget showInputBox(CalculatorValues valueToChange, IconData icon,
      String caption, String suffix) {
    return Card(
      child: Container(
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
              color: Colors.grey,
            ),
            suffixText: suffix,
            suffixStyle: TextStyle(
                color: Colors.grey[800],
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic),
            hintText: caption,
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
