import 'package:flutter_manager/data_editor/data_editor.dart';
import 'package:flutter_manager/data_editor/ui/data_view.dart';
import 'package:flutter_manager/editable/editable_attributes.dart';
import 'package:flutter_manager/editable/editable_entities.dart';
import 'package:flutter_manager/logic/app.dart';
import 'package:flutter_manager/logic/tabs.dart';
import 'package:flutter_manager/logic/widget_library.dart';
import 'package:flutter_manager/ui/column_button.dart';
import 'package:flutter_manager/widget_library/widget_library_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_managed/locator.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          get<Application>().name
        ),
      ),
      backgroundColor: Colors.grey[200],
      body: Row(
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.grey[400]
            ),
            child: Column(
              children: <Widget>[
                MenuElement(
                  title: 'ENTITIES',
                  tab: AppTab.ENTITIES,
                ),
                MenuElement(
                  title: 'ATTRIBUTES',
                  tab: AppTab.ATTRIBUTES,
                ),
                MenuElement(
                  title: 'SERVICES',
                  tab: AppTab.SERVICES,
                ),
                MenuElement(
                  title: 'WIDGET LIBRARY',
                  tab: AppTab.WIDGET_LIBRARY,
                ),
              ],
            ),
          ),
//            Expanded(
//              child: EntitiesContent(),
//            )
          Expanded(
            child: Consumer<Tabs>(
              builder: (context, tabs, child) {
                switch (tabs.selected) {
                  case AppTab.ENTITIES:
                    return ChangeNotifierProvider<EditableData>(
                      key: UniqueKey(),
                      create: (_) => EditableEntities(),
                      child: EditableDataView()
                    );
                  case AppTab.ATTRIBUTES:
                    return ChangeNotifierProvider<EditableData>(
                      key: UniqueKey(),
                      create: (_) => EditableAttributes(),
                      child: EditableDataView()
                    );
                  case AppTab.SERVICES:
                    return SizedBox();
                  case AppTab.WIDGET_LIBRARY:
                    return ChangeNotifierProvider(
                      create: (_) => WidgetLibrary(),
                      child: WidgetLibraryView()
                    );
                }
                return SizedBox();
              },
            )
          )
        ],
      ),
    );
  }
}

class MenuElement extends StatelessWidget {

  final String title;
  final AppTab tab;

  MenuElement({Key key, this.title, this.tab}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<Tabs>(
      builder: (context, tabs, child) {
        return GestureDetector(
          onTap: () {
            context.get<Tabs>().select(tab);
          },
          child: ColumnButton(
            text: title,
            fontSize: 20,
            selected: tabs.selected == tab,
            selectedBgColor: Colors.grey[600],
            selectedFontColor: Colors.white,
          )
//          child: Text(
//            title,
//            style: TextStyle(
//              fontSize: 20,
//              fontWeight: FontWeight.bold,
//              color: Colors.grey[800],
//            ),
//          ),
        );

        return Container(
          decoration: BoxDecoration(
            color: tabs.selected == tab
                ? Colors.grey
                : Colors.transparent
          ),
          width: 200,
          padding: EdgeInsets.all(12),
          child: child,
        );
      },

    );
  }
}