// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:typed_data';

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.modular.services.agent.agent_controller/agent_controller.fidl.dart';
import 'package:apps.modular.services.component/component_context.fidl.dart';
import 'package:apps.modular.services.component/message_queue.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modular.services.module/module_controller.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:apps.modular.services.story/surface.fidl.dart';
import 'package:apps.modules.chat.services/chat_content_provider.fidl.dart'
    as chat_fidl;
import 'package:collection/collection.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:lib.widgets/modular.dart';
import 'package:models/user.dart';

import '../models.dart';

const String _kChatContentProviderUrl =
    'file:///system/apps/chat_content_provider';
const String _kChatConversationModuleUrl =
    'file:///system/apps/chat_conversation';

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

  final MessageQueueProxy _messageQueue = new MessageQueueProxy();
  final Completer<String> _mqTokenCompleter = new Completer<String>();

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

  bool _shouldShowNewConversationForm = false;

  /// Indicates whether the conversation list screen should show the new
  /// conversation form.
  bool get shouldShowNewConversationForm => _shouldShowNewConversationForm;

  Uint8List _lastCreatedConversationId;

  @override
  void onReady(
    ModuleContext moduleContext,
    Link link,
    ServiceProvider incomingServices,
  ) {
    super.onReady(moduleContext, link, incomingServices);

    _log('ModuleModel::onReady call.');
    // Start the chat conversation module.
    _startConversationModule();

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

    // Obtain a message queue.
    componentContext.obtainMessageQueue(
      'chat_conversation_list',
      _messageQueue.ctrl.request(),
    );
    // Save the message queue token for later use.
    _messageQueue.getToken((String token) => _mqTokenCompleter.complete(token));
    _messageQueue.receive(_handleNewConversation);

    // Close all the unnecessary bindings.
    contentProviderServices.ctrl.close();
    componentContext.ctrl.close();

    _fetchConversations();
  }

  /// Start the chat_conversation module in story shell.
  void _startConversationModule() {
    InterfacePair<ModuleController> moduleControllerPair =
        new InterfacePair<ModuleController>();

    moduleContext.startModuleInShell(
      'chat_conversation',
      _kChatConversationModuleUrl,
      null, // Pass on our default link to the child.
      null,
      null,
      moduleControllerPair.passRequest(),
      new SurfaceRelation()
        ..arrangement = SurfaceArrangement.copresent
        ..emphasis = 2.0,
    );
  }

  /// Fetches the conversation list from the content provider. Also provide our
  /// message queue token to the agent so that the agent can notify us whenever
  /// a new conversation is added.
  ///
  /// The returned conversations will be stored in the [conversations] list.
  Future<Null> _fetchConversations() async {
    _log('_fetchConversations call.');

    String messageQueueToken = await _mqTokenCompleter.future;
    chatContentProvider.getConversations(
      messageQueueToken,
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

  /// Handles the new message passed via the [MessageQueue].
  ///
  /// Refer to the `chat_content_provider.fidl` file for the expected message
  /// format coming from the content provider.
  void _handleNewConversation(String message) {
    _log('handleNewConversation call with message: $message');
    try {
      Map<String, dynamic> decoded = JSON.decode(message);
      List<int> conversationId = decoded['conversation_id'];
      List<String> participants = decoded['participants'];

      _conversations.add(new Conversation(
        conversationId: conversationId,
        participants: participants.map(_getUserFromEmail).toList(),
      ));

      // If this conversation happens to be the last created conversation from
      // the current user, select it immediately. If not, just notify that there
      // is a new conversation added.
      if (_intListEquality.equals(_lastCreatedConversationId, conversationId)) {
        _lastCreatedConversationId = null;
        // No need to notify here, because setConversationId does it already.
        setConversationId(conversationId);
      } else {
        notifyListeners();
      }
    } catch (e) {
      _log('Error occurred while processing the message received via the '
          'message queue: $e');
    } finally {
      // Register the handler again to process further messages.
      _messageQueue.receive(_handleNewConversation);
    }
  }

  // TODO(youngseokyoon): get the last message and fill in the info.
  Conversation _getConversationFromFidl(chat_fidl.Conversation c) =>
      new Conversation(
        conversationId: c.conversationId,
        participants: c.participants.map(_getUserFromEmail).toList(),
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

  /// Shows the new conversation form.
  void showNewConversationForm() {
    _shouldShowNewConversationForm = true;
    notifyListeners();
  }

  /// Hides the new conversation form.
  void hideNewConversationForm() {
    _shouldShowNewConversationForm = false;
    notifyListeners();
  }

  /// Create a new conversation with the specified participant emails.
  void newConversation(List<String> participants) {
    _chatContentProvider.newConversation(
      participants,
      (chat_fidl.ChatStatus status, chat_fidl.Conversation conversation) {
        // TODO(youngseokyoon): properly communicate the error status to the
        // user. (https://fuchsia.atlassian.net/browse/SO-365)
        if (status != chat_fidl.ChatStatus.ok) {
          _log('ChatContentProvider::NewConversation() returned an error '
              'status: $status');
          return;
        }

        // The intended behavior is to auto-select the newly created
        // conversation when it is successfully created. However, we don't know
        // whether the `_handleNewConversation()` notification or this callback
        // of `newConversation()` call will come first.
        //
        // In order to account for both scenarios, if the created conversation
        // id is already in our list of conversation ids, just select that
        // conversation right away. If not, store the id in a temporary variable
        // and select it later when the conversation is notified via the message
        // queue mechanism.
        if (conversations.any((Conversation c) => _intListEquality.equals(
              c.conversationId,
              conversation.conversationId,
            ))) {
          setConversationId(conversation.conversationId);
        } else {
          _lastCreatedConversationId = new Uint8List.fromList(
            conversation.conversationId,
          );
        }
      },
    );
  }
}
