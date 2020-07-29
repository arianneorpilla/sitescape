import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tfsitescapeweb/main.dart';
import 'package:tfsitescapeweb/pages/root.dart';
import 'package:tfsitescapeweb/pages/sub.dart';
import 'package:tfsitescapeweb/services/auth.dart';
import 'package:tfsitescapeweb/services/classes.dart';

/* Login page taking a previously initialised Auth and a void function
   which executes after authentication attempt.
   
   auth -> Auth: Needed to pass authentication after login during activities
   loginCallback -> void: Performed after authentication attempt 
*/
class SitePage extends StatefulWidget {
  SitePage({this.auth, this.site, this.create});

  final Auth auth;
  final Site site;
  final bool create;

  @override
  State<StatefulWidget> createState() => new SitePageState(this.site);
}

/* State for SitePage */
class SitePageState extends State<SitePage> {
  Site site;
  SitePageState(this.site);

  final _formKey = new GlobalKey<FormState>();

  final codeController = TextEditingController();
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final buildController = TextEditingController();
  final latController = TextEditingController();
  final longController = TextEditingController();
  final networkController = TextEditingController();

  @override
  void initState() {
    super.initState();

    codeController.text = site.code;
    nameController.text = site.name;
    addressController.text = site.address;
    buildController.text = site.build;
    latController.text = site.latitude == null ? "" : site.latitude.toString();
    longController.text =
        site.longitude == null ? "" : site.longitude.toString();
    networkController.text = site.network;
  }

