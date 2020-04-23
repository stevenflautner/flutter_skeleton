import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_skeleton/localizator.dart';
import 'package:flutter_skeleton/locator.dart';
import 'package:flutter_skeleton/skeleton.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dependency.dart';

typedef FutureOr<Iterable<dynamic>> Initializer();
typedef FutureOr<Iterable<SingleChildWidget>> _Registrator(Dependency dependency);
typedef Widget ParentBuilder(BuildContext context, Widget child);

void asd() async {
  await SharedPreferences.getInstance();
}

void run({
  @required String title,
  Initializer initializer,
  _Registrator registrator,
  @required Widget startScreen,
  ParentBuilder parent,
  Skeleton skeleton,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final locator = Locator();
  final dependency = Dependency(initializer != null ? await initializer() : null);

//  SharedPreferences.setMockInitialValues({});
  service(await SharedPreferences.getInstance());

  skeleton?.loadModules(dependency);

  List<SingleChildWidget> providers;
  if (registrator != null)
     providers = await registrator(dependency);

  final overlayStyle = dependency<SystemUiOverlayStyle>();
  if (overlayStyle != null) SystemChrome.setSystemUIOverlayStyle(overlayStyle);

  runApp(App(
    providers: providers,
    dependency: dependency,
    startScreen: startScreen,
    parentBuilder: parent,
  ));
}

class App extends StatefulWidget {

  final Dependency dependency;
  final List<SingleChildWidget> providers;
  final Widget startScreen;
  final ParentBuilder parentBuilder;

  const App({
    Key key,
    @required this.dependency,
    @required this.providers,
    @required this.startScreen,
    @required this.parentBuilder,
  }) : super(key: key);

  @override
  _AppState createState() => _AppState();

  static _AppState of(BuildContext context) {
    return context.ancestorStateOfType(const TypeMatcher<_AppState>());
  }

}

class _AppState extends State<App> {

  @override
  Widget build(BuildContext context) {
    if (widget.providers != null && widget.providers.isNotEmpty)
      return MultiProvider(
        providers: widget.providers,
        child: _buildWidget()
      );
    else
      return _buildWidget();
  }

  Widget _buildWidget() {
    Localizator localizator;
    try {
      localizator = get();
    } on ArgumentError catch(_) {}

    Widget child;

    if (localizator != null) {
      child = MaterialApp(
        home: widget.startScreen,
        locale: Localizator.forcedLocale(),
        theme: widget.dependency<ThemeData>(),
        supportedLocales: localizator.supportedLocales,
        localizationsDelegates: [
          localizator,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        builder: _childBuilder,
      );
    } else {
      child = MaterialApp(
        home: widget.startScreen,
        builder: _childBuilder,
      );
    }

    if (widget.parentBuilder == null)
      return child;
    else
      return widget.parentBuilder(context, child);
  }

  Widget _childBuilder(BuildContext context, Widget child) {
    final ScrollBehavior scrollBehavior = widget.dependency();
    if (scrollBehavior != null) {
      return ScrollConfiguration(
        behavior: scrollBehavior,
        child: child,
      );
    }
    return child;
  }

  void rebuild() {
    setState(() {});
  }
}