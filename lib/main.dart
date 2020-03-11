import 'package:flutter_managed/app.dart';
import 'package:flutter_managed/dependency.dart';
import 'package:flutter_managed/locator.dart';
import 'package:flutter_manager/logic/app.dart';
import 'package:flutter_manager/logic/tabs.dart';
import 'package:flutter_manager/screens/main_screen.dart';
import 'package:provider/provider.dart';

void main() {
  run(
    title: 'Windows',
    initializer: () {
      return [
        NoOverscrollGlow()
      ];
    },
    registrator: (dependency) async {
      final app = Application();
      await app.initialize();
      service(app);

      return [
        ChangeNotifierProvider(
          create: (_) => Tabs()
        ),
      ];
    },
    startScreen: MainScreen()
  );
}