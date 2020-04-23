import 'package:flutter/material.dart';

class Dependency {

  List<Object> _data;

  Dependency(this._data);

  T call<T>() {
    if (_data != null) {
      final matcher = TypeMatcher<T>();

      for (Object object in _data) {
        if (matcher.check(object))
          return object as T;
      }
    }
    return null;
  }
}

class NoOverscrollGlow extends ScrollBehavior {
  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) => child;
}