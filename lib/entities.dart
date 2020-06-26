import 'package:flutter_skeleton/dependency.dart';
import 'package:flutter_manager/framework/skeleton.dart';
import 'package:flutter_manager/pub_dependency/pub_dependency.dart';
import 'package:path/path.dart';
import 'data_editor/data_editor.dart';

class Data {
  final List<Entity> entities;
  final List<Attribute> attributes;
  final List<PubDependency> dependencies;
  final List<Interceptor> interceptors;
  final List<Service> services;

  Data(this.entities, this.attributes, this.dependencies, this.interceptors, this.services);

  Map<String, dynamic> toYaml() => <String, dynamic> {
    'entities': entities.map((e) => e.toYaml()),
    'attributes': attributes.map((e) => e.toYaml()),
    'dependencies': dependencies.map((e) => e.toYaml()),
    'interceptors': interceptors.map((e) => e.toYaml()),
    'services': services.map((e) => e.toYaml()),
  };
  factory Data.fromYaml(dynamic json) {
    return Data(
      (json['entities'] as List)?.map((yaml)
        => Entity.fromYaml(yaml))?.toList() ?? [],
      (json['attributes'] as List)?.map((yaml)
        => Attribute.fromYaml(yaml))?.toList() ?? [],
      (json['dependencies'] as List)?.map((yaml)
        => PubDependency.fromYaml(yaml))?.toList() ?? [],
      (json['interceptors'] as List)?.map((yaml)
        => Interceptor.fromYaml(yaml))?.toList() ?? [],
      []
    );
  }
}

class Entity extends DataElement {
  List<EntityField> fields;
  bool customClientDeserializer;

  Entity(String name, this.fields, this.customClientDeserializer) : super(name);

  Map<String, dynamic> toYaml() {
    final map = <String, dynamic> {
      'name': name,
      'fields': fields,
    };
    if (customClientDeserializer)
      map['customClientDeserializer'] = customClientDeserializer;
    return map;
  }
  factory Entity.fromYaml(dynamic json) {
    final fieldsJson = json['fields'];
    final List<EntityField> fields = fieldsJson != null
        ? (fieldsJson as List).map((json) => EntityField.fromJson(json)).toList()
        : [];

    return Entity(
      json['name'],
      fields,
      json['customClientDeserializer'] ?? false,
    );
  }
}

class EntityField {
  String name;
  Type type;
  bool serverModifiable;
  bool clientModifiable;
  bool serverProperty;
  bool clientProperty;

  EntityField(this.name, this.type, this.serverModifiable, this.clientModifiable, this.serverProperty, this.clientProperty);

  Map<String, dynamic> toJson() => <String, dynamic> {
    'name': name,
    'type': type.fullTypeString,
    'serverModifiable': serverModifiable,
    'clientModifiable': clientModifiable,
    'serverProperty': serverProperty,
    'clientProperty': clientProperty,
  };
  factory EntityField.fromJson(Map<String, dynamic> json) {
    return EntityField(
      json['name'],
      Type(json['type']),
      json['serverModifiable'],
      json['clientModifiable'],
      json['serverProperty'] ?? true,
      json['clientProperty'] ?? true,
    );
  }
}

abstract class Attribute extends DataElement {

  final Type type;

  Attribute(String name, this.type) : super(name);

  factory Attribute.fromYaml(dynamic json) {
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
  Map<String, dynamic> toYaml();
}

abstract class ValueAttribute extends Attribute {

  final List<String> values;

  ValueAttribute(String name, Type type, this.values) : super(name, type);
}

class EnumAttribute extends ValueAttribute {

  EnumAttribute(String name, List<String> values) : super(name, Type('Enum'), values);

  Map<String, dynamic> toYaml() => <String, dynamic> {
    'name': name,
    'type': type.fullTypeString,
    'values': values,
  };
  factory EnumAttribute.fromJson(dynamic json) {
    return EnumAttribute(
      json['name'],
      json['values'].cast<String>()
    );
  }
}

class ListAttribute extends ValueAttribute {

  ListAttribute(String name, Type type, List<String> values) : super(name, type, values);

  Map<String, dynamic> toYaml() => <String, dynamic> {
    'name': name,
    'type': type.fullTypeString,
    'values': values,
  };
  factory ListAttribute.fromJson(dynamic json) {
    return ListAttribute(
      json['name'],
      Type(json['type']),
      json['values'].cast<String>()
    );
  }
}

//class Service extends Element {
//
//  List<String> interceptors = [];
//
//  Service(String name) : super(name);
//
//  Map<String, dynamic> toYaml() => <String, dynamic> {
//    'name': name,
//    'interceptors': interceptors,
//  };
//}

class Service extends DataElement {

  List<String> interceptors = [];

  Service(String name) : super(name);

  Map<String, dynamic> toYaml() => <String, dynamic> {
    'name': name,
    'interceptors': interceptors,
  };
}

class Interceptor extends DataElement {

  Interceptor(String name) : super(name);

  Map<String, dynamic> toYaml() => <String, dynamic> {
    'name': name
  };
  factory Interceptor.fromYaml(dynamic json) {
    return Interceptor(
      json['name']
    );
  }
}