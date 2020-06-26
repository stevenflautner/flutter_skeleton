import 'package:flutter_manager/logic/app.dart';
import 'package:flutter_manager/logic/pub_dependencies.dart';
import 'package:flutter_manager/widget_library/widget_library_view.dart';
import 'package:flutter_skeleton/locator.dart';

abstract class PubDependency {

  final WidgetView widgetView;

  PubDependency(this.widgetView);

  String serialize();

  static PubDependency fromYaml(Map<String, dynamic> json) {
    return allDependencies[json['name']];
  }
  Map<String, dynamic> toYaml();
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

  Map<String, dynamic> toYaml() => <String, dynamic> {
    'name': name
  };
}