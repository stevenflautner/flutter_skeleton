import 'package:flutter_manager/data_editor/data_editor.dart';
import 'package:flutter_manager/editable/editable_views.dart';
import 'package:flutter_manager/entities.dart';
import 'package:flutter_manager/logic/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_managed/locator.dart';

class EditableEntities extends EditableData<Entity> {

  Entity add(String entityName) {
    final entity = Entity(entityName, []);
    getData().add(entity);
    notify();
    return entity;
  }

  void modifyEntity(Entity entity, String newEntityName) {
    entity.name = newEntityName;
    notify();
  }

  void addField(Entity entity, String newFieldName, String newfieldType) {
    entity.fields.add(EntityField(newFieldName, Type(newfieldType), false, false));
    notify();
  }

  void modifyField(EntityField field, String newFieldName, String newfieldType, bool newServerModifiable, bool newClientModifiable) {
    field.name = newFieldName;
    field.type = Type(newfieldType);
    field.serverModifiable = newServerModifiable;
    field.clientModifiable = newClientModifiable;
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
import 'attributes.g.dart';
''';
  }

  @override
  String writeServerHead() {
    return 'package ${get<Application>().serverKotlinPackage}';
  }

  @override
  String writeClientObjString(Entity entity) {
    final fields = writeFor(entity.fields, 1, '\n', (EntityField field) {
      final attr = _findAttr(field);

      String leadingFinal = field.clientModifiable ? '' : 'final ';

      if (attr != null && attr.type.subtype != null) {
        return '$leadingFinal${attr.type.subtype.dartString} ${field.name};';
      }

      return '$leadingFinal${field.type.dartString} ${field.name};';
    });

    final constructor = writeFor(entity.fields, 0, ', ', (EntityField field) {
      return 'this.${field.name}';
    });

    final toJson = writeFor(entity.fields, 2, ',\n', (EntityField field) {
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

    final fromJson = writeFor(entity.fields, 3, ',\n', (EntityField field) {
      final attr = _findAttr(field);

      if (attr != null) {
        if (attr is EnumAttribute) {
          return "${attr.type.baseType}.values[json['${field.name}'] as int]";
        }
        if (attr is ListAttribute) {
          return "${attr.type.baseType}[json['${field.name}'] as int]";
        }
      }

      if (field.type.subtype != null) {
        if (field.type.subtype.isPrimitive) {
          return "json['${field.name}'].cast<${field.type.subtype.dartString}>()";
        } else {
          final attr = get<Application>().attributes.firstWhere((attr) => attr.name == field.type.subtype.fullTypeString, orElse: () => null);

          if (attr != null) {
            String attrFromJson;
            if (attr is EnumAttribute) {
              attrFromJson = "${attr.type.baseType}.values[json as int]";
            }
            else if (attr is ListAttribute) {
              attrFromJson = "${attr.type.baseType}[json as int]";
            }
            return "(json['${field.name}'] as List).map((json) => $attrFromJson)";
          }

          return "(json['${field.name}'] as List).map((json) => ${field.type.subtype.dartString}.fromJson(json))";
        }
      } else {
        return "json['${field.name}']";
      }
    });

    return
'''
class ${entity.name} {

  $fields

  ${entity.name}($constructor);
  
  Map<String, dynamic> toJson() => <String, dynamic> {
    $toJson
  };
  
  factory ${entity.name}.fromJson(Map<String, dynamic> json) =>
    ${entity.name}(
      $fromJson
    );
}
'''.trim();
  }

  Attribute _findAttr(EntityField field) => get<Application>().attributes.firstWhere((attr) => attr.name == field.name, orElse: () => null);

  @override
  String writeServerObjString(Entity entity) {
    final fieldsString = writeFor(entity.fields, 0, ', ', (EntityField field) {
      final attr = get<Application>().attributes.firstWhere((attr) => attr.type.fullTypeString == field.type.fullTypeString, orElse: () => null);

      String leadingType = field.serverModifiable ? 'var' : 'val';

      if (attr != null && attr is ListAttribute) {
        return '$leadingType ${field.name}: ${attr.type.subtype.baseType}';
      }

      return '$leadingType ${field.name}: ${field.type.dartString}';
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