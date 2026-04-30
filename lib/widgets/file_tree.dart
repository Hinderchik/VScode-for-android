import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../services/file_service.dart';

class FileTreeWidget extends StatefulWidget {
  final List<FileNode> nodes;
  final ValueChanged<FileNode> onFileTap;
  final ValueChanged<FileNode>? onLongPress;

  const FileTreeWidget({
    super.key,
    required this.nodes,
    required this.onFileTap,
    this.onLongPress,
  });

  @override
  State<FileTreeWidget> createState() => _FileTreeWidgetState();
}

class _FileTreeWidgetState extends State<FileTreeWidget> {
  final Set<String> _expanded = {};
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return _buildList(widget.nodes, 0);
  }

  Widget _buildList(List<FileNode> nodes, int depth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: nodes.map((n) => _buildNode(n, depth)).toList(),
    );
  }

  Widget _buildNode(FileNode node, int depth) {
    final indent = 8.0 + depth * 14.0;
    final isSelected = _selected == node.path;

    if (node.isDir) {
      final isOpen = _expanded.contains(node.path);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () => widget.onLongPress?.call(node),
            child: InkWell(
              onTap: () => setState(() {
                if (isOpen) _expanded.remove(node.path);
                else _expanded.add(node.path);
              }),
              hoverColor: VscodeTheme.bgHover,
              child: Container(
                width: double.infinity,
                color: isSelected ? VscodeTheme.bgSelection : Colors.transparent,
                padding: EdgeInsets.only(left: indent, top: 4, bottom: 4, right: 8),
                child: Row(
                  children: [
                    Icon(
                      isOpen ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                      size: 13, color: VscodeTheme.fgMuted,
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      isOpen ? Icons.folder_open : Icons.folder,
                      size: 14, color: const Color(0xFFDCB67A),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(node.name,
                        style: const TextStyle(fontSize: 13, color: VscodeTheme.fg),
                        overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isOpen) _buildList(node.children, depth + 1),
        ],
      );
    }

    return GestureDetector(
      onLongPress: () => widget.onLongPress?.call(node),
      child: InkWell(
        onTap: () {
          setState(() => _selected = node.path);
          widget.onFileTap(node);
        },
        hoverColor: VscodeTheme.bgHover,
        child: Container(
          width: double.infinity,
          color: isSelected ? VscodeTheme.bgSelection : Colors.transparent,
          padding: EdgeInsets.only(left: indent + 16, top: 4, bottom: 4, right: 8),
          child: Row(
            children: [
              Icon(_fileIcon(node.name), size: 13, color: _fileIconColor(node.name)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(node.name,
                  style: const TextStyle(fontSize: 13, color: VscodeTheme.fg),
                  overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'dart': return Icons.code;
      case 'js': case 'ts': case 'jsx': case 'tsx': return Icons.javascript;
      case 'py': return Icons.code;
      case 'json': return Icons.data_object;
      case 'md': return Icons.article_outlined;
      case 'html': return Icons.html;
      case 'css': return Icons.css;
      case 'yaml': case 'yml': return Icons.settings_outlined;
      case 'sh': return Icons.terminal;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  Color _fileIconColor(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'dart': return const Color(0xFF54C5F8);
      case 'js': case 'jsx': return const Color(0xFFDCDCAA);
      case 'ts': case 'tsx': return const Color(0xFF569CD6);
      case 'py': return const Color(0xFF4EC9B0);
      case 'json': return const Color(0xFFDCB67A);
      case 'md': return const Color(0xFF9CDCFE);
      case 'html': return const Color(0xFFE34C26);
      case 'css': return const Color(0xFF563D7C);
      case 'sh': return const Color(0xFF4EC9B0);
      default: return VscodeTheme.fgMuted;
    }
  }
}
