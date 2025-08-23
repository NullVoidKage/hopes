import 'package:flutter/material.dart';

/// A safe wrapper for network images that handles offline errors gracefully
class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final Widget fallback;
  final BoxFit? fit;
  final double? width;
  final double? height;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    required this.fallback,
    this.fit,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Return fallback widget when image fails to load (offline, network error, etc.)
        return fallback;
      },
    );
  }
}

/// A safe wrapper for CircleAvatar with network image
class SafeCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget fallbackChild;
  final Color? backgroundColor;

  const SafeCircleAvatar({
    super.key,
    this.imageUrl,
    required this.radius,
    required this.fallbackChild,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      onBackgroundImageError: imageUrl != null
          ? (exception, stackTrace) {
              // Handle image loading error silently
            }
          : null,
      child: imageUrl == null ? fallbackChild : null,
    );
  }
}
