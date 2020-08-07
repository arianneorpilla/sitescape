import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:sitescape/services/modal.dart';
import 'package:sitescape/services/ui.dart';
import 'package:sitescape/services/util.dart';

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
  String _chrAGCValue;
  String _chrRSLValueLER;

  String _eAGCValue;
  String _eRSLValueLER;

  TextEditingController _chrIV;
  TextEditingController _chrSPV;
  TextEditingController _chrBPV;
  TextEditingController _chrRSLV;

  TextEditingController _eIV;
  TextEditingController _eSPV;
  TextEditingController _eBPV;
  TextEditingController _eRSLV;

  @override
  void initState() {
    // Show first 10 Sites alphabetically
    _chrAGCValue = "";
    _chrRSLValueLER = "";

    _chrIV = new TextEditingController();
    _chrSPV = new TextEditingController();
    _chrBPV = new TextEditingController();
    _chrRSLV = new TextEditingController();

    _eAGCValue = "";
    _eRSLValueLER = "";

    _eIV = new TextEditingController();
    _eSPV = new TextEditingController();
    _eBPV = new TextEditingController();
    _eRSLV = new TextEditingController();

    super.initState();
  }

  @override
  void dispose() {
    _chrIV.dispose();
    _chrSPV.dispose();
    _chrBPV.dispose();
    _chrRSLV.dispose();

    _eIV.dispose();
    _eSPV.dispose();
    _eBPV.dispose();
    _eRSLV.dispose();

    super.dispose();
  }

  void updateValues() {
    print(_chrAGCValue);

    try {
      double numCHRRSLValueLER = double.parse(_chrRSLValueLER);

      _chrIV.text = ((numCHRRSLValueLER) / 100 + 1).toStringAsFixed(3);
      _chrSPV.text = (((numCHRRSLValueLER) + 1) / 100 + 1).toStringAsFixed(3);
      _chrBPV.text = (((numCHRRSLValueLER) + 2) / 100 + 1).toStringAsFixed(3);
    } catch (e) {
      print(e);
      _chrIV.clear();
      _chrSPV.clear();
      _chrBPV.clear();
    }

    try {
      double numCHRAGCVal = double.parse(_chrAGCValue);

      _chrRSLV.text = ((numCHRAGCVal - 1) * 100).toStringAsFixed(3);
    } catch (e) {
      print(e);
      _chrRSLV.clear();
    }

    try {
      double numERSLValueLER = double.parse(_eRSLValueLER);

      _eIV.text = ((120 - numERSLValueLER) / 40).toStringAsFixed(3);
      _eSPV.text = ((120 - (numERSLValueLER + 1)) / 40).toStringAsFixed(3);
      _eBPV.text = ((120 - (numERSLValueLER + 2)) / 40).toStringAsFixed(3);
    } catch (e) {
      print(e);
      _eIV.clear();
      _eSPV.clear();
      _eBPV.clear();
    }

    try {
      double numEAGCVal = double.parse(_eAGCValue);

      _eRSLV.text = (120 - (numEAGCVal * 40)).toStringAsFixed(3);
    } catch (e) {
      print(e);
      _eRSLV.clear();
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
          showBottomArt(),
          showCalculatorWidgets(),
          showTopNavBox(),
          showBackButton(),
          showStatusBarBox(),
        ],
      ),
      // floatingActionButton: showFloatingActionButton(),
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
                    launchURL();
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

  Widget showCalculatorWidgets() {
    return Container(
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
                fontWeight: FontWeight.w300,
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
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(42, 47, 93, 0.85),
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
                  _chrIV,
                ),
                showOutput(
                  Icons.exposure_plus_1,
                  "Safe Passing Value",
                  "AGC Volts",
                  _chrSPV,
                ),
                showOutput(
                  Icons.exposure_plus_2,
                  "Borderline Passing Value",
                  "AGC Volts",
                  _chrBPV,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(30, 30, 30, 15),
          ),
          SizedBox(height: 8),
          showInputBox(
            CalculatorValues.CHR_AGC_VALUE,
            Icons.flash_on,
            "Enter AGC Value",
            "AGC Volts",
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(42, 47, 93, 0.85),
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
                  _chrRSLV,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(30, 15, 30, 15),
          ),
          SizedBox(height: MediaQuery.of(context).size.height / 16),
          Container(
            child: Text(
              "Ericsson",
              style: TextStyle(
                fontSize: ScreenUtil().setSp(72),
                fontFamily: "Quicksand",
                color: Colors.white,
                fontWeight: FontWeight.w300,
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
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(42, 47, 93, 0.85),
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
                  _eIV,
                ),
                showOutput(
                  Icons.exposure_plus_1,
                  "Safe Passing Value",
                  "AGC Volts",
                  _eSPV,
                ),
                showOutput(
                  Icons.exposure_plus_2,
                  "Borderline Passing Value",
                  "AGC Volts",
                  _eBPV,
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
              color: Color.fromRGBO(42, 47, 93, 0.85),
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
                  _eRSLV,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(30, 15, 30, 15),
          ),
          SizedBox(height: MediaQuery.of(context).size.height / 3),
        ],
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
        child: InkWell(
          onTap: () {},
          child: TextField(
            textAlignVertical: TextAlignVertical.center,
            onChanged: ((val) async {
              setState(() {
                switch (valueToChange) {
                  case CalculatorValues.CHR_RSL_VALUE_LER:
                    _chrRSLValueLER = val;
                    break;
                  case CalculatorValues.CHR_AGC_VALUE:
                    _chrAGCValue = val;
                    break;
                  case CalculatorValues.ERIC_RSL_VALUE_LER:
                    _eRSLValueLER = val;
                    break;
                  case CalculatorValues.ERIC_AGC_VALUE:
                    _eAGCValue = val;
                    break;
                }
              });
            }),
            textCapitalization: TextCapitalization.none,
            inputFormatters: [
              DecimalTextInputFormatter(),
            ],

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
              isDense: true,
              prefixIconConstraints: BoxConstraints(
                minWidth: ScreenUtil().setSp(42),
                minHeight: ScreenUtil().setSp(42),
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(
                  left: ScreenUtil().setWidth(42),
                  right: ScreenUtil().setWidth(21),
                ),
                child: Icon(
                  icon,
                  size: ScreenUtil().setSp(42),
                  color: Colors.grey,
                ),
              ),
              suffix: Padding(
                padding: EdgeInsets.only(
                  left: ScreenUtil().setWidth(26),
                ),
                child: Text(
                  suffix,
                  style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: ScreenUtil().setSp(42),
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic),
                ),
              ),
              contentPadding: EdgeInsets.only(
                top: ScreenUtil().setWidth(26),
                bottom: ScreenUtil().setWidth(26),
                right: ScreenUtil().setWidth(42),
              ),
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
}

class DecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final regEx = RegExp(r"^\d*\.?\d*");
    String newString = regEx.stringMatch(newValue.text) ?? "";
    return newString == newValue.text ? newValue : oldValue;
  }
}
