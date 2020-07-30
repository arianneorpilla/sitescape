import 'package:flutter/material.dart';

/* A class providing paged scrolling functionality with tab headers.
   Used in the Site page to pretty up SubSites and Sectors display.
   
   int -> itemCount: Number of tabs/pages to build
   tabBuilder -> IndexedWidgetBuilder: Used to iteratively generate tabs
   pageBuilder -> IndexedWidgetBuilder: Used to iteratively generate pages
   stub -> Widget: Build if itemCount < 0
   onPositionChange -> ValueChanged<int>: Called when tab/page switch
   onScroll -> ValueChanged<double>: Called when scrolling on widget
   initPosition -> int: Initial page/tab on build
   backgroundColor -> Color: Used as this widget is used for multiple screens
*/
class CustomTabView extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder tabBuilder;
  final IndexedWidgetBuilder pageBuilder;
  final Widget stub;
  final ValueChanged<int> onPositionChange;
  final ValueChanged<double> onScroll;
  final int initPosition;
  final Color backgroundColor;
  final Alignment alignment;

  CustomTabView(
      {Key key,
      @required this.itemCount,
      @required this.tabBuilder,
      @required this.pageBuilder,
      this.stub,
      this.onPositionChange,
      this.onScroll,
      this.initPosition,
      this.backgroundColor,
      this.alignment})
      : super(key: key);

  @override
  CustomTabsState createState() => CustomTabsState();
}

/* State for CustomTabView */
class CustomTabsState extends State<CustomTabView>
    with TickerProviderStateMixin {
  TabController _controller;
  int _currentCount;
  int _currentPosition;
  bool _scrollable;

  void animateTo(int position) {
    _controller.animateTo(position);
  }

  void toggleScrollable() {
    _scrollable = !_scrollable;
  }

  int getCurrentPosition() {
    return _currentPosition;
  }

  @override
  void initState() {
    _currentPosition = widget.initPosition ?? 0;
    _controller = TabController(
      length: widget.itemCount,
      vsync: this,
      initialIndex: _currentPosition,
    );
    _controller.addListener(onPositionChange);
    _controller.animation.addListener(onScroll);
    _currentCount = widget.itemCount;
    _scrollable = true;
    super.initState();
  }

  @override
  void didUpdateWidget(CustomTabView oldWidget) {
    if (_currentCount != widget.itemCount) {
      _controller.animation.removeListener(onScroll);
      _controller.removeListener(onPositionChange);
      _controller.dispose();

      if (widget.initPosition != null) {
        _currentPosition = widget.initPosition;
      }

      if (_currentPosition > widget.itemCount - 1) {
        _currentPosition = widget.itemCount - 1;
        _currentPosition = _currentPosition < 0 ? 0 : _currentPosition;
        if (widget.onPositionChange is ValueChanged<int>) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onPositionChange(_currentPosition);
            }
          });
        }
      }

      _currentCount = widget.itemCount;
      setState(() {
        _controller = TabController(
          length: widget.itemCount,
          vsync: this,
          initialIndex: _currentPosition,
        );
        _controller.addListener(onPositionChange);
        _controller.animation.addListener(onScroll);
      });
    }
    // } else if (widget.initPosition != null) {

    // }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.animation.removeListener(onScroll);
    _controller.removeListener(onPositionChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount < 1) return widget.stub ?? Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          color: widget.backgroundColor,
          alignment: widget.alignment,
          child: _scrollable
              ? TabBar(
                  isScrollable: true,
                  controller: _controller,
                  labelColor: Theme.of(context).accentColor,
                  unselectedLabelColor: Theme.of(context).hintColor,
                  indicator: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).accentColor,
                        width: 2,
                      ),
                    ),
                  ),
                  tabs: List.generate(
                    widget.itemCount,
                    (index) => widget.tabBuilder(context, index),
                  ),
                )
              : IgnorePointer(
                  child: TabBar(
                    isScrollable: true,
                    controller: _controller,
                    labelColor: Theme.of(context).accentColor,
                    unselectedLabelColor: Theme.of(context).hintColor,
                    indicator: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).accentColor,
                          width: 2,
                        ),
                      ),
                    ),
                    tabs: List.generate(
                      widget.itemCount,
                      (index) => widget.tabBuilder(context, index),
                    ),
                  ),
                ),
        ),
        Expanded(
          child: TabBarView(
            physics: _scrollable
                ? AlwaysScrollableScrollPhysics()
                : NeverScrollableScrollPhysics(),
            controller: _controller,
            children: List.generate(
              widget.itemCount,
              (index) => widget.pageBuilder(context, index),
            ),
          ),
        ),
      ],
    );
  }

  onPositionChange() {
    if (!_controller.indexIsChanging) {
      _currentPosition = _controller.index;
      if (widget.onPositionChange is ValueChanged<int>) {
        widget.onPositionChange(_currentPosition);
      }
    }
  }

  onScroll() {
    if (widget.onScroll is ValueChanged<double>) {
      widget.onScroll(_controller.animation.value);
    }
  }
}
