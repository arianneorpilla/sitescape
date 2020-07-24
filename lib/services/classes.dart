import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as ph;
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:tfsitescape/main.dart';
import 'package:tfsitescape/pages/site.dart';
import 'package:tfsitescape/services/cloud.dart';
import 'package:tfsitescape/services/util.dart';

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
  factory Site.fromMap(String key, Map<dynamic, dynamic> value) {
    // Convert GPS values to double, as JSON has no concept of int/double
    double latitude = value["latitude"].toDouble();
    double longitude = value["longitude"].toDouble();

    return Site(
      key,
      value["sitename"],
      value["address"],
      value["build"],
      value["network"],
      latitude,
      longitude,
      value["subsites"],
    );
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

  Future<List<SiteNote>> getIssues() async {
    DatabaseReference issueRef =
        FirebaseDatabase.instance.reference().child("issues/" + this.code);

    DataSnapshot issues = await issueRef.once();

    if (issues.value == null) {
      return null;
    }

    return snapshotToNotes(issues.value);
  }

  // Future updateTaskInfo() async {
  //   DatabaseReference siteRef = FirebaseDatabase.instance.reference().child(
  //         ph.join("photos", name),
  //       );

  //   DataSnapshot siteInfo = await siteRef.once();
  //   Map<dynamic, dynamic> siteMap = siteInfo.value;

  //   if (siteMap == null) return;

  //   for (Subsite sub in this.subsites) {
  //     Map<dynamic, dynamic> subMap = siteMap[sub.name];
  //     if (subMap == null) continue;

  //     for (Sector sec in sub.sectors) {
  //       Map<dynamic, dynamic> secMap = subMap[sec.name];
  //       if (secMap == null) continue;

  //       print(secMap);
  //       secMap.forEach((key, values) {
  //         TaskInfo info = TaskInfo.fromMap(key, values);

  //         Task task = sec.tasks.firstWhere((task) => info.taskname == task.name,
  //             orElse: () => null);

  //         if (task != null) {
  //           task.info = info;

  //           if (task.info.notRequired) {
  //             print("fuck");
  //             try {
  //               String notRequiredCloudPath = ph.join(
  //                     extDir.path,
  //                     task.sector.subsite.site.name,
  //                     task.sector.subsite.name,
  //                     task.sector.name,
  //                   ) +
  //                   "/." +
  //                   task.name +
  //                   ".notrequired";
  //               print(notRequiredCloudPath);

  //               File(notRequiredCloudPath).createSync(recursive: true);
  //             } catch (e) {
  //               print(e);
  //             }
  //           }
  //         }
  //       });
  //     }
  //   }
  // }

  Future addIssue(SiteNote note) async {
    DatabaseReference issueRef =
        FirebaseDatabase.instance.reference().child("issues/" + this.code);

    issueRef.update(note.getDatabaseNote());
  }

  Image getSiteThumbnail() {
    for (Subsite sub in this.subsites) {
      for (Sector sec in sub.sectors) {
        for (Task task in sec.tasks) {
          TaskImage thumb = task.getTaskThumbnail();
          if (thumb != null) {
            return Image(
              image: thumb.image,
              height: 64,
              width: 64,
              fit: BoxFit.fill,
            );
          }
        }
      }
    }

    return null;
  }

  /* From the site's network String value, get the appropriate AssetImage.
     Called in Search and Site pages
  */
  AssetImage getIconFromNetwork() {
    switch (this.network.toLowerCase()) {
      case "telstra":
        return AssetImage("images/telstra.png");
      case "optus":
        return AssetImage("images/optus.png");
      case "nbn":
        return AssetImage("images/nbn.png");
      case "vodafone":
        return AssetImage("images/vodafone.png");
      case "tpg":
        return AssetImage("images/tpg.png");
      default:
        return null;
    }
  }

  /* Get the directory relevant to a user selection, as the app stores images
     with the following folder structure appropriate to a user's selection:

     /External Directory/Site Name/Subsite Name/Sector Name/Images Are Here
  */
  Directory getDirectory() {
    return Directory(
      ph.join(
        extDir.path,
        this.name,
      ),
    );
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

  sitesJson.forEach((key, value) {
    Site site = Site.fromMap(key, value);
    site.populate();

    sites.add(site);
  });

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
    return Subsite(key, value["sectors"]);
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

  /* Get the directory relevant to a user selection, as the app stores images
     with the following folder structure appropriate to a user's selection:

     /External Directory/Site Name/Subsite Name/Sector Name/Images Are Here
  */
  Directory getDirectory() {
    return Directory(
      ph.join(
        extDir.path,
        site.name,
        this.name,
      ),
    );
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
  GlobalKey<SectorCardState> key;
  bool downloading;
  bool uploading;

  bool inTransaction() {
    return (downloading || uploading);
  }

  Sector(
    this.name,
    this.maps,
    this.key,
    this.downloading,
    this.uploading,
  );

  /* Used after decode to get a Sector from a JSON string. 
     Called recursively from Subsite.fromMap() 
     
     key -> String: A primary key from a JSON map, this is the sector name
     value -> Map<dynamic, dynamic>: A JSON map containing sector data
  */
  factory Sector.fromMap(String key, Map<dynamic, dynamic> value) {
    return Sector(
      key,
      value["tasks"],
      GlobalKey(),
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

  /* Get the directory relevant to a user selection, as the app stores images
     with the following folder structure appropriate to a user's selection:

     /External Directory/Site Name/Subsite Name/Sector Name/Images Are Here
  */
  Directory getDirectory() {
    return Directory(
      ph.join(
        extDir.path,
        subsite.site.name,
        subsite.name,
        this.name,
      ),
    );
  }

  String getCloudPath() {
    return ph.join(
      cloudDir,
      subsite.site.name,
      subsite.name,
      this.name,
    );
  }

  /* Get a sector's progress as a value between 0.0 to 1.0, useful for
     progress bars, by calling and iterating on every task's progress
     and checking if they have images. */
  double getSectorProgress() {
    int numTasks = this.tasks.length;
    List<Task> tasks = this.tasks;

    int doneCount = 0;

    for (int i = 0; i < numTasks; i++) {
      switch (tasks[i].getTaskProgress()) {
        case TaskStatus.NOT_STARTED:
        case TaskStatus.INVALID:
          break;
        case TaskStatus.DONE_NOT_SYNCED:
        case TaskStatus.DONE_SYNCED:
        case TaskStatus.NOT_REQUIRED:
          doneCount += 1;
          break;
      }
    }

    return (doneCount / numTasks);
  }

  /* Get a sector's progress color, yellow if there are items not synced or
     there are no images -- except for the Not Required case.
     
     Green if all okay and images are synced to cloud (no -L.png files). */
  Color getSectorProgressColor() {
    List<TaskImage> images = getLocalPhotos();

    if (getSectorProgress() != 1.0) {
      return Colors.yellow[700];
    }

    for (TaskImage taskImage in images) {
      if (!taskImage.isCloud) {
        return Colors.yellow[700];
      }
    }

    return Colors.greenAccent[700];
  }

  /* Get all photos as a list of TaskImage objects, given the appropriate
     directory from getDirectory(), appropriate to the user selection. 

     {taskSpecific -> bool}: If true, sector-wide, otherwise task-wide check.
  */
  List<FileTaskImage> getLocalPhotos({Task task}) {
    List<FileTaskImage> photos = [];

    try {
      // Get all the files in the appropriate directory, filter by filenames.
      List<FileSystemEntity> entries =
          getDirectory().listSync(recursive: true).toList();

      for (var i in entries) {
        String filePath = i.path;

        if (ph.extension(filePath) != ".jpg" &&
            ph.extension(filePath) != ".png") {
          continue;
        }

        // Parse the file's name and split up by delimiter (-)
        List<String> parts = ph.basenameWithoutExtension(filePath).split("-");

        // Disregard file if site code mismatch
        if (parts[0] != subsite.site.code) {
          continue;
        }

        // Disregard if task name mismatch if task-specific
        String taskName = parts[1];
        if (task != null && taskName != task.name) {
          continue;
        }

        // Add the photo into the list if all is well
        if (FileTaskImage.file(i) != null) {
          photos.add(FileTaskImage.file(i));
        }
      }
    } catch (e) {
      // Will print out if directory does not exist.
      // print(e);
      // print("Directory may not exist.");
      return [];
    }

    // Sort the photos so that the highest count comes up first.
    photos.sort((a, b) => b.count.compareTo(a.count));
    return photos;
  }

  /* Check if a task has been synced by checking if it ends with the local
     indicator "-L" meaning it has not yet been uploaded. */
  int getUnsyncedPhotos({Task task}) {
    List<TaskImage> allPhotos = getLocalPhotos(task: task);

    int unsyncCount = 0;

    for (int i = 0; i < allPhotos.length; i++) {
      if (allPhotos[i] is FileTaskImage) {
        FileTaskImage fileTask = allPhotos[i];
        String imageFilePath = fileTask.imageFile.path;
        if (ph.basename(imageFilePath).endsWith("-L.png")) {
          unsyncCount += 1;
        }
      }
    }

    return unsyncCount;
  }

  bool getUnsynced({Task task}) {
    // try {
    //   List<FileSystemEntity> entries =
    //       getDirectory().listSync(recursive: true).toList();

    //   for (var i in entries) {
    //     String filePath = i.path;

    //     if (ph.extension(filePath) == ".notrequired-L") {
    //       return true;
    //     }
    //   }
    // } catch (e) {}

    if (getUnsyncedPhotos() != 0) {
      return true;
    }

    return false;
  }

  Future<List<dynamic>> getSectorCloudThumbnails() async {
    var thumbs = [];

    List<dynamic> fileNames = await getPhotosInCloudFolder(getCloudPath());

    for (Task task in tasks) {
      bool found = false;

      for (String basename in fileNames) {
        List<String> parts = ph.basenameWithoutExtension(basename).split("-");
        if (task.name == parts[1]) {
          thumbs.add(task.getCloudPhoto(basename));
          found = true;
          break;
        }
      }
      if (!found) {
        thumbs.add(null);
      }
    }

    return thumbs;
  }

  Future<List<int>> getSectorCloudProgress() async {
    List<int> secProgress = [];

    List<dynamic> fileNames = await getPhotosInCloudFolder(getCloudPath());

    for (Task task in tasks) {
      int taskImageCount = 0;

      for (String basename in fileNames) {
        List<String> parts = ph.basenameWithoutExtension(basename).split("-");

        if (task.name == parts[1]) {
          taskImageCount += 1;
        }
      }

      secProgress.add(taskImageCount);
    }

    return secProgress;
  }

  double getSectorProgressUpdate(List<int> local, List<int> cloud) {
    int count = 0;

    for (int i = 0; i < tasks.length; i++) {
      bool localOrCloud = local[i] > 0 || cloud[i] > 0;

      if (localOrCloud ||
          tasks[i].getTaskProgress() == TaskStatus.NOT_REQUIRED) {
        count += 1;
      }
    }

    // print(count / tasks.length);

    return count / tasks.length;
  }

  List<int> getSectorLocalProgress() {
    List<int> secProgress = [];

    for (Task task in tasks) {
      List<TaskImage> localPhotos = getLocalPhotos(task: task);
      secProgress.add(localPhotos.length);
    }

    return secProgress;
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

  /* Get the directory relevant to a user selection, as the app stores images
     with the following folder structure appropriate to a user's selection:

     /External Directory/Site Name/Subsite Name/Sector Name/Images Are Here
  */
  Directory getDirectory() {
    return sector.getDirectory();
  }

  String getCloudPath() {
    return sector.getCloudPath();
  }

  /* Given the user's selection, return the next appropriate sequential
     number to be applied to the next file,

     i.e., If a user has 000 and 001 stored, the next should be 002.
           We get the next after the highest regardless if there's anything
           missing in between.
  */
  int getNextCount() {
    // Iterate on all the photos and get the maximum count.
    List<TaskImage> allPhotos = getLocalPhotos();

    int maxCount = -1;
    for (int i = 0; i < allPhotos.length; i++) {
      if (allPhotos[i].count > maxCount) {
        maxCount = allPhotos[i].count;
      }
    }

    // If overflow, the image will always have a sequential
    // count of 1. The hash should suffice in cases to handle
    // instances where there are file naming conflicts.
    if (maxCount >= 9999 || maxCount <= -1) {
      return 0;
    } else {
      return maxCount + 1;
    }
  }

  /* Return the photo with the highest count as a thumbnail. Used in 
     Sector page. */
  TaskImage getTaskThumbnail() {
    List<TaskImage> allPhotos = getLocalPhotos();

    if (allPhotos.length == null) {
      return null;
    }

    TaskImage thumbnail;
    int maxCount = -1;
    for (int i = 0; i < allPhotos.length; i++) {
      if (allPhotos[i].count > maxCount) {
        maxCount = allPhotos[i].count;
        thumbnail = allPhotos[i];
      }
    }

    return thumbnail;
  }

  /* Given a task (as there are instances when an object's UserSelection is
     null and needs to iterate on all the tasks while having access to 
     site and subsite data logically), get the number of images it has.

     Used for photo count on the Task page.

     task -> Task: The task to check for image count
  */
  int getTaskImageCount() {
    List<TaskImage> allPhotos = getLocalPhotos();
    return allPhotos.length;
  }

  /* Given a task (as there are instances when an object's UserSelection is
     null and needs to iterate on all the tasks while having access to 
     site and subsite data logically), get its current progress.

     Used for progress checking on the Sector page.

     task -> Task: The task to check for progress status
  */
  TaskStatus getTaskProgress() {
    String notRequiredPath = getDirectory().path + "/." + name + ".notrequired";

    if (getTaskImageCount() >= 1 && sector.getUnsyncedPhotos(task: this) != 0) {
      return TaskStatus.DONE_NOT_SYNCED;
    } else if (getTaskImageCount() >= 1 &&
        sector.getUnsyncedPhotos(task: this) == 0) {
      return TaskStatus.DONE_SYNCED;
    } else if (getTaskImageCount() == 0 && File(notRequiredPath).existsSync()) {
      return TaskStatus.NOT_REQUIRED;
    } else if (getTaskImageCount() == 0) {
      return TaskStatus.NOT_STARTED;
    } else {
      return TaskStatus.INVALID;
    }
  }

  /* Add the .notrequired file in the Sector directory with the task name
     to indicate that the app should read the Task as not required. */
  void setTaskNotRequired() {
    String notRequiredPath =
        getDirectory().path + "/." + this.name + ".notrequired";
    File(notRequiredPath).createSync(recursive: true);
  }

  /* Delete the .notrequired file in the Sector directory with the task name
     to indicate that the app should read the Task as required. */
  void undoTaskNotRequired() {
    String notRequiredPath =
        getDirectory().path + "/." + this.name + ".notrequired";
    File notRequiredCloud = File(notRequiredPath);

    if (notRequiredCloud.existsSync()) {
      notRequiredCloud.deleteSync(recursive: false);
    }

    // String notRequiredLocalPath =
    //     getDirectory().path + "/." + this.name + ".notrequired-L";
    // File notRequiredLocal = File(notRequiredLocalPath);

    // if (notRequiredLocal.existsSync()) {
    //   notRequiredLocal.deleteSync(recursive: false);
    // }
  }

  Future<List<Future<NetworkTaskImage>>> getCloudPhotos({Task task}) async {
    List<dynamic> filenames = await getPhotosInCloudFolder(getCloudPath());

    List<Future<NetworkTaskImage>> futures = [];

    for (String basename in filenames) {
      List<String> parts = ph.basenameWithoutExtension(basename).split("-");
      if (task == null || task.name == parts[1]) {
        // print(basename);
        futures.add(getCloudPhoto(basename));
      }
    }

    return futures;
  }

  Future<NetworkTaskImage> getCloudPhoto(String basename) async {
    String fullPath = ph.join(getCloudPath(), basename);
    String thumbPath =
        ph.join(getCloudPath(), "thumbs", "thumb@256_" + basename);

    final StorageReference fullRef =
        FirebaseStorage.instance.ref().child(fullPath);
    final StorageReference thumbRef =
        FirebaseStorage.instance.ref().child(thumbPath);

    final DatabaseReference dbRef = FirebaseDatabase.instance
        .reference()
        .child("photos")
        .child(this.sector.subsite.site.name)
        .child(this.sector.subsite.name)
        .child(this.sector.name)
        .child(ph.basenameWithoutExtension(basename));

    List<dynamic> futures = await Future.wait(
        [dbRef.once(), fullRef.getDownloadURL(), thumbRef.getDownloadURL()]);

    DataSnapshot dbSnapshot = futures[0];
    String fullURL = futures[1];
    String thumbURL = futures[2];

    Map<dynamic, dynamic> data = dbSnapshot.value;

    NetworkTaskImage cloudTaskImage =
        NetworkTaskImage.filename(this, basename, data, fullURL, thumbURL);

    return cloudTaskImage;
  }

  /* Get all photos as a list of TaskImage objects, given the appropriate
     directory from getDirectory(), appropriate to the user selection. 

     {taskSpecific -> bool}: If true, sector-wide, otherwise task-wide check.
  */
  List<FileTaskImage> getLocalPhotos() {
    List<FileTaskImage> photos = [];

    try {
      // Get all the files in the appropriate directory, filter by filenames.
      List<FileSystemEntity> entries =
          getDirectory().listSync(recursive: true).toList();

      for (var i in entries) {
        String filePath = i.path;

        if (ph.extension(filePath) != ".jpg" &&
            ph.extension(filePath) != ".png") {
          continue;
        }

        // Parse the file's name and split up by delimiter (-)
        List<String> parts = ph.basenameWithoutExtension(filePath).split("-");

        // Disregard file if site code mismatch
        if (parts[0] != sector.subsite.site.code) {
          continue;
        }

        // Disregard if task name mismatch if task-specific
        String taskName = parts[1];
        if (taskName != this.name) {
          continue;
        }

        // Add the photo into the list if all is well
        if (FileTaskImage.file(i) != null) {
          photos.add(FileTaskImage.file(i));
        }
      }
    } catch (e) {
      // Will print out if directory does not exist.
      // print(e);
      // print("Directory may not exist.");
      return [];
    }

    // Sort the photos so that the highest count comes up first.
    photos.sort((a, b) => b.count.compareTo(a.count));
    return photos;
  }
}

/* Used to structure task current status. */
enum TaskStatus {
  NOT_STARTED,
  NOT_REQUIRED,
  DONE_NOT_SYNCED,
  DONE_SYNCED,
  INVALID
}

/* From an image file, we need to be able to tell assign its filename to
   metadata and tell the app how to read it. This class is for organising
   and deciding filenames given certain parameters.

   siteName -> String: Name of site from folder name
   siteCode -> String: Code of site from image name
   subName -> String: Name of subsite from folder name
   secName -> String: Name of sector from folder name
   taskName -> String: Name of task from image name
   count -> int: Sequential count of the image for alphabetical sort in filesys
   hash -> String: Cryptographic hash to prevent filename collisions in cloud
   isCloud -> bool: Whether or not photo ends with "-L" to check sync status
*/

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

class FileTaskImage implements TaskImage {
  String siteName;
  String siteCode;
  String subName;
  String secName;
  String taskName;
  ImageProvider image;
  int count;
  String hash;
  bool isCloud;
  File imageFile;

  FileTaskImage(
    this.siteName,
    this.siteCode,
    this.subName,
    this.secName,
    this.taskName,
    this.image,
    this.count,
    this.hash,
    this.isCloud,
    this.imageFile,
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
  factory FileTaskImage.create(Task task, File file) {
    String siteName = task.sector.subsite.site.name;
    String siteCode = task.sector.subsite.site.code;
    String subName = task.sector.subsite.name;
    String secName = task.sector.name;
    String taskName = task.name;

    return FileTaskImage(
      siteName,
      siteCode,
      subName,
      secName,
      taskName,
      FileImage(file),
      task.getNextCount(),
      generateFileHash(file).substring(0, 8),
      false,
      file,
    );
  }

  /* From a file, parse the appropriate data from it given its filename.

     file -> File: The file to take path from.
  */
  factory FileTaskImage.file(File file) {
    String pathText = file.path.toString();

    if (ph.extension(pathText) != ".jpg" && ph.extension(pathText) != ".png") {
      return null;
    }

    String basename = ph.basenameWithoutExtension(pathText);
    List<String> parts = basename.split("-");

    bool isCloud;

    if (parts.length == 4) {
      isCloud = true;
    } else if (parts.length == 5 && parts[4] == "L") {
      isCloud = false;
    } else {
      return null;
    }

    String siteName = ph.basename(ph.dirname(ph.dirname(ph.dirname(pathText))));
    String siteCode = parts[0];
    String subName = ph.basename(ph.dirname(ph.dirname(pathText)));
    String secName = ph.basename(ph.dirname(pathText));
    String taskName = parts[1];
    int count = int.tryParse(parts[2]);
    String hash = parts[3];

    return FileTaskImage(
      siteName,
      siteCode,
      subName,
      secName,
      taskName,
      FileImage(file),
      count,
      hash,
      isCloud,
      file,
    );
  }

  String getCloudPath() {
    return ph.join(cloudDir, siteName, subName, secName, getBasename(true));
  }

  String getCloudThumbPath() {
    return ph.join(cloudThumbDir, siteName, subName, secName, "thumbs",
        "thumb@256_" + getBasename(true));
  }

  String getBasename(bool isCloud) {
    String cloudSuffix;

    if (isCloud) {
      cloudSuffix = ".jpg";
    } else {
      cloudSuffix = "-L.png";
    }

    return this.siteCode +
        "-" +
        this.taskName +
        "-" +
        this.count.toString().padLeft(3, "0") +
        "-" +
        this.hash +
        cloudSuffix;
  }

  String getFilePath() {
    return ph.join(
        extDir.path, siteName, subName, secName, getBasename(isCloud));
  }
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

class SiteNote {
  final String hash;
  final String contents;
  final int reportTime;
  bool resolved;
  int resolveTime;

  SiteNote(
    this.hash,
    this.contents,
    this.reportTime,
    this.resolved,
    this.resolveTime,
  );

  Map<String, dynamic> getDatabaseNote() {
    return {
      this.hash: {
        "contents": this.contents,
        "reportTime": this.reportTime,
        "resolved": this.resolved,
        "resolveTime": this.resolveTime,
      }
    };
  }

  String getTimeString(int ms) {
    DateTime dt = DateTime.fromMillisecondsSinceEpoch(ms);
    String timeString = DateFormat('yyyy-MM-dd kk:mm:ss').format(dt);

    return timeString;
  }

  factory SiteNote.create(String contents, int ms) {
    return SiteNote(
      generateStringHash(contents) + "_" + ms.toString(),
      contents,
      ms,
      false,
      ms,
    );
  }

  factory SiteNote.fromJson(String key, Map<dynamic, dynamic> value) {
    return SiteNote(
      key,
      value['contents'] as String,
      value['reportTime'] as int,
      value['resolved'] as bool,
      value['resolveTime'] as int,
    );
  }
}

List<SiteNote> snapshotToNotes(Map<dynamic, dynamic> snapshot) {
  List<SiteNote> notes = [];

  snapshot.forEach((key, values) {
    SiteNote note = SiteNote.fromJson(key, values);
    notes.add(note);
  });

  notes.sort((a, b) => b.reportTime.compareTo(a.reportTime));

  return notes;
}

class PhotoInfo {
  String basename;
  String message;
  bool approved;
  bool rejected;

  PhotoInfo(
    this.basename,
    this.message,
    this.approved,
    this.rejected,
  );

  factory PhotoInfo.fromMap(String key, Map<dynamic, dynamic> value) {
    return PhotoInfo(
      key,
      value['message'] as String ?? "",
      value['approved'] as bool ?? false,
      value['rejected'] as bool ?? false,
    );
  }
}
