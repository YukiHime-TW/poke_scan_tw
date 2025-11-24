import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/collection_provider.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CollectionProvider>(context);

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("PokeScan TW")),
      body: ListView.builder(
        itemCount: provider.database.keys.length,
        itemBuilder: (context, index) {
          String setCode = provider.database.keys.elementAt(index);
          var setData = provider.database[setCode];
          Map cards = setData['cards'];

          // 計算進度
          int ownedCount = 0;
          cards.keys.forEach((key) {
            if (provider.userCollection.containsKey("$setCode-$key")) {
              ownedCount++;
            }
          });
          double progress = cards.isNotEmpty ? ownedCount / cards.length : 0.0;

          return Card(
            margin: const EdgeInsets.all(8),
            child: ExpansionTile(
              title: Text("${setData['name']} ($setCode)"),
              subtitle: LinearProgressIndicator(value: progress),
              trailing: Text("$ownedCount / ${cards.length}"),
              children: [
                Container(
                  // 調整背景色，讓卡片看起來更明顯
                  color: Colors.grey[100],
                  height: 400, // 加大高度方便瀏覽
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, // 改成一行 4 張，圖片比較清楚
                      childAspectRatio: 0.7, // 寶可夢卡片比例約為 0.71
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (ctx, cIndex) {
                      String cNum = cards.keys.elementAt(cIndex);
                      var cardData = cards[cNum];
                      String fullId = "$setCode-$cNum";
                      bool isOwned =
                          provider.userCollection.containsKey(fullId);
                      String shortNum = cNum.split('/')[0];

                      // 取得圖片連結 (如果 JSON 裡面有的話)
                      String? imgUrl = cardData['image'];

                      return InkWell(
                        onTap: () => provider.addCard(setCode, cNum),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // --- 層級 1: 卡片圖片 ---
                            if (imgUrl != null && imgUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: isOwned
                                    ? Image.network(
                                        imgUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (ctx, child, loading) {
                                          if (loading == null) return child;
                                          return Container(
                                              color: Colors.grey[300]);
                                        },
                                        errorBuilder: (ctx, err, stack) =>
                                            Container(
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                    Icons.broken_image)),
                                      )
                                    : ColorFiltered(
                                        // 未擁有：套用黑白濾鏡
                                        colorFilter: const ColorFilter.mode(
                                          Colors.grey,
                                          BlendMode.saturation,
                                        ),
                                        child: Opacity(
                                          opacity: 0.5, // 並讓它變淡
                                          child: Image.network(imgUrl,
                                              fit: BoxFit.cover),
                                        ),
                                      ),
                              )
                            else
                              // 如果沒有圖片連結，顯示回原本的文字框框
                              Container(
                                decoration: BoxDecoration(
                                  color: isOwned
                                      ? Colors.blue[100]
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: Center(child: Text(shortNum)),
                              ),

                            // --- 層級 2: 編號標籤 (右下角) ---
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(6),
                                      bottomRight: Radius.circular(6)),
                                ),
                                child: Text(
                                  "$setCode-$shortNum",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),

                            // --- 層級 3: 擁有數量標記 (如果有複數張) ---
                            if (isOwned)
                              Positioned(
                                left: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check,
                                      size: 10, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.qr_code_scanner),
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ScannerScreen()));
        },
      ),
    );
  }
}
