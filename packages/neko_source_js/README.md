# neko_source_js

JavaScript-based comic source system for NekoComic.

## Overview

This package provides a JavaScript runtime for executing comic source plugins. Comic sources are written in JavaScript and define how to fetch comics from various websites.

## Features

- JavaScript runtime (QuickJS via flutter_qjs)
- JS API for network requests, HTML parsing, and encryption
- Comic source plugin system
- Category, search, and explore page support
- Cookie management
- Cloudflare bypass capabilities

## Architecture

```
lib/
├── neko_source_js.dart       # Main export file
├── js_engine.dart            # JavaScript engine wrapper
├── js_pool.dart              # Engine pool for parallel execution
├── comic_source/
│   ├── comic_source.dart     # Comic source class and manager
│   ├── models.dart           # Data models
│   ├── types.dart            # Type definitions
│   ├── category.dart         # Category data classes
│   ├── favorites.dart        # Favorites management
│   └── parser.dart           # Source parser
└── api/
    ├── network.dart          # HTTP API for JS
    ├── html.dart             # HTML parsing API
    └── convert.dart          # Encryption/decryption API
```

## Usage

### Initialize the JS Engine

```dart
import 'package:neko_source_js/neko_source_js.dart';

await NekoJsEngine().ensureInit();
```

### Load a Comic Source

```dart
final sourceCode = await rootBundle.loadString('sources/my_source.js');
final source = await NekoComicSourceParser().parse(sourceCode, 'my_source.js');
NekoComicSourceManager().add(source);
```

### Search for Comics

```dart
final result = await source.search('keyword');
if (result.isSuccess) {
  final comics = result.data!;
  for (final comic in comics) {
    print('${comic.title} - ${comic.author}');
  }
}
```

### Get Comic Details

```dart
final details = await source.getComic(comicId);
if (details.isSuccess) {
  print('Chapters: ${details.data!.chapters.length}');
}
```

## JavaScript API

Comic sources written in JavaScript have access to the following APIs:

### Network API

```javascript
// GET request
const response = await sendRequest({
  url: 'https://api.example.com/comics',
  headers: { 'Accept': 'application/json' }
});

// POST request
const postResponse = await sendRequest({
  url: 'https://api.example.com/login',
  http_method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  data: JSON.stringify({ username, password })
});
```

### HTML API

```javascript
// Parse HTML
html.parse('<div><p>Hello</p></div>');

// Query elements
const elements = html.querySelectorAll('.comic-item');
for (const el of elements) {
  const title = html.getText(el);
  const link = html.getAttribute(el, 'href');
}
```

### Convert API

```javascript
// Base64 encoding
const encoded = convert({ type: 'base64', value: 'hello', isEncode: true });

// MD5 hash
const hash = convert({ type: 'md5', value: 'password' });

// AES encryption
const encrypted = convert({
  type: 'aes-cbc',
  value: plainText,
  key: encryptionKey,
  iv: initializationVector,
  isEncode: true
});
```

### Cookie API

```javascript
// Get cookies
const cookies = cookie.get('https://example.com');

// Set cookies
cookie.set('https://example.com', [
  { name: 'session', value: 'abc123' }
]);
```

## Creating a Comic Source

```javascript
class MySource extends ComicSource {
  constructor() {
    super();
    this.name = 'My Source';
    this.key = 'my_source';
    this.version = '1.0.0';
    this.url = 'https://example.com';
  }

  async getComic(id) {
    const html = await this.getHtml(this.url + '/comic/' + id);
    // Parse and return comic details
  }

  async search(keyword, page) {
    const url = `${this.url}/search?q=${encodeURIComponent(keyword)}&page=${page}`;
    const data = await this.getJson(url);
    // Return list of comics
  }
}
```

## Dependencies

- `flutter_qjs` - QuickJS JavaScript engine
- `dio` - HTTP client
- `html` - HTML parser
- `crypto` - Cryptographic functions
- `pointycastle` - Cryptographic algorithms
- `uuid` - UUID generation
- `enough_convert` - Character encoding conversion

## TODO

- [ ] Complete JS engine initialization
- [ ] Implement full HTML API
- [ ] Add more encryption algorithms
- [ ] Cookie persistence
- [ ] Source hot-reload support
- [ ] Unit tests
