// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/modular.dart';

import 'src/modular/conversation_list_module_model.dart';
import 'src/modular/conversation_list_screen.dart';

void main() {
  ModuleWidget<ChatConversationListModuleModel> moduleWidget =
      new ModuleWidget<ChatConversationListModuleModel>(
    applicationContext: new ApplicationContext.fromStartupInfo(),
    moduleModel: new ChatConversationListModuleModel(),
    child: new ChatConversationListScreen(),
  );

  moduleWidget.advertise();

  runApp(moduleWidget);
}
