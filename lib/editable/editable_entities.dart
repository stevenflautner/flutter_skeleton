import 'package:flutter_manager/data_editor/data_editor.dart';
import 'package:flutter_manager/editable/editable_views.dart';
import 'package:flutter_manager/entities.dart';
import 'package:flutter_manager/framework/skeleton.dart';
import 'package:flutter_manager/logic/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_managed/locator.dart';

class EditableEntities extends EditableData<Entity> {

  EditableEntities() {
//    GrpcBone().writeAll();
  }

  Entity add(String entityName) {
    final entity = Entity(entityName, [], false);
    getData().add(entity);
    notify();
    return entity;
  }

  void modifyEntity(Entity entity, String newEntityName, bool newCustomClientDeserializer) {
    entity.name = newEntityName;
    entity.customClientDeserializer = newCustomClientDeserializer;
    notify();
  }

  void addField(Entity entity, String newFieldName, String newfieldType) {
    entity.fields.add(EntityField(newFieldName, Type(newfieldType), false, false, true, true));
    notify();
  }

  void modifyField(EntityField field, String newFieldName, String newfieldType, bool newServerModifiable, bool newClientModifiable, bool newServerProperty, bool newClientPropertyy) {
    field.name = newFieldName;
    field.type = Type(newfieldType);
    field.serverModifiable = newServerModifiable;
    field.clientModifiable = newClientModifiable;
    field.serverProperty = newServerProperty;
    field.clientProperty = newClientPropertyy;
    notify();
  }

  void removeField(Entity entity, EntityField field) {
    entity.fields.remove(field);
    notify();
  }

  @override
  String writeClientHead() {
    return
'''
part of '../entities.dart';
''';
  }

  @override
  String writeServerHead() {
    return
'''
package ${serverDataKotlinPackage}

import com.fasterxml.jackson.databind.annotation.JsonSerialize
'''.trim();
  }

  @override
  String writeClientObjString(Entity entity) {
    final filteredFields = entity.fields.where((field) => field.clientProperty).toList();

    final fields = writeFor(filteredFields, 1, '\n', (EntityField field) {
      final attr = _findAttr(field);

      String leadingFinal = field.clientModifiable ? '' : 'final ';

      if (attr != null && attr.type.subtype != null) {
        return '$leadingFinal${attr.type.subtype.dartString} ${field.name};';
      }

      return '$leadingFinal${field.type.dartString} ${field.name};';
    });

    final constructor = writeFor(filteredFields, 0, ', ', (EntityField field) {
      return 'this.${field.name}';
    });

    final toJson = writeFor(filteredFields, 2, ',\n', (EntityField field) {
      final attr = _findAttr(field);

      if (attr != null) {
        if (attr is EnumAttribute) {
          return "'${field.name}': ${field.name}.index";
        }
        if (attr is ListAttribute) {
          return "'${field.name}': ${field.type.dartString}.indexOf(${field.name})";
        }
      }

      return "'${field.name}': ${field.name}";
    });

    String fromJson = _writeFromJson(entity, filteredFields);

    return
'''
class ${entity.name} extends Entity {

  $fields

  ${entity.name}($constructor);
  
  Map<String, dynamic> toJson() => <String, dynamic> {
    $toJson
  };
  
  $fromJson
}
'''.trim();
  }

  String _writeFromJson(Entity entity, List<EntityField> filteredFields) {
    final buffer = StringBuffer();

    String fromJsonPrivate = entity.customClientDeserializer ? '_' : '';
    String fromJsonFields = _writeFromJsonFields(entity, filteredFields);

    buffer.write(
'''
  factory ${entity.name}.${fromJsonPrivate}fromJson(Map<String, dynamic> json) =>
    ${entity.name}(
      $fromJsonFields
    );
'''.trim());

    if (entity.customClientDeserializer) {
      buffer..write('\n\n')
            ..write(
'''
  factory ${entity.name}.fromJson(Map<String, dynamic> json) => _${entity.name}FromJson(json);
'''.trim());
    }
    return buffer.toString();
  }

  String _writeFromJsonFields(Entity entity, List<EntityField> filteredFields) {
    return writeFor(filteredFields, 3, ',\n', (EntityField field) {
      if (!field.clientProperty) return null;

      final attr = _findAttr(field);

      if (attr != null) {
        if (attr is EnumAttribute) {
          return "${attr.name}.values[json['${field.name}'] as int]";
        }
        if (attr is ListAttribute) {
          return "${attr.name}[json['${field.name}'] as int]";
        }
      }

      if (field.type.subtype != null) {
        if (field.type.subtype.isPrimitive) {
          return "json['${field.name}'].cast<${field.type.subtype.dartString}>()";
        } else {
          final attr = get<Application>().attributes.firstWhere((attr) => attr.name == field.type.subtype.baseType, orElse: () => null);

          if (attr != null) {
            String attrFromJson;
            if (attr is EnumAttribute) {
              attrFromJson = "${attr.name}.values[json as int]";
            }
            else if (attr is ListAttribute) {
              attrFromJson = "${attr.name}[json as int]";
            }
            return "(json['${field.name}'] as List).map((json) => $attrFromJson).toList()";
          }

          return "(json['${field.name}'] as List).map((json) => ${field.type.subtype.dartString}.fromJson(json)).toList()";
        }
      } else {
        if (field.type.isPrimitive) {
          return "json['${field.name}']";
        } else {
          return "${field.type.baseType}.fromJson(json['${field.name}'])";
        }
      }
    });
  }

  Attribute _findAttr(EntityField field) => get<Application>().attributes.firstWhere((attr) => attr.name == field.type.baseType, orElse: () => null);

  @override
  String writeServerObjString(Entity entity) {
    final fieldsString = writeFor(entity.fields, 0, ', ', (EntityField field) {
      final attr = get<Application>().attributes.firstWhere((attr) => attr.name == field.type.baseType, orElse: () => null);

      String leadingType = field.serverModifiable ? 'var' : 'val';

      if (attr != null && attr is ListAttribute) {
        String serializer = "@JsonSerialize(using = ${attr.name}Serializer::class)";
        return '$serializer $leadingType ${field.name}: ${attr.type.subtype.baseType}';
      }

      return '$leadingType ${field.name}: ${field.type.fullTypeString}';
    });

    return 'data class ${entity.name}($fieldsString)';
  }

  @override
  String writeFileTo(bool isClient) {
    if (isClient) {
      return 'entities.g.dart';
    }
    return 'entities.g.kt';
  }

  @override
  List<Entity> getData() {
    return get<Application>().entities;
  }

  @override
  Widget buildObjView() {
    return EntityObjView();
  }

  @override
  Widget buildAddObjDialog(BuildContext context) => AddEntityDialog();
}