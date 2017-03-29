// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:apps.modules.chat.services/chat_content_provider.fidl.dart';
import 'package:fixtures/fixtures.dart';
import 'package:lib.fidl.dart/bindings.dart' show InterfaceRequest;
import 'package:uuid/uuid.dart';

/// Implementation of the [ChatContentProvider] fidl interface.
class ChatContentProviderImpl extends ChatContentProvider {
  // Keeps the list of bindings.
  final List<ChatContentProviderBinding> _bindings =
      <ChatContentProviderBinding>[];

  /// Runs the startup logic for the chat content provider.
  Future<Null> initialize() async {
    // TODO(youngseokyoon): add the startup logic here.
  }

  /// Bind this instance with the given request, and keep the binding object
  /// in the binding list.
  void addBinding(InterfaceRequest<ChatContentProvider> request) {
    _bindings.add(new ChatContentProviderBinding()..bind(this, request));
  }

  /// Close all the bindings.
  void close() {
    _bindings.forEach(
      (ChatContentProviderBinding binding) => binding.close(),
    );
  }

  /// NOTE: Temporary implementation.
  // TODO(youngseokyoon): properly implement with the ledger.
  @override
  void me(void callback(User user)) {
    callback(_randomUser());
  }

  /// NOTE: Temporary implementation.
  // TODO(youngseokyoon): properly implement with the ledger.
  @override
  void getUser(String emailAddress, void callback(User user)) {
    callback(null);
  }

  /// NOTE: Temporary implementation.
  // TODO(youngseokyoon): properly implement with the ledger.
  @override
  void getConversations(void callback(List<Conversation> conversations)) {
    Random random = new Random();
    List<Conversation> conversations = <Conversation>[];
    for (int i = 0; i < 3 + random.nextInt(3); ++i) {
      conversations.add(_randomConversation());
    }

    callback(conversations);
  }

  /// NOTE: Temporary implementation.
  // TODO(youngseokyoon): properly implement with the ledger.
  @override
  void getMessageHistory(
    List<int> conversationId,
    void callback(List<Message> messages),
  ) {
    Random random = new Random();
    List<Message> messages = <Message>[];
    for (int i = 0; i < 3 + random.nextInt(3); ++i) {
      messages.add(_randomMessage());
    }

    callback(messages);
  }

  /// NOTE: Temporary implementation.
  // TODO(youngseokyoon): properly implement with the ledger.
  @override
  void getMessage(List<int> messageId, void callback(Message message)) {
    callback(_randomMessage());
  }

  /// NOTE: Temporary implementation.
  // TODO(youngseokyoon): properly implement with the ledger.
  @override
  void getLastMessage(
    List<int> conversationId,
    void callback(Message message),
  ) {
    callback(_randomMessage());
  }

  /// NOTE: Temporary implementation.
  // TODO(youngseokyoon): properly implement with the ledger.
  @override
  void sendMessage(
    List<int> conversationId,
    String type,
    String jsonPayload,
    void callback(List<int> messageId),
  ) {
    callback(_randomId());
  }

  /// Temporary method for creating a random user.
  User _randomUser() {
    Fixtures fixtures = new Fixtures();
    String name = fixtures.name();
    String email = _emailFromName(name);
    return new User.init(email, name, null);
  }

  String _emailFromName(String name) =>
      '${name.toLowerCase().split(' ').join('.')}@example.com';

  /// Temporary method for creating a random conversation.
  Conversation _randomConversation() {
    Random random = new Random();
    List<User> participants = <User>[];
    for (int i = 0; i < 2 + random.nextInt(2); ++i) {
      participants.add(_randomUser());
    }

    return new Conversation.init(
      _randomId(),
      participants,
    );
  }

  /// Temporary method for creating a random message.
  Message _randomMessage() {
    return new Message.init(
      _randomId(),
      new DateTime.now().millisecondsSinceEpoch,
      _emailFromName(new Fixtures().name()),
      'text',
      new Fixtures().lorem.createSentence(),
    );
  }

  /// Temporary method for creating a random id.
  List<int> _randomId() => new Uuid().v4().toString().codeUnits;
}
