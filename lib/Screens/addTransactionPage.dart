import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spendz/Data/Expense_data.dart';
import 'package:spendz/Model/Expense_item.dart';
import 'package:spendz/utils.dart';
import 'package:spendz/Screens/Settings/Categories.dart';

enum TypeEI { expense, income }

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AddTransactionPage(),
    );
  }
}

class AddTransactionPage extends StatefulWidget {
  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  Set<TypeEI> selectedAccessories = <TypeEI>{TypeEI.expense};
  TypeEI selectedIndex = TypeEI.expense;
  // Variables to store transaction details
  String? title;
  double? amount;
  String? selectedCategory; // Selected category
  DateTime? dateTime;
  // Create text editing controllers for the input fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int? _value;
  var avlC = ['Education', 'Food', 'Travel', 'Miscellaneous'];

  void _submitForm() {
    // Validate form first. If invalid, stop and show errors.
    if (!_formKey.currentState!.validate()) {
      // Form invalid: do nothing (validator will show messages).
      return;
    }

    // At this point the form is valid; ensure amount isn't null.
    final double enteredAmount = amount ?? 0.0;
    if (enteredAmount <= 0) {
      // Optional: show a snackbar if amount is zero or negative
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount greater than 0')),
      );
      return;
    }

    // Get provider
    final expenseData = Provider.of<ExpenseData>(context, listen: false);

    dateTime = DateTime.now();

    // Build ExpenseItem with type and add through provider methods
    if (selectedIndex == TypeEI.expense) {
      final ExpenseItem newExpense = ExpenseItem(
        name: title?.toString() ?? 'Expense',
        dateTime: dateTime!,
        amount: enteredAmount.toString(),
        type: 'expense',
      );

      // Add expense (provider will normalize, persist and notify)
      expenseData.addExpense(newExpense);

      // Show confirmation
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          contentPadding: EdgeInsets.all(0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.check, size: 60, color: Colors.white)),
              const SizedBox(height: 20),
              const Text('Expense Submitted',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pop(context);
                  },
                  child: const Text('OK')),
            ],
          ),
        ),
      );
    } else {
      final ExpenseItem newIncome = ExpenseItem(
        name: title?.toString() ?? 'Income',
        dateTime: dateTime!,
        amount: enteredAmount.toString(),
        type: 'income',
      );

      // Add income via provider
      expenseData.addIncome(newIncome);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          contentPadding: EdgeInsets.all(0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check, size: 60, color: Colors.white)),
              const SizedBox(height: 20),
              const Text('Income Added',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pop(context);
                  },
                  child: const Text('OK')),
            ],
          ),
        ),
      );
    }

    // Clear fields after adding
    setState(() {
      _titleController.clear();
      _amountController.clear();
      title = null;
      amount = null;
      _value = null;
      // keep selectedIndex as-is so user can add multiple of same type quickly
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    avlC = hive.getCategory();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SegmentedButton<TypeEI>(
                selected: selectedAccessories,
                onSelectionChanged: (Set<TypeEI> newSelection) {
                  setState(() {
                    selectedAccessories = newSelection;
                    selectedIndex = newSelection.first;
                  });
                },
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                selectedIcon: const Icon(Icons.check_circle),
                segments: const <ButtonSegment<TypeEI>>[
                  ButtonSegment<TypeEI>(
                    value: TypeEI.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.upload_rounded),
                  ),
                  ButtonSegment<TypeEI>(
                    value: TypeEI.income,
                    label: Text('Income'),
                    icon: Icon(Icons.download),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), filled: true, labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    title = value;
                  });
                },
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  filled: true,
                  labelText: selectedIndex == TypeEI.expense ? 'Expense' : 'Income',
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    amount = double.tryParse(value);
                  });
                },
              ),
              const SizedBox(height: 10),
              Wrap(
                children: <Widget>[
                  const SizedBox(height: 10.0),
                  Wrap(
                    spacing: 3.0,
                    children: List<Widget>.generate(
                      avlC.length,
                      (int index) {
                        return ChoiceChip(
                          label: Text(avlC[index]),
                          labelStyle: TextStyle(
                              color: _value == index ? Colors.white : Colors.black),
                          selected: _value == index,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (bool selected) {
                            setState(() {
                              _value = selected ? index : null;
                            });
                          },
                          backgroundColor: Colors.blue.shade50,
                        );
                      },
                    ).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ButtonStyle(
                    alignment: Alignment.center,
                    side: MaterialStateProperty.all(
                      const BorderSide(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    'Add Transaction',
                    style: SafeGoogleFont(
                      'Encode Sans SC',
                      fontSize: 18,
                    ),
                    textScaleFactor: 1.1,
                    selectionColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
