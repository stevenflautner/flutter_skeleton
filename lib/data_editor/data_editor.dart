import 'dart:io';

import 'package:flutter_manager/entities.dart';
import 'package:flutter_manager/logic/app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_managed/locator.dart';

abstract class EditableData<T> extends ChangeNotifier {

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
      clientStringBuffer
        ..write(writeClientObjString(obj).trim())
        ..write('\n');
      serverStringBuffer
        ..write(writeServerObjString(obj).trim())
        ..write('\n');
    });

    final app = get<Application>();
    _writeFile(app.clientSrcPath, writeFileTo(true), clientStringBuffer.toString());
    _writeFile(app.serverSrcPath, writeFileTo(false), serverStringBuffer.toString());
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
      file.create(recursive: true);
    }
    file.writeAsStringSync(generatedString);
  }

  String writeClientObjString(T obj);
  String writeServerObjString(T obj);
  String writeFileTo(bool isClient);

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

      final written = writer(value);
      if (written != null)
        values.write(written);

      if (!isLast) {
        values.write(trailing);
      }
    }
    return values.toString();
  }

}

class SelectedObject extends ChangeNotifier {

  DataObj _obj;

  void select(dynamic obj) {
    _obj = obj;
    notifyListeners();
  }

  DataObj get obj => _obj;
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