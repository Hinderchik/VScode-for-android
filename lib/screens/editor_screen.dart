import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../models/open_file.dart';
import '../models/settings_model.dart';
import '../services/file_service.dart';
import '../services/tor_service.dart';
import '../services/plugin_service.dart';
import '../widgets/activity_bar.dart';
import '../widgets/sidebar.dart';
import '../widgets/tab_bar.dart';
import '../widgets/status_bar.dart';
import '../widgets/clim_panel.dart';
import 'settings_screen.dart';
import 'marketplace_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  InAppWebViewController? _webCtrl;
  ActivityBarItem _activeBar = ActivityBarItem.explorer;
  bool _sidebarVisible = true;
  bool _climVisible = false;
  String _currentLang = 'plaintext';
  int _line = 1, _col = 1;
  String _selectedCode = '';
  bool _torEnabled = false;

  @override
  void initState() {
    super.initState();
    TorService.checkStatus().then((v) => setState(() => _torEnabled = v));
  }

  void _onActivityBarSelect(ActivityBarItem item) {
    if (item == ActivityBarItem.settings) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
      return;
    }
    if (item == ActivityBarItem.clim) {
      setState(() => _climVisible = !_climVisible);
      return;
    }
    if (item == ActivityBarItem.extensions) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen()));
      return;
    }
    setState(() {
      if (_activeBar == item) {
        _sidebarVisible = !_sidebarVisible;
      } else {
        _activeBar = item;
        _sidebarVisible = true;
      }
    });
  }

  void _openFile(String path, String name, String content) {
    final filesModel = context.read<OpenFilesModel>();
    filesModel.open(OpenFile(uri: path, name: name, content: content));
    _loadInEditor(content, name);
    // Auto-close sidebar on small screens / landscape
    final size = MediaQuery.of(context).size;
    if (size.width < 600 || size.width > size.height) {
      setState(() => _sidebarVisible = false);
    }
  }

  void _loadInEditor(String content, String name) {
    final lang = _detectLang(name);
    setState(() => _currentLang = lang);
    final escaped = content
        .replaceAll('\\', '\\\\')
        .replaceAll('`', '\\`')
        .replaceAll('\$', '\\\$');
    _webCtrl?.evaluateJavascript(source: "window.loadFile(`$escaped`, '$lang', '$name');");
  }

  Future<void> _saveActive() async {
    final filesModel = context.read<OpenFilesModel>();
    final active = filesModel.active;
    if (active == null) return;
    final content = await _webCtrl?.evaluateJavascript(source: 'window.editor.getValue()');
    if (content == null) return;
    final cleaned = (content as String).replaceAll('"', '').replaceAll('\\n', '\n');
    await FileService.saveFile(active.uri, cleaned);
    filesModel.markClean(active.uri);
  }

  Future<void> _toggleTor() async {
    if (_torEnabled) await TorService.stop(); else await TorService.start();
    final status = await TorService.checkStatus();
    setState(() => _torEnabled = status);
  }

  void _insertCode(String code) {
    final escaped = code
        .replaceAll('\\', '\\\\')
        .replaceAll('`', '\\`')
        .replaceAll('\$', '\\\$');
    _webCtrl?.evaluateJavascript(source: "window.editor.trigger('clim', 'type', { text: `$escaped` });");
  }

  void _runCommand(String command) {
    _webCtrl?.evaluateJavascript(source: "window.runCommand && window.runCommand(${jsonEncode(command)});");
  }

  @override
  Widget build(BuildContext context) {
    final filesModel = context.watch<OpenFilesModel>();
    final settings = context.watch<SettingsModel>();
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: VscodeTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  // Activity Bar
                  ActivityBar(selected: _activeBar, onSelect: _onActivityBarSelect),

                  // Editor area + overlay sidebar
                  Expanded(
                    child: Stack(
                      children: [
                        // Main editor column
                        Column(
                          children: [
                            EditorTabBar(model: filesModel),
                            Expanded(
                              child: Row(
                                children: [
                                  // Monaco WebView
                                  Expanded(child: _buildEditor(settings)),
                                  // Clim panel — right side
                                  if (_climVisible)
                                    ClimPanel(
                                      selectedCode: _selectedCode,
                                      language: _currentLang,
                                      onClose: () => setState(() => _climVisible = false),
                                      onInsertCode: _insertCode,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Sidebar overlay (doesn't push editor)
                        if (_sidebarVisible)
                          Positioned(
                            left: 0, top: 0, bottom: 0,
                            child: Row(
                              children: [
                                Sidebar(
                                  activePanel: _activeBar.name,
                                  filesModel: filesModel,
                                  onFileOpen: _openFile,
                                ),
                                // Tap outside to close
                                GestureDetector(
                                  onTap: () => setState(() => _sidebarVisible = false),
                                  child: Container(
                                    width: isLandscape ? 40 : 0,
                                    color: Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            VscodeStatusBar(
              fileName: filesModel.active?.name ?? '',
              language: _currentLang,
              line: _line,
              col: _col,
              torEnabled: _torEnabled,
              onTorTap: _toggleTor,
              onLangTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor(SettingsModel settings) {
    return InAppWebView(
      initialFile: 'assets/editor.html',
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        allowFileAccessFromFileURLs: true,
        allowUniversalAccessFromFileURLs: true,
        supportZoom: false,
        transparentBackground: true,
      ),
      onWebViewCreated: (ctrl) {
        _webCtrl = ctrl;
        _registerHandlers(ctrl, settings);
      },
      onLoadStop: (ctrl, _) async {
        await _applySettings(settings);
        await _loadInstalledPlugins(ctrl);
      },
    );
  }

  void _registerHandlers(InAppWebViewController ctrl, SettingsModel settings) {
    ctrl.addJavaScriptHandler(
      handlerName: 'onCursorChange',
      callback: (args) {
        if (args.length >= 2) setState(() { _line = args[0]; _col = args[1]; });
      },
    );
    ctrl.addJavaScriptHandler(
      handlerName: 'onSelectionChange',
      callback: (args) {
        if (args.isNotEmpty) setState(() => _selectedCode = args[0]);
      },
    );
    ctrl.addJavaScriptHandler(
      handlerName: 'onContentChange',
      callback: (args) {
        final filesModel = context.read<OpenFilesModel>();
        if (filesModel.active != null) filesModel.markDirty(filesModel.active!.uri);
        if (settings.autoSave == 'afterDelay') {
          Future.delayed(const Duration(seconds: 1), _saveActive);
        }
      },
    );
    ctrl.addJavaScriptHandler(
      handlerName: 'installPlugin',
      callback: (args) async {
        if (args.isEmpty) return;
        final url = args[0] as String;
        try {
          final code = await PluginService.fetchPluginCode(url);
          await PluginService.install(url);
          await ctrl.evaluateJavascript(source: '(function(){$code})()');
        } catch (e) {
          await ctrl.evaluateJavascript(source:
            "window.onPluginError && window.onPluginError('${e.toString().replaceAll("'", "\\'")}')");
        }
      },
    );
    ctrl.addJavaScriptHandler(
      handlerName: 'removePlugin',
      callback: (args) async {
        if (args.isEmpty) return;
        await PluginService.remove(args[0]);
      },
    );
    ctrl.addJavaScriptHandler(
      handlerName: 'listPlugins',
      callback: (_) async => await PluginService.getInstalled(),
    );
    ctrl.addJavaScriptHandler(
      handlerName: 'saveFile',
      callback: (args) async {
        if (args.length < 2) return;
        await FileService.saveFile(args[0], args[1]);
        context.read<OpenFilesModel>().markClean(args[0]);
      },
    );
  }

  Future<void> _applySettings(SettingsModel s) async {
    await _webCtrl?.evaluateJavascript(source: '''
      window.applySettings({
        fontSize: ${s.fontSize},
        fontFamily: '${s.fontFamily}',
        tabSize: ${s.tabSize},
        wordWrap: ${s.wordWrap ? "'on'" : "'off'"},
      });
    ''');
  }

  Future<void> _loadInstalledPlugins(InAppWebViewController ctrl) async {
    final urls = await PluginService.getInstalled();
    for (final url in urls) {
      try {
        final code = await PluginService.fetchPluginCode(url);
        await ctrl.evaluateJavascript(source: '(function(){$code})()');
      } catch (_) {}
    }
  }

  String _detectLang(String name) {
    final ext = name.split('.').last.toLowerCase();
    const map = {
      'js': 'javascript', 'ts': 'typescript', 'jsx': 'javascript', 'tsx': 'typescript',
      'py': 'python', 'kt': 'kotlin', 'java': 'java', 'dart': 'dart', 'go': 'go',
      'rs': 'rust', 'c': 'c', 'cpp': 'cpp', 'h': 'cpp', 'cs': 'csharp',
      'html': 'html', 'css': 'css', 'scss': 'scss', 'json': 'json',
      'yaml': 'yaml', 'yml': 'yaml', 'md': 'markdown', 'sh': 'shell',
      'xml': 'xml', 'php': 'php', 'rb': 'ruby', 'swift': 'swift',
      'sql': 'sql', 'r': 'r', 'lua': 'lua',
    };
    return map[ext] ?? 'plaintext';
  }
}
