import 'dart:async';
import 'dart:io';

import 'package:flutter_manager/entities.dart';
import 'package:flutter_manager/framework/skeleton.dart';
import 'package:flutter_manager/pub_dependency/pub_dependency.dart';
import 'package:flutter_manager/skeleton/skeleton.dart';
import 'package:path/path.dart';
import 'package:recase/recase.dart';
import 'package:yaml/yaml.dart';
import 'package:yamlicious/yamlicious.dart';

const skeletonFilePath = 'skeleton.yaml';
String projName;
Client client;
Server server;

Future<void> initialize(String workingDir) async {
  Directory.current = Directory(workingDir);
  projName = basename(workingDir);
  client = Client();
  server = Server();
}

final _defaultDependencies = <PubDependency>[
  GitPubDependency(
      'flutter_managed',
      'http://github.com/stevenflautner/flutter_managed.git'
  )
];

abstract class OPlatform {
  static const workingDir = 'managed';

  final String root;

  OPlatform(this.root);

  String get src;
  String get workingPath => join(src, workingDir);
}

class Client extends OPlatform {
  Client() : super('client');

  @override
  String get src => join(root, 'lib');
}
class Server extends OPlatform {

  String _workingDirPackage;
  String _src;

  Server() : super('server') {
    final buildGradle = File(join(root, 'build.gradle')).readAsStringSync();
    final mainClassMatch = RegExp(r'mainClassName = "(.*).MainKt"')
        .firstMatch(buildGradle);

    if (mainClassMatch == null)
      throw 'mainClassName could not be identified';

    final package = mainClassMatch.group(1);
    _src = join(root, 'src/main/kotlin', package.pathCase);
    _workingDirPackage = join(package, OPlatform.workingDir).dotCase;
  }

  @override
  String get src => _src;
  String get workingDirPackage => _workingDirPackage;
}

//void _initPath() {
//  final serverBuildGradleString = File('$serverRootPath/build.gradle').readAsStringSync();
//  final serverMainClassMatch = RegExp(r'mainClassName = "(.*).MainKt"').firstMatch(serverBuildGradleString);
//  if (serverMainClassMatch == null)
//    throw 'mainClassName could not be identified';
//
//  final serverSrcKotlinPackage = serverMainClassMatch.group(1);
//  serverDataKotlinPackage = (serverSrcKotlinPackage + projDir).dotCase;
//  serverSrcPath = '$serverRootPath/src/main/kotlin/${serverSrcKotlinPackage.replaceAll('.', '/')}';
//  serverDataPath = '$serverRootPath/src/main/kotlin/${serverDataKotlinPackage.replaceAll('.', '/')}';
//}

class Application {

//  final _path = dirname(Platform.script.toString());


//  String get path => _path;

//  String serverDataPath;
//  final String clientSrcPath = clientRootPath + '/lib/managed/g';

  Data _data;

  final _defaultDependencies = <PubDependency>[
    GitPubDependency(
      'flutter_managed',
      'http://github.com/stevenflautner/flutter_managed.git'
    )
  ];
  

//  Future<void> initialize(String _workingDir) async {
//    workingDir = _workingDir;
//
//    projName = _parseName();
//
//
//    await initPath();
//    await _loadData();
//  }


//  Future<void> initPath() async {
//    final serverBuildGradleString = File('$serverRootPath/build.gradle').readAsStringSync();
//    final serverMainClassMatch = RegExp(r'mainClassName = "(.*).MainKt"').firstMatch(serverBuildGradleString);
//    if (serverMainClassMatch == null)
//      throw 'mainClassName could not be identified';
//
//    final serverSrcKotlinPackage = serverMainClassMatch.group(1);
//    serverDataKotlinPackage = (serverSrcKotlinPackage + projDir).dotCase;
//    serverSrcPath = '$serverRootPath/src/main/kotlin/${serverSrcKotlinPackage.replaceAll('.', '/')}';
//    serverDataPath = '$serverRootPath/src/main/kotlin/${serverDataKotlinPackage.replaceAll('.', '/')}';
//  }

  Future<void> _loadData() async {
    _data = Data([], [], [], [], []);
//    try {
//      _data = Data.fromYaml(
//        loadYaml(File(skeletonFilePath).readAsStringSync())
//      );
//    } catch (e) {
//      print(e);
//      _data = Data([], [], [], [], []);
//    }

//    final interceptorListFromProject = await listFromDir(
//        dirPath: '$serverSrcPath/interceptors',
//        regExp: r'class (.*)Interceptor : ServerInterceptor {',
//        writtenData: _data.interceptors,
//        defObj: (fileName, objName) => Interceptor(objName));
//    _data.interceptors
//      ..clear()
//      ..addAll(interceptorListFromProject);
//
//    final serviceListFromProject = await listFromDir(
//        dirPath: serverRootPath + '/src/main/proto',
//        regExp: r'service (.*) {',
//        defObj: (fileName, objName) => Service(objName),
//        writtenData: _data.services);
//    _data.services
//      ..clear()
//      ..addAll(serviceListFromProject);
  }

  Future<void> saveData() async {
    File(skeletonFilePath).writeAsStringSync(
      toYamlString(_data.toYaml())
    );
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
    final file = File('${client.root}/pubspec.yaml');
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

  Future<List<T>> listFromDir<T extends DataElement>({ String dirPath, String regExp, List<T> writtenData, T Function(String, String) defObj}) {
    final completer = Completer<List<T>>();
    final list = <T>[];
    Directory(dirPath).list(recursive: false).listen ((fileEntity) {
      final fileString = File(fileEntity.path).readAsStringSync();
      final serviceMatch = RegExp(regExp);
      serviceMatch?.allMatches(fileString)?.forEach((match) {
        final objName = match.group(1);
        final obj = writtenData.firstWhere((T obj) => obj.name == objName,
            orElse: () => defObj(basename(fileEntity.path), objName));
        list.add(obj);
      });
    }, onDone: () {
      completer.complete(list);
    });
    return completer.future;
  }

  List<Entity> get entities => _data.entities;
  List<Attribute> get attributes => _data.attributes;
  List<PubDependency> get dependencies => _data.dependencies;
  List<Service> get services => _data.services;
  Data get data => _data;
}