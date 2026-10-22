import 'package:flutter_test/flutter_test.dart';
import 'package:saqbol_mobile/src/features/history/history_models.dart';
import 'package:saqbol_mobile/src/features/history/history_providers.dart';

HistoryItem _item(String id, String verdict, DateTime createdAt, {String channel = 'sms'}) {
  return HistoryItem(
    id: id,
    channel: channel,
    text: 'text $id',
    sourceNumber: '',
    probability: 0.5,
    verdict: verdict,
    category: '',
    createdAt: createdAt,
  );
}

void main() {
  final now = DateTime(2026, 10, 20, 15);

  test('weekly stats count only the last seven days', () {
    final items = [
      _item('1', 'scam', now.subtract(const Duration(hours: 1))),
      _item('2', 'suspicious', now.subtract(const Duration(days: 2))),
      _item('3', 'safe', now.subtract(const Duration(days: 6))),
      _item('4', 'scam', now.subtract(const Duration(days: 8))),
    ];

    final stats = weeklyStats(items, now);

    expect(stats.checked, 3);
    expect(stats.scam, 1);
    expect(stats.suspicious, 1);
  });

  test('weekly stats of an empty history are zero', () {
    final stats = weeklyStats(const [], now);
    expect([stats.checked, stats.scam, stats.suspicious], [0, 0, 0]);
  });

  test('recent threats skip safe messages and come newest first', () {
    final items = [
      _item('old-scam', 'scam', now.subtract(const Duration(days: 3))),
      _item('safe', 'safe', now),
      _item('new-suspicious', 'suspicious', now.subtract(const Duration(hours: 2))),
      _item('mid-scam', 'scam', now.subtract(const Duration(days: 1))),
      _item('oldest-scam', 'scam', now.subtract(const Duration(days: 5))),
    ];

    final threats = recentThreats(items);

    expect(threats.map((item) => item.id), ['new-suspicious', 'mid-scam', 'old-scam']);
  });

  test('filters combine channel and verdict, empty means all', () {
    final items = [
      _item('sms-scam', 'scam', now),
      _item('sms-safe', 'safe', now),
      _item('call-scam', 'scam', now, channel: 'call'),
    ];

    expect(filterHistory(items).length, 3);
    expect(filterHistory(items, verdict: 'scam').map((item) => item.id), ['sms-scam', 'call-scam']);
    expect(filterHistory(items, channel: 'call').map((item) => item.id), ['call-scam']);
    expect(filterHistory(items, channel: 'sms', verdict: 'scam').map((item) => item.id), ['sms-scam']);
    expect(filterHistory(items, verdict: 'suspicious'), isEmpty);
  });

  test('groups by calendar day, newest day and item first', () {
    final items = [
      _item('yesterday-evening', 'safe', DateTime(2026, 10, 19, 23, 50)),
      _item('today-morning', 'safe', DateTime(2026, 10, 20, 8)),
      _item('today-noon', 'scam', DateTime(2026, 10, 20, 12)),
      _item('last-week', 'safe', DateTime(2026, 10, 13, 9)),
    ];

    final days = groupByDay(items);

    expect(days.map((day) => day.day), [
      DateTime(2026, 10, 20),
      DateTime(2026, 10, 19),
      DateTime(2026, 10, 13),
    ]);
    expect(days.first.items.map((item) => item.id), ['today-noon', 'today-morning']);
    expect(days[1].items.single.id, 'yesterday-evening');
  });
}
