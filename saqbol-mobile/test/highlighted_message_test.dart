import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saqbol_mobile/src/features/sms/widgets/highlighted_message.dart';

void main() {
  testWidgets('renders the full message text with triggers highlighted', (tester) async {
    const message = 'Служба безопасности банка, назовите код из смс';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HighlightedMessage(
            text: message,
            triggers: ['код из смс', 'служба безопасности'],
            highlightColor: Colors.red,
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(find.byType(RichText));
    expect(richText.text.toPlainText(), message);

    var highlighted = 0;
    (richText.text as TextSpan).visitChildren((span) {
      if (span is TextSpan && span.style?.fontWeight == FontWeight.w600) {
        highlighted++;
      }
      return true;
    });
    expect(highlighted, greaterThan(0));
  });

  testWidgets('renders plain text when there are no triggers', (tester) async {
    const message = 'Привет, увидимся завтра';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HighlightedMessage(
            text: message,
            triggers: [],
            highlightColor: Colors.green,
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(find.byType(RichText));
    expect(richText.text.toPlainText(), message);
  });
}
