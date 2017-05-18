// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert' show UTF8;
import 'dart:typed_data';

import 'package:apps.ledger.services.public/ledger.fidl.dart';
import 'package:apps.modular.services.component/component_context.fidl.dart';
import 'package:apps.modular.services.component/message_queue.fidl.dart';
import 'package:apps.modular.services.device..info/device_info.fidl.dart';
import 'package:apps.modules.chat.services/chat_content_provider.fidl.dart';
import 'package:collection/collection.dart';
import 'package:lib.fidl.dart/bindings.dart' show InterfaceRequest;
import 'package:lib.fidl.dart/core.dart' show Vmo;
import 'package:meta/meta.dart';
import 'package:quiver/core.dart' as quiver;

import 'base_page_watcher.dart';
import 'chat_message_transporter.dart';
import 'ledger_utils.dart';
import 'new_conversation_watcher.dart';
import 'new_message_watcher.dart';

void _log(String msg) {
  print('[chat_content_provider_impl] $msg');
}

const int _kKeyLengthInBytes = 16;

/// Defines a reserved [Page] for the Ledger instance.
class _ReservedPage {
  final String name;
  final Uint8List id;
  const _ReservedPage({this.name, this.id});
}

/// List of reserved pages to be used for Chat modules.
final List<_ReservedPage> _kReservedPages = <_ReservedPage>[
  new _ReservedPage(
    name: 'conversations',
    id: new Uint8List.fromList(
      const <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    ),
  ),
];

/// Implementation of the [ChatContentProvider] fidl interface.
class ChatContentProviderImpl extends ChatContentProvider {
  // Keeps the list of bindings.
  final List<ChatContentProviderBinding> _bindings =
      <ChatContentProviderBinding>[];

  /// [ComponentContext] from which we obtain the [Ledger] and [MessageSender]s.
  final ComponentContext componentContext;

  /// [ChatMessageTransporter] for sending / receiveing messages between users.
  final ChatMessageTransporter chatMessageTransporter;

  /// The device id obtained from the [DeviceInfo] service.
  final String deviceId;

  /// The device id encoded in UTF8.
  final Uint8List deviceIdBytes;

  /// [Ledger] instance given to the content provider.
  LedgerProxy _ledger;

  /// Keeps the map of message queue tokens and the [BasePageWatcher] instances
  /// so the [PageWatcherBinding]s can be correctly closed later.
  final Map<String, BasePageWatcher> _pageWatchers =
      <String, BasePageWatcher>{};

  /// Reserved [Page]s in the ledger.
  final Map<String, PageProxy> _reservedPages = <String, PageProxy>{};

  /// Local cache of the [Conversation] objects.
  ///
  /// We have to manually provide the hashCode / equals implementation so that
  /// the [List<int>] ids can be used as keys.
  final Map<List<int>, Conversation> _conversationCache =
      new HashMap<List<int>, Conversation>(
    equals: const ListEquality<int>().equals,
    hashCode: (List<int> key) => quiver.hashObjects(key),
    isValidKey: (dynamic key) => key is List<int>,
  );

  /// The last index of the messages that the current user sent to other people.
  /// This value is added to the message ids to prevent id collision.
  int _messageIndex = 0;

  /// Indicates whether the [Ledger] initialization is successfully done.
  final Completer<Null> _ledgerReady = new Completer<Null>();

  /// Creates a new [ChatContentProviderImpl] instance.
  ChatContentProviderImpl({
    @required this.componentContext,
    @required this.chatMessageTransporter,
    this.deviceId,
  })
      : deviceIdBytes = deviceId != null
            ? new Uint8List.fromList(UTF8.encode(deviceId))
            : new Uint8List(0) {
    assert(componentContext != null);
    assert(chatMessageTransporter != null);

    chatMessageTransporter.onReceived = _handleMessage;
  }

  Page get _conversationsPage => _reservedPages['conversations'];

