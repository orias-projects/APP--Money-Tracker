import 'package:spend_sync/src/features/charts/data/analytics_repository.dart';

/// Một lát của biểu đồ tròn danh mục.
///
/// [isOthers] đánh dấu lát tổng hợp các danh mục nhỏ. Dùng cờ này thay vì so
/// sánh tên với chuỗi "Khác": một danh mục CÓ THẬT tên "Khác" vẫn là danh mục
/// thường và phải hiển thị đúng phần trăm của nó.
class PieSlice {
  const PieSlice({
    required this.name,
    required this.amount,
    required this.colorHex,
    required this.isOthers,
  });

  final String name;
  final double amount;
  final String colorHex;
  final bool isOthers;
}

/// Gộp các danh mục nhỏ hơn [minRatio] phần của tổng vào một lát "Khác" duy nhất
/// để biểu đồ tròn không bị vụn. Trả về danh sách rỗng khi tổng bằng 0.
List<PieSlice> buildPieSlices(
  List<CategoryAmount> items, {
  double minRatio = 0.03,
  String othersLabel = 'Khác',
  String uncategorizedLabel = 'Khác',
  String othersColorHex = '#808080',
}) {
  final total = items.fold<double>(0, (sum, e) => sum + e.amount);
  if (total <= 0) return const [];

  final threshold = total * minRatio;
  final slices = <PieSlice>[];
  var othersAmount = 0.0;

  for (final item in items) {
    if (item.amount < threshold) {
      othersAmount += item.amount;
    } else {
      slices.add(
        PieSlice(
          name: item.name ?? uncategorizedLabel,
          amount: item.amount,
          colorHex: item.colorHex,
          isOthers: false,
        ),
      );
    }
  }

  if (othersAmount > 0) {
    slices.add(
      PieSlice(
        name: othersLabel,
        amount: othersAmount,
        colorHex: othersColorHex,
        isOthers: true,
      ),
    );
  }

  return slices;
}
