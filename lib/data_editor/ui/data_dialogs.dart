import 'package:flutter_manager/data_editor/data_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_skeleton/locator.dart';
import 'package:provider/provider.dart';

class DataDialogButton extends StatelessWidget {

  final String text;
  final Color bgColor;
  final void Function(Map<String, dynamic> values) onPressed;

  const DataDialogButton({Key key, this.text, this.bgColor = Colors.greenAccent, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      color: bgColor,
      onPressed: () {
        final _DataDialogState dialogState = context.findAncestorStateOfType<_DataDialogState>();
        onPressed(dialogState._createValuesMap());
      },
    );
  }
}


class DataDialog extends StatefulWidget {

  final Map<String, String> fields;
  final Map<String, bool> checkboxes;
  final List<Widget> Function(
      BuildContext context,
      Map<String, dynamic> values) buttonsBuilder;

  const DataDialog({Key key, this.fields, this.checkboxes, this.buttonsBuilder}) : super(key: key);

  static Widget buildButton({BuildContext context, String text, Function onPressed, Color bgColor = Colors.greenAccent}) {
    return RaisedButton(
      child: Text(text),
      color: bgColor,
      onPressed: onPressed,
    );
  }

  static void show({BuildContext context, Widget dialog}) {
    showDialog(
      context: context,
      builder: (_) {
        return MultiProvider(
            providers: [
              ChangeNotifierProvider.value(
                value: context.get<EditableData>(),
              ),
              ChangeNotifierProvider.value(
                value: context.get<SelectedObject>(),
              ),
            ],
            child: dialog
        );
      },
    );
  }

  @override
  _DataDialogState createState() => _DataDialogState();
}

class _DataDialogState extends State<DataDialog> {

  Map<String, TextEditingController> _fieldControllers;
  Map<String, bool> _checkboxes;

  @override
  void initState() {
    _fieldControllers = {};
    widget.fields.forEach((key, value) {
      _fieldControllers[key] = TextEditingController(text: value);
    });
    if (widget.checkboxes != null) {
      _checkboxes = Map.from(widget.checkboxes);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final checkboxKeys = _checkboxes?.keys?.toList();

    return Center(
        child: Material(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildFields(context)
                ),
                if (checkboxKeys != null) ...{
                  Column(
                    children: List.generate(checkboxKeys.length, (index) {
                      String checkboxKey = checkboxKeys[index];
                      final checkboxValue = _checkboxes[checkboxKey];

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(checkboxKey),
                          Checkbox(
                            value: checkboxValue,
                            onChanged: (bool value) {
                              setState(() {
                                _checkboxes[checkboxKey] = !checkboxValue;
                              });
                            },
                          ),
                        ],
                      );
                    })
                  )

//                  Column(
//                    mainAxisSize: MainAxisSize.min,
//                    children: List.generate(checkBoxKeys.length)
//
//                    children: <Widget>[
//                      for (int i = 0; i < checkboxKeys.length; i++) ...{
////                        String checkboxKey = checkboxKeys[i];
////                        final checkboxValue = checkboxValues[checkboxKey];
//
//                      }
//                    ],
//                  ),
                },
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (Widget widget in widget.buttonsBuilder(context, _createValuesMap())) ...{
                      widget,
                      SizedBox(width: 20)
                    }
                  ]
                )
              ],
            ),
          ),
        )
    );
  }

  Map<String, dynamic> _createValuesMap() {
    final map = <String, dynamic>{};
    _fieldControllers?.forEach((key, controller) {
      map[key] = controller.text;
    });
    _checkboxes?.forEach((key, value) {
      map[key] = value;
    });
    return map;
  }

  _buildFields(BuildContext context) {
    final list = <Widget>[];
    _fieldControllers.forEach((fieldName, controller) {
      list.add(
        SizedBox(
          width: 300,
          child: TextField(
            controller: controller,
            style: TextStyle(
              fontSize: 25,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              labelText: fieldName,
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                  borderSide: BorderSide(color: Colors.blue)
              ),
              filled: true,
            ),
          ),
        )
      );
    });
    return list;
  }

  @override
  void dispose() {
    _fieldControllers.values.forEach((controller) {
      controller.dispose();
    });
    super.dispose();
  }
}