  /// Runs the startup logic for the chat content provider.
  Future<Null> initialize() async {
    try {
      /// These two operations don't depend on each other, so just run them in
      /// parallel.
      await Future.wait(<Future<Null>>[
        _initializeLedger(),
        chatMessageTransporter.initialize(),
      ]);
    } catch (e, stackTrace) {
      _log('Failed to initialize: $e');
      _log(stackTrace.toString());
      return;
    }
  }

  /// Initializes the Ledger instance with all the reserved pages created.
  Future<Null> _initializeLedger() async {
    _ledger?.ctrl?.close();
    _ledger = new LedgerProxy();

    try {
      // Obtain the Ledger instance for this agent.
      Completer<Status> statusCompleter = new Completer<Status>();
      componentContext.getLedger(
        _ledger.ctrl.request(),
        statusCompleter.complete,
      );
      Status status = await statusCompleter.future;

      if (status != Status.ok) {
        throw new Exception(
          'ComponentContext::GetLedger returned an error status: $status',
        );
      }

      _reservedPages.values.forEach((PageProxy page) => page?.ctrl?.close());
      _reservedPages.clear();

      await Future.forEach(_kReservedPages, (_ReservedPage pageInfo) {
        PageProxy page = new PageProxy();
        _ledger.getPage(pageInfo.id, page.ctrl.request(), (Status status) {
          if (status != Status.ok) {
            throw new Exception(
              'Ledger::GetPage() returned an error status: $status',
            );
          }
        });
        _reservedPages[pageInfo.name] = page;
      });

      _ledgerReady.complete();
      _log('Ledger Initialized');
    } catch (e) {
      _ledgerReady.completeError(e);
      _log('Failed to initialize Ledger');
      rethrow;
    }
  }

  /// Returns true if the given [email] address is not a valid one.
  bool _isEmailNotValid(String email) {
    // TODO(youngseokyoon): implement this properly.
    // https://fuchsia.atlassian.net/browse/SO-370
    return false;
  }

  /// Bind this instance with the given request, and keep the binding object
  /// in the binding list.
  void addBinding(InterfaceRequest<ChatContentProvider> request) {
    _bindings.add(new ChatContentProviderBinding()..bind(this, request));
  }

  /// Close all the bindings.
  void close() {
    _reservedPages.values.forEach((PageProxy page) => page?.ctrl?.close());

    _pageWatchers.values.forEach((BasePageWatcher watcher) => watcher.close());

    _bindings.forEach(
      (ChatContentProviderBinding binding) => binding.close(),
    );
  }

  @override
  Future<Null> newConversation(
    List<String> participants,
    void callback(
      ChatStatus chatStatus,
      Conversation conversation,
    ),
  ) async {
    try {
      try {
        await _ledgerReady.future;
      } catch (e) {
        callback(ChatStatus.ledgerNotInitialized, null);
        return;
      }

      // Validate the email addresses first.
      if (participants == null || participants.any(_isEmailNotValid)) {
        callback(ChatStatus.invalidEmailAddress, null);
        return;
      }

      PageProxy newConversationPage = new PageProxy();

      try {
        // Request a new page from Ledger.
        Completer<Status> statusCompleter = new Completer<Status>();
        _ledger.getPage(
          null,
          newConversationPage.ctrl.request(),
          statusCompleter.complete,
        );

        Status status = await statusCompleter.future;
        if (status != Status.ok) {
          _log('Ledger::GetPage() returned an error status: $status');
          callback(ChatStatus.ledgerOperationError, null);
          return;
        }

        // Get the ID of that page, which will be used as the conversation id.
        Completer<Uint8List> idCompleter = new Completer<Uint8List>();
        newConversationPage.getId(
          (List<int> id) => idCompleter.complete(new Uint8List.fromList(id)),
        );
        Uint8List conversationId = await idCompleter.future;

        // Put the conversation entry to the conversations page.
        statusCompleter = new Completer<Status>();
        _conversationsPage.put(
          conversationId,
          encodeLedgerValue(<String, dynamic>{
            'participants': participants,
          }),
          statusCompleter.complete,
        );

        status = await statusCompleter.future;
        if (status != Status.ok) {
          _log('Page::Put() returned an error status: $status');
          callback(ChatStatus.ledgerOperationError, null);
          return;
        }

        // Return the created conversation.
        Conversation conversation = new Conversation()
          ..conversationId = conversationId
          ..participants = participants;

        _conversationCache[conversationId] = conversation;

        callback(ChatStatus.ok, conversation);
      } finally {
        newConversationPage.ctrl.close();
      }
    } catch (e, stackTrace) {
      _log('ERROR: Sending ChatStatus.unknownError caused by: $e.');
      _log(stackTrace.toString());
      callback(ChatStatus.unknownError, null);
    }
  }

