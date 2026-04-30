import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../models/settings_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsModel>();
    return Scaffold(
      backgroundColor: VscodeTheme.bg,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: VscodeTheme.bgSidebar,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: VscodeTheme.fgMuted),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _section('Appearance'),
          _dropdown(context, 'Theme', s.themeMode == ThemeMode.dark ? 'dark' : 'light',
            ['dark', 'light'], (v) => s.set('theme', v!)),
          _slider(context, 'Font Size', s.fontSize, 10, 24,
            (v) => s.set('fontSize', v)),
          _dropdown(context, 'Font Family', s.fontFamily,
            ['JetBrains Mono', 'Fira Code', 'Cascadia Code', 'monospace'],
            (v) => s.set('fontFamily', v!)),
          _section('Editor'),
          _dropdown(context, 'Tab Size', s.tabSize.toString(),
            ['2', '4', '8'], (v) => s.set('tabSize', int.parse(v!))),
          _toggle(context, 'Word Wrap', s.wordWrap, (v) => s.set('wordWrap', v)),
          _dropdown(context, 'Auto Save', s.autoSave,
            ['off', 'afterDelay', 'onFocusChange'],
            (v) => s.set('autoSave', v!)),
          _section('AI / Clim'),
          _textField(context, 'Anthropic API Key', s.apiKey, obscure: true,
            onSave: (v) => s.set('apiKey', v)),
          _dropdown(context, 'AI Model', s.aiModel,
            ['claude-sonnet-4-6', 'claude-opus-4-7', 'claude-haiku-4-5'],
            (v) => s.set('aiModel', v!)),
          _section('Network'),
          _toggle(context, 'Tor Proxy (via Orbot)', s.torEnabled,
            (v) => s.set('torEnabled', v)),
          _section('Developer'),
          _toggle(context, 'Developer Mode', s.developerMode,
            (v) => s.set('developerMode', v)),
          if (s.developerMode) _devModePanel(context),
          _section('About'),
          _info('Version', '1.0.0'),
          _info('Platform', 'Flutter · Android'),
          _link(context, 'GitHub', 'https://github.com/Hinderchik/VScode-for-android'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(title.toUpperCase(),
      style: const TextStyle(fontSize: 11, color: VscodeTheme.fgLabel,
        letterSpacing: 1, fontWeight: FontWeight.w600)),
  );

  Widget _toggle(BuildContext ctx, String label, bool value, ValueChanged<bool> onChanged) =>
    SwitchListTile(
      title: Text(label, style: const TextStyle(color: VscodeTheme.fg, fontSize: 13)),
      value: value,
      onChanged: onChanged,
      activeColor: VscodeTheme.accent,
      tileColor: VscodeTheme.bgSidebar,
      dense: true,
    );

  Widget _dropdown(BuildContext ctx, String label, String value,
      List<String> options, ValueChanged<String?> onChanged) =>
    ListTile(
      tileColor: VscodeTheme.bgSidebar,
      dense: true,
      title: Text(label, style: const TextStyle(color: VscodeTheme.fg, fontSize: 13)),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: VscodeTheme.bgInput,
        style: const TextStyle(color: VscodeTheme.fg, fontSize: 13),
        underline: const SizedBox(),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: onChanged,
      ),
    );

  Widget _slider(BuildContext ctx, String label, double value,
      double min, double max, ValueChanged<double> onChanged) =>
    ListTile(
      tileColor: VscodeTheme.bgSidebar,
      dense: true,
      title: Text('$label: ${value.round()}px',
        style: const TextStyle(color: VscodeTheme.fg, fontSize: 13)),
      subtitle: Slider(
        value: value, min: min, max: max, divisions: (max - min).round(),
        activeColor: VscodeTheme.accent,
        onChanged: onChanged,
        onChangeEnd: onChanged,
      ),
    );

  Widget _textField(BuildContext ctx, String label, String value,
      {bool obscure = false, required ValueChanged<String> onSave}) {
    final ctrl = TextEditingController(text: value);
    return ListTile(
      tileColor: VscodeTheme.bgSidebar,
      dense: true,
      title: Text(label, style: const TextStyle(color: VscodeTheme.fg, fontSize: 13)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        child: TextField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(color: VscodeTheme.fg, fontSize: 13),
          onSubmitted: onSave,
          decoration: InputDecoration(
            hintText: obscure ? 'sk-ant-...' : label,
            suffixIcon: IconButton(
              icon: const Icon(Icons.check, size: 16, color: VscodeTheme.accent),
              onPressed: () => onSave(ctrl.text),
            ),
          ),
        ),
      ),
    );
  }

  Widget _info(String label, String value) => ListTile(
    tileColor: VscodeTheme.bgSidebar,
    dense: true,
    title: Text(label, style: const TextStyle(color: VscodeTheme.fg, fontSize: 13)),
    trailing: Text(value, style: const TextStyle(color: VscodeTheme.fgMuted, fontSize: 12)),
  );

  Widget _link(BuildContext ctx, String label, String url) => ListTile(
    tileColor: VscodeTheme.bgSidebar,
    dense: true,
    title: Text(label, style: const TextStyle(color: VscodeTheme.accent, fontSize: 13)),
    trailing: const Icon(Icons.open_in_new, size: 14, color: VscodeTheme.accent),
    onTap: () {},
  );

  Widget _devModePanel(BuildContext ctx) {
    final ctrl = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Load Local Plugin (paste JS code):',
            style: TextStyle(color: VscodeTheme.fgLabel, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: VscodeTheme.bgInput,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: VscodeTheme.border),
            ),
            child: TextField(
              controller: ctrl,
              maxLines: 8,
              style: const TextStyle(color: VscodeTheme.fg, fontSize: 12, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: '// VscodePlugin.register({ id: "my-plugin", ... })',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: inject into WebView via navigator key
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Plugin loaded in editor'),
                  backgroundColor: VscodeTheme.accent),
              );
            },
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Run Plugin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: VscodeTheme.accent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
