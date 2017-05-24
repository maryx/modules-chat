// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:application.lib.app.dart/app.dart';
import 'package:apps.modular.services.device..info/device_info.fidl.dart';
import 'package:apps.modules.chat.services/chat_content_provider.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:lib.modular/modular.dart';
import 'package:meta/meta.dart';

import 'src/chat_content_provider_impl.dart';
import 'src/firebase_chat_message_transporter.dart';

ChatContentProviderAgent _agent;

void _log(String msg) {
  print('[chat_content_provider] $msg');
}

/// An implementation of the [Agent] interface.
class ChatContentProviderAgent extends AgentImpl {
  ChatContentProviderImpl _contentProviderImpl;

  /// Creates a new instance of [ChatContentProviderAgent].
  ChatContentProviderAgent({@required ApplicationContext applicationContext})
      : super(applicationContext: applicationContext);

  @override
  Future<Null> onReady(
    ApplicationContext applicationContext,
    AgentContext agentContext,
    ComponentContext componentContext,
    TokenProvider tokenProvider,
    ServiceProviderImpl outgoingServices,
  ) async {
    _log('onReady start.');

    // Get the device id.
    DeviceInfoProxy deviceInfo = new DeviceInfoProxy();
    connectToService(applicationContext.environmentServices, deviceInfo.ctrl);
    Completer<String> deviceIdCompleter = new Completer<String>();
    deviceInfo.getDeviceIdForSyncing(deviceIdCompleter.complete);
    String deviceId = await deviceIdCompleter.future;
    deviceInfo.ctrl.close();

    // Initialize the content provider.
    _contentProviderImpl = new ChatContentProviderImpl(
      componentContext: componentContext,
      chatMessageTransporter: new FirebaseChatMessageTransporter(
        tokenProvider: tokenProvider,
      ),
      deviceId: deviceId,
    );
    await _contentProviderImpl.initialize();

    // Register the ChatContentProvider service to the outgoingServices
    // service provider.
    outgoingServices.addServiceForName(
      (InterfaceRequest<ChatContentProvider> request) {
        _log('Received a ChatContentProvider request');
        _contentProviderImpl.addBinding(request);
      },
      ChatContentProvider.serviceName,
    );

    _log('onReady end.');
  }
}

/// Main entry point.
Future<Null> main(List<String> args) async {
  _agent = new ChatContentProviderAgent(
    applicationContext: new ApplicationContext.fromStartupInfo(),
  );
  _agent.advertise();
}
