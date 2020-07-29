import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/js.dart' as js;

import 'package:tfsitescapeweb/main.dart';
import 'package:tfsitescapeweb/pages/root.dart';
import 'package:tfsitescapeweb/services/auth.dart';
import 'package:tfsitescapeweb/services/classes.dart';

/* Login page taking a previously initialised Auth and a void function
   which executes after authentication attempt.
   
   auth -> Auth: Needed to pass authentication after login during activities
   loginCallback -> void: Performed after authentication attempt 
*/
class PhotosPage extends StatefulWidget {
  PhotosPage({this.auth, this.task});

  final Auth auth;
  final Task task;

  @override
  State<StatefulWidget> createState() => new PhotosPageState(this.task);
}

/* State for TaskPage */
class PhotosPageState extends State<PhotosPage> {
  final Task task;
  PhotosPageState(this.task);

  TextEditingController messageController;

  List<Future<NetworkTaskImage>> _cloudPhotos;

  ScrollController _scrollController;

  FocusNode messageFocus;
  int _selectedIndex;
  NetworkTaskImage _selectedImage;

  @override
  void initState() {
    super.initState();
    messageController = new TextEditingController();

    messageFocus = new FocusNode();

    _scrollController = new ScrollController();
  }

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    messageFocus.dispose();

