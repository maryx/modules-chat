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
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:apps.modules.chat.services/chat_content_provider.fidl.dart'
    as chat_fidl;
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/modular.dart';

import '../models.dart';
import '../widgets.dart';

const String _kChatContentProviderUrl =
    'file:///system/apps/chat_content_provider';

const Duration _kScrollAnimationDuration = const Duration(milliseconds: 300);

void _log(String msg) {
  print('[chat_conversation_module_model] $msg');
}

/// A [ModuleModel] providing chat conversation specific data to the descendant
/// widgets.
class ChatConversationModuleModel extends ModuleModel {
  static final ListEquality<int> _intListEquality = const ListEquality<int>();

  final AgentControllerProxy _chatContentProviderController =
      new AgentControllerProxy();

  final chat_fidl.ChatContentProviderProxy _chatContentProvider =
      new chat_fidl.ChatContentProviderProxy();

  final MessageQueueProxy _messageQueue = new MessageQueueProxy();
  final Completer<String> _mqTokenCompleter = new Completer<String>();

  List<chat_fidl.Message> _messages;
  List<Section> _sections;

  Uint8List _conversationId;

  /// Gets the current conversation id value.
  Uint8List get conversationId => _conversationId;

  /// Sets the current conversation id value.
  void _setConversationId(List<int> id) {
    Uint8List newId = id == null ? null : new Uint8List.fromList(id);
    if (!_intListEquality.equals(_conversationId, newId)) {
      _conversationId = newId;

      // We don't want to reuse the existing scroll controller, so create a new
      // one here. Otherwise, the scroll position will animate when jumping
      // between different conversation rooms.
      _scrollController = new ScrollController();

      // We set the messages as null and notify here first to indicate the
      // conversation id value is changed.
      _setMessages(null);

      // After fetching is done, a second notification will be sent out.
      _fetchMessageHistory();
    }
  }

  /// Sets the new list of [chat_fidl.Message]s received from the agent.
  /// Calling this also recalculates the [Section]s, and notifies the listeners.
  void _setMessages(List<chat_fidl.Message> messages) {
    try {
      _messages = messages;
      if (_messages == null) {
        _sections = null;
        return;
      }

      List<chat_fidl.Message> sortedMessages =
          new List<chat_fidl.Message>.from(_messages)..sort(_compareMessages);

      _sections = createSectionsFromMessages(
        sortedMessages.map(_createMessageFromFidl).toList(),
      );
    } catch (e, stackTrace) {
      _log('Error occurred while setting _messages: $e');
      _log('$stackTrace');
    } finally {
      notifyListeners();
    }
  }

  /// Gets the list of consecutive chat [Section]s in this conversation.
  List<Section> get sections => _sections == null
      ? const <Section>[]
      : new UnmodifiableListView<Section>(_sections);

  ScrollController _scrollController;

  /// Gets the [ScrollController] to be used in the [ChatConversation] widget.
  ///
  /// This is needed here because we want to programmatically manipulate the
  /// scroll position when a new message is added.
  ScrollController get scrollController => _scrollController;

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

    // Obtain a message queue.
    componentContext.obtainMessageQueue(
      'chat_conversation',
      _messageQueue.ctrl.request(),
    );
    // Save the message queue token for later use.
    _messageQueue.getToken((String token) => _mqTokenCompleter.complete(token));
    _messageQueue.receive(_handleNewMessage);

    // Close all the unnecessary bindings.
    contentProviderServices.ctrl.close();
    componentContext.ctrl.close();

