# NekoComic UI

Reusable UI components for NekoComic, migrated from Venera.

## Features

- **Comic Components**
  - `NekoComicCard` - Card-style comic display
  - `NekoComicTile` - List-style comic item with detailed/brief modes
  - `NekoComicGrid` - Responsive grid layout
  - `NekoComicDescription` - Comic information display

- **Loading Components**
  - `NekoListLoadingIndicator` - Loading indicator for lists
  - `NekoSliverLoadingIndicator` - Loading indicator for sliver-based scrolling
  - `FiveDotLoadingAnimation` - Custom five-dot loading animation
  - `NekoShimmerLoading` - Shimmer skeleton loading
  - `NekoSkeletonGrid` - Skeleton grid for loading states

- **Error Handling**
  - `NekoErrorWidget` - Generic error display
  - `NekoEmptyWidget` - Empty state display
  - `NekoNetworkError` - Network/cloudflare error display

- **Buttons**
  - `NekoButton` - Custom button with filled/outlined/text/normal types
  - `NekoIconButton` - Icon button with hover effects

- **Common Components**
  - `NekoShimmer` - Shimmer loading effect
  - `NekoOptionChip` - Option/tag chip
  - `NekoChipWrap` - Wrap of option chips

## Installation

```yaml
dependencies:
  neko_ui:
    path: packages/neko_ui
```

## Usage

### Comic Grid

```dart
import 'package:neko_ui/neko_ui.dart';

NekoComicGrid(
  comics: comicList,
  onComicTap: (comic) => openComic(comic),
  onLoadMore: () => loadMoreComics(),
  isLoading: isLoading,
)
```

### Loading State

```dart
import 'package:neko_ui/neko_ui.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends NekoLoadingState<MyWidget, List<Comic>> {
  @override
  Future<List<Comic>> loadData() async {
    return await comicRepository.getComics();
  }

  @override
  Widget buildContent(BuildContext context, List<Comic> data) {
    return NekoComicGrid(
      comics: data,
      onComicTap: (comic) => openComic(comic),
    );
  }
}
```

### Error Handling

```dart
import 'package:neko_ui/neko_ui.dart';

NekoErrorWidget(
  message: error.toString(),
  onRetry: () => loadData(),
)

NekoNetworkError(
  message: 'Network error',
  onRetry: () => loadData(),
)

NekoEmptyWidget(
  title: 'No comics found',
  message: 'Try adjusting your search',
)
```

## Dependencies

- `flutter_staggered_grid_view` - For grid layouts
- `shimmer_animation` - For shimmer effects
- `flex_seed_scheme` - For Material color generation
- `dynamic_color` - For dynamic theming

## Migrated from

This package was migrated from Venera's `lib/components/` directory, including:
- `comic.dart` - ComicTile, ComicCard, ComicGrid
- `loading.dart` - Loading indicators and states
- `button.dart` - Custom button components
- And more...

## License

MIT
