import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_manager/entities.dart';
import 'package:flutter_manager/logic/app.dart';
import 'package:flutter_manager/skeleton/grpc/grpc.dart';
import 'package:path/path.dart';
import 'package:recase/recase.dart';
import 'package:yaml/yaml.dart';

class Skeleton {

  final List<ModuleBone> modules;

  Skeleton({this.modules});

  Future<void> run() async {
    if (modules == null || modules.isEmpty) return;

    final boneMap = BoneMap();

    final yaml = loadYaml(File(skeletonFilePath).readAsStringSync());

    for (var module in modules) {
      await module.readTree(boneMap, yaml[module.name]);
    }

    for (var module in modules) {
      module.writeTree();
    }
  }
}

//class RootModule extends ModuleBone {
//  RootModule() : super(
//    name: null,
//    children: [
//      OutputBone(
//        output: Output(
//          language: Language.Dart,
//          target: Target.Client
//        ),
//        children: [
//
//        ]
//      )
//    ]
//  );
//}

abstract class Bone {
  final String name;
  Bone(this.name);

  String get path => name != null ? name : null;
}

abstract class CopyFilesBone extends ListReaderBone<DataElement> with Writer {
  final String fromFolder;
  CopyFilesBone({this.fromFolder});

  @override
  String get regexp => null;

  @override
  FutureOr<List<DataElement>> read(dynamic yaml) async {
    list.clear();
    list.addAll(listFromDir(
        dirPath: fromFolder,
        regExp: regexp,
        yaml: yaml
    ));
  }

  @override
  DataElement createOnMatch(RegExpMatch match) => DataElement(null);

//  String import(String fileName) {
//    return _import(relativePath + '/' + fileName);
//  }
}
abstract class FileBone extends Bone with Writer {

  final DataElement elem;
  final WriteFileInfo fileInfo;

  FileBone(String elemName, String fileName) :
        elem = DataElement(elemName),
        fileInfo = WriteFileInfo(fileName),
        super(null);

  String import() {
    return _import(relativePath, elem, fileInfo);
  }
}
abstract class Reader<T> {
  FutureOr<T> read(dynamic yaml);
}
//abstract class KeyReader<T> implements Reader<T> {
//  FutureOr<T> read(dynamic yaml);
//}
//abstract class SimpleReader<T> implements Reader<T> {
//  FutureOr<T> read();
//}
abstract class Writer {
  String relativePath;
  WriterContext _writerContext;

  String write() => null;

  void attach(ReadContext readContext) {
    this.relativePath = readContext.relativePath;
    this._writerContext = readContext.writerContext;
  }

  String _import(String relativePath, DataElement elem, WriteFileInfo fileInfo) {
    if (_writerContext.output == null)
      throw Exception('Can not import bone which is outside of an Output');

    final language = _writerContext.output.language;

//    String fileName;
//    if (elem.fileName != null) {
//      fileName = basenameWithoutExtension(elem.fileName);
//    } else if (elem.name != null) {
//      String name = elem.name;
//
//      if (language == Language.Dart) {
//        name = name.snakeCase;
//      } else if (language == Language.Kotlin) {
//        name = name.pascalCase;
//      }
//      fileName = name + language.fileExtension;
//    }

    if (language == Language.Dart) {
      return "import 'package:"
          + join(projName, OPlatform.workingDir, relativePath, fileInfo.fileName)
          + "';";
    }
    else if (language == Language.Kotlin) {
      return 'import ' + server.workingDirPackage
          + '.' + relativePath.dotCase
          + '.' + elem.name;
    }
    throw Exception('No support for language: $language');
  }

  T get<T extends Bone>() => _writerContext.get<T>();

  WriterContext get nodeContext => _writerContext;

  String get absolutePath {
    return join(_writerContext.output.target.projPath, relativePath);
  }

  notEmptyThenLoop<T>(Iterable<T> iterable, String lead, String Function(T obj) elem, String trail) {
    if (iterable.isEmpty) return '';
    return '''
    
  $lead
    ${loop(iterable, 2, ',\n', elem)}
  $trail''';
  }

