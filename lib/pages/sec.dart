import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tfsitescapeweb/main.dart';
import 'package:tfsitescapeweb/pages/root.dart';
import 'package:tfsitescapeweb/pages/task.dart';
import 'package:tfsitescapeweb/services/auth.dart';
import 'package:tfsitescapeweb/services/classes.dart';

/* Login page taking a previously initialised Auth and a void function
   which executes after authentication attempt.
   
   auth -> Auth: Needed to pass authentication after login during activities
   loginCallback -> void: Performed after authentication attempt 
*/
class SecPage extends StatefulWidget {
  SecPage({this.auth, this.sub, this.readOnly});

  final Auth auth;
  final Subsite sub;
  final bool readOnly;

  @override
  State<StatefulWidget> createState() => new SecPageState(this.sub);
}

/* State for SecPage */
class SecPageState extends State<SecPage> {
  final Subsite sub;
  SecPageState(this.sub);

  TextEditingController secController;

  @override
  void initState() {
    super.initState();
    secController = new TextEditingController();
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
                  !widget.readOnly
                      ? Container(
                          padding: EdgeInsets.only(
                            left: 15,
                            right: 15,
                            top: 15,
                          ),
                          margin: EdgeInsets.only(top: 30),
                          child: showSubInput(),
                        )
                      : Container(),
                  !widget.readOnly ? showAdd() : Container(),
                  showSectors(),
                  showCancel(context),
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

  Widget showSectors() {
    if (sub.sectors.isEmpty) {
      return Expanded(
        child: Container(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "No sectors listed",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 24),
                )
              ],
            ),
          ),
        ),
      );
    } else {
      return Expanded(
        child: Container(
          padding: EdgeInsets.all(15),
          child: Scrollbar(
            child: ListView.builder(
              shrinkWrap: true,
              primary: true,
              itemCount: sub.sectors.length,
              itemBuilder: (BuildContext context, int index) {
                // Return a card only if the search term is found in name/code.
                return showSectorCard(sub.sectors[index]);
              },
            ),
          ),
        ),
      );
    }
  }

  Widget showAdd() {
    return RaisedButton(
        elevation: 20,
        shape: new RoundedRectangleBorder(
          borderRadius: new BorderRadius.circular(20.0),
        ),
        color: Colors.green[400].withOpacity(0.9),
        child: new Text(
          "Add sector",
          style: new TextStyle(
              fontSize: 12.0, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          bool notDuplicate = true;
          for (Sector sec in sub.sectors) {
            if (sec.name == secController.text) {
              notDuplicate = false;
            }
          }

          if (notDuplicate && secController.text.isNotEmpty) {
            setState(() {
              Sector sec = Sector(secController.text, {}, false, false);
              sec.populate();

              sub.sectors.add(sec);
              sub.sectors.sort((a, b) => a.name.compareTo(b.name));
            });
          }

          secController.clear();
        });
  }

  Widget showSectorCard(Sector sec) {
    return InkWell(
      child: new Card(
        elevation: 5,
        child: new Container(
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // Stretch the cards in horizontal axis
                  children: <Widget>[
                    new Text(
                      sec.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    new Text(
                      sec.tasks.length.toString() + " tasks",
                      style: new TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              new Row(
                mainAxisAlignment: MainAxisAlignment.end,
                // Stretch the cards in horizontal axis
                children: <Widget>[
                  SizedBox(
                    height: 36,
                    width: 36,
                    child: IconButton(
                      icon: Icon(
                        !widget.readOnly ? Icons.edit : Icons.photo_library,
                        size: 16,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (BuildContext context) => TaskPage(
                              auth: userAuth,
                              sec: sec,
                              readOnly: widget.readOnly,
                            ),
                          ),
                        ).then(
                          (onValue) => setState(() {}),
                        );
                      },
                    ),
                  ),
                  !widget.readOnly
                      ? SizedBox(
                          height: 36,
                          width: 36,
                          child: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                sub.sectors.remove(sec);
                              });
                            },
                          ),
                        )
                      : Container()
                ],
              ),
            ],
          ),
          padding: const EdgeInsets.all(15.0),
        ),
      ),
    );
  }

  Widget showCancel(BuildContext context) {
    return new Container(
      padding: EdgeInsets.only(
        bottom: 15,
        left: 15,
        right: 15,
      ),
      child: SizedBox(
        height: 60.0,
        width: 600,
        child: new RaisedButton(
          elevation: 20,
          shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(20.0),
          ),
          color: Colors.indigoAccent[400].withOpacity(0.9),
          child: new Text(
            !widget.readOnly ? "Back to subsite details" : "Back to subsite",
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

  Widget showSubInput() {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: secController,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r"[0-9A-Z_a-z ]"))
        ],
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
          labelText: "Enter new sector name",
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
      ),
    );
  }
}
