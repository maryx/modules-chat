// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show JSON;

import 'package:apps.ledger.services.public/ledger.fidl.dart';
import 'package:apps.modular.services.component/message_queue.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:meta/meta.dart';

import 'base_page_watcher.dart';

/// A [PageWatcher] implementation that watches for new changes in a
/// conversation log [Page] and sends notifications to the subscriber through
/// the [MessageQueue].
class NewMessageWatcher extends BasePageWatcher {
  /// The id of the conversation that this watcher is watching for.
  final List<int> conversationId;

  /// The [MessageSender] attached to the message queue of the subscriber.
  final MessageSenderProxy messageSender;

  /// Creates a [NewMessageWatcher] instance.
  NewMessageWatcher({
    @required this.conversationId,
    @required this.messageSender,
  }) {
    assert(this.conversationId != null);
    assert(this.messageSender != null);
  }

  @override
  void onChange(
    PageChange pageChange,
    ResultState resultState,
    void callback(InterfaceRequest<PageSnapshot> snapshot),
  ) {
    // The underlying assumption is that there will be no changes to an existing
    // message, and only new messages will be added to a conversation.
    // Therefore, we can safely ignore whether this onChange notification is
    // partial or complete, and just process the messages independently.
    pageChange.changes.forEach(_processEntry);

    callback(null);
  }

  /// Process the provided [Entry] and sends notification to the subscriber.
  /// Refer to the `chat_content_provider.fidl` file for the message format.
  void _processEntry(Entry entry) {
    Map<String, dynamic> newMessageNotification = <String, dynamic>{
      'conversation_id': conversationId,
      'message_id': entry.key,
    };

    messageSender.send(JSON.encode(newMessageNotification));
  }

  @override
  void close() {
    messageSender.ctrl.close();
    super.close();
  }
}
