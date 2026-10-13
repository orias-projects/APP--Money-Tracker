// Sinh icon launcher + logo splash cho Coinsort.
//
// Chạy: dart run tool/gen_icon.dart
// Sau đó: dart run flutter_launcher_icons && dart run flutter_native_splash:create
//
// Thiết kế: đồng xu (hai vòng tròn đồng tâm) với ký hiệu $ ở giữa, toàn bộ
// bằng nét TRẮNG trên nền VÀNG. Vẽ ở độ phân giải gấp đôi rồi thu nhỏ để có
// biên mượt (canvas trong suốt tô "trắng alpha 0" để không bị viền đen khi
// lấy trung bình pixel).
//
// Tạo ra:
//   assets/ICO/app_icon.png     1024² nền vàng đặc — icon legacy Android, iOS, web
//   assets/ICO/app_icon_fg.png  1024² nền trong suốt — foreground adaptive icon
//                               + monochrome (Android 13 themed icon)
//   assets/ICO/splash_logo.png   512² nền trong suốt — logo splash
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

/// Nền vàng thương hiệu (khớp `#FFC107` trong flutter_launcher_icons.yaml và
/// flutter_native_splash.yaml).
final _yellow = ColorRgb8(0xFF, 0xC1, 0x07);
final _white = ColorRgb8(0xFF, 0xFF, 0xFF);

/// Trắng nhưng alpha 0: khi thu nhỏ, pixel biên trộn trắng-đục với trắng-trong
/// suốt → ra trắng bán trong suốt, không có quầng đen.
final _clearWhite = ColorRgba8(0xFF, 0xFF, 0xFF, 0);

const _supersample = 2;

void main() {
  Directory('assets/ICO').createSync(recursive: true);

  final icon = _render(size: 1024, background: _yellow);
  File('assets/ICO/app_icon.png').writeAsBytesSync(encodePng(icon));

  final foreground = _render(size: 1024, background: _clearWhite);
  File('assets/ICO/app_icon_fg.png').writeAsBytesSync(encodePng(foreground));

  final splash = _render(size: 512, background: _clearWhite);
  File('assets/ICO/splash_logo.png').writeAsBytesSync(encodePng(splash));

  stdout.writeln(
    'Đã tạo assets/ICO/app_icon.png (1024, nền vàng), app_icon_fg.png (1024, '
    'trong suốt) và splash_logo.png (512, trong suốt).',
  );
}

Image _render({required int size, required Color background}) {
  final big = size * _supersample;
  final img = Image(width: big, height: big, numChannels: 4);
  fill(img, color: background);
  _drawCoinDollar(img, scale: big / 1024.0);
  return copyResize(
    img,
    width: size,
    height: size,
    interpolation: Interpolation.average,
  );
}

/// Vẽ đồng xu + ký hiệu $ vào tâm ảnh. Toạ độ thiết kế theo canvas 1024,
/// nhân [scale] để ra pixel thật. Toàn bộ hình nằm trong đường kính 620/1024
/// (~60%) để lọt vùng an toàn 66% của adaptive icon — mask tròn/vuông bo góc
/// của launcher không cắt mất vòng ngoài.
void _drawCoinDollar(Image img, {required double scale}) {
  final cx = img.width / 2;
  final cy = img.height / 2;
  int px(double v) => (v * scale).round();

  Color? bgAt(int x, int y) => img.getPixelSafe(x, y);
  // Màu nền để "khoét" ruột vòng tròn: lấy đúng pixel nền hiện tại.
  final bg = bgAt(0, 0)!;

  // --- Vòng ngoài đồng xu (dày 30) ---
  fillCircle(img, x: cx.round(), y: cy.round(), radius: px(310), color: _white);
  fillCircle(img, x: cx.round(), y: cy.round(), radius: px(280), color: bg);

  // --- Vòng trong mảnh (dày 12) — gợi gờ đồng xu ---
  fillCircle(img, x: cx.round(), y: cy.round(), radius: px(250), color: _white);
  fillCircle(img, x: cx.round(), y: cy.round(), radius: px(238), color: bg);

  // --- Ký hiệu $ : hai cung tròn tạo chữ S + thanh dọc xuyên qua ---
  const r = 72.0; // bán kính mỗi vòng của chữ S
  const strokeS = 30.0; // độ dày nét S
  const strokeBar = 22.0; // độ dày thanh dọc

  void stamp(double x, double y, double stroke) {
    fillCircle(
      img,
      x: (cx + x * scale).round(),
      y: (cy + y * scale).round(),
      radius: px(stroke / 2),
      color: _white,
    );
  }

  // Thanh dọc: vẽ trước để nét S phủ lên, đầu thanh tròn nhờ stamp.
  final barHalf = 2 * r + 40;
  for (var y = -barHalf; y <= barHalf; y += 1) {
    stamp(0, y, strokeBar);
  }

  // Cung trên: tâm (0, -r), quét từ 320° giảm về 90° (toạ độ ảnh: y hướng
  // xuống, 270° là đỉnh). Cung dưới đối xứng: tâm (0, r), từ 270° tăng tới 500°.
  void arc({
    required double centerY,
    required double fromDeg,
    required double toDeg,
  }) {
    final steps = ((toDeg - fromDeg).abs() * 2).round(); // 0.5° mỗi bước
    for (var i = 0; i <= steps; i++) {
      final deg = fromDeg + (toDeg - fromDeg) * i / steps;
      final rad = deg * math.pi / 180;
      stamp(r * math.cos(rad), centerY + r * math.sin(rad), strokeS);
    }
  }

  arc(centerY: -r, fromDeg: 320, toDeg: 90);
  arc(centerY: r, fromDeg: 270, toDeg: 500);
}
