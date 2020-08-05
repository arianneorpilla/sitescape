import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:sitescape/services/ui.dart';

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
class CameraScanScreenState extends State<CameraScanScreen>
    with WidgetsBindingObserver {
  CameraController _controller;
  QRViewController _qrController;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Future<void> _initializeControllerFuture;

  String _qrText;
  bool _isLampOn;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

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
    _qrController.dispose();
    WidgetsBinding.instance.removeObserver(this);
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
    } else if (state == AppLifecycleState.inactive) {
      // app is inactive
    } else if (state == AppLifecycleState.paused) {
      Get.back();
      // user is about quit our app temporally
    }
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
          showBackFloatButton(),
          Center(
            child: ImageIcon(
              AssetImage("images/home/icon_scanner.png"),
              size: (MediaQuery.of(context).size.width / 3) * 2,
              color: Colors.white.withOpacity(0.1),
            ),
          )
          // showCompass(),
        ],
      ),
      // floatingActionButton: showFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(bottom: 48),
        child: BottomAppBar(
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
      ),
    );
  }

  Widget showCameraPreview() {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // If the Future is complete, display the preview.
          return Center(
            child: CameraPreview(_controller),
          );
        } else {
          // Otherwise, display a loading indicator.
          return Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
      },
    );
  }

  Widget showLamp() {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 36, 12, 0),
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
                ? Colors.blue.withOpacity(0.7)
                : Colors.grey.withOpacity(0.7),
            child: ImageIcon(
              AssetImage("images/icons/icon_torch.png"),
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