  @override
  Future<Null> getConversations(
    String messageQueueToken,
    void callback(ChatStatus chatStatus, List<Conversation> conversations),
  ) async {
    try {
      try {
        await _ledgerReady.future;
      } catch (e) {
        callback(ChatStatus.ledgerNotInitialized, const <Conversation>[]);
        return;
      }

      // Get the current snapshot of the 'conversations' page.
      PageSnapshotProxy snapshot = new PageSnapshotProxy();

      try {
        // Here, we create a [NewconversationWatcher] instance in case the
        // client gave us a message queue token.
        NewConversationWatcher newConversationWatcher;
        if (messageQueueToken != null) {
          MessageSenderProxy messageSender = new MessageSenderProxy();
          componentContext.getMessageSender(
            messageQueueToken,
            messageSender.ctrl.request(),
          );

          newConversationWatcher = new NewConversationWatcher(
            messageSender: messageSender,
          );

          _pageWatchers[messageQueueToken]?.close();
          _pageWatchers[messageQueueToken] = newConversationWatcher;
        }

        Completer<Status> statusCompleter = new Completer<Status>();
        _conversationsPage.getSnapshot(
          snapshot.ctrl.request(),
          null,
          newConversationWatcher?.handle,
          statusCompleter.complete,
        );

        Status status = await statusCompleter.future;
        if (status != Status.ok) {
          _log('Page::GetSnapshot() returned an error status: $status');
          callback(ChatStatus.ledgerOperationError, const <Conversation>[]);
          return;
        }

        List<Entry> entries;
        try {
          entries = await getFullEntries(snapshot);
        } catch (e) {
          _log(e);
          callback(ChatStatus.ledgerOperationError, const <Conversation>[]);
          return;
        }

        try {
          List<Conversation> conversations = <Conversation>[];

          entries.forEach((Entry entry) {
            Conversation conversation = _createConversationFromLedgerEntry(
              entry.key,
              entry.value,
            );
            conversations.add(conversation);
            _conversationCache[entry.key] = conversation;
          });

          callback(ChatStatus.ok, conversations);
        } catch (e) {
          _log(e);
          callback(ChatStatus.decodingError, const <Conversation>[]);
        }
      } finally {
        snapshot.ctrl.close();
      }
    } catch (e, stackTrace) {
      _log('ERROR: Sending ChatStatus.unknownError caused by: $e.');
      _log(stackTrace.toString());
      callback(ChatStatus.unknownError, const <Conversation>[]);
    }
  }

