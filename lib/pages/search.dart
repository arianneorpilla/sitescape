import "dart:ui";

import "package:flushbar/flushbar.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import 'package:flutter_screenutil/flutter_screenutil.dart';
import "package:get/get.dart";
import "package:lazy_load_scrollview/lazy_load_scrollview.dart";

import "package:tfsitescape/main.dart";
import "package:tfsitescape/pages/site.dart";
import 'package:tfsitescape/services/modal.dart';
import 'package:tfsitescape/services/classes.dart';
import "package:tfsitescape/services/util.dart";

class SearchPage extends StatefulWidget {
  SearchPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new SearchPageState();
}

/* State for SearchPage */
class SearchPageState extends State<SearchPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  // 10 initially, and paginated per scroll
  static const int PAGE_SIZE = 10;

  // Paginated list of Sites for performance reasons
  List<Site> _paged;
  // Whether or not to show the loading circle
  bool _isLoading;

  // For search term, used for filtering
  String _search;
  // Initially 10, as per page size
  int _currentIndex;

  /* Called when scrolling past the bottommost site on the ListView */
  void loadMore() {
    if (_paged.isNotEmpty) {
      // Show the loading circle
      Future.delayed(Duration(milliseconds: 100)).then((onValue) {
        setState(() {
          _isLoading = true;
        });
      });
    }

    // After 2 seconds, load more to delay intensive infinite scrolling,
    // then expand the pagination
    Future.delayed(Duration(milliseconds: 2000)).then((onValue) {
      setState(() {
        _currentIndex += PAGE_SIZE;
        _paged = filterSitesByNameOrCode(_search, _currentIndex);
        _isLoading = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    // Show first 10 Sites alphabetically
    _search = "";
    _currentIndex = PAGE_SIZE;
    _paged = filterSitesByNameOrCode(_search, PAGE_SIZE);
    _isLoading = false;
  }

  /* If network error on refresh, show an error message on top */
  void offlineError() {
    Flushbar(
      title: "Error fetching site manifest from server.",
      message: "Please try again with a better connection. " +
          "If you already had a site manifest, you can " +
          "continue to use your current one until you " +
          "can request another.",
      duration: Duration(seconds: 5),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Colors.red[900],
      animationDuration: Duration(milliseconds: 500),
      icon: Icon(
        Icons.error,
        size: 36,
        color: Colors.white,
      ),
      shouldIconPulse: false,
    )..show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      extendBody: true,
      backgroundColor: Theme.of(context).primaryColor,
      body: Stack(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  width: 0,
                  color: Color.fromRGBO(84, 176, 159, 1.0),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(84, 176, 159, 1.0),
                    Theme.of(context).primaryColor,
                  ],
                ),
              ),
            ),
          ),
          LazyLoadScrollView(
            scrollOffset: (512.h).round(),
            onEndOfPage: () => loadMore(),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(16, 96, 16, 64),
              children: [
                // Search Bar
                showSearchBar(),
                showSites(),
                _isLoading ? showLoading() : Container()
                // siteDisplay(context, _search)
              ],
            ),
          ),
          showBackButton()
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        notchMargin: 12.0,
        shape: CircularNotchedRectangle(),
        child: Container(
          padding: EdgeInsets.only(left: 36, right: 36),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                  icon: ImageIcon(AssetImage("images/home/icon_help.png")),
                  color: Colors.white,
                  iconSize: 28,
                  onPressed: () async {
                    _scaffoldKey.currentState.showSnackBar(
                      SnackBar(
                        backgroundColor: Color.fromRGBO(84, 176, 159, 1.0),
                        content: Text(
                          "This feature is under construction.",
                          style: TextStyle(
                            fontSize: ScreenUtil().setSp(36),
                          ),
                        ),
                        duration: Duration(milliseconds: 200),
                      ),
                    );
                  }),
              GestureDetector(
                onTapDown: (TapDownDetails details) {
                  showPopupMenu(context, details.globalPosition);
                },
                child: ImageIcon(
                  AssetImage("images/home/icon_menu.png"),
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
        elevation: 0,
        color: Color.fromRGBO(51, 57, 104, 1),
      ),
    );
  }

  /* Auto focus on widget spawn, used for text filtering, on top below
     the back button */
  Widget showSearchBar() {
    return Container(
      margin: EdgeInsets.fromLTRB(
        16,
        ScreenUtil().setHeight(16),
        16,
        ScreenUtil().setHeight(16),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: TextField(
          onChanged: ((search) async {
            setState(() {
              _search = search;
              _currentIndex = PAGE_SIZE;
              _paged = filterSitesByNameOrCode(_search, PAGE_SIZE);
              _isLoading = false;
            });
          }),
          textCapitalization: TextCapitalization.none,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          cursorColor: Colors.grey,
          obscureText: false,
          showCursor: true,
          decoration: InputDecoration(
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.all(12.0),
            prefixIcon: Icon(
              Icons.search,
              size: ScreenUtil().setSp(48),
              color: Colors.grey,
            ),
            hintText: 'Search for site',
            hintStyle: TextStyle(
              color: Colors.grey,
              fontSize: ScreenUtil().setSp(42),
              fontWeight: FontWeight.w400,
            ),
          ),
          style: TextStyle(
            color: Colors.black,
            fontSize: ScreenUtil().setSp(42),
          ),
          // Must be valid entry
        ),
      ),
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
          color: Colors.black.withOpacity(0.25),
          child: Icon(
            Icons.arrow_back,
            size: 28,
            color: Colors.white,
          ),
          padding: EdgeInsets.all(0.1),
          shape: CircleBorder(),
          onPressed: () {
            Get.back();
          },
        ),
      ),
    );
  }

  /* List of Sites that can be scrolled through infinitely with pagination */
  Widget showSites() {
    if (gSites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height / 3),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
            SizedBox(height: 10),
            Text(
              "Fetching site data...",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 24),
            )
          ],
        ),
      );
    } else if (_paged.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height / 3),
            Icon(Icons.search, color: Colors.white70, size: 36),
            SizedBox(height: 10),
            Text(
              _search == "" ? "Enter a site name or code" : "No search results",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  fontSize: 24),
            )
          ],
        ),
      );
    } else {
      return Container(
        child: ListView.builder(
          shrinkWrap: true,
          primary: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _paged.length,
          itemBuilder: (BuildContext context, int index) {
            // Return a card only if the search term is found in name/code.
            return showSiteCard(_paged[index]);
          },
        ),
      );
    }
  }

  /* Loading circle for refresh status shown in center */
  Widget showLoading() {
    return Container(
      padding: EdgeInsets.all(15.0),
      height: 512.h,
      alignment: Alignment.center,
      child: Align(
        alignment: Alignment.topCenter,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      ),
    );
  }

  // return Container(
  //         decoration: BoxDecoration(
  //           color: Colors.white.withOpacity(0.9),
  //           boxShadow: [
  //             BoxShadow(
  //               color: Colors.black.withOpacity(0.2),
  //               spreadRadius: 1,
  //               blurRadius: 10,
  //               offset: Offset(0, 3), // changes position of shadow
  //             ),
  //           ],
  //         ),
  //         margin: EdgeInsets.fromLTRB(
  //           24,
  //           ScreenUtil().setHeight(16),
  //           24,
  //           ScreenUtil().setHeight(16),
  //         ),
  //         child: Material(
  //           color: Colors.transparent,
  //           child: InkWell(
  //             onTap: () {
  //               Get.to(SitePage(site: lastSite))
  //                   .then((onValue) => setState(() {}));
  //             },
  //             child: Stack(
  //               children: [
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.start,
  //                   children: [
  //                     (lastSite.getSiteThumbnail() != null)
  //                         ? lastSite.getSiteThumbnail()
  //                         : Container(
  //                             height: 96, width: 96, color: Colors.grey[400]),
  //                     Expanded(
  //                       child: Container(
  //                         margin: EdgeInsets.only(left: 16, right: 16),
  //                         child: Column(
  //                           mainAxisAlignment: MainAxisAlignment.start,
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             Text(
  //                               lastSite.name.toUpperCase(),
  //                               textAlign: TextAlign.start,
  //                               overflow: TextOverflow.ellipsis,
  //                               maxLines: 1,
  //                               style: TextStyle(
  //                                   fontSize: ScreenUtil().setSp(42),
  //                                   fontWeight: FontWeight.w600,
  //                                   color: Colors.black54),
  //                             ),
  //                             Text(
  //                               lastSite.code.toUpperCase(),
  //                               overflow: TextOverflow.ellipsis,
  //                               maxLines: 1,
  //                               textAlign: TextAlign.start,
  //                               style: TextStyle(
  //                                   fontSize: ScreenUtil().setSp(36),
  //                                   fontWeight: FontWeight.w400,
  //                                   color: Colors.black54),
  //                             )
  //                           ],
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 Positioned.fill(
  //                   child: Align(
  //                     alignment: Alignment.topRight,
  //                     child: Container(
  //                       child: Text(
  //                         " Last accessed site ",
  //                         textAlign: TextAlign.start,
  //                         style: TextStyle(
  //                           color: Colors.white,
  //                           fontSize: ScreenUtil().setSp(32),
  //                         ),
  //                       ),
  //                       padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
  //                       color: Color.fromRGBO(84, 176, 159, 1.0),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );

  /* Site card which shows site name, code and network icon
     site -> Site: The site pertaining to the card */
  Widget showSiteCard(Site site) {
    return Container(
      margin: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.to(SitePage(site: site), transition: Transition.downToUp);
            SystemChannels.textInput.invokeMethod("TextInput.hide");
          },
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // Stretch the cards in horizontal axis
                    children: <Widget>[
                      Text(
                        site.name.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: ScreenUtil().setSp(42),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        site.code.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: ScreenUtil().setSp(36),
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  // Stretch the cards in horizontal axis
                  children: <Widget>[
                    ImageIcon(
                      site.getIconFromNetwork(),
                      color: Colors.black54,
                      size: ScreenUtil().setSp(64),
                    ),
                    Text(" "),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.black54,
                      size: ScreenUtil().setSp(42),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
