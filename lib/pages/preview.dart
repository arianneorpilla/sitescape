import "dart:io";
import "dart:typed_data";

import "package:esys_flutter_share/esys_flutter_share.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import 'package:flutter_screenutil/screenutil.dart';
import "package:get/get.dart";
import "package:photo_view/photo_view.dart";
import "package:photo_view/photo_view_gallery.dart";
import "package:path/path.dart" as ph;

import 'package:sitescape/services/classes.dart';
import 'package:sitescape/services/ui.dart';

/* The Preview Page is for photo inspection and interaction; the user can
   zoom, pinch and scroll through a task"s gallery
   
   selection -> UserSelection: For passing site, sub, sec, task parameters
   startIndex -> int: Used for initialising which image should be shown first 
*/
class PreviewPage extends StatefulWidget {
  final Task task;
  final int startIndex;

  const PreviewPage({
    Key key,
    @required this.task,
    this.startIndex,
  }) : super(key: key);

  @override
  _PreviewScreenState createState() => _PreviewScreenState(this.task);
}

/* State for PreviewScreen */
class _PreviewScreenState extends State<PreviewPage> {
  final Task task;
  _PreviewScreenState(this.task);

  // To allow indication of initial page
  PageController _pageController;
  // Array of task images in the gallery
  List<FileTaskImage> allPhotos;

  @override
  void initState() {
    super.initState();
    // To allow indication of initial page
    _pageController = new PageController(initialPage: widget.startIndex);
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  Widget build(BuildContext context) {
    // Reset all photos with each build as delete operations may have happened
    allPhotos = task.getLocalPhotos();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          showPreviewGallery(),
          showBackFloatButton(),
          showShareButton(),
          showDeleteButton(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        notchMargin: 12.0,
        elevation: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Icon(Icons.camera_alt, color: Colors.transparent, size: 36),
          ],
        ),
        color: Colors.transparent,
        shape: CircularNotchedRectangle(),
      ),
    );
  }

  /* Main content of the page, using PhotoViewGallery on allPhotos */
  Widget showPreviewGallery() {
    return Center(
      child: Container(
        child: PhotoViewGallery.builder(
          pageController: _pageController,
          scrollPhysics: const BouncingScrollPhysics(),
          builder: (BuildContext context, int index) {
            return PhotoViewGalleryPageOptions.customChild(
              child: FadeInImage(
                fit: BoxFit.fitWidth,
                fadeInDuration: Duration(milliseconds: 100),
                fadeOutDuration: Duration(milliseconds: 100),
                placeholder: AssetImage("images/placeholder.png"),
                image: allPhotos[index].image,
              ),
              initialScale: PhotoViewComputedScale.contained * 1,
              minScale: PhotoViewComputedScale.contained * 1,
              maxScale: PhotoViewComputedScale.covered * 10,
            );
          },
          itemCount: allPhotos.length,
        ),
      ),
    );
  }

  /* On top right */
  Widget showShareButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 36, 12, 0),
        height: 96,
        width: 96,
        child: FittedBox(
          child: FlatButton(
            onPressed: () async {
              await sharePhoto();
            },
            color: Colors.blueAccent.withOpacity(0.2),
            child: ImageIcon(
              AssetImage("images/icons/icon_share.png"),
              size: 28,
              color: Colors.blueAccent,
            ),
            padding: EdgeInsets.all(0.1),
            shape: CircleBorder(),
          ),
        ),
      ),
    );
  }

  /* Calls share functionality */
  Future sharePhoto() async {
    int currentPage = _pageController.page.toInt();
    FileTaskImage toShare = allPhotos[currentPage];

    File fileToShare = toShare.imageFile;
    String filePath = toShare.getFilePath();

    Uint8List bytes = await fileToShare.readAsBytes();
    if (ph.extension(toShare.getFilePath()) == "png") {
      await Share.file(ph.basenameWithoutExtension(filePath),
          ph.basename(filePath), bytes, "image/png");
    } else {
      await Share.file(ph.basenameWithoutExtension(filePath),
          ph.basename(filePath), bytes, "image/jpeg");
    }
  }

  /* On top right offset from share */
  Widget showDeleteButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 36, 12, 0),
        height: 96,
        width: 96,
        margin: EdgeInsets.only(right: 64),
        child: FittedBox(
          child: FlatButton(
            onPressed: () {
              deletePhoto();
            },
            color: Colors.red.withOpacity(0.2),
            child: ImageIcon(
              AssetImage("images/icons/icon_delete.png"),
              size: 28,
              color: Colors.red,
            ),
            padding: EdgeInsets.all(0.1),
            shape: CircleBorder(),
          ),
        ),
      ),
    );
  }

  /* Calls dialog to prompt user to confirm if they wish to proceed with
     the deletion of the photo */
  void deletePhoto() {
    Widget logout = FlatButton(
      child: Text(
        "DELETE PHOTO",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.red,
          fontSize: ScreenUtil().setSp(40),
        ),
      ),
      onPressed: () {
        try {
          // Get current page and use it as index to delete
          int currentPage = _pageController.page.toInt();
          FileTaskImage toDelete = allPhotos[currentPage];

          // Delete image and update the gallery accordingly
          setState(() {
            toDelete.imageFile.deleteSync(recursive: false);
            allPhotos.remove(toDelete);
            // Pop the dialog
            Get.back();

            // If no more photos, exit the preview
            if (allPhotos.isEmpty) {
              Get.back();
            }
          });
        } catch (e) {
          print(e);
        }
      },
    );

    Widget cancel = FlatButton(
      child: Text(
        "CANCEL",
        style: TextStyle(
          color: Colors.black,
          fontSize: ScreenUtil().setSp(40),
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
            "Are you sure?",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: ScreenUtil().setSp(42),
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              "Deleting this photo will mean losing it permanently if it " +
                  "has not yet been synced with the cloud.",
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: ScreenUtil().setSp(40),
              ),
            ),
          ),
          actions: [logout, cancel],
        );
      },
    );
  }
}
