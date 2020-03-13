import 'package:flutter_manager/pub_dependency/pub_dependency.dart';
import 'data_editor/data_editor.dart';

class Data {
  final List<Entity> entities;
  final List<Attribute> attributes;
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
//    final entities = <String, Map<String, String>> {};
//    (json['entities'] as Map<String, dynamic>)?.forEach((key, value) {
//      final entity = <String, String> {};
//      (value as Map<String, dynamic>)?.forEach((key, value) {
//        entity[key] = value as String;
//      });
//      entities[key] = entity;
//    });

//    final attrs = <String, Attribute> {};
//    (json['attributes'] as Map<String, dynamic>)?.forEach((key, value) {
//      attrs[key] = Attribute.fromJson(value);
//    });

    return Data(
      (json['entities'] as List).map((json) => Entity.fromJson(json)).toList(),
      (json['attributes'] as List).map((json) => Attribute.fromJson(json)).toList(),
      dependencies,
    );
  }
}

abstract class DataObj {
  String name;

  DataObj(this.name);
}

class Entity extends DataObj {
  List<EntityField> fields;

  Entity(String name, this.fields) : super(name);

  Map<String, dynamic> toJson() => <String, dynamic> {
    'name': name,
    'fields': fields,
  };
  factory Entity.fromJson(Map<String, dynamic> json) {
    return Entity(
      json['name'],
      (json['fields'] as List).map((json) => EntityField.fromJson(json)).toList(),
    );
  }
}

class EntityField {
  String name;
  Type type;
  bool serverModifiable;
  bool clientModifiable;

  EntityField(this.name, this.type, this.serverModifiable, this.clientModifiable);

  Map<String, dynamic> toJson() => <String, dynamic> {
    'name': name,
    'type': type.fullTypeString,
    'serverModifiable': serverModifiable,
    'clientModifiable': clientModifiable,
  };
  factory EntityField.fromJson(Map<String, dynamic> json) {
    return EntityField(
      json['name'],
      Type(json['type']),
      json['serverModifiable'],
      json['clientModifiable'],
    );
  }
}

abstract class Attribute extends DataObj {

  final Type type;

  Attribute(String name, this.type) : super(name);

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

  ValueAttribute(String name, Type type, this.values) : super(name, type);
}

class EnumAttribute extends ValueAttribute {

  EnumAttribute(String name, List<String> values) : super(name, Type('Enum'), values);

  Map<String, dynamic> toJson() => <String, dynamic> {
    'name': name,
    'type': type.fullTypeString,
    'values': values,
  };
  factory EnumAttribute.fromJson(Map<String, dynamic> json) {
    return EnumAttribute(
      json['name'],
      json['values'].cast<String>()
    );
  }
}

class ListAttribute extends ValueAttribute {

  ListAttribute(String name, Type type, List<String> values) : super(name, type, values);

  Map<String, dynamic> toJson() => <String, dynamic> {
    'name': name,
    'type': type.fullTypeString,
    'values': values,
  };
  factory ListAttribute.fromJson(Map<String, dynamic> json) {
    return ListAttribute(
      json['name'],
      Type(json['type']),
      json['values'].cast<String>()
    );
  }
}