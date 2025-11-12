import 'package:hive_flutter/hive_flutter.dart';
import '../Model/Expense_item.dart';

class HiveDataBase {
  final _myBox = Hive.box("expense_database");

  void saveData(List<ExpenseItem> allExpense) {
  List<List<dynamic>> allExpensesFormatted = [];

  for (var expense in allExpense) {
    List<dynamic> expenseFormatted = [
      expense.name,
      expense.amount,
      expense.dateTime,
      expense.type, // store type
    ];
    allExpensesFormatted.add(expenseFormatted);
  }
  _myBox.put("All Expenses", allExpensesFormatted);
}
  void saveBalance(double balance) {
    _myBox.put("Balance", balance);
  }
  void saveSettings(List<int> newSettings) {
    _myBox.put("Settings",newSettings[0]);
  }
  int getSettings() {
    return _myBox.get("Settings")?? 0;
  }
  double readBalance() {
    return _myBox.get("Balance") ?? 0.0; // Default to 0.0 if no balance is stored.
  }
   void setCategory(List<String> avlbC){
    _myBox.put("Category", avlbC);
  }

  /// Return the stored category list, or a safe default if nothing valid is stored.
  List<String> getCategory() {
    final raw = _myBox.get("Category");

    // If it's already a List<String>, return it.
    if (raw is List<String>) {
      return raw;
    }

    // If it's a List (e.g., List<dynamic>), try to convert elements to String.
    if (raw is List) {
      try {
        return raw.map((e) => e.toString()).toList();
      } catch (_) {
        // fall through to default
      }
    }

    // Default categories (fallback)
    final defaultCategories = <String>['Education', 'Food', 'Travel', 'Miscellaneous'];

    // Optionally persist the default so next time we read a valid value
    _myBox.put('Category', defaultCategories);

    return defaultCategories;
  }

 List<ExpenseItem> readData() {
  List savedExpenses = _myBox.get("All Expenses") ?? [];
  List<ExpenseItem> allExpenses = [];

  for (int i = 0; i < savedExpenses.length; i++) {
    final rawName = savedExpenses[i][0];
    final rawAmount = savedExpenses[i][1];
    final rawDate = savedExpenses[i][2];

    // type may be missing in older entries
    final rawType = (savedExpenses[i].length > 3) ? savedExpenses[i][3] : 'expense';

    final name = rawName.toString();
    double parsedAmount = double.tryParse(rawAmount.toString()) ?? 0.0;
    if (parsedAmount < 0) parsedAmount = parsedAmount.abs();
    final amountString = parsedAmount.toString();

    DateTime dateTime;
    if (rawDate is DateTime) {
      dateTime = rawDate;
    } else {
      dateTime = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    }

    final type = rawType?.toString() ?? 'expense';

    ExpenseItem expense = ExpenseItem(
      name: name,
      dateTime: dateTime,
      amount: amountString,
      type: type,
    );
    allExpenses.add(expense);
  }
  return allExpenses;
 }
}