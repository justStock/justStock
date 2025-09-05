import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../wallet/wallet_page.dart';
import '../advice/advice_page.dart';
import '../../services/market_service.dart';
import '../../services/profile_service.dart';

class HomeArgs {
  final String name;
  const HomeArgs({required this.name});
}

class HomePage extends StatefulWidget {
  static const routeName = '/home';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String userName;
  String _productTab = 'stocks';
  String _region = 'indian';
  int _bottomIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    userName = (args is HomeArgs && args.name.trim().isNotEmpty)
        ? args.name.trim()
        : 'Trader';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: _buildTopBar(context, cs),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSegmentedTabs(cs)),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(child: _sectionHeader('Indices', trailing: 'View all')),
          SliverToBoxAdapter(child: _buildRegionChips(cs)),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(child: _buildIndicesCarousel(cs)),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(child: _sectionHeader('Commodities', trailing: 'View all')),
          SliverToBoxAdapter(child: _buildCommoditiesCarousel(cs)),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(child: _sectionHeader('Stocks', trailing: 'View all')),
          SliverToBoxAdapter(child: _buildStocksCarousel(cs)),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(child: _promoCard(cs)),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(child: _quickActions(cs)),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(child: _sectionHeader('Market movers')),
            SliverToBoxAdapter(child: _moversChips(cs)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _moverTile(i, cs),
                childCount: 6,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomIndex,
        onDestinationSelected: (i) {
          if (i == 4) {
            Navigator.of(context).pushNamed(
              WalletPage.routeName,
              arguments: WalletArgs(name: userName),
            );
            return;
          }
          setState(() => _bottomIndex = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.show_chart_outlined), selectedIcon: Icon(Icons.show_chart), label: 'Market'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Portfolio'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.notifications_none), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTopBar(BuildContext context, ColorScheme cs) {
    final trimmed = userName.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : 'U';
    return AppBar(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 12,
      leadingWidth: 52,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pushNamed(WalletPage.routeName, arguments: WalletArgs(name: userName)),
          child: ValueListenableBuilder<String?>(
            valueListenable: ProfileService.instance.imagePath,
            builder: (context, path, _) {
              if (path != null && File(path).existsSync()) {
                return CircleAvatar(
                  backgroundColor: cs.onPrimary.withOpacity(0.15),
                  foregroundImage: FileImage(File(path)),
                );
              }
              return CircleAvatar(
                backgroundColor: cs.onPrimary.withOpacity(0.15),
                foregroundColor: cs.onPrimary,
                child: Text(initial),
              );
            },
          ),
        ),
      ),
      title: const Text('Market'),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: const StadiumBorder(),
              backgroundColor: cs.onPrimary,
              foregroundColor: cs.primary,
            ),
            onPressed: () {},
            child: const Text('Buy PRO'),
          ),
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.headset_mic_outlined, color: Colors.white)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: Colors.white)),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildSegmentedTabs(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'stocks', label: Text('Stocks')),
          ButtonSegment(value: 'fno', label: Text('Futures & Options')),
        ],
        selected: {_productTab},
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.comfortable,
          side: MaterialStatePropertyAll(BorderSide(color: cs.outlineVariant)),
        ),
        onSelectionChanged: (s) => setState(() => _productTab = s.first),
      ),
    );
  }

  Widget _sectionHeader(String title, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
          if (trailing != null)
            TextButton(onPressed: () {}, child: Text(trailing)),
        ],
      ),
    );
  }

  Widget _buildRegionChips(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _choiceChip('Indian', 'indian', cs),
          const SizedBox(width: 8),
          _choiceChip('Global', 'global', cs),
        ],
      ),
    );
  }

  Widget _choiceChip(String label, String value, ColorScheme cs) {
    final selected = _region == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _region = value),
      selectedColor: cs.primaryContainer,
      labelStyle: TextStyle(color: selected ? cs.onPrimaryContainer : null),
    );
  }

  Widget _buildIndicesCarousel(ColorScheme cs) {
    final items = const [
      _IndexItem('NIFTY 50', 'NSE', '^NSEI'),
      _IndexItem('SENSEX', 'BSE', '^BSESN'),
      _IndexItem('BANK NIFTY', 'NSE', '^NSEBANK'),
    ];
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) {
          final item = items[i];
          return _LiveIndexCard(title: item.title, exchange: item.ex, symbol: item.symbol, cs: cs);
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: items.length,
      ),
    );
  }

  Widget _buildCommoditiesCarousel(ColorScheme cs) {
    final items = const [
      _IndexItem('Gold', 'COMEX', 'GC=F'),
      _IndexItem('Crude Oil', 'NYMEX', 'CL=F'),
    ];
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) {
          final item = items[i];
          return _LiveIndexCard(title: item.title, exchange: item.ex, symbol: item.symbol, cs: cs);
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: items.length,
      ),
    );
  }

  Widget _buildStocksCarousel(ColorScheme cs) {
    // Common Indian large-cap symbols on NSE (Yahoo suffix .NS)
    final items = const [
      _IndexItem('RELIANCE', 'NSE', 'RELIANCE.NS'),
      _IndexItem('TCS', 'NSE', 'TCS.NS'),
      _IndexItem('INFY', 'NSE', 'INFY.NS'),
      _IndexItem('HDFCBANK', 'NSE', 'HDFCBANK.NS'),
      _IndexItem('ITC', 'NSE', 'ITC.NS'),
      _IndexItem('LT', 'NSE', 'LT.NS'),
    ];
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) {
          final item = items[i];
          return _LiveIndexCard(title: item.title, exchange: item.ex, symbol: item.symbol, cs: cs);
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: items.length,
      ),
    );
  }

  Widget _promoCard(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('UNIVEST DEMAT', style: TextStyle(color: cs.onPrimary.withOpacity(0.9))),
                  const SizedBox(height: 6),
                  Text('Smart Research Smarter Trades',
                      style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: cs.onPrimary,
                foregroundColor: cs.primary,
                shape: const StadiumBorder(),
              ),
              onPressed: () {},
              child: const Text('Get 25 FREE trades →'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(ColorScheme cs) {
    final items = [
      (Icons.trending_up, 'Nifty', 'nifty'),
      (Icons.account_balance, 'BankNifty', 'banknifty'),
      (Icons.stacked_line_chart, 'Sensex', 'sensex'),
      (Icons.show_chart, 'Stock', 'stock'),
      (Icons.inventory_2_outlined, 'Commodity', 'commodity'),
    ];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final tuple = items[i];
          final icon = tuple.$1 as IconData;
          final label = tuple.$2 as String;
          final category = tuple.$3 as String;
          return InkWell(
            onTap: () {
              Navigator.of(context).pushNamed(
                '/advice',
                arguments: AdviceArgs(category: category),
              );
            },
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Icon(icon, color: cs.primary),
                ),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _moversChips(ColorScheme cs) {
    final labels = ['Top gainers', 'Top losers', '52 wk high', '52 wk low'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          for (final l in labels)
            FilterChip(
              label: Text(l),
              onSelected: (_) {},
            )
        ],
      ),
    );
  }

  Widget _moverTile(int i, ColorScheme cs) {
    final green = cs.primary;
    final names = ['RELIANCE', 'TCS', 'INFY', 'HDFCBANK', 'ITC', 'LT'];
    final change = (i.isEven ? 1 : -1) * (0.5 + (i % 3) * 0.3);
    final price = 1000 + i * 50 + (change * 3);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(backgroundColor: cs.primaryContainer, child: Text(names[i][0])),
      title: Text(names[i]),
      subtitle: Text('\u20B9${price.toStringAsFixed(2)}'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: change >= 0 ? green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
          style: TextStyle(color: change >= 0 ? green : Colors.red),
        ),
      ),
    );
  }
}

