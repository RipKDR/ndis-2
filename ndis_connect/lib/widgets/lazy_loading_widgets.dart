import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A widget that implements lazy loading for its children
/// Only builds widgets when they become visible in the viewport
class LazyLoadingListView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final double? itemExtent;
  final Widget? separator;

  const LazyLoadingListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.itemExtent,
    this.separator,
  });

  @override
  State<LazyLoadingListView> createState() => _LazyLoadingListViewState();
}

class _LazyLoadingListViewState extends State<LazyLoadingListView> {
  final Set<int> _builtItems = {};
  final Map<int, Widget> _itemCache = {};
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    // Clear cache for items that are far from viewport to save memory
    _cleanupDistantItems();
  }

  void _cleanupDistantItems() {
    if (_itemCache.length > 50) {
      // Keep max 50 items in cache
      final itemsToRemove = _itemCache.keys.take(_itemCache.length - 30).toList();
      for (final index in itemsToRemove) {
        _itemCache.remove(index);
        _builtItems.remove(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.separator != null) {
      return ListView.separated(
        controller: _scrollController,
        padding: widget.padding,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        itemCount: widget.itemCount,
        separatorBuilder: (context, index) => widget.separator!,
        itemBuilder: _buildItem,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemCount: widget.itemCount,
      itemExtent: widget.itemExtent,
      itemBuilder: _buildItem,
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    // Return cached widget if available
    if (_itemCache.containsKey(index)) {
      return _itemCache[index]!;
    }

    // Build and cache the widget
    final widget = this.widget.itemBuilder(context, index);
    _itemCache[index] = widget;
    _builtItems.add(index);

    return widget;
  }
}

/// A widget that loads content only when it becomes visible
class LazyLoadingWidget extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final Widget placeholder;
  final double threshold;

  const LazyLoadingWidget({
    super.key,
    required this.builder,
    this.placeholder = const SizedBox.shrink(),
    this.threshold = 200.0,
  });

  @override
  State<LazyLoadingWidget> createState() => _LazyLoadingWidgetState();
}

class _LazyLoadingWidgetState extends State<LazyLoadingWidget> {
  bool _hasBuilt = false;
  Widget? _cachedWidget;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: widget.key ?? ValueKey(widget.hashCode),
      onVisibilityChanged: _onVisibilityChanged,
      child: _hasBuilt ? (_cachedWidget ?? widget.placeholder) : widget.placeholder,
    );
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final isVisible = info.visibleFraction > 0;

    if (isVisible && !_hasBuilt) {
      setState(() {
        _hasBuilt = true;
        _cachedWidget = widget.builder(context);
      });
    }
  }
}

/// Simplified visibility detector for lazy loading
class VisibilityDetector extends StatefulWidget {
  @override
  final Key key;
  final Widget child;
  final Function(VisibilityInfo) onVisibilityChanged;

  const VisibilityDetector({
    required this.key,
    required this.child,
    required this.onVisibilityChanged,
  }) : super(key: key);

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final size = renderBox.size;
      final position = renderBox.localToGlobal(Offset.zero);
      final screenSize = MediaQuery.of(context).size;

      // Simple visibility calculation
      final isVisible = position.dy < screenSize.height &&
          position.dy + size.height > 0 &&
          position.dx < screenSize.width &&
          position.dx + size.width > 0;

      final visibleFraction = isVisible ? 1.0 : 0.0;

      widget.onVisibilityChanged(VisibilityInfo(
        key: widget.key,
        size: size,
        visibleFraction: visibleFraction,
        visibleBounds: isVisible
            ? Rect.fromLTWH(position.dx, position.dy, size.width, size.height)
            : Rect.zero,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Visibility information for lazy loading
class VisibilityInfo {
  final Key key;
  final Size size;
  final double visibleFraction;
  final Rect visibleBounds;

  VisibilityInfo({
    required this.key,
    required this.size,
    required this.visibleFraction,
    required this.visibleBounds,
  });
}

/// Optimized image widget with lazy loading and caching
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableMemoryCache;
  final Duration fadeInDuration;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.enableMemoryCache = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    // Use placeholder for empty URLs
    if (imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    // Use cached network image for better performance
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeInDuration,
      memCacheWidth: enableMemoryCache ? width?.toInt() : null,
      memCacheHeight: enableMemoryCache ? height?.toInt() : null,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
      // Use default cache manager
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.error_outline,
        color: Colors.grey,
      ),
    );
  }
}

/// Lazy loading grid view for better performance
class LazyLoadingGridView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const LazyLoadingGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<LazyLoadingGridView> createState() => _LazyLoadingGridViewState();
}

class _LazyLoadingGridViewState extends State<LazyLoadingGridView> {
  final Map<int, Widget> _itemCache = {};

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: widget.controller,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      gridDelegate: widget.gridDelegate,
      itemCount: widget.itemCount,
      itemBuilder: _buildItem,
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    // Return cached widget if available
    if (_itemCache.containsKey(index)) {
      return _itemCache[index]!;
    }

    // Build and cache the widget
    final widget = this.widget.itemBuilder(context, index);
    _itemCache[index] = widget;

    // Clean up cache if it gets too large
    if (_itemCache.length > 100) {
      final keysToRemove = _itemCache.keys.take(50).toList();
      for (final key in keysToRemove) {
        _itemCache.remove(key);
      }
    }

    return widget;
  }
}

/// Performance-optimized card widget
class OptimizedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const OptimizedCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.color,
    this.elevation,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardWidget = Card(
      margin: margin,
      color: color,
      elevation: elevation ?? 2,
      shape: borderRadius != null ? RoundedRectangleBorder(borderRadius: borderRadius!) : null,
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );

    if (onTap != null) {
      cardWidget = InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}

/// Mixin for implementing lazy loading in widgets
mixin LazyLoadingMixin<T extends StatefulWidget> on State<T> {
  final Map<String, Widget> _widgetCache = {};
  final Map<String, bool> _loadingStates = {};

  /// Build widget with lazy loading
  Widget buildLazyWidget(
    String key,
    Widget Function() builder, {
    Widget? placeholder,
  }) {
    if (_widgetCache.containsKey(key)) {
      return _widgetCache[key]!;
    }

    if (_loadingStates[key] == true) {
      return placeholder ?? const CircularProgressIndicator();
    }

    // Mark as loading and build asynchronously
    _loadingStates[key] = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _widgetCache[key] = builder();
          _loadingStates[key] = false;
        });
      }
    });

    return placeholder ?? const CircularProgressIndicator();
  }

  /// Clear widget cache to free memory
  void clearWidgetCache() {
    _widgetCache.clear();
    _loadingStates.clear();
  }

  /// Remove specific widget from cache
  void removeFromCache(String key) {
    _widgetCache.remove(key);
    _loadingStates.remove(key);
  }
}
