import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:disk_space/disk_space.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:intl/intl.dart';
import 'package:image_editor/image_editor.dart';
import 'package:path/path.dart' as ph;

import 'package:weather/weather_library.dart';

import 'package:tfsitescape/main.dart';
import 'package:tfsitescape/services/classes.dart';

/* Used to await an image and pre-cache it so it loads without blinking in.
   Used for the splash screen, where image takes time to load and thus
   looks ugly without this.
  
   url -> String: Path to image to pre-cache
*/
Future<Uint8List> loadImage(String url) {
  ImageStreamListener listener;

  final Completer<Uint8List> completer = Completer<Uint8List>();
  final ImageStream imageStream =
      AssetImage(url).resolve(ImageConfiguration.empty);

  listener = ImageStreamListener(
    (ImageInfo imageInfo, bool synchronousCall) {
      imageInfo.image
          .toByteData(format: ui.ImageByteFormat.png)
          .then((ByteData byteData) {
        imageStream.removeListener(listener);
        completer.complete(byteData.buffer.asUint8List());
      });
    },
    onError: (dynamic exception, StackTrace stackTrace) {
      imageStream.removeListener(listener);
      completer.completeError(exception);
    },
  );

  imageStream.addListener(listener);

  return completer.future;
}

/* Generate a cryptographic hash from a file using SHA-256, useful for
   filenames to prevent sequential naming collisions. */
String generateFileHash(File file) {
  // Read the bytes from the file and encode UTF-8.
  var bytes = file.readAsBytesSync().toString();
  var encoded = utf8.encode(bytes);

  // SHA256 - which outputs in base16.
  var hash = sha256.convert(encoded);

  // Encoding the raw bytes from SHA256 in base64 should give us more entropy
  // when truncating the filename to 8 characters.
  var base64Str = base64UrlEncode(hash.bytes).replaceAll("-", ",");

  return base64Str;
}

String generateStringHash(String text) {
  var encoded = utf8.encode(text);

  // SHA256 - which outputs in base16.
  var hash = sha256.convert(encoded);

  // Encoding the raw bytes from SHA256 in base64 should give us more entropy
  // when truncating the filename to 8 characters.
  var base64Str = base64UrlEncode(hash.bytes);
  return base64Str;
}

/* Used to get ratio of free/total device storage information, 
   useful in Free up space menu option. */
Future<double> getDiskSpaceInfo() async {
  double a = await DiskSpace.getFreeDiskSpace;
  double b = await DiskSpace.getTotalDiskSpace;
  return (a / b);
}

/* Used to check if an internet connection is available to prevent futile
   connection attempts in app behaviour. */
Future<bool> isConnectionAvailable() async {
  try {
    final result = await InternetAddress.lookup('tfsitescape.firebaseio.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      return true;
    }
  } on SocketException catch (_) {
    return false;
  }
  return false;
}

/* Used to check if location services is available to prevent futile
   location request attempts in app behaviour. */
Future<bool> isLocationAvailable() async {
  bool enabled = await Geolocator().isLocationServiceEnabled();
  return enabled;
}

/* Refreshes site data and saves the new data in the local cache for offline
   use. Offline callback is called if there is no internet available to
   trigger a message from the current context. 
   
   {offlineCallback -> void}: Calls when internet is unavailable
*/
Future refreshSites({offlineCallback}) async {
  sites = [];

  String siteCacheDir = extDir.path + "/.sites";
  File(siteCacheDir).createSync();
  File siteCache = File(siteCacheDir);

  bool isOnline = await isConnectionAvailable();
  if (!isOnline) {
    offlineCallback();
    loadLocalSites();
    return;
  }

  final firestoreInstance = Firestore.instance;
  Map<dynamic, dynamic> sitesChild = {};

  firestoreInstance.collection("sites").snapshots().listen((result) {
    if (result.documents.isNotEmpty) {
      result.documents.forEach((entry) {
        Site site = Site.fromMap(entry.documentID, entry.data);
        site.populate();
        sites.add(site);
        sitesChild.addAll({entry.documentID: entry.data});
      });
      sites.sort((a, b) => a.name.compareTo(b.name));

      String cacheContents = json.encode(sitesChild);
      print(cacheContents);
      siteCache.writeAsString(cacheContents);
    }
  });

  return;
}

