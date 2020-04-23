import 'dart:ui';
import 'package:flutter/material.dart';

void postBuild(FrameCallback callback) => WidgetsBinding.instance.addPostFrameCallback(callback);