import "dart:ui";

import "package:flushbar/flushbar.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:get/get.dart";
import "package:lazy_load_scrollview/lazy_load_scrollview.dart";

import "package:tfsitescape/main.dart";
import "package:tfsitescape/pages/site.dart";
import 'package:tfsitescape/services/modal.dart';
import "package:tfsitescape/services/classes.dart";
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

  // Paginated list of sites for performance reasons
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
    // Show first 10 sites alphabetically
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
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/login.jpg'),
                colorFilter: new ColorFilter.mode(
                    Colors.black.withOpacity(0.2), BlendMode.dstATop),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Container(color: Colors.indigo.withOpacity(0.7)),
            ),
          ),
          LazyLoadScrollView(
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
                icon: Icon(Icons.help_outline),
                color: Colors.white,
                iconSize: 36,
                onPressed: () async {
                  _scaffoldKey.currentState.showSnackBar(
                    SnackBar(
                      content: Text("This feature is under construction."),
                      duration: Duration(milliseconds: 500),
                    ),
                  );
                }),
            GestureDetector(
              onTapDown: (TapDownDetails details) {
                showPopupMenu(context, details.globalPosition);
              },
              child: Icon(
                Icons.more_vert,
                color: Colors.white,
                size: 36,
              ),
            ),
          ],
        ),
        // shape: CircularNotchedRectangle(),
        elevation: 0,
        color: Colors.black.withOpacity(0.25),
      ),
    );
  }

  /* Auto focus on widget spawn, used for text filtering, on top below
     the back button */
  Widget showSearchBar() {
    return Card(
      child: Container(
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
              color: Colors.grey,
            ),
            hintText: "Search for site",
            hintStyle: TextStyle(
              color: Colors.grey,
              fontSize: 20,
              fontWeight: FontWeight.w300,
            ),
          ),
          style: TextStyle(color: Colors.black, fontSize: 20),
          // Must be valid entry
        ),
      ),
      elevation: 10,
      color: Colors.white.withOpacity(0.9),
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

  /* List of sites that can be scrolled through infinitely with pagination */
  Widget showSites() {
    if (sites.isEmpty) {
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
      height: 69,
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Colors.white),
      ),
    );
  }

  /* Site card which shows site name, code and network icon
     site -> Site: The site pertaining to the card */
  Widget showSiteCard(Site site) {
    return InkWell(
      child: new Card(
        elevation: 5,
        child: new Container(
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // Stretch the cards in horizontal axis
                  children: <Widget>[
                    new Text(
                      site.name.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    new Text(
                      site.code.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: new TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              new Row(
                mainAxisAlignment: MainAxisAlignment.end,
                // Stretch the cards in horizontal axis
                children: <Widget>[
                  ImageIcon(
                    site.getIconFromNetwork(),
                    color: Colors.black54,
                    size: 28,
                  ),
                  Text(" "),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.black54,
                  )
                ],
              ),
            ],
          ),
          padding: const EdgeInsets.all(15.0),
        ),
      ),
      onTap: () {
        Get.to(SitePage(site: site), transition: Transition.downToUp);
        SystemChannels.textInput.invokeMethod("TextInput.hide");
      },
    );
  }
}
