import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/collection_provider.dart';

/// 盤點對帳畫面：列出本次掃到的每張卡（資料庫數 vs 本次掃到），
/// 每列最終數量可調（預設帶「取大的」，永不誤減）；
/// 最後決定沒掃到的卡「保留原數 / 全部歸零」，再套用。
class StocktakeReviewScreen extends StatefulWidget {
  const StocktakeReviewScreen({super.key});

  @override
  State<StocktakeReviewScreen> createState() => _StocktakeReviewScreenState();
}

class _StocktakeReviewScreenState extends State<StocktakeReviewScreen> {
  late final List<StocktakeRow> _rows;
  final Map<String, int> _final = {};
  bool _zeroUnscanned = false;
  final TextEditingController _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rows = context.read<CollectionProvider>().stocktakeRows();
    for (final r in _rows) {
      _final[r.id] = r.scanned > r.db ? r.scanned : r.db; // max(db, scanned)
    }
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diffCount = _rows.where((r) => !r.matches).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("盤點對帳"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _confirmDiscard,
            child: const Text("放棄", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.teal.shade50,
            padding: const EdgeInsets.all(12),
            child: Text(
              _rows.isEmpty
                  ? "本次沒有掃到任何卡片。"
                  : "本次掃到 ${_rows.length} 種、"
                      "${_rows.fold<int>(0, (a, r) => a + r.scanned)} 張"
                      "（其中 $diffCount 種與收藏不一致）",
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _rowTile(_rows[i]),
            ),
          ),
          _unscannedChooser(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text("套用盤點"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowTile(StocktakeRow r) {
    final v = _final[r.id] ?? r.db;
    return ListTile(
      leading: SizedBox(
        width: 40,
        child: r.image.isEmpty
            ? const Icon(Icons.image_not_supported, color: Colors.black26)
            : CachedNetworkImage(
                imageUrl: r.image,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.broken_image, color: Colors.black26),
              ),
      ),
      title: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        "資料庫 ${r.db} · 本次掃到 ${r.scanned}",
        style: TextStyle(
            color: r.matches ? Colors.black45 : Colors.orange.shade800,
            fontWeight: r.matches ? FontWeight.normal : FontWeight.bold),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: v <= 0
                ? null
                : () => setState(() => _final[r.id] = v - 1),
          ),
          SizedBox(
            width: 26,
            child: Text("$v",
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: v >= 99
                ? null
                : () => setState(() => _final[r.id] = v + 1),
          ),
        ],
      ),
    );
  }

  Widget _unscannedChooser() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const Divider(height: 1),
          SwitchListTile(
            value: _zeroUnscanned,
            // 一張都沒掃就不可能是「完整盤點」，不給開
            onChanged: _rows.isEmpty
                ? null
                : (x) => setState(() => _zeroUnscanned = x),
            activeThumbColor: Colors.red,
            title: const Text("把這次沒掃到的收藏卡全部歸零"),
            subtitle: Text(
              _zeroUnscanned
                  ? "確定已把每一張都攤出來數過再開"
                  : "關：沒攤出來數的卡維持原數（預設）",
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _apply() async {
    final prov = context.read<CollectionProvider>();
    final messenger = ScaffoldMessenger.of(context); // pop 後這個 context 會失效
    final navigator = Navigator.of(context);
    if (_zeroUnscanned) {
      final ok = await _typeConfirm();
      if (ok != true) return;
    }
    await prov.commitStocktake(_final, zeroUnscanned: _zeroUnscanned);
    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
        const SnackBar(content: Text("盤點完成，收藏已更新")));
  }

  Future<bool?> _typeConfirm() {
    _confirmController.clear();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final ok = _confirmController.text.trim() == "歸零";
          return AlertDialog(
            title: const Text("確認全部歸零"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "這次沒掃到的收藏卡會全部歸零。若你其實只是沒把牌組 / 收藏本裡的卡"
                  "攤出來，請改選「保留原數」。",
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: "輸入「歸零」以確認",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setLocal(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("取消")),
              TextButton(
                onPressed: ok ? () => Navigator.pop(ctx, true) : null,
                child: const Text("確認歸零",
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDiscard() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("放棄盤點"),
        content: const Text("這次掃到的計數會全部丟棄，收藏不變。"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("取消")),
          TextButton(
            onPressed: () async {
              await context.read<CollectionProvider>().cancelStocktake();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("放棄", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
