// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/modular.dart';

import 'src/modular/conversation_module_model.dart';
import 'src/modular/conversation_screen.dart';

void main() {
  ModuleWidget<ChatConversationModuleModel> moduleWidget =
      new ModuleWidget<ChatConversationModuleModel>(
    applicationContext: new ApplicationContext.fromStartupInfo(),
    moduleModel: new ChatConversationModuleModel(),
    child: new ChatConversationScreen(),
  );

  moduleWidget.advertise();

  runApp(moduleWidget);
}
