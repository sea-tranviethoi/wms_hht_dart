import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme_config.dart';

class ImageViewWidget extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;
  final String? placeholder;
  final BoxFit fit;
  final double? width;
  final double? height;
  final bool showFullScreen;

  const ImageViewWidget({
    Key? key,
    this.imageUrl,
    this.imageFile,
    this.placeholder,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.showFullScreen = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (imageFile != null) {
      imageWidget = Image.file(
        imageFile!,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    } else {
      imageWidget = _buildPlaceholder();
    }

    if (showFullScreen) {
      return GestureDetector(
        onTap: () => _showFullScreen(context),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.lighter,
      child: const Icon(
        Icons.image_not_supported,
        size: 48,
        color: AppColors.textPlaceholder,
      ),
    );
  }

  void _showFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: imageFile != null
                ? Image.file(imageFile!)
                : (imageUrl != null && imageUrl!.isNotEmpty)
                    ? CachedNetworkImage(imageUrl: imageUrl!)
                    : _buildPlaceholder(),
          ),
        ),
      ),
    );
  }
}

