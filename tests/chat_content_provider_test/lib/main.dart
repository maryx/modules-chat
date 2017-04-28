// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.ledger.services.public/ledger.fidl.dart';
import 'package:apps.modular.services.component/component_context.fidl.dart';
import 'package:apps.modular.services.module/module.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modules.chat.agents.content_provider..chat_content_provider_dart_package/src/chat_content_provider_impl.dart';
import 'package:apps.modules.chat.services/chat_content_provider.fidl.dart';
import 'package:apps.test_runner.services..test_runner/test_runner.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart' hide Message;
import 'package:test/test.dart' hide expect;

import 'src/expect.dart';
import 'src/mock_chat_message_transporter.dart';

final ApplicationContext _context = new ApplicationContext.fromStartupInfo();
ChatContentProviderTestModule _module;

// ignore: unused_element
void _log(String msg) {
  print('[chat_content_provider_test] $msg');
}

/// Implementation of the [Module] interface which tests the functionalities of
/// [ChatContentProvider].
class ChatContentProviderTestModule extends Module {
  final ModuleBinding _moduleBinding = new ModuleBinding();

  final TestRunnerProxy _testRunner = new TestRunnerProxy();
  final ComponentContextProxy _componentContext = new ComponentContextProxy();
  final LedgerProxy _ledger = new LedgerProxy();

  ChatContentProviderImpl _chatContentProvider;
  final MockChatMessageTransporter _mockChatMessageTransporter =
      new MockChatMessageTransporter();

  /// Bind an [InterfaceRequest] for a [Module] interface to this object.
  void bind(InterfaceRequest<Module> request) {
    _moduleBinding.bind(this, request);
  }

  /// Implements [Module] interface.
  @override
  Future<Null> initialize(
    InterfaceHandle<ModuleContext> moduleContext,
    InterfaceHandle<ServiceProvider> incomingServices,
    InterfaceRequest<ServiceProvider> outgoingServices,
  ) async {
    // Obtain TestRunner interface.
    connectToService(_context.environmentServices, _testRunner.ctrl);
    _testRunner.identify('chat_content_provider_test');

    // Obtain the ComponentContext interface.
    ModuleContextProxy moduleContextProxy = new ModuleContextProxy();
    moduleContextProxy.ctrl.bind(moduleContext);
    moduleContextProxy.getComponentContext(_componentContext.ctrl.request());
    moduleContextProxy.ctrl.close();

    // Obtain Ledger
    _componentContext.getLedger(_ledger.ctrl.request(), (Status s) {
      if (s != Status.ok) {
        _testRunner.fail('ComponentContext::GetLedger() failed: $s');
      }
    });

    // Initialize the ChatContentProviderImpl with our ComponentContext.
    _chatContentProvider = new ChatContentProviderImpl(
      componentContext: _componentContext,
      chatMessageTransporter: _mockChatMessageTransporter,
    );
    await _chatContentProvider.initialize();

    // Now run the actual tests!
    try {
      await _testFromBlankSlate();
    } catch (e, stackTrace) {
      _testRunner.fail('Test Error. See the console logs for more details.');
      _log('Test Error:\n$e\n$stackTrace');
    }

    _testRunner.teardown();
  }

  /// Implements [Module] interface.
  @override
  void stop(void callback()) {
    _chatContentProvider?.close();
    _ledger.ctrl.close();
    _componentContext.ctrl.close();
    _testRunner.ctrl.close();
    _moduleBinding.close();

    callback();
  }