  // ignore: non_constant_identifier_names
  String loop<T>(Iterable<T> list, int padding, String trailing, String Function(T value) writer) {
    final values = StringBuffer();

    final leadingBuffer = StringBuffer();
    for (var i = 0; i < padding; i++) {
      leadingBuffer.write('  ');
    }
    final leading = leadingBuffer.toString();

    var i = 0;
    for (var elem in list) {
      final isFirst = i == 0;
      final isLast = i == list.length - 1;

      if (!isFirst) {
        values.write(leading);
      }
      String string = writer(elem).trim();
      string = string.replaceAll('\n', '\n$leading');
      values.write(string);
      if (!isLast) {
        values.write(trailing);
      }

      i++;
    }

    return values.toString();
  }
}
class WriterContext {
  final BoneMap _dependencies;
  final Output output;

  WriterContext(this._dependencies, this.output);

  T get<T extends Bone>() => _dependencies.get<T>();

  void add(Bone bone) => _dependencies.add(bone);
}
class ReadContext {
  final WriterContext writerContext;
  dynamic yaml;
  String relativePath;
  ReadContext(this.writerContext, this.relativePath, this.yaml);
}
class Dependency<T> {
  final T obj;
  final String relativePath;

  Dependency(this.obj, this.relativePath);
}

class KeyBone<T> extends Bone {
  static final keys = <Type, String> {};

  KeyBone(String name) : super(name) {
    keys[T] = name;
  }
}

abstract class ValueBone<T> extends Bone with Reader<T> {
  T value;

  ValueBone() : super(null);

  @override
  FutureOr<T> read(yaml) {
    return value = yaml as T;
  }
}

class Folder extends MultiChildBone {
  Folder(String name, List<Bone> children) : super(name, children: children);
}

abstract class KeyListBone<T extends DataElement> extends KeyBone<List<T>> {

  KeyListBone(String name) : super(name);

//  @override
//  FutureOr<List<T>> read(dynamic yaml) async {
//    final listFromFunc = await readList(yaml);
//    if (listFromFunc != null) list.addAll(listFromFunc);
//    return list;
//  }
  FutureOr<List<T>> readList(dynamic yaml) {
//    return <T>[];
    return (yaml as List)?.map<T>((yaml) {
      final name = yaml['name'];
      final element = createElement(name);
      return readElement(element, yaml);
    })?.toList();
  }

  T readElement(T obj, dynamic yaml);
  T createElement(String name);

  List<T> listFromDir({
      String dirPath,
      String regExp,
      T Function(String fileName, RegExpMatch match) createOnMatch,
      dynamic yaml}) {

    final list = <T>[];

    for (var fileEntity in Directory(dirPath).listSync(recursive: false)) {
      final fileString = File(fileEntity.path).readAsStringSync();
      final serviceMatch = RegExp(regExp);

      serviceMatch?.allMatches(fileString)?.forEach((match) {
        T created = createOnMatch(basename(fileEntity.path), match);

//        final obj = this.list.firstWhere((T obj) => obj.name == created.name,
//            orElse: () => null);

        if (yaml != null) {
          final childYaml = yaml[created.name];
          if (childYaml != null)
            readElement(created, childYaml);
        }
//          readElement(created, yaml != null ? yaml[created.name] : null);

        list.add(created);
      });
    }
    return list;
  }
}
class BoneMap {
  final List<Bone> _bones = [];

  T get<T extends Bone>() {
    if (_bones == null) return null;
    final matcher = TypeMatcher<T>();

    for (Bone bone in _bones) {
      if (matcher.check(bone)) {
//        print(dep as Dependency<T>);
        return bone as T;
//        return Dependency<T>(dep.obj, dep.relativePath);
//        return dep as Dependency<T>;
      }
    }
    throw Exception('Missing dependency for type: $T');
  }

  void add(Bone bone) {
    _bones.add(bone);
  }
}
abstract class SingleChildBone<T extends Bone> extends Bone {
  final T child;
  SingleChildBone(String name, {this.child}) : super(name);
}
abstract class MultiChildBone<T extends Bone> extends Bone {
  final List<T> children;

  MultiChildBone(String name, {this.children}) : super(name);
}
class ModuleBone extends MultiChildBone {

  ModuleBone({String name, List<Bone> children}): super(name, children: children);

  Future<void> readTree(BoneMap boneMap, dynamic yaml) async {
    for (var rootBone in children) {
      final output = rootBone is OutputBone ? rootBone.output : null;
      final writerContext = WriterContext(boneMap, output);
      final readContext = ReadContext(writerContext, path, yaml);

      await read(rootBone, readContext);
    }
  }

