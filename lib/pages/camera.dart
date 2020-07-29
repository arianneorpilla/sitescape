import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:get/get.dart';
import 'package:adv_camera/adv_camera.dart';
import 'package:tfsitescape/main.dart';

import 'package:tfsitescape/services/classes.dart';
import 'package:tfsitescape/services/util.dart';

/* Screen for taking photo, has entire preview as background and take
   picture button
   
   camera -> CameraDescription: To use as camera
   selection -> UserSelection: For image filename, etc. */
class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  final Task task;

  const CameraScreen({
    Key key,
    @required this.camera,
    this.task,
  }) : super(key: key);

  @override
  CameraScreenState createState() => CameraScreenState();
}

/* State for CameraScreen */
class CameraScreenState extends State<CameraScreen> {
  AdvCameraController _cameraController;

  bool _isBearingsOn;
  int _flashType;

  @override
  void initState() {
    super.initState();
    // Controller to display the current output from camera.

    // Next, initialize the controller. This returns a Future.
    _isBearingsOn = false;
    _flashType = 0;
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    super.dispose();
  }

  /* Take a picture and return the file to save */
  void _processPicture(String path) async {
    if (this.mounted) {
      // This is necessary for the settings to apply on slow cameras.
      print(path);

      ImageProperties properties =
          await FlutterNativeImage.getImageProperties(path);

      File processed;

      int scaleWidth = (properties.width * 1080 / properties.height).round();
      int scaleHeight = (properties.height * 1920 / properties.width).round();

      if (properties.height > 1080) {
        processed = await FlutterNativeImage.compressImage(
          path,
          targetWidth: scaleWidth,
          targetHeight: 1080,
        );
      } else if (properties.width > 1920) {
        processed = await FlutterNativeImage.compressImage(
          path,
          targetHeight: scaleHeight,
          targetWidth: 1920,
        );
      } else {
        processed = File(path);
      }

      File workingFile =
          await bakeTimestamp(File(processed.path), bearings: _isBearingsOn);

      FileTaskImage taskImage = FileTaskImage.create(
        widget.task,
        workingFile,
      );
      String fileName = taskImage.getFilePath();

      File file = new File(fileName);
      file.createSync(recursive: true);
      await workingFile.copy(fileName);
      workingFile.deleteSync();

      Get.back();
    }
    return null;
  }

  _onCameraCreated(AdvCameraController controller) {
    this._cameraController = controller;

    _cameraController.setFlashType(FlashType.off);
    _cameraController.setSessionPreset(CameraSessionPreset.photo);
    _cameraController.setSavePath(gTempDir.path);
    _cameraController.setPictureSize(1920, 1080);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          showCameraPreview(),
          showBackButton(),
          showCompass(),
          showFlash(),
        ],
      ),
      floatingActionButton: showFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        notchMargin: 12.0,
        elevation: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
                icon: Icon(Icons.camera_alt),
                color: Colors.transparent,
                iconSize: 36,
                onPressed: () {}),
          ],
        ),
        color: Colors.transparent,
        shape: CircularNotchedRectangle(),
      ),
    );
  }

  Widget showCameraPreview() {
    return Container(
      child: AdvCamera(
        onCameraCreated: _onCameraCreated,
        onImageCaptured: (String path) => _processPicture(path),
        cameraPreviewRatio: CameraPreviewRatio.r16_9,
        cameraSessionPreset: CameraSessionPreset.high,
        bestPictureSize: false,
        flashType: FlashType.off,
      ),
    );
  }

  /* On click, will call take a picture and create the image */
  Widget showFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: Colors.white.withOpacity(0.8),
      child: Icon(Icons.camera_alt, color: Colors.black, size: 36),
      elevation: 0,
      onPressed: () async {
        _cameraController.captureImage();
      },
    );
  }

  /* On top left */
  Widget showBackButton() {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 36, 16, 0),
        height: 96,
        width: 96,
        child: FittedBox(
          child: FlatButton(
            onPressed: () {
              Get.back();
            },
            color: Colors.grey.withOpacity(0.5),
            child: Icon(
              Icons.arrow_back,
              size: 28,
              color: Colors.white,
            ),
            padding: EdgeInsets.all(0.1),
            shape: CircleBorder(),
          ),
        ),
      ),
    );
  }

  Widget showCompass() {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 36, 16, 0),
        height: 96,
        width: 96,
        margin: EdgeInsets.only(right: 64),
        child: FittedBox(
          child: FlatButton(
            onPressed: () {
              setState(() {
                _isBearingsOn = !_isBearingsOn;
              });
            },
            color: _isBearingsOn
                ? Colors.blue.withOpacity(0.5)
                : Colors.grey.withOpacity(0.5),
            child: Icon(
              Icons.explore,
              size: 28,
              color: _isBearingsOn ? Colors.blue : Colors.white,
            ),
            padding: EdgeInsets.all(0.1),
            shape: CircleBorder(),
          ),
        ),
      ),
    );
  }

  Widget showFlash() {
    IconData flashIcon;
    Color flashColor;
    Color backColor;

    switch (_flashType) {
      case 0:
        flashIcon = Icons.flash_off;
        flashColor = Colors.white;
        backColor = Colors.grey.withOpacity(0.5);
        break;
      case 1:
        flashIcon = Icons.flash_on;
        flashColor = Colors.blue;
        backColor = Colors.blue.withOpacity(0.5);
        break;
      case 2:
        flashIcon = Icons.lightbulb_outline;
        flashColor = Colors.blue;
        backColor = Colors.blue.withOpacity(0.5);
        break;
    }

    return Align(
      alignment: Alignment.topRight,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 36, 16, 0),
        height: 96,
        width: 96,
        child: FittedBox(
          child: FlatButton(
            onPressed: () {
              setState(() {
                switch (_flashType) {
                  case 0:
                    _cameraController.setFlashType(FlashType.on);
                    _flashType = 1;
                    break;
                  case 1:
                    _cameraController.setFlashType(FlashType.torch);
                    _flashType = 2;
                    break;
                  case 2:
                    _cameraController.setFlashType(FlashType.off);
                    _flashType = 0;
                    break;
                }
              });
            },
            color: backColor,
            child: Icon(
              flashIcon,
              size: 28,
              color: flashColor,
            ),
            padding: EdgeInsets.all(0.1),
            shape: CircleBorder(),
          ),
        ),
      ),
    );
  }
}
