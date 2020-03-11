import 'package:flutter_manager/logic/app.dart';
import 'package:flutter_manager/logic/pub_dependencies.dart';
import 'package:flutter_manager/widget_library/widget_library_view.dart';
import 'package:flutter_managed/locator.dart';

abstract class PubDependency {

  final WidgetView widgetView;

  PubDependency(this.widgetView);

  String serialize();

  static PubDependency fromJson(Map<String, dynamic> json) {
    return allDependencies[json['name']];
  }
}

class GitPubDependency extends PubDependency {

  final String name;
  final String url;

  GitPubDependency(this.name, this.url, { WidgetView widgetView }) : super(widgetView);

  @override
  String serialize() {
    return '''
  $name:
    git:
      url: $url''';
  }

  Map<String, dynamic> toJson() => <String, dynamic> {
    'name': name
  };
}