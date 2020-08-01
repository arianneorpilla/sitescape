import 'dart:convert';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as ph;
import 'package:tfsitescapeweb/main.dart';
import 'package:firebase/firebase.dart' as fb;
import 'package:tfsitescapeweb/services/cloud.dart';
import 'package:http/http.dart' as http;

/* Represents a cell-site with a unique code. Top-level nested 
   structure loaded from the cloud or as a JSON file. 
   
   Subsite mappings are stored separately to the list of Subsites
   to allow exporting to JSON.
   
   code -> String: A site code, typically a 5 letter ID (primary key)
   name -> String: The site's name, used as header and search term
   address -> String: The site's postal address and location
   build -> String: The type of work done on site, i.e. Rigging, Civil
   network -> String: The network associated with the site, i.e. Telstra
   latitude -> double: GPS coordinates, north-south
   longitude -> double: GPS coordinates, west-east
   maps -> Map<dynamic, dynamic>: A map of subsites for JSON storage
   subsites -> List<Subsite>: Subcategories under the site
*/
class Site {
  final String code;
  final String name;
  final String address;
  final String build;
  final String network;
  final double latitude;
  final double longitude;
  final Map<dynamic, dynamic> maps;
  List<Subsite> subsites;

  Site(
    this.code,
    this.name,
    this.address,
    this.build,
    this.network,
    this.latitude,
    this.longitude,
    this.maps,
  );

  /* Used after decode to get a Site from JSON key-value String pairs.
  
     key -> String: A primary key from a JSON map, this is the code
     value -> Map<dynamic, dynamic>: A JSON map containing site data
  */
  /* Used after decode to get a Site from JSON key-value String pairs.
  
     key -> String: A primary key from a JSON map, this is the code
     value -> Map<dynamic, dynamic>: A JSON map containing site data
  */
  factory Site.fromMap(String key, Map<dynamic, dynamic> value) {
    // Convert GPS values to double, as JSON has no concept of int/double
    double latitude = value["latitude"].toDouble();
    double longitude = value["longitude"].toDouble();

    Map<dynamic, dynamic> maps;

    if (value["subsites"] == null) {
      maps = {};
    } else {
      maps = value["subsites"];
    }

    return Site(
      key,
      value["sitename"],
      value["address"],
      value["build"],
      value["network"],
      latitude,
      longitude,
      maps,
    );
  }

  Map<String, dynamic> getSiteJson() {
    Map<dynamic, dynamic> subsitesMap;
    Map<dynamic, dynamic> sectorsMap;
    Map<dynamic, dynamic> tasksMap;

    subsitesMap = {};
    for (Subsite sub in this.subsites) {
      sectorsMap = {};
      for (Sector sec in sub.sectors) {
        tasksMap = {};
        for (Task task in sec.tasks) {
          tasksMap.addAll({
            task.name: {
              "note": task.note,
              "required": 0,
            }
          });
        }
        sectorsMap.addAll({
          sec.name: {
            "tasks": tasksMap,
            "name": sec.name,
          }
        });
      }
      subsitesMap.addAll({
        sub.name: {
          "sectors": sectorsMap,
          "name": sub.name,
        }
      });
    }

    Map<String, dynamic> siteJson = {
      this.code: {
        "sitename": this.name,
        "address": this.address,
        "build": this.build,
        "network": this.network,
        "latitude": this.latitude,
        "longitude": this.longitude,
        "subsites": subsitesMap
      }
    };

    return siteJson;
  }

  /*
    Used after factory constructor to populate subsites. Necessary to set
    up a reference to site. 
  */
  void populate() {
    // Initialise subsites and make them from the maps.
    subsites = [];
    maps.forEach((k, v) => subsites.add(Subsite.fromMap(k, v)));

    subsites.forEach((sub) {
      sub.site = this;
      sub.populate();
    });
    // Sort the subsites by alphabetical order
    subsites.sort((a, b) => a.name.compareTo(b.name));
  }

  factory Site.add() {
    return Site(
      "",
      "",
      "",
      "",
      "",
      null,
      null,
      {},
    );
  }

