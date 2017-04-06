// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/modular.dart';

import 'src/modular/story_module_model.dart';
import 'src/modular/story_screen.dart';

void main() {
  ModuleWidget<ChatStoryModuleModel> moduleWidget =
      new ModuleWidget<ChatStoryModuleModel>(
    applicationContext: new ApplicationContext.fromStartupInfo(),
    moduleModel: new ChatStoryModuleModel(),
    child: new ChatStoryScreen(),
  );

  moduleWidget.advertise();

  runApp(moduleWidget);
}
