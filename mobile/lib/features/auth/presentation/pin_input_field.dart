import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A row of tappable PIN boxes backed by a single hidden [TextField].
///
/// Using one hidden field (instead of four separate controllers/FocusNodes,
/// the classic OTP-box pattern) sidesteps the usual fiddly auto-advance /
/// backspace-across-boxes bugs — the OS keyboard and text editing just work
/// as normal, and the boxes are purely a visual reflection of its value.
class PinInputField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final bool obscure;
  final bool hasError;
  final int length;
  final bool autofocus;

  const PinInputField({
    super.key,
    required this.onChanged,
    this.onCompleted,
    this.obscure = true,
    this.hasError = false,
    this.length = 4,
    this.autofocus = false,
  });

  @override
  State<PinInputField> createState() => PinInputFieldState();
}

class PinInputFieldState extends State<PinInputField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Focus changes affect which box is highlighted as "active", so they
    // need to trigger a rebuild even though the text itself didn't change.
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Wipes the entered digits — handy after a failed login attempt so the
  /// person isn't stuck editing four dots that no longer mean anything.
  void clear() {
    _controller.clear();
    widget.onChanged('');
  }

  void requestFocus() => _focusNode.requestFocus();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focusNode.requestFocus,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final digits = value.text;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.length, (i) {
                  final filled = i < digits.length;
                  final isActive = i == digits.length && _focusNode.hasFocus;
                  return Container(
                    width: 56,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: widget.hasError
                            ? const Color(0xFFD9534F)
                            : isActive
                                ? const Color(0xFF0F5132)
                                : const Color(0xFFE7ECE6),
                        width: isActive || widget.hasError ? 1.8 : 1.2,
                      ),
                    ),
                    child: Text(
                      filled ? (widget.obscure ? '●' : digits[i]) : '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF14231C),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          // The actual input surface — invisible, 1x1, but focusable and
          // keyboard-driven like any other text field.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                showCursor: false,
                decoration: const InputDecoration(border: InputBorder.none),
                onChanged: (value) {
                  widget.onChanged(value);
                  if (value.length == widget.length) {
                    widget.onCompleted?.call(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
