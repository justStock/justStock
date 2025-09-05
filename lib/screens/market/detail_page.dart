import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/market_service.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = (ModalRoute.of(context)?.settings.arguments ?? {}) as Map;
    _title = (args['title'] as String?) ?? 'Instrument';
    _exchange = (args['exchange'] as String?) ?? '';
    _symbol = (args['symbol'] as String?) ?? '';
    _future = _service.fetchChart(_symbol, range: '1d', interval: '1m');
    _sub?.cancel();
    _sub = _service.quoteStream(_symbol).listen((q) {
      if (!mounted) return;
      setState(() {
        _livePrice = q.price;
        _liveChange = q.change;
        _livePct = q.changePct;
        if (_closes.isNotEmpty) {
          final list = List<double>.from(_closes)..add(q.price);
          if (list.length > 240) list.removeAt(0);
          _closes = list;
        }
      });
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

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
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
                    Text(
                      '₹${last.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${ch >= 0 ? '+' : ''}${ch.toStringAsFixed(2)} (${pct.toStringAsFixed(2)}%)',
                      style: TextStyle(color: ch >= 0 ? cs.primary : Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border.all(color: cs.outlineVariant),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: _BigSparkline(data: _closes, color: ch >= 0 ? cs.primary : Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
    final dx = size.width / (data.length - 1);

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
      ..color = color.withOpacity(0.12);
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

