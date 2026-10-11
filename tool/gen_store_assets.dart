// Sinh anh cho Play Store listing tu icon co san.
// Chay: dart run tool/gen_store_assets.dart
import 'dart:io';

import 'package:image/image.dart';

void main() {
  Directory('store_assets').createSync();

  final icon = decodePng(File('assets/ICO/app_icon.png').readAsBytesSync())!;
  File('store_assets/icon_512.png').writeAsBytesSync(
    encodePng(
      copyResize(icon, width: 512, height: 512,
          interpolation: Interpolation.average),
    ),
  );

  // Feature graphic 1024x500: nen vang + dong xu o giua.
  final fg = decodePng(File('assets/ICO/app_icon_fg.png').readAsBytesSync())!;
  final art = copyResize(fg, width: 440, height: 440,
      interpolation: Interpolation.average);
  final canvas = Image(width: 1024, height: 500, numChannels: 4);
  fill(canvas, color: ColorRgb8(0xFF, 0xC1, 0x07));
  compositeImage(canvas, art, dstX: (1024 - 440) ~/ 2, dstY: (500 - 440) ~/ 2);
  File('store_assets/feature_graphic.png')
      .writeAsBytesSync(encodePng(canvas));

  stdout.writeln('store_assets/: icon_512.png (512x512), feature_graphic.png (1024x500)');
}
