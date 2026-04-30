import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/theme.dart';
import 'models/settings_model.dart';
import 'models/open_file.dart';
import 'services/settings_service.dart';
import 'screens/editor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsService();
  await settings.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsModel(settings)),
        ChangeNotifierProvider(create: (_) => OpenFilesModel()),
      ],
      child: const VscodeApp(),
    ),
  );
}

class VscodeApp extends StatelessWidget {
  const VscodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();
    return MaterialApp(
      title: 'VScode Mobile',
      debugShowCheckedModeBanner: false,
      theme: VscodeTheme.dark(),
      darkTheme: VscodeTheme.dark(),
      themeMode: settings.themeMode,
      home: const EditorScreen(),
    );
  }
}
