import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:firebase/firebase.dart' as fb;
import 'package:tfsitescapeweb/main.dart';

import 'package:tfsitescapeweb/services/classes.dart';

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
  var base64Str = base64UrlEncode(hash.bytes).replaceAll("-", ".");

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

/* Refreshes site data and saves the new data in the local cache for offline
   use. Offline callback is called if there is no internet available to
   trigger a message from the current context. 
   
   {offlineCallback -> void}: Calls when internet is unavailable
*/
Future<List<Site>> fetchSites() async {
  List<Site> sites = [];

  fb.DatabaseReference sitesRef = userAuth
      .getDatabase()
      .refFromURL("gs://tfsitescape.firebaseio.com")
      .child("sites");

  fb.QueryEvent allSites = await sitesRef.once('value');

  allSites.snapshot.forEach((result) {
    Map<dynamic, dynamic> value = result.val();
    print(value);
    Site site = Site.fromMap(result.key, value);
    site.populate();
    sites.add(site);
  });

  sites.sort((a, b) => a.name.compareTo(b.name));

  return sites;
}

/* Uses Fuzzy string searching to filter sites in search properly. Limit
   is used to limit the search results for performance.
   
   searchTerm -> String: String to use for a filter
   limit -> int: The max number of sites to return */
List<Site> filterSitesByNameOrCode(
    List<Site> sites, String searchTerm, int limit) {
  // If the search term is blank, return the sites in alphabetical order
  // as already sorted
  if (searchTerm == "") {
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
