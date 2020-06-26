import 'package:flutter_manager/data_editor/data_editor.dart';
import 'package:flutter_manager/data_editor/ui/data_dialogs.dart';
import 'package:flutter_manager/ui/column_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_skeleton/locator.dart';
import 'package:provider/provider.dart';

class EditableDataView extends StatefulWidget {

  EditableDataView({ Key key }): super(key: key);

  @override
  _EditableDataViewState createState() => _EditableDataViewState();

}

class _EditableDataViewState extends State<EditableDataView> {

  @override
  Widget build(BuildContext context) {
    final data = context.depends<EditableData>().getData();

    return ChangeNotifierProvider(
      create: (_) => SelectedObject(),
      child: Builder(
        builder: (context) {
          final selectedObj = context.depends<SelectedObject>();

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                    color: Colors.grey[300]
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(data.length, (index) {
                            final obj = data[index];

                            return GestureDetector(
                              onTap: () {
                                context.get<SelectedObject>().select(obj);
                              },
                              child: ColumnButton(
                                text: obj.name,
                                selected: selectedObj.obj == obj
                              )
                            );
                          })
                      ),
                      _buildNewObjButton(context)
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ObjView(),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildNewObjButton(BuildContext context) {
    return ObjView.buildNewButton(
      context: context,
      dialog: context.get<EditableData>().buildAddObjDialog(context),
    );
  }
}

class ObjView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selectedObj = context.depends<SelectedObject>();

    if (selectedObj.obj == null)
      return SizedBox();

    return context.get<EditableData>().buildObjView();
  }

  static Widget buildNewButton({BuildContext context, Widget dialog}) {
    return IconButton(
      icon: Icon(
        Icons.add,
        size: 26,
      ),
      color: Colors.grey[500],
      onPressed: () {
        DataDialog.show(
          context: context,
          dialog: dialog
        );
      },
    );
  }

  static Widget buildEditButton({BuildContext context, DataDialog dialog}) {
    return RawMaterialButton(
      shape: CircleBorder(),
      child: Icon(
        Icons.edit,
        color: Colors.blue,
        size: 35.0,
      ),
      onPressed: () {
        DataDialog.show(
          context: context,
          dialog: dialog
        );
      },
      elevation: 2.0,
      fillColor: Colors.white,
      padding: const EdgeInsets.all(15.0),
    );
  }
}

