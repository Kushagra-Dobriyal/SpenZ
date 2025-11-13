"""
Simple All-in-One ML Backend for SpenZ
Everything in one file - expense optimization + stock recommendations
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime
from collections import defaultdict

app = Flask(__name__)
CORS(app)

# Simple stock database
STOCKS = {
    'conservative': [
        {'symbol': 'RELIANCE', 'name': 'Reliance Industries', 'risk': 'Low', 'return': '8-12%'},
        {'symbol': 'TCS', 'name': 'Tata Consultancy Services', 'risk': 'Low', 'return': '10-15%'},
        {'symbol': 'HDFCBANK', 'name': 'HDFC Bank', 'risk': 'Low', 'return': '9-13%'},
    ],
    'moderate': [
        {'symbol': 'INFY', 'name': 'Infosys', 'risk': 'Medium', 'return': '12-18%'},
        {'symbol': 'ICICIBANK', 'name': 'ICICI Bank', 'risk': 'Medium', 'return': '15-20%'},
        {'symbol': 'BHARTIARTL', 'name': 'Bharti Airtel', 'risk': 'Medium', 'return': '14-19%'},
    ],
    'aggressive': [
        {'symbol': 'ZOMATO', 'name': 'Zomato', 'risk': 'High', 'return': '20-30%'},
        {'symbol': 'PAYTM', 'name': 'Paytm', 'risk': 'High', 'return': '18-25%'},
        {'symbol': 'TATAMOTORS', 'name': 'Tata Motors', 'risk': 'High', 'return': '15-22%'},
    ]
}

def analyze_expenses(transactions):
    """Simple expense analysis"""
    if not transactions:
        return {
            'total': 0,
            'avg': 0,
            'recommendations': ['Start tracking expenses to get insights!'],
            'top_category': None
        }
    
    # Calculate totals
    expenses = [float(tx.get('amount', 0)) for tx in transactions if tx.get('type') == 'expense']
    total = sum(expenses)
    avg = total / len(expenses) if expenses else 0
    
    # Category analysis
    categories = defaultdict(float)
    for tx in transactions:
        if tx.get('type') == 'expense':
            cat = tx.get('category', 'Miscellaneous')
            categories[cat] += float(tx.get('amount', 0))
    
    top_category = max(categories.items(), key=lambda x: x[1])[0] if categories else None
    top_amount = categories[top_category] if top_category else 0
    
    # Generate simple recommendations
    recommendations = []
    if top_category and top_amount > total * 0.3:
        recommendations.append(f"Reduce spending in {top_category} - it's {top_amount/total*100:.1f}% of expenses")
    
    if avg > 1000:
        recommendations.append(f"Your average expense is ₹{avg:.0f}. Try to reduce by 15% to save ₹{avg*0.15:.0f} per transaction")
    
    if total > 50000:
        recommendations.append(f"Total expenses: ₹{total:.0f}. Consider setting a monthly budget")
    
    return {
        'total': total,
        'avg': avg,
        'count': len(expenses),
        'recommendations': recommendations,
        'top_category': top_category,
        'potential_savings': avg * 0.15 * len(expenses) if expenses else 0
    }

def get_stocks(balance, monthly_income):
    """Simple stock recommendations"""
    # Determine risk
    if balance < 10000 or monthly_income < 20000:
        risk = 'conservative'
    elif balance < 100000:
        risk = 'moderate'
    else:
        risk = 'aggressive'
    
    # Calculate investment amount
    invest = min(balance * 0.1, monthly_income * 0.2)
    invest = max(1000, invest)  # Minimum ₹1000
    
    return {
        'risk': risk,
        'investment': invest,
        'stocks': STOCKS[risk][:3],
        'advice': [
            f"Invest ₹{invest:.0f} in {risk} risk stocks",
            "Start with SIP (Systematic Investment Plan)",
            "Diversify across 3-5 stocks"
        ]
    }

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok'})

@app.route('/api/analyze', methods=['POST'])
def analyze():
    """Single endpoint for expense analysis"""
    try:
        data = request.json
        transactions = data.get('transactions', [])
        analysis = analyze_expenses(transactions)
        return jsonify({'success': True, 'data': analysis})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/stocks', methods=['POST'])
def stocks():
    """Single endpoint for stock recommendations"""
    try:
        data = request.json
        balance = float(data.get('balance', 0))
        monthly_income = float(data.get('monthly_income', 0))
        result = get_stocks(balance, monthly_income)
        return jsonify({'success': True, 'data': result})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/all', methods=['POST'])
def all_insights():
    """Get both expense analysis and stock recommendations"""
    try:
        data = request.json
        transactions = data.get('transactions', [])
        balance = float(data.get('balance', 0))
        monthly_income = float(data.get('monthly_income', balance / 12))
        
        expense_analysis = analyze_expenses(transactions)
        stock_recommendations = get_stocks(balance, monthly_income)
        
        return jsonify({
            'success': True,
            'expenses': expense_analysis,
            'stocks': stock_recommendations
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

if __name__ == '__main__':
    print("🚀 Starting Simple ML Backend...")
    print("📊 Endpoints:")
    print("   POST /api/analyze - Expense analysis")
    print("   POST /api/stocks - Stock recommendations")
    print("   POST /api/all - Both insights")
    app.run(host='0.0.0.0', port=5000, debug=True)