Future<Site> getLastSiteAccessed() async {
  String lastSiteCacheDir = extDir.path + "/.lastaccessed";
  File lastSiteCache = File(lastSiteCacheDir);

  if (lastSiteCache.existsSync()) {
    for (int i = 0; i < sites.length; i++) {
      if (lastSiteCache.readAsStringSync() == sites[i].code) {
        return sites[i];
      }
    }
  }
  return null;
}

void setLastSiteAccessed(Site site) {
  String lastSiteCacheDir = extDir.path + "/.lastaccessed";
  File lastSiteCache = File(lastSiteCacheDir);

  lastSiteCache.createSync();
  lastSiteCache.writeAsStringSync(site.code);
}

void freeUpSpace() {
  List<FileSystemEntity> files = extDir.listSync(recursive: true);

  for (FileSystemEntity i in files) {
    if (ph.extension(i.path) == ".jpg" &&
        (!ph.basenameWithoutExtension(i.path).endsWith("-L"))) {
      print("FILE DELETE: " + i.path);
      i.deleteSync();
    }

    if (ph.extension(i.path) == ".notrequired") {
      print("FILE DELETE: " + i.path);
      i.deleteSync();
    }
  }
}

/* If the cache exists, load it. Used on startup so that site data is
   available on startup. */
Future loadLocalSites() async {
  sites = [];

  String siteCacheDir = extDir.path + "/.sites";
  bool siteCacheExists = await File(siteCacheDir).exists();

  if (siteCacheExists) {
    print("Site cache exists: " + siteCacheDir);
    String contents = await File(siteCacheDir).readAsString();
    sites = jsonToSites(contents);
    sites.sort((a, b) => a.name.compareTo(b.name));
  } else {
    print("Site cache not found.");
    sites = [];
  }
}

/* Returns a pleasant greeting appropriate to current device time. */
String getTimeFlavour() {
  TimeOfDay now = TimeOfDay.now();
  if (now.hour >= 5 && now.hour < 12) {
    return "Good morning";
  } else if (now.hour >= 12 && now.hour <= 17) {
    return "Good afternoon";
  } else {
    return "Good evening";
  }
}

/* Returns weather from OpenWeather API. */
Future<Weather> getWeather() async {
  if (userLat == null || userLong == null) {
    // Get current user's GPS coordinates.
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    userLat = position.latitude;
    userLong = position.longitude;
  }

  WeatherStation weatherStation =
      new WeatherStation("d61e123d47c998fb20c54a8cc5bc300b");

  Weather weather = await weatherStation.currentWeather(userLat, userLong);
  return weather;
}

/* Iterate on all sites and return the ones with closest distance.
   Returns [List<Site>, List<double>], closest site and distance. */
Future<List<dynamic>> getThreeClosestSites() async {
  if (userLat == null || userLong == null) {
    // Get current user's GPS coordinates.
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    userLat = position.latitude;
    userLong = position.longitude;
  }

  // List of closest sites and distances to return
  List<Site> closestSites = [];
  List<double> closestDistances = [];
  // Necessary as we'll be manipulating and removing from this list
  List<Site> allSites = []..addAll(sites);
  List<double> allDistances = [];

  // Get all distances from every site
  for (Site i in allSites) {
    allDistances.add(
      await Geolocator()
          .distanceBetween(i.latitude, i.longitude, userLat, userLong),
    );
  }

  // Perform three times as we are getting three of the closest sites
  for (int i = 0; i < 3; i++) {
    double minimum = -1;
    // Get the minimum distance among all sites
    for (var i = 0; i < allDistances.length; i++) {
      if (minimum == -1 || minimum > allDistances[i]) {
        minimum = allDistances[i];
      }
    }

    // Get the site index of the minimum
    int indexMin = allDistances.indexOf(minimum);

    // Add these sites/distances of the min's index to the appropriate lists
    closestSites.add(allSites[indexMin]);
    closestDistances.add(allDistances[indexMin]);

    // Remove these sites from the list to check in the next iteration
    allSites.removeAt(indexMin);
    allDistances.removeAt(indexMin);
  }

  return [closestSites, closestDistances];
}

/* Return the appropriate unit of measurement as a suffix to a given
   distance in meters. 

   distance -> double: Distance in meters 
*/
String getDistanceText(double distance) {
  // If meters is greater than 1000, use km instead.
  if (distance >= 1000) {
    int m = distance ~/ 1000;
    return m.toString() + "km";
  } else {
    int m = distance.round();
    return m.toString() + "m";
  }
}

/* Uses Fuzzy string searching to filter sites in search properly. Limit
   is used to limit the search results for performance.
   
   searchTerm -> String: String to use for a filter
   limit -> int: The max number of sites to return */
