// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:math';

import 'package:apps.modules.chat.services/chat_content_provider.fidl.dart';
import 'package:config/config.dart';
import 'package:fixtures/fixtures.dart';
import 'package:http/http.dart' as http;
import 'package:lib.fidl.dart/bindings.dart' show InterfaceRequest;
import 'package:uuid/uuid.dart';

void _log(String msg) {
  print('[chat_content_provider_impl] $msg');
}

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

  /// Indicates whether the chat content provider is properly initialized.
  final Completer<bool> _ready = new Completer<bool>();

  /// Runs the startup logic for the chat content provider.
  Future<Null> initialize() async {
    // First, see if the required config values are all provided.
    Config config = await Config.read('/system/data/modules/config.json');
    List<String> keys = <String>[
      'chat_firebase_api_key',
      'chat_firebase_project_id',
      'id_token',
      'oauth_token',
    ];

    try {
      config.validate(keys);
      _config = config;

      await _signInToFirebase();
      await _updateUserInfo();
    } catch (e, stackTrace) {
      _log('Failed to initialize: $e');
      _log(stackTrace.toString());
      return;
    }

    _ready.complete(true);
  }

  /// Sign in to the firebase DB using the given google auth credentials.
  Future<Null> _signInToFirebase() async {
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

    // Parse the response.
    // TODO(youngseokyoon): add more explicit error handling.
    dynamic identityJson = JSON.decode(identityToolkitResponse.body);
    _firebaseUid = identityJson['localId'];
    _email = _normalizeEmail(identityJson['email']);
    _firebaseAuthToken = identityJson['idToken'];

    if (_firebaseUid == null || _email == null || _firebaseAuthToken == null) {
      throw new Exception(
          'Failed to initialize: could not parse the response from the '
          'identitytoolkit API\n: ${identityToolkitResponse.body}');
    }
  }

  /// Updates the current user's email address to the firebase DB's user
  /// directory, so that other users can search this user by email.
  ///
  /// The email data is stored in:
  ///
  ///     /users/<firebase-uid>/email: <normalized-email-address>
  ///
  Future<Null> _updateUserInfo() async {
    http.Response response = await _firebaseDBPut(
      '/users/$_firebaseUid/email',
      _email,
    );

    if (response.statusCode != 200) {
      throw new Exception(
        '_updateUserInfo operation failed (code: ${response.statusCode})',
      );
    }

    // Make sure that the value is actually written.
    http.Response getResponse = await _firebaseDBGet(
      '/users/$_firebaseUid/email',
    );

    if (getResponse.statusCode != 200 ||
        JSON.decode(getResponse.body) != _email) {
      throw new Exception(
        '_updateUserInfo: failed to confirm the updated user info.',
      );
    }

    _log('Successfully updated user info for $_email');
  }

  /// Make a GET request to the firebase DB.
  Future<http.Response> _firebaseDBGet(String path) {
    Uri url = _getFirebaseUrl(path);
    return http.get(
      url,
    );
  }

  /// Make a PUT request to the firebase DB.
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