  /// Test adding a new conversation and a few messages, starting from a blank
  /// slate.
  Future<Null> _testFromBlankSlate() async {
    ChatStatus status;
    Conversation conversation;
    List<Conversation> conversations;
    Message message;
    List<Message> messages;
    List<int> messageId1, messageId2;

    // GetConversations() should return an empty list for the first call.
    await _chatContentProvider.getConversations(
      null,
      (ChatStatus s, List<Conversation> c) {
        status = s;
        conversations = c;
      },
    );

    expect(status, equals(ChatStatus.ok));
    expect(conversations, isNotNull);
    expect(conversations, isEmpty);
    // TODO: _testRunner.pass('GetConversations()');

    // Test NewConversation() method.
    List<String> participants = <String>[
      'alice@example.com',
      'bob@example.com',
    ];
    await _chatContentProvider.newConversation(
      participants,
      (ChatStatus s, Conversation c) {
        status = s;
        conversation = c;
      },
    );

    expect(status, equals(ChatStatus.ok));
    expect(conversation, isNotNull);
    expect(conversation.conversationId, isNotNull);
    expect(conversation.conversationId, isNotEmpty);
    expect(conversation.participants, unorderedEquals(participants));
    // TODO: _testRunner.pass('NewConversation()');

    // Test GetConversations() method again.
    await _chatContentProvider.getConversations(
      null,
      (ChatStatus s, List<Conversation> c) {
        status = s;
        conversations = c;
      },
    );

    expect(status, equals(ChatStatus.ok));
    expect(conversations, isNotNull);
    expect(conversations, hasLength(1));
    expect(
      conversations[0].conversationId,
      orderedEquals(conversation.conversationId),
    );
    expect(conversations[0].participants, unorderedEquals(participants));
    // _testRunner.pass('GetConversations()');

    // Test GetMessages() method.
    await _chatContentProvider.getMessages(
      conversation.conversationId,
      null,
      (ChatStatus s, List<Message> m) {
        status = s;
        messages = m;
      },
    );

    expect(status, equals(ChatStatus.ok));
    expect(messages, isNotNull);
    expect(messages, isEmpty);
    // _testRunner.pass('GetMessages() should return an empty message list');

    // Test SendMessage() method #1.
    await _chatContentProvider.sendMessage(
      conversation.conversationId,
      'text',
      'My First Message',
      (ChatStatus s, List<int> mid) {
        status = s;
        messageId1 = mid;
      },
    );

    expect(status, equals(ChatStatus.ok));
    expect(messageId1, isNotNull);
    expect(messageId1, isNotEmpty);
    // _testRunner.pass('SendMessage()');

    // Test SendMessage() method #2.
    await _chatContentProvider.sendMessage(
      conversation.conversationId,
      'text',
      'My Second Message',
      (ChatStatus s, List<int> mid) {
        status = s;
        messageId2 = mid;
      },
    );

    expect(status, equals(ChatStatus.ok));
    expect(messageId2, isNotNull);
    expect(messageId2, isNotEmpty);
    // _testRunner.pass('SendMessage()');

    // Test GetMessages() method again.
    await _chatContentProvider.getMessages(
      conversation.conversationId,
      null,
      (ChatStatus s, List<Message> m) {
        status = s;
        messages = m;
      },
    );

    expect(status, equals(ChatStatus.ok));
    expect(messages, isNotNull);
    expect(messages, hasLength(2));
    expect(messages[0].messageId, orderedEquals(messageId1));
    expect(messages[0].sender, equals('me'));
    expect(messages[0].type, equals('text'));
    expect(messages[0].jsonPayload, equals('My First Message'));
    expect(messages[0].timestamp, isNotNull);
    expect(messages[1].messageId, orderedEquals(messageId2));
    expect(messages[1].sender, equals('me'));
    expect(messages[1].type, equals('text'));
    expect(messages[1].jsonPayload, equals('My Second Message'));
    expect(messages[1].timestamp, isNotNull);
    expect(messages[0].timestamp, lessThan(messages[1].timestamp));
    // _testRunner.pass('GetMessages()');

    // Test GetMessage() method #1.
    await _chatContentProvider.getMessage(
      conversation.conversationId,
      messageId1,
      (ChatStatus s, Message m) {
        status = s;
        message = m;
      },
    );

    expect(status, equals(ChatStatus.ok));
    expect(message, isNotNull);
    expect(message.messageId, orderedEquals(messageId1));
    expect(message.sender, equals('me'));
    expect(message.type, equals('text'));
    expect(message.jsonPayload, equals('My First Message'));
    expect(message.timestamp, isNotNull);
    // _testRunner.pass('GetMessage() #1');

    // Test GetMessage() method #2.
    await _chatContentProvider.getMessage(
      conversation.conversationId,
      messageId2,
      (ChatStatus s, Message m) {
        status = s;
        message = m;
      },
    );

    expect(status, equals(ChatStatus.ok));
    expect(message, isNotNull);
    expect(message.messageId, orderedEquals(messageId2));
    expect(message.sender, equals('me'));
    expect(message.type, equals('text'));
    expect(message.jsonPayload, equals('My Second Message'));
    expect(message.timestamp, isNotNull);
    // _testRunner.pass('GetMessage() #2');

    // Test GetLastMessage() method.
    await _chatContentProvider.getLastMessage(
      conversation.conversationId,
      (ChatStatus s, Message m) {
        status = s;
        message = m;
      },
    );

    expect(status, equals(ChatStatus.ok));
    expect(message, isNotNull);
    expect(message.messageId, orderedEquals(messageId2));
    expect(message.sender, equals('me'));
    expect(message.type, equals('text'));
    expect(message.jsonPayload, equals('My Second Message'));
    expect(message.timestamp, isNotNull);
    // _testRunner.pass('GetLastMessage()');
  }
}

/// Main entry point.
Future<Null> main(List<String> args) async {
  _context.outgoingServices.addServiceForName(
    (InterfaceRequest<Module> request) {
      if (_module == null) {
        _module = new ChatContentProviderTestModule()..bind(request);
      } else {
        // Can only connect to this interface once.
        request.close();
      }
    },
    Module.serviceName,
  );
}
