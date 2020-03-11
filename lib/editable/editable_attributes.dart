import 'package:flutter/material.dart';
import 'package:flutter_managed/locator.dart';
import 'package:flutter_manager/data_editor/data_editor.dart';
import 'package:flutter_manager/editable/editable_views.dart';
import 'package:flutter_manager/entities.dart';
import 'package:flutter_manager/logic/app.dart';

class EditableAttributes extends EditableData<Attribute> {

  void add(String attrName, String typeString) {
    final type = Type(typeString);
    if (type.baseType.contains('List')) {
      getData()[attrName] = ListAttribute(type, []);
    }
    else {
      getData()[attrName] = EnumAttribute([]);
    }
    notify();
  }

  void addValue(String attrName, String value) {
    (getData()[attrName] as ValueAttribute).values.add(value);
    notify();
  }

  void removeValue(String attrName, String value) {
    (getData()[attrName] as ValueAttribute).values.remove(value);
    notify();
  }

  void modifyValue(String attrName, String oldValue, String newValue) {
    final attr = getData()[attrName] as ValueAttribute;
    final index = attr.values.indexOf(oldValue);

    removeValue(attrName, oldValue);
    attr.values.insert(index, newValue);
    notify();
  }

  void modifyAttr(String attrName, String newAttrName) {
    final data = getData();
    final currentAttr = data[attrName];
    data.remove(attrName);
    data[newAttrName] = currentAttr;
    notify();
  }

  @override
  String writeServerHead() {
    return 'package ${get<Application>().serverKotlinPackage}';
  }

  @override
  String writeServerObjString(String attrName, Attribute attr) {
    if (attr is EnumAttribute) {
      final values = writeFor(attr.values, 1, ',\n', (String value) {
        return value.toUpperCase();
      });

      return
'''
enum class $attrName {
  $values
}
''';
    }
    if (attr is ListAttribute) {
      final values = writeFor(attr.values, 1, ',\n', (String value) {
        return '\"$value\"';
      });

      return
'''
val $attrName = arrayOf(
  $values
)
''';
    }
  }

  @override
  String writeClientObjString(String attrName, Attribute attr) {
    if (attr is EnumAttribute) {
      final values = writeFor(attr.values, 1, ',\n', (String value) {
        return value;
      });

      return
'''
enum $attrName {
  $values
}
''';
    }

    if (attr is ListAttribute) {
      final values = writeFor(attr.values, 1, ',\n', (String value) {
        return "'$value'";
      });

      return
  '''
const $attrName = [
  $values
];
''';
    }
  }

  @override
  String writeFileTo(bool isClient) {
    return 'attributes.g.${isClient ? 'dart' : 'kt'}';
  }

  @override
  Map<String, Attribute> getData() {
    return get<Application>().attributes;
  }

  @override
  Widget buildAddObjDialog(BuildContext context) => AddAttributeDialog();

  @override
  Widget buildObjView() {
    return AttributeObjView();
  }
}