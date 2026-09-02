import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glass_theme.dart';

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
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

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
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    width: 56,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white.withOpacity(filled || isActive ? 0.85 : 0.55),
                            border: Border.all(
                              color: widget.hasError
                                  ? LightGlassTheme.danger
                                  : isActive
                                      ? LightGlassTheme.brightGold
                                      : LightGlassTheme.subtleBorder,
                              width: isActive || widget.hasError ? 1.8 : 1.2,
                            ),
                            boxShadow: (isActive && !widget.hasError)
                                ? [
                                    BoxShadow(
                                      color: LightGlassTheme.brightGold.withOpacity(0.32),
                                      blurRadius: 16,
                                      spreadRadius: -2,
                                    ),
                                  ]
                                : widget.hasError
                                    ? [
                                        BoxShadow(
                                          color: LightGlassTheme.danger.withOpacity(0.24),
                                          blurRadius: 14,
                                          spreadRadius: -2,
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: LightGlassTheme.forestGreen.withOpacity(0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                          ),
                          child: Text(
                            filled ? (widget.obscure ? '●' : digits[i]) : '',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: LightGlassTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
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