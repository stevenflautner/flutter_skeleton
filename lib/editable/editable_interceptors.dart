import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_managed/locator.dart';
import 'package:flutter_manager/data_editor/data_editor.dart';
import 'package:flutter_manager/editable/editable_views.dart';
import 'package:flutter_manager/entities.dart';
import 'package:flutter_manager/logic/app.dart';

class EditableInterceptors extends EditableData<Interceptor> {

  List<Interceptor> _interceptors = [];

  Interceptor add(String name) {
    final interceptor = Interceptor(name);
    getData().add(interceptor);
    notify();
    return interceptor;
  }

  @override
  String writeServerHead() {
    return '';
  }

  @override
  String writeServerObjString(Interceptor interceptor) {
    return null;
  }

  @override
  String writeFileTo(bool isClient) {
  }

  @override
  List<Interceptor> getData() => get<Application>().data.interceptors;

  @override
  Widget buildAddObjDialog(BuildContext context) => AddInterceptorDialog();

  @override
  Widget buildObjView() {
    return InterceptorsObjView();
  }

  @override
  String writeClientObjString(Interceptor obj) {
    return '';
  }
}