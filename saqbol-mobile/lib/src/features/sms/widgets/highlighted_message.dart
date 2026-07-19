import 'package:flutter/material.dart';

class HighlightedMessage extends StatelessWidget {
  const HighlightedMessage({
    super.key,
    required this.text,
    required this.triggers,
    required this.highlightColor,
  });

  final String text;
  final List<String> triggers;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final spans = _buildSpans(context);
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(fontSize: 15, height: 1.4),
        children: spans,
      ),
    );
  }

  List<InlineSpan> _buildSpans(BuildContext context) {
    final ranges = _matchRanges();
    if (ranges.isEmpty) {
      return [TextSpan(text: text)];
    }

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final range in ranges) {
      if (range.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, range.start)));
      }
      spans.add(TextSpan(
        text: text.substring(range.start, range.end),
        style: TextStyle(
          backgroundColor: highlightColor.withValues(alpha: 0.22),
          color: highlightColor,
          fontWeight: FontWeight.w600,
        ),
      ));
      cursor = range.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return spans;
  }

  List<_Range> _matchRanges() {
    final lowered = text.toLowerCase();
    final matches = <_Range>[];
    for (final trigger in triggers) {
      final needle = trigger.toLowerCase().trim();
      if (needle.isEmpty) continue;
      var index = lowered.indexOf(needle);
      while (index != -1) {
        matches.add(_Range(index, index + needle.length));
        index = lowered.indexOf(needle, index + needle.length);
      }
    }
    matches.sort((a, b) => a.start.compareTo(b.start));
    return _merge(matches);
  }

  List<_Range> _merge(List<_Range> ranges) {
    final merged = <_Range>[];
    for (final range in ranges) {
      if (merged.isNotEmpty && range.start <= merged.last.end) {
        if (range.end > merged.last.end) {
          merged[merged.length - 1] = _Range(merged.last.start, range.end);
        }
      } else {
        merged.add(range);
      }
    }
    return merged;
  }
}

class _Range {
  const _Range(this.start, this.end);

  final int start;
  final int end;
}
