// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modular.services.module/module_controller.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:apps.mozart.lib.flutter/child_view.dart';
import 'package:apps.mozart.services.views/view_token.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:lib.widgets/modular.dart';

const String _kConversationListUrl =
    'file:///system/apps/chat_conversation_list';
const String _kConversationUrl = 'file:///system/apps/chat_conversation';

void _log(String msg) {
  print('[chat_story_module_model] $msg');
}

/// A [ModuleModel] providing the [ChildViewConnection]s of the child modules.
class ChatStoryModuleModel extends ModuleModel {
  ChildViewConnection _conversationListConnection;
  ChildViewConnection _conversationConnection;

  /// Gets the [ChildViewConnection] for the conversation list sub module.
  ChildViewConnection get conversationListConnection =>
      _conversationListConnection;

  /// Gets the [ChildViewConnection] for the conversation sub module.
  ChildViewConnection get conversationConnection => _conversationConnection;

  @override
  void onReady(
    ModuleContext moduleContext,
    Link link,
    ServiceProvider incomingServices,
  ) {
    super.onReady(moduleContext, link, incomingServices);

    // Launch the conversation list module.
    _conversationListConnection = new ChildViewConnection(
      startModule(url: _kConversationListUrl),
    );

    // Launch the conversation module.
    _conversationConnection = new ChildViewConnection(
      startModule(url: _kConversationUrl),
    );

    notifyListeners();
  }

  @override
  void onStop() {
    _conversationListConnection = null;
    _conversationConnection = null;

    super.onStop();
  }

  /// Start a module and return its [ViewOwner] handle.
  InterfaceHandle<ViewOwner> startModule({
    String url,
    InterfaceHandle<ServiceProvider> outgoingServices,
    InterfaceRequest<ServiceProvider> incomingServices,
  }) {
    InterfacePair<ViewOwner> viewOwnerPair = new InterfacePair<ViewOwner>();
    InterfacePair<ModuleController> moduleControllerPair =
        new InterfacePair<ModuleController>();

    _log('Starting sub-module: $url');
    moduleContext.startModule(
      url, // module name
      url,
      duplicateLink(),
      outgoingServices,
      incomingServices,
      moduleControllerPair.passRequest(),
      viewOwnerPair.passRequest(),
    );
    _log('Started sub-module: $url');

    return viewOwnerPair.passHandle();
  }

  /// Obtains a duplicated [InterfaceHandle] for the given [Link] object.
  InterfaceHandle<Link> duplicateLink() {
    InterfacePair<Link> linkPair = new InterfacePair<Link>();
    link.dup(linkPair.passRequest());
    return linkPair.passHandle();
  }
}
