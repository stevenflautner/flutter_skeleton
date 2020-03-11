import 'package:flutter_manager/data_editor/data_editor.dart';
import 'package:flutter_manager/data_editor/ui/data_dialogs.dart';
import 'package:flutter_manager/data_editor/ui/data_view.dart';
import 'package:flutter_manager/editable/editable_attributes.dart';
import 'package:flutter_manager/editable/editable_entities.dart';
import 'package:flutter_manager/entities.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_managed/locator.dart';

class EntityObjView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selectedObj = context.get<SelectedObject>();
    final editableData = context.get<EditableData>() as EditableEntities;
    final entity = editableData.getData()[selectedObj.name];

    final fieldNameList = <Widget>[];
    final fieldTypeList = <Widget>[];

    entity.forEach((fieldName, fieldType) {
      void onTap() {
        showDialog(
          context: context,
          builder: (_) {
            return ChangeNotifierProvider<EditableData>.value(
              value: editableData,
              child: DataDialog(
                fields: {
                  'Name': fieldName,
                  'Type': fieldType
                },
                buttonsBuilder: (context, controllers) {
                  return [
                    DataDialog.buildButton(
                      context: context,
                      text: 'Save',
                      onPressed: () {
                        final newFieldName = controllers['Name'].text;
                        final newFieldType = controllers['Type'].text;

                        (context.get<EditableData>() as EditableEntities)
                            .modifyField(selectedObj.name, fieldName, newFieldName, newFieldType);
                        Navigator.pop(context);
                      }
                    ),
                    DataDialog.buildButton(
                        context: context,
                        text: 'Delete',
                        bgColor: Colors.red,
                        onPressed: () {
                          editableData.removeField(selectedObj.name, fieldName);
                          Navigator.pop(context);
                        }
                    )
                  ];
                },
              ),
            );
          },
        );
      }

      fieldNameList.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: GestureDetector(
              onTap: onTap,
              child: Text('$fieldName:', style: TextStyle(
                  fontSize: 25
              )),
            ),
          )
      );
      fieldTypeList.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: GestureDetector(
              onTap: onTap,
              child: Text(fieldType, style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold
              )),
            ),
          )
      );
    });

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
//            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ObjView.buildEditButton(
                context: context,
                dialog: _buildEditEntityDialog(context, selectedObj.name, entity)
              ),
              SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: fieldNameList
                  ),
                  SizedBox(width: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: fieldTypeList
                  ),
                ],
              ),
              ObjView.buildNewButton(
                  context: context,
                  dialog: DataDialog(
                    fields: const {
                      'Name': null,
                      'Type': null,
                    },
                    buttonsBuilder: (context, controllers) {
                      return [
                        DataDialog.buildButton(
                            context: context,
                            text: 'Save',
                            onPressed: () {
                              editableData.addField(
                                  selectedObj.name,
                                  controllers['Name'].text,
                                  controllers['Type'].text
                              );
                              Navigator.pop(context);
                            }
                        )
                      ];
                    },
                  )
              )
            ],
          ),
        ),
      ),
    );
  }

  DataDialog _buildEditEntityDialog(BuildContext context, String entityName, Map<String, String> entity) {
    final entityNameId = 'Entity name';

    return DataDialog(
      fields: {
        entityNameId: entityName,
      },
      buttonsBuilder: (context, controllers) {
        return [
          DataDialog.buildButton(
              context: context,
              text: 'Save',
              onPressed: () {
                final newEntityName = controllers[entityNameId].text;
//                final newAttrType = controllers['Type'].text;

//                (context.get<EditableData>() as EditableEntities)
//                    .modifyEntity(attrName, newAttrName);
                context.get<SelectedObject>().select(newEntityName);
                Navigator.pop(context);
              }
          ),
          DataDialog.buildButton(
            context: context,
            text: 'Delete',
            bgColor: Colors.red,
            onPressed: () {
              context.get<EditableData>().remove(context.get<SelectedObject>().name);
              context.get<SelectedObject>().select(null);
              Navigator.pop(context);
            }
          )
        ];
      },
    );
  }
}

