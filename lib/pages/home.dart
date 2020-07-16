import 'dart:ui';
import 'dart:js' as js;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase/firebase.dart' as fb;

import 'package:tfsitescapeweb/main.dart';
import 'package:tfsitescapeweb/pages/site.dart';
import 'package:tfsitescapeweb/pages/root.dart';
import 'package:tfsitescapeweb/services/auth.dart';
import 'package:tfsitescapeweb/services/classes.dart';
import 'package:tfsitescapeweb/services/util.dart';

/* Login page taking a previously initialised Auth and a void function
   which executes after authentication attempt.
   
   auth -> Auth: Needed to pass authentication after login during activities
   loginCallback -> void: Performed after authentication attempt 
*/
class HomePage extends StatefulWidget {
  HomePage({this.auth, this.loginCallback});

  final Auth auth;
  final VoidCallback loginCallback;

  @override
  State<StatefulWidget> createState() => new HomePageState();
}

/* State for HomePage */
class HomePageState extends State<HomePage> {
  bool _downloading;
  int _downloadingIndex;

  @override
  void initState() {
    super.initState();
    _downloading = false;
    _downloadingIndex = -1;
  }

  // Build the widget.
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.indigo[900],
      body: Stack(
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
          ),
          Center(
            child: Container(
              width: 600,
              height: 800,
              padding: EdgeInsets.all(10),
              color: Colors.black.withOpacity(0.25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  showLogOut(context),
                  Container(
                    padding: EdgeInsets.all(15),
                    child: showAddSite(context),
                  ),
                  showSites(),
                ],
              ),
            ),
          )
          // _showCircularProgress(),
        ],
      ),
    );
  }

  Future<List<Uri>> getDownloadInfo(Site site) async {
    List<Uri> links = [];

    for (Subsite sub in site.subsites) {
      for (Sector sec in sub.sectors) {
        fb.StorageReference storageRef = fb
            .app()
            .storage()
            .refFromURL("gs://tfsitescape.appspot.com")
            .child("tfcloud")
            .child(site.name)
            .child(sub.name)
            .child(sec.name);
        fb.ListResult result = await storageRef.listAll();
        result.items.forEach((a) async => links.add(await a.getDownloadURL()));
      }
    }

    return links;
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

  Widget showSites() {
    return Container(
      height: 538,
      padding: EdgeInsets.all(15),
      child: Scrollbar(
        child: ListView.builder(
          shrinkWrap: true,
          primary: true,
          itemCount: sites.length,
          itemBuilder: (BuildContext context, int index) {
            // Return a card only if the search term is found in name/code.
            return showSiteCard(context, sites[index], index);
          },
        ),
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
          color: Colors.indigoAccent[400].withOpacity(0.9),
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
                    builder: (BuildContext context) => SitePage(
                        auth: userAuth,
                        site: Site.add(),
                        create: true))).then((onValue) => setState(() {}));
          },
        ),
      ),
    );
  }

  Widget showSiteCard(BuildContext context, Site site, int index) {
    return InkWell(
      child: new Card(
        elevation: 5,
        child: new Container(
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // Stretch the cards in horizontal axis
                children: <Widget>[
                  new Text(
                    site.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  new Text(
                    site.code.toUpperCase(),
                    style: new TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ],
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
                        Icons.edit,
                        size: 16,
                      ),
                      onPressed: () {
                        Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) => SitePage(
                                        auth: userAuth,
                                        site: site,
                                        create: false)))
                            .then((onValue) => setState(() {}));
                      },
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    width: 36,
                    child: IconButton(
                      icon: Icon(
                        Icons.content_copy,
                        size: 16,
                      ),
                      onPressed: () {
                        Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) => SitePage(
                                        auth: userAuth,
                                        site: site,
                                        create: true)))
                            .then((onValue) => setState(() {}));
                      },
                    ),
                  ),
                  showDownloadButton(site, index)
                ],
              ),
            ],
          ),
          padding: const EdgeInsets.all(15.0),
        ),
      ),
    );
  }

  Widget showDownloadButton(Site site, int index) {
    if (_downloading) {
      if (index == _downloadingIndex) {
        return SizedBox(
          width: 36,
          height: 36,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.indigoAccent),
            ),
          ),
        );
      } else {
        return SizedBox(
          height: 36,
          width: 36,
          child: IconButton(
            icon: Icon(
              Icons.file_download,
              size: 16,
            ),
            disabledColor: Colors.grey,
          ),
        );
      }
    } else {
      return SizedBox(
        height: 36,
        width: 36,
        child: IconButton(
            icon: Icon(
              Icons.file_download,
              size: 16,
            ),
            onPressed: () async {
              setState(() {
                _downloading = true;
                _downloadingIndex = index;
              });

              List<Uri> links = await getDownloadInfo(site);
              List<String> urls = [];
              links.forEach((a) => urls.add(a.toString()));

              await js.context.callMethod("generateZIP", [
                js.JsArray.from(urls),
              ]);

              setState(() {
                _downloading = false;
                _downloadingIndex = -1;
              });
            }),
      );
    }
  }
}
