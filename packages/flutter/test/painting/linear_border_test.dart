// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const Rect canvasRect = Rect.fromLTWH(0, 0, 100, 100);
const BorderSide borderSide = BorderSide(width: 4, color: Color(0x0f00ff00));

// Test points for rectangular filled paths based on a BorderSide with width 4 and
// a 100x100 bounding rectangle (canvasRect).
List<Offset> rectIncludes(Rect r) {
  return <Offset>[r.topLeft, r.topRight, r.bottomLeft, r.bottomRight, r.center];
}

final List<Offset> leftRectIncludes = rectIncludes(const Rect.fromLTWH(0, 0, 4, 100));
final List<Offset> rightRectIncludes = rectIncludes(const Rect.fromLTWH(96, 0, 4, 100));
final List<Offset> topRectIncludes = rectIncludes(const Rect.fromLTWH(0, 0, 100, 4));
final List<Offset> bottomRectIncludes = rectIncludes(const Rect.fromLTWH(0, 96, 100, 4));

void main() {
  test('LinearBorder scaling preserves its edges', () {
    const border = LinearBorder(
      side: borderSide,
      start: LinearBorderEdge(size: 0.5, alignment: -1.0),
      end: LinearBorderEdge(size: 0.25, alignment: 1.0),
      top: LinearBorderEdge(),
      bottom: LinearBorderEdge(size: 0.75),
    );
    expect(border.scale(1.0), border);
    final LinearBorder scaled = border.copyWith(side: borderSide.scale(0.5));
    expect(border.scale(0.5), scaled);
    expect(ShapeBorder.lerp(null, border, 0.5), scaled);
    expect(ShapeBorder.lerp(border, null, 0.5), scaled);
  });

  for (final TextDirection direction in TextDirection.values) {
    test('LinearBorder paints translated edges in $direction', () {
      const border = LinearBorder(
        side: borderSide,
        start: LinearBorderEdge(),
        end: LinearBorderEdge(),
        top: LinearBorderEdge(),
        bottom: LinearBorderEdge(),
      );
      final canvas = _PathRecordingCanvas();
      border.paint(canvas, const Rect.fromLTWH(30.0, 40.0, 100.0, 100.0), textDirection: direction);
      final startX = direction == TextDirection.ltr ? 30.0 : 126.0;
      final endX = direction == TextDirection.ltr ? 126.0 : 30.0;
      expect(canvas.paths.map((Path path) => path.getBounds()), <Rect>[
        Rect.fromLTWH(startX, 44.0, 4.0, 92.0),
        Rect.fromLTWH(endX, 44.0, 4.0, 92.0),
        const Rect.fromLTWH(30.0, 40.0, 100.0, 4.0),
        const Rect.fromLTWH(30.0, 136.0, 100.0, 4.0),
      ]);

      final LinearBorder partialBorder = border.copyWith(
        start: const LinearBorderEdge(size: 0.5, alignment: 1.0),
        end: const LinearBorderEdge(size: 0.5, alignment: -1.0),
        top: const LinearBorderEdge(size: 0.5, alignment: 1.0),
        bottom: const LinearBorderEdge(size: 0.5, alignment: -1.0),
      );
      final partialCanvas = _PathRecordingCanvas();
      partialBorder.paint(
        partialCanvas,
        const Rect.fromLTWH(30.0, 40.0, 100.0, 100.0),
        textDirection: direction,
      );
      expect(partialCanvas.paths.map((Path path) => path.getBounds()), <Rect>[
        Rect.fromLTWH(startX, 90.0, 4.0, 46.0),
        Rect.fromLTWH(endX, 44.0, 4.0, 46.0),
        Rect.fromLTWH(direction == TextDirection.ltr ? 80.0 : 30.0, 40.0, 50.0, 4.0),
        Rect.fromLTWH(direction == TextDirection.ltr ? 30.0 : 80.0, 136.0, 50.0, 4.0),
      ]);
    });
  }

  test('LinearBorderEdge defaults', () {
    expect(const LinearBorderEdge().size, 1);
    expect(const LinearBorderEdge().alignment, 0);
  });

  test('LinearBorder defaults', () {
    void expectEmptyBorder(LinearBorder border) {
      expect(border.side, BorderSide.none);
      expect(border.dimensions, EdgeInsets.zero);
      expect(border.preferPaintInterior, false);
      expect(border.start, null);
      expect(border.end, null);
      expect(border.top, null);
      expect(border.bottom, null);
    }

    expectEmptyBorder(LinearBorder.none);

    expect(LinearBorder.start().side, BorderSide.none);
    expect(LinearBorder.start().start, const LinearBorderEdge());
    expect(LinearBorder.start().end, null);
    expect(LinearBorder.start().top, null);
    expect(LinearBorder.start().bottom, null);

    expect(LinearBorder.end().side, BorderSide.none);
    expect(LinearBorder.end().start, null);
    expect(LinearBorder.end().end, const LinearBorderEdge());
    expect(LinearBorder.end().top, null);
    expect(LinearBorder.end().bottom, null);

    expect(LinearBorder.top().side, BorderSide.none);
    expect(LinearBorder.top().start, null);
    expect(LinearBorder.top().end, null);
    expect(LinearBorder.top().top, const LinearBorderEdge());
    expect(LinearBorder.top().bottom, null);

    expect(LinearBorder.bottom().side, BorderSide.none);
    expect(LinearBorder.bottom().start, null);
    expect(LinearBorder.bottom().end, null);
    expect(LinearBorder.bottom().top, null);
    expect(LinearBorder.bottom().bottom, const LinearBorderEdge());
  });

  test('LinearBorder copyWith, ==, hashCode', () {
    expect(LinearBorder.none, LinearBorder.none.copyWith());
    expect(LinearBorder.none.hashCode, LinearBorder.none.copyWith().hashCode);
    const side = BorderSide(width: 10.0, color: Color(0xff123456));
    expect(LinearBorder.none.copyWith(side: side), const LinearBorder(side: side));
  });

  test('LinearBorder lerp identical a,b', () {
    expect(OutlinedBorder.lerp(null, null, 0), null);
    const LinearBorder border = LinearBorder.none;
    expect(identical(OutlinedBorder.lerp(border, border, 0.5), border), true);
  });

  test('LinearBorderEdge.lerp identical a,b', () {
    expect(LinearBorderEdge.lerp(null, null, 0), null);
    const edge = LinearBorderEdge();
    expect(identical(LinearBorderEdge.lerp(edge, edge, 0.5), edge), true);
  });

  test(
    'LinearBorderEdge, LinearBorder toString()',
    () {
      expect(
        const LinearBorderEdge(size: 0.5, alignment: -0.5).toString(),
        'LinearBorderEdge(size: 0.5, alignment: -0.5)',
      );
      expect(LinearBorder.none.toString(), 'LinearBorder.none');
      const side = BorderSide(width: 10.0, color: Color(0xff123456));
      expect(
        const LinearBorder(side: side).toString(),
        'LinearBorder(side: BorderSide(color: ${const Color(0xff123456)}, width: 10.0))',
      );
      expect(
        const LinearBorder(
          side: side,
          start: LinearBorderEdge(size: 0, alignment: -0.75),
          end: LinearBorderEdge(size: 0.25, alignment: -0.5),
          top: LinearBorderEdge(size: 0.5, alignment: 0.5),
          bottom: LinearBorderEdge(size: 0.75, alignment: 0.75),
        ).toString(),
        'LinearBorder('
        'side: BorderSide(color: ${const Color(0xff123456)}, width: 10.0), '
        'start: LinearBorderEdge(size: 0.0, alignment: -0.75), '
        'end: LinearBorderEdge(size: 0.25, alignment: -0.5), '
        'top: LinearBorderEdge(size: 0.5, alignment: 0.5), '
        'bottom: LinearBorderEdge(size: 0.75, alignment: 0.75))',
      );
    },
    skip: isBrowser, // [intended] see https://github.com/flutter/flutter/issues/118207
  );

  test('LinearBorder.start()', () {
    final border = LinearBorder.start(side: borderSide);
    expect(
      (Canvas canvas) => border.paint(canvas, canvasRect, textDirection: TextDirection.ltr),
      paints
        ..path(includes: leftRectIncludes, excludes: rightRectIncludes, color: borderSide.color),
    );
    expect(
      (Canvas canvas) => border.paint(canvas, canvasRect, textDirection: TextDirection.rtl),
      paints
        ..path(includes: rightRectIncludes, excludes: leftRectIncludes, color: borderSide.color),
    );
  });

  test('LinearBorder.end()', () {
    final border = LinearBorder.end(side: borderSide);
    expect(
      (Canvas canvas) => border.paint(canvas, canvasRect, textDirection: TextDirection.ltr),
      paints
        ..path(includes: rightRectIncludes, excludes: leftRectIncludes, color: borderSide.color),
    );
    expect(
      (Canvas canvas) => border.paint(canvas, canvasRect, textDirection: TextDirection.rtl),
      paints
        ..path(includes: leftRectIncludes, excludes: rightRectIncludes, color: borderSide.color),
    );
  });

  test('LinearBorder.top()', () {
    final border = LinearBorder.top(side: borderSide);
    expect(
      (Canvas canvas) => border.paint(canvas, canvasRect, textDirection: TextDirection.ltr),
      paints
        ..path(includes: topRectIncludes, excludes: bottomRectIncludes, color: borderSide.color),
    );
  });

  test('LinearBorder.bottom()', () {
    final border = LinearBorder.bottom(side: borderSide);
    expect(
      (Canvas canvas) => border.paint(canvas, canvasRect, textDirection: TextDirection.ltr),
      paints
        ..path(includes: bottomRectIncludes, excludes: topRectIncludes, color: borderSide.color),
    );
  });
}

class _PathRecordingCanvas extends TestRecordingCanvas {
  final List<Path> paths = <Path>[];

  @override
  void drawPath(Path path, Paint paint) {
    paths.add(Path.from(path));
  }
}
