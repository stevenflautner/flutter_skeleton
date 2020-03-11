import 'package:flutter_manager/logic/app.dart';
import 'package:flutter_manager/logic/widget_library.dart';
import 'package:flutter_manager/pub_dependency/pub_dependency.dart';
import 'package:flutter_manager/ui/column_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_managed/locator.dart';

abstract class WidgetView {
  final String name;

  WidgetView(this.name);

  Widget buildPreview();
}

class ProgressButtonWidgetView extends WidgetView {

  ProgressButtonWidgetView() : super("Progress Button");

  @override
  Widget buildPreview() {
    return RaisedButton(
      child: Text('Some preview'),
      onPressed: () {

      },
    );
  }
}

//class BackButtonWidget extends WidgetView {
//
//  BackButtonWidget() : super("On Back Button Pressed");
//
//  @override
//  Widget buildPreview() {
//    return WillPopScope(
//      onWillPop: (),
//      child: RaisedButton(
//        child: Text('Example button'),
//        onPressed: () {
//
//        },
//      ),
//    );
//  }
//}

class WidgetLibraryView extends StatelessWidget {

  final style = TextStyle(
    fontWeight: FontWeight.bold
  );

  @override
  Widget build(BuildContext context) {
    final widgetLibrary = context.depends<WidgetLibrary>();

    return Row(
      children: <Widget>[
        _buildList(context, widgetLibrary.widgets, 'Project widgets', 300),
        _buildList(context, widgetLibrary.availableWidgets, 'Library', 200),
        Expanded(
          child: _WidgetPreview(),
        )
      ],
    );
  }

  Widget _buildList(BuildContext context, List<PubDependency> dependencies, String title, int colorShade) {
    return Container(
      width: 250,
      color: Colors.grey[colorShade],
      child: Column(
        children: <Widget>[
          Container(
            width: 250,
            padding: const EdgeInsets.all(8.0),
            color: Colors.black45,
            child: Text(title, style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800]
            )),
          ),
          Column(
            children: List.generate(dependencies.length, (index) {
              final dependency = dependencies[index];

              return GestureDetector(
                onTap: () {
                  context.get<WidgetLibrary>().select(dependency);
                },
                child: Consumer<WidgetLibrary>(
                  builder: (context, widgetLibrary, child) {
                    final selected = widgetLibrary.selected;

//                    Container(
//                      width: 200,
//                      padding: const EdgeInsets.all(8.0),
//                      color: selected == entity
//                          ? Colors.grey[400]
//                          : Colors.transparent,
//                      child: Center(
//                        child: Text(entityName, style: TextStyle(
//                            fontWeight: FontWeight.bold,
//                            color: Colors.grey[700],
//                            fontSize: 18
//                        )),
//                      ),
//                    ),

                    return ColumnButton(
                      text: dependency.widgetView.name,
                      selected: selected == dependency,
                    );

                    return Container(
                      width: 200,
                      padding: const EdgeInsets.all(12.0),
                      color: selected == dependency
                            ? Colors.grey[400]
                            : Colors.transparent,
                      child: Center(
                        child: Text(dependency.widgetView.name, style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          fontSize: 18
                        ))
                      ),
                    );
                  },
                ),
              );
            })
          ),
        ],
      ),
    );
  }
}

class _WidgetPreview extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final widgetLibrary = context.depends<WidgetLibrary>();

    if (widgetLibrary.selected == null)
      return Container(
        color: Colors.white,
      );

    final addedToProject = widgetLibrary.widgets.contains(widgetLibrary.selected);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Text(
            'Preview:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(width: 1, color: Colors.grey[400]),
                  borderRadius: BorderRadius.all(Radius.circular(16))
                ),
                child: Center(child: widgetLibrary.selected.widgetView.buildPreview())
              ),
            )
          ),
          RaisedButton(
            onPressed: () {
              if (addedToProject) {
                context.get<WidgetLibrary>().remove(widgetLibrary.selected);
              } else {
                context.get<WidgetLibrary>().add(widgetLibrary.selected);
              }
            },
            color: addedToProject
                ? Colors.red
                : Colors.greenAccent,
            child: Text(
                addedToProject
                    ? 'Remove widget from project'
                    : 'Add Widget to Project'
            ),
          )
        ],
      ),
    );
  }
}
