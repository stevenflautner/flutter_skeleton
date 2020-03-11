import 'package:flutter_manager/data_editor/data_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_managed/locator.dart';
import 'package:provider/provider.dart';

class DataDialog extends StatefulWidget {

  final Map<String, String> fields;
  final List<Widget> Function(
      BuildContext context,
      Map<String, TextEditingController> controllers) buttonsBuilder;

  const DataDialog({Key key, this.fields, this.buttonsBuilder}) : super(key: key);

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

  Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    _controllers = {};
    widget.fields.forEach((key, value) {
      _controllers[key] = TextEditingController(text: value);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (Widget widget in widget.buttonsBuilder(context, _controllers)) ...{
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

  _buildFields(BuildContext context) {
    final list = <Widget>[];
    _controllers.forEach((fieldName, controller) {
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
    _controllers.values.forEach((controller) {
      controller.dispose();
    });
    super.dispose();
  }
}