class AttributeObjView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selectedObj = context.get<SelectedObject>();
    final editableData = context.get<EditableData>() as EditableAttributes;
    final attribute = editableData.getData()[selectedObj.name];

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  ObjView.buildEditButton(
                    context: context,
                    dialog: _buildEditDialog(context, selectedObj.name, attribute)
                  ),
                  SizedBox(width: 10),
                  Text('Type: ${attribute.type.fullTypeString}', style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20
                  )),
                ],
              ),
              SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildFieldList(context, selectedObj.name, attribute)
              ),
              ObjView.buildNewButton(
                context: context,
                dialog: DataDialog(
                  fields: const {
                    'Value': null
                  },
                  buttonsBuilder: (context, controllers) {
                    return [
                      DataDialog.buildButton(
                        context: context,
                        text: 'Save',
                        onPressed: () {
                          final objName = context.get<SelectedObject>().name;
                          editableData.addValue(objName, controllers['Value'].text);
                          Navigator.of(context).pop();
                        }
                      )
                    ];
                  },
                )
              )
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFieldList(BuildContext context, String attrName, Attribute attribute) {
    if (attribute is ValueAttribute) {
      return [
        for (String value in attribute.values) ...{
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: GestureDetector(
              onTap: () {
                DataDialog.show(
                  context: context,
                  dialog: DataDialog(
                    fields: {
                      'Value': value
                    },
                    buttonsBuilder: (context, controllers) {
                      return [
                        DataDialog.buildButton(
                          context: context,
                          text: 'Save',
                          onPressed: () {
                            final newValue = controllers['Value'].text;
                            (context.get<EditableData>() as EditableAttributes)
                                .modifyValue(attrName, value, newValue);
                            Navigator.of(context).pop();
                          }
                        ),
                        DataDialog.buildButton(
                          context: context,
                          text: 'Delete',
                          bgColor: Colors.red,
                          onPressed: () {
                            (context.get<EditableData>() as EditableAttributes)
                                .removeValue(attrName, value);
                            Navigator.of(context).pop();
                          }
                        )
                      ];
                    },
                  )
                );
              },
              child: Text(value, style: TextStyle(
                fontSize: 25
              )),
            ),
          )
        }
      ];
    }
    throw 'no impl found';
  }

  DataDialog _buildEditDialog(BuildContext context, String attrName, Attribute attr) {
    final attrNameId = 'Attribute name';

    return DataDialog(
      fields: {
        attrNameId: attrName,
      },
      buttonsBuilder: (context, controllers) {
        return [
          DataDialog.buildButton(
            context: context,
            text: 'Save',
            onPressed: () {
              final newAttrName = controllers[attrNameId].text;
//                final newAttrType = controllers['Type'].text;

              (context.get<EditableData>() as EditableAttributes)
                  .modifyAttr(attrName, newAttrName);
              context.get<SelectedObject>().select(newAttrName);
              Navigator.pop(context);
            }
          ),
          DataDialog.buildButton(
            context: context,
            text: 'Delete',
            bgColor: Colors.red,
            onPressed: () {
              context.get<EditableData>().remove(context.get<SelectedObject>().name);
              context.get<SelectedObject>().select(null);
              Navigator.pop(context);
            }
          )
        ];
      },
    );
  }
}

class AddAttributeDialog extends StatelessWidget {
  final attrNameId = 'Attribute name';
  final attrTypeId = 'Attribute type';

  @override
  Widget build(BuildContext context) {
    return DataDialog(
      fields: {
        attrNameId: null,
        attrTypeId: null
      },
      buttonsBuilder: (context, controllers) {
        return [
          DataDialog.buildButton(
            context: context,
            text: 'Save',
            onPressed: () {
              final attrName = controllers[attrNameId].text;
              final attrType = controllers[attrTypeId].text;

              (context.get<EditableData>() as EditableAttributes).add(attrName, attrType);
              context.get<SelectedObject>().select(attrName);
              Navigator.pop(context);
            }
          )
        ];
      },
    );
  }
}
class AddEntityDialog extends StatelessWidget {
  final entityNameId = 'Entity name';

  @override
  Widget build(BuildContext context) {
    return DataDialog(
      fields: {
        entityNameId: null
      },
      buttonsBuilder: (context, controllers) {
        return [
          DataDialog.buildButton(
              context: context,
              text: 'Save',
              onPressed: () {
                final entityName = controllers[entityNameId].text;

                (context.get<EditableData>() as EditableEntities).add(entityName);
                context.get<SelectedObject>().select(entityName);
                Navigator.pop(context);
              }
          )
        ];
      },
    );
  }
}
