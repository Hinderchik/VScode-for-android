import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/open_file.dart';

class EditorTabBar extends StatelessWidget {
  final OpenFilesModel model;

  const EditorTabBar({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    if (model.files.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 35,
      color: VscodeTheme.bgTab,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: model.files.length,
        itemBuilder: (_, i) {
          final f = model.files[i];
          final isActive = i == model.activeIndex;
          return GestureDetector(
            onTap: () => model.setActive(i),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive ? VscodeTheme.bgTabActive : VscodeTheme.bgTab,
                border: Border(
                  top: BorderSide(
                    color: isActive ? VscodeTheme.accent : Colors.transparent,
                    width: 1,
                  ),
                  right: const BorderSide(color: VscodeTheme.border, width: 1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (f.isDirty)
                    Container(
                      width: 6, height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                        color: VscodeTheme.fg,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Flexible(
                    child: Text(
                      f.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isActive ? VscodeTheme.fg : VscodeTheme.fgMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => model.close(i),
                    borderRadius: BorderRadius.circular(3),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.close, size: 14, color: VscodeTheme.fgMuted),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
