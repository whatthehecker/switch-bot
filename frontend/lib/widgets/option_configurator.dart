import 'package:flutter/material.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:switch_bot_frontend/models/options/bool_option.dart';
import 'package:switch_bot_frontend/models/options/int_option.dart';
import 'package:switch_bot_frontend/models/options/option.dart';
import 'package:switch_bot_frontend/models/options/selection_option.dart';
import 'package:switch_bot_frontend/models/options/string_option.dart';

typedef OptionChangedCallback = void Function(String, Object?);

/// A widget containing controls to set the option values for a given [Program].
class OptionConfigurator extends StatelessWidget {
  final List<Option<Object>> options;
  final Map<String, Object?> currentOptionValues;
  final OptionChangedCallback onOptionChanged;

  /// If set, prevents input for all options that have
  /// [Option.allowChangeAtRuntime] set to false.
  final bool lockOptionsCurrentlyInUse;

  const OptionConfigurator({
    Key? key,
    required this.options,
    required this.currentOptionValues,
    required this.onOptionChanged,
    this.lockOptionsCurrentlyInUse = false,
  }) : super(key: key);

  Widget _buildInputForOption(Option<Object> option) {
    bool shouldBeDisabled = lockOptionsCurrentlyInUse && !option.allowChangeAtRuntime;

    if (option is BoolOption) {
      return Switch(
        value: currentOptionValues[option.name] as bool,
        onChanged: shouldBeDisabled ? null : (bool newValue) => onOptionChanged(option.name, newValue),
      );
    } else if (option is IntOption) {
      return SpinBox(
        min: option.minValue?.toDouble() ?? 0.0,
        max: option.maxValue?.toDouble() ?? double.maxFinite,
        value: (currentOptionValues[option.name] as int).toDouble(),
        onChanged: shouldBeDisabled ? null : (double newValue) => currentOptionValues[option.name],
      );
    } else if (option is SelectionOption) {
      return DropdownButton<String>(
        value: currentOptionValues[option.name] as String,
        onChanged: shouldBeDisabled ? null : (String? selection) => onOptionChanged(option.name, selection),
        items: option.choices
            .map((String choice) => DropdownMenuItem(
                  value: choice,
                  child: Text(choice),
                ))
            .toList(),
      );
    } else if (option is StringOption) {
      return Expanded(
        child: TextFormField(
          enabled: !shouldBeDisabled,
          initialValue: currentOptionValues[option.name] as String,
          onFieldSubmitted: (String newInput) => onOptionChanged(option.name, newInput),
        ),
      );
    }

    throw StateError('Unknown Option type ${option.runtimeType} to build widget for.');
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      separatorBuilder: (BuildContext context, int _) => const Divider(),
      itemCount: options.length,
      itemBuilder: (BuildContext context, int index) {
        Option<Object> option = options[index];

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Tooltip(
                message: option.description,
                child: Text(option.name),
              ),
            ),
            _buildInputForOption(option),
          ],
        );
      },
    );
  }
}
