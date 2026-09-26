import 'package:flutter/material.dart';

/// Màn hình Dashboard - Trang chủ "Quản lý thu chi".
/// Dùng: Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentTab = 0;

  static const Color bluePrimary = Color(0xFF2F6FED);
  static const Color textGray = Color(0xFF9AA0A6);

  // Dữ liệu mẫu - sau này thay bằng dữ liệu thật (API / SQLite / SharedPreferences...)
  final int balance = 5000000;
  final int totalIncome = 8000000;
  final int totalExpense = 3000000;

  final List<Map<String, dynamic>> transactions = const [
    {
      'name': 'Ăn trưa',
      'category': 'Ăn uống',
      'date': '03/09/2024',
      'amount': -50000,
      'icon': Icons.restaurant,
      'color': Color(0xFFFF8A3D),
    },
    {
      'name': 'Xăng xe',
      'category': 'Di chuyển',
      'date': '03/09/2024',
      'amount': -100000,
      'icon': Icons.directions_car,
      'color': Color(0xFF4C9AFF),
    },
    {
      'name': 'Lương tháng 9',
      'category': 'Thu nhập',
      'date': '01/09/2024',
      'amount': 8000000,
      'icon': Icons.savings,
      'color': Color(0xFF4CAF50),
    },
    {
      'name': 'Mua sắm',
      'category': 'Mua sắm',
      'date': '31/08/2024',
      'amount': -300000,
      'icon': Icons.shopping_cart,
      'color': Color(0xFF9C6BFF),
    },
    {
      'name': 'Học phí',
      'category': 'Giáo dục',
      'date': '30/08/2024',
      'amount': -500000,
      'icon': Icons.school,
      'color': Color(0xFF14B8A6),
    },
  ];

  String _formatMoney(int value) {
    final isNegative = value < 0;
    final abs = value.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < abs.length; i++) {
      final posFromEnd = abs.length - i;
      buffer.write(abs[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write('.');
    }
    return '${isNegative ? '-' : ''}${buffer.toString()} đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {},
        ),
        title: const Text(
          'Quản lý thu chi',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none, color: Colors.black87, size: 26),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: const Text(
                      '3',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      label: 'TỔNG THU NHẬP',
                      amount: totalIncome,
                      icon: Icons.arrow_downward,
                      bg: const Color(0xFFE7F7EA),
                      fg: const Color(0xFF2E9E4B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      label: 'TỔNG CHI TIÊU',
                      amount: totalExpense,
                      icon: Icons.arrow_upward,
                      bg: const Color(0xFFFDEBEB),
                      fg: const Color(0xFFE0453C),
                      isExpense: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Giao dịch gần đây',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text('Xem tất cả', style: TextStyle(color: bluePrimary)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ...transactions.map((t) => _buildTransactionTile(t)),
            ],
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: FloatingActionButton(
              backgroundColor: bluePrimary,
              onPressed: () {
                // TODO: mở AddTransactionScreen()
              },
              child: const Icon(Icons.add, size: 28),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTab,
        onTap: (i) => setState(() => currentTab = i),
        selectedItemColor: bluePrimary,
        unselectedItemColor: textGray,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Giao dịch'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), label: 'Thống kê'),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF2F6FED), Color(0xFF5B8DF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'SỐ DƯ HIỆN TẠI',
                style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 0.5),
              ),
              SizedBox(width: 6),
              Icon(Icons.visibility_outlined, color: Colors.white70, size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatMoney(balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.account_balance_wallet, color: Colors.white, size: 40),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == 0 ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == 0 ? Colors.white : Colors.white38,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
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
    required Color fg,
    bool isExpense = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: fg.withOpacity(0.15),
                child: Icon(icon, size: 14, color: fg),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatMoney(amount),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> t) {
    final int amount = t['amount'] as int;
    final bool isIncome = amount > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDEEF0))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: (t['color'] as Color).withOpacity(0.15),
            child: Icon(t['icon'] as IconData, color: t['color'] as Color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  '${t['category']}   ${t['date']}',
                  style: const TextStyle(fontSize: 12, color: textGray),
                ),
              ],
            ),
          ),
          Text(
            _formatMoney(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isIncome ? const Color(0xFF2E9E4B) : const Color(0xFFE0453C),
            ),
          ),
        ],
      ),
    );
  }
}
