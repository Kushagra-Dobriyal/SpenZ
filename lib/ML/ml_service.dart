import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/Expense_item.dart';

class MLService {
  // Update this URL:
  // Android Emulator: http://10.0.2.2:5000
  // Physical Device: http://YOUR_COMPUTER_IP:5000
  static const String baseUrl = 'http://localhost:5000';

  /// Get all insights (expenses + stocks) in one call
  static Future<Map<String, dynamic>> getAllInsights(
      List<ExpenseItem> transactions, double balance) async {
    try {
      final transactionsJson = transactions.map((tx) => {
            'name': tx.name,
            'amount': tx.amount,
            'dateTime': tx.dateTime.toIso8601String(),
            'type': tx.type,
            'category': 'Miscellaneous',
          }).toList();

      final monthlyIncome = balance / 12; // Approximate

      final response = await http.post(
        Uri.parse('$baseUrl/api/all'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'transactions': transactionsJson,
          'balance': balance,
          'monthly_income': monthlyIncome,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'error': 'Failed to get insights'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get only expense analysis
  static Future<Map<String, dynamic>> analyzeExpenses(
      List<ExpenseItem> transactions) async {
    try {
      final transactionsJson = transactions.map((tx) => {
            'name': tx.name,
            'amount': tx.amount,
            'dateTime': tx.dateTime.toIso8601String(),
            'type': tx.type,
            'category': 'Miscellaneous',
          }).toList();

      final response = await http.post(
        Uri.parse('$baseUrl/api/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'transactions': transactionsJson}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'error': 'Failed to analyze'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get only stock recommendations
  static Future<Map<String, dynamic>> getStocks(
      double balance, double monthlyIncome) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/stocks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'balance': balance,
          'monthly_income': monthlyIncome,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'error': 'Failed to get stocks'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}

