// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show JSON;
import 'dart:typed_data';

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.modular.services.agent.agent_controller/agent_controller.fidl.dart';
import 'package:apps.modular.services.component/component_context.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:apps.modules.chat.services/chat_content_provider.fidl.dart';
import 'package:lib.widgets/modular.dart';

const String _kChatContentProviderUrl =
    'file:///system/apps/chat_content_provider';

void _log(String msg) {
  print('[chat_conversation_module_model] $msg');
}

/// A [ModuleModel] providing chat conversation specific data to the descendant
/// widgets.
class ChatConversationModuleModel extends ModuleModel {
  final AgentControllerProxy _chatContentProviderController =
      new AgentControllerProxy();

  final ChatContentProviderProxy _chatContentProvider =
      new ChatContentProviderProxy();

  final LinkWatcherBinding _linkWatcherBinding = new LinkWatcherBinding();
  LinkWatcherImpl _linkWatcher;

  List<Message> _messages;

  Uint8List _conversationId;

  /// Gets the [ChatContentProvider] service provided by the agent.
  ChatContentProvider get chatContentProvider => _chatContentProvider;

  /// Gets and sets the current conversation id value.
  Uint8List get conversationId => _conversationId;

  set conversationId(List<int> id) {
    Uint8List newId = new Uint8List.fromList(id);
    if (_conversationId != newId) {
      _messages = null;
      _conversationId = newId;

      // We notify here first to indicate the conversation id value is changed.
      notifyListeners();

      // After fetching is done, a second notification will be sent out.
      _fetchMessageHistory();
    }
  }

  /// Gets the list of chat messages in the current conversation.
  ///
  /// Returns null when the messages are not yet retrieved from the content
  /// provider.
  List<Message> get messages =>
      _messages == null ? null : new List<Message>.unmodifiable(_messages);

  @override
  void onReady(
    ModuleContext moduleContext,
    Link link,
    ServiceProvider incomingServices,
  ) {
    super.onReady(moduleContext, link, incomingServices);

    _log('ModuleModel::onReady call.');

    // Obtain the component context.
    ComponentContextProxy componentContext = new ComponentContextProxy();
    moduleContext.getComponentContext(componentContext.ctrl.request());

    // Obtain the ChatContentProvider service.
    ServiceProviderProxy contentProviderServices = new ServiceProviderProxy();
    componentContext.connectToAgent(
      _kChatContentProviderUrl,
      contentProviderServices.ctrl.request(),
      _chatContentProviderController.ctrl.request(),
    );
    connectToService(contentProviderServices, _chatContentProvider.ctrl);

    // Register a LinkWatcher.
    _linkWatcher = new LinkWatcherImpl(
      onNotify: (String json) {
        conversationId = JSON.decode(json);
      },
    );
    link.watch(_linkWatcherBinding.wrap(_linkWatcher));

    // Close all the unnecessary bindings.
    contentProviderServices.ctrl.close();
    componentContext.ctrl.close();

    // Fetch the message history.
    _fetchMessageHistory();
  }

  void _fetchMessageHistory() {
    _log('fetchMessageHistory call.');

    chatContentProvider.getMessageHistory(
      conversationId ?? new Uint8List(16),
      (List<Message> messages) {
        _log('getMessageHistory callback.');
        _messages = new List<Message>.from(messages);
        notifyListeners();
      },
    );
  }

  @override
  void onStop() {
    _linkWatcherBinding.close();

    _chatContentProvider.ctrl.close();
    _chatContentProviderController.ctrl.close();

    super.onStop();
  }
}
