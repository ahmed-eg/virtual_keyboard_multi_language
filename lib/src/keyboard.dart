part of virtual_keyboard_multi_language;

/// The default keyboard height. Can we overriden by passing
///  `height` argument to `VirtualKeyboard` widget.
const double _virtualKeyboardDefaultHeight = 300;

const int _virtualKeyboardBackspaceEventPerioud = 250;

/// Virtual Keyboard widget.
class VirtualKeyboard extends StatefulWidget {
  /// Keyboard Type: Should be inited in creation time.
  final VirtualKeyboardType type;

  /// Callback for Key press event. Called with pressed `Key` object.
  /// will fire before adding key's text to controller if a controller is provided
  final Function(VirtualKeyboardKey key)? preKeyPress;

  /// Callback for Key press event. Called with pressed `Key` object.
  /// will fire after adding key's text to controller if a controller is provided
  final Function(VirtualKeyboardKey key)? postKeyPress;

  /// Virtual keyboard height. Default is 300
  final double height;

  /// Virtual keyboard height. Default is full screen width
  final double? width;

  /// Color for key texts and icons.
  final Color textColor;

  /// Font size for keyboard keys.
  final double fontSize;

  /// the custom layout for multi or single language
  final VirtualKeyboardLayoutKeys? customLayoutKeys;

  /// the text controller go get the output and send the default input
  final TextEditingController? textController;

  /// The builder function will be called for each Key object.
  final Widget Function(BuildContext context, VirtualKeyboardKey key)? builder;

  /// Set to true if you want only to show Caps letters.
  final bool alwaysCaps;

  /// inverse the layout to fix the issues with right to left languages.
  final bool reverseLayout;

  /// used for multi-languages with default layouts, the default is English only
  /// will be ignored if customLayoutKeys is not null
  final List<VirtualKeyboardDefaultLayouts>? defaultLayouts;

  VirtualKeyboard(
      {Key? key,
      required this.type,
      this.preKeyPress,
      this.postKeyPress,
      this.builder,
      this.width,
      this.defaultLayouts,
      this.customLayoutKeys,
      this.textController,
      this.reverseLayout = false,
      this.height = _virtualKeyboardDefaultHeight,
      this.textColor = Colors.black,
      this.fontSize = 14,
      this.alwaysCaps = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VirtualKeyboardState();
  }
}

/// Holds the state for Virtual Keyboard class.
class _VirtualKeyboardState extends State<VirtualKeyboard> {
  VirtualKeyboardType type = VirtualKeyboardType.Alphanumeric;
  Function(VirtualKeyboardKey key)? preKeyPress;
  Function(VirtualKeyboardKey key)? postKeyPress;
  TextEditingController? textController;

  // The builder function will be called for each Key object.
  Widget Function(BuildContext context, VirtualKeyboardKey key)? builder;
  late double height;
  double? width;
  late Color textColor;
  late double fontSize;
  late bool alwaysCaps;
  late bool reverseLayout;
  late VirtualKeyboardLayoutKeys customLayoutKeys;

  // Text Style for keys.
  late TextStyle textStyle;

  // True if shift is enabled.
  bool isShiftEnabled = false;

  void _onKeyPress(VirtualKeyboardKey key) {
    if (preKeyPress != null) preKeyPress!(key);

    if (key.keyType == VirtualKeyboardKeyType.String) {
      if (isShiftEnabled) {
        _insertText(key.capsText!);
      } else {
        _insertText(key.text!);
      }
    } else if (key.keyType == VirtualKeyboardKeyType.Action) {
      switch (key.action) {
        case VirtualKeyboardKeyAction.Backspace:
          _backspace();
          break;
        case VirtualKeyboardKeyAction.Return:
          _insertText('\n');
          break;
        case VirtualKeyboardKeyAction.Space:
          _insertText(key.text!);
          break;
        case VirtualKeyboardKeyAction.Shift:
          break;
        default:
      }
    }

    if (postKeyPress != null) postKeyPress!(key);
  }

