import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import 'package:tfsitescape/pages/task.dart';
import 'package:tfsitescape/services/modal.dart';
import 'package:tfsitescape/services/classes.dart';

/* Sector Page with option to pick a Task, also showing progress 

   selection -> UserSelection: Site, sub and sector for passing parameters */
class SectorPage extends StatefulWidget {
  SectorPage({
    Key key,
    this.sector,
    this.photos,
    this.progress,
    this.color,
  }) : super(key: key);

  final Sector sector;
  final List<int> photos;
  final double progress;
  final Color color;

  @override
  State<StatefulWidget> createState() => new _SectorPageState(this.sector);
}

/* State for HomePage */
class _SectorPageState extends State<SectorPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final Sector sector;

  // Used for overall top bar progress based on tasks completed/sync
  double _sectorProgress;
  Color _sectorProgressColor;
  List<int> _cloudPhotos;
  List<dynamic> _cloudThumbs;

  _SectorPageState(this.sector);

  @override
  void initState() {
    super.initState();
    // Initialise progress parameters
    _sectorProgress = widget.progress;
    _sectorProgressColor = widget.color;
    _cloudPhotos = widget.photos;

    sector.getSectorCloudThumbnails().then((onValue) {
      setState(() {
        _cloudThumbs = onValue;
      });
    });

    updateSectorCloudProgress();
  }

  void refreshProgress() {
    updateSectorCloudProgress();
  }

  void updateSectorCloudProgress() {
    _sectorProgress = sector.getSectorProgress();
    _sectorProgressColor = sector.getSectorProgressColor();

    sector.getSectorCloudProgress().then(
          (onValue) => {
            if (mounted)
              {
                setState(() {
                  _cloudPhotos = onValue;
                  List<int> localPhotos = sector.getSectorLocalProgress();

                  _sectorProgress =
                      sector.getSectorProgressUpdate(localPhotos, _cloudPhotos);

                  if (_sectorProgress == 1.0 &&
                      sector.getUnsyncedPhotos() == 0) {
                    _sectorProgressColor = Colors.greenAccent[700];
                  } else {
                    _sectorProgressColor = Colors.yellow[700];
                  }
                })
              }
          },
        );
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
            child: Column(
              children: [
                showTaskInfo(),
                showProgress(),
                showTasks(),
              ],
            ),
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
                child: showMarkDoneButton(),
              ),
            ),
          )
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      // ),
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
        shape: CircularNotchedRectangle(),
        elevation: 0,
        color: Colors.black.withOpacity(0.35),
      ),
    );
  }

  /* On top center below Sector Name */
  Widget showProgress() {
    return LinearPercentIndicator(
      animateFromLastPercent: true,
      animation: true,
      lineHeight: 4.0,
      animationDuration: 600,
      percent: _sectorProgress,
      progressColor: _sectorProgressColor,
      padding: EdgeInsets.zero,
      linearStrokeCap: LinearStrokeCap.roundAll,
    );
  }

  /* On top left */
  Widget showBackButton() {
    return FlatButton(
      onPressed: () {
        Get.back();
      },
      color: Colors.black.withOpacity(0.35),
      child: Icon(
        Icons.arrow_back,
        size: 28,
        color: Colors.white,
      ),
      padding: EdgeInsets.all(0.1),
      shape: CircleBorder(),
    );
  }

  /* On top center */
  Widget showTaskInfo() {
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
                  sector.name,
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

  /* Main content, listview of showTaskCards */
  Widget showTasks() {
    return Flexible(
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 96),
          alignment: Alignment.topCenter,
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView.builder(
              shrinkWrap: true,
              primary: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: sector.tasks.length,
              itemBuilder: (BuildContext context, int index) {
                // Return a card only if the search term is found in name/code.
                return showTaskCard(sector.tasks[index], index);
              },
            ),
          ),
        ),
      ),
    );
  }

  /* List of tasks with thumbnail, photo count, name and description
  
     task -> Task: The task to show info about */
  Widget showTaskCard(Task task, int index) {
    return InkWell(
      child: new Card(
        elevation: 5,
        child: new Container(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              Row(
                children: [
                  showThumbnail(task, index),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            new Text(
                              task.name,
                              overflow: TextOverflow.fade,
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            new Text(
                              task.note,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                              style: new TextStyle(
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  showImageCount(task, index),
                  showTaskStatus(task, index),
                ],
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        bool showNotReq = _cloudPhotos == null || (_cloudPhotos[index] == 0);
        Get.to(TaskPage(
          task: task,
          showNotReq: showNotReq,
        )).then((value) {
          setState(() {
            refreshProgress();
          });
        });
      },
    );
  }

  /* On task card, showing appropriate singular/plural text for photo count

     task -> Task: The task to get image count for 
  */
  Widget showImageCount(Task task, int index) {
    int imageCount = task.getTaskImageCount();

    String singularOrPlural;
    if (imageCount == 1) {
      singularOrPlural = " photo";
    } else {
      singularOrPlural = " photos";
    }

    return Text(
      (_cloudPhotos == null || (_cloudPhotos[index] == 0))
          ? imageCount.toString() + singularOrPlural + " in device"
          : imageCount.toString() +
              singularOrPlural +
              " in device (" +
              _cloudPhotos[index].toString() +
              " in cloud)",
      style: new TextStyle(
        fontStyle: FontStyle.italic,
        color: Colors.grey,
        fontSize: 12,
      ),
    );
  }

  /* On task card, showing appropriate status label on bottom right

     task -> Task: The task to get status for 
  */
  Widget showTaskStatus(Task task, int index) {
    TaskStatus status = task.getTaskProgress();

    // For code redundancy as this is called for all status cases
    Widget statusWidget(IconData icon, Color color, String text) {
      return Row(
        children: [
          Icon(icon, color: color, size: 14),
          Text(
            " " + text,
            textAlign: TextAlign.right,
            style: new TextStyle(
              color: color,
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    switch (status) {
      case TaskStatus.NOT_STARTED:
        if (_cloudPhotos != null && _cloudPhotos[index] != 0) {
          if (sector.getUnsyncedPhotos() == 0) {
            return statusWidget(Icons.cloud, Colors.blue, "Cloud Available");
          } else {
            return statusWidget(
                Icons.cloud_off, Colors.yellow[700], "Not Synced");
          }
        }
        return statusWidget(Icons.error, Colors.red[400], "Photos Needed");
        break;
      case TaskStatus.NOT_REQUIRED:
        if (_cloudPhotos != null && _cloudPhotos[index] != 0) {
          if (sector.getUnsyncedPhotos() == 0) {
            return statusWidget(Icons.cloud, Colors.blue, "Cloud Available");
          }
        }
        return statusWidget(
            Icons.indeterminate_check_box, Colors.grey, "Not Required");
        break;
      case TaskStatus.DONE_NOT_SYNCED:
        return statusWidget(Icons.cloud_off, Colors.yellow[700], "Not Synced");
      case TaskStatus.DONE_SYNCED:
        return statusWidget(
            Icons.cloud_done, Colors.greenAccent[700], "Synced");
      case TaskStatus.INVALID:
        return statusWidget(Icons.error, Colors.red[300], "Error");
    }
    return null;
  }

  /* Thumbnail shown on leftmost of task card

     task -> Task: The task to show thumbnail for */
  Widget showThumbnail(Task task, int index) {
    TaskImage thumbnail = task.getTaskThumbnail();

    if (_cloudThumbs == null || _cloudThumbs[index] == null) {
      if (sector.tasks[index].thumbnail != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(5.0),
          child: new FadeInImage(
            fit: BoxFit.cover,
            fadeInDuration: Duration(milliseconds: 100),
            fadeOutDuration: Duration(milliseconds: 100),
            placeholder: AssetImage("images/placeholder.png"),
            image: sector.tasks[index].thumbnail,
            height: 96.0,
            width: 96.0,
          ),
        );
      } else if (thumbnail == null) {
        return Icon(Icons.photo_library, size: 96.0, color: Colors.grey);
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(5.0),
          child: new FadeInImage(
            fit: BoxFit.cover,
            fadeInDuration: Duration(milliseconds: 100),
            fadeOutDuration: Duration(milliseconds: 100),
            placeholder: AssetImage("images/placeholder.png"),
            image: thumbnail.image,
            height: 96.0,
            width: 96.0,
          ),
        );
      }
    } else {
      return FutureBuilder(
        future: _cloudThumbs[index],
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (sector.tasks[index].thumbnail != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(5.0),
              child: new FadeInImage(
                fit: BoxFit.cover,
                fadeInDuration: Duration(milliseconds: 100),
                fadeOutDuration: Duration(milliseconds: 100),
                placeholder: AssetImage("images/placeholder.png"),
                image: sector.tasks[index].thumbnail,
                height: 96.0,
                width: 96.0,
              ),
            );
          } else if (thumbnail != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(5.0),
              child: new FadeInImage(
                fit: BoxFit.cover,
                fadeInDuration: Duration(milliseconds: 100),
                fadeOutDuration: Duration(milliseconds: 100),
                placeholder: AssetImage("images/placeholder.png"),
                image: thumbnail.image,
                height: 96.0,
                width: 96.0,
              ),
            );
          } else if (!snapshot.hasData) {
            return Icon(Icons.photo_library, size: 96.0, color: Colors.grey);
          } else {
            sector.tasks[index].thumbnail = snapshot.data.image;
            return ClipRRect(
              borderRadius: BorderRadius.circular(5.0),
              child: new FadeInImage(
                fit: BoxFit.cover,
                fadeInDuration: Duration(milliseconds: 100),
                fadeOutDuration: Duration(milliseconds: 100),
                placeholder: AssetImage("images/placeholder.png"),
                image: snapshot.data.image,
                height: 96.0,
                width: 96.0,
              ),
            );
          }
        },
      );
    }
  }

  /* On top right */
  Widget showMarkDoneButton() {
    return FlatButton(
      onPressed: () {
        setAllMarkNotRequired();
      },
      color: Colors.black.withOpacity(0.35),
      child: Icon(
        Icons.check_circle,
        size: 28,
        color: Colors.blueGrey[300],
      ),
      padding: EdgeInsets.all(0.1),
      shape: CircleBorder(),
    );
  }

  /* Action for widget showNotRequired() which allows the user to set the
    task as not required */
  void setAllMarkNotRequired() {
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
        for (Task task in sector.tasks) {
          if (task.getTaskProgress() != TaskStatus.DONE_NOT_SYNCED ||
              task.getTaskProgress() != TaskStatus.DONE_SYNCED) {
            task.setTaskNotRequired();
          }
        }
        setState(() {
          updateSectorCloudProgress();
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
              'This will locally mark all incomplete tasks as not required, ' +
                  'meaning tasks will be left blank and without images when ' +
                  'submitted.\n\nYour progression may not reflect what '
                      'others see on the cloud.',
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
