/// HTML parsing API for JavaScript comic sources.
///
/// This file provides HTML DOM manipulation functionality that can be
/// called from JavaScript code running in comic sources.

import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as dom;

/// Document wrapper for HTML parsing in JavaScript context.
class NekoDocumentWrapper {
  final dom.Document _document;
  final Map<int, dynamic> _elements = {};
  int _keyCounter = 0;

  NekoDocumentWrapper._(this._document);

  /// Parse HTML string and create a document.
  static NekoDocumentWrapper parse(String htmlString) {
    final document = html.parse(htmlString);
    return NekoDocumentWrapper._(document);
  }

  int _nextKey() => _keyCounter++;

  /// Query a single element by CSS selector.
  NekoElementWrapper? querySelector(String selector) {
    final element = _document.querySelector(selector);
    if (element == null) return null;
    final key = _nextKey();
    _elements[key] = element;
    return NekoElementWrapper(this, key, element);
  }

  /// Query all elements matching CSS selector.
  List<NekoElementWrapper> querySelectorAll(String selector) {
    final elements = _document.querySelectorAll(selector);
    final result = <NekoElementWrapper>[];
    for (final element in elements) {
      final key = _nextKey();
      _elements[key] = element;
      result.add(NekoElementWrapper(this, key, element));
    }
    return result;
  }

  /// Get element by ID.
  NekoElementWrapper? getElementById(String id) {
    final element = _document.getElementById(id);
    if (element == null) return null;
    final key = _nextKey();
    _elements[key] = element;
    return NekoElementWrapper(this, key, element);
  }

  /// Remove an element from tracking.
  void dispose(int key) {
    _elements.remove(key);
  }
}

/// Element wrapper for DOM manipulation.
class NekoElementWrapper {
  final NekoDocumentWrapper _doc;
  final int _key;
  final dom.Element _element;

  NekoElementWrapper(this._doc, this._key, this._element);

  /// Get element text content.
  String get text => _element.text;

  /// Get inner HTML.
  String get innerHTML => _element.innerHtml;

  /// Get tag name.
  String get tagName => _element.localName ?? '';

  /// Get attribute value.
  String? getAttribute(String name) => _element.getAttribute(name);

  /// Get all attributes as a map.
  Map<String, String> get attributes {
    final result = <String, String>{};
    for (final attr in _element.attributes.entries) {
      result[attr.key] = attr.value;
    }
    return result;
  }

  /// Get CSS classes.
  List<String> get classNames => _element.classes.toList();

  /// Get element ID.
  String? get id => _element.id;

  /// Get parent element.
  NekoElementWrapper? get parent {
    final parent = _element.parent;
    if (parent == null) return null;
    final key = _doc._nextKey();
    _doc._elements[key] = parent;
    return NekoElementWrapper(_doc, key, parent);
  }

  /// Get children elements.
  List<NekoElementWrapper> get children {
    final result = <NekoElementWrapper>[];
    for (final child in _element.children) {
      final key = _doc._nextKey();
      _doc._elements[key] = child;
      result.add(NekoElementWrapper(_doc, key, child));
    }
    return result;
  }

  /// Dispose this element from tracking.
  void dispose() {
    _doc.dispose(_key);
  }
}

/// Handle HTML callbacks from JavaScript.
///
/// This function is called from the JS engine to perform
/// HTML parsing operations.
dynamic handleHtmlCallback(Map<String, dynamic> data) {
  // This is a placeholder - actual implementation depends on
  // how the JavaScript side calls this function
  return null;
}

/// Mixin for HTML API implementation in JS engine.
mixin class NekoHtmlApi {
  final Map<int, NekoDocumentWrapper> _documents = {};

  /// Parse HTML string.
  NekoDocumentWrapper parseHtml(String htmlString) {
    return NekoDocumentWrapper.parse(htmlString);
  }

  /// Handle HTML callback from JavaScript.
  dynamic handleHtmlCallback(Map<String, dynamic> data) {
    switch (data["function"]) {
      case "parse":
        final key = data["key"] ?? DateTime.now().millisecondsSinceEpoch;
        _documents[key] = NekoDocumentWrapper.parse(data["data"]);
        return null;
      case "querySelector":
        return _documents[data["key"]]!.querySelector(data["query"])?.toMap();
      case "querySelectorAll":
        return _documents[data["key"]]!.querySelectorAll(data["query"])
            .map((e) => e.toMap()).toList();
      case "getText":
        return _documents[data["doc"]]!.getElementById(data["key"])?.text;
      case "getAttributes":
        return _documents[data["doc"]]!.getElementById(data["key"])?.attributes;
      case "dispose":
        _documents.remove(data["key"]);
        return null;
    }
    return null;
  }
}

extension _ElementExtension on NekoElementWrapper {
  Map<String, dynamic> toMap() {
    return {
      'key': _key,
      'text': text,
      'innerHTML': innerHTML,
      'tagName': tagName,
      'attributes': attributes,
      'classNames': classNames,
      'id': id,
    };
  }
}
