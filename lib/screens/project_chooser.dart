import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_chooser/file_chooser.dart';
import 'package:flutter_managed/locator.dart';
import 'package:flutter_manager/logic/app.dart';
import 'package:flutter_manager/screens/main_screen.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ProjectChooser extends StatefulWidget {
  @override
  _ProjectChooserState createState() => _ProjectChooserState();
}

class _ProjectChooserState extends State<ProjectChooser> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select skeleton.yaml of project'),
      ),
      body: Center(
        child: RaisedButton(
          child: Text('select'),
          onPressed: () async {
            String initialDirectory;
            if (Platform.isMacOS || Platform.isWindows) {
              initialDirectory =
                  (await getApplicationDocumentsDirectory()).path;
            }
            final result = await showOpenPanel(
                allowsMultipleSelection: false,
                initialDirectory: initialDirectory);

            final workingDir = dirname(result.paths[0]);

            await initialize(workingDir);
            Navigator.push(context, MaterialPageRoute(builder: (c) => MainScreen()));
          },
        )
      ),
    );
  }
}
