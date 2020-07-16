import 'dart:convert';
import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  final List<Subsite> subsites;

  Site(
    this.code,
    this.name,
    this.address,
    this.build,
    this.network,
    this.latitude,
    this.longitude,
    this.maps,
    this.subsites,
  );

  /* Used after decode to get a Site from JSON key-value String pairs.
  
     key -> String: A primary key from a JSON map, this is the code
     value -> Map<dynamic, dynamic>: A JSON map containing site data
  */
  factory Site.fromJson(String key, Map<dynamic, dynamic> value) {
    // Convert GPS values to double, as JSON has no concept of int/double
    double latitude = value["latitude"].toDouble();
    double longitude = value["longitude"].toDouble();

    // Call the Subsite factory on the 'subsites' parameter
    List<Subsite> subs = [];
    Map<dynamic, dynamic> maps = value["subsites"];
    maps.forEach((k, v) => subs.add(Subsite.fromMap(k, v)));
    // Sort the subsites by alphabetical order
    subs.sort((a, b) => a.name.compareTo(b.name));

    return Site(
      key,
      value["sitename"],
      value["address"],
      value["build"],
      value["network"],
      latitude,
      longitude,
      value["subsites"],
      subs,
    );
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
      [],
    );
  }

  void updateCloudEntry() {
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
            task.name: {"note": task.note, "required": 0}
          });
        }
        sectorsMap.addAll({
          sec.name: {"tasks": tasksMap}
        });
      }
      subsitesMap.addAll({
        sub.name: {"sectors": sectorsMap}
      });
    }

    final firestoreInstance = Firestore.instance;
    firestoreInstance.collection("sites").document(this.code).delete();
    firestoreInstance.collection("sites").document(this.code).setData({
      "sitename": this.name,
      "address": this.address,
      "build": this.build,
      "network": this.network,
      "latitude": this.latitude,
      "longitude": this.longitude,
      "subsites": subsitesMap
    });
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

  sitesJson.forEach((key, value) => sites.add(Site.fromJson(key, value)));

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
    Site site = Site.fromJson(key, values);
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
  final List<Sector> sectors;

  Subsite(
    this.name,
    this.maps,
    this.sectors,
  );

  /* Used after decode to get a Subsite from a JSON string. 
     Called recursively from Site.fromMap() 
     
     key -> String: A primary key from a JSON map, this is the subsite name
     value -> Map<dynamic, dynamic>: A JSON map containing subsite data
  */
  factory Subsite.fromMap(String key, Map<dynamic, dynamic> value) {
    List<Sector> secs = [];
    Map<dynamic, dynamic> maps = value["sectors"];
    maps.forEach((k, v) => secs.add(Sector.fromMap(k, v)));

    secs.sort((a, b) => a.name.compareTo(b.name));

    return Subsite(key, value["sectors"], secs);
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
  final List<Task> tasks;

  Sector(
    this.name,
    this.maps,
    this.tasks,
  );

  /* Used after decode to get a Sector from a JSON string. 
     Called recursively from Subsite.fromMap() 
     
     key -> String: A primary key from a JSON map, this is the sector name
     value -> Map<dynamic, dynamic>: A JSON map containing sector data
  */
  factory Sector.fromMap(String key, Map<dynamic, dynamic> value) {
    List<Task> tasks = [];
    Map<dynamic, dynamic> maps = value["tasks"];
    maps.forEach((k, v) => tasks.add(Task.fromMap(k, v)));

    tasks.sort((a, b) => a.name.compareTo(b.name));

    return Sector(key, value["tasks"], tasks);
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
}
