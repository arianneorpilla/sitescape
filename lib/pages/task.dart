import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tfsitescapeweb/main.dart';

import 'package:tfsitescapeweb/pages/root.dart';
import 'package:tfsitescapeweb/services/auth.dart';
import 'package:tfsitescapeweb/services/classes.dart';

/* Login page taking a previously initialised Auth and a void function
   which executes after authentication attempt.
   
   auth -> Auth: Needed to pass authentication after login during activities
   loginCallback -> void: Performed after authentication attempt 
*/
class TaskPage extends StatefulWidget {
  TaskPage({this.auth, this.sec});

  final Auth auth;
  final Sector sec;

  @override
  State<StatefulWidget> createState() => new TaskPageState(this.sec);
}

/* State for TaskPage */
class TaskPageState extends State<TaskPage> {
  final Sector sec;
  TaskPageState(this.sec);

  String _name;
  String _description;
  TextEditingController nameController;
  TextEditingController descriptionController;

  FocusNode descriptionFocus;

  @override
  void initState() {
    super.initState();
    nameController = new TextEditingController();
    descriptionController = new TextEditingController();

    descriptionFocus = new FocusNode();

    _name = "";
    _description = "";
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
                    padding: EdgeInsets.only(
                      top: 15,
                      left: 15,
                      right: 15,
                    ),
                    margin: EdgeInsets.only(top: 30),
                    child: showNameInput(),
                  ),
                  Container(
                    padding: EdgeInsets.only(
                      top: 15,
                      left: 15,
                      right: 15,
                    ),
                    child: showDescriptionInput(),
                  ),
                  showAdd(),
                  showTasks(),
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

  Widget showTasks() {
    if (sec.tasks.isEmpty) {
      return Expanded(
        child: Container(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "No tasks listed",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 24,
                  ),
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
              itemCount: sec.tasks.length,
              itemBuilder: (BuildContext context, int index) {
                // Return a card only if the search term is found in name/code.
                return showTaskCard(sec.tasks[index]);
              },
            ),
          ),
        ),
      );
    }
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
                        onPressed: () {
                          setState(() {
                            sec.tasks.remove(task);
                          });
                        },
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

  Widget showAdd() {
    return RaisedButton(
      elevation: 20,
      shape: new RoundedRectangleBorder(
        borderRadius: new BorderRadius.circular(20.0),
      ),
      color: Colors.green[400].withOpacity(0.9),
      child: new Text(
        "Add task",
        style: new TextStyle(
            fontSize: 12.0, color: Colors.white, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        bool notDuplicate = true;
        for (Task task in sec.tasks) {
          if (task.name == nameController.text) {
            notDuplicate = false;
          }
        }

        if (notDuplicate &&
            nameController.text.isNotEmpty &&
            descriptionController.text.isNotEmpty) {
          setState(() {
            sec.tasks.add(Task(
              nameController.text,
              descriptionController.text,
              0,
            ));
            sec.tasks.sort((a, b) => a.name.compareTo(b.name));

            nameController.clear();
            descriptionController.clear();
            descriptionFocus.unfocus();
          });
        }
      },
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

  Widget showNameInput() {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: TextField(
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
          labelText: "Enter new task name",
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

  Widget showDescriptionInput() {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: descriptionController,
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
          labelText: "Enter new task description",
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
