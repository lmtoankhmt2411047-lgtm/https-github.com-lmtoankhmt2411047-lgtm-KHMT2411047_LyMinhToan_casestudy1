import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/database_helper.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import 'add_transaction_screen.dart';
import 'edit_transaction_screen.dart';

/// Màn hình Dashboard (Trang chủ) - bám theo mẫu "2. Màn hình Dashboard".
/// Dữ liệu (số dư, tổng thu, tổng chi, giao dịch gần đây) lấy từ SQLite.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color bluePrimary = Color(0xFF2F6FED);
  static const Color textGray = Color(0xFF9AA0A6);
  static const Color greenColor = Color(0xFF2E9E4B);
  static const Color redColor = Color(0xFFE0453C);

  int currentTab = 0;
  bool loading = true;

  int totalIncome = 0;
  int totalExpense = 0;
  List<TransactionModel> recent = [];
  Map<int, CategoryModel> categories = {};

  int get balance => totalIncome - totalExpense;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper.instance;
    final cats = await db.getCategories();
    final txs = await db.getRecentTransactions(limit: 5);
    final income = await db.getTotalIncome();
    final expense = await db.getTotalExpense();
    if (!mounted) return;
    setState(() {
      categories = {for (final c in cats) c.id!: c};
      recent = txs;
      totalIncome = income;
      totalExpense = expense;
      loading = false;
    });
  }

  Future<void> _goToAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    _loadData();
  }

  Future<void> _goToEdit(TransactionModel tx) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditTransactionScreen(transaction: tx)),
    );
    _loadData();
  }

  String _money(int value) {
    final sign = value < 0 ? '-' : '';
    final s = value.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$sign${buf.toString()} đ';
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: currentTab == 0
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: currentTab == 0 ? _buildHome() : _buildPlaceholder(),
        floatingActionButton: currentTab == 0
            ? FloatingActionButton(
          backgroundColor: bluePrimary,
          shape: const CircleBorder(),
          onPressed: _goToAdd,
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        )
            : null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentTab,
          onTap: (i) => setState(() => currentTab = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: bluePrimary,
          unselectedItemColor: textGray,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.format_list_bulleted),
              label: 'Giao dịch',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Thống kê',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- TRANG CHỦ ----------------

  Widget _buildHome() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    label: 'Thu nhập',
                    amount: totalIncome,
                    icon: Icons.arrow_upward,
                    bg: const Color(0xFFE6F6EA),
                    iconColor: greenColor,
                    amountColor: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    label: 'Chi tiêu',
                    amount: totalExpense,
                    icon: Icons.arrow_downward,
                    bg: const Color(0xFFFDEBEB),
                    iconColor: redColor,
                    amountColor: const Color(0xFFC62828),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chi tiêu gần đây',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => setState(() => currentTab = 1),
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(color: bluePrimary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          _buildTransactionList(),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final topPad = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: topPad + 150,
          padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 0),
          decoration: const BoxDecoration(
            color: bluePrimary,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Hôm nay là một ngày tốt lành!',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => currentTab = 3),
                child: const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0x33FFFFFF),
                  child: Icon(Icons.person, color: Colors.white, size: 26),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: topPad + 108, left: 16, right: 16),
          child: _buildBalanceCard(),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Số dư hiện tại',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  _money(balance),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE3ECFD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.account_balance_wallet, color: bluePrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required int amount,
    required IconData icon,
    required Color bg,
    required Color iconColor,
    required Color amountColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            _money(amount),
            style: TextStyle(
              color: amountColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (recent.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Chưa có giao dịch nào.\nBấm nút + để thêm giao dịch đầu tiên.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textGray),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (int i = 0; i < recent.length; i++) ...[
              _buildTransactionTile(recent[i]),
              if (i < recent.length - 1)
                const Divider(
                  height: 1,
                  indent: 76,
                  endIndent: 16,
                  color: Color(0xFFEDEEF0),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(TransactionModel tx) {
    final cat = categories[tx.categoryId];
    final isIncome = tx.type == 'income';
    final color = cat?.color ?? const Color(0xFFADB5BD);
    final icon = cat?.icon ?? Icons.category;
    final name = cat?.name ?? 'Khác';
    final sign = isIncome ? '+' : '-';

    return InkWell(
      onTap: () => _goToEdit(tx),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(tx.date),
                    style: const TextStyle(fontSize: 12, color: textGray),
                  ),
                ],
              ),
            ),
            Text(
              '$sign${_money(tx.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isIncome ? greenColor : redColor,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Color(0xFFC4C7CC), size: 20),
          ],
        ),
      ),
    );
  }

  // ---------------- CÁC TAB CÒN LẠI (làm ở buổi sau) ----------------

  Widget _buildPlaceholder() {
    const titles = ['Trang chủ', 'Giao dịch', 'Thống kê', 'Cá nhân'];
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titles[currentTab],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Màn hình này sẽ được làm ở buổi sau',
              style: TextStyle(color: textGray),
            ),
          ],
        ),
      ),
    );
  }
}
