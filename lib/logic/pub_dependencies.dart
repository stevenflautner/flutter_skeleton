import 'package:flutter_manager/logic/app.dart';
import 'package:flutter_manager/pub_dependency/pub_dependency.dart';
import 'package:flutter_manager/widget_library/widget_library_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_managed/locator.dart';

final allDependencies = {
  'flutter_rest_api': GitPubDependency(
      'flutter_rest_api',
      'http://github.com/stevenflautner/flutter_rest_api.git',
      widgetView: ProgressButtonWidgetView()
  ),
};