List<Site> filterSitesByNameOrCode(String searchTerm, int limit) {
  // If the search term is blank, return the sites in alphabetical order
  // as already sorted
  if (searchTerm == "") {
    // return [];
    // Safety for when limit exceeds the site length
    if (limit > sites.length) {
      limit = sites.length;
    }

    return sites.sublist(0, limit);
  }

  // Useful so we can iterate on these and get their site indexes
  List<String> names = [];
  List<String> codes = [];
  // To fairly discern between codes and names in the search
  List<String> namesAndCodes = [];

  for (int i = 0; i < sites.length; i++) {
    names.add(sites[i].name);
    codes.add(sites[i].code);
    namesAndCodes.add(sites[i].name);
    namesAndCodes.add(sites[i].code);
  }

  // Perform a Fuzzy string search with the term on all names/codes
  final fuzzy = Fuzzy(
    namesAndCodes,
    options: FuzzyOptions(
      threshold: 0.2,
      shouldSort: true,
      findAllMatches: false,
    ),
  );
  final results = fuzzy.search(searchTerm);

  // Safety for when limit exceeds the results length
  if (results.length < limit) {
    limit = results.length;
  }

  List<Site> bestResults = [];
  for (int i = 0; i < limit; i++) {
    // Get the index of a name match
    int addIndex = names.indexOf(results[i].item);
    // If it's not a name match, it must be a code match
    if (addIndex == -1) {
      addIndex = codes.indexOf(results[i].item);
    }

    // If an index match is found, add it
    if (addIndex != -1 && !bestResults.contains(sites[addIndex])) {
      bestResults.add(sites[addIndex]);
    }
  }

  return bestResults;
}

/* Draw a watermark on top of an image and return the manipulated file
   with the appropriate timestamp.

   pathToImage -> String: The path to the file to manipulate. */
Future<File> bakeTimestamp(File file, {bool bearings = false}) async {
  // Get current time for timestamp to bake
  DateTime now = DateTime.now();
  String timeStamp = DateFormat('yyyy-MM-dd kk:mm:ss').format(now);

  // Set up the text option to use to edit the image
  final textOption = AddTextOption();

  // For code redundancy as this is called four times
  void addWatermark(
    double x,
    double y,
    Color color,
    String text,
  ) {
    textOption.addText(
      EditorText(
        offset: Offset(x, y),
        text: text,
        fontSizePx: 48,
        textColor: color,
      ),
    );
  }

  // For compass bearings
  double compassDouble = await FlutterCompass.events.first;
  int compassValue = compassDouble.floor();
  int compassRelative = compassValue.floor() % 90;

  String trueBearing = compassValue.toString() + "°T";
  String relativeBearing;

  if (0 <= compassValue && compassValue < 90) {
    relativeBearing = "N " + compassRelative.toString() + "°E";
  } else if (90 <= compassValue && compassValue < 180) {
    relativeBearing = "S " + compassRelative.toString() + "°E";
  } else if (180 <= compassValue && compassValue < 270) {
    relativeBearing = "S " + compassRelative.toString() + "°W";
  } else {
    relativeBearing = "N " + compassRelative.toString() + "°W";
  }

  String compass = trueBearing + ", " + relativeBearing;

  // For black border
  addWatermark(8, 12, Colors.black, timeStamp);
  addWatermark(12, 8, Colors.black, timeStamp);
  addWatermark(12, 12, Colors.black, timeStamp);
  addWatermark(8, 8, Colors.black, timeStamp);
  // For white on top of the black border
  addWatermark(10, 10, Colors.white, timeStamp);

  if (bearings == true) {
    // For black border
    addWatermark(8, 60, Colors.black, compass);
    addWatermark(12, 56, Colors.black, compass);
    addWatermark(12, 60, Colors.black, compass);
    addWatermark(8, 56, Colors.black, compass);
    // For white on top of the black border
    addWatermark(10, 58, Colors.white, compass);
  }

  final editorOption = ImageEditorOption();
  editorOption.addOption(textOption);

  // Perform the operation
  return ImageEditor.editFileImageAndGetFile(
    file: file,
    imageEditorOption: editorOption,
  );
}

Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) {
  if (message.containsKey('data')) {
    // Handle data message
    final dynamic data = message['data'];
  }

  if (message.containsKey('notification')) {
    // Handle notification message
    final dynamic notification = message['notification'];
  }

  // Or do other work.
}
