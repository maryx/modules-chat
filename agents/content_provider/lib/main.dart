// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.maxwell.services.suggestion/proposal_publisher.fidl.dart';
import 'package:apps.modular.services.agent/agent.fidl.dart';
import 'package:apps.modular.services.agent/agent_context.fidl.dart';
import 'package:apps.modular.services.auth/token_provider.fidl.dart';
import 'package:apps.modular.services.component/component_context.fidl.dart';
import 'package:apps.modular.services.device..info/device_info.fidl.dart';
import 'package:apps.modules.chat.services/chat_content_provider.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';

import 'src/chat_content_provider_impl.dart';
import 'src/firebase_chat_message_transporter.dart';

final ApplicationContext _context = new ApplicationContext.fromStartupInfo();
ChatContentProviderAgent _agent;

void _log(String msg) {
  print('[chat_content_provider] $msg');
}

/// An implementation of the [Agent] interface.
class ChatContentProviderAgent extends Agent {
  final AgentBinding _agentBinding = new AgentBinding();
  final ComponentContextProxy _componentContext = new ComponentContextProxy();

  final ServiceProviderImpl _outgoingServicesImpl = new ServiceProviderImpl();
  final List<ServiceProviderBinding> _outgoingServicesBindings =
      <ServiceProviderBinding>[];

  ChatContentProviderImpl _contentProviderImpl;

  TokenProviderProxy _tokenProvider;

  /// Bind an [InterfaceRequest] for an [Agent] interface to this object.
  void bind(InterfaceRequest<Agent> request) {
    _agentBinding.bind(this, request);
  }

  /// Implements [Agent] interface.
  @override
  Future<Null> initialize(
    InterfaceHandle<AgentContext> agentContextHandle,
    void callback(),
  ) async {
    _log('Agent::initialize start.');

    // Get the ComponentContext
    AgentContextProxy agentContext = new AgentContextProxy()
      ..ctrl.bind(agentContextHandle);
    agentContext.getComponentContext(_componentContext.ctrl.request());

    // Get the device id.
    DeviceInfoProxy deviceInfo = new DeviceInfoProxy();
    connectToService(_context.environmentServices, deviceInfo.ctrl);
    Completer<String> deviceIdCompleter = new Completer<String>();
    deviceInfo.getDeviceIdForSyncing(deviceIdCompleter.complete);
    String deviceId = await deviceIdCompleter.future;
    deviceInfo.ctrl.close();

    // Get the TokenProvider
    _tokenProvider?.ctrl?.close();
    _tokenProvider = new TokenProviderProxy();
    agentContext.getTokenProvider(_tokenProvider.ctrl.request());

    // Initialize the content provider.
    _contentProviderImpl = new ChatContentProviderImpl(
      componentContext: _componentContext,
      chatMessageTransporter: new FirebaseChatMessageTransporter(
        tokenProvider: _tokenProvider,
      ),
      deviceId: deviceId,
    );
    await _contentProviderImpl.initialize();

    // Register the ChatContentProvider service to the outgoingServices
    // service provider.
    _outgoingServicesImpl.addServiceForName(
      (InterfaceRequest<ChatContentProvider> request) {
        _log('Received a ChatContentProvider request');
        _contentProviderImpl.addBinding(request);
      },
      ChatContentProvider.serviceName,
    );

    // Get the ProposalPublisher
    ProposalPublisherProxy proposalPublisher = new ProposalPublisherProxy();
    connectToService(_context.environmentServices, proposalPublisher.ctrl);

    agentContext.ctrl.close();
    proposalPublisher.ctrl.close();

    _log('Agent::initialize end.');

    callback();
  }

  /// Implements [Agent] interface.
  @override
  Future<Null> connect(
    String requestorUrl,
    InterfaceRequest<ServiceProvider> services,
  ) async {
    _log('Agent::connect call from $requestorUrl.');
    _outgoingServicesBindings.add(
      new ServiceProviderBinding()..bind(_outgoingServicesImpl, services),
    );
  }

  /// Implements [Agent] interface.
  @override
  void runTask(String taskId, void callback()) {}

  /// Implements [Agent] interface.
  @override
  void stop(void callback()) {
    _tokenProvider?.ctrl?.close();
    _tokenProvider = null;

    _outgoingServicesBindings
        .forEach((ServiceProviderBinding binding) => binding.close());

    callback();
  }
}

/// Main entry point.
Future<Null> main(List<String> args) async {
  _context.outgoingServices.addServiceForName(
      (InterfaceRequest<Agent> request) {
    if (_agent == null) {
      _agent = new ChatContentProviderAgent()..bind(request);
    } else {
      // Can only connect to this interface once.
      request.close();
    }
  }, Agent.serviceName);
}