  // Build the widget.
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).primaryColor,
      body: Stack(
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
          ),
          Center(
            child: Container(
              width: 600,
              height: 900,
              padding: EdgeInsets.all(10),
              color: Colors.black.withOpacity(0.25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  showLogOut(context),
                  Container(
                    padding: EdgeInsets.all(15),
                    margin: EdgeInsets.only(top: 30),
                    child: showForm(),
                  ),
                  Expanded(child: Container()),
                  Container(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      children: [
                        showContinue(context),
                        showCancel(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          // _showCircularProgress(),
        ],
      ),
    );
  }

  Widget showLogOut(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FutureBuilder(
              future: widget.auth.getCurrentUserEmail(),
              builder: (context, AsyncSnapshot<String> snapshot) {
                if (snapshot.data == null) {
                  return Container();
                }

                return new Text(
                  snapshot.data,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w300),
                  textAlign: TextAlign.left,
                );
              }),
          InkWell(
            onTap: () {
              userAuth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => RootPage(auth: userAuth),
                ),
              );
            },
            child: new Text(
              "[log out]",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w300),
              textAlign: TextAlign.right,
            ),
          )
        ],
      ),
    );
  }

  Widget showAddSite(BuildContext context) {
    return new Container(
      padding: EdgeInsets.fromLTRB(0.0, 40.0, 0.0, 0.0),
      child: SizedBox(
        height: 60.0,
        width: 600,
        child: new RaisedButton(
          elevation: 20,
          shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(20.0),
          ),
          color: Colors.green[400].withOpacity(0.9),
          child: new Text(
            "Add new site",
            style: new TextStyle(
                fontSize: 20.0,
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => SitePage()));
          },
        ),
      ),
    );
  }

  /* Overall widget structure passed in build. */
  Widget showForm() {
    return new Container(
      child: new Center(
        child: Form(
          key: _formKey,
          child: Container(
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                showCodeInput(),
                showNameInput(),
                Row(
                  children: [
                    Flexible(child: showBuild()),
                    SizedBox(width: 10),
                    Flexible(child: showNetwork()),
                  ],
                ),
                showAddress(),
                Row(
                  children: [
                    Flexible(child: showLat()),
                    SizedBox(width: 10),
                    Flexible(child: showLong()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool isTakenSite(String value) {
    if (!widget.create) {
      return false;
    }

    for (Site i in sites) {
      if (i.code == value) {
        return true;
      }
    }
    return false;
  }

  Widget showCodeInput() {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: TextFormField(
        enabled: widget.create,
        controller: codeController,
        textCapitalization: TextCapitalization.none,
        autofocus: false,
        cursorColor: Colors.white,
        obscureText: false,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r"[0-9A-Z_a-z ]"))
        ],
        decoration: InputDecoration(
          fillColor: widget.create
              ? Colors.indigo[400].withOpacity(0.8)
              : Colors.indigo[500].withOpacity(0.8),
          filled: true,
          prefixIcon: Icon(
            Icons.code,
            color: Colors.white,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.red,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.red,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.white,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.grey[600],
            ),
          ),
          labelText: "Site Code",
          labelStyle: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          errorStyle: TextStyle(
            color: Colors.red,
            fontSize: 14,
          ),
        ),
        style: TextStyle(color: Colors.white, fontSize: 16),
        // Must be valid entry
        validator: (value) => value.isEmpty || isTakenSite(value)
            ? 'Site code required and must be unique.'
            : null,
        // Used to pass focus from user -> pass
      ),
    );
  }

  Widget showNameInput() {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: nameController,
        textCapitalization: TextCapitalization.none,
        autofocus: false,
        cursorColor: Colors.white,
        obscureText: false,
        decoration: InputDecoration(
          fillColor: Colors.indigo[400].withOpacity(0.8),
          filled: true,
          prefixIcon: Icon(
            Icons.menu,
            color: Colors.white,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.red,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.red,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.white,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.grey[600],
            ),
          ),
          labelText: "Site Name",
          labelStyle: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          errorStyle: TextStyle(
            color: Colors.red,
            fontSize: 14,
          ),
        ),
        style: TextStyle(color: Colors.white, fontSize: 16),
        // Must be valid entry
        validator: (value) => value.isEmpty ? 'Site name required.' : null,
        // Used to pass focus from user -> pass
      ),
    );
  }

  Widget showAddress() {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: addressController,
        textCapitalization: TextCapitalization.none,
        autofocus: false,
        cursorColor: Colors.white,
        obscureText: false,
        maxLines: 3,
        decoration: InputDecoration(
          fillColor: Colors.indigo[400].withOpacity(0.8),
          filled: true,
          prefixIcon: Icon(
            Icons.location_city,
            color: Colors.white,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.red,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.red,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.white,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.grey[600],
            ),
          ),
          labelText: "Address",
          labelStyle: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          errorStyle: TextStyle(
            color: Colors.red,
            fontSize: 14,
          ),
        ),
        style: TextStyle(color: Colors.white, fontSize: 16),
        // Must be valid entry
        validator: (value) => value.isEmpty ? 'Address required.' : null,
        // Used to pass focus from user -> pass
      ),
    );
  }

  Widget showBuild() {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: buildController,
        textCapitalization: TextCapitalization.none,
        autofocus: false,
        cursorColor: Colors.white,
        obscureText: false,
        decoration: InputDecoration(
          fillColor: Colors.indigo[400].withOpacity(0.8),
          filled: true,
          prefixIcon: Icon(
            Icons.build,
            color: Colors.white,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.red,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.red,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.white,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.grey[600],
            ),
          ),
          labelText: "Build",
          labelStyle: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          errorStyle: TextStyle(
            color: Colors.red,
            fontSize: 14,
          ),
        ),
        style: TextStyle(color: Colors.white, fontSize: 16),
        // Must be valid entry
        validator: (value) => value.isEmpty ? 'Build required.' : null,
        // Used to pass focus from user -> pass
      ),
    );
  }

  Widget showLat() {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: latController,
        textCapitalization: TextCapitalization.none,
        keyboardType: TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        autofocus: false,
        cursorColor: Colors.white,
        obscureText: false,
        decoration: InputDecoration(
          fillColor: Colors.indigo[400].withOpacity(0.8),
          filled: true,
          prefixIcon: Icon(
            Icons.location_on,
            color: Colors.white,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.red,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.red,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.white,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.grey[600],
            ),
          ),
          labelText: "Latitude",
          labelStyle: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          errorStyle: TextStyle(
            color: Colors.red,
            fontSize: 14,
          ),
        ),
        style: TextStyle(color: Colors.white, fontSize: 16),
        // Must be valid entry
        validator: (value) => value.isEmpty ||
                (double.tryParse(value) == null ||
                    double.tryParse(value) < -180 ||
                    double.tryParse(value) > 180)
            ? 'Latitude required (-180 to 180).'
            : null,
        // Used to pass focus from user -> pass
      ),
    );
  }

  Widget showLong() {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: longController,
        textCapitalization: TextCapitalization.none,
        keyboardType: TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        autofocus: false,
        cursorColor: Colors.white,
        obscureText: false,
        decoration: InputDecoration(
          fillColor: Colors.indigo[400].withOpacity(0.8),
          filled: true,
          prefixIcon: Icon(
            Icons.location_on,
            color: Colors.white,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.red,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.red,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.white,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.grey[600],
            ),
          ),
          labelText: "Longitude",
          labelStyle: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          errorStyle: TextStyle(
            color: Colors.red,
            fontSize: 14,
          ),
        ),
        style: TextStyle(color: Colors.white, fontSize: 16),
        // Must be valid entry
        validator: (value) => value.isEmpty ||
                (double.tryParse(value) == null ||
                    double.tryParse(value) < -180 ||
                    double.tryParse(value) > 180)
            ? 'Longitude required (-180 to 180).'
            : null,
        // Used to pass focus from user -> pass
      ),
    );
  }

  Widget showNetwork() {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: networkController,
        textCapitalization: TextCapitalization.none,
        autofocus: false,
        cursorColor: Colors.white,
        obscureText: false,
        decoration: InputDecoration(
          fillColor: Colors.indigo[400].withOpacity(0.8),
          filled: true,
          prefixIcon: Icon(
            Icons.network_check,
            color: Colors.white,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.red,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.red,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.white,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.grey[600],
            ),
          ),
          labelText: "Network",
          labelStyle: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          errorStyle: TextStyle(
            color: Colors.red,
            fontSize: 14,
          ),
        ),
        style: TextStyle(color: Colors.white, fontSize: 16),
        // Must be valid entry
        validator: (value) => value.isEmpty ? 'Network required.' : null,
        // Used to pass focus from user -> pass
      ),
    );
  }

  Widget showContinue(BuildContext context) {
    return new Container(
      padding: EdgeInsets.only(bottom: 15),
      child: SizedBox(
        height: 60.0,
        width: 600,
        child: new RaisedButton(
          elevation: 20,
          shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(20.0),
          ),
          color: Colors.green[400].withOpacity(0.9),
          child: new Text(
            "Continue to subsites",
            style: new TextStyle(
                fontSize: 20.0,
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            if (_formKey.currentState.validate()) {
              Site clone = Site(
                codeController.text,
                nameController.text,
                addressController.text,
                buildController.text,
                networkController.text,
                double.parse(latController.text),
                double.parse(longController.text),
                site.maps,
              );

              clone.populate();

              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => SubPage(
                          auth: userAuth, site: clone, readOnly: false))).then(
                (onValue) => setState(() {}),
              );
            }
          },
        ),
      ),
    );
  }

  Widget showCancel(BuildContext context) {
    return new Container(
      padding: EdgeInsets.only(bottom: 15),
      child: SizedBox(
        height: 60.0,
        width: 600,
        child: new RaisedButton(
          elevation: 20,
          shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(20.0),
          ),
          color: Colors.red[300].withOpacity(0.9),
          child: new Text(
            "Cancel submission",
            style: new TextStyle(
                fontSize: 20.0,
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
