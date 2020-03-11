import 'package:flutter_manager/pub_dependency/pub_dependency.dart';
import 'data_editor/data_editor.dart';

class Data {
  final Map<String, Map<String, String>> entities;
  final Map<String, Attribute> attributes;
  final List<PubDependency> dependencies;

  Data(this.entities, this.attributes, this.dependencies);

  Map<String, dynamic> toJson() => <String, dynamic> {
    'entities': entities,
    'attributes': attributes,
    'dependencies': dependencies,
  };
  factory Data.fromJson(Map<String, dynamic> json) {
    final dependencies = <PubDependency>[];
    final dependenciesJson = json['dependencies'];
    if (dependenciesJson != null) {
      dependencies.addAll((dependenciesJson as List).map((json) => PubDependency.fromJson(json)));
    }
    final entities = <String, Map<String, String>> {};
    (json['entities'] as Map<String, dynamic>)?.forEach((key, value) {
      final entity = <String, String> {};
      (value as Map<String, dynamic>)?.forEach((key, value) {
        entity[key] = value as String;
      });
      entities[key] = entity;
    });

    final attrs = <String, Attribute>{};
    (json['attributes'] as Map<String, dynamic>)?.forEach((key, value) {
      attrs[key] = Attribute.fromJson(value);
    });

    return Data(
      entities,
      attrs,
      dependencies,
    );
  }
}

abstract class Attribute {

  final Type type;

  Attribute(this.type);

  factory Attribute.fromJson(Map<String, dynamic> json) {
    final type = Type(json['type']);

    switch (type.baseType) {
      case 'Enum': {
        return EnumAttribute.fromJson(json);
      }
      case 'List': {
        return ListAttribute.fromJson(json);
      }
    }
    throw 'No deserializer found for type: ${json['type']}';
  }
}

abstract class ValueAttribute extends Attribute {

  final List<String> values;

  ValueAttribute(Type type, this.values) : super(type);
}

class EnumAttribute extends ValueAttribute {

  EnumAttribute(List<String> values) : super(Type('Enum'), values);

  Map<String, dynamic> toJson() => <String, dynamic> {
    'type': type.fullTypeString,
    'values': values,
  };
  factory EnumAttribute.fromJson(Map<String, dynamic> json) {
    return EnumAttribute(
      json['values'].cast<String>()
    );
  }
}

class ListAttribute extends ValueAttribute {

  ListAttribute(Type type, List<String> values) : super(type, values);

  Map<String, dynamic> toJson() => <String, dynamic> {
    'type': type.fullTypeString,
    'values': values,
  };
  factory ListAttribute.fromJson(Map<String, dynamic> json) {
    return ListAttribute(
      Type(json['type']),
      json['values'].cast<String>()
    );
  }
}