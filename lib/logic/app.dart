import 'dart:convert';
import 'dart:io';
import 'package:flutter_manager/entities.dart';
import 'package:flutter_manager/logic/pub_dependencies.dart';
import 'package:flutter_manager/pub_dependency/pub_dependency.dart';
import 'package:flutter_manager/widget_library/widget_library_view.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';

const clientPath = '../client';
const serverPath = '../server';

class Application {

  final _path = dirname(Platform.script.toString());
  String _name;
  Data _data;

  final _defaultDependencies = <PubDependency>[
    GitPubDependency(
        'flutter_managed',
        'http://github.com/stevenflautner/flutter_managed.git'
    )
  ];

  Future<void> initialize() async {
    final split = _path.split('/');
    _name = split[split.length - 2];
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      final json = jsonDecode(await rootBundle.loadString('assets/data.json'));
      _data = Data.fromJson(json);
    } catch (e) {
      _data = Data({}, {}, []);
    }
  }

  Future<void> saveData() async {
    File('assets/data.json').writeAsStringSync(jsonEncode(_data.toJson()));
//    final json = jsonDecode(await rootBundle.loadString('assets/data.json'));
//    _data = Data.fromJson(json);
  }

  void addDependency(PubDependency dependency) {
    dependencies.add(dependency);
    saveData();
    writePubspec();
  }

  void removeDependency(PubDependency dependency) {
    dependencies.remove(dependency);
    saveData();
    writePubspec();
  }

  void writePubspec() {
    final file = File('$clientPath/pubspec.yaml');
    var fileString = file.readAsStringSync();

//    const asd = "# DON'T EDIT COMMENT GENERATED BY FLUTTER_MANAGED #";
    final regExp = RegExp(
      r"(  # DON'T EDIT COMMENT GENERATED BY FLUTTER_MANAGED #\s)([\s\S]*?)(\s  # DON'T EDIT COMMENT GENERATED BY FLUTTER_MANAGED #)",
      caseSensitive: true,
      multiLine: true,
    );

    final match = regExp.firstMatch(fileString).group(2);

    final dependenciesBuffer = StringBuffer();
    _serialize(_defaultDependencies, dependenciesBuffer);
    _serialize(dependencies, dependenciesBuffer);
//    _defaultDependencies.forEach((dependency) => dependenciesBuffer.write('${dependency.serialize()}\n'));
//    dependencies.forEach((dependency) => dependenciesBuffer.write('${dependency.serialize()}\n'));
    fileString = fileString.replaceFirst(match, dependenciesBuffer.toString());

    file.writeAsStringSync(fileString);
  }

  void _serialize(List<PubDependency> list, StringBuffer buffer) {
    list.forEach((dependency) => buffer.write('${dependency.serialize()}\n'));
  }

  String get name => _name;
  Map<String, Map<String, dynamic>> get entities => _data.entities;
  Map<String, Attribute> get attributes => _data.attributes;
  List<PubDependency> get dependencies => _data.dependencies;
}