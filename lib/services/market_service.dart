import 'dart:convert';
import 'package:http/http.dart' as http;

class ChartData {
  final List<DateTime> times;
  final List<double> closes;
  final double last;
  final double change;
  final double changePct;

  ChartData({
    required this.times,
    required this.closes,
    required this.last,
    required this.change,
    required this.changePct,
  });
}

class MarketService {
  final http.Client _client;
  MarketService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches intraday chart data from Yahoo Finance public API.
  /// Example symbols:
  ///  - NIFTY 50: ^NSEI
  ///  - SENSEX: ^BSESN
  ///  - BANK NIFTY: ^NSEBANK
  ///  - Gold: GC=F, Crude: CL=F
  Future<ChartData> fetchChart(
    String symbol, {
    String range = '1d',
    String interval = '1m',
  }) async {
    final uri = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?range=$range&interval=$interval');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load $symbol: ${res.statusCode}');
    }
    final json = jsonDecode(res.body);
    final result = json['chart']['result'][0];
    final timestamps = (result['timestamp'] as List).cast<int>();
    final indicators = result['indicators'];
    final quote = indicators['quote'][0];
    final closesRaw = (quote['close'] as List).map((e) => e?.toDouble()).toList();

    // filter nulls while keeping alignment with timestamps
    final times = <DateTime>[];
    final closes = <double>[];
    for (var i = 0; i < closesRaw.length; i++) {
      final v = closesRaw[i];
      if (v != null) {
        times.add(DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000));
        closes.add(v);
      }
    }

    if (closes.isEmpty) {
      throw Exception('No data for $symbol');
    }

    final last = closes.last;
    final previousClose = (result['meta']['previousClose'] as num?)?.toDouble() ?? closes.first;
    final change = last - previousClose;
    final changePct = previousClose == 0 ? 0 : (change / previousClose) * 100;

    return ChartData(
      times: times,
      closes: closes,
      last: last,
      change: change,
      changePct: changePct.toDouble(),
    );
  }

  // Lightweight quote endpoint for near-realtime price.
  Future<Quote> fetchQuote(String symbol) async {
    final uri = Uri.parse('https://query1.finance.yahoo.com/v7/finance/quote?symbols=$symbol');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load quote for $symbol: ${res.statusCode}');
    }
    final json = jsonDecode(res.body);
    final result = (json['quoteResponse']['result'] as List).first;
    final price = (result['regularMarketPrice'] as num?)?.toDouble() ?? 0.0;
    final change = (result['regularMarketChange'] as num?)?.toDouble() ?? 0.0;
    final changePct = (result['regularMarketChangePercent'] as num?)?.toDouble() ?? 0.0;
    final tsMs = ((result['regularMarketTime'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch ~/ 1000) * 1000;
    final name = (result['shortName'] as String?) ?? (result['longName'] as String?) ?? symbol;
    return Quote(
      symbol: symbol,
      price: price,
      change: change,
      changePct: changePct,
      name: name,
      time: DateTime.fromMillisecondsSinceEpoch(tsMs),
    );
  }

  // Batch quotes for multiple symbols in one request
  Future<List<Quote>> fetchQuotesBatch(List<String> symbols) async {
    if (symbols.isEmpty) return [];
    final joined = symbols.join(',');
    final uri = Uri.parse('https://query1.finance.yahoo.com/v7/finance/quote?symbols=$joined');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed batch quotes: ${res.statusCode}');
    }
    final json = jsonDecode(res.body);
    final results = (json['quoteResponse']['result'] as List);
    return results.map<Quote>((r) {
      final price = (r['regularMarketPrice'] as num?)?.toDouble() ?? 0.0;
      final change = (r['regularMarketChange'] as num?)?.toDouble() ?? 0.0;
      final changePct = (r['regularMarketChangePercent'] as num?)?.toDouble() ?? 0.0;
      final tsMs = ((r['regularMarketTime'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch ~/ 1000) * 1000;
      final sym = (r['symbol'] as String?) ?? '';
      final name = (r['shortName'] as String?) ?? (r['longName'] as String?) ?? sym;
      final high52 = (r['fiftyTwoWeekHigh'] as num?)?.toDouble();
      final low52 = (r['fiftyTwoWeekLow'] as num?)?.toDouble();
      return Quote(
        symbol: sym,
        name: name,
        price: price,
        change: change,
        changePct: changePct,
        time: DateTime.fromMillisecondsSinceEpoch(tsMs),
        fiftyTwoWeekHigh: high52,
        fiftyTwoWeekLow: low52,
      );
    }).toList();
  }

  // Emits quotes on a periodic timer (defaults to 1 second).
  Stream<Quote> quoteStream(String symbol, {Duration interval = const Duration(seconds: 1)}) async* {
    while (true) {
      try {
        final q = await fetchQuote(symbol);
        yield q;
      } catch (_) {
        // swallow transient errors; continue
      }
      await Future.delayed(interval);
    }
  }
}

class Quote {
  final String symbol;
  final String? name;
  final double price;
  final double change;
  final double changePct;
  final DateTime time;
  final double? fiftyTwoWeekHigh;
  final double? fiftyTwoWeekLow;
  Quote({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePct,
    required this.time,
    this.name,
    this.fiftyTwoWeekHigh,
    this.fiftyTwoWeekLow,
  });
}
