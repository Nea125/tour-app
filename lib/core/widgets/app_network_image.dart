import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../network/api_json.dart';

/// Renders a network image (authenticated when it's served by the API) and
/// falls back to a themed placeholder tile when the URL fails to load or
/// is blank.
class AppNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholderIcon = Icons.image_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    return ClipRRect(
      borderRadius: radius,
      child: url.isEmpty
          ? _placeholder()
          : Image.network(
              url,
              headers: ApiJson.imageHeaders(url),
              width: width,
              height: height,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _placeholder(loading: true);
              },
              errorBuilder: (context, error, stack) => _placeholder(),
            ),
    );
  }

  Widget _placeholder({bool loading = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.secondary.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: AppSpacing.s22,
                height: AppSpacing.s22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Icon(
                placeholderIcon,
                color: AppColors.primary.withValues(alpha: 0.5),
                size: 32,
              ),
      ),
    );
  }
}
