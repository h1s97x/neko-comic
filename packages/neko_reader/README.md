# neko_reader

Comic reader component for NekoComic.

## Features

- Multiple reading layouts (RTL, LTR, Vertical, Webtoon)
- Gallery mode (page-by-page) and continuous scroll mode
- Pinch to zoom with double-tap zoom
- Custom gesture detection
- Image preloading
- UI controls (slider, page indicator)
- Dark mode optimized

## Installation

```yaml
dependencies:
  neko_reader:
    path: packages/neko_reader
```

## Usage

### Basic Usage

```dart
import 'package:neko_reader/neko_reader.dart';

NekoReader(
  images: ['https://example.com/1.jpg', 'https://example.com/2.jpg'],
  initialIndex: 0,
  layout: ReaderLayout.rightToLeft,
  onPageChanged: (index) => print('Page: $index'),
);
```

### Gallery Mode (Page-by-Page)

```dart
NekoReader(
  images: imageUrls,
  layout: ReaderLayout.rightToLeft, // Manga style
  onPageChanged: (index) => saveProgress(index),
);
```

### Webtoon Mode (Continuous Scroll)

```dart
NekoReader(
  images: imageUrls,
  layout: ReaderLayout.webtoon, // Webtoon style
  onIndexChanged: (index) => updateCurrentIndex(index),
);
```

## Reader Layouts

| Layout | Description |
|--------|-------------|
| `leftToRight` | Gallery mode, tap right to go next |
| `rightToLeft` | Manga style, tap left to go next |
| `topToBottom` | Gallery mode, vertical pagination |
| `vertical` | Continuous vertical scroll |
| `webtoon` | Webtoon optimized continuous scroll |

## API

### NekoReader

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `images` | `List<String>` | Required | Image URLs or paths |
| `initialIndex` | `int` | `0` | Initial page index |
| `layout` | `ReaderLayout` | `rightToLeft` | Reading layout |
| `onPageChanged` | `Function(int)` | `null` | Page change callback |
| `onTap` | `VoidCallback` | `null` | Tap callback |
| `onLongPress` | `Function(int)` | `null` | Long press callback |
| `showControls` | `bool` | `true` | Show UI controls |

### NekoReaderState

```dart
final readerState = GlobalKey<NekoReaderState>();

// Methods
readerState.currentState?.goToPage(5);
readerState.currentState?.nextPage();
readerState.currentState?.previousPage();
readerState.currentState?.toggleUi();
```

## TODO

- [x] Basic reader component
- [x] Gallery mode layouts
- [x] Continuous scroll layouts
- [x] Gesture detection
- [x] Page slider control
- [ ] Volume key support
- [ ] Reading progress auto-save
- [ ] Custom theming
- [ ] Reading settings persistence
- [ ] Image cache integration with neko_image

## Dependencies

- `photo_view` - Image viewing with zoom
- `scrollable_positioned_list` - Scrollable positioned list
