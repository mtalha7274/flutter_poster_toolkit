import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_poster_example/main.dart';

void main() {
  testWidgets('example displays a blank editor with visible tools', (
    tester,
  ) async {
    await tester.pumpWidget(const PosterExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('LOST CAT'), findsNothing);
    expect(find.byTooltip('Add Text'), findsOneWidget);
    expect(find.byTooltip('Show tools'), findsNothing);
  });
}
