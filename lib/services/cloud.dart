import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as ph;
import 'package:http/http.dart' as http;

import 'package:sitescape/main.dart';
import 'package:sitescape/services/classes.dart';

Future<List<String>> getPhotosInCloudFolder(String path) async {
  // print(gCloudPath + path);
  final StorageReference storageRef =
      FirebaseStorage.instance.ref().child(path);
  Map<dynamic, dynamic> listed = (await storageRef.listAll());

  // print(listed["items"].keys.toList());
  List<dynamic> items = listed["items"].keys.toList();
  List<String> fileNames = new List<String>.from(items);

  fileNames.sort((a, b) => b.compareTo(a));

  return fileNames;
}

Future syncPhoto(
    Sector sec, FileTaskImage taskImage, VoidCallback callback) async {
  if (!gTransaction) {
    return;
  }

  File file = taskImage.imageFile;
  // print(file.path);

  FlutterImageCompress.validator.ignoreCheckExtName = true;
  File workingFile = File(ph.join(gTempDir.path,
      ph.basename(file.path) + "_compressed" + ph.extension(file.path)));
  workingFile.createSync(recursive: true);
  // File thumbFile = File(ph.join(gTempDir.path,
  //     ph.basename(file.path) + "_thumbnail" + ph.extension(file.path)));

  workingFile.createSync(recursive: true);
  // thumbFile.createSync(recursive: true);

  workingFile = await FlutterImageCompress.compressAndGetFile(
    file.path,
    ph.join(gTempDir.path,
        ph.basenameWithoutExtension(file.path) + "_compressed.jpg"),
    minWidth: 1920,
    minHeight: 1080,
    quality: 80,
    format: CompressFormat.jpeg,
  );

  StorageReference storageReference =
      FirebaseStorage.instance.ref().child(taskImage.getCloudPath());
  try {
    await storageReference.getDownloadURL();
  } catch (e) {
    FirebaseUser user = await gUserAuth.getCurrentUser();

    StorageMetadata metadata = StorageMetadata(customMetadata: {
      'uid': user.uid,
    });

    StorageUploadTask uploadTask =
        storageReference.putFile(workingFile, metadata);
    print("Uploaded: " + ph.basename(workingFile.path));
    await uploadTask.onComplete;

    if (uploadTask.isSuccessful) {
      workingFile.deleteSync();

      String newPath = ph.join(
        gExtDir.path,
        taskImage.siteName,
        taskImage.subName,
        taskImage.secName,
        taskImage.getBasename(true),
      );

      print("name" + taskImage.siteName);

      file.renameSync(newPath);
      print("Rename: " + newPath);
    } else {
      callback();
    }
  }

  sec.key.currentState.refresh();

  return;
}

Future downloadPhoto(Sector sec, String imageBasename) async {
  if (!gTransaction) {
    return;
  }

  String localPath = ph.join(sec.getDirectory().path, imageBasename);
  String cloudPath = ph.join(sec.getCloudPath(), imageBasename);

  bool fileExists = await File(localPath).exists();

  final StorageReference storageRef =
      FirebaseStorage.instance.ref().child(cloudPath);

  String url = "";
  url = await storageRef.getDownloadURL();

  if (!fileExists) {
    var imageBytes = await http.get(url);
    File file = new File(localPath);
    file.createSync(recursive: true);
    file.writeAsBytesSync(imageBytes.bodyBytes);
  }

  sec.key.currentState
      .setDownloadCount(sec.key.currentState.getDownloadCount() - 1);
  sec.key.currentState.refresh();

  return;
}
