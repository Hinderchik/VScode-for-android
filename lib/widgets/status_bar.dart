import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../services/tor_service.dart';

class VscodeStatusBar extends StatelessWidget {
  final String fileName;
  final String language;
  final int line;
  final int col;
  final bool torEnabled;
  final VoidCallback onTorTap;
  final VoidCallback onLangTap;

  const VscodeStatusBar({
    super.key,
    required this.fileName,
    required this.language,
    required this.line,
    required this.col,
    required this.torEnabled,
    required this.onTorTap,
    required this.onLangTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      color: VscodeTheme.statusBg,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _item(
            torEnabled ? 'Tor: ON' : 'Tor: OFF',
            onTorTap,
            icon: torEnabled ? Icons.shield : Icons.shield_outlined,
            iconColor: torEnabled ? Colors.greenAccent : Colors.white70,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: _item(fileName.isEmpty ? 'No file open' : fileName, () {}, ellipsis: true),
          ),
          const Spacer(),
          _item('Ln $line, Col $col', () {}),
          const SizedBox(width: 8),
          _item(language, onLangTap),
          const SizedBox(width: 8),
          _item('UTF-8', () {}),
        ],
      ),
    );
  }

  Widget _item(String label, VoidCallback onTap,
      {IconData? icon, Color? iconColor, bool ellipsis = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: iconColor ?? Colors.white),
              const SizedBox(width: 3),
            ],
            ellipsis
                ? Flexible(child: Text(label,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    overflow: TextOverflow.ellipsis))
                : Text(label,
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
