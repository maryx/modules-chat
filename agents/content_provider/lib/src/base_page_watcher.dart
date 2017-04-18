// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.ledger.services.public/ledger.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';

/// Base class for our [PageWatcher] implementations.
abstract class BasePageWatcher extends PageWatcher {
  final PageWatcherBinding _binding = new PageWatcherBinding();

  /// Gets the [InterfaceHandle] for this [PageWatcher] implementation.
  InterfaceHandle<PageWatcher> get handle => _binding.wrap(this);

  /// Closes the binding.
  void close() {
    _binding.close();
  }
}
