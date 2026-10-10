import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/database_helper.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

/// Màn hình Sửa giao dịch.
/// Nhận 1 giao dịch từ database, sửa xong bấm Lưu sẽ cập nhật SQLite rồi trả về true.
/// Dùng: Navigator.push(context, MaterialPageRoute(
///   builder: (_) => EditTransactionScreen(transaction: tx)));
class EditTransactionScreen extends StatefulWidget {
  final TransactionModel transaction;

  const EditTransactionScreen({super.key, required this.transaction});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  static const Color bluePrimary = Color(0xFF2F6FED);
  static const Color redPrimary = Color(0xFFFA5A5A);
  static const Color borderGray = Color(0xFFE3E5E8);
  static const Color textGray = Color(0xFF6B7280);

  late bool isExpense;
  late DateTime selectedDate;
  late final TextEditingController amountController;
  late final TextEditingController noteController;

  List<CategoryModel> categories = [];
  CategoryModel? selectedCategory;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    isExpense = tx.type == 'expense';
    selectedDate = tx.date;
    amountController = TextEditingController(text: _groupDigits(tx.amount.toString()));
    noteController = TextEditingController(text: tx.note);
    _loadCategories();
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final list = await DatabaseHelper.instance.getCategories(
      type: isExpense ? 'expense' : 'income',
    );
    if (!mounted) return;
    CategoryModel? current;
    for (final c in list) {
      if (c.id == widget.transaction.categoryId) current = c;
    }
    setState(() {
      categories = list;
      selectedCategory = current ?? (list.isNotEmpty ? list.first : null);
    });
  }

  void _selectType(bool expense) {
    if (isExpense == expense) return;
    setState(() => isExpense = expense);
    _loadCategories();
  }

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
    if (categories.isEmpty) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: categories.map((cat) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: cat.color.withValues(alpha: 0.15),
                  child: Icon(cat.icon, color: cat.color),
                ),
                title: Text(cat.name),
                onTap: () {
                  setState(() => selectedCategory = cat);
                  Navigator.pop(sheetContext);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final amount =
        int.tryParse(amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền')),
      );
      return;
    }
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục')),
      );
      return;
    }

    await DatabaseHelper.instance.updateTransaction(
      TransactionModel(
        id: widget.transaction.id,
        categoryId: selectedCategory!.id!,
        amount: amount,
        type: isExpense ? 'expense' : 'income',
        date: selectedDate,
        note: noteController.text.trim(),
      ),
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final cat = selectedCategory;
    final catColor = cat?.color ?? textGray;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Sửa giao dịch',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _typeTab(
                    text: 'Chi tiêu',
                    selected: isExpense,
                    onTap: () => _selectType(true),
                    margin: const EdgeInsets.only(right: 8),
                  ),
                  _typeTab(
                    text: 'Thu nhập',
                    selected: !isExpense,
                    onTap: () => _selectType(false),
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
                        backgroundColor: catColor.withValues(alpha: 0.15),
                        child: Icon(cat?.icon ?? Icons.category, size: 16, color: catColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(cat?.name ?? 'Chọn danh mục')),
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
                inputFormatters: [_ThousandsSeparatorFormatter()],
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

  Widget _typeTab({
    required String text,
    required bool selected,
    required VoidCallback onTap,
    EdgeInsets margin = EdgeInsets.zero,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          margin: margin,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? redPrimary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? redPrimary : borderGray),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : textGray,
              fontWeight: FontWeight.bold,
            ),
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

/// Thêm dấu chấm ngăn cách hàng nghìn khi gõ số tiền: 100000 -> 100.000
String _groupDigits(String digits) {
  final buf = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return buf.toString();
}

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final text = _groupDigits(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