  Future<void> read(Bone bone, ReadContext readContext) async {
    if (bone.path != null)
      readContext.relativePath = join(readContext.relativePath, bone.path);

    readContext.writerContext.add(bone);

    if (bone is Writer) {
      (bone as Writer).attach(readContext);
    }

    if (bone is Reader) {
      dynamic yaml;
      final key = KeyBone.keys[bone.runtimeType];
      if (key != null)
        yaml = readContext.yaml[key];

      await (bone as Reader).read(yaml);
    }

    if (bone is SingleChildBone && bone.child != null) {
      await read(bone.child, readContext);
    }
    else if (bone is MultiChildBone && bone.children != null) {
      final fallbackPath = readContext.relativePath;
      final fallbackYaml = readContext.yaml;

      for (var child in bone.children) {
        await read(child, readContext);

        readContext.relativePath = fallbackPath;
        readContext.yaml = fallbackYaml;
      }
    }
  }

  void writeTree() {
    for (var bone in children) {
      if (bone is OutputBone) {
        if (bone.output.g) {
          // Should remove everything before writing to ensure
          // complete sync with generated files
          final dir = Directory(bone.absolutePath);
          if (dir.existsSync()) dir.deleteSync(recursive: true);
        }

        bone.children?.forEach((child) {
          write(child);
        });
      }
    }
  }

  void write(Bone bone) {
    if (bone is CopyFilesBone) {
      final dest = Directory(bone.absolutePath);
      if (!dest.existsSync())
        dest.createSync(recursive: true);

      copyDirectory(Directory(bone.fromFolder), dest);
    }
    else if (bone is ListWriterBone) {
      for (var i = 0; i < bone.list.length; i++) {
        final elem = bone.list[i];
        final file = bone.files[i];
        _writeFile(
            bone,
            file,
            bone.writeElement(elem));
      }
    }
    else if (bone is FileBone) {
      _writeFile(bone, bone.fileInfo, bone.write());
    }

    if (bone is SingleChildBone) {
      write(bone.child);
    }
    else if (bone is MultiChildBone) {
      bone.children?.forEach((child) {
        write(child);
      });
    }
  }

  void copyDirectory(Directory source, Directory dest) {
    source.listSync(recursive: false).forEach((var entity) {
      if (entity is Directory) {
        var newDirectory = Directory(join(dest.absolute.path, basename(entity.path)));
        newDirectory.createSync();

        copyDirectory(entity.absolute, newDirectory);
      } else if (entity is File) {
        entity.copySync(join(dest.path, basename(entity.path)));
      }
    });
  }

  void _writeFile(Writer writer, WriteFileInfo fileInfo, String fileString) {
    if (fileString == null) return;

    final relativePath = writer.relativePath;
    final output = writer.nodeContext.output;
    final buffer = StringBuffer();

    if (output.target == Target.Server) {
      buffer..write('package ${server.workingDirPackage}' + '.' + relativePath.dotCase)
            ..write('\n\n');
    }

    buffer.write(fileString.trim());

//    String fileName;
//    if (elem.fileName != null) {
//      fileName = elem.fileNameNoExt;
//    } else if (elem.name != null) {
//      fileName = elem.name;
//    }
//    if (language == Language.Dart) {
//      fileName = fileName.snakeCase;
//    } else if (language == Language.Kotlin) {
//      fileName = fileName.pascalCase;
//    }
//    fileName += output.language.fileExtension;

//    String filePath = output.target.projPath
//        + relativePath
//        + '/' + fileInfo.fileName;
    String filePath = join(output.target.projPath, relativePath, fileInfo.fileName);

    final file = File(filePath);
    // If not fully generated code and file already exists should not overwrite
    if (!output.g && file.existsSync()) return;
    else file.createSync(recursive: true);

    file.writeAsStringSync(buffer.toString());
  }
}

abstract class ListWriterBone<R extends ListReaderBone<T>, T extends DataElement> extends Bone with Writer {

  List<WriteFileInfo> _files;

  ListWriterBone() : super(null);

  R get _reader => get<R>();
  List<T> get list => _reader.list;

  List<WriteFileInfo> get files {
    if (_files != null) return _files;
    _files = [];

    final language = _writerContext.output.language;

    for (var file in _reader.files) {
      String fileName = file.fileNameNoExt;

      if (language == Language.Dart) {
        fileName = fileName.snakeCase;
      } else if (language == Language.Kotlin) {
        fileName = fileName.pascalCase;
      }
      fileName += language.fileExtension;

      _files.add(WriteFileInfo(fileName));
    }
    return _files;
  }