    // Fetch the message history.
    _fetchMessageHistory();
  }

  /// Fetches the message history from the content provider. It also gives our
  /// message queue token to the agent so that the agent can notify us whenever
  /// a new message appears in the current conversation.
  ///
  /// The returned messages will be stored in the [_messages] list.
  Future<Null> _fetchMessageHistory() async {
    _log('fetchMessageHistory call.');

    if (conversationId == null) {
      return;
    }

    String messageQueueToken = await _mqTokenCompleter.future;
    _chatContentProvider.getMessages(
      conversationId,
      messageQueueToken,
      (chat_fidl.ChatStatus status, List<chat_fidl.Message> messages) {
        _log('getMessageHistory callback.');

        // TODO(youngseokyoon): properly communicate the error status to the
        // user. (https://fuchsia.atlassian.net/browse/SO-365)
        if (status != chat_fidl.ChatStatus.ok) {
          _log('ChatContentProvider::GetMessages() returned an error '
              'status: $status');
          _setMessages(null);
        }

        _log('setMessages call');
        _setMessages(new List<chat_fidl.Message>.from(messages));
      },
    );
  }

  /// Handle the new message passed via the [MessageQueue].
  ///
  /// Refer to the `chat_content_provider.fidl` file for the expected message
  /// format coming from the content provider.
  void _handleNewMessage(String message) {
    _log('handleNewMessage call with message: $message');
    try {
      Map<String, dynamic> decoded = JSON.decode(message);
      List<int> conversationId = decoded['conversation_id'];
      List<int> messageId = decoded['message_id'];

      // Ask for the new message content and add it to the message list.
      _chatContentProvider.getMessage(
        conversationId,
        messageId,
        (chat_fidl.ChatStatus status, chat_fidl.Message message) {
          _log('getMessage() callback');

          // TODO(youngseokyoon): properly communicate the error status to the
          // user. (https://fuchsia.atlassian.net/browse/SO-365)
          if (status != chat_fidl.ChatStatus.ok) {
            _log('ChatContentProvider::GetMessage() returned an error '
                'status: $status');
            return;
          }

          if (message != null &&
              _intListEquality.equals(this.conversationId, conversationId)) {
            _log('adding the new message.');
            _setMessages(_messages..add(message));
            _scrollToEnd();
          }
        },
      );
    } catch (e) {
      _log('Error occurred while processing the message received via the '
          'message queue: $e');
    } finally {
      // Register the handler again to process further messages.
      _messageQueue.receive(_handleNewMessage);
    }
  }

  /// Auto-scroll the chat conversation list to the end.
  ///
  /// Because the [ListView] used inside the [ChatConversation] widget is a
  /// reversed list, we can simply animate to 0.0 to scroll to end.
  void _scrollToEnd() {
    _scrollController.animateTo(
      0.0,
      curve: Curves.easeOut,
      duration: _kScrollAnimationDuration,
    );
  }

  Message _createMessageFromFidl(chat_fidl.Message m) {
    switch (m.type) {
      case 'text':
        return new TextMessage(
          time: new DateTime.fromMillisecondsSinceEpoch(m.timestamp),
          sender: m.sender,
          text: m.jsonPayload,
        );

      default:
        _log('Unsupported message type: ${m.type}');
        return null;
    }
  }

  static int _compareMessages(chat_fidl.Message m1, chat_fidl.Message m2) {
    if (m1.timestamp < m2.timestamp) return -1;
    if (m1.timestamp > m2.timestamp) return 1;
    return 0;
  }

  @override
  Future<Null> onStop() async {
    if (_mqTokenCompleter.isCompleted) {
      String messageQueueToken = await _mqTokenCompleter.future;
      _chatContentProvider.unsubscribe(messageQueueToken);
    }

    _messageQueue.ctrl.close();
    _chatContentProvider.ctrl.close();
    _chatContentProviderController.ctrl.close();

    super.onStop();
  }

  @override
  void onNotify(String json) {
    _setConversationId(JSON.decode(json));
  }

  /// Send a new message to the current conversation.
  /// Internally, it invokes the [chat_fidl.ChatContentProvider.sendMessage]
  /// method.
  void sendMessage(String message) {
    _chatContentProvider.sendMessage(
      conversationId,
      'text',
      message,
      (_, __) => null,
    );
  }
}
