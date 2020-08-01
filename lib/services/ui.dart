import 'package:flutter/material.dart';
import 'package:flutter_screenutil/screenutil.dart';
import 'package:get/get.dart';

Widget showCloudBottom() {
  return Container(
    margin: EdgeInsets.only(bottom: ScreenUtil().setHeight(200)),
    decoration: BoxDecoration(
      image: DecorationImage(
        alignment: Alignment.bottomCenter,
        fit: BoxFit.contain,
        image: AssetImage('images/login/cloud_bottom.png'),
      ),
    ),
  );
}

Widget showCloudTop() {
  return Container(
    margin: EdgeInsets.only(top: ScreenUtil().setHeight(100)),
    decoration: BoxDecoration(
      image: DecorationImage(
        alignment: Alignment.topCenter,
        fit: BoxFit.contain,
        image: AssetImage('images/login/cloud_top.png'),
      ),
    ),
  );
}

Widget showHill() {
  return Container(
    decoration: BoxDecoration(
      image: DecorationImage(
        alignment: Alignment.bottomCenter,
        fit: BoxFit.contain,
        image: AssetImage('images/login/hill.png'),
      ),
    ),
  );
}

Widget showTower() {
  return Container(
    margin: EdgeInsets.only(bottom: ScreenUtil().setHeight(120)),
    decoration: BoxDecoration(
      image: DecorationImage(
        alignment: Alignment.bottomCenter,
        fit: BoxFit.contain,
        image: AssetImage('images/login/tower.png'),
      ),
    ),
  );
}

Widget showBottomArt() {
  return Container(
    child: Stack(children: [
      showCloudBottom(),
      showTower(),
      showHill(),
    ]),
  );
}

Widget showBottomArtFaded() {
  return Opacity(
    opacity: 0.2,
    child: showBottomArt(),
  );
}

Widget showBackButton({Color color = Colors.transparent}) {
  return Container(
    padding: EdgeInsets.fromLTRB(12, 36, 12, 0),
    height: 96,
    width: 96,
    child: FittedBox(
      child: FlatButton(
        color: color,
        child: ImageIcon(
          AssetImage("images/icons/icon_back.png"),
          size: 34,
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

Widget showBackFloatButton({VoidCallback callback}) {
  return Container(
    padding: EdgeInsets.fromLTRB(12, 36, 12, 0),
    height: 96,
    width: 96,
    child: FittedBox(
      child: FlatButton(
          color: Colors.grey.withOpacity(0.7),
          child: ImageIcon(
            AssetImage("images/icons/icon_back_float.png"),
            size: 34,
            color: Colors.white,
          ),
          padding: EdgeInsets.all(0.1),
          shape: CircleBorder(),
          onPressed: callback ?? () => Get.back()),
    ),
  );
}

Widget showLogo() {
  return Container(
    margin: EdgeInsets.only(top: ScreenUtil().setHeight(220)),
    decoration: BoxDecoration(
      image: DecorationImage(
        alignment: Alignment.topCenter,
        fit: BoxFit.contain,
        image: AssetImage('images/login/logo.png'),
      ),
    ),
  );
}

Widget buildCustomPrefixIcon(IconData iconData) {
  return Container(
    width: 0,
    alignment: Alignment(-0.99, 0.0),
    child: Icon(
      iconData,
    ),
  );
}

Widget showTopNavBox() {
  return Container(
    height: 96,
    color: Color.fromRGBO(55, 63, 125, 1),
  );
}

Widget showStatusBarBox({Color color}) {
  return Container(
    height: ScreenUtil.statusBarHeight,
    color: color ?? Color.fromRGBO(51, 57, 104, 1),
  );
}

Widget showGradientBack() {
  return Builder(builder: (BuildContext context) {
    return Opacity(
      opacity: 0.8,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
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
    );
  });
}
