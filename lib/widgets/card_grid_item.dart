import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/collection_provider.dart';

class CardGridItem extends StatefulWidget {
  final String setCode;
  final String cNum;
  final dynamic cardData;

  const CardGridItem(
      {super.key,
      required this.setCode,
      required this.cNum,
      required this.cardData});

  @override
  State<CardGridItem> createState() => _CardGridItemState();
}

class _CardGridItemState extends State<CardGridItem> {
  Timer? _timer;
  int _interval = 500;

  String _getOptimizedUrl(String? rawUrl, double screenWidth) {
    if (rawUrl == null || rawUrl.isEmpty || rawUrl == "X") return "";
    String cleanUrl = rawUrl.replaceFirst(RegExp(r'^https?://'), '');
    int requestWidth = 300;
    if (screenWidth > 1200)
      requestWidth = 600;
    else if (screenWidth > 600) requestWidth = 450;
    return "https://wsrv.nl/?url=$cleanUrl&w=$requestWidth&q=80&output=webp&il";
  }

  Widget _buildPlaceholder(String shortNum, bool isOwned,
      {bool isError = false}) {
    return Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(shortNum,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      color: isOwned ? Colors.black87 : Colors.grey[500]))),
          const SizedBox(height: 2),
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(widget.cardData['name'] ?? "",
                  style: TextStyle(
                      fontSize: 24,
                      color: isOwned ? Colors.black87 : Colors.grey[500]))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CollectionProvider>(context);
    double screenWidth = MediaQuery.of(context).size.width;
    String fullId = "${widget.setCode}-${widget.cNum}";
    int count = provider.userCollection[fullId] ?? 0;
    bool isOwned = count > 0;
    String shortNum = widget.cNum.split('/')[0];
    String optimizedImgUrl =
        _getOptimizedUrl(widget.cardData['image'], screenWidth);

    return GestureDetector(
      onTap: () => provider.addCard(widget.setCode, widget.cNum),
      onLongPressStart: (_) {
        if (count > 0) _startDecreasing(provider);
      },
      onLongPressEnd: (_) => _stopDecreasing(),
      onLongPressCancel: () => _stopDecreasing(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isOwned ? Colors.white : Colors.grey[200],
          borderRadius: BorderRadius.circular(6),
          border: isOwned
              ? Border.all(color: Colors.amber.shade600, width: 2)
              : Border.all(color: Colors.grey.shade400, width: 1),
          boxShadow: [
            if (isOwned)
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (optimizedImgUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: optimizedImgUrl,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) =>
                      _buildPlaceholder(shortNum, isOwned),
                  errorWidget: (ctx, url, err) =>
                      _buildPlaceholder(shortNum, isOwned, isError: true),
                  imageBuilder: (ctx, imageProvider) => isOwned
                      ? Image(image: imageProvider, fit: BoxFit.cover)
                      : ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                              Colors.grey, BlendMode.saturation),
                          child: Opacity(
                              opacity: 0.4,
                              child: Image(
                                  image: imageProvider, fit: BoxFit.cover)),
                        ),
                )
              else
                _buildPlaceholder(shortNum, isOwned),
              _buildCardBadge("${widget.setCode}-$shortNum"),
              if (isOwned) _buildCountBadge(count),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardBadge(String label) {
    return Positioned(
        right: 0,
        bottom: 0,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius:
                    const BorderRadius.only(topLeft: Radius.circular(6))),
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Monospace"))));
  }

  Widget _buildCountBadge(int count) {
    return Positioned(
        left: 2,
        top: 2,
        child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 2)
                ]),
            child: Center(
                child: Text("x$count",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900)))));
  }

  void _startDecreasing(CollectionProvider p) {
    _interval = 500;
    _loop(p);
  }

  void _loop(CollectionProvider p) {
    p.removeCard(widget.setCode, widget.cNum);
    _interval = (_interval * 0.8).toInt();
    if (_interval < 50) _interval = 50;
    _timer = Timer(Duration(milliseconds: _interval), () => _loop(p));
  }

  void _stopDecreasing() {
    _timer?.cancel();
  }
}
