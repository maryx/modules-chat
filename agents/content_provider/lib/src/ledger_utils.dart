// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON, UTF8;
import 'dart:math' show Random;
import 'dart:typed_data' show ByteData, Uint8List;

import 'package:apps.ledger.services.public/ledger.fidl.dart';
import 'package:lib.fidl.dart/core.dart';

// This file defines global functions that are useful for directly manipulating
// Ledger data.

/// Encodes the given value first into a JSON string and then encode in UTF8.
List<int> encodeLedgerValue(dynamic value) => UTF8.encode(JSON.encode(value));

/// Decodes the given [Vmo] into a Dart Object. This assumes that the data held
/// in the given [Vmo] is encoded in JSON and UTF8.
///
/// This throws an exception when it fails to decode the given data.
dynamic decodeLedgerValue(Vmo value) {
  VmoGetSizeResult sizeResult = value.getSize();
  if (sizeResult.status != NO_ERROR) {
    throw new Exception('Unable to retrieve vmo size: ${sizeResult.status}');
  }

  Uint8List data = new Uint8List(sizeResult.size);
  VmoReadResult readResult = value.read(new ByteData.view(data.buffer));
  if (readResult.status != NO_ERROR) {
    throw new Exception('Unable to read from vmo: ${readResult.status}');
  }
  if (readResult.bytesRead != sizeResult.size) {
    throw new Exception('Unexpected count of bytes read.');
  }

  return JSON.decode(UTF8.decode(data));
}

/// Gets the full list of [Entry] objects from a given [PageSnapshot].
///
/// This will continuously call the [PageSnapshot.getEntries] method in case the
/// returned status code is [Status.partialResult].
Future<List<Entry>> getFullEntries(
  PageSnapshot snapshot, {
  List<int> keyPrefix,
}) async {
  List<Entry> entries = <Entry>[];
  await _getFullEntriesRecursively(snapshot, entries);
  return entries;
}

/// Helper method for the [getFullEntries] method.
Future<Null> _getFullEntriesRecursively(
  PageSnapshot snapshot,
  List<Entry> result, {
  List<int> keyPrefix,
  List<int> token,
}) async {
  Completer<Status> statusCompleter = new Completer<Status>();
  List<Entry> entries;
  List<int> nextToken;

  snapshot.getEntries(keyPrefix, token,
      (Status status, List<Entry> entriesResult, List<int> nextTokenResult) {
    entries = entriesResult;
    nextToken = nextTokenResult;
    statusCompleter.complete(status);
  });

  Status status = await statusCompleter.future;

  if (status != Status.ok && status != Status.partialResult) {
    throw new Exception(
      'PageSnapshot::GetEntries() returned an error status: $status',
    );
  }

  result.addAll(entries ?? const <Entry>[]);
  if (status == Status.partialResult) {
    await _getFullEntriesRecursively(
      snapshot,
      result,
      keyPrefix: keyPrefix,
      token: nextToken,
    );
  }
}

/// Returns a randomly generated id value. Each element in the returned [List]
/// is a byte value, and the length of it will be equal to [lengthInBytes].
List<int> generateRandomId(int lengthInBytes) {
  Random random = new Random(new DateTime.now().millisecondsSinceEpoch);
  Uint8List id = new Uint8List(lengthInBytes);
  for (int i = 0; i < id.lengthInBytes; ++i) {
    id[i] = random.nextInt(256);
  }
  return id;
}
