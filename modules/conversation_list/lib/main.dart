// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.modular.services.agent.agent_controller/agent_controller.fidl.dart';
import 'package:apps.modular.services.component/component_context.fidl.dart';
import 'package:apps.modular.services.module/module.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:apps.modules.chat.services/chat_content_provider.fidl.dart';
import 'package:flutter/material.dart';
import 'package:lib.fidl.dart/bindings.dart';

import 'src/chat_conversation_list_screen.dart';

const String _kChatContentProviderUrl =
    'file:///system/apps/chat_content_provider';

final ApplicationContext _appContext = new ApplicationContext.fromStartupInfo();

ModuleImpl _module;

void _log(String msg) {
  print('[chat_conversation_list] $msg');
}

/// An implementation of the [Module] interface.
class ModuleImpl extends Module {
  final ModuleBinding _binding = new ModuleBinding();
  final ModuleContextProxy _moduleContext = new ModuleContextProxy();
  final AgentControllerProxy _chatContentProviderController =
      new AgentControllerProxy();

  final ChatContentProviderProxy _chatContentProvider =
      new ChatContentProviderProxy();

  /// Bind an [InterfaceRequest] for a [Module] interface to this object.
  void bind(InterfaceRequest<Module> request) {
    _binding.bind(this, request);
  }

  @override
  void initialize(
      InterfaceHandle<ModuleContext> moduleContextHandle,
      InterfaceHandle<Link> linkHandle,
      InterfaceHandle<ServiceProvider> incomingServices,
      InterfaceRequest<ServiceProvider> outgoingServices) {
    _log('Module::initialize call.');

    // Obtain the component context.
    _moduleContext.ctrl.bind(moduleContextHandle);
    ComponentContextProxy componentContext = new ComponentContextProxy();
    _moduleContext.getComponentContext(componentContext.ctrl.request());

    // Obtain the ChatContentProvider service.
    ServiceProviderProxy contentProviderServices = new ServiceProviderProxy();
    componentContext.connectToAgent(
      _kChatContentProviderUrl,
      contentProviderServices.ctrl.request(),
      _chatContentProviderController.ctrl.request(),
    );
    connectToService(contentProviderServices, _chatContentProvider.ctrl);

    // Close all the unnecessary bindings.
    contentProviderServices.ctrl.close();
    componentContext.ctrl.close();

    // Run the app at this point with the obtained chat content provider.
    runApp(new MaterialApp(
      theme: new ThemeData(primarySwatch: Colors.purple),
      home: new Material(
        child: new ChatConversationListScreen(
          chatContentProvider: _chatContentProvider,
        ),
      ),
    ));
  }

  @override
  void stop(void callback()) {
    _moduleContext.ctrl.close();
    _chatContentProvider.ctrl.close();
    _chatContentProviderController.ctrl.close();
    callback();
  }
}

/// Entry point for this module.
void main() {
  _appContext.outgoingServices.addServiceForName(
    (InterfaceRequest<Module> request) {
      if (_module == null) {
        _module = new ModuleImpl();
      }

      _module.bind(request);
    },
    Module.serviceName,
  );
}
