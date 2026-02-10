import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Reusable settings tile with icon, title, subtitle, and navigation
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: NunuColors.primaryMain.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: NunuColors.primaryLight, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ?? const Icon(
                Icons.chevron_right,
                color: NunuColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable toggle tile
class SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  
  const SettingsToggleTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: NunuColors.primaryMain.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: NunuColors.primaryLight, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: NunuColors.primaryMain,
            activeTrackColor: NunuColors.primaryMain.withOpacity(0.4),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade700,
          ),
        ],
      ),
    );
  }
}

/// Reusable slider tile
class SettingsSliderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String? valueLabel;
  
  const SettingsSliderTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.valueLabel,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: NunuColors.primaryMain.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: NunuColors.primaryLight, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (valueLabel != null)
                Text(
                  valueLabel!,
                  style: const TextStyle(
                    color: NunuColors.primaryLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: NunuColors.primaryMain,
              inactiveTrackColor: NunuColors.primaryDark.withOpacity(0.3),
              thumbColor: NunuColors.primaryLight,
              overlayColor: NunuColors.primaryMain.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable dropdown tile
class SettingsDropdownTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  
  const SettingsDropdownTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: NunuColors.primaryMain.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: NunuColors.primaryLight, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          DropdownButton<String>(
            value: value,
            dropdownColor: NunuColors.backgroundPaper,
            underline: const SizedBox(),
            items: options.map((opt) => DropdownMenuItem(
              value: opt,
              child: Text(opt, style: const TextStyle(color: Colors.white, fontSize: 14)),
            )).toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

/// Reusable section container
class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: NunuColors.primaryLight.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: NunuColors.primaryDark.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// Standard divider for settings
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 70,
      color: NunuColors.primaryDark.withOpacity(0.2),
    );
  }
}

/// Settings header with back navigation
class SettingsHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;
  
  const SettingsHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.onBack,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        border: Border(
          bottom: BorderSide(
            color: NunuColors.primaryDark.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: NunuColors.primaryLight),
              onPressed: onBack,
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// Edit screen with text field
class SettingsEditScreen extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final VoidCallback onSave;
  
  const SettingsEditScreen({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    required this.onSave,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: NunuColors.primaryLight,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: NunuColors.backgroundPaper,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: NunuColors.primaryDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: NunuColors.primaryDark.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: NunuColors.primaryMain, width: 2),
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('save changes'),
          ),
        ],
      ),
    );
  }
}

/// Password field widget
class SettingsPasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  
  const SettingsPasswordField({
    super.key,
    required this.label,
    required this.controller,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: NunuColors.primaryLight,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: NunuColors.backgroundPaper,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: NunuColors.primaryDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: NunuColors.primaryDark.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: NunuColors.primaryMain, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

