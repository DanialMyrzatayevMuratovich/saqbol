import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saqbol_mobile/src/core/providers.dart';
import 'package:saqbol_mobile/src/core/strings.dart';
import 'package:saqbol_mobile/src/features/dashboard/dashboard_screen.dart';
import 'package:saqbol_mobile/src/features/history/history_repository.dart';
import 'package:saqbol_mobile/src/features/history/history_tile.dart';
import 'package:saqbol_mobile/src/shared/app_theme.dart';

final _now = DateTime.now().toUtc();

Map<String, dynamic> _item(String id, String verdict, Duration age) => {
      'id': id,
      'channel': 'sms',
      'text': 'text of $id',
      'source_number': '+77000000000',
      'probability': verdict == 'safe' ? 0.1 : 0.9,
      'verdict': verdict,
      'category': verdict == 'scam' ? 'fake_bank' : '',
      'triggers': '[]',
      'created_at': _now.subtract(age).toIso8601String(),
    };

/// A week with 150 checks, e.g. after one inbox scan: the newest 147 are safe
/// and the 3 threats are older than the first page of 100. The summary is
/// what GET /history/summary returns for that data; /history only ever
/// returns a page of the newest checks.
class _Server implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  late final _page = [for (var i = 0; i < 100; i++) _item('safe-$i', 'safe', Duration(minutes: i + 1))];

  late final _summary = {
    'since': _now.subtract(const Duration(days: 7)).toIso8601String(),
    'checked': 150,
    'scam': 2,
    'suspicious': 1,
    'threats': [
      _item('scam-4-days-ago', 'scam', const Duration(days: 4)),
      _item('suspicious-5-days-ago', 'suspicious', const Duration(days: 5)),
      _item('scam-6-days-ago', 'scam', const Duration(days: 6)),
    ],
  };

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final body = options.path.endsWith('/history/summary') ? _summary : {'items': _page};
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('Home shows the server totals for the week, not the first page of history', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final server = _Server();
    final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'))..httpClientAdapter = server;

    await tester.pumpWidget(ProviderScope(
      overrides: [
        historyRepositoryProvider.overrideWithValue(HistoryRepository(dio)),
        stringsProvider.overrideWithValue(const AppStrings(AppLocale.en)),
      ],
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(body: DashboardScreen()),
      ),
    ));
    await tester.pumpAndSettle();

    // Last 7 days: all 150 checks, and the threats beyond the first 100.
    expect(find.text('150'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    expect(find.byType(HistoryTile), findsNWidgets(3));
    for (final id in ['scam-4-days-ago', 'suspicious-5-days-ago', 'scam-6-days-ago']) {
      expect(find.text('text of $id'), findsOneWidget);
    }

    // One request for the week; the paged history is not used for it.
    expect(server.requests.map((request) => request.path), ['/history/summary']);
    expect(server.requests.single.queryParameters['days'], 7);
  });
}