  void _insertText(String myText) {
    if (textController != null) {
      final text = textController!.text;
      final textSelection = textController!.selection;
      final newText = text.replaceRange(
        (textSelection.start >= 0) ? textSelection.start : 0,
        (textSelection.end >= 0) ? textSelection.end : 0,
        myText,
      );
      final myTextLength = myText.length;
      textController!.text = newText;
      textController!.selection = textSelection.copyWith(
        baseOffset: min(
            textSelection.start + myTextLength, textController!.text.length),
        extentOffset: min(
            textSelection.start + myTextLength, textController!.text.length),
      );
    }
  }

  void _backspace() {
    if (textController != null) {
      final text = textController!.text;
      final textSelection = textController!.selection;
      final selectionLength = textSelection.end - textSelection.start;

      // There is a selection.
      if (selectionLength > 0) {
        final newText = text.replaceRange(
          textSelection.start,
          textSelection.end,
          '',
        );
        textController!.text = newText;
        textController!.selection = textSelection.copyWith(
          baseOffset: textSelection.start,
          extentOffset: textSelection.start,
        );
        return;
      }

      // The cursor is at the beginning.
      if (textSelection.start == 0) {
        return;
      }

      // Delete the previous character
      final previousCodeUnit = text.codeUnitAt(textSelection.start - 1);
      final offset = _isUtf16Surrogate(previousCodeUnit) ? 2 : 1;
      final newStart = textSelection.start - offset;
      final newEnd = textSelection.start;
      final newText = text.replaceRange(
        newStart,
        newEnd,
        '',
      );
      textController!.text = newText;
      textController!.selection = textSelection.copyWith(
        baseOffset: newStart,
        extentOffset: newStart,
      );
    }
  }

  bool _isUtf16Surrogate(int value) {
    return value & 0xF800 == 0xD800;
  }

