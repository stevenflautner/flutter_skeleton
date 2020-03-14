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
    final entity = selectedObj.obj as Entity;

    final fieldNameList = <Widget>[];
    final fieldTypeList = <Widget>[];

    const nameId = 'Name';
    const typeId = 'Type';
    const serverModifiableId = 'Server modifiable';
    const clientModifiableId = 'Client modifiable';
    entity.fields.forEach((EntityField field) {
      void onTap() {
        showDialog(
          context: context,
          builder: (_) {
            return ChangeNotifierProvider<EditableData>.value(
              value: editableData,
              child: DataDialog(
                fields: {
                  nameId: field.name,
                  typeId: field.type.fullTypeString
                },
                checkboxes: {
                  serverModifiableId: field.serverModifiable,
                  clientModifiableId: field.clientModifiable
                },
                buttonsBuilder: (context, values) {
                  return [
                    DataDialogButton(
                      text: 'Save',
                      onPressed: (values) {
                        final newFieldName = values[nameId].toString();
                        final newFieldType = values[typeId].toString();
                        final newServerModifiable = values[serverModifiableId] as bool;
                        final newClientModifiable = values[clientModifiableId] as bool;

                        (context.get<EditableData>() as EditableEntities)
                            .modifyField(field, newFieldName, newFieldType, newServerModifiable, newClientModifiable);
                        Navigator.pop(context);
                      }
                    ),
                    DataDialogButton(
                      text: 'Delete',
                      bgColor: Colors.red,
                      onPressed: (values) {
                        editableData.removeField(entity, field);
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
              child: Text('${field.name}:', style: TextStyle(
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
              child: Text(field.type.fullTypeString, style: TextStyle(
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
                dialog: _buildEditEntityDialog(context, entity)
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
                    buttonsBuilder: (context, values) {
                      return [
                        DataDialogButton(
                          text: 'Save',
                          onPressed: (values) {
                            editableData.addField(
                                entity,
                                values['Name'].toString(),
                                values['Type'].toString()
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

  DataDialog _buildEditEntityDialog(BuildContext context, Entity entity) {
    final entityNameId = 'Entity name';
    final customClientDeserializerId = 'Custom client deserializer';

    return DataDialog(
      fields: {
        entityNameId: entity.name,
      },
      checkboxes: {
        customClientDeserializerId: entity.customClientDeserializer,
      },
      buttonsBuilder: (context, values) {
        return [
          DataDialogButton(
            text: 'Save',
            onPressed: (values) {
              final newEntityName = values[entityNameId].toString();
              final newCustomClientDeserializer = values[customClientDeserializerId] as bool;
//                final newAttrType = controllers['Type'].text;

              (context.get<EditableData>() as EditableEntities)
                  .modifyEntity(entity, newEntityName, newCustomClientDeserializer);
              context.get<SelectedObject>().select(entity);
              Navigator.pop(context);
            }
          ),
          DataDialogButton(
            text: 'Delete',
            bgColor: Colors.red,
            onPressed: (values) {
              context.get<EditableData>().remove(entity);
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
    final attr = selectedObj.obj as Attribute;

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
                    dialog: _buildEditDialog(context, attr)
                  ),
                  SizedBox(width: 10),
                  Text('Type: ${attr.type.fullTypeString}', style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20
                  )),
                ],
              ),
              SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildFieldList(context, attr)
              ),
              ObjView.buildNewButton(
                context: context,
                dialog: DataDialog(
                  fields: const {
                    'Value': null
                  },
                  buttonsBuilder: (context, values) {
                    return [
                      DataDialogButton(
                        text: 'Save',
                        onPressed: (values) {
                          editableData.addValue(attr, values['Value'].toString());
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

  List<Widget> _buildFieldList(BuildContext context, Attribute attr) {
    if (attr is ValueAttribute) {
      return [
        for (String value in attr.values) ...{
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
                    buttonsBuilder: (context, values) {
                      return [
                        DataDialogButton(
                          text: 'Save',
                          onPressed: (values) {
                            final newValue = values['Value'].toString();
                            (context.get<EditableData>() as EditableAttributes)
                                .modifyValue(attr, value, newValue);
                            Navigator.of(context).pop();
                          }
                        ),
                        DataDialogButton(
                          text: 'Delete',
                          bgColor: Colors.red,
                          onPressed: (values) {
                            (context.get<EditableData>() as EditableAttributes)
                                .removeValue(attr, value);
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

  DataDialog _buildEditDialog(BuildContext context, Attribute attr) {
    final attrNameId = 'Attribute name';

    return DataDialog(
      fields: {
        attrNameId: attr.name,
      },
      buttonsBuilder: (context, values) {
        return [
          DataDialogButton(
            text: 'Save',
            onPressed: (values) {
              final newAttrName = values[attrNameId].toString();
//                final newAttrType = controllers['Type'].text;

              (context.get<EditableData>() as EditableAttributes)
                  .modifyAttr(attr, newAttrName);
              context.get<SelectedObject>().select(attr);
              Navigator.pop(context);
            }
          ),
          DataDialogButton(
            text: 'Delete',
            bgColor: Colors.red,
            onPressed: (values) {
              context.get<EditableData>().remove(attr);
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
      buttonsBuilder: (context, values) {
        return [
          DataDialogButton(
            text: 'Save',
            onPressed: (values) {
              final attrName = values[attrNameId].toString();
              final attrType = values[attrTypeId].toString();

              final attr = (context.get<EditableData>() as EditableAttributes).add(attrName, attrType);
              context.get<SelectedObject>().select(attr);
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
      buttonsBuilder: (context, values) {
        return [
          DataDialogButton(
            text: 'Save',
            onPressed: (values) {
              final entityName = values[entityNameId].toString();

              final entity = (context.get<EditableData>() as EditableEntities).add(entityName);
              context.get<SelectedObject>().select(entity);
              Navigator.pop(context);
            }
          )
        ];
      },
    );
  }
}

//class EntityFieldDialog extends StatefulWidget {
//
//  final String entityName;
//  final Map<String, String> entity;
//
//  const EntityFieldDialog({Key key, this.entityName, this.entity}) : super(key: key);
//
//  @override
//  _EntityFieldDialogState createState() => _EntityFieldDialogState();
//}
//
//class _EntityFieldDialogState extends State<EntityFieldDialog> {
//  @override
//  Widget build(BuildContext context) {
//    final entityNameId = 'Entity name';
//
//    return DataDialog(
//      fields: {
//        entityNameId: widget.entityName,
//      },
//      buttonsBuilder: (context, controllers) {
//        return [
//          DataDialog.buildButton(
//              context: context,
//              text: 'Save',
//              onPressed: () {
//                final newEntityName = controllers[entityNameId].text;
////                final newAttrType = controllers['Type'].text;
//
////                (context.get<EditableData>() as EditableEntities)
////                    .modifyEntity(attrName, newAttrName);
//                context.get<SelectedObject>().select(newEntityName);
//                Navigator.pop(context);
//              }
//          ),
//          DataDialog.buildButton(
//              context: context,
//              text: 'Delete',
//              bgColor: Colors.red,
//              onPressed: () {
//                context.get<EditableData>().remove(context.get<SelectedObject>().name);
//                context.get<SelectedObject>().select(null);
//                Navigator.pop(context);
//              }
//          )
//        ];
//      },
//    );
//  }
//}