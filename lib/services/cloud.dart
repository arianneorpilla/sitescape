import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as ph;

import 'package:tfsitescape/main.dart';
import 'package:tfsitescape/services/classes.dart';

Future<List<dynamic>> getPhotosInCloudFolder(String path) async {
  // print(gCloudPath + path);
  final StorageReference storageRef =
      FirebaseStorage.instance.ref().child(path);
  Map<dynamic, dynamic> listed = (await storageRef.listAll());

  // print(listed["items"].keys.toList());
  return listed["items"].keys.toList();
}

Future syncPhoto(FileTaskImage taskImage) async {
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
  }

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
}
