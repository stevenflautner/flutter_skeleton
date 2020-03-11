import 'package:flutter_manager/logic/app.dart';
import 'package:flutter_manager/logic/pub_dependencies.dart';
import 'package:flutter_manager/pub_dependency/pub_dependency.dart';
import 'package:flutter_manager/widget_library/widget_library_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_managed/locator.dart';

class WidgetLibrary extends ChangeNotifier {

  PubDependency _selected;

  void select(PubDependency dependency) {
    _selected = dependency;
    notifyListeners();
  }

  void add(PubDependency dependency) {
    get<Application>().addDependency(dependency);
    notifyListeners();
  }

  void remove(PubDependency dependency) {
    get<Application>().removeDependency(dependency);
    notifyListeners();
  }

  PubDependency get selected => _selected;

  List<PubDependency> get widgets =>
      get<Application>().dependencies.where((element) => element.widgetView != null).toList();

  List<PubDependency> get availableWidgets =>
      allDependencies.values.where((element) => element.widgetView != null
          && !get<Application>().dependencies.contains(element)).toList();

}