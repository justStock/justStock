import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/market_service.dart';
import '../advice/advice_page.dart';

class MarketDetailPage extends StatefulWidget {
  static const routeName = '/market-detail';
  const MarketDetailPage({super.key});

  @override
  State<MarketDetailPage> createState() => _MarketDetailPageState();
}

class _MarketDetailPageState extends State<MarketDetailPage> {
  final MarketService _service = MarketService();
  late String _title;
  late String _exchange;
  late String _symbol;
  late Future<ChartData> _future;
  StreamSubscription<Quote>? _sub;
  List<double> _closes = const [];
  double? _livePrice;
  double? _liveChange;
  double? _livePct;
  Quote? _quote; // richer quote for OHLC + stats

  String _range = '1D';
  static const _rangeMap = {
    '1D': ('1d', '1m'),
    '1W': ('5d', '15m'),
    '1M': ('1mo', '1d'),
    '3M': ('3mo', '1d'),
    '6M': ('6mo', '1d'),
    '1Y': ('1y', '1d'),
    '5Y': ('5y', '1wk'),
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = (ModalRoute.of(context)?.settings.arguments ?? {}) as Map;
    _title = (args['title'] as String?) ?? 'Instrument';
    _exchange = (args['exchange'] as String?) ?? '';
    _symbol = (args['symbol'] as String?) ?? '';
    final ri = _rangeMap[_range]!;
    _future = _service.fetchChart(_symbol, range: ri.$1, interval: ri.$2);
    _loadQuote();
    _sub?.cancel();
    _sub = _service.quoteStream(_symbol).listen((q) {
      if (!mounted) return;
      setState(() {
        _livePrice = q.price;
        _liveChange = q.change;
        _livePct = q.changePct;
        _quote = q;
        // Seed sparkline even if initial chart failed; then keep a rolling window
        final list = _closes.isEmpty
            ? <double>[q.price]
            : (List<double>.from(_closes)..add(q.price));
        if (list.length > 240) list.removeAt(0);
        _closes = list;
      });
    });
  }

  Future<void> _loadQuote() async {
    try {
      final q = await _service.fetchQuote(_symbol);
      if (!mounted) return;
      setState(() => _quote = q);
    } catch (_) {}
  }