  Future<void> updateCloudEntry() async {
    Map<dynamic, dynamic> subsitesMap;
    Map<dynamic, dynamic> sectorsMap;
    Map<dynamic, dynamic> tasksMap;

    subsitesMap = {};
    for (Subsite sub in this.subsites) {
      sectorsMap = {};
      for (Sector sec in sub.sectors) {
        tasksMap = {};
        for (Task task in sec.tasks) {
          tasksMap.addAll({
            task.name: {
              "note": task.note,
              "required": 0,
            }
          });
        }
        sectorsMap.addAll({
          sec.name: {
            "tasks": tasksMap,
            "name": sec.name,
          }
        });
      }
      subsitesMap.addAll({
        sub.name: {
          "sectors": sectorsMap,
          "name": sub.name,
        }
      });
    }

    await userAuth
        .getDatabase()
        .refFromURL("gs://tfsitescape.firebaseio.com")
        .child("sites")
        .child(
          ph.basenameWithoutExtension(
            ph.basenameWithoutExtension(this.code),
          ),
        )
        .set(
      {
        "sitename": this.name,
        "address": this.address,
        "build": this.build,
        "network": this.network,
        "latitude": this.latitude,
        "longitude": this.longitude,
        "subsites": subsitesMap
      },
    );

    Map<String, dynamic> sitesMap = {};
    sites.forEach((a) => sitesMap.addAll(a.getSiteJson()));

    String toWrite = json.encode(sitesMap);

    fb.StorageReference sitesRef = userAuth
        .getStorage()
        .refFromURL("gs://tfsitescape.appspot.com")
        .child("tfcloud/sites.json");

    await sitesRef
        .putString(
          toWrite,
        )
        .future
        .then((snapshot) {
      print("Done");
      sitesRef.getDownloadURL();
    });
    return;
  }

  /* From the site's network String value, get the appropriate AssetImage.
     Called in Search and Site pages
  */
  AssetImage getIconFromNetwork() {
    switch (this.network) {
      case "Telstra":
        return AssetImage("images/telstra.png");
      case "Optus":
        return AssetImage("images/optus.png");
      default:
        return null;
    }
  }
}

enum SyncStatus {
  SITE_NO_ADDITIONS,
  SITE_HAS_UNUPLOADED,
  SITE_UPLOADING,
  SITE_SYNCED
}

/* From a JSON represented string probably obtained and loaded
   locally, convert the String to an appropriate client-readabler
   list of Site class objects.

   text -> String: Text containing JSON site data
*/
List<Site> jsonToSites(String text) {
  List<Site> sites = [];

  Map sitesJson = json.decode(text);

  sitesJson.forEach((key, value) => sites.add(Site.fromMap(key, value)));

  sites.sort((a, b) => a.name.compareTo(b.name));

  return sites;
}

/* From the cloud, convert the database mappings to an appropriate
   client-readable list of Site class objects.
   
   snapshot -> Map<dynamic, dynamic>: JSON map pulled from database 
*/
List<Site> snapshotToSites(Map<dynamic, dynamic> snapshot) {
  List<Site> sites = [];

  snapshot.forEach((key, values) {
    Site site = Site.fromMap(key, values);
    sites.add(site);
  });

  sites.sort((a, b) => a.name.compareTo(b.name));

  return sites;
}

/* Represents a Subsite within a Site with a unique name.
   
   Sector mappings are stored separately to the list of Sectors
   to allow exporting to JSON.
   
   name -> String: Subsite name
   maps -> Map<dynamic, dynamic>: Sectors JSON data
   sectors -> List<Sector>: Array of sectors under the Subsite 
*/
class Subsite {
  final String name;
  final Map<dynamic, dynamic> maps;
  List<Sector> sectors;
  Site site;

  Subsite(
    this.name,
    this.maps,
  );

  /* Used after decode to get a Subsite from a JSON string. 
     Called recursively from Site.fromMap() 
     
     key -> String: A primary key from a JSON map, this is the subsite name
     value -> Map<dynamic, dynamic>: A JSON map containing subsite data
  */
  factory Subsite.fromMap(String key, Map<dynamic, dynamic> value) {
    Map<dynamic, dynamic> maps;

    if (value["sectors"] == null) {
      maps = {};
    } else {
      maps = value["sectors"];
    }

    return Subsite(key, maps);
  }

  void populate() {
    sectors = [];
    maps.forEach((k, v) => sectors.add(Sector.fromMap(k, v)));

    sectors.forEach((sec) {
      sec.subsite = this;
      sec.populate();
    });

    sectors.sort((a, b) => a.name.compareTo(b.name));
  }
}

/* Represents a Sector within a Site with a unique name,
   contains tasks.
   
   Task mappings are stored separately to the list of Task
   to allow exporting to JSON.
   
   name -> String: Sector name
   maps -> Map<dynamic, dynamic>: Tasks JSON data
   sectors -> List<Sector>: Array of tasks under the Subsite 
*/
class Sector {
  final String name;
  final Map<dynamic, dynamic> maps;
  List<Task> tasks;
  Subsite subsite;
  bool downloading;
  bool uploading;

  bool inTransaction() {
    return (downloading || uploading);
  }

  Sector(
    this.name,
    this.maps,
    this.downloading,
    this.uploading,
  );

