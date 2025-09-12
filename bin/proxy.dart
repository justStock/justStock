import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8089;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  print('CORS proxy listening on http://localhost:$port');
  await for (final req in server) {
    // Basic CORS headers
    req.response.headers.set('Access-Control-Allow-Origin', '*');
    req.response.headers.set(
        'Access-Control-Allow-Headers', 'Content-Type, Authorization');
    req.response.headers.set('Access-Control-Allow-Methods', 'GET, OPTIONS');

    if (req.method == 'OPTIONS') {
      req.response.statusCode = HttpStatus.noContent;
      await req.response.close();
      continue;
    }

    // Routes:
    //  - /proxy?url=<encoded target>  (generic passthrough)
    //  - /api/quote?symbols=RELIANCE.NS
    //  - /api/quotes?symbols=TCS.NS,INFY.NS
    //  - /api/chart?symbol=^NSEI&range=1d&interval=1m
    final path = req.uri.path;

    Future<void> forward(Uri target) async {
      try {
        final client = HttpClient();
        client.userAgent =
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
        final upstream = await client.getUrl(target);
        upstream.headers.set('Accept', 'application/json,text/plain,*/*');
        final upstreamRes = await upstream.close();

        upstreamRes.headers.forEach((name, values) {
          final lname = name.toLowerCase();
          if ({
            'connection',
            'keep-alive',
            'proxy-authenticate',
            'proxy-authorization',
            'te',
            'trailer',
            'transfer-encoding',
            'upgrade',
          }.contains(lname)) return;
          for (final v in values) {
            req.response.headers.add(name, v);
          }
        });
        req.response.statusCode = upstreamRes.statusCode;
        await upstreamRes.pipe(req.response);
      } catch (e, st) {
        req.response.statusCode = HttpStatus.badGateway;
        req.response.headers.set('content-type', 'application/json');
        req.response
            .write(jsonEncode({'error': e.toString(), 'stack': st.toString()}));
        await req.response.close();
      }
    }

    if (path == '/proxy') {
      final url = req.uri.queryParameters['url'];
      if (url == null || url.isEmpty) {
        req.response.statusCode = HttpStatus.badRequest;
        req.response.write('Missing url parameter');
        await req.response.close();
        continue;
      }
      Uri target;
      try {
        target = Uri.parse(url);
        if (!(target.isScheme('http') || target.isScheme('https'))) {
          throw FormatException('Only http/https allowed');
        }
      } catch (e) {
        req.response.statusCode = HttpStatus.badRequest;
        req.response.write('Invalid url: $e');
        await req.response.close();
        continue;
      }
      await forward(target);
      continue;
    }

    if (path == '/api/quote') {
      final symbols = req.uri.queryParameters['symbols'];
      if (symbols == null || symbols.isEmpty) {
        req.response.statusCode = HttpStatus.badRequest;
        req.response.write('symbols required');
        await req.response.close();
        continue;
      }
      final target = Uri.https(
        'query1.finance.yahoo.com',
        '/v7/finance/quote',
        {'symbols': symbols},
      );
      await forward(target);
      continue;
    }

    if (path == '/api/quotes') {
      final symbols = req.uri.queryParameters['symbols'];
      if (symbols == null || symbols.isEmpty) {
        req.response.statusCode = HttpStatus.badRequest;
        req.response.write('symbols required');
        await req.response.close();
        continue;
      }
      final target = Uri.https(
        'query1.finance.yahoo.com',
        '/v7/finance/quote',
        {'symbols': symbols},
      );
      await forward(target);
      continue;
    }

    if (path == '/api/chart') {
      final symbol = req.uri.queryParameters['symbol'];
      final range = req.uri.queryParameters['range'] ?? '1d';
      final interval = req.uri.queryParameters['interval'] ?? '1m';
      if (symbol == null || symbol.isEmpty) {
        req.response.statusCode = HttpStatus.badRequest;
        req.response.write('symbol required');
        await req.response.close();
        continue;
      }
      final target = Uri.https(
        'query1.finance.yahoo.com',
        '/v8/finance/chart/$symbol',
        {'range': range, 'interval': interval},
      );
      await forward(target);
      continue;
    }

    // 404 fallback with help text
    req.response.statusCode = HttpStatus.notFound;
    req.response.headers.set('content-type', 'text/plain');
    req.response.write('Routes:\n');
    req.response.write('/api/quote?symbols=RELIANCE.NS\n');
    req.response.write('/api/quotes?symbols=TCS.NS,INFY.NS\n');
    req.response.write('/api/chart?symbol=^NSEI&range=1d&interval=1m\n');
    req.response.write('/proxy?url=<encoded target url>\n');
    await req.response.close();
  }
}
