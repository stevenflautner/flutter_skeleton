import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_managed/locator.dart';
import 'package:flutter_manager/data_editor/data_editor.dart';
import 'package:flutter_manager/editable/editable_views.dart';
import 'package:flutter_manager/entities.dart';
import 'package:flutter_manager/logic/app.dart';

class EditableServices extends EditableData<Service> {

  List<Service> _services = [];

  Service add(String name) {
    final service = Service(name);
    getData().add(service);
    notify();
    return service;
  }

//  void addValue(Attribute attr, String value) {
//    (attr as ValueAttribute).values.add(value);
//    notify();
//  }

//  void removeValue(Attribute attr, String value) {
//    (attr as ValueAttribute).values.remove(value);
//    notify();
//  }

//  void modifyValue(Attribute attr, String oldValue, String newValue) {
//    final valueAttr = attr as ValueAttribute;
//    final index = valueAttr.values.indexOf(oldValue);
//
//    removeValue(valueAttr, oldValue);
//    valueAttr.values.insert(index, newValue);
//    notify();
//  }

//  void modifyAttr(Attribute attr, String newAttrName) {
//    attr.name = newAttrName;
//    notify();
//  }

  @override
  String writeServerHead() {
    return '';
  }

  @override
  String writeServerObjString(Service service) {
    return null;
  }

  @override
  String writeFileTo(bool isClient) {
  }

  @override
  List<Service> getData() => get<Application>().services;

  @override
  Widget buildAddObjDialog(BuildContext context) => AddServiceDialog();

  @override
  Widget buildObjView() {
    return ServicesObjView();
  }

  @override
  String writeClientObjString(Service obj) {
    return '';
  }
}