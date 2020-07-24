import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

/* Screen for taking photo, has entire preview as background and take
   picture button
   
   camera -> CameraDescription: To use as camera
   selection -> UserSelection: For image filename, etc. */
class CameraScanScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScanScreen({Key key, @required this.camera}) : super(key: key);

  @override
  CameraScanScreenState createState() => CameraScanScreenState();
}

/* State for CameraScanScreen */
class CameraScanScreenState extends State<CameraScanScreen> {
  CameraController _controller;
  QRViewController _qrController;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Future<void> _initializeControllerFuture;

  String _qrText;
  bool _isLampOn;

  @override
  void initState() {
    super.initState();
    // Controller to display the current output from camera.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.veryHigh,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
    _isLampOn = false;
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    _qrController = controller;
    controller.scannedDataStream.listen((scanData) {
      if (_qrText == null) {
        _qrText = scanData;
        Get.back(result: _qrText);
      }
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          // showCameraPreview(),
          showCameraPreview(),
          Column(
            children: <Widget>[
              Expanded(
                flex: 5,
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                ),
              ),
            ],
          ),
          showLamp(),
          showBackButton(),
          Center(
            child: Icon(
              Icons.center_focus_weak,
              size: (MediaQuery.of(context).size.width / 4) * 3,
              color: Colors.white.withOpacity(0.1),
            ),
          )
          // showCompass(),
        ],
      ),
      // floatingActionButton: showFloatingActionButton(),
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
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // If the Future is complete, display the preview.
          final size = MediaQuery.of(context).size;
          final deviceRatio = size.width / size.height;
          return Transform.scale(
            scale: _controller.value.aspectRatio / deviceRatio,
            child: Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: CameraPreview(_controller),
              ),
            ),
          );
        } else {
          // Otherwise, display a loading indicator.
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  /* On top left */
  Widget showBackButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 36, 16, 0),
      height: 96,
      width: 96,
      child: FittedBox(
        child: FlatButton(
          onPressed: () {
            Get.back();
          },
          color: Colors.grey.withOpacity(0.4),
          child: Icon(
            Icons.arrow_back,
            size: 28,
            color: Colors.white,
          ),
          padding: EdgeInsets.all(0.1),
          shape: CircleBorder(),
        ),
      ),
    );
  }

  Widget showLamp() {
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
                _isLampOn = !_isLampOn;
                _qrController.toggleFlash();
              });
            },
            color: _isLampOn
                ? Colors.blue.withOpacity(0.5)
                : Colors.grey.withOpacity(0.5),
            child: Icon(
              Icons.lightbulb_outline,
              size: 28,
              color: _isLampOn ? Colors.blue : Colors.white,
            ),
            padding: EdgeInsets.all(0.1),
            shape: CircleBorder(),
          ),
        ),
      ),
    );
  }
}
