import 'package:flutter_manager/data_editor/data_editor.dart';
import 'package:flutter_manager/editable/editable_views.dart';
import 'package:flutter_manager/entities.dart';
import 'package:flutter_manager/logic/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_managed/locator.dart';

class EditableEntities extends EditableData<Map<String, String>> {

  void add(String entityName) {
    getData()[entityName] = {};
    notify();
  }

  void addField(String entityName, String newFieldName, String newfieldType) {
    getData()[entityName][newFieldName] = newfieldType;
    notify();
  }

  void modifyField(String entityName, String fieldName, String newFieldName, String newfieldType) {
    removeField(entityName, fieldName);
    addField(entityName, newFieldName, newfieldType);
    notify();
  }

  void removeField(String entityName, String fieldName) {
    getData()[entityName].remove(fieldName);
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
    return 'import ${get<Application>().serverKotlinPackage}.*';
  }

  @override
  String writeClientObjString(String entityName, Map<String, String> entityFields) {
    final fieldNames = entityFields.keys.toList();

    final fields = writeFor(fieldNames, 1, '\n', (fieldName) {
      final fieldType = Type(entityFields[fieldName]);
      final attr = get<Application>().attributes[fieldType.baseType];

      if (fieldType.baseType == 'Units') {
          print(attr);
          print(attr?.type?.subtype);
      }
      if (attr != null && attr.type.subtype != null) {
        return 'final ${attr.type.subtype.dartString} $fieldName;';
      }

      return 'final ${fieldType.dartString} $fieldName;';
    });

    final constructor = writeFor(fieldNames, 0, ', ', (fieldName) {
      return 'this.$fieldName';
    });

    final toJson = writeFor(fieldNames, 2, ',\n', (fieldName) {
      final fieldType = entityFields[fieldName];
      final attr = get<Application>().attributes[fieldType];

      if (attr != null) {
        if (attr is EnumAttribute) {
          return "'$fieldName': $fieldName.index";
        }
        if (attr is ListAttribute) {
          return "'$fieldName': $fieldType.indexOf($fieldName)";
        }
      }

      return "'$fieldName': $fieldName";
    });

    final fromJson = writeFor(fieldNames, 3, ',\n', (fieldName) {
      final fieldType = Type(entityFields[fieldName]);

      final attr = get<Application>().attributes[fieldType.baseType];
      if (attr != null) {
        if (attr is EnumAttribute) {
          return "${fieldType.baseType}.values[json['$fieldName'] as int]";
        }
        if (attr is ListAttribute) {
          return "${fieldType.baseType}[json['$fieldName'] as int]";
        }
      }

      if (fieldType.subtype != null) {
        if (fieldType.subtype.isPrimitive) {
          return "json['$fieldName'].cast<${fieldType.subtype.dartString}>()";
        } else {
          final attr = get<Application>().attributes[fieldType.subtype.baseType];

          if (attr != null) {
            String attrFromJson;
            if (attr is EnumAttribute) {
              attrFromJson = "${fieldType.subtype.baseType}.values[json as int]";
            }
            else if (attr is ListAttribute) {
              attrFromJson = "${fieldType.subtype.baseType}[json as int]";
            }
            return "(json['$fieldName'] as List).map((json) => $attrFromJson)";
          }

          return "(json['$fieldName'] as List).map((json) => ${fieldType.subtype.dartString}.fromJson(json))";
        }
      } else {
        return "json['$fieldName']";
      }
    });

    return
'''
class $entityName {

  $fields

  $entityName($constructor);
  
  Map<String, dynamic> toJson() => <String, dynamic> {
    $toJson
  };
  
  factory $entityName.fromJson(Map<String, dynamic> json) =>
    $entityName(
      $fromJson
    );
}
'''.trim();
  }

  @override
  String writeServerObjString(String entityName, Map<String, String> fields) {
    final fieldsString = writeFor(fields.keys.toList(), 1, ', ', (String fieldName) {
      final fieldType = fields[fieldName];
      return 'val $fieldName: $fieldType';
    }, useSpaces: true);

    return 'data class $entityName($fieldsString)';
  }

  @override
  String writeFileTo(bool isClient) {
    if (isClient) {
      return 'entities.g.dart';
    }
    return 'entities.g.kt';
  }

  @override
  Map<String, Map<String, String>> getData() {
    return get<Application>().entities;
  }

  @override
  Widget buildObjView() {
    return EntityObjView();
  }

  @override
  Widget buildAddObjDialog(BuildContext context) => AddEntityDialog();
}