  void _changeRange(String r) {
    if (!_rangeMap.containsKey(r)) return;
    setState(() {
      _range = r;
      final ri = _rangeMap[_range]!;
      _future = _service.fetchChart(_symbol, range: ri.$1, interval: ri.$2);
      _closes = const [];
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: FutureBuilder<ChartData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Failed to load data'),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: () => setState(() {}), child: const Text('Retry')),
                ],
              ),
            );
          }
          final data = snap.data!;
          _closes = _closes.isEmpty ? List<double>.from(data.closes) : _closes;
          final last = _livePrice ?? data.last;
          final ch = _liveChange ?? data.change;
          final pct = _livePct ?? data.changePct;

          final upColor = ch >= 0 ? cs.primary : Colors.red;
          final q = _quote;
          final open = q?.open ?? data.open;
          final high = q?.dayHigh ?? data.dayHigh;
          final low = q?.dayLow ?? data.dayLow;
          final prevClose = q?.previousClose ?? data.previousClose;

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 720;
              final body = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
                        child: Text(_exchange, style: TextStyle(color: cs.onPrimaryContainer)),
                      ),
                      const SizedBox(width: 12),
                      Text(_symbol, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('₹${last.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: upColor.withOpacity(0.12), borderRadius: BorderRadius.circular(24)),
                        child: Text('${ch >= 0 ? '+' : ''}${ch.toStringAsFixed(2)} (${pct.toStringAsFixed(2)}%)',
                            style: TextStyle(color: upColor, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // OHLC band
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _kv('OPEN', open),
                          _kv('HIGH', high),
                          _kv('LOW', low),
                          _kv('CLOSE', prevClose != null ? prevClose + ch : last),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Chart card
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        border: Border.all(color: cs.outlineVariant),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: Column(
                          children: [
                            Expanded(child: _BigSparkline(data: _closes, color: upColor)),
                            const SizedBox(height: 8),
                            _rangeSelector(cs),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Stats grid and actions
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _statsGrid(cs, q, prevClose)),
                        const SizedBox(width: 12),
                        Expanded(child: _topicsAndActions(cs)),
                      ],
                    )
                  else ...[
                    _statsGrid(cs, q, prevClose),
                    const SizedBox(height: 12),
                    _topicsAndActions(cs),
                  ],
                ],
              );

              return Padding(padding: const EdgeInsets.all(16), child: body);
            },
          );
        },
      ),
    );
  }

  Widget _rangeSelector(ColorScheme cs) {
    final items = _rangeMap.keys.toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final r in items) ...[
            ChoiceChip(
              label: Text(r),
              selected: _range == r,
              onSelected: (_) => _changeRange(r),
              selectedColor: cs.primaryContainer,
              labelStyle: TextStyle(color: _range == r ? cs.onPrimaryContainer : null),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, double? v) {
    final s = v == null ? '--' : '₹${v.toStringAsFixed(2)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(s, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _statsGrid(ColorScheme cs, Quote? q, double? prevClose) {
    final items = <(String, String)>[
      ('Prev Close', prevClose == null ? '--' : '₹${prevClose.toStringAsFixed(2)}'),
      ('Open', q?.open == null ? '--' : '₹${q!.open!.toStringAsFixed(2)}'),
      ('52W High', q?.fiftyTwoWeekHigh == null ? '--' : '₹${q!.fiftyTwoWeekHigh!.toStringAsFixed(2)}'),
      ('52W Low', q?.fiftyTwoWeekLow == null ? '--' : '₹${q!.fiftyTwoWeekLow!.toStringAsFixed(2)}'),
      ('Volume', q?.volume == null ? '--' : _fmtInt(q!.volume!)),
      ('Mkt Cap', q?.marketCap == null ? '--' : _fmtNumber(q!.marketCap!)),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 480 ? 3 : 2;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: cols,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 3.2,
        children: [
          for (final it in items)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it.$1, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(it.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      );
    });
  }

  String _fmtInt(int v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)} L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(2)} K';
    return '$v';
  }

  String _fmtNumber(double v) {
    if (v >= 1e12) return '${(v / 1e12).toStringAsFixed(2)} T';
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(2)} B';
    if (v >= 1e7) return '${(v / 1e7).toStringAsFixed(2)} Cr';
    if (v >= 1e5) return '${(v / 1e5).toStringAsFixed(2)} L';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(2)} K';
    return v.toStringAsFixed(2);
  }

  Widget _topicsAndActions(ColorScheme cs) {
    final topics = ['Derivatives', 'Banking', 'IT', 'Auto', 'Energy', 'Midcap', 'Smallcap', 'FII/DII flows'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Related Topics', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final t in topics) Chip(label: Text(t))],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.shopping_bag),
                label: const Text('Buy'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(AdvicePage.routeName, arguments: const AdviceArgs(category: 'nifty'));
                },
                icon: const Icon(Icons.lightbulb),
                label: const Text('Strategies'),
              ),
            ),
          ],
        )
      ],
    );
  }
}

class _BigSparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  const _BigSparkline({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BigSparkPainter(data: data, color: color),
      size: Size.infinite,
    );
  }
}

class _BigSparkPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _BigSparkPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final minV = data.reduce((a, b) => a < b ? a : b);
    final maxV = data.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).clamp(0.0001, double.infinity);
    final dx = data.length > 1 ? size.width / (data.length - 1) : 0.0;

    // grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;
    const gridCount = 4;
    for (var i = 0; i <= gridCount; i++) {
      final y = size.height * (i / gridCount);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = i * dx;
      final y = size.height - ((data[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.25), color.withOpacity(0.05)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fill, fillPaint);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = color;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _BigSparkPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}
