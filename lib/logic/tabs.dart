import 'package:flutter/cupertino.dart';

enum AppTab {
  ENTITIES,
  ATTRIBUTES,
  INTERCEPTORS,
  SERVICES,
  WIDGET_LIBRARY
}

class Tabs extends ChangeNotifier {

  AppTab _selected;

  void select(AppTab tab) {
    _selected = tab;
    notifyListeners();
  }

  AppTab get selected => _selected;
}