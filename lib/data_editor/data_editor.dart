import 'dart:async';
import 'dart:io';

import 'package:flutter_manager/framework/skeleton.dart';
import 'package:flutter_manager/logic/app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_managed/locator.dart';

abstract class EditableData<T extends DataElement> extends ChangeNotifier {

  void remove(T obj) {
    getData().remove(obj);
    notify();
  }

  notify() async {
    generate();
    await get<Application>().saveData();
    notifyListeners();
  }

  void generate() {
    final clientStringBuffer = StringBuffer();
    final serverStringBuffer = StringBuffer();

    _writeHead(clientStringBuffer, serverStringBuffer);

    getData().forEach((obj) {
      final clientObjString = writeClientObjString(obj)?.trim();
      final serverObjString = writeServerObjString(obj)?.trim();

      clientStringBuffer
        ..write(clientObjString)
        ..write('\n');
      serverStringBuffer
        ..write(serverObjString)
        ..write('\n');
    });

    final app = get<Application>();
//    _writeFile(app.clientSrcPath, writeFileTo(true), clientStringBuffer.toString());
//    _writeFile(app.serverDataPath, writeFileTo(false), serverStringBuffer.toString());
  }

  void _writeHead(StringBuffer clientStringBuffer, StringBuffer serverStringBuffer) {
    final clientHead = writeClientHead();
    if (clientHead != null)
      clientStringBuffer
        ..write(clientHead.trim())
        ..write('\n\n');

    final serverHead = writeServerHead();
    if (serverHead != null)
      serverStringBuffer
        ..write(serverHead.trim())
        ..write('\n\n');
  }

  String writeServerHead() => null;
  String writeClientHead() => null;

  _writeFile(String basePath, String path, String generatedString) {
    final fullPath = '$basePath/$path';
    final file = File(fullPath);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync(generatedString);
  }

  String writeClientObjString(T obj) => null;
  String writeServerObjString(T obj) => null;
  String writeFileTo(bool isClient) => null;

  List<T> getData();

  Widget buildObjView();

  Widget buildAddObjDialog(BuildContext context);

  String writeFor<T>(List<T> list, int padding, String trailing, String Function(T value) writer) {
    final values = StringBuffer();

    final leadingBuffer = StringBuffer();
    for (var i = 0; i < padding; i++) {
      leadingBuffer.write('  ');
    }
    final leading = leadingBuffer.toString();

    for (var i = 0; i < list.length; i++) {
      final value = list[i];
      final isFirst = i == 0;
      final isLast = i == list.length - 1;

      if (!isFirst) {
        values.write(leading);
      }
      values.write(writer(value));
      if (!isLast) {
        values.write(trailing);
      }
    }
    return values.toString();
  }

  Future<List<T>> listFromDir({ String dirPath, String regExp, T Function(String) defObj}) {
    final completer = Completer<List<T>>();
    final list = <T>[];
    Directory(dirPath).list(recursive: false).listen ((file) {
      final fileString = File(file.path).readAsStringSync();
      final serviceMatch = RegExp(regExp);
      serviceMatch?.allMatches(fileString)?.forEach((match) {
        final objName = match.group(1);
        final obj = getData().firstWhere((T obj) => obj.name == objName,
            orElse: () => defObj(objName));
        list.add(obj);
      });
    }, onDone: () {
      completer.complete(list);
    });
    return completer.future;
  }

}

class SelectedObject extends ChangeNotifier {

  DataElement _obj;

  void select(dynamic obj) {
    _obj = obj;
    notifyListeners();
  }

  DataElement get obj => _obj;
}

class Type {
  final String baseType;
  final String dartString;
  final Type subtype;
  final bool isPrimitive;

  Type._(this.baseType, this.dartString, {this.subtype, this.isPrimitive});

//  factory Type.list(String listType) {
//    final subtype = _convert(listType);
//    return Type(listType, 'List<${subtype.dartString}>', subtype: subtype);
//  }

  factory Type._simple(String typeString) {
    String primitiveString;
    switch (typeString) {
      case 'String': {
        primitiveString = 'String';
        break;
      }
      case 'Boolean': {
        primitiveString = 'bool';
        break;
      }
      case 'Int': {
        primitiveString = 'int';
        break;
      }
      case 'Float': {
        primitiveString = 'num';
        break;
      }
      case 'Double': {
        primitiveString = 'num';
        break;
      }
    }
    return Type._(typeString, primitiveString ?? typeString, isPrimitive: primitiveString != null);
  }

  factory Type(String typeString) {
    final typeMatch = RegExp(r'(.*)<(.*)>').firstMatch(typeString);
    if (typeMatch != null) {
      final subtype = Type._simple(typeMatch.group(2));
      final collType = Type._(typeMatch.group(1), '${typeMatch.group(1)}<${subtype.dartString}>', subtype: subtype);
      return collType;
    }
    return Type._simple(typeString);
  }

  String get fullTypeString {
    if (subtype != null)
      return '$baseType<${subtype.baseType}>';
    return baseType;
  }

}