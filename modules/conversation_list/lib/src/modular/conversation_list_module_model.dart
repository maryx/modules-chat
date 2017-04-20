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
import 'package:apps.modules.chat.services/chat_content_provider.fidl.dart'
    as chat_fidl;
import 'package:collection/collection.dart';
import 'package:lib.widgets/modular.dart';
import 'package:models/user.dart';

import '../models.dart';

const String _kChatContentProviderUrl =
    'file:///system/apps/chat_content_provider';

void _log(String msg) {
  print('[chat_conversation_list_module_model] $msg');
}

/// A [ModuleModel] providing chat conversation list specific data to the
/// descendant widgets.
class ChatConversationListModuleModel extends ModuleModel {
  static final ListEquality<int> _intListEquality = const ListEquality<int>();

  final AgentControllerProxy _chatContentProviderController =
      new AgentControllerProxy();

  final chat_fidl.ChatContentProviderProxy _chatContentProvider =
      new chat_fidl.ChatContentProviderProxy();

  Uint8List _conversationId;

  List<Conversation> _conversations;

  /// Gets the [ChatContentProvider] service provided by the agent.
  chat_fidl.ChatContentProvider get chatContentProvider => _chatContentProvider;

  /// Gets and sets the current conversation id value.
  Uint8List get conversationId => _conversationId;

  /// Sets the current conversation id value.
  void setConversationId(List<int> id, {bool updateLink: true}) {
    Uint8List newId = id == null ? null : new Uint8List.fromList(id);
    if (!_intListEquality.equals(_conversationId, newId)) {
      _conversationId = newId;

      // Set the value to Link.
      if (updateLink) {
        link.set(null, JSON.encode(id));
      }

      notifyListeners();
    }
  }

  /// Gets the list of chat conversations.
  ///
  /// Returns null when the conversation list is not yet retrieved.
  List<Conversation> get conversations => _conversations == null
      ? null
      : new UnmodifiableListView<Conversation>(_conversations);

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

    // Close all the unnecessary bindings.
    contentProviderServices.ctrl.close();
    componentContext.ctrl.close();

    // Fetch the conversation list.
    _fetchConversations();
  }

  void _fetchConversations() {
    _log('_fetchConversations call.');

    chatContentProvider.getConversations(
      (
        chat_fidl.ChatStatus status,
        List<chat_fidl.Conversation> conversations,
      ) {
        _log('getConversations callback.');

        // TODO(youngseokyoon): properly communicate the error status to the
        // user. (https://fuchsia.atlassian.net/browse/SO-365)
        if (status != chat_fidl.ChatStatus.ok) {
          _log('ChatContentProvider::GetConversations() returned an error '
              'status: $status');
          _conversations = null;
          notifyListeners();
        }

        _conversations = conversations == null
            ? null
            : conversations.map(_getConversationFromFidl).toList();

        notifyListeners();
      },
    );
  }

  // TODO(youngseokyoon): get the last message and fill in the info.
  Conversation _getConversationFromFidl(chat_fidl.Conversation c) =>
      new Conversation(
        conversationId: c.conversationId,
        participants: c.participants.map(_getUserFromEmail).toList(),
        snippet: null,
        timestamp: null,
      );

  User _getUserFromEmail(String email) => new User(
        email: email,
        name: email,
        picture: null,
      );

  @override
  void onStop() {
    _chatContentProvider.ctrl.close();
    _chatContentProviderController.ctrl.close();

    super.onStop();
  }

  @override
  void onNotify(String json) {
    setConversationId(JSON.decode(json), updateLink: false);
  }
}
