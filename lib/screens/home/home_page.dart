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
            SliverToBoxAdapter(child: _quickActions(cs)),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(child: _promoCard(cs)),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(child: _sectionHeader('Market movers')),
            SliverToBoxAdapter(child: _MarketMovers(cs: cs)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomIndex,
        onDestinationSelected: (i) {
          if (i == 1) {
            // Redirecting button to Stocks page
            Navigator.of(context).pushNamed(AdvicePage.routeName, arguments: const AdviceArgs(category: 'stock'));
            return;
          }
          if (i == 2) {
            Navigator.of(context).pushNamed(
              WalletPage.routeName,
              arguments: WalletArgs(name: userName),
            );
            return;
          }
          setState(() => _bottomIndex = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.show_chart_outlined), selectedIcon: Icon(Icons.show_chart), label: 'Stocks'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
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
      title: _brandLogo(cs),
      actions: [
        IconButton(
          onPressed: _openSearch,
          icon: const Icon(Icons.search, color: Colors.white),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // JustStock logo: gradient circle + wordmark
  Widget _brandLogo(ColorScheme cs) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'lib/logo.png',
        height: 98,
        fit: BoxFit.contain,
      ),
    );
  }

  void _openSearch() {
    showSearch(context: context, delegate: _SymbolSearchDelegate());
  }

  Widget _buildSegmentedTabs(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Center(
        child: IntrinsicWidth(
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
        ),
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
    final items = _region == 'global'
        ? const [
            _IndexItem('S&P 500', 'NYSE', '^GSPC'),
            _IndexItem('Dow Jones', 'NYSE', '^DJI'),
            _IndexItem('NASDAQ', 'NASDAQ', '^IXIC'),
          ]
        : const [
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
          return GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(
                '/market-detail',
                arguments: {
                  'title': item.title,
                  'exchange': item.ex,
                  'symbol': item.symbol,
                },
              );
            },
            child: _LiveIndexCard(title: item.title, exchange: item.ex, symbol: item.symbol, cs: cs),
          );
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
          return GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(
                '/market-detail',
                arguments: {
                  'title': item.title,
                  'exchange': item.ex,
                  'symbol': item.symbol,
                },
              );
            },
            child: _LiveIndexCard(title: item.title, exchange: item.ex, symbol: item.symbol, cs: cs),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: items.length,
      ),
    );
  }

  Widget _buildStocksCarousel(ColorScheme cs) {
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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF17A589), Color(0xFF0E6655)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Left: Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Buy CALL at \u20B9100',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Earn up to \u20B92000',
                    style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: cs.primary,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AdvicePage.routeName,
                        arguments: const AdviceArgs(category: 'nifty'),
                      );
                    },
                    child: const Text('Explore Calls'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right: Decorative image area (icon-based placeholder)
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.trending_up, color: Colors.white, size: 42),
              ),
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
                AdvicePage.routeName,
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
    // replaced by live movers widget
    return const SizedBox.shrink();
  }
}

class _MarketMovers extends StatefulWidget {
  final ColorScheme cs;
  const _MarketMovers({required this.cs});

  @override
  State<_MarketMovers> createState() => _MarketMoversState();
}

