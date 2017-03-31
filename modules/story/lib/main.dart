// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.modular.services.module/module.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modular.services.module/module_controller.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:apps.mozart.lib.flutter/child_view.dart';
import 'package:apps.mozart.services.views/view_token.fidl.dart';
import 'package:flutter/material.dart';
import 'package:lib.fidl.dart/bindings.dart';

const String _kChatListUrl = 'file:///system/apps/chat_conversation_list';
const String _kChatConversationUrl = 'file:///system/apps/chat_conversation';

final ApplicationContext _appContext = new ApplicationContext.fromStartupInfo();
final GlobalKey<_HomeScreenState> _kHomeKey = new GlobalKey<_HomeScreenState>();

ModuleImpl _module;
ChildViewConnection _connConversationList;
ChildViewConnection _connConversation;

void _log(String msg) {
  print('[chat_story] $msg');
}

/// An implementation of the [Module] interface.
class ModuleImpl extends Module {
  final ModuleBinding _binding = new ModuleBinding();

  /// [ModuleContext] service provided by the framework.
  final ModuleContextProxy moduleContext = new ModuleContextProxy();

  /// [Link] service provided by the framework.
  final LinkProxy link = new LinkProxy();

  /// Bind an [InterfaceRequest] for a [Module] interface to this object.
  void bind(InterfaceRequest<Module> request) {
    _binding.bind(this, request);
  }

  @override
  void initialize(
      InterfaceHandle<ModuleContext> moduleContextHandle,
      InterfaceHandle<Link> linkHandle,
      InterfaceHandle<ServiceProvider> incomingServices,
      InterfaceRequest<ServiceProvider> outgoingServices) {
    _log('Module::initialize call.');

    moduleContext.ctrl.bind(moduleContextHandle);
    link.ctrl.bind(linkHandle);

    // Launch the conversation list module.
    InterfaceHandle<ViewOwner> conversationListViewOwner = startModule(
      url: _kChatListUrl,
    );
    _connConversationList = new ChildViewConnection(conversationListViewOwner);

    // Launch the conversation module.
    InterfaceHandle<ViewOwner> conversationViewOwner = startModule(
      url: _kChatConversationUrl,
    );
    _connConversation = new ChildViewConnection(conversationViewOwner);

    updateUI();
  }

  @override
  void stop(void callback()) {
    moduleContext.ctrl.close();
    link.ctrl.close();
    callback();
  }

  /// Updates the UI by calling setState on the [_HomeScreenState] object.
  void updateUI() {
    _kHomeKey.currentState?.updateUI();
  }

  /// Start a module and return its [ViewOwner] handle.
  InterfaceHandle<ViewOwner> startModule({
    String url,
    InterfaceHandle<ServiceProvider> outgoingServices,
    InterfaceRequest<ServiceProvider> incomingServices,
  }) {
    InterfacePair<ViewOwner> viewOwnerPair = new InterfacePair<ViewOwner>();
    InterfacePair<ModuleController> moduleControllerPair =
        new InterfacePair<ModuleController>();

    _log('Starting sub-module: $url');
    moduleContext.startModule(
      url,
      duplicateLink(),
      outgoingServices,
      incomingServices,
      moduleControllerPair.passRequest(),
      viewOwnerPair.passRequest(),
    );
    _log('Started sub-module: $url');

    return viewOwnerPair.passHandle();
  }

  /// Obtains a duplicated [InterfaceHandle] for the given [Link] object.
  InterfaceHandle<Link> duplicateLink() {
    InterfacePair<Link> linkPair = new InterfacePair<Link>();
    link.dup(linkPair.passRequest());
    return linkPair.passHandle();
  }
}

/// Entry point for this module.
void main() {
  _appContext.outgoingServices.addServiceForName(
    (InterfaceRequest<Module> request) {
      if (_module == null) {
        _module = new ModuleImpl();
      }

      _module.bind(request);
    },
    Module.serviceName,
  );

  runApp(new HomeScreen(key: _kHomeKey));
}

/// The top-level widget for the chat_story module.
class HomeScreen extends StatefulWidget {
  /// Creates a new instance of [HomeScreen].
  HomeScreen({Key key}) : super(key: key);

  @override
  _HomeScreenState createState() => new _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData(primarySwatch: Colors.purple),
      home: new Material(
        child: new Row(
          children: <Widget>[
            new Expanded(
              flex: 1,
              child: new Container(
                decoration: new BoxDecoration(
                  border: new Border(
                    right: new BorderSide(color: Colors.grey[300]),
                  ),
                ),
                child: _connConversationList != null
                    ? new ChildView(connection: _connConversationList)
                    : new Container(),
              ),
            ),
            new Expanded(
              flex: 2,
              child: _connConversation != null
                  ? new ChildView(connection: _connConversation)
                  : new Container(),
            )
          ],
        ),
      ),
    );
  }

  /// Refresh the UI.
  void updateUI() {
    setState(() {});
  }
}
