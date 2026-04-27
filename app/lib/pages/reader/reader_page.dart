import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:neko_core/neko_core.dart';
import 'package:neko_reader/neko_reader.dart';
import 'package:provider/provider.dart';

import '../../stores/app_store.dart';

/// Reader page for viewing comic chapters
class ReaderPage extends StatefulWidget {
  final String comicId;
  final String chapterId;
  final List<String> images;
  final int currentIndex;

  const ReaderPage({
    super.key,
    required this.comicId,
    required this.chapterId,
    required this.images,
    required this.currentIndex,
  });

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late NekoReaderController _controller;
  late ReaderLayout _layout;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = NekoReaderController(
      initialIndex: widget.currentIndex,
    );
    _layout = context.read<AppStore>().defaultLayout;
    
    // Enter fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Save to history
    _saveHistory();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveHistory() async {
    try {
      await NekoHistoryManager().add(
        comicId: widget.comicId,
        chapterId: widget.chapterId,
        page: widget.currentIndex,
      );
    } catch (e) {
      // Ignore history save errors
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ReaderSettingsSheet(
        layout: _layout,
        onLayoutChanged: (layout) {
          setState(() {
            _layout = layout;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Reader
          GestureDetector(
            onTap: _toggleControls,
            child: NekoReader(
              controller: _controller,
              images: widget.images,
              layout: _layout,
              imageBuilder: (context, imageUrl, index) {
                return NekoReaderImage(
                  url: imageUrl,
                  comicId: widget.comicId,
                );
              },
              onPageChanged: (index) {
                // Update history
                NekoHistoryManager().updateProgress(
                  widget.comicId,
                  widget.chapterId,
                  index,
                );
              },
            ),
          ),

          // Controls overlay
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: _ReaderControls(
                controller: _controller,
                totalPages: widget.images.length,
                onBack: () => context.pop(),
                onSettings: _showSettingsSheet,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReaderControls extends StatelessWidget {
  final NekoReaderController controller;
  final int totalPages;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  const _ReaderControls({
    required this.controller,
    required this.totalPages,
    required this.onBack,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top bar
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black54,
                Colors.transparent,
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: onBack,
                ),
                Expanded(
                  child: ValueListenableBuilder<int>(
                    valueListenable: controller,
                    builder: (context, index, _) {
                      return Text(
                        '${index + 1} / $totalPages',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: onSettings,
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        // Bottom bar
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black54,
                Colors.transparent,
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ValueListenableBuilder<int>(
                valueListenable: controller,
                builder: (context, index, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Slider(
                        value: index.toDouble(),
                        min: 0,
                        max: (totalPages - 1).toDouble(),
                        onChanged: (value) {
                          controller.jumpToPage(value.toInt());
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReaderSettingsSheet extends StatelessWidget {
  final ReaderLayout layout;
  final ValueChanged<ReaderLayout> onLayoutChanged;

  const _ReaderSettingsSheet({
    required this.layout,
    required this.onLayoutChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reading Layout',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReaderLayout.values.map((l) {
              final isSelected = l == layout;
              return ChoiceChip(
                label: Text(_getLayoutName(l)),
                selected: isSelected,
                onSelected: (_) {
                  onLayoutChanged(l);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getLayoutName(ReaderLayout layout) {
    switch (layout) {
      case ReaderLayout.rightToLeft:
        return 'Right to Left';
      case ReaderLayout.leftToRight:
        return 'Left to Right';
      case ReaderLayout.vertical:
        return 'Vertical';
      case ReaderLayout.webtoon:
        return 'Webtoon';
      case ReaderLayout.single:
        return 'Single Page';
    }
  }
}
