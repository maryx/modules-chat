// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:typed_data';

import 'package:apps.ledger.services.public/ledger.fidl.dart';
import 'package:apps.modules.chat.services/chat_content_provider.fidl.dart';
import 'package:config/config.dart';
import 'package:fixtures/fixtures.dart';
import 'package:http/http.dart' as http;
import 'package:lib.fidl.dart/bindings.dart' show InterfaceRequest;
import 'package:uuid/uuid.dart';

import 'ledger_utils.dart';

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

  /// Config object obtained from the `/system/data/modules/config.json` file.
  Config _config;

  /// Firebase User ID of the current user.
  String _firebaseUid;

  /// The primary email address of this user.
  String _email;

  /// Firebase auth token obtained from the identity toolkit api.
  String _firebaseAuthToken;

  /// Ledger instance given to the content provider.
  Ledger _ledger;

  /// Reserved [Page]s in the ledger.
  final Map<String, PageProxy> _reservedPages = <String, PageProxy>{};
  Page get _conversationsPage => _reservedPages['conversations'];

  /// Indicates whether the chat content provider is properly initialized.
  final Completer<Null> _ledgerReady = new Completer<Null>();

  /// Runs the startup logic for the chat content provider.
  Future<Null> initialize(Ledger ledger) async {
    _ledger = ledger;

    try {
      /// These two operations don't depend on each other, so just run them in
      /// parallel.
      await Future.wait(<Future<Null>>[
        _initializeLedger(),
        _signInToFirebase(),
      ]);
    } catch (e, stackTrace) {
      _log('Failed to initialize: $e');
      _log(stackTrace.toString());
      return;
    }
  }

  /// Initializes the Ledger instance with all the reserved pages created.
  Future<Null> _initializeLedger() async {
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
  }

  /// Temporary method for adding some sample data.
  // TODO(youngseokyoon): take this out.
  Future<Null> addTestData() async {
    for (int i = 0; i < 3; ++i) {
      await _addConversation();
    }
  }

  Future<Null> _addConversation() async {
    // Request a new page from Ledger.
    PageProxy newConversationPage = new PageProxy();
    _ledger.getPage(null, newConversationPage.ctrl.request(), (Status status) {
      if (status != Status.ok) {
        throw new Exception(
          'Ledger::GetPage() returned an error status: $status',
        );
      }
    });

    // Get the ID of that page, which will be used as the conversation id.
    Completer<Uint8List> idCompleter = new Completer<Uint8List>();
    newConversationPage.getId(
      (List<int> id) => idCompleter.complete(new Uint8List.fromList(id)),
    );
    Uint8List conversationId = await idCompleter.future;

    // Put the conversation entry to the conversations page.
    Completer<Status> statusCompleter = new Completer<Status>();
    _conversationsPage.put(
      conversationId,
      encodeLedgerValue(<String, dynamic>{
        'participants': <String>[_randomEmail(), _randomEmail()],
      }),
      (Status s) => statusCompleter.complete(s),
    );
    Status status = await statusCompleter.future;
    if (status != Status.ok) {
      throw new Exception('Page::Put() returned an error status: $status');
    }

    // Put some example data in the conversation log page.
    for (int i = 0; i < 3; ++i) {
      Message message = _randomMessage();
      Map<String, dynamic> messageObject = <String, dynamic>{
        'sender': message.sender,
        'type': message.type,
        'json_payload': message.jsonPayload,
      };

      Uint8List messageId = new Uint8List(_kKeyLengthInBytes);
      messageId[_kKeyLengthInBytes - 1] = i + 1;
      statusCompleter = new Completer<Status>();
      newConversationPage.put(
        messageId,
        encodeLedgerValue(messageObject),
        (Status s) => statusCompleter.complete(s),
      );
      status = await statusCompleter.future;
      if (status != Status.ok) {
        throw new Exception(
          'Page::Put() returned an error status: $status',
        );
      }
    }

    // Close the page.
    newConversationPage.ctrl.close();
  }

  /// Sign in to the firebase DB using the given google auth credentials.
  Future<Null> _signInToFirebase() async {
    // First, see if the required config values are all provided.
    Config config = await Config.read('/system/data/modules/config.json');
    List<String> keys = <String>[
      'chat_firebase_api_key',
      'chat_firebase_project_id',
      'id_token',
      'oauth_token',
    ];

    config.validate(keys);
    _config = config;

    // Make a call to identitytoolkit API to register the current user to the
    // Firebase project, and obtain the Firebase UID for this user.
    Uri identityToolkitUrl = new Uri.https(
      'www.googleapis.com',
      '/identitytoolkit/v3/relyingparty/verifyAssertion',
      <String, String>{
        'key': _config.get('chat_firebase_api_key'),
      },
    );

    http.Response identityToolkitResponse = await http.post(
      identityToolkitUrl,
      headers: <String, String>{
        'accept': 'application/json',
        'content-type': 'application/json',
      },
      body: JSON.encode(<String, dynamic>{
        'postBody': 'id_token=${_config.get('id_token')}&providerId=google.com',
        'requestUri': 'http://localhost',
        'returnIdpCredential': true,
        'returnSecureToken': true,
      }),
    );

    if (identityToolkitResponse.statusCode != 200 ||
        (identityToolkitResponse.body?.isEmpty ?? true)) {
      throw new Exception(
          'identityToolkit#verifyAssertion call was unsuccessful.\n'
          'status code: ${identityToolkitResponse.statusCode}\n'
          'body: ${identityToolkitResponse.body}');
    }

    // Parse the response.
    String responseBody = identityToolkitResponse.body;
    dynamic responseJson;
    try {
      responseJson = JSON.decode(responseBody);
    } catch (e) {
      throw new Exception(
          'Error parsing JSON response from identityToolkit#verifyAssertion '
          'response.\n'
          'body: $responseBody');
    }

    _firebaseUid = responseJson['localId'];
    _email = _normalizeEmail(responseJson['email']);
    _firebaseAuthToken = responseJson['idToken'];

    if (_firebaseUid == null || _email == null || _firebaseAuthToken == null) {
      throw new Exception(
          'identityToolkit#verifyAssertion response is missing one of the '
          'expected parameters (localId, email, idToken).\n'
          'body: $responseBody');
    }
  }

  /// Make a GET request to the firebase DB.
  // ignore: unused_element
  Future<http.Response> _firebaseDBGet(String path) {
    Uri url = _getFirebaseUrl(path);
    return http.get(
      url,
    );
  }

  /// Make a PUT request to the firebase DB.
  // ignore: unused_element
  Future<http.Response> _firebaseDBPut(String path, dynamic data) {
    Uri url = _getFirebaseUrl(path);
    return http.put(
      url,
      headers: <String, String>{
        'content-type': 'application/json',
      },
      body: JSON.encode(data),
    );
  }

  /// Returns the firebase DB url with the given data path.
  Uri _getFirebaseUrl(String path) {
    return new Uri.https(
      '${_config.get('chat_firebase_project_id')}.firebaseio.com',
      '$path.json',
      <String, String>{
        'auth': _firebaseAuthToken,
      },
    );
  }

  /// Normalize the email address.
  String _normalizeEmail(String email) {
    int atSignIndex = email?.indexOf('@') ?? -1;
    if (atSignIndex == -1) {
      return email;
    }

    String lowerCaseEmail = email.toLowerCase();
    String username = lowerCaseEmail.substring(0, atSignIndex);
    String domain = lowerCaseEmail.substring(atSignIndex + 1);

    if (domain == 'gmail.com') {
      return '${username.replaceAll('.', '')}@$domain';
    }

    return lowerCaseEmail;
  }

  /// Bind this instance with the given request, and keep the binding object
  /// in the binding list.
  void addBinding(InterfaceRequest<ChatContentProvider> request) {
    _bindings.add(new ChatContentProviderBinding()..bind(this, request));
  }

  /// Close all the bindings.
  void close() {
    _reservedPages.values.forEach((PageProxy page) => page?.ctrl?.close());

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

  @override
  Future<Null> getConversations(
    void callback(List<Conversation> conversations),
  ) async {
    await _ledgerReady.future;

    // Get the current snapshot of the 'conversations' page.
    PageSnapshotProxy snapshot = new PageSnapshotProxy();

    _conversationsPage.getSnapshot(
      snapshot.ctrl.request(),
      null,
      (Status status) {
        if (status != Status.ok) {
          throw new Exception(
            'Page::GetSnapshot() returned an error status: $status',
          );
        }
      },
    );

    List<Entry> entries = await getFullEntries(snapshot);
    List<Conversation> conversations = <Conversation>[];
    entries.forEach((Entry entry) {
      dynamic decodedValue = decodeLedgerValue(entry.value);

      Conversation conversation = new Conversation()
        ..conversationId = entry.key
        ..participants = decodedValue['participants']
            .map((String email) => new User()..emailAddress = email)
            .toList();

      conversations.add(conversation);
    });

    snapshot.ctrl.close();

    callback(conversations);
  }

  @override
  Future<Null> getMessageHistory(
    List<int> conversationId,
    void callback(List<Message> messages),
  ) async {
    await _ledgerReady.future;

    _log('getMessageHistory() called with conversationId: $conversationId');

    // Get the current snapshot of the specified conversation page.
    PageProxy conversationPage = new PageProxy();
    _ledger.getPage(
      conversationId,
      conversationPage.ctrl.request(),
      (Status status) {
        if (status != Status.ok) {
          throw new Exception(
            'Ledger::GetPage() returned an error status: $status',
          );
        }
      },
    );

    PageSnapshotProxy snapshot = new PageSnapshotProxy();
    conversationPage.getSnapshot(
      snapshot.ctrl.request(),
      null,
      (Status status) {
        if (status != Status.ok) {
          throw new Exception(
            'Page::GetSnapshot() returned an error status: $status',
          );
        }
      },
    );

    List<Entry> entries = await getFullEntries(snapshot);
    List<Message> messages = <Message>[];
    entries.forEach((Entry entry) {
      dynamic decodedValue = decodeLedgerValue(entry.value);

      Message message = new Message()
        ..messageId = entry.key
        ..sender = decodedValue['sender']
        ..type = decodedValue['type']
        ..jsonPayload = decodedValue['json_payload'];

      messages.add(message);
    });

    snapshot.ctrl.close();
    conversationPage.ctrl.close();

    callback(messages);
  }

  // TODO(youngseokyoon): implement this more efficiently by only fetching the
  // last message from the ledger.
  @override
  void getLastMessage(
    List<int> conversationId,
    void callback(Message message),
  ) {
    getMessageHistory(conversationId, (List<Message> messages) {
      callback((messages == null || messages.isEmpty) ? null : messages.last);
    });
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

  String _randomEmail() => _emailFromName(new Fixtures().name());

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
