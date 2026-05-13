import 'package:flutter/material.dart';
import '../../widgets/app_theme.dart';

class FormSectionTitle extends StatelessWidget {
  final String title;
  final String sub;

  const FormSectionTitle({super.key, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context)
                          .extension<InternSpaceThemeColors>()
                          ?.surfaceText ??
                      Colors.black)),
          const SizedBox(height: 4),
          Text(sub,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                          .extension<InternSpaceThemeColors>()
                          ?.mutedText ??
                      Colors.grey)),
        ],
      ),
    );
  }
}

class FormLabel extends StatelessWidget {
  final String text;

  const FormLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context)
                    .extension<InternSpaceThemeColors>()
                    ?.surfaceText ??
                Colors.black87),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.ctrl,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(
          color: Theme.of(context)
                  .extension<InternSpaceThemeColors>()
                  ?.surfaceText ??
              Colors.black,
          fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: Theme.of(context)
                    .extension<InternSpaceThemeColors>()
                    ?.mutedText ??
                Colors.grey,
            fontSize: 13),
        suffixIcon: suffix,
        filled: true,
        fillColor:
            Theme.of(context).extension<InternSpaceThemeColors>()?.formFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: Theme.of(context)
                      .extension<InternSpaceThemeColors>()
                      ?.border ??
                  Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: kCrimsonDeep.withValues(alpha: 0.8), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.red.withValues(alpha: 0.6), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.red.withValues(alpha: 0.9), width: 1.2),
        ),
      ),
    );
  }
}

class CustomDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = (value != null && items.contains(value)) ? value : null;
    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      validator: validator,
      style: TextStyle(
          color: Theme.of(context)
                  .extension<InternSpaceThemeColors>()
                  ?.surfaceText ??
              Colors.black,
          fontSize: 14),
      dropdownColor: Theme.of(context)
          .extension<InternSpaceThemeColors>()
          ?.dialogBackground,
      decoration: InputDecoration(
        filled: true,
        fillColor:
            Theme.of(context).extension<InternSpaceThemeColors>()?.formFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: Theme.of(context)
                      .extension<InternSpaceThemeColors>()
                      ?.border ??
                  Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: kCrimsonDeep.withValues(alpha: 0.8), width: 1.5),
        ),
      ),
      hint: Text(hint,
          style: TextStyle(
              color: Theme.of(context)
                      .extension<InternSpaceThemeColors>()
                      ?.mutedText ??
                  Colors.grey,
              fontSize: 13)),
      icon: Icon(Icons.keyboard_arrow_down,
          color: Theme.of(context)
                  .extension<InternSpaceThemeColors>()
                  ?.mutedText ??
              Colors.grey),
      items: items
          .map((s) => DropdownMenuItem(
                value: s,
                child: Text(s,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Theme.of(context)
                                .extension<InternSpaceThemeColors>()
                                ?.surfaceText ??
                            Colors.black,
                        fontSize: 13)),
              ))
          .toList(),
      onChanged: items.isEmpty ? null : onChanged,
    );
  }
}