    super.dispose();
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
                  isAdmin
                      ? Container(
                          padding: EdgeInsets.only(
                            top: 15,
                            left: 15,
                            right: 15,
                          ),
                          child: showMessageInput(),
                        )
                      : Container(),
                  isAdmin
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            showAccept(),
                            SizedBox(width: 8),
                            showReject(),
                          ],
                        )
                      : Container(),
                  Flexible(
                    child: showCloud(),
                  ),
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

  Widget showCloud() {
    if (_cloudPhotos == null) {
      return FutureBuilder(
        future: task.getCloudPhotos(task: task),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          _cloudPhotos = snapshot.data;

          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white70),
                  ),
                  SizedBox(height: 96),
                ],
              ),
            );
          }
          if (_cloudPhotos.isEmpty) {
            return Container(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_queue, color: Colors.white70, size: 36),
                    SizedBox(height: 10),
                    Text(
                      "No photos in cloud",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          fontSize: 24),
                    ),
                    SizedBox(height: 96),
                  ],
                ),
              ),
            );
          } else {
            return showCloudPhotos();
          }
        },
      );
    } else {
      if (_cloudPhotos.isEmpty) {
        return Container(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.cloud_queue, color: Colors.white70, size: 36),
                SizedBox(height: 10),
                Text(
                  "No photos in cloud",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: 24),
                ),
                SizedBox(height: 96),
              ],
            ),
          ),
        );
      } else {
        return showCloudPhotos();
      }
    }
  }

  Widget showCloudPhotos() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
      alignment: Alignment.topCenter,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: GridView.builder(
          padding: EdgeInsets.only(bottom: 96),
          controller: _scrollController,
          itemCount: _cloudPhotos.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
          itemBuilder: (BuildContext context, int index) {
            return FutureBuilder(
                future: _cloudPhotos[index],
                builder: (BuildContext context,
                    AsyncSnapshot<NetworkTaskImage> snapshot) {
                  NetworkTaskImage netTask = snapshot.data;

                  if (!snapshot.hasData) {
                    return Card(
                      elevation: 5,
                      color: Colors.black.withOpacity(0.1),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image(
                            fit: BoxFit.cover,
                            image: AssetImage("images/placeholder.png"),
                          )
                        ],
                      ),
                    );
                  }

                  return InkWell(
                    child: Card(
                      elevation: 5,
                      color: Colors.black.withOpacity(0.1),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: (_selectedIndex == index)
                            ? BoxDecoration(
                                border:
                                    Border.all(color: Colors.blue, width: 2))
                            : BoxDecoration(
                                border: Border.all(color: Colors.transparent)),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            FadeInImage(
                              fit: BoxFit.cover,
                              fadeInDuration: Duration(milliseconds: 100),
                              fadeOutDuration: Duration(milliseconds: 100),
                              placeholder: AssetImage("images/placeholder.png"),
                              image: netTask.image,
                            ),
                            showCloudIcon(netTask),
                            showFullIcon(netTask.getFullImage().url),
                          ],
                        ),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                        _selectedImage = netTask;
                        messageController.text = netTask.message;
                        messageFocus.requestFocus();
                      });
                    },
                  );
                });
          },
        ),
      ),
    );
  }

  Widget showCloudIcon(NetworkTaskImage netTask) {
    if (netTask.approved) {
      return Container(
        alignment: Alignment.bottomRight,
        padding: EdgeInsets.all(8.0),
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 1.0,
              top: 2.0,
              child: Icon(
                Icons.check_box,
                color: Colors.black54,
                size: 14,
              ),
            ),
            Icon(
              Icons.check_box,
              color: Colors.green,
              size: 14,
            ),
          ],
        ),
      );
    } else if (netTask.rejected) {
      return Container(
        alignment: Alignment.bottomRight,
        padding: EdgeInsets.all(8.0),
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 1.0,
              top: 2.0,
              child: Icon(
                Icons.error,
                color: Colors.black54,
                size: 14,
              ),
            ),
            Icon(
              Icons.error,
              color: Colors.red,
              size: 14,
            ),
          ],
        ),
      );
    } else {
      return Container(
        alignment: Alignment.bottomRight,
        padding: EdgeInsets.all(8.0),
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 1.0,
              top: 2.0,
              child: Icon(
                Icons.check_box_outline_blank,
                color: Colors.black54,
                size: 14,
              ),
            ),
            Icon(
              Icons.check_box_outline_blank,
              color: Colors.grey,
              size: 14,
            ),
          ],
        ),
      );
    }
  }

  Widget showFullIcon(String url) {
    return Container(
      height: 20,
      width: 20,
      alignment: Alignment.bottomLeft,
      padding: EdgeInsets.all(8.0),
      child: InkWell(
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 1.0,
              top: 2.0,
              child: Icon(
                Icons.link,
                color: Colors.black54,
                size: 14,
              ),
            ),
            Icon(
              Icons.link,
              color: Colors.blue,
              size: 14,
            ),
          ],
        ),
        onTap: () {
          js.context.callMethod("open", [url]);
        },
      ),
    );
  }

  Widget showTaskCard(Task task) {
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
                      task.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    new Text(
                      task.note,
                      style: new TextStyle(
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
              Container(
                width: 150,
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  // Stretch the cards in horizontal axis
                  children: <Widget>[
                    SizedBox(
                      height: 36,
                      width: 36,
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.red,
                        ),
                        onPressed: () {},
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          padding: const EdgeInsets.all(15.0),
        ),
      ),
    );
  }

  Widget showAccept() {
    return RaisedButton(
        elevation: 20,
        shape: new RoundedRectangleBorder(
          borderRadius: new BorderRadius.circular(20.0),
        ),
        color: Colors.green[400].withOpacity(0.9),
        child: new Text(
          "Accept photo",
          style: new TextStyle(
              fontSize: 12.0, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          try {
            await task.acceptCloudPhoto(_selectedImage, messageController.text);
            setState(() {});
          } catch (e) {}
        });
  }

  Widget showReject() {
    return RaisedButton(
        elevation: 20,
        shape: new RoundedRectangleBorder(
          borderRadius: new BorderRadius.circular(20.0),
        ),
        color: Colors.red[400].withOpacity(0.9),
        child: new Text(
          "Reject photo",
          style: new TextStyle(
              fontSize: 12.0, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          try {
            await task.rejectCloudPhoto(_selectedImage, messageController.text);
            setState(() {});
          } catch (e) {}
        });
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
            "Back to sector details",
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

  Widget showMessageInput() {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: messageController,
        focusNode: messageFocus,
        textCapitalization: TextCapitalization.none,
        autofocus: false,
        cursorColor: Colors.white,
        obscureText: false,
        maxLines: 3,
        decoration: InputDecoration(
          fillColor: Colors.indigo[400].withOpacity(0.8),
          filled: true,
          prefixIcon: Icon(
            Icons.subtitles,
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
          labelText: "Enter feedback",
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
      ),
    );
  }
}
