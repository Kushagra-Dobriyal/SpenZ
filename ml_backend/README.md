# Simple ML Backend for SpenZ

One file, super simple ML backend for expense optimization and stock recommendations.

## Quick Setup

1. **Install dependencies:**
```bash
pip install -r requirements.txt
```

2. **Run the server:**
```bash
python ml_server.py
```

Server runs on `http://localhost:5000`

## API Endpoints

### 1. Get All Insights (Recommended)
**POST** `/api/all`
```json
{
  "transactions": [...],
  "balance": 50000,
  "monthly_income": 30000
}
```

### 2. Expense Analysis Only
**POST** `/api/analyze`
```json
{
  "transactions": [...]
}
```

### 3. Stock Recommendations Only
**POST** `/api/stocks`
```json
{
  "balance": 50000,
  "monthly_income": 30000
}
```

## Flutter Integration

Use `MLService` from `lib/ML/ml_service.dart`:

```dart
final result = await MLService.getAllInsights(transactions, balance);
```

**Update URL in `ml_service.dart`:**
- Android Emulator: `http://10.0.2.2:5000`
- Physical Device: `http://YOUR_COMPUTER_IP:5000`

## That's It! 🚀

One file, simple, works!

