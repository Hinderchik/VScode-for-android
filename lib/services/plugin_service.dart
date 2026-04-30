import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plugin_model.dart';
import 'tor_service.dart';

class PluginService {
  static const _installedKey = 'installed_plugins';
  static const _marketplaceUrl =
      'https://vscode-mobile-plugins.vercel.app/api/plugins';

  static Future<List<String>> getInstalled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_installedKey) ?? [];
  }

  static Future<void> saveInstalled(List<String> urls) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_installedKey, urls);
  }

  static Future<void> install(String url) async {
    final urls = await getInstalled();
    if (!urls.contains(url)) {
      urls.add(url);
      await saveInstalled(urls);
    }
  }

  static Future<void> remove(String url) async {
    final urls = await getInstalled();
    urls.remove(url);
    await saveInstalled(urls);
  }

  static Future<String> fetchPluginCode(String url) async {
    final dio = Dio();
    final response = await dio.get<String>(url,
        options: Options(responseType: ResponseType.plain));
    return response.data ?? '';
  }

  static Future<List<PluginModel>> fetchMarketplace({String? query, String? category}) async {
    try {
      final dio = Dio();
      final params = <String, String>{};
      if (query != null && query.isNotEmpty) params['q'] = query;
      if (category != null && category.isNotEmpty) params['category'] = category;
      final response = await dio.get(_marketplaceUrl, queryParameters: params);
      final list = response.data as List;
      return list.map((e) => PluginModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
