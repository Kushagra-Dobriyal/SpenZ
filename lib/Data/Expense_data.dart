import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:spendz/Data/hive_database.dart';
import '../Model/Expense_item.dart';

class ExpenseData extends ChangeNotifier {
  final db = HiveDataBase();

  List<ExpenseItem> overallExpenseList = [];
  List<int> savedSettings = [0, 0, 0, 0];

  // Constructor: load stored items immediately
  ExpenseData();

  List<ExpenseItem> getExpenseList() {
    return overallExpenseList;
  }

 double sumIncome() {
  return overallExpenseList
      .where((t) => t.type == 'income')
      .fold(0.0, (s, t) => s + (double.tryParse(t.amount) ?? 0.0).abs());
}

double sumExpense() {
  return overallExpenseList
      .where((t) => t.type == 'expense')
      .fold(0.0, (s, t) => s + (double.tryParse(t.amount) ?? 0.0).abs());
}

double computeBalance() {
  return sumIncome() - sumExpense();
}

// keep getBalance but compute from transactions (no longer rely on saved Balance)
double getBalance() {
  return computeBalance();
}


  void setBalance(double balance) {
    db.saveBalance(balance);
    notifyListeners();
  }

  // Read stored data and normalize amounts to positive strings
  void prepareData() {
    final stored = db.readData();
    if (stored.isNotEmpty) {
      overallExpenseList = stored;
    } else {
      overallExpenseList = [];
    }
    notifyListeners();
  }

 List<double> weeklyAmounts({String? typeFilter}) {
  final list = List<double>.filled(7, 0.0);

  for (var tx in overallExpenseList) {
    // If a type filter is provided (e.g., "expense"), skip others
    if (typeFilter != null && tx.type != typeFilter) continue;

    final amt = double.tryParse(tx.amount.toString()) ?? 0.0;
    final weekday = tx.dateTime.weekday; // Mon = 1, ..., Sun = 7
    final idx = weekday % 7; // Sun -> 0, Mon -> 1, ..., Sat -> 6
    list[idx] += amt.abs();
  }

  return list;
}

  // ---- helper: compute a sensible maxY (non-null) ----
  double computeChartMaxY([List<double>? values]) {
    final vals = values ?? weeklyAmounts();
    if (vals.isEmpty) return 100.0;
    double maxVal = vals.reduce((a, b) => a > b ? a : b);
    if (maxVal <= 0) return 100.0;
    // add some padding so bars aren't flush with top
    final padded = maxVal * 1.2;
    // round up to a clean number
    final magnitude =
        pow(10, padded.floor().toString().length - 1).toDouble();
    // simple ceil to nearest 10/100 etc:
    return (padded / magnitude).ceilToDouble() * magnitude;
  }

 void addExpense(ExpenseItem newExpense) {
  final amt = double.tryParse(newExpense.amount) ?? 0.0;
  final normalized = ExpenseItem(
    name: newExpense.name,
    dateTime: newExpense.dateTime,
    amount: amt.abs().toString(),
    type: 'expense',
  );
  overallExpenseList.add(normalized);
  db.saveData(overallExpenseList);
  notifyListeners();
}

void addIncome(ExpenseItem newIncome) {
  final amt = double.tryParse(newIncome.amount) ?? 0.0;
  final normalized = ExpenseItem(
    name: newIncome.name,
    dateTime: newIncome.dateTime,
    amount: amt.abs().toString(),
    type: 'income',
  );
  overallExpenseList.add(normalized);
  db.saveData(overallExpenseList);
  notifyListeners();
}

  // deleteExpense: remove and update stored data and balance
  void deleteExpense(ExpenseItem expense) {
    final double amt = double.tryParse(expense.amount) ?? 0.0;

    overallExpenseList.remove(expense);
    db.saveData(overallExpenseList);

    // update stored balance by subtracting removed amount
    final double newBalance = getBalance() - amt;
    setBalance(newBalance);

    notifyListeners();
  }

  void addSettings(int settingNum, int newSetting) {
    if (settingNum >= 0 && settingNum < savedSettings.length) {
      savedSettings[settingNum] = newSetting;
      db.saveSettings(savedSettings);
      notifyListeners();
    }
  }

  int getSavedSettings(int settingNum) {
    savedSettings[0] = db.getSettings();
    return savedSettings[0];
  }

  void clearAllExpenses() {
    overallExpenseList.clear();
    db.saveData(overallExpenseList);
    // optionally reset balance too:
    setBalance(0.0);
    notifyListeners();
  }
}
