import 'package:flutter/material.dart';
import 'package:flutter_skeleton/app.dart';
import 'package:flutter_skeleton/dependency.dart';
import 'package:flutter_skeleton/locator.dart';
import 'package:flutter_manager/logic/app.dart';
import 'package:flutter_manager/logic/tabs.dart';
import 'package:flutter_manager/screens/main_screen.dart';
import 'package:flutter_manager/screens/project_chooser.dart';
import 'package:flutter_skeleton/app.dart';
import 'package:flutter_skeleton/dependency.dart';
import 'package:flutter_skeleton/locator.dart';
import 'package:provider/provider.dart';
//import 'package:window_size/window_size.dart' as window_size;
//import 'dart:math' as math;

void main() {
  // Try to resize and reposition the window to be half the width and height
  // of its screen, centered horizontally and shifted up from center.
//  WidgetsFlutterBinding.ensureInitialized();
//  window_size.getWindowInfo().then((window) {
//    if (window.screen != null) {
//      final screenFrame = window.screen.visibleFrame;
//      final width = math.max((screenFrame.width / 2).roundToDouble(), 800.0);
//      final height = math.max((screenFrame.height / 2).roundToDouble(), 600.0);
//      final left = ((screenFrame.width - width) / 2).roundToDouble();
//      final top = ((screenFrame.height - height) / 3).roundToDouble();
//      final frame = Rect.fromLTWH(left, top, width, height);
//      window_size.setWindowFrame(frame);
//      window_size
//          .setWindowTitle('Flutter Testbed on ${Platform.operatingSystem}');
//
//      if (Platform.isMacOS) {
//        window_size.setWindowMinSize(Size(800, 600));
//        window_size.setWindowMaxSize(Size(1600, 1200));
//      }
//    }
//  });


  run(
    title: 'Windows',
    initializer: () {
      return [
        NoOverscrollGlow()
      ];
    },
    registrator: (dependency) async {
      final app = Application();
      service(app);

      return [
        ChangeNotifierProvider(
          create: (_) => Tabs()
        ),
      ];
    },
    startScreen: ProjectChooser()
  );
}