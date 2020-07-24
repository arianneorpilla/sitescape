import 'dart:io';
import 'dart:ui';

import 'package:expandable/expandable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:get/get.dart';

import 'package:tfsitescape/main.dart';
import 'package:tfsitescape/pages/camera.dart';
import 'package:tfsitescape/pages/preview.dart';
import 'package:tfsitescape/pages/preview_cloud.dart';
import 'package:tfsitescape/services/modal.dart';
import 'package:tfsitescape/services/classes.dart';
import 'package:tfsitescape/services/tabs.dart';
import 'package:tfsitescape/services/util.dart';

/* Page for Task Selection, shows tasks in list order with option to take
   a picture or upload.
   
   selection -> UserSelection: The current user selection context, 
                               complete with Site->Subsite->Sector->Task 
*/
class TaskPage extends StatefulWidget {
  TaskPage({
    Key key,
    this.task,
    this.showNotReq,
  }) : super(key: key);

  final Task task;
  final bool showNotReq;

  @override
  State<StatefulWidget> createState() => new _TaskPageState(this.task);
}

/* State for TaskPage */
class _TaskPageState extends State<TaskPage> {
  final Task task;
  _TaskPageState(this.task);

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _tabKey = new GlobalKey<CustomTabsState>();

  ScrollController _scrollController;
  ExpandableController _expandableController;

  List<Future<NetworkTaskImage>> _cloudPhotos;

  bool _isUploading;

