import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase/firebase.dart' as fb;
import 'package:path/path.dart' as ph;
import 'package:tfsitescapeweb/main.dart';

Future<List<String>> getPhotosInCloudFolder(String path) async {
  // print(cloudDir + path);
  final fb.StorageReference storageRef = userAuth
      .getStorage()
      .refFromURL("gs://tfsitescape.appspot.com")
      .child(path);

  fb.ListResult result = await storageRef.listAll();

  List<String> fileNames = [];
  result.items.forEach((i) => fileNames.add(i.name));

  print(fileNames);

  return fileNames;
}