  @override
  Future<Null> getMessages(
    List<int> conversationId,
    String messageQueueToken,
    void callback(ChatStatus chatStatus, List<Message> messages),
  ) async {
    try {
      try {
        await _ledgerReady.future;
      } catch (e) {
        callback(ChatStatus.ledgerNotInitialized, const <Message>[]);
        return;
      }

      // Get the current snapshot of the specified conversation page.
      PageProxy conversationPage = new PageProxy();
      PageSnapshotProxy snapshot = new PageSnapshotProxy();

      try {
        Completer<Status> statusCompleter = new Completer<Status>();
        _ledger.getPage(
          conversationId,
          conversationPage.ctrl.request(),
          statusCompleter.complete,
        );

        Status status = await statusCompleter.future;
        if (status != Status.ok) {
          _log('Ledger::GetPage() returned an error status: $status');
          callback(ChatStatus.ledgerOperationError, const <Message>[]);
          return;
        }

        // Here, we create a [NewMessageWatcher] instance in case the client
        // gave us a message queue token.
        NewMessageWatcher newMessageWatcher;
        if (messageQueueToken != null) {
          MessageSenderProxy messageSender = new MessageSenderProxy();
          componentContext.getMessageSender(
            messageQueueToken,
            messageSender.ctrl.request(),
          );

          newMessageWatcher = new NewMessageWatcher(
            conversationId: conversationId,
            messageSender: messageSender,
          );

          _pageWatchers[messageQueueToken]?.close();
          _pageWatchers[messageQueueToken] = newMessageWatcher;
        }

        statusCompleter = new Completer<Status>();
        conversationPage.getSnapshot(
          snapshot.ctrl.request(),
          null,
          newMessageWatcher?.handle,
          statusCompleter.complete,
        );

        status = await statusCompleter.future;
        if (status != Status.ok) {
          _log('Page::GetSnapshot() returned an error status: $status');
          callback(ChatStatus.ledgerOperationError, const <Message>[]);
          return;
        }

        List<Entry> entries;
        try {
          entries = await getFullEntries(snapshot);
        } catch (e) {
          _log(e);
          callback(ChatStatus.ledgerOperationError, const <Message>[]);
          return;
        }

        try {
          List<Message> messages = entries
              .map((Entry entry) =>
                  _createMessageFromLedgerEntry(entry.key, entry.value))
              .toList();

          callback(ChatStatus.ok, messages);
        } catch (e) {
          _log(e);
          callback(ChatStatus.decodingError, const <Message>[]);
        }
      } finally {
        snapshot.ctrl.close();
        conversationPage.ctrl.close();
      }
    } catch (e, stackTrace) {
      _log('ERROR: Sending ChatStatus.unknownError caused by: $e.');
      _log(stackTrace.toString());
      callback(ChatStatus.unknownError, const <Message>[]);
    }
  }

  @override
  Future<Null> getMessage(
    List<int> conversationId,
    List<int> messageId,
    void callback(ChatStatus chatStatus, Message message),
  ) async {
    try {
      try {
        await _ledgerReady.future;
      } catch (e) {
        callback(ChatStatus.ledgerNotInitialized, null);
        return;
      }

      // Get the current snapshot of the specified conversation page.
      PageProxy conversationPage = new PageProxy();
      PageSnapshotProxy snapshot = new PageSnapshotProxy();

      try {
        Completer<Status> statusCompleter = new Completer<Status>();
        _ledger.getPage(
          conversationId,
          conversationPage.ctrl.request(),
          statusCompleter.complete,
        );

        Status status = await statusCompleter.future;
        if (status != Status.ok) {
          _log('Ledger::GetPage() returned an error status: $status');
          callback(ChatStatus.ledgerOperationError, null);
          return;
        }

        statusCompleter = new Completer<Status>();
        conversationPage.getSnapshot(
          snapshot.ctrl.request(),
          null,
          null,
          statusCompleter.complete,
        );

        status = await statusCompleter.future;
        if (status != Status.ok) {
          _log('Page::GetSnapshot() returned an error status: $status');
          callback(ChatStatus.ledgerOperationError, null);
        }

        statusCompleter = new Completer<Status>();
        Completer<Vmo> valueCompleter = new Completer<Vmo>();
        snapshot.get(messageId, (Status status, Vmo value) {
          statusCompleter.complete(status);
          valueCompleter.complete(value);
        });

        status = await statusCompleter.future;
        if (status != Status.ok) {
          // Handle the KEY_NOT_FOUND error separately.
          if (status == Status.keyNotFound) {
            callback(ChatStatus.idNotFound, null);
            return;
          }

          _log('PageSnapshot::Get() returned an error status: $status');
          callback(ChatStatus.ledgerOperationError, null);
          return;
        }

        Vmo value = await valueCompleter.future;
        try {
          Message message = _createMessageFromLedgerEntry(messageId, value);
          callback(ChatStatus.ok, message);
        } catch (e) {
          _log(e);
          callback(ChatStatus.decodingError, null);
        }
      } finally {
        snapshot.ctrl.close();
        conversationPage.ctrl.close();
      }
    } catch (e, stackTrace) {
      _log('ERROR: Sending ChatStatus.unknownError caused by: $e.');
      _log(stackTrace.toString());
      callback(ChatStatus.unknownError, null);
    }
  }

