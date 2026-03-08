import 'package:flutter_test/flutter_test.dart';
import 'package:inference_gunslinger/models/tool.dart';
import 'package:inference_gunslinger/models/context_window.dart';

void main() {
  group('Tool', () {
    test('three tools defined', () {
      expect(Tool.all.length, 3);
    });

    test('web search costs 8% system', () {
      expect(Tool.all[0].systemCost, 0.08);
    });
  });

  group('ContextWindow with tools', () {
    late ContextWindow ctx;

    setUp(() {
      ctx = ContextWindow();
    });

    test('addToolLoad increases system load', () {
      ctx.addToolLoad(0.08);
      expect(ctx.systemLoad, closeTo(0.28, 0.01));
    });

    test('removeToolLoad decreases system load', () {
      ctx.addToolLoad(0.10);
      ctx.removeToolLoad(0.10);
      expect(ctx.systemLoad, closeTo(0.20, 0.01));
    });

    test('removeToolLoad cannot go below base', () {
      ctx.removeToolLoad(0.50);
      expect(ctx.systemLoad, closeTo(0.20, 0.01));
    });

    test('compaction buffer threshold is 83.5%', () {
      expect(ctx.compactionThreshold, closeTo(0.835, 0.01));
    });

    test('isInCompactionZone when load exceeds threshold', () {
      ctx.consumeContext(0.50);
      expect(ctx.isInCompactionZone, true);
    });

    test('compact reduces user space by 60%', () {
      ctx.consumeContext(0.40);
      ctx.compact();
      expect(ctx.userLoad, closeTo(0.16, 0.01));
      expect(ctx.isCompacted, true);
    });

    test('reset clears compacted state and tool loads', () {
      ctx.addToolLoad(0.10);
      ctx.consumeContext(0.20);
      ctx.compact();
      ctx.reset();
      expect(ctx.systemLoad, closeTo(0.20, 0.01));
      expect(ctx.userLoad, 0.0);
      expect(ctx.isCompacted, false);
    });
  });
}