class _LiveIndexCard extends StatefulWidget {
  final String title;
  final String exchange;
  final String symbol;
  final ColorScheme cs;
  const _LiveIndexCard({required this.title, required this.exchange, required this.symbol, required this.cs});

  @override
  State<_LiveIndexCard> createState() => _LiveIndexCardState();
}

class _LiveIndexCardState extends State<_LiveIndexCard> {
  final _service = MarketService();
  late Future<ChartData> _future;
  Timer? _timer; // minute refresh
  StreamSubscription<Quote>? _sub; // live quotes
  List<double> _closes = const [];
  double? _livePrice;
  double? _liveChange;
  double? _livePct;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchChart(widget.symbol);
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _refresh());
    _sub = _service.quoteStream(widget.symbol).listen((q) {
      if (!mounted) return;
      setState(() {
        _livePrice = q.price;
        _liveChange = q.change;
        _livePct = q.changePct;
        if (_closes.isNotEmpty) {
          final list = List<double>.from(_closes)..add(q.price);
          if (list.length > 60) list.removeAt(0);
          _closes = list;
        }
      });
    });
  }

  Future<void> _refresh() async {
    final data = await _service.fetchChart(widget.symbol);
    if (!mounted) return;
    setState(() {
      _future = Future.value(data);
      _closes = data.closes;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: FutureBuilder<ChartData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _titleRow(cs),
                const SizedBox(height: 12),
                const Text('Failed to load'),
                const SizedBox(height: 8),
                TextButton(onPressed: _refresh, child: const Text('Retry')),
              ],
            );
          }
          final data = snap.data!;
          _closes = _closes.isEmpty ? List<double>.from(data.closes) : _closes;
          final green = cs.primary;
          final last = _livePrice ?? data.last;
          final ch = _liveChange ?? data.change;
          final pct = _livePct ?? data.changePct;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titleRow(cs),
              const SizedBox(height: 6),
              SizedBox(height: 56, child: _Sparkline(data: _closes, color: green)),
              const SizedBox(height: 8),
              Text(last.toStringAsFixed(2), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                '${ch >= 0 ? '+' : ''}${ch.toStringAsFixed(2)} (${pct.toStringAsFixed(2)}%)',
                style: TextStyle(color: ch >= 0 ? green : Colors.red),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _titleRow(ColorScheme cs) {
    return Row(
      children: [
        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(widget.exchange, style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer)),
        ),
      ],
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  const _Sparkline({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparkPainter(data: data, color: color),
      size: Size.infinite,
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _SparkPainter({required this.data, required this.color});

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
      ..strokeWidth = 2
      ..color = color;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}

class _IndexItem {
  final String title;
  final String ex;
  final String symbol;
  const _IndexItem(this.title, this.ex, this.symbol);
}