  /* Used after decode to get a Sector from a JSON string. 
     Called recursively from Subsite.fromMap() 
     
     key -> String: A primary key from a JSON map, this is the sector name
     value -> Map<dynamic, dynamic>: A JSON map containing sector data
  */
  factory Sector.fromMap(String key, Map<dynamic, dynamic> value) {
    Map<dynamic, dynamic> maps;

    if (value["tasks"] == null) {
      maps = {};
    } else {
      maps = value["tasks"];
    }

    return Sector(
      key,
      maps,
      false,
      false,
    );
  }

  populate() {
    tasks = [];
    maps.forEach((k, v) => tasks.add(Task.fromMap(k, v)));

    tasks.forEach((task) => task.sector = this);

    // Sort the subsites by alphabetical order
    tasks.sort((a, b) => a.name.compareTo(b.name));
  }

  String getCloudPath() {
    return ph.join(
      cloudDir,
      subsite.site.name,
      subsite.name,
      this.name,
    );
  }
}

/* Most atomic among Site -> Subsite -> Sector -> Task.
   Represents a Task with a unique name, note and
   number of images required. 
   
   name -> String: Task name
   note -> String: Description of the task
   required -> Number of pictures required to consider task complete
*/
class Task {
  final String name;
  final String note;
  final int required;
  Sector sector;
  NetworkImage thumbnail;

  Task(
    this.name,
    this.note,
    this.required,
  );

  /* Used after decode to get a Task from a JSON string.
     Called recursively from Sector.fromMap() 

     key -> String: A primary key from a JSON map, this is the task name
     value -> Map<dynamic, dynamic>: A JSON map containing task data */
  factory Task.fromMap(String key, Map<dynamic, dynamic> value) {
    return Task(key, value["note"], value["required"]);
  }

  String getCloudPath() {
    return sector.getCloudPath();
  }

  Future<List<Future<NetworkTaskImage>>> getCloudPhotos({Task task}) async {
    List<String> filenames = await getPhotosInCloudFolder(getCloudPath());
    List<Future<NetworkTaskImage>> futures = [];

    for (String basename in filenames) {
      List<String> parts = ph.basenameWithoutExtension(basename).split("-");
      if (task == null || task.name == parts[1]) {
        futures.add(getCloudPhoto(basename));
      }
    }

    return futures;
  }

  Future<NetworkTaskImage> getCloudPhoto(String basename) async {
    String fullPath = ph.join(getCloudPath(), basename);
    String thumbPath =
        ph.join(getCloudPath(), "thumbs", "thumb@256_" + basename);

    print(fullPath);
    print(thumbPath);

    final fb.StorageReference fullRef = userAuth
        .getStorage()
        .refFromURL("gs://tfsitescape.appspot.com")
        .child(fullPath);
    final fb.StorageReference thumbRef = userAuth
        .getStorage()
        .refFromURL("gs://tfsitescape.appspot.com")
        .child(thumbPath);

    final fb.DatabaseReference dbRef = userAuth
        .getDatabase()
        .refFromURL("gs://tfsitescape.firebaseio.com")
        .child("photos")
        .child(this.sector.subsite.site.name)
        .child(this.sector.subsite.name)
        .child(this.sector.name)
        .child(ph.basenameWithoutExtension(basename));

    List<dynamic> futures = await Future.wait([
      dbRef.once('value'),
      fullRef.getDownloadURL(),
      thumbRef.getDownloadURL()
    ]);

    fb.QueryEvent once = futures[0];
    Uri fullURL = futures[1];
    Uri thumbURL = futures[2];

    String key = once.snapshot.key;
    Map<dynamic, dynamic> data = once.snapshot.val();

    NetworkTaskImage cloudTaskImage = NetworkTaskImage.filename(
        this, basename, key, data, fullURL.toString(), thumbURL.toString());

    return cloudTaskImage;
  }

  Future<dynamic> acceptCloudPhoto(
      NetworkTaskImage netTask, String message) async {
    netTask.message = message;
    netTask.rejected = false;
    netTask.approved = true;

    return userAuth
        .getDatabase()
        .refFromURL("gs://tfsitescape.firebaseio.com")
        .child("photos")
        .child(this.sector.subsite.site.name)
        .child(this.sector.subsite.name)
        .child(this.sector.name)
        .child(
          ph.basenameWithoutExtension(
            ph.basenameWithoutExtension(netTask.fileName),
          ),
        )
        .update(
      {
        "rejected": false,
        "message": message,
        "approved": true,
      },
    );
  }