  // TODO(youngseokyoon): implement this more efficiently by only fetching the
  // last message from the ledger.
  @override
  Future<Null> getLastMessage(
    List<int> conversationId,
    void callback(ChatStatus chatStatus, Message message),
  ) async {
    await getMessages(
      conversationId,
      null,
      (ChatStatus cs, List<Message> messages) {
        callback(
          cs,
          messages.isEmpty ? null : messages.last,
        );
      },
    );
  }

  @override
  Future<Null> sendMessage(
    List<int> conversationId,
    String type,
    String jsonPayload,
    void callback(ChatStatus chatStatus, List<int> messageId),
  ) async {
    try {
      try {
        await _ledgerReady.future;
      } catch (e) {
        callback(ChatStatus.ledgerNotInitialized, const <int>[]);
        return;
      }

      // First, store the message in the current user's Ledger.

      // The message id is constructed by concatenating three values: the local
      // timestamp, incremental message index, and device id.
      // Refer to the `chat_content_provider.fidl` file for the full rationale.
      int localTimestamp = new DateTime.now().millisecondsSinceEpoch;
      Uint8List messageId = new Uint8List(12 + deviceIdBytes.lengthInBytes);
      new ByteData.view(messageId.buffer)
        ..setInt64(0, localTimestamp)
        ..setInt32(8, _messageIndex++);
      messageId.setRange(12, 12 + deviceIdBytes.lengthInBytes, deviceIdBytes);

      Map<String, dynamic> localMessageObject = <String, dynamic>{
        'id': messageId,
        'timestamp': localTimestamp,
        'sender': 'me',
        'type': type,
        'json_payload': jsonPayload,
      };

      // Get the current snapshot of the specified conversation page.
      PageProxy conversationPage = new PageProxy();

      try {
        Completer<Status> statusCompleter = new Completer<Status>();
        _ledger.getPage(
          conversationId,
          conversationPage.ctrl.request(),
          statusCompleter.complete,
        );

        Status status = await statusCompleter.future;
        if (status != Status.ok) {
          _log('Ledger::GetPage() returned an error status: $status');
          callback(ChatStatus.ledgerOperationError, const <int>[]);
          return;
        }

        // Put the message object to the ledger.
        statusCompleter = new Completer<Status>();
        conversationPage.put(
          messageId,
          encodeLedgerValue(localMessageObject),
          statusCompleter.complete,
        );

        status = await statusCompleter.future;
        if (status != Status.ok) {
          _log('Page::Put() returned an error status: $status');
          callback(ChatStatus.ledgerOperationError, const <int>[]);
          return;
        }
      } finally {
        conversationPage.ctrl.close();
      }

      Conversation conversation = await _getConversation(conversationId);

      // Send the message via the chat message transporter.
      // In case of an error, depending on the type of exception we get, we
      // return different status codes to the client.
      try {
        await chatMessageTransporter.sendMessage(
          conversation: conversation,
          messageId: messageId,
          type: type,
          jsonPayload: jsonPayload,
        );
      } on ChatAuthenticationException {
        callback(ChatStatus.authenticationError, const <int>[]);
      } on ChatAuthorizationException {
        callback(ChatStatus.permissionError, const <int>[]);
      } on ChatNetworkException {
        callback(ChatStatus.networkError, const <int>[]);
      }

      callback(ChatStatus.ok, messageId);
    } catch (e, stackTrace) {
      _log('ERROR: Sending ChatStatus.unknownError caused by: $e.');
      _log(stackTrace.toString());
      callback(ChatStatus.unknownError, const <int>[]);
    }
  }

  @override
  void unsubscribe(String messageQueueToken) {
    _pageWatchers[messageQueueToken]?.close();
    _pageWatchers.remove(messageQueueToken);
  }