  @override
  void initState() {
    super.initState();
    _isUploading = false;
    _scrollController = new ScrollController();
    _expandableController = new ExpandableController();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _expandableController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      extendBody: true,
      backgroundColor: Theme.of(context).primaryColor,
      body: Stack(
        children: <Widget>[
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
              child: Container(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: Column(children: [
              showTaskInfo(context),
              _isUploading ? showProgress() : Container(),
              widget.showNotReq ? showNotRequired() : Container(),
              showDescription(),
              showTabs(),
              // showPhotos(),
            ]),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 36, 16, 0),
            height: 96,
            width: 96,
            child: FittedBox(child: showBackButton()),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 36, 16, 0),
              height: 96,
              width: 96,
              child: FittedBox(
                child: showUploadButton(),
              ),
            ),
          )
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
        shape: (task.getTaskProgress() == TaskStatus.NOT_REQUIRED)
            ? null
            : CircularNotchedRectangle(),
        elevation: 0,
        color: Colors.black.withOpacity(0.35),
      ),
    );
  }

  Widget showTabs() {
    Widget buildPages(int index) {
      switch (index) {
        case 0:
          return showLocalPhotos();
        case 1:
          return showCloud();
      }
      return null;
    }

    Widget buildTabs(int index) {
      switch (index) {
        case 0:
          return Tab(text: "Local");
        case 1:
          return Tab(text: "Cloud");
      }
      return null;
    }

    return Flexible(
      child: Container(
        child: CustomTabView(
          key: _tabKey,
          alignment: Alignment.center,
          backgroundColor: Colors.white,
          initPosition: 0,
          itemCount: 2,
          tabBuilder: (context, index) => buildTabs(index),
          pageBuilder: (context, index) => buildPages(index),
        ),
      ),
    );
  }

  /* On top center below Sector Name */
  Widget showProgress() {
    return LinearProgressIndicator(
      backgroundColor: Colors.green[300],
      valueColor: AlwaysStoppedAnimation(Colors.green),
      minHeight: 4,
    );
  }

  /* On upper left */
  Widget showBackButton() {
    return FlatButton(
      onPressed: () {
        Get.back();
      },
      color: Colors.black.withOpacity(0.35),
      child: Icon(Icons.arrow_back, size: 28, color: Colors.white),
      padding: EdgeInsets.all(0.1),
      shape: CircleBorder(),
    );
  }

  /* On top right */
  Widget showUploadButton() {
    if (task.getTaskProgress() != TaskStatus.NOT_REQUIRED) {
      return FlatButton(
        onPressed: () async {
          uploadFiles();
        },
        color: Colors.black.withOpacity(0.35),
        child: Icon(
          Icons.file_upload,
          size: 28,
          color: Colors.greenAccent,
        ),
        padding: EdgeInsets.all(0.1),
        shape: CircleBorder(),
      );
    } else {
      return Container();
    }
  }

  /* On top center */
  Widget showTaskInfo(BuildContext context) {
    return Container(
      height: 96,
      color: Colors.black.withOpacity(0.35),
      padding: EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  task.name,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* Below task header at top */
  Widget showDescription() {
    return Container(
      width: MediaQuery.of(context).size.width,
      color: Colors.white,
      padding: EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
      child: InkWell(
        onTap: () {
          _expandableController.toggle();
        },
        child: ExpandablePanel(
          controller: _expandableController,
          // ignore: deprecated_member_use
          headerAlignment: ExpandablePanelHeaderAlignment.center,
          header: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.info, size: 18, color: Colors.black),
              SizedBox(width: 6),
              Text(
                " Description",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          collapsed: Text(task.note == "" ? "N/A" : task.note,
              textAlign: TextAlign.justify,
              maxLines: 3,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              softWrap: true,
              overflow: TextOverflow.ellipsis),
          expanded: Text(
            task.note == "" ? "N/A" : task.note,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
            softWrap: true,
          ),
        ),
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
                        ],
                      ),
                    ),
                    onTap: () {
                      Get.to(
                        PreviewCloudPage(
                          task: task,
                          list: _cloudPhotos,
                          startIndex: index,
                        ),
                      ).then((r) => setState(() {}));
                    },
                  );
                });
          },
        ),
      ),
    );
  }

  /* Main content showing grid view of photos */
  Widget showLocalPhotos() {
    List<FileTaskImage> allPhotos = task.getLocalPhotos();

    TaskStatus status = task.getTaskProgress();
    IconData emptyIcon;
    String emptyText;

    if (status == TaskStatus.NOT_REQUIRED) {
      emptyIcon = Icons.indeterminate_check_box;
      emptyText = "Task is marked as not required";
    } else {
      emptyIcon = Icons.photo_library;
      emptyText = "Task gallery is empty";
    }

    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
      alignment: Alignment.topCenter,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: allPhotos.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(emptyIcon, color: Colors.white70, size: 36),
                    SizedBox(height: 10),
                    Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          fontSize: 24),
                    ),
                    SizedBox(height: 96),
                  ],
                ),
              )
            : GridView.builder(
                padding: EdgeInsets.only(bottom: 96),
                controller: _scrollController,
                itemCount: allPhotos.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2),
                itemBuilder: (BuildContext context, int index) {
                  return InkWell(
                    child: Card(
                      elevation: 5,
                      color: Colors.black.withOpacity(0.1),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          FadeInImage(
                            fit: BoxFit.cover,
                            fadeInDuration: Duration(milliseconds: 100),
                            fadeOutDuration: Duration(milliseconds: 100),
                            placeholder: AssetImage("images/placeholder.png"),
                            image: allPhotos[index].image,
                          ),
                          showLocalIcon(allPhotos[index].isCloud)
                        ],
                      ),
                    ),
                    onTap: () {
                      Get.to(
                        PreviewPage(
                          task: task,
                          startIndex: index,
                        ),
                      ).then((r) => setState(() {}));
                    },
                  );
                },
              ),
      ),
    );
  }

  /* Shows on bottom right of a photo grid if the photo is a local image
     ending with "-L" */
  Widget showLocalIcon(bool isCloud) {
    if (!isCloud) {
      return Container(
        alignment: Alignment.bottomRight,
        padding: EdgeInsets.all(15.0),
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 1.0,
              top: 2.0,
              child: Icon(
                Icons.cloud_off,
                color: Colors.black54,
                size: 24,
              ),
            ),
            Icon(
              Icons.cloud_off,
              color: Colors.yellow[700],
              size: 24,
            ),
          ],
        ),
      );
    } else {
      return Container(
        alignment: Alignment.bottomRight,
        padding: EdgeInsets.all(15.0),
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 1.0,
              top: 2.0,
              child: Icon(
                Icons.cloud_off,
                color: Colors.black54,
                size: 24,
              ),
            ),
            Icon(
              Icons.cloud_done,
              color: Colors.green,
              size: 24,
            ),
          ],
        ),
      );
    }
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

  /* Shows if the task is not required, can be clicked on to set task to
     required, does not show if gallery is not empty */
  Widget showNotRequired() {
    List<TaskImage> allPhotos = task.getLocalPhotos();
    TaskStatus status = task.getTaskProgress();

    if (allPhotos.isEmpty && status != TaskStatus.NOT_REQUIRED) {
      return Container(
        color: Colors.red[400],
        padding: EdgeInsets.fromLTRB(0, 16, 0, 16),
        child: InkWell(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 18, color: Colors.white),
              Text(
                " MARK TASK AS NOT REQUIRED",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          onTap: () {
            markNotRequired();
          },
        ),
      );
    } else if (status == TaskStatus.NOT_REQUIRED) {
      return Container(
        color: Colors.grey,
        padding: EdgeInsets.fromLTRB(0, 16, 0, 16),
        child: InkWell(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.undo, size: 18, color: Colors.white),
              Text(
                " MARK TASK AS REQUIRED",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          onTap: () {
            task.undoTaskNotRequired();
            setState(() {});
          },
        ),
      );
    } else {
      return Container();
    }
  }

  /* Floating action button action on bottom of task screen, with option to
     go to the camera screen */
  Widget showFloatingActionButton() {
    if (task.getTaskProgress() != TaskStatus.NOT_REQUIRED) {
      return FloatingActionButton(
          backgroundColor: Colors.black.withOpacity(0.35),
          child: Icon(Icons.add_a_photo, color: Colors.white, size: 36),
          elevation: 0,
          onPressed: () async {
            int oldCount = task.getTaskImageCount();

            Get.to(CameraScreen(camera: cam, task: task)).then((onValue) => {
                  setState(() {
                    int newCount = task.getTaskImageCount();

                    if (oldCount != newCount) {
                      _tabKey.currentState.animateTo(0);
                      scrollToTop();
                    }
                  })
                });
          });
    } else {
      return FloatingActionButton(
          backgroundColor: Colors.transparent, elevation: 0, onPressed: () {});
    }
  }

  /* Scroll action is performed when the screen state is updated and a change
     in the image count is found or images added */
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  /* Opens the multi-file picker and lets the user select between multiple
     files in their local gallery */
  void uploadFiles() async {
    List<File> files = await FilePicker.getMultiFile(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );

    if (files != null) {
      setState(() {
        _tabKey.currentState.animateTo(0);
        _isUploading = true;
      });
    }

    // Scroll to top as a file upload was performed, to notify the user
    scrollToTop();

    // Iterate on every file and bake the current time
    for (File file in files) {
      print(file.path);

      ImageProperties properties =
          await FlutterNativeImage.getImageProperties(file.path);

      File processed;

      int scaleWidth = (properties.width * 1080 / properties.height).round();
      int scaleHeight = (properties.height * 1920 / properties.width).round();

      if (properties.width > 1920) {
        processed = await FlutterNativeImage.compressImage(
          file.path,
          quality: 80,
          targetHeight: scaleHeight,
          targetWidth: 1920,
        );
      } else if (properties.height > 1080) {
        processed = await FlutterNativeImage.compressImage(
          file.path,
          quality: 80,
          targetWidth: scaleWidth,
          targetHeight: 1080,
        );
      } else {
        processed = file;
      }

      File workingFile = await bakeTimestamp(processed);

      FileTaskImage taskImage = FileTaskImage.create(task, workingFile);
      String fileName = taskImage.getFilePath();

      File newFile = File(fileName);
      newFile.createSync(recursive: true);
      workingFile.copySync(newFile.path);
      processed.deleteSync();

      setState(() {});
    }

    setState(() {
      _isUploading = false;
    });
  }

  /* Action for widget showNotRequired() which allows the user to set the
    task as not required */
  void markNotRequired() {
    Widget logout = FlatButton(
      child: Text(
        'CONFIRM',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.red,
          fontSize: 16,
        ),
      ),
      onPressed: () async {
        Get.back();
        setState(() {
          task.setTaskNotRequired();
        });
      },
    );

    Widget cancel = FlatButton(
      child: Text(
        'CANCEL',
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
      ),
      onPressed: () {
        Get.back();
      },
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Are you sure?',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              'This will locally mark the task not required, meaning this ' +
                  'task will be left blank and without images when submitted.' +
                  '\n\nYour progression may not reflect what others see on ' +
                  'the cloud.',
              textAlign: TextAlign.justify,
              style: TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
          actions: [logout, cancel],
        );
      },
    );
  }
}
