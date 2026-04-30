import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/plugin_model.dart';
import '../services/plugin_service.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  List<PluginModel> _plugins = [];
  List<String> _installed = [];
  bool _loading = true;
  String _query = '';
  String _category = '';
  final _searchCtrl = TextEditingController();

  static const _categories = ['', 'ai', 'formatter', 'language', 'theme', 'utility'];
  static const _categoryLabels = ['All', 'AI', 'Formatter', 'Language', 'Theme', 'Utility'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      PluginService.fetchMarketplace(query: _query, category: _category),
      PluginService.getInstalled(),
    ]);
    setState(() {
      _plugins = results[0] as List<PluginModel>;
      _installed = results[1] as List<String>;
      _loading = false;
    });
  }

  Future<void> _install(PluginModel plugin) async {
    await PluginService.install(plugin.installUrl);
    setState(() => _installed.add(plugin.installUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${plugin.name} installed'),
        backgroundColor: VscodeTheme.accent,
      ));
    }
  }

  Future<void> _uninstall(PluginModel plugin) async {
    await PluginService.remove(plugin.installUrl);
    setState(() => _installed.remove(plugin.installUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VscodeTheme.bg,
      appBar: AppBar(
        title: const Text('Extensions Marketplace'),
        backgroundColor: VscodeTheme.bgSidebar,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: VscodeTheme.fgMuted),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: VscodeTheme.fg, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search extensions...',
                    prefixIcon: const Icon(Icons.search, size: 16, color: VscodeTheme.fgMuted),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 14),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                              _load();
                            })
                        : null,
                  ),
                  onSubmitted: (v) {
                    setState(() => _query = v);
                    _load();
                  },
                ),
              ),
              SizedBox(
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  itemBuilder: (_, i) {
                    final selected = _category == _categories[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(_categoryLabels[i],
                          style: TextStyle(
                            fontSize: 11,
                            color: selected ? Colors.white : VscodeTheme.fgMuted,
                          )),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _category = _categories[i]);
                          _load();
                        },
                        backgroundColor: VscodeTheme.bgInput,
                        selectedColor: VscodeTheme.accent,
                        checkmarkColor: Colors.white,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: VscodeTheme.accent))
          : _plugins.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: VscodeTheme.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _plugins.length,
                    itemBuilder: (_, i) => _buildCard(_plugins[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.extension_off_outlined, size: 64, color: VscodeTheme.fgMuted),
          const SizedBox(height: 16),
          const Text('No extensions found', style: TextStyle(color: VscodeTheme.fgMuted, fontSize: 14)),
          const SizedBox(height: 8),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildCard(PluginModel plugin) {
    final isInstalled = _installed.contains(plugin.installUrl);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: VscodeTheme.bgSidebar,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: VscodeTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: VscodeTheme.bgInput,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.extension, color: VscodeTheme.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(plugin.name,
                          style: const TextStyle(color: VscodeTheme.fg, fontSize: 14,
                            fontWeight: FontWeight.w600)),
                      ),
                      _categoryBadge(plugin.category),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(plugin.author,
                    style: const TextStyle(color: VscodeTheme.fgMuted, fontSize: 11)),
                  const SizedBox(height: 6),
                  Text(plugin.description,
                    style: const TextStyle(color: VscodeTheme.fgLabel, fontSize: 12),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.download_outlined, size: 12, color: VscodeTheme.fgMuted),
                      const SizedBox(width: 3),
                      Text('${plugin.downloads}',
                        style: const TextStyle(color: VscodeTheme.fgMuted, fontSize: 11)),
                      const SizedBox(width: 10),
                      Icon(Icons.star_outline, size: 12, color: VscodeTheme.fgMuted),
                      const SizedBox(width: 3),
                      Text(plugin.rating.toStringAsFixed(1),
                        style: const TextStyle(color: VscodeTheme.fgMuted, fontSize: 11)),
                      const Spacer(),
                      isInstalled
                          ? OutlinedButton(
                              onPressed: () => _uninstall(plugin),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: VscodeTheme.red,
                                side: const BorderSide(color: VscodeTheme.red),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Uninstall', style: TextStyle(fontSize: 11)),
                            )
                          : ElevatedButton(
                              onPressed: () => _install(plugin),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: VscodeTheme.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Install', style: TextStyle(fontSize: 11)),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryBadge(String cat) {
    const colors = {
      'ai': Color(0xFF4EC9B0),
      'formatter': Color(0xFFDCDCAA),
      'language': Color(0xFF9CDCFE),
      'theme': Color(0xFFCE9178),
      'utility': Color(0xFF858585),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (colors[cat] ?? VscodeTheme.fgMuted).withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (colors[cat] ?? VscodeTheme.fgMuted).withOpacity(0.4)),
      ),
      child: Text(cat,
        style: TextStyle(fontSize: 10, color: colors[cat] ?? VscodeTheme.fgMuted)),
    );
  }
}