  /// Gets the [Conversation] object associated with the given [conversationId].
  ///
  /// The [conversationId] is assumed to be valid, and this method will throw an
  /// exception when the given id is not found in the `Conversations` page.
  Future<Conversation> _getConversation(List<int> conversationId) async {
    // Look for the conversation id from the local cache.
    if (!_conversationCache.containsKey(conversationId)) {
      return _conversationCache[conversationId];
    }

    // Get the current snapshot of the 'conversations' page.
    PageSnapshotProxy snapshot = new PageSnapshotProxy();

    _conversationsPage.getSnapshot(
      snapshot.ctrl.request(),
      null,
      null,
      (Status status) {
        if (status != Status.ok) {
          throw new Exception(
            'Page::GetSnapshot() returned an error status: $status',
          );
        }
      },
    );

    Completer<Status> statusCompleter = new Completer<Status>();
    Completer<Vmo> valueCompleter = new Completer<Vmo>();
    snapshot.get(conversationId, (Status status, Vmo value) {
      statusCompleter.complete(status);
      valueCompleter.complete(value);
    });

    Status status = await statusCompleter.future;
    if (status != Status.ok) {
      throw new Exception(
        'PageSnapshot::Get() returned an error status: $status',
      );
    }

    Vmo value = await valueCompleter.future;
    Conversation conversation =
        _createConversationFromLedgerEntry(conversationId, value);
    _conversationCache[conversationId] = conversation;

    snapshot.ctrl.close();

    return conversation;
  }

  Conversation _createConversationFromLedgerEntry(List<int> key, Vmo value) {
    Map<String, dynamic> decodedValue = decodeLedgerValue(value);
    return new Conversation()
      ..conversationId = key
      ..participants = decodedValue['participants'];
  }

  Message _createMessageFromLedgerEntry(List<int> key, Vmo value) {
    Map<String, dynamic> decodedValue = decodeLedgerValue(value);
    return new Message()
      ..messageId = key
      ..sender = decodedValue['sender']
      ..timestamp = decodedValue['timestamp'] ?? 0
      ..type = decodedValue['type']
      ..jsonPayload = decodedValue['json_payload'];
  }

  /// Handles a newly received message from another user.
  Future<Null> _handleMessage(
    Conversation conversation,
    Message message,
  ) async {
    try {
      await _ledgerReady.future;

      Conversation cachedConversation =
          await _getConversation(conversation.conversationId);

      PageProxy conversationPage = new PageProxy();
      try {
        // Request a new page from Ledger.
        Completer<Status> statusCompleter = new Completer<Status>();
        _ledger.getPage(
          conversation.conversationId,
          conversationPage.ctrl.request(),
          statusCompleter.complete,
        );

        Status status = await statusCompleter.future;
        if (status != Status.ok) {
          _log('Ledger::GetPage() returned an error status: $status');
          return;
        }

        if (cachedConversation == null) {
          // Put the conversation entry to the conversations page.
          statusCompleter = new Completer<Status>();
          _conversationsPage.put(
            conversation.conversationId,
            encodeLedgerValue(<String, dynamic>{
              'participants': conversation.participants,
            }),
            statusCompleter.complete,
          );

          status = await statusCompleter.future;
          if (status != Status.ok) {
            _log('Page::Put() returned an error status: $status');
          }

          _conversationCache[conversation.conversationId] = conversation;
        }

        Map<String, dynamic> localMessageObject = _messageToJson(message);

        // Put the message object to the ledger.
        statusCompleter = new Completer<Status>();
        conversationPage.put(
          message.messageId,
          encodeLedgerValue(localMessageObject),
          statusCompleter.complete,
        );

        status = await statusCompleter.future;
        if (status != Status.ok) {
          _log('Page::Put() returned an error status: $status');
          return;
        }
      } finally {
        conversationPage.ctrl.close();
      }
    } catch (e, stackTrace) {
      _log('An error occurred while processing an incoming message.');
      _log('$e');
      _log('$stackTrace');
    }
  }

  /// Returns the JSON encodable [Map] representation of the given message,
  /// which can be encoded and stored in [Ledger].
  Map<String, dynamic> _messageToJson(Message message) => <String, dynamic>{
        'id': message.messageId,
        'timestamp': message.timestamp,
        'sender': message.sender,
        'type': message.type,
        'json_payload': message.jsonPayload,
      };
}
