// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.ledger.services.public/ledger.fidl.dart';
import 'package:apps.modular.services.component/component_context.fidl.dart';
import 'package:apps.modular.services.component/message_queue.fidl.dart';
import 'package:apps.modular.services.module/module.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modules.chat.agents.content_provider..chat_content_provider_dart_package/src/chat_content_provider_impl.dart';
import 'package:apps.modules.chat.services/chat_content_provider.fidl.dart';
import 'package:apps.test_runner.services..test_runner/test_runner.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart' hide Message;
import 'package:meta/meta.dart';
import 'package:test/test.dart' hide expect;

import 'src/expect.dart';
import 'src/mock_chat_message_transporter.dart';

const Duration _kTimeout = const Duration(seconds: 1);

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
      await _testMessageQueues();
    } catch (e, stackTrace) {
      _testRunner.fail('Test Error. See the console logs for more details.');
      _log('Test Error:\n$e\n$stackTrace');
    }

    _testRunner.teardown(() {});
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

  /// Test getting notified of new conversations / messages with message queues.
  /// This is assumed to be called after [_testFromBlankSlate()].
  Future<Null> _testMessageQueues() async {
    ChatStatus status;
    List<Conversation> conversations;
    Conversation conversation0, conversation1, conversation2;
    List<Message> messages;
    List<int> messageId;
    Completer<Null> completer1, completer2;
    dynamic decoded;

    _MessageQueueWrapper mqConversation1 = await _getMessageQueue('conv1');
    _MessageQueueWrapper mqConversation2 = await _getMessageQueue('conv2');
    _MessageQueueWrapper mqMessage1 = await _getMessageQueue('msg1');
    _MessageQueueWrapper mqMessage2 = await _getMessageQueue('msg2');

    // GetConversations() should return a single conversation.
    await _chatContentProvider.getConversations(
      mqConversation1.token,
      (ChatStatus s, List<Conversation> c) {
        status = s;
        conversations = c;
      },
    );
    expect(status, equals(ChatStatus.ok));
    expect(conversations, allOf(isNotNull, hasLength(1)));
    expect(mqConversation1.receivedMessages, allOf(isNotNull, isEmpty));
    conversation0 = conversations[0];

    // GetMessages() should return two messages in the conversation.
    await _chatContentProvider.getMessages(
      conversation0.conversationId,
      mqMessage1.token,
      (ChatStatus s, List<Message> m) {
        status = s;
        messages = m;
      },
    );
    expect(status, equals(ChatStatus.ok));
    expect(messages, allOf(isNotNull, hasLength(2)));
    expect(mqMessage1.receivedMessages, allOf(isNotNull, isEmpty));

    // Add a new conversation and see if mqConversation1 gets notified.
    completer1 = new Completer<Null>();
    mqConversation1.completer = completer1;

    List<String> participants1 = <String>[
      'foo@example.com',
      'bar@example.com',
    ];

    await _chatContentProvider.newConversation(
      participants1,
      (ChatStatus s, Conversation c) {
        status = s;
        conversation1 = c;
      },
    );
    expect(status, equals(ChatStatus.ok));
    expect(conversation1.participants, unorderedEquals(participants1));

    // Wait for the message queue notification.
    await completer1.future.timeout(_kTimeout);
    expect(mqConversation1.receivedMessages, hasLength(1));
    decoded = JSON.decode(mqConversation1.receivedMessages.last);
    expect(decoded, isMap);
    expect(
      decoded['conversation_id'],
      orderedEquals(conversation1.conversationId),
    );
    expect(
      decoded['participants'],
      unorderedEquals(participants1),
    );

    // Register another message queue for conversation.
    await _chatContentProvider.getConversations(
      mqConversation2.token,
      (ChatStatus s, List<Conversation> c) {
        status = s;
        conversations = c;
      },
    );
    expect(status, equals(ChatStatus.ok));
    expect(conversations, allOf(isNotNull, hasLength(2)));

    // Create a new conversation. Both message queues should be notified.
    completer1 = new Completer<Null>();
    completer2 = new Completer<Null>();
    mqConversation1.completer = completer1;
    mqConversation2.completer = completer2;

    List<String> participants2 = <String>[
      'qux@example.com',
      'baz@example.com',
    ];

    await _chatContentProvider.newConversation(
      participants2,
      (ChatStatus s, Conversation c) {
        status = s;
        conversation2 = c;
      },
    );
    expect(status, equals(ChatStatus.ok));
    expect(conversation2.participants, unorderedEquals(participants2));

    // Wait for the message queue notifications.
    await completer1.future.timeout(_kTimeout);
    expect(mqConversation1.receivedMessages, hasLength(2));
    decoded = JSON.decode(mqConversation1.receivedMessages.last);
    expect(decoded, isMap);
    expect(
      decoded['conversation_id'],
      orderedEquals(conversation2.conversationId),
    );
    expect(
      decoded['participants'],
      unorderedEquals(participants2),
    );

    await completer2.future.timeout(_kTimeout);
    expect(mqConversation2.receivedMessages, hasLength(1));
    decoded = JSON.decode(mqConversation1.receivedMessages.last);
    expect(decoded, isMap);
    expect(
      decoded['conversation_id'],
      orderedEquals(conversation2.conversationId),
    );
    expect(
      decoded['participants'],
      unorderedEquals(participants2),
    );

    // Now send a few messages to the initial conversation and see if that
    // message is delivered to the message queue.
    completer1 = new Completer<Null>();
    mqMessage1.completer = completer1;

    await _chatContentProvider.sendMessage(
      conversation0.conversationId,
      'text',
      JSON.encode('sample message1'),
      (ChatStatus s, List<int> mid) {
        status = s;
        messageId = mid;
      },
    );
    expect(status, equals(ChatStatus.ok));

    await completer1.future.timeout(_kTimeout);
    expect(mqMessage1.receivedMessages, hasLength(1));
    decoded = JSON.decode(mqMessage1.receivedMessages.last);
    expect(decoded, isMap);
    expect(
      decoded['conversation_id'],
      orderedEquals(conversation0.conversationId),
    );
    expect(
      decoded['message_id'],
      orderedEquals(messageId),
    );

    // Register another message queue on the initial conversation.
    await _chatContentProvider.getMessages(
      conversation0.conversationId,
      mqMessage2.token,
      (ChatStatus s, List<Message> m) {
        status = s;
        messages = m;
      },
    );
    expect(status, equals(ChatStatus.ok));
    expect(messages, allOf(isNotNull, hasLength(3)));

    // Send another message and see if both message queues are notified.
    completer1 = new Completer<Null>();
    completer2 = new Completer<Null>();
    mqMessage1.completer = completer1;
    mqMessage2.completer = completer2;

    await _chatContentProvider.sendMessage(
      conversation0.conversationId,
      'text',
      JSON.encode('sample message2'),
      (ChatStatus s, List<int> mid) {
        status = s;
        messageId = mid;
      },
    );
    expect(status, equals(ChatStatus.ok));

    await completer1.future.timeout(_kTimeout);
    expect(mqMessage1.receivedMessages, hasLength(2));
    decoded = JSON.decode(mqMessage1.receivedMessages.last);
    expect(decoded, isMap);
    expect(
      decoded['conversation_id'],
      orderedEquals(conversation0.conversationId),
    );
    expect(
      decoded['message_id'],
      orderedEquals(messageId),
    );

    await completer2.future.timeout(_kTimeout);
    expect(mqMessage2.receivedMessages, hasLength(1));
    decoded = JSON.decode(mqMessage1.receivedMessages.last);
    expect(decoded, isMap);
    expect(
      decoded['conversation_id'],
      orderedEquals(conversation0.conversationId),
    );
    expect(
      decoded['message_id'],
      orderedEquals(messageId),
    );

    // Lastly, simulate the situation where a new message arrives from some
    // other user. Both message queues should be notified.
    completer1 = new Completer<Null>();
    completer2 = new Completer<Null>();
    mqMessage1.completer = completer1;
    mqMessage2.completer = completer2;

    messageId = const <int>[0, 1, 2, 3, 4];
    await _mockChatMessageTransporter.mockReceiveMessage(
      conversation0,
      new Message()
        ..messageId = messageId
        ..sender = 'alice@example.com'
        ..timestamp = new DateTime.now().millisecondsSinceEpoch
        ..jsonPayload = JSON.encode('A message from Alice!'),
    );

    await completer1.future.timeout(_kTimeout);
    expect(mqMessage1.receivedMessages, hasLength(3));
    decoded = JSON.decode(mqMessage1.receivedMessages.last);
    expect(decoded, isMap);
    expect(
      decoded['conversation_id'],
      orderedEquals(conversation0.conversationId),
    );
    expect(
      decoded['message_id'],
      orderedEquals(messageId),
    );

    await completer2.future.timeout(_kTimeout);
    expect(mqMessage2.receivedMessages, hasLength(2));
    decoded = JSON.decode(mqMessage1.receivedMessages.last);
    expect(decoded, isMap);
    expect(
      decoded['conversation_id'],
      orderedEquals(conversation0.conversationId),
    );
    expect(
      decoded['message_id'],
      orderedEquals(messageId),
    );

    mqConversation1.close();
    mqConversation2.close();
    mqMessage1.close();
    mqMessage2.close();
  }

  /// Helper method for obtaining a [MessageQueue] from the [ComponentContext].
  Future<_MessageQueueWrapper> _getMessageQueue(String name) async {
    MessageQueueProxy queue = new MessageQueueProxy();
    _componentContext.obtainMessageQueue(
      name,
      queue.ctrl.request(),
    );
    Completer<String> tokenCompleter = new Completer<String>();
    queue.getToken(tokenCompleter.complete);
    String token = await tokenCompleter.future;

    return new _MessageQueueWrapper(queue: queue, token: token);
  }
}

class _MessageQueueWrapper {
  final MessageQueueProxy queue;
  final String token;
  final List<String> receivedMessages = <String>[];

  Completer<Null> completer;

  _MessageQueueWrapper({
    @required this.queue,
    @required this.token,
  }) {
    assert(queue != null);
    assert(token != null);
    queue.receive(handleMessage);
  }

  void handleMessage(String message) {
    receivedMessages.add(message);
    queue.receive(handleMessage);

    // If a completer is given from outside, complete it and set it to null.
    if (completer != null && !completer.isCompleted) {
      completer.complete();
      completer = null;
    }
  }

  void close() {
    queue.ctrl.close();
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
