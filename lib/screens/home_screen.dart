import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../providers/collection_provider.dart';
import '../providers/deck_provider.dart';
import '../widgets/card_grid_item.dart';
import '../widgets/set_header.dart';
import 'deck_list_screen.dart';

// 擴充狀態過濾：新增 inDeck
enum StatusFilter { all, owned, missing, duplicates, competitive, inDeck }

enum FormatFilter { all, standard, expanded }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, bool> _expandedState = {};
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  StatusFilter _statusFilter = StatusFilter.all;
  FormatFilter _formatFilter = FormatFilter.standard;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesFormat(dynamic cardData) {
    if (_formatFilter == FormatFilter.all) return true;
    String regMark = (cardData['reg'] ?? "").toString().toUpperCase();
    if (_formatFilter == FormatFilter.standard) {
      return ["H", "I", "J", "NONE"].contains(regMark);
    }
    return true;
  }

  Color _getThemeColor(bool isDeckMode) {
    if (_statusFilter == StatusFilter.inDeck) return Colors.teal.shade400;
    if (isDeckMode) return Colors.teal.shade800;

    if (_statusFilter == StatusFilter.duplicates ||
        _statusFilter == StatusFilter.competitive) {
      return Colors.deepPurple.shade700;
    }
    if (_statusFilter == StatusFilter.owned) return Colors.green.shade700;
    if (_statusFilter == StatusFilter.missing) return Colors.orange.shade800;
    if (_formatFilter == FormatFilter.standard) return Colors.blue.shade700;
    if (_formatFilter == FormatFilter.expanded) return Colors.purple.shade700;
    return Colors.redAccent;
  }

  String _getAppBarTitle(bool isDeckMode) {
    if (_isSearching) return "";
    if (_statusFilter == StatusFilter.inDeck) return "當前牌組內容";
    if (isDeckMode) return "正在編輯牌組";

    String title = "PokeScan TW";
    switch (_statusFilter) {
      case StatusFilter.owned:
        title = "我的收藏";
        break;
      case StatusFilter.missing:
        title = "缺卡清單";
        break;
      case StatusFilter.duplicates:
        title = "重複卡片 (>1)";
        break;
      case StatusFilter.competitive:
        title = "多餘物資 (>4)";
        break;
      default:
        break;
    }
    if (_formatFilter == FormatFilter.standard)
      title += " (標準)";
    else if (_formatFilter == FormatFilter.expanded) title += " (開放)";
    return title;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CollectionProvider>(context);
    final deckProvider = Provider.of<DeckProvider>(context);

    final activeDeck = deckProvider.currentDeck;
    final bool isDeckMode = activeDeck != null;
    final themeColor = _getThemeColor(isDeckMode);

    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth < 600 ? 3 : (screenWidth < 1000 ? 5 : 8);

    if (provider.isLoading) {
      return Scaffold(
          body: Center(child: CircularProgressIndicator(color: themeColor)));
    }

    List<Widget> slivers = [];
    String query = _searchText.trim().toLowerCase();

    var sortedKeys = provider.database.keys.toList();
    sortedKeys.sort((a, b) => (provider.database[b]['releaseDate'] ?? "")
        .compareTo(provider.database[a]['releaseDate'] ?? ""));

    for (String setCode in sortedKeys) {
      var setData = provider.database[setCode];
      Map allCards = setData['cards'];
      Map filteredCards = {};

      allCards.forEach((k, v) {
        String fullId = "$setCode-$k";
        int count = provider.userCollection[fullId] ?? 0;

        // --- 核心過濾邏輯 ---
        if (_statusFilter == StatusFilter.inDeck) {
          if (!isDeckMode || !activeDeck.cards.containsKey(fullId)) return;
        } else {
          if (_statusFilter == StatusFilter.owned && count == 0) return;
          if (_statusFilter == StatusFilter.missing && count > 0) return;
          if (_statusFilter == StatusFilter.duplicates && count <= 1) return;
          if (_statusFilter == StatusFilter.competitive && count <= 4) return;
        }

        if (!_matchesFormat(v)) return;

        if (query.isNotEmpty) {
          String cardName = v['name'].toString().toLowerCase();
          if (!cardName.contains(query) && !k.contains(query)) return;
        }
        filteredCards[k] = v;
      });

      if (filteredCards.isEmpty) continue;

      int ownedInSet = allCards.keys
          .where((k) => provider.userCollection.containsKey("$setCode-$k"))
          .length;
      // 搜尋或檢視牌組清單時強制展開
      bool isExpanded =
          (query.isNotEmpty || _statusFilter == StatusFilter.inDeck)
              ? true
              : (_expandedState[setCode] ?? false);

      slivers.add(
        MultiSliver(
          pushPinnedChildren: true,
          children: [
            SliverPinnedHeader(
              child: SetHeader(
                title: setData['name'],
                setCode: setCode,
                progress:
                    allCards.isNotEmpty ? ownedInSet / allCards.length : 0,
                owned: ownedInSet,
                total: allCards.length,
                isExpanded: isExpanded,
                themeColor: themeColor,
                onTap: () {
                  if (query.isEmpty && _statusFilter != StatusFilter.inDeck)
                    setState(() => _expandedState[setCode] = !isExpanded);
                },
              ),
            ),
            if (isExpanded)
              SliverPadding(
                padding: const EdgeInsets.all(8.0),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => CardGridItem(
                        setCode: setCode,
                        cNum: filteredCards.keys.elementAt(i),
                        cardData: filteredCards.values.elementAt(i)),
                    childCount: filteredCards.length,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    hintText: "搜尋...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70)),
                onChanged: (val) => setState(() => _searchText = val),
              )
            : Text(_getAppBarTitle(isDeckMode),
                style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () => setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchText = "";
                      _searchController.clear();
                    }
                  })),
          _buildFilterMenu(isDeckMode),
          IconButton(
              icon: const Icon(Icons.style),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DeckListScreen()))),
          Consumer<CollectionProvider>(
            builder: (context, prov, _) => prov.user == null
                ? IconButton(
                    icon: const Icon(Icons.login),
                    onPressed: () => prov.signInWithGoogle())
                : InkWell(
                    onTap: () => _showLogoutDialog(context, prov),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: CircleAvatar(
                          radius: 14,
                          backgroundImage: prov.user!.photoURL != null
                              ? NetworkImage(prov.user!.photoURL!)
                              : null),
                    ),
                  ),
          ),
        ],
        bottom: activeDeck == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              "編輯：${activeDeck.name} (${activeDeck.cards.values.fold(0, (sum, c) => sum + c)}/60)",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13))),
                      TextButton(
                          onPressed: () {
                            deckProvider.selectDeck(null);
                            setState(() =>
                                _statusFilter = StatusFilter.all); // 退出時重設過濾
                          },
                          child: const Text("完成",
                              style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ),
      ),
      body: CustomScrollView(cacheExtent: 1000, slivers: slivers),
    );
  }

  Widget _buildFilterMenu(bool isDeckMode) {
    return PopupMenuButton<dynamic>(
      icon: const Icon(Icons.filter_list),
      onSelected: (value) => setState(() {
        if (value is StatusFilter) _statusFilter = value;
        if (value is FormatFilter) _formatFilter = value;
      }),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<dynamic>>[
        const PopupMenuItem(
            enabled: false,
            child: Text("收藏狀態",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey))),
        _buildPopupItem(StatusFilter.all, Icons.apps, "顯示全部",
            _statusFilter == StatusFilter.all),

        // --- 智慧選項：僅編輯模式顯示 ---
        if (isDeckMode)
          _buildPopupItem(StatusFilter.inDeck, Icons.fact_check, "這副牌的卡片",
              _statusFilter == StatusFilter.inDeck),

        _buildPopupItem(StatusFilter.owned, Icons.check_circle, "只看已擁有",
            _statusFilter == StatusFilter.owned),
        _buildPopupItem(StatusFilter.missing, Icons.radio_button_unchecked,
            "只看未擁有", _statusFilter == StatusFilter.missing),
        _buildPopupItem(StatusFilter.duplicates, Icons.copy, "重複 (>1)",
            _statusFilter == StatusFilter.duplicates),
        _buildPopupItem(StatusFilter.competitive, Icons.layers, "多餘 (>4)",
            _statusFilter == StatusFilter.competitive),
        const PopupMenuDivider(),
        const PopupMenuItem(
            enabled: false,
            child: Text("賽制篩選",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey))),
        _buildPopupItem(FormatFilter.all, Icons.not_interested, "不限賽制",
            _formatFilter == FormatFilter.all),
        _buildPopupItem(FormatFilter.standard, Icons.verified_user, "標準賽制",
            _formatFilter == FormatFilter.standard),
        _buildPopupItem(FormatFilter.expanded, Icons.public, "開放賽制",
            _formatFilter == FormatFilter.expanded),
      ],
    );
  }

  PopupMenuEntry<dynamic> _buildPopupItem(
      dynamic value, IconData icon, String title, bool isSelected) {
    Color activeColor = _getThemeColor(false);
    return PopupMenuItem<dynamic>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: isSelected ? activeColor : Colors.grey, size: 20),
          const SizedBox(width: 12),
          Text(title,
              style: TextStyle(
                  color: isSelected ? activeColor : Colors.black87,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal)),
          const Spacer(),
          if (isSelected) Icon(Icons.check, color: activeColor, size: 16),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, CollectionProvider provider) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text("登出"),
                content: Text("確定要登出 ${provider.user!.displayName} 嗎？"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("取消")),
                  TextButton(
                      onPressed: () {
                        provider.signOut();
                        Navigator.pop(ctx);
                      },
                      child:
                          const Text("登出", style: TextStyle(color: Colors.red)))
                ]));
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text("使用說明"),
                content:
                    const Text("• 點擊板手進入編輯模式\n• 編輯時可過濾「這副牌的卡片」\n• 長按卡片可快速連續減量"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("我知道了"))
                ]));
  }
}
