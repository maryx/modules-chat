// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:matcher/matcher.dart';
import 'package:matcher/src/util.dart';
import 'package:test/src/frontend/expect.dart';
import 'package:test/test.dart';

// TODO(youngseokyoon): consider putting this file under //apps/test_runner.

final Future<Null> _emptyFuture = new Future<Null>.value();

/// Assert that [actual] matches [matcher].
///
/// This version of [expect] function is a reduced version which doesn't require
/// an enclosing `test()` method. This version doesn't support an async matcher.
void expect(
  dynamic actual,
  dynamic matcher, {
  String reason,
}) {
  _expect(actual, matcher, reason: reason);
}

Future<Null> _expect(
  dynamic actual,
  dynamic matcher, {
  String reason,
}) {
  // ignore: deprecated_member_use
  ErrorFormatter formatter = (
    dynamic actual,
    dynamic matcher,
    String reason,
    dynamic matchState,
    bool verbose,
  ) {
    dynamic mismatchDescription = new StringDescription();
    matcher.describeMismatch(actual, mismatchDescription, matchState, verbose);

    // ignore: deprecated_member_use
    return formatFailure(matcher, actual, mismatchDescription.toString(),
        reason: reason);
  };

  matcher = wrapMatcher(matcher);

  dynamic matchState = <dynamic, dynamic>{};
  try {
    if (matcher.matches(actual, matchState)) return _emptyFuture;
  } catch (e, trace) {
    reason ??= '$e at $trace';
  }
  fail(formatter(actual, matcher, reason, matchState, false));
  return _emptyFuture;
}
