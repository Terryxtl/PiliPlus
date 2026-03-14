import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DualSliderDialog extends StatefulWidget {
  final double value1;
  final double value2;
  final String title;
  final String description1;
  final String description2;
  final double min;
  final double max;
  final int? divisions;
  final String suffix;
  final int precise;

  const DualSliderDialog({
    super.key,
    required this.value1,
    required this.value2,
    required this.description1,
    required this.description2,
    required this.title,
    required this.min,
    required this.max,
    this.divisions,
    this.suffix = '',
    this.precise = 1,
  });

  @override
  State<DualSliderDialog> createState() => _DualSliderDialogState();
}

class _DualSliderDialogState extends State<DualSliderDialog> {
  late double _tempValue1;
  late double _tempValue2;
  late final TextEditingController _controller1;
  late final TextEditingController _controller2;
  late final FocusNode _focusNode1;
  late final FocusNode _focusNode2;
  late final List<TextInputFormatter> _inputFormatters;

  @override
  void initState() {
    super.initState();
    _tempValue1 = _normalizeValue(widget.value1);
    _tempValue2 = _normalizeValue(widget.value2);
    _controller1 = TextEditingController(text: _formatValue(_tempValue1));
    _controller2 = TextEditingController(text: _formatValue(_tempValue2));
    _focusNode1 = FocusNode()
      ..addListener(() => _handleFocusChange(_focusNode1, 1));
    _focusNode2 = FocusNode()
      ..addListener(() => _handleFocusChange(_focusNode2, 2));
    _inputFormatters = _buildInputFormatters();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _focusNode1.dispose();
    _focusNode2.dispose();
    super.dispose();
  }

  double _normalizeValue(double value) =>
      value.clamp(widget.min, widget.max).toPrecision(widget.precise);

  String _formatValue(double value) {
    final text = value.toStringAsFixed(widget.precise);
    if (widget.precise == 0) {
      return text;
    }
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  List<TextInputFormatter> _buildInputFormatters() {
    if (widget.precise == 0) {
      return [FilteringTextInputFormatter.digitsOnly];
    }
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      TextInputFormatter.withFunction((oldValue, newValue) {
        final text = newValue.text;
        if (text.isEmpty || text == '.') {
          return newValue;
        }
        final parts = text.split('.');
        if (parts.length > 2) {
          return oldValue;
        }
        if (parts.length == 2 && parts[1].length > widget.precise) {
          return oldValue;
        }
        return newValue;
      }),
    ];
  }

  void _handleFocusChange(FocusNode focusNode, int index) {
    if (!focusNode.hasFocus && mounted) {
      _commitInputValue(index);
    }
  }

  void _setValue(int index, double value) {
    final normalized = _normalizeValue(value);
    final controller = index == 1 ? _controller1 : _controller2;
    setState(() {
      if (index == 1) {
        _tempValue1 = normalized;
      } else {
        _tempValue2 = normalized;
      }
      final text = _formatValue(normalized);
      controller.value = controller.value.copyWith(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  void _commitInputValue(int index) {
    final controller = index == 1 ? _controller1 : _controller2;
    final fallbackValue = index == 1 ? _tempValue1 : _tempValue2;
    final parsed = double.tryParse(controller.text);
    final normalized = _normalizeValue(parsed ?? fallbackValue);
    final formatted = _formatValue(normalized);
    if ((index == 1 ? _tempValue1 : _tempValue2) == normalized &&
        controller.text == formatted) {
      return;
    }
    setState(() {
      if (index == 1) {
        _tempValue1 = normalized;
      } else {
        _tempValue2 = normalized;
      }
      controller.value = controller.value.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    });
  }

  Widget _buildValueEditor({
    required String description,
    required double value,
    required TextEditingController controller,
    required FocusNode focusNode,
    required int index,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(description),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: widget.min,
                max: widget.max,
                divisions: widget.divisions,
                label: '${_formatValue(value)}${widget.suffix}',
                onChanged: (double newValue) => _setValue(index, newValue),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: widget.precise > 0,
                ),
                inputFormatters: _inputFormatters,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  suffixText: widget.suffix.isEmpty ? null : widget.suffix,
                ),
                onSubmitted: (_) => _commitInputValue(index),
                onEditingComplete: () => _commitInputValue(index),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.only(
        top: 20,
        left: 8,
        right: 8,
        bottom: 8,
      ),
      content: Column(
        mainAxisSize: .min,
        children: [
          _buildValueEditor(
            description: widget.description1,
            value: _tempValue1,
            controller: _controller1,
            focusNode: _focusNode1,
            index: 1,
          ),
          const SizedBox(height: 8),
          _buildValueEditor(
            description: widget.description2,
            value: _tempValue2,
            controller: _controller2,
            focusNode: _focusNode2,
            index: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text(
            '取消',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        TextButton(
          onPressed: () {
            _commitInputValue(1);
            _commitInputValue(2);
            Navigator.pop(context, (_tempValue1, _tempValue2));
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
