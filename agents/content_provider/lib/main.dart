// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.maxwell.services.suggestion/proposal_publisher.fidl.dart';
import 'package:apps.modular.services.agent/agent.fidl.dart';
import 'package:apps.modular.services.agent/agent_context.fidl.dart';
import 'package:apps.modular.services.component/component_context.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';

final ApplicationContext _context = new ApplicationContext.fromStartupInfo();
ChatContentProviderAgent _agent;

void _log(String msg) {
  print('[chat_content_provider] $msg');
}

/// An implementation of the [Agent] interface.
class ChatContentProviderAgent extends Agent {
  AgentBinding _agentBinding;
  ComponentContextProxy _componentContext;

  final ServiceProviderImpl _outgoingServicesImpl = new ServiceProviderImpl();
  final List<ServiceProviderBinding> _outgoingServicesBindings =
      new List<ServiceProviderBinding>();

  /// Constructor.
  ChatContentProviderAgent(InterfaceRequest<Agent> request) {
    _agentBinding = new AgentBinding()..bind(this, request);
  }

  /// Implements [Agent] interface.
  @override
  Future<Null> initialize(
      InterfaceHandle<AgentContext> agentContextHandle) async {
    _log('Initialize called');

    // Get the ComponentContext
    AgentContextProxy agentContext = new AgentContextProxy()
      ..ctrl.bind(agentContextHandle);
    _componentContext = new ComponentContextProxy();
    agentContext.getComponentContext(_componentContext.ctrl.request());

    // Get the ProposalPublisher
    ProposalPublisherProxy proposalPublisher = new ProposalPublisherProxy();
    connectToService(_context.environmentServices, proposalPublisher.ctrl);

    agentContext.ctrl.close();
    proposalPublisher.ctrl.close();
  }

  /// Implements [Agent] interface.
  @override
  void connect(
      String requestorUrl, InterfaceRequest<ServiceProvider> services) {
    _outgoingServicesBindings.add(
        new ServiceProviderBinding()..bind(_outgoingServicesImpl, services));
  }

  /// Implements [Agent] interface.
  @override
  void runTask(String taskId, void callback()) {}

  /// Implements [Agent] interface.
  @override
  void stop(void callback()) {
    _log('Stop called');

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
      _agent = new ChatContentProviderAgent(request);
    } else {
      // Can only connect to this interface once.
      request.close();
    }
  }, Agent.serviceName);
}
