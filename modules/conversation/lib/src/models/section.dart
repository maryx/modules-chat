// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:util/time_util.dart';

import 'message.dart';

/// A model class representing a [Section] of consecutive chat [Message]s.
///
/// There are three rules being used to determine whether two consecutive
/// [Message]s belong to the same [Section] or not. They should be separated if
/// one of the following conditions is met.
///
/// 1. The senders are different.
/// 2. The dates are different.
/// 3. The times are apart more than an hour.
///
/// Clients are expected to use the [createSectionsFromMessages()] function to
/// create consecutive chat [Section]s from a sorted list of [Message]s.
class Section {
  /// The sorted [List] of [Message]s.
  final List<Message> _messages;

  /// Indicates whether this section needs a date header.
  final bool shouldDisplayDateHeader;

  /// Indicates whether this section needs the timestamp at the end.
  final bool shouldDisplayLastMessageTime;

  /// Creates a new instance of [Section].
  Section({
    @required List<Message> messages,
    bool shouldDisplayDateHeader,
    bool shouldDisplayLastMessageTime,
  })
      : _messages = new List<Message>.from(messages),
        shouldDisplayDateHeader = shouldDisplayDateHeader ?? false,
        shouldDisplayLastMessageTime = shouldDisplayLastMessageTime ?? false {
    assert(messages != null && messages.isNotEmpty);
    assert(messages.every((Message m) => m.sender == sender));
  }

  /// Gets the [Message]s contained in this [Section].
  List<Message> get messages => new UnmodifiableListView<Message>(_messages);

  /// Gets the sender's email address.
  String get sender => messages.first.sender;

  /// Gets the time of the first message.
  DateTime get firstMessageTime => messages.first.time;

  /// Gets the time of the last message.
  DateTime get lastMessageTime => messages.last.time;

  /// Indicates whether this section contains [Message]s from the current user.
  bool get isMyMessage => sender == 'me';
}

/// Returns a [List] of [Section]s from the given [List] of [Message]s. It is
/// assumed that the given list is already sorted by their time in ascending
/// order.
List<Section> createSectionsFromMessages(List<Message> messages) {
  if (messages == null) return null;
  if (messages.isEmpty) return const <Section>[];

  List<List<Message>> sectionCandidates = <List<Message>>[];

  for (int i = 0; i < messages.length; ++i) {
    if (i == 0 || _shouldBeSeparated(messages[i - 1], messages[i])) {
      sectionCandidates.add(<Message>[messages[i]]);
    } else {
      sectionCandidates.last.add(messages[i]);
    }
  }

  List<Section> sections = new List<Section>.generate(
    sectionCandidates.length,
    (int i) => new Section(
          messages: sectionCandidates[i],
          shouldDisplayDateHeader: i == 0 ||
              _onDifferentDate(
                sectionCandidates[i - 1].last,
                sectionCandidates[i].first,
              ),
          shouldDisplayLastMessageTime: i == sectionCandidates.length - 1 ||
              _diffGreaterThanThreshold(
                sectionCandidates[i].last,
                sectionCandidates[i + 1].first,
              ),
        ),
  );

  return sections;
}

bool _shouldBeSeparated(Message m1, Message m2) =>
    m1.sender != m2.sender ||
    _diffGreaterThanThreshold(m1, m2) ||
    _onDifferentDate(m1, m2);

bool _diffGreaterThanThreshold(Message m1, Message m2) =>
    m1.time.difference(m2.time).abs() > const Duration(hours: 1);

bool _onDifferentDate(Message m1, Message m2) =>
    !TimeUtil.isSameDay(m1.time, m2.time);