  @override
  void didUpdateWidget(VirtualKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      type = widget.type;
      preKeyPress = widget.preKeyPress;
      postKeyPress = widget.postKeyPress;
      height = widget.height;
      width = widget.width;
      textColor = widget.textColor;
      fontSize = widget.fontSize;
      alwaysCaps = widget.alwaysCaps;
      reverseLayout = widget.reverseLayout;
      textController = widget.textController;
      customLayoutKeys = widget.customLayoutKeys ?? customLayoutKeys;
      // Init the Text Style for keys.
      textStyle = TextStyle(
        fontSize: fontSize,
        color: textColor,
      );
    });
  }

  @override
  void initState() {
    super.initState();

    textController = widget.textController;
    width = widget.width;
    type = widget.type;
    customLayoutKeys = widget.customLayoutKeys ??
        VirtualKeyboardDefaultLayoutKeys(
            widget.defaultLayouts ?? [VirtualKeyboardDefaultLayouts.English]);
    preKeyPress = widget.preKeyPress;
    postKeyPress = widget.postKeyPress;
    height = widget.height;
    textColor = widget.textColor;
    fontSize = widget.fontSize;
    alwaysCaps = widget.alwaysCaps;
    reverseLayout = widget.reverseLayout;
    // Init the Text Style for keys.
    textStyle = TextStyle(
      fontSize: fontSize,
      color: textColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return type == VirtualKeyboardType.Numeric ? _numeric() : _alphanumeric();
  }

  Widget _alphanumeric() {
    return Container(
      height: height,
      width: width ?? MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _rows(),
      ),
    );
  }

  Widget _numeric() {
    return Container(
      height: height,
      width: width ?? MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _rows(),
      ),
    );
  }

  /// Returns the rows for keyboard.
  List<Widget> _rows() {
    // Get the keyboard Rows
    List<List<VirtualKeyboardKey>> keyboardRows =
        type == VirtualKeyboardType.Numeric
            ? _getKeyboardRowsNumeric()
            : _getKeyboardRows(customLayoutKeys);

    // Generate keyboard row.
    List<Widget> rows = List.generate(keyboardRows.length, (int rowNum) {
      var items = List.generate(keyboardRows[rowNum].length, (int keyNum) {
        // Get the VirtualKeyboardKey object.
        VirtualKeyboardKey virtualKeyboardKey = keyboardRows[rowNum][keyNum];

        Widget keyWidget;

        // Check if builder is specified.
        // Call builder function if specified or use default
        //  Key widgets if not.
        if (builder == null) {
          // Check the key type.
          switch (virtualKeyboardKey.keyType) {
            case VirtualKeyboardKeyType.String:
              // Draw String key.
              keyWidget = _keyboardDefaultKey(virtualKeyboardKey);
              break;
            case VirtualKeyboardKeyType.Action:
              // Draw action key.
              keyWidget = _keyboardDefaultActionKey(virtualKeyboardKey);
              break;
          }
        } else {
          // Call the builder function, so the user can specify custom UI for keys.
          keyWidget = builder!(context, virtualKeyboardKey);
        }

        return keyWidget;
      });

      if (this.reverseLayout) items = items.reversed.toList();
      return Material(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          // Generate keboard keys
          children: items,
        ),
      );
    });

    return rows;
  }

  // True if long press is enabled.
  bool longPress = false;

  /// Creates default UI element for keyboard Key.
  Widget _keyboardDefaultKey(VirtualKeyboardKey key) {
    return Expanded(
        child: InkWell(
      onTap: () {
        _onKeyPress(key);
      },
      child: Container(
        height: height / customLayoutKeys.activeLayout.length,
        child: Center(
            child: Text(
          alwaysCaps
              ? key.capsText!
              : (isShiftEnabled ? key.capsText! : key.text!),
          style: textStyle,
        )),
      ),
    ));
  }

  /// Creates default UI element for keyboard Action Key.
  Widget _keyboardDefaultActionKey(VirtualKeyboardKey key) {
    // Holds the action key widget.
    Widget actionKey;

    // Switch the action type to build action Key widget.
    switch (key.action!) {
      case VirtualKeyboardKeyAction.Backspace:
        actionKey = GestureDetector(
            onLongPress: () {
              longPress = true;
              // Start sending backspace key events while longPress is true
              Timer.periodic(
                  Duration(milliseconds: _virtualKeyboardBackspaceEventPerioud),
                  (timer) {
                if (longPress) {
                  _onKeyPress(key);
                } else {
                  // Cancel timer.
                  timer.cancel();
                }
              });
            },
            onLongPressUp: () {
              // Cancel event loop
              longPress = false;
            },
            child: Container(
              height: double.infinity,
              width: double.infinity,
              child: Icon(
                Icons.backspace,
                color: textColor,
              ),
            ));
        break;
      case VirtualKeyboardKeyAction.Shift:
        actionKey = Icon(Icons.arrow_upward, color: textColor);
        break;
      case VirtualKeyboardKeyAction.Space:
        actionKey = actionKey = Icon(Icons.space_bar, color: textColor);
        break;
      case VirtualKeyboardKeyAction.Return:
        actionKey = Icon(
          Icons.keyboard_return,
          color: textColor,
        );
        break;
      case VirtualKeyboardKeyAction.SwithLanguage:
        actionKey = GestureDetector(
            onTap: () {
              setState(() {
                customLayoutKeys.switchLanguage();
              });
            },
            child: Container(
              height: double.infinity,
              width: double.infinity,
              child: Icon(
                Icons.language,
                color: textColor,
              ),
            ));
        break;
    }

    var wdgt = InkWell(
      onTap: () {
        if (key.action == VirtualKeyboardKeyAction.Shift) {
          if (!alwaysCaps) {
            setState(() {
              isShiftEnabled = !isShiftEnabled;
            });
          }
        }

        _onKeyPress(key);
      },
      child: Container(
        alignment: Alignment.center,
        height: height / customLayoutKeys.activeLayout.length,
        child: actionKey,
      ),
    );

    if (key.action == VirtualKeyboardKeyAction.Space)
      return Expanded(flex: 6, child: wdgt);
    else
      return Expanded(child: wdgt);
  }
}
