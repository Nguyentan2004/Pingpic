import 'dart:html' as html;
import 'package:flutter/material.dart';

class WebSafeImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const WebSafeImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  State<WebSafeImage> createState() => _WebSafeImageState();
}

class _WebSafeImageState extends State<WebSafeImage> {
  bool _isLoading = true;
  bool _hasError = false;
  html.ImageElement? _imgElement;

  void _configureElement(html.ImageElement img) {
    _imgElement = img;
    img.src = widget.imageUrl;
    img.style.width = '100%';
    img.style.height = '100%';
    img.style.objectFit = _mapBoxFitToCss(widget.fit);
    img.style.border = 'none';
    img.style.visibility = _isLoading ? 'hidden' : 'visible';

    img.onLoad.listen((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          img.style.visibility = 'visible';
        });
      }
    });

    img.onError.listen((_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant WebSafeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      if (_imgElement != null) {
        _imgElement!.src = widget.imageUrl;
        _imgElement!.style.visibility = 'hidden';
      }
    } else if (oldWidget.fit != widget.fit) {
      if (_imgElement != null) {
        _imgElement!.style.objectFit = _mapBoxFitToCss(widget.fit);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_hasError && widget.errorWidget != null) {
      content = widget.errorWidget!(context, widget.imageUrl, 'Failed to load web image');
    } else {
      content = Stack(
        fit: StackFit.expand,
        children: [
          HtmlElementView.fromTagName(
            tagName: 'img',
            onElementCreated: (Object element) {
              _configureElement(element as html.ImageElement);
            },
          ),
          if (_isLoading && widget.placeholder != null)
            widget.placeholder!(context, widget.imageUrl),
        ],
      );
    }

    final hasBorderRadius = widget.borderRadius != null && widget.borderRadius != BorderRadius.zero;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: hasBorderRadius
          ? ClipRRect(borderRadius: widget.borderRadius!, child: content)
          : content,
    );
  }

  String _mapBoxFitToCss(BoxFit fit) {
    switch (fit) {
      case BoxFit.cover:
        return 'cover';
      case BoxFit.contain:
        return 'contain';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.fitHeight:
        return 'contain';
      case BoxFit.fitWidth:
        return 'contain';
      case BoxFit.scaleDown:
        return 'scale-down';
      case BoxFit.none:
        return 'none';
    }
  }
}
