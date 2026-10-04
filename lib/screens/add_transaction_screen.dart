import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/transaction_model.dart';
/// Màn hình Thêm giao dịch.
/// Dùng: Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool isExpense = true; // true = Chi tiêu, false = Thu nhập
  DateTime selectedDate = DateTime.now();

  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  final List<Map<String, dynamic>> categories = const [
    {'name': 'Ăn uống', 'icon': Icons.restaurant, 'color': Color(0xFFFA5A5A)},
    {'name': 'Di chuyển', 'icon': Icons.directions_car, 'color': Color(0xFF4C9AFF)},
    {'name': 'Mua sắm', 'icon': Icons.shopping_bag, 'color': Color(0xFFFFA94D)},
    {'name': 'Hóa đơn', 'icon': Icons.receipt_long, 'color': Color(0xFF9C88FF)},
    {'name': 'Giải trí', 'icon': Icons.movie, 'color': Color(0xFF63E6BE)},
    {'name': 'Khác', 'icon': Icons.more_horiz, 'color': Color(0xFFADB5BD)},
  ];

  late Map<String, dynamic> selectedCategory = categories.first;

  static const Color bluePrimary = Color(0xFF2F6FED);
  static const Color redPrimary = Color(0xFFFA5A5A);
  static const Color borderGray = Color(0xFFE3E5E8);
  static const Color textGray = Color(0xFF6B7280);

  String get formattedDate =>
      '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  void _pickCategory() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: categories.map((cat) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: (cat['color'] as Color).withOpacity(0.15),
                  child: Icon(cat['icon'] as IconData, color: cat['color'] as Color),
                ),
                title: Text(cat['name'] as String),
                onTap: () {
                  setState(() => selectedCategory = cat);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final amount = amountController.text.trim();
    if (amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền')),
      );
      return;
    }
    final result = {
      'type': isExpense ? 'expense' : 'income',
      'category': selectedCategory['name'],
      'amount': amount,
      'date': selectedDate,
      'note': noteController.text.trim(),
    };
    await DatabaseHelper.instance.insertTransaction(
      TransactionModel(
        categoryId: 1,
        amount: int.parse(amount),
        type: isExpense ? 'expense' : 'income',
        date: selectedDate,
        note: noteController.text,
      ),
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Thêm giao dịch',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle Chi tiêu / Thu nhập
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isExpense = true),
                      child: Container(
                        height: 48,
                        margin: const EdgeInsets.only(right: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isExpense ? redPrimary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isExpense ? redPrimary : borderGray),
                        ),
                        child: Text(
                          'Chi tiêu',
                          style: TextStyle(
                            color: isExpense ? Colors.white : textGray,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isExpense = false),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: !isExpense ? redPrimary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: !isExpense ? redPrimary : borderGray),
                        ),
                        child: Text(
                          'Thu nhập',
                          style: TextStyle(
                            color: !isExpense ? Colors.white : textGray,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _label('Danh mục'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickCategory,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderGray),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: (selectedCategory['color'] as Color).withOpacity(0.15),
                        child: Icon(selectedCategory['icon'] as IconData,
                            size: 16, color: selectedCategory['color'] as Color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(selectedCategory['name'] as String)),
                      const Icon(Icons.keyboard_arrow_down, color: textGray),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _label('Số tiền'),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Nhập số tiền',
                  suffixText: 'đ',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: borderGray),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _label('Ngày giao dịch'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderGray),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(formattedDate)),
                      const Icon(Icons.calendar_today_outlined, size: 18, color: textGray),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _label('Ghi chú'),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhập ghi chú (tùy chọn)',
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: borderGray),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bluePrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Lưu',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      );
}