  String writeElement(T element) => null;

  String import({String Function(T elem) fileNameBuilder}) {
    return loop(list, 0, '\n', (T elem) {
      final fileInfo = files[list.indexOf(elem)];
      return _import(relativePath, elem, fileInfo);
    });
  }
}

class DataElement {
  String name;

  DataElement(this.name);
}

class WriteFileInfo {
  String fileName;
  String get fileNameNoExt => basenameWithoutExtension(fileName);

  WriteFileInfo(this.fileName);
}
abstract class ListReaderBone<T extends DataElement> extends Bone with Reader<List<T>>, Writer {

  final List<T> list = [];
  final List<WriteFileInfo> files = [];

  ListReaderBone() : super(null);

  String get regexp;

  @override
  FutureOr<List<T>> read(dynamic yaml) async {
    list.clear();
    list.addAll(listFromDir(
      dirPath: absolutePath,
      regExp: regexp,
      yaml: yaml
    ));
  }

//  FutureOr<List<T>> readList(dynamic yaml) {
//    if (yaml == null) return null;
//
//    if (yaml is List) {
//      return yaml.map<T>((yaml) {
//        final name = yaml['name'];
//        final element = match(name);
//        return readElement(element, yaml);
//      })?.toList();
//    }
//    return null;
//  }

  T readElement(T obj, dynamic yaml) => obj;
  T createOnMatch(RegExpMatch match);

//  FutureOr<List<T>> readList();

  List<T> listFromDir({
    String dirPath,
    String regExp,
    dynamic yaml}) {

    return _readDir(Directory(dirPath), regExp, yaml).toList();
  }

  Iterable<T> _readDir(Directory dir, String regexp, yaml) sync* {
    for (var fileEntity in dir.listSync(recursive: true)) {
      final file = File(fileEntity.path);
      if (!file.existsSync()) continue;

      final fileString = file.readAsStringSync();
      // Create match by files if input regex is null
      if (regexp == null) {
        yield createOnMatch(null);
        files.add(WriteFileInfo(basename(fileEntity.path)));
        continue;
      }

      final serviceMatch = RegExp(regexp);
      if (serviceMatch != null) {
        for (var match in serviceMatch.allMatches(fileString)) {
          T created = createOnMatch(match);

          if (yaml != null) {
            final childYaml = yaml[created.name];
            if (childYaml != null)
              readElement(created, childYaml);
          }
          yield created;
          files.add(WriteFileInfo(basename(fileEntity.path)));
        }
      }
    }
  }

//  Future<List<T>> listFromDir<T extends Element>({ String dirPath, String regExp, List<T> writtenData, T Function(String, String) defObj}) {
//    final completer = Completer<List<T>>();
//    final list = <T>[];
//    Directory(dirPath).list(recursive: false).listen ((fileEntity) {
//      final fileString = File(fileEntity.path).readAsStringSync();
//      final serviceMatch = RegExp(regExp);
//      serviceMatch?.allMatches(fileString)?.forEach((match) {
//        final objName = match.group(1);
//        Object obj;
//        if (writtenData != null) {
//          obj = writtenData.firstWhere((T obj) => obj.name == objName,
//            orElse: () => defObj(basename(fileEntity.path), objName));
//        } else {
//          obj = defObj(basename(fileEntity.path), objName);
//        }
//        list.add(obj);
//      });
//    }, onDone: () {
//      completer.complete(list);
//    });
//    return completer.future;
//  }

  String import({Function(T elem, WriteFileInfo fileInfo) where}) {
    Iterable<T> iterable = list;
    if (where != null) {
      iterable = iterable.where((elem) => where(elem, files[list.indexOf(elem)]));
    }
    return loop(iterable, 0, '\n', (T elem) {
      final file = files[list.indexOf(elem)];
//      String fileName = elem.name?.snakeCase;
//      if (fileName == null) fileName = elem.fileName;

      return _import(relativePath, elem, file);
    });
  }

  String writeElement(T element) => null;
}

class OutputBone extends MultiChildBone with Writer {

  final Output output;
//  final Language language;
//  final Target target;

