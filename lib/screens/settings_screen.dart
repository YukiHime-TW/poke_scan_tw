import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/collection_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = "";

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = "${info.version} (${info.buildNumber})");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CollectionProvider>();
    final user = prov.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("設定"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _sectionLabel("帳號"),
          if (user == null)
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text("使用 Google 登入"),
              subtitle: const Text("登入後收藏、願望清單與牌組跨裝置同步"),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final err = await prov.signInWithGoogle();
                if (err != null) {
                  messenger.showSnackBar(SnackBar(content: Text(err)));
                }
              },
            )
          else
            ListTile(
              leading: CircleAvatar(
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null ? const Icon(Icons.person) : null,
              ),
              title: Text(user.displayName ?? "已登入"),
              subtitle: Text(user.email ?? ""),
              trailing: TextButton(
                onPressed: () => _confirmLogout(context, prov),
                child: const Text("登出", style: TextStyle(color: Colors.red)),
              ),
            ),

          const SizedBox(height: 8),
          _sectionLabel("收藏資料"),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("清空收藏資料",
                style: TextStyle(color: Colors.red)),
            subtitle: const Text("收藏數量與願望清單全部歸零；牌組 / 收藏本不受影響"),
            onTap: () => _confirmClear(context, prov),
          ),
          if (prov.canUndoClear)
            ListTile(
              leading: const Icon(Icons.undo, color: Colors.blue),
              title: const Text("復原剛才的清空"),
              subtitle: const Text("下次開啟 App 後就無法復原"),
              onTap: () async {
                await prov.undoClearCollection();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("已復原")));
                }
              },
            ),

          const SizedBox(height: 8),
          _sectionLabel("關於"),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text("使用說明"),
            onTap: () => showHelpDialog(context),
          ),
          if (prov.feedbackUrl != null)
            ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: const Text("回報問題"),
              onTap: () => _openFeedback(context, prov.feedbackUrl!),
            ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("版本"),
            trailing: Text(_version,
                style: const TextStyle(color: Colors.black54)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600)),
      );

  void _confirmLogout(BuildContext context, CollectionProvider prov) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("登出"),
        content: Text("確定要登出 ${prov.user!.displayName} 嗎？登出會清除本機資料"
            "（雲端資料保留，下次登入還原）。"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("取消")),
          TextButton(
            onPressed: () {
              prov.signOut();
              Navigator.pop(ctx);
            },
            child: const Text("登出", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, CollectionProvider prov) {
    final controller = TextEditingController();
    final loggedIn = prov.user != null;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final ok = controller.text.trim() == "清空";
          return AlertDialog(
            title: const Text("清空收藏資料"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "所有卡片的收藏數量與願望清單將全部歸零，牌組不受影響。"
                  "${loggedIn ? '\n\n你目前已登入，這也會同步清空雲端，'
                      '並影響你的其他裝置。' : ''}"
                  "\n\n清空後可在設定畫面按一次「復原」（下次開 App 前有效）。",
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: "輸入「清空」以確認",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setLocal(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("取消")),
              TextButton(
                onPressed: ok
                    ? () async {
                        Navigator.pop(ctx);
                        await prov.clearCollection();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text("收藏已清空"),
                          duration: const Duration(seconds: 8),
                          action: SnackBarAction(
                            label: "復原",
                            onPressed: prov.undoClearCollection,
                          ),
                        ));
                      }
                    : null,
                child: const Text("清空", style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _openFeedback(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final uri = Uri.tryParse(url);
  final ok = uri != null &&
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) {
    messenger.showSnackBar(
        const SnackBar(content: Text("無法開啟回報頁面")));
  }
}

void showHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.style, color: Colors.redAccent),
          SizedBox(width: 10),
          Expanded(child: Text("繁中PTCG集換所 使用手冊")),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "繁體中文 PTCG 玩家與收藏家的工具：收藏管理、牌組構築、相機掃描登錄，登入後可跨裝置同步。",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const Divider(height: 30),
              _buildHelpHeader("1. 收藏管理", Icons.touch_app),
              _buildHelpItem("增加數量", "直接點擊卡片，收藏數量 +1。"),
              _buildHelpItem("卡片詳情", "長按卡片開啟詳情：招式、特性、效果、弱點、繪師等，"
                  "並可在裡面調整「收藏 / 這副 / 想要」的張數。"),
              _buildHelpItem("視覺辨識",
                  "• 彩色：已擁有\n• 黑白半透明：尚未收藏\n• 左上角紅圈：持有數量\n• 左下角粉紅星星：願望清單想要數"),
              _buildHelpHeader("2. 願望清單", Icons.star_border),
              _buildHelpItem(
                  "加入 / 調整", "在卡片詳情裡的「想要」+/− 設定想要幾張。收藏數達到想要數時會自動移出清單。"),
              _buildHelpItem("檢視 / 複製",
                  "篩選面板選「願望清單」只看已標的卡；此時右上角出現「複製」，可輸出「還缺 N」的對齊文字貼社群。"),
              _buildHelpHeader("3. 搜尋與過濾", Icons.search),
              _buildHelpItem(
                  "搜尋", "點放大鏡輸入 名稱 / 編號 / 系列代碼或系列名，按 Enter。"),
              _buildHelpItem("篩選面板", "點漏斗開啟，各組用 chip 選：\n"
                  "• 收藏狀態（含願望清單）\n• 賽制（標準 / 開放）\n• 種類 / 屬性\n"
                  "• 稀有度、機制標籤（依資料動態產生）\n漏斗上的數字 = 目前生效幾個篩選。"),
              const Padding(
                padding: EdgeInsets.only(left: 12, top: 4, bottom: 6),
                child: Column(
                  children: [
                    _ColorTip(Colors.redAccent, "紅：一般瀏覽"),
                    _ColorTip(Colors.green, "綠：只看已擁有"),
                    _ColorTip(Colors.orange, "橘：只看未擁有"),
                    _ColorTip(Colors.deepPurple, "紫：重複 / 競技用量"),
                    _ColorTip(Colors.pink, "粉紅：願望清單"),
                  ],
                ),
              ),
              _buildHelpHeader("4. 牌組與收藏本", Icons.style),
              _buildHelpItem("種類區分",
                  "• 牌組：限 60 張、同名 4 張。額外上限：光輝寶可夢 / ACE SPEC 各限 1 張、"
                  "◇（稜柱之星）卡同名限 1 張、「傳說的」競技場同名限 2 張（1 張算 2 張）、"
                  "V-UNION 寶可夢整套限 1 種（算 4 張）\n• 收藏本：無張數與同名限制"),
              _buildHelpItem("合法性標記", "牌組名稱旁：\n"
                  "• 標準：全部標準賽制合法（含官方「過往可用卡清單」的舊標記卡）\n"
                  "• 開放：含已輪替的卡\n"
                  "• 未完成：未滿 60 張、沒有基礎寶可夢、違反上述額外張數規則，"
                  "或含官方禁用卡\n"
                  "預覽頁會列出非標準卡、禁用卡、以及違反了哪條規則。"),
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("🛠️ 編輯模式",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text("點「板手」進入，上方顯示青色條；點卡片 = 放入牌組。",
                        style: TextStyle(fontSize: 13, color: Colors.black54)),
                    _LabelRow(Colors.teal.shade600, "青標籤：庫存充足"),
                    _LabelRow(Colors.red.shade900, "紅標籤 + ⚠️：實體收藏不足"),
                  ],
                ),
              ),
              _buildHelpHeader("5. 其他", Icons.bolt),
              _buildHelpItem("卡片用途查詢", "非編輯模式點卡片底部「用於 N 副牌」可查看位置。"),
              _buildHelpItem("牌組導出", "牌組清單點「複製」生成對齊的分享文字。"),
              _buildHelpItem("雲端同步", "登入 Google 後收藏與牌組跨裝置自動同步；登出會清掉本機資料。"),
              _buildHelpItem("設定", "右上角頭像進入：登入 / 登出、清空收藏、使用說明、回報問題、版本。"),
              const Divider(height: 30),
              _buildHelpHeader("💡 小提示", Icons.lightbulb_outline),
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text(
                  "• 基本能量在牌組模式下不受 4 張限制。\n"
                  "• 點系列標題橫條可收合 / 展開（有篩選時會強制展開）。\n"
                  "• 賽制篩選會記住，其他篩選每次開 App 還原預設。\n"
                  "• 內建智慧縮圖，第二次開卡片秒開。",
                  style: TextStyle(
                      fontSize: 13, color: Colors.blueGrey, height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("關閉",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    ),
  );
}

Widget _buildHelpHeader(String title, IconData icon) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey.shade700),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey)),
      ],
    ),
  );
}

Widget _buildHelpItem(String title, String content) {
  return Padding(
    padding: const EdgeInsets.only(left: 12, bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 2),
        Text(content,
            style: const TextStyle(
                fontSize: 13, color: Colors.black54, height: 1.4)),
      ],
    ),
  );
}

// 顏色提示
class _ColorTip extends StatelessWidget {
  final Color color;
  final String text;
  const _ColorTip(this.color, this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}

// 標籤範例
class _LabelRow extends StatelessWidget {
  final Color color;
  final String text;
  const _LabelRow(this.color, this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(4)),
            child: const Text("IN: 1",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }
}
