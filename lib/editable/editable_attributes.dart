import 'package:flutter/material.dart';
import 'package:flutter_managed/locator.dart';
import 'package:flutter_manager/data_editor/data_editor.dart';
import 'package:flutter_manager/editable/editable_views.dart';
import 'package:flutter_manager/entities.dart';
import 'package:flutter_manager/logic/app.dart';

class EditableAttributes extends EditableData<Attribute> {

  Attribute add(String attrName, String typeString) {
    Attribute attr;
    final type = Type(typeString);
    if (type.baseType.contains('List')) {
      attr = ListAttribute(attrName, type, []);
      getData().add(attr);
    }
    else {
      attr = EnumAttribute(attrName, []);
      getData().add(attr);
    }
    notify();
    return attr;
  }

  void addValue(Attribute attr, String value) {
    (attr as ValueAttribute).values.add(value);
    notify();
  }

  void removeValue(Attribute attr, String value) {
    (attr as ValueAttribute).values.remove(value);
    notify();
  }

  void modifyValue(Attribute attr, String oldValue, String newValue) {
    final valueAttr = attr as ValueAttribute;
    final index = valueAttr.values.indexOf(oldValue);

    removeValue(valueAttr, oldValue);
    valueAttr.values.insert(index, newValue);
    notify();
  }

  void modifyAttr(Attribute attr, String newAttrName) {
    attr.name = newAttrName;
    notify();
  }

  @override
  String writeServerHead() {
    return 'package ${get<Application>().serverKotlinPackage}';
  }

  @override
  String writeServerObjString(Attribute attr) {
    if (attr is EnumAttribute) {
      final values = writeFor(attr.values, 1, ',\n', (String value) {
        return value.toUpperCase();
      });

      return
'''
enum class ${attr.name} {
  $values;
  companion object
}
''';
    }
    if (attr is ListAttribute) {
      final values = writeFor(attr.values, 1, ',\n', (String value) {
        return '\"$value\"';
      });

      return
'''
val ${attr.name} = arrayOf(
  $values
)

class ${attr.name}Serializer : JsonSerializer<${attr.type.subtype.baseType}>() {
    override fun serialize(value: ${attr.type.subtype.baseType}, gen: JsonGenerator, serializers: SerializerProvider) {
        gen.writeNumber(${attr.name}.indexOf(value))
    }
}
''';
    }
  }

  @override
  String writeClientObjString(Attribute attr) {
    if (attr is EnumAttribute) {
      final values = writeFor(attr.values, 1, ',\n', (String value) {
        return value;
      });

      return
'''
enum ${attr.name} {
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
const ${attr.name} = [
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
  List<Attribute> getData() => get<Application>().attributes;

  @override
  Widget buildAddObjDialog(BuildContext context) => AddAttributeDialog();

  @override
  Widget buildObjView() {
    return AttributeObjView();
  }
}