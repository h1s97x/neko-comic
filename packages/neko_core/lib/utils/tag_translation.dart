import 'dart:convert';
import 'package:flutter/services.dart';

/// 标签翻译管理器
/// 提供标签的翻译功能，支持简繁体中文、英文
class NekoTagTranslation {
  static NekoTagTranslation? _instance;
  static NekoTagTranslation get instance => _instance ??= NekoTagTranslation._();

  NekoTagTranslation._();

  /// 翻译缓存
  Map<String, Map<String, String>>? _translations;

  /// 当前语言: zh_CN, zh_TW, en
  String _currentLang = 'zh_CN';

  /// 初始化
  Future<void> init() async {
    try {
      final jsonString = await rootBundle.loadString('assets/tags.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      _translations = {};

      for (final entry in data.entries) {
        if (entry.value is Map) {
          _translations![entry.key] = Map<String, String>.from(entry.value);
        }
      }
    } catch (e) {
      // 如果资源文件不存在，使用内置翻译
      _translations = _builtinTranslations;
    }
  }

  /// 设置语言
  void setLanguage(String lang) {
    _currentLang = lang;
  }

  /// 获取当前语言
  String get currentLanguage => _currentLang;

  /// 翻译标签
  String translate(String category, String tag) {
    if (_translations == null) return tag;

    final categoryMap = _translations![category];
    if (categoryMap == null) return tag;

    return categoryMap[tag] ?? tag;
  }

  /// 翻译标签列表
  List<String> translateTags(String category, List<String> tags) {
    return tags.map((tag) => translate(category, tag)).toList();
  }

  /// 获取分类下的所有翻译
  Map<String, String>? getCategoryTranslations(String category) {
    return _translations?[category];
  }

  /// 翻译类型
  String translateType(String type) {
    return translate('reclass', type);
  }

  /// 翻译语言
  String translateLanguage(String lang) {
    return translate('language', lang);
  }

  /// 翻译作者
  String translateArtist(String artist) {
    return translate('artist', artist);
  }

  /// 翻译原作
  String translateParody(String parody) {
    return translate('parody', parody);
  }

  /// 翻译角色
  String translateCharacter(String character) {
    return translate('character', character);
  }

  /// 内置翻译（简化版）
  static final Map<String, Map<String, String>> _builtinTranslations = {
    'rows': {
      'female': '女性',
      'male': '男性',
      'mixed': '混合',
      'language': '语言',
      'other': '其他',
      'group': '团队',
      'artist': '艺术家',
      'cosplayer': 'Coser',
      'parody': '原作',
      'character': '角色',
    },
    'reclass': {
      'doujinshi': '同人志',
      'manga': '漫画',
      'artistcg': '画师CG',
      'gamecg': '游戏CG',
      'non-h': '无H',
      'imageset': '图集',
      'cosplay': 'Cosplay',
      'misc': '杂项',
    },
    'language': {
      'chinese': '中文',
      'english': '英语',
      'japanese': '日语',
      'korean': '韩语',
    },
  };
}

/// 简化的标签数据类
class NekoTag {
  final String category;
  final String tag;
  final String translated;

  NekoTag({
    required this.category,
    required this.tag,
    required this.translated,
  });

  @override
  String toString() => translated;
}

/// 标签组
class NekoTagGroup {
  final String category;
  final List<NekoTag> tags;

  NekoTagGroup({
    required this.category,
    required this.tags,
  });

  /// 翻译分类名称
  String get translatedCategory {
    return NekoTagTranslation.instance.translate('rows', category);
  }
}