class _MarketMoversState extends State<_MarketMovers> {
  final MarketService _service = MarketService();
  final _symbols = const [
    // Popular NSE large/mid caps; append .NS suffix
    'RELIANCE.NS','TCS.NS','INFY.NS','HDFCBANK.NS','ICICIBANK.NS','SBIN.NS','ITC.NS','LT.NS','HINDUNILVR.NS','ASIANPAINT.NS',
    'BHARTIARTL.NS','AXISBANK.NS','MARUTI.NS','BAJFINANCE.NS','ADANIENT.NS','WIPRO.NS','TATASTEEL.NS','POWERGRID.NS','ONGC.NS','ULTRACEMCO.NS',
  ];
  String _filter = 'gainers'; // gainers | losers | 52high | 52low
  List<Quote> _list = const [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final quotes = await _service.fetchQuotesBatch(_symbols);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _list = _applyFilter(quotes, _filter).take(8).toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Iterable<Quote> _applyFilter(List<Quote> quotes, String f) {
    switch (f) {
      case 'losers':
        return quotes.where((q) => q.changePct.isFinite).toList()
          ..sort((a, b) => a.changePct.compareTo(b.changePct));
      case '52high':
        return quotes.where((q) => q.fiftyTwoWeekHigh != null && q.price >= (q.fiftyTwoWeekHigh! * 0.995)).toList()
          ..sort((a, b) => (b.price - (b.fiftyTwoWeekHigh ?? b.price)).compareTo(a.price - (a.fiftyTwoWeekHigh ?? a.price)));
      case '52low':
        return quotes.where((q) => q.fiftyTwoWeekLow != null && q.price <= (q.fiftyTwoWeekLow! * 1.005)).toList()
          ..sort((a, b) => ((a.price - (a.fiftyTwoWeekLow ?? a.price))).compareTo(b.price - (b.fiftyTwoWeekLow ?? b.price)));
      case 'gainers':
      default:
        return quotes.where((q) => q.changePct.isFinite).toList()
          ..sort((a, b) => b.changePct.compareTo(a.changePct));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            children: [
              _chip('Top gainers', 'gainers', cs),
              _chip('Top losers', 'losers', cs),
              _chip('52 wk high', '52high', cs),
              _chip('52 wk low', '52low', cs),
            ],
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          ..._list.map((q) => _tile(q, cs)).toList(),
      ],
    );
  }

  Widget _chip(String label, String value, ColorScheme cs) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() {
        _filter = value;
        // reapply current quotes quickly
        _list = _applyFilter(_list, value).take(8).toList();
      }),
      selectedColor: cs.primaryContainer,
      labelStyle: TextStyle(color: selected ? cs.onPrimaryContainer : null),
    );
  }

  Widget _tile(Quote q, ColorScheme cs) {
    final up = q.change >= 0;
    final color = up ? cs.primary : Colors.red;
    final title = (q.name?.isNotEmpty ?? false) ? q.name! : q.symbol;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(backgroundColor: cs.primaryContainer, child: Text((title.isNotEmpty ? title[0] : '?'))),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('₹${q.price.toStringAsFixed(2)}'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          '${up ? '+' : ''}${q.changePct.toStringAsFixed(2)}%',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
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

// Simple search delegate to search symbols and fetch a quick quote
class _SymbolSearchDelegate extends SearchDelegate<String> {
  final MarketService _service = MarketService();

  final _suggestions = const [
    '^NSEI', // NIFTY 50
    '^NSEBANK', // BankNifty
    '^BSESN', // Sensex
    'RELIANCE.NS', 'TCS.NS', 'INFY.NS', 'HDFCBANK.NS', 'ITC.NS', 'LT.NS',
    'GC=F', 'CL=F',
  ];

  @override
  String get searchFieldLabel => 'Search symbol (e.g., RELIANCE.NS)';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(onPressed: () => close(context, ''), icon: const Icon(Icons.arrow_back));
  }

  @override
  Widget buildResults(BuildContext context) {
    final symbol = query.trim().isEmpty ? _suggestions.first : query.trim();
    return FutureBuilder<Quote>(
      future: _service.fetchQuote(symbol),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || !snap.hasData) {
          return const Center(child: Text('No result'));
        }
        final q = snap.data!;
        final up = q.change >= 0;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(q.symbol.isNotEmpty ? q.symbol[0] : '?')),
              title: Text(q.symbol),
              subtitle: Text('₹${q.price.toStringAsFixed(2)}'),
              trailing: Text(
                '${up ? '+' : ''}${q.change.toStringAsFixed(2)} (${q.changePct.toStringAsFixed(2)}%)',
                style: TextStyle(color: up ? Colors.green : Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final q = query.toUpperCase();
    final list = _suggestions.where((s) => s.toUpperCase().contains(q)).toList();
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, i) {
        final s = list[i];
        return ListTile(
          leading: const Icon(Icons.search),
          title: Text(s),
          onTap: () {
            query = s;
            showResults(context);
          },
        );
      },
    );
  }
}