  @override
  final List<Bone> children;

//  OutputBone({this.language, this.target, List<Bone> create, List<Bone> g})
//      : children = [
//          ...create,
//          ...g
//        ],
//        super(null);

  OutputBone({this.output, this.children}) : super(null);
//  OutputBone({this.language, this.target, this.children}) : super(null);

  @override
  String get path => output.g ? 'g' : '';

}

//
//
//
//
////class GrpcBone extends ModuleBone {
////
////  GrpcBone() : super('grpc');
////
////
////
////}
//
//abstract class Backbone {
//  final String name;
//
//  Backbone(this.name);
//
//  List<WBone> body();
//
//  void writeAll() {
//    body().forEach((bone) {
//      bone.writeFile();
//    });
//  }
//
//  Future<List<T>> listFromDir<T extends Element>({ String dirPath, String regExp, List<T> writtenData, T Function(String, String) defObj}) {
//    final completer = Completer<List<T>>();
//    final list = <T>[];
//    Directory(dirPath).list(recursive: false).listen ((fileEntity) {
//      final fileString = File(fileEntity.path).readAsStringSync();
//      final serviceMatch = RegExp(regExp);
//      serviceMatch?.allMatches(fileString)?.forEach((match) {
//        final objName = match.group(1);
//        final obj = writtenData.firstWhere((T obj) => obj.name == objName,
//            orElse: () => defObj(basename(fileEntity.path), objName));
//        list.add(obj);
//      });
//    }, onDone: () {
//      completer.complete(list);
//    });
//    return completer.future;
//  }
//}
//
//abstract class WBone <T extends Backbone> {
//
//  final T backbone;
//  final Output output;
//
//  WBone(this.backbone, this.output);
//
//  void writeFile() {
//    final fileString = write().trim();
//    final file = File(filePath);
//    if (!file.existsSync()) {
//      file.create(recursive: true);
//    }
//    file.writeAsStringSync(fileString);
//  }
//
//  String get filePath;
//
//  String write();
//
//  String constructFullFilePath() {
//    return output.target.projPath
//        + '/' + backbone.name.snakeCase + '/'
//        + (output.g ? 'g/' : '')
//        + output.fileName
//        + output.language.fileExtension;
//  }
//
//  String writeFor<T>(List<T> list, int padding, String trailing, String Function(T value) writer) {
//    final values = StringBuffer();
//
//    final leadingBuffer = StringBuffer();
//    for (var i = 0; i < padding; i++) {
//      leadingBuffer.write('  ');
//    }
//    final leading = leadingBuffer.toString();
//
//    for (var i = 0; i < list.length; i++) {
//      final value = list[i];
//      final isFirst = i == 0;
//      final isLast = i == list.length - 1;
//
//      if (!isFirst) {
//        values.write(leading);
//      }
//      values.write(writer(value));
//      if (!isLast) {
//        values.write(trailing);
//      }
//    }
//    return values.toString();
//  }
//}

//abstract class DartBone <T extends Backbone> extends Bone<T> {
//  final _importRoot = 'package:$projName$projDir';
//
//  DartBone(T backbone) : super(backbone);
//
//  String import(String fileName) {
//    return "import '$_importRoot/${backbone.name}/$fileName.dart';";
//  }
//  String importGen(String fileName) {
//    return "import '$_importRoot/${backbone.name}/g/$fileName.dart';";
//  }
//
//  @override
//  String get filePath => '$clientProjPath/${backbone.name.toLowerCase()}/g/${'${backbone.name}Bone'.snakeCase}.dart';
//}


//
//abstract class ListBone<T extends Backbone, R extends WBone> extends WBone<T> {
//
//  ListBone(T backbone, Output output, this._filePath) : super(backbone, output);
//
//}

class Target {
  final String srcPath;
  final String projPath;

  Target._(this.srcPath, this.projPath);

  static final Client = Target._(client.src, client.workingPath);
  static final Server = Target._(server.src, server.workingPath);
}
class Output {
  final Language language;
  final Target target;
  final String fileName;
  final bool g;

  Output({this.language, this.target, this.fileName, this.g});
}
class Language {
  final String fileExtension;

  Language._(this.fileExtension);

  static final Dart = Language._('.dart');
  static final Kotlin = Language._('.kt');
}

//abstract class DartListBone <T extends DartBone> extends ListBone<T> {
//
//  DartListBone(String name) : super(name);
//
//
//
//}