  Future<dynamic> rejectCloudPhoto(
      NetworkTaskImage netTask, String message) async {
    netTask.message = message;
    netTask.rejected = true;
    netTask.approved = false;

    fb.DatabaseReference tokensRef = userAuth
        .getDatabase()
        .refFromURL("gs://tfsitescape.firebaseio.com")
        .child("users")
        .child(netTask.uid)
        .child("tokens");

    fb.QueryEvent allTokens = await tokensRef.once('value');

    allTokens.snapshot.forEach((result) {
      sendNote(netTask, result.key);
    });

    return userAuth
        .getDatabase()
        .refFromURL("gs://tfsitescape.firebaseio.com")
        .child("photos")
        .child(this.sector.subsite.site.name)
        .child(this.sector.subsite.name)
        .child(this.sector.name)
        .child(
          ph.basenameWithoutExtension(
            ph.basenameWithoutExtension(netTask.fileName),
          ),
        )
        .update(
      {
        "rejected": true,
        "message": message,
        "approved": false,
      },
    );
  }

  Future<void> sendNote(NetworkTaskImage netTask, String token) async {
    String content = "A photo has been rejected. Review it under " +
        netTask.siteName +
        ", " +
        netTask.subName +
        ", " +
        netTask.secName +
        ".";
    String header = netTask.taskName + ": Photo Rejected";

    await http.post(
      'https://fcm.googleapis.com/fcm/send',
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization':
            'key=AAAAsStnRHY:APA91bHJPex4cOuzXD2N2-uGjZ9LE4GFEQmnw0RugQt8pI6G-_XRqxoEnENWOA9yBaYlG0QK4NnUAgCBaQp3GN0B1UQz2-CyrCIPQv4ayLPXYx9ABdQjSV3KgfEm6Y8Hy9OTrO6KO89W',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{'body': content, 'title': header},
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'sitename': netTask.siteName,
            'subname': netTask.subName,
            'secname': netTask.secName,
            'taskname': netTask.taskName,
          },
          'to': token,
        },
      ),
    );

    return;
  }
}

abstract class TaskImage {
  String siteName;
  String siteCode;
  String subName;
  String secName;
  String taskName;
  ImageProvider image;
  int count;
  String hash;
  bool isCloud;

  TaskImage(
    this.siteName,
    this.siteCode,
    this.subName,
    this.secName,
    this.taskName,
    this.image,
    this.count,
    this.hash,
    this.isCloud,
  );
}

class NetworkTaskImage implements TaskImage {
  String siteName;
  String siteCode;
  String subName;
  String secName;
  String taskName;
  ImageProvider image;
  ImageProvider fullImage;
  int count;
  String hash;
  bool isCloud;
  String fullURL;
  String thumbURL;
  String fileName;
  bool rejected;
  bool approved;
  String message;
  String uid;

  NetworkTaskImage(
    this.siteName,
    this.siteCode,
    this.subName,
    this.secName,
    this.taskName,
    this.image,
    this.fullImage,
    this.count,
    this.hash,
    this.isCloud,
    this.fullURL,
    this.thumbURL,
    this.fileName,
    this.rejected,
    this.approved,
    this.message,
    this.uid,
  );

  /* From a UserSelection object providing names/codes, a file to work with
     and a cryptographic hash, create a TaskImage.

     NOTE: May need refactoring and unification under UserSelection as
     having these separate may be redundant. Point is, the constructor
     is from two things which are separately obtained upon new file, but
     the two are very exclusively used and removed from one another.

     It may be unnecessary (though hash may need to be removed as an
     argument).

     This is just used for filename generation, after all.

     selection -> UserSelection: Holds names/codes for file details
     image -> File: Appropriate to hold file
     hash -> String: Cryptographic hash for filename creation
  */
  factory NetworkTaskImage.filename(
    Task task,
    String basename,
    String fileName,
    Map<dynamic, dynamic> data,
    String finalURL,
    String thumbURL,
  ) {
    List<String> parts = basename.split("-");

    if (parts.length != 4) {
      return null;
    }

    String siteName = task.sector.subsite.site.name;
    String siteCode = task.sector.subsite.site.code;
    String subName = task.sector.subsite.name;
    String secName = task.sector.name;
    String taskName = task.name;
    int count = int.tryParse(parts[2]);
    String hash = parts[3];

    return NetworkTaskImage(
      siteName,
      siteCode,
      subName,
      secName,
      taskName,
      NetworkImage(thumbURL),
      NetworkImage(finalURL),
      count,
      hash,
      true,
      finalURL,
      thumbURL,
      fileName,
      data['rejected'] as bool,
      data['approved'] as bool,
      data['message'] as String,
      data['uid'] as String,
    );
  }

  String getBasename(bool isCloud) {
    return this.siteCode +
        "-" +
        this.taskName +
        "-" +
        this.count.toString().padLeft(3, "0") +
        "-" +
        this.hash;
  }

  String getFilePath() {
    return ph.join(cloudDir, siteName, subName, secName, getBasename(isCloud));
  }

  String getCloudPath() {
    return fullURL;
  }

  String getCloudThumbPath() {
    return thumbURL;
  }

  NetworkImage getFullImage() {
    return fullImage;
  }
}
