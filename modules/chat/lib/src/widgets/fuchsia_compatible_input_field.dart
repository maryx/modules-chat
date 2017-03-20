// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const int _kHidUsageKeyboardReturn = 40;
const int _kHidUsageKeyboardBackspace = 42;

/// A fuchsia-compatible [InputField] replacement.
///
/// When the current platform is Fuchsia, it uses the [RawKeyboardInputField]
/// using the [RawKeyboardListener].
///
/// Otherwise, it fallbacks to the regular [InputField] widget.
///
/// Most parameters are taken from the [InputField] widget, but not all of them.
class FuchsiaCompatibleInputField extends StatelessWidget {
  /// Creates a new instance of [FuchsiaCompatibleInputField].
  FuchsiaCompatibleInputField({
    Key key,
    this.focusKey,
    this.value,
    this.hintText,
    this.style,
    this.hintStyle,
    this.obscureText: false,
    this.onChanged,
    this.onSubmitted,
  })
      : super(key: key);

  /// Global key of the widget that holds the focus.
  final GlobalKey focusKey;

  /// The current state of text of the input field. This includes the selected
  /// text, if any, among other things.
  final InputValue value;

  /// Text to show inline in the input field when it would otherwise be empty.
  final String hintText;

  /// The style to use for the text being edited.
  final TextStyle style;

  /// The style to use for the hint text.
  ///
  /// Defaults to the specified TextStyle in style with the hintColor from
  /// the ThemeData
  final TextStyle hintStyle;

  /// Whether to hide the text being edited (e.g., for passwords).
  ///
  /// When this is set to true, all the characters in the input are replaced by
  /// U+2022 BULLET characters (•).
  ///
  /// Defaults to false.
  final bool obscureText;

  /// Called when the text being edited changes.
  ///
  /// The [value] must be updated each time [onChanged] is invoked.
  final ValueChanged<InputValue> onChanged;

  /// Called when the user indicates that they are done editing the text in the field.
  final ValueChanged<InputValue> onSubmitted;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    if (theme.platform == TargetPlatform.fuchsia) {
      return new RawKeyboardInputField(
        focusKey: focusKey,
        value: value,
        hintText: hintText,
        style: style,
        hintStyle: hintStyle,
        obscureText: obscureText,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      );
    } else {
      return new InputField(
        focusKey: focusKey,
        value: value,
        hintText: hintText,
        style: style,
        hintStyle: hintStyle,
        obscureText: obscureText,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      );
    }
  }
}

/// An [InputField] replacement implemented using the [RawKeyboardListener].
///
/// This class does not support IME or software heyboard.
class RawKeyboardInputField extends StatefulWidget {
  /// Creates a new instance of [RawKeyboardInputField].
  RawKeyboardInputField({
    Key key,
    this.focusKey,
    this.value,
    this.hintText,
    this.style,
    this.hintStyle,
    this.obscureText: false,
    this.onChanged,
    this.onSubmitted,
  })
      : super(key: key);

  /// Global key of the widget that holds the focus.
  final GlobalKey focusKey;

  /// The current state of text of the input field. This includes the selected
  /// text, if any, among other things.
  final InputValue value;

  /// Text to show inline in the input field when it would otherwise be empty.
  final String hintText;

  /// The style to use for the text being edited.
  final TextStyle style;

  /// The style to use for the hint text.
  ///
  /// Defaults to the specified TextStyle in style with the hintColor from
  /// the ThemeData
  final TextStyle hintStyle;

  /// Whether to hide the text being edited (e.g., for passwords).
  ///
  /// When this is set to true, all the characters in the input are replaced by
  /// U+2022 BULLET characters (•).
  ///
  /// Defaults to false.
  final bool obscureText;

  /// Called when the text being edited changes.
  ///
  /// The [value] must be updated each time [onChanged] is invoked.
  final ValueChanged<InputValue> onChanged;

  /// Called when the user indicates that they are done editing the text in the field.
  final ValueChanged<InputValue> onSubmitted;

  @override
  _RawKeyboardInputFieldState createState() =>
      new _RawKeyboardInputFieldState();
}

class _RawKeyboardInputFieldState extends State<RawKeyboardInputField> {
  final GlobalKey _rawKeyboardListenerKey = new GlobalKey();
  final GlobalKey<_RawKeyboardInputFieldState> _focusKey =
      new GlobalKey<_RawKeyboardInputFieldState>();

  GlobalKey get focusKey =>
      config.focusKey ?? (config.key is GlobalKey ? config.key : _focusKey);

  String get _currentText => config.value?.text ?? '';

  String get _displayText => (config.obscureText ?? false)
      ? new String.fromCharCodes(
          new List<int>.filled(_currentText.length, 0x2022))
      : _currentText;

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      key: focusKey == _focusKey ? _focusKey : null,
      behavior: HitTestBehavior.opaque,
      onTap: _acquireFocus,
      child: new Builder(
        builder: (BuildContext context) => new RawKeyboardListener(
              key: _rawKeyboardListenerKey,
              onKey: _handleKey,
              focused: Focus.at(focusKey.currentContext),
              // TODO(youngseokyoon): add blinking cursor.
              child: _buildText(context),
            ),
      ),
    );
  }

  Widget _buildText(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TextStyle textStyle = config.style ?? themeData.textTheme.subhead;
    final TextStyle hintStyle =
        config.hintStyle ?? textStyle.copyWith(color: themeData.hintColor);

    return _currentText.isEmpty && config.hintText != null
        ? new Text(config.hintText, style: hintStyle)
        : new Text(_displayText, style: textStyle);
  }

  void _acquireFocus() {
    setState(() {
      Focus.moveTo(focusKey);
    });
  }

  void _handleKey(RawKeyEvent event) {
    // We're only interested in KeyDown event for now.
    if (event is! RawKeyDownEvent) {
      return;
    }

    assert(event.data is RawKeyEventDataFuchsia);
    RawKeyEventDataFuchsia data = event.data;

    if (data.codePoint != 0) {
      String newText = _currentText + new String.fromCharCode(data.codePoint);
      _notifyTextChanged(newText);
    } else if (data.hidUsage == _kHidUsageKeyboardReturn) {
      if (config.onSubmitted != null) {
        config.onSubmitted(config.value);
      }
    } else if (data.hidUsage == _kHidUsageKeyboardBackspace) {
      if (_currentText.isNotEmpty) {
        _notifyTextChanged(_currentText.substring(0, _currentText.length - 1));
      }
    }
  }

  void _notifyTextChanged(String newText) {
    if (config.onChanged != null) {
      config.onChanged(new InputValue(text: newText));
    }
  }
}
