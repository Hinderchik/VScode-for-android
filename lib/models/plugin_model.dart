class PluginModel {
  final String id;
  final String name;
  final String description;
  final String version;
  final String author;
  final String category;
  final List<String> tags;
  final String installUrl;
  final String? homepage;
  final int downloads;
  final double rating;

  const PluginModel({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.author,
    required this.category,
    required this.tags,
    required this.installUrl,
    this.homepage,
    this.downloads = 0,
    this.rating = 0.0,
  });

  factory PluginModel.fromJson(Map<String, dynamic> j) => PluginModel(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        description: j['description'] ?? '',
        version: j['version'] ?? '1.0.0',
        author: j['author'] ?? '',
        category: j['category'] ?? 'utility',
        tags: List<String>.from(j['tags'] ?? []),
        installUrl: j['installUrl'] ?? '',
        homepage: j['homepage'],
        downloads: j['downloads'] ?? 0,
        rating: (j['rating'] ?? 0.0).toDouble(),
      );
}
