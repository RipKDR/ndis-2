import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final bool enableCaching;
  final Duration cacheDuration;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.enableCaching = true,
    this.cacheDuration = const Duration(days: 7),
  });

  @override
  Widget build(BuildContext context) {
    if (!enableCaching) {
      return _buildBasicImage();
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
        maxWidthDiskCache: 1000,
        maxHeightDiskCache: 1000,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
      ),
    );
  }

  Widget _buildBasicImage() {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return placeholder ?? Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return errorWidget ?? Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: const Icon(
        Icons.error_outline,
        color: Colors.grey,
        size: 32,
      ),
    );
  }
}

/// Optimized avatar widget
class OptimizedAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool enableCaching;

  const OptimizedAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
    this.enableCaching = true,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: OptimizedImage(
          imageUrl: imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(radius),
          enableCaching: enableCaching,
          placeholder: Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: _buildFallbackAvatar(),
        ),
      );
    }

    return _buildFallbackAvatar();
  }

  Widget _buildFallbackAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[300],
      foregroundColor: foregroundColor ?? Colors.grey[600],
      child: name != null && name!.isNotEmpty
          ? Text(
              name!.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: radius * 0.6,
                fontWeight: FontWeight.bold,
              ),
            )
          : Icon(
              Icons.person,
              size: radius * 0.8,
            ),
    );
  }
}

/// Optimized image gallery
class OptimizedImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final double? height;
  final double? width;
  final BoxFit fit;
  final bool enableCaching;
  final VoidCallback? onImageTap;

  const OptimizedImageGallery({
    super.key,
    required this.imageUrls,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.enableCaching = true,
    this.onImageTap,
  });

  @override
  State<OptimizedImageGallery> createState() => _OptimizedImageGalleryState();
}

class _OptimizedImageGalleryState extends State<OptimizedImageGallery> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: widget.onImageTap,
                child: OptimizedImage(
                  imageUrl: widget.imageUrls[index],
                  width: widget.width,
                  height: widget.height,
                  fit: widget.fit,
                  enableCaching: widget.enableCaching,
                ),
              );
            },
          ),
        ),
        if (widget.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Optimized image with lazy loading
class LazyOptimizedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableCaching;

  const LazyOptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.enableCaching = true,
  });

  @override
  State<LazyOptimizedImage> createState() => _LazyOptimizedImageState();
}

class _LazyOptimizedImageState extends State<LazyOptimizedImage> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.imageUrl),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.1 && !_isVisible) {
          setState(() {
            _isVisible = true;
          });
        }
      },
      child: _isVisible
          ? OptimizedImage(
              imageUrl: widget.imageUrl,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              placeholder: widget.placeholder,
              errorWidget: widget.errorWidget,
              enableCaching: widget.enableCaching,
            )
          : widget.placeholder ?? Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
    );
  }
}

/// Visibility detector for lazy loading
class VisibilityDetector extends StatefulWidget {
  final Widget child;
  final Function(VisibilityInfo) onVisibilityChanged;

  const VisibilityDetector({
    super.key,
    required this.child,
    required this.onVisibilityChanged,
  });

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Visibility info for lazy loading
class VisibilityInfo {
  final double visibleFraction;
  final Size size;
  final Offset offset;

  VisibilityInfo({
    required this.visibleFraction,
    required this.size,
    required this.offset,
  });
}
