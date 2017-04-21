// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show JSON;

import 'package:apps.ledger.services.public/ledger.fidl.dart';
import 'package:apps.modular.services.component/message_queue.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:meta/meta.dart';

import 'base_page_watcher.dart';
import 'ledger_utils.dart';

/// A [PageWatcher] implementation that watches for changes in the
/// `conversations` [Page] which stores the list of all conversations. Whenever
/// a new [Entry] is added to this page, this [NewConversationWatcher] sends
/// notifications to the subscriber through the [MessageQueue].
class NewConversationWatcher extends BasePageWatcher {
  /// The [MessageSender] attached to the message queue of the subscriber.
  final MessageSenderProxy messageSender;

  /// Creates a [NewConversationWatcher] instance.
  NewConversationWatcher({
    @required this.messageSender,
  }) {
    assert(this.messageSender != null);
  }

  @override
  void onChange(
    PageChange pageChange,
    ResultState resultState,
    void callback(InterfaceRequest<PageSnapshot> snapshot),
  ) {
    // The underlying assumption is that there will be no changes to an existing
    // conversation, and only new conversations will be added to the list of all
    // conversations. Therefore, we can safely ignore whether this onChange
    // notification is partial or complete, and just process the changes
    // independently.
    pageChange.changes.forEach(_processEntry);

    callback(null);
  }

  /// Process the provided [Entry] and sends notification to the subscriber.
  /// Refer to the `chat_content_provider.fidl` file for the message format.
  void _processEntry(Entry entry) {
    Map<String, dynamic> decoded = decodeLedgerValue(entry.value);

    Map<String, dynamic> newConversationNotification = <String, dynamic>{
      'conversation_id': entry.key,
      'participants': decoded['participants'],
    };

    messageSender.send(JSON.encode(newConversationNotification));
  }

  @override
  void close() {
    messageSender.ctrl.close();
    super.close();
  }
}
