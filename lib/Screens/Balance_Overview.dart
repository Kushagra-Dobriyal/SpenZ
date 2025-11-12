// lib/Screens/Balance_Overview.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../API/Number_Fact.dart';
import '../Design/FrostedGlass.dart';
import '../Data/Expense_data.dart';

class BalanceOverview extends StatefulWidget {
  const BalanceOverview({Key? key}) : super(key: key);

  @override
  _BalanceOverviewState createState() => _BalanceOverviewState();
}

class _BalanceOverviewState extends State<BalanceOverview>
    with SingleTickerProviderStateMixin {
  String fact = 'Loading...';
  bool factLoading = true;
  int _lastTriviaForBalance = -1;
  late AnimationController _anim;
  final Duration animDur = const Duration(milliseconds: 900);

  OverlayEntry? _tooltipEntry;
  Timer? _tooltipTimer;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: animDur);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _removeTooltip();
    super.dispose();
  }

  Future<void> _loadFactFor(int number) async {
    setState(() {
      factLoading = true;
      fact = 'Loading...';
    });
    try {
      final v = await fetchNumberFact('trivia', number.toString());
      if (!mounted) return;
      setState(() {
        fact = v;
        factLoading = false;
        _lastTriviaForBalance = number;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        fact = 'Could not load trivia. Tap to retry.';
        factLoading = false;
        _lastTriviaForBalance = number;
      });
    }
  }

  Future<void> _refreshAll(int balance) async {
    _anim.forward(from: 0.0);
    await _loadFactFor(balance);
  }

  Color _colorForValue(double v) {
    if (v <= 0.5) {
      final t = (v / 0.5).clamp(0.0, 1.0);
      return Color.lerp(Colors.redAccent, Colors.amber, t)!;
    } else {
      final t = ((v - 0.5) / 0.5).clamp(0.0, 1.0);
      return Color.lerp(Colors.amber, Colors.greenAccent, t)!;
    }
  }

  double _percentile(List<double> xs, double p) {
    if (xs.isEmpty) return 0.0;
    final sorted = [...xs]..sort();
    final idx = (p * (sorted.length - 1)).clamp(0, sorted.length - 1).toDouble();
    final lo = idx.floor();
    final hi = idx.ceil();
    if (lo == hi) return sorted[lo];
    final t = idx - lo;
    return sorted[lo] * (1 - t) + sorted[hi] * t;
  }

  void _removeTooltip() {
    _tooltipTimer?.cancel();
    _tooltipTimer = null;
    _tooltipEntry?.remove();
    _tooltipEntry = null;
  }

  void _showBarTooltip({
    required BuildContext context,
    required Offset globalTap,
    required int index,
    required double amount,
  }) {
    _removeTooltip(); // remove any existing

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    // Convert global position to overlay/local coordinates
    final renderBox = context.findRenderObject() as RenderBox?;
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final overlayOffset = overlayBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final localPos = globalTap - overlayOffset;

    final String weekday = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][index % 7];
    final text = '$weekday • ₹${amount.toStringAsFixed(0)}';

    final entry = OverlayEntry(
      builder: (context) {
        // Position the tooltip slightly above the tapped point, clamp to screen
        final screenSize = MediaQuery.of(context).size;
        final dx = localPos.dx.clamp(16.0, screenSize.width - 200.0);
        final dy = (localPos.dy - 72).clamp(64.0, screenSize.height - 160.0);
        return Positioned(
          left: dx,
          top: dy,
          child: Material(
            color: Colors.transparent,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: 1.0,
              child: Container(
                constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: Offset(0,6))
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                  // glowing ring
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.06)]),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Icon(Icons.calendar_today, size: 18, color: Colors.white.withOpacity(0.95)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Tap to dismiss', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    _tooltipEntry = entry;

    // auto-dismiss
    _tooltipTimer = Timer(const Duration(milliseconds: 2500), () {
      _removeTooltip();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardWidth = MediaQuery.of(context).size.width * 0.92;

    return Consumer<ExpenseData>(builder: (context, provider, child) {
      final displayBalance = provider.getBalance();
      final balanceInt = displayBalance.toInt();

      List<double> weekValues;
      try {
        weekValues = provider.weeklyAmounts(typeFilter: 'expense');
      } catch (_) {
        weekValues = List<double>.filled(7, 0.0);
      }
      if (weekValues.length != 7) {
        final tmp = List<double>.filled(7, 0.0);
        for (int i = 0; i < min(weekValues.length, 7); i++) tmp[i] = weekValues[i];
        weekValues = tmp;
      }

      final totalWeekSpend = weekValues.reduce((a, b) => a + b);
      final avgWeekly = weekValues.isNotEmpty ? totalWeekSpend / weekValues.length : 0.0;
      double ratio = (displayBalance / (totalWeekSpend + 1)).clamp(0.0, 5.0);
      final savingsScore = (ratio / 2.0).clamp(0.0, 1.0);

      String aiInsight;
      if (savingsScore > 0.8) {
        aiInsight =
            "Amazing! Your savings are strong — balance greatly exceeds recent spending.";
      } else if (savingsScore > 0.55) {
        aiInsight =
            "You're doing okay. Small reductions in variable expenses can boost your savings quickly.";
      } else {
        aiInsight =
            "Your spending is catching up to your balance. Try saving a bit more this week.";
      }
      final trend = weekValues.last - weekValues.first;
      final suggestion = (trend > avgWeekly * 0.2)
          ? "⚠️ Spending is trending up — consider tracking small daily expenses."
          : (trend < -avgWeekly * 0.1)
              ? "✅ Spending trending down — good job!"
              : "💡 Steady habits build savings.\nSmall changes multiply over time.";
      aiInsight = "$aiInsight\n\n$suggestion";

      if (_lastTriviaForBalance != balanceInt) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_lastTriviaForBalance != balanceInt) _loadFactFor(balanceInt);
        });
      }

      final low = weekValues.reduce(min);
      final avg = weekValues.isNotEmpty ? weekValues.reduce((a, b) => a + b) / weekValues.length : 0.0;
      final p95 = _percentile(weekValues, 0.95);
      final displayMax = max(p95, weekValues.reduce(max) * 0.6);

      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.navigate_before_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: const Text('Balance Overview'),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/Balance_Overview_Background.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 18.0),
            child: Column(
              children: [
                FrostedGlassBox(
                  theWidth: cardWidth,
                  theHeight: 110,
                  theChild: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Balance Left', style: TextStyle(color: Colors.white70)),
                              const SizedBox(height: 6),
                              Text('₹${displayBalance.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28)),
                              const SizedBox(height: 6),
                              Text('Updated just now', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: SizedBox(
                          width: 88,
                          height: 88,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: savingsScore),
                            duration: animDur,
                            curve: Curves.easeOut,
                            builder: (context, animatedValue, child) {
                              final color = _colorForValue(animatedValue);
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 88,
                                    height: 88,
                                    child: CircularProgressIndicator(
                                      value: animatedValue,
                                      strokeWidth: 8,
                                      backgroundColor: Colors.white12,
                                      valueColor: AlwaysStoppedAnimation<Color>(color),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${(animatedValue * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      Text('Health', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11)),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // --- Interactive Bar Chart: GestureDetector wraps CustomPaint and handles taps ---
                FrostedGlassBox(
                  theWidth: cardWidth,
                  theHeight: 220,
                  theChild: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.bar_chart, color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            const Text('Last 7 days', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text('Expenses only', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // interactive area
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: LayoutBuilder(builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final n = weekValues.length;
                            final barSpacing = w * 0.06;
                            final totalSpacing = barSpacing * (n + 1);
                            final barWidth = (w - totalSpacing) / n;

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (details) {
                                final local = details.localPosition;
                                // compute index by x
                                final dx = local.dx;
                                for (int i = 0; i < n; i++) {
                                  final x = barSpacing + i * (barWidth + barSpacing);
                                  final rect = Rect.fromLTWH(x, 0, barWidth, constraints.maxHeight);
                                  if (rect.contains(Offset(dx, local.dy))) {
                                    final tappedAmount = weekValues[i];
                                    final globalPos = details.globalPosition;
                                    _showBarTooltip(context: context, globalTap: globalPos, index: i, amount: tappedAmount);
                                    return;
                                  }
                                }
                                // if tapped outside bar -> remove tooltip
                                _removeTooltip();
                              },
                              onTap: () => _removeTooltip(),
                              child: CustomPaint(
                                painter: _BarsPainter(weekValues, displayMax, theme.colorScheme.primary),
                                child: Container(),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Low: ₹${low.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70)),
                            Text('Avg: ₹${avg.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70)),
                            Text('High (p95): ₹${p95.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                FrostedGlassBox(
                  theWidth: cardWidth,
                  theHeight: 140,
                  theChild: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(left: 10),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [_colorForValue(savingsScore), Colors.blueAccent.withOpacity(0.7)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: _colorForValue(savingsScore).withOpacity(0.25), blurRadius: 8)],
                        ),
                        child: const Icon(Icons.smart_toy, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('AI Insight', style: TextStyle(color: Colors.white70)),
                              const SizedBox(height: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Text(aiInsight, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                GestureDetector(
                  onTap: () => _loadFactFor(balanceInt),
                  child: FrostedGlassBox(
                    theWidth: cardWidth,
                    theHeight: 120,
                    theChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Number Trivia', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: factLoading
                                  ? const Text('Loading...', style: TextStyle(color: Colors.white70))
                                  : Text(fact, style: TextStyle(color: Colors.white.withOpacity(0.9)), textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Tap trivia to retry', style: TextStyle(color: Colors.white.withOpacity(0.22), fontSize: 11)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _refreshAll(balanceInt),
          backgroundColor: Colors.purpleAccent,
          child: const Icon(Icons.refresh),
        ),
      );
    });
  }
}

/// Painter: draws 7 vertical rounded bars. If a bar exceeds displayMax, it's clipped and shows an ▲ marker.
class _BarsPainter extends CustomPainter {
  final List<double> values; // length 7
  final double displayMax; // max used for scaling (p95-based)
  final Color color;
  _BarsPainter(this.values, this.displayMax, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final n = values.length;
    if (n == 0) return;
    final barSpacing = w * 0.06;
    final totalSpacing = barSpacing * (n + 1);
    final barWidth = (w - totalSpacing) / n;
    final paint = Paint()..style = PaintingStyle.fill;

    // faint baseline grid
    for (int i = 1; i <= 3; i++) {
      final y = h * i / 4;
      canvas.drawLine(Offset(0, y), Offset(w, y), Paint()..color = Colors.white.withOpacity(0.03));
    }

    for (int i = 0; i < n; i++) {
      final v = values[i];
      final clipped = v > displayMax;
      final scaled = ((clipped ? displayMax : v) / (displayMax == 0 ? 1 : displayMax)).clamp(0.0, 1.0);
      final barH = scaled * h;
      final x = barSpacing + i * (barWidth + barSpacing);
      final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(x, h - barH, barWidth, barH), Radius.circular(barWidth * 0.25));
      final grad = LinearGradient(colors: [color.withOpacity(0.95), color.withOpacity(0.55)]);
      paint.shader = grad.createShader(Rect.fromLTWH(x, h - barH, barWidth, barH));
      canvas.drawRRect(rrect, paint);

      // subtle top glow
      canvas.drawRRect(rrect.deflate(2), Paint()..color = Colors.white.withOpacity(0.02));

      // small dot at top
      canvas.drawCircle(Offset(x + barWidth / 2, h - barH - 6), 3, Paint()..color = Colors.white.withOpacity(0.9));

      // clip marker
      if (clipped) {
        final triangle = Path();
        final tx = x + barWidth / 2;
        final ty = h - barH - 14;
        triangle.moveTo(tx - 6, ty + 6);
        triangle.lineTo(tx + 6, ty + 6);
        triangle.lineTo(tx, ty);
        triangle.close();
        canvas.drawPath(triangle, Paint()..color = Colors.white.withOpacity(0.9));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) {
    return old.values != values || old.color != color || old.displayMax != displayMax;
  }
}
