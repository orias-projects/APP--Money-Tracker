import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Ánh xạ `categories.icon_name` sang [IconData].
///
/// Trước đây bảng này chỉ có 5 mục nằm lẫn trong màn Thêm giao dịch, nên 20/25
/// danh mục mặc định đều rơi về icon "category" chung chung.
const Map<String, IconData> kCategoryIcons = {
  // Chi tiêu
  'restaurant': Icons.restaurant,
  'medical_services': Icons.medical_services,
  'face': Icons.face,
  'work': Icons.work,
  'shopping_cart': Icons.shopping_cart,
  'directions_car': Icons.directions_car,
  'home': Icons.home,
  'sports_esports': Icons.sports_esports,
  'school': Icons.school,
  'pool': Icons.pool,
  'people': Icons.people,
  'checkroom': Icons.checkroom,
  'directions_car_filled': Icons.directions_car_filled,
  'devices': Icons.devices,
  'flight_takeoff': Icons.flight_takeoff,
  'pets': Icons.pets,
  'card_giftcard': Icons.card_giftcard,
  'volunteer_activism': Icons.volunteer_activism,
  'family_restroom': Icons.family_restroom,

  // Thu nhập
  'payments': Icons.payments,
  'military_tech': Icons.military_tech,
  'trending_up': Icons.trending_up,
  'laptop_mac': Icons.laptop_mac,
  'redeem': Icons.redeem,
  'account_balance_wallet': Icons.account_balance_wallet,

  // Bổ sung cho danh mục tự tạo
  'local_cafe': Icons.local_cafe,
  'local_bar': Icons.local_bar,
  'fastfood': Icons.fastfood,
  'local_grocery_store': Icons.local_grocery_store,
  'local_gas_station': Icons.local_gas_station,
  'local_hospital': Icons.local_hospital,
  'fitness_center': Icons.fitness_center,
  'spa': Icons.spa,
  'child_care': Icons.child_care,
  'phone_android': Icons.phone_android,
  'wifi': Icons.wifi,
  'bolt': Icons.bolt,
  'water_drop': Icons.water_drop,
  'subscriptions': Icons.subscriptions,
  'movie': Icons.movie,
  'music_note': Icons.music_note,
  'menu_book': Icons.menu_book,
  'savings': Icons.savings,
  'account_balance': Icons.account_balance,
  'credit_card': Icons.credit_card,
  'receipt_long': Icons.receipt_long,
  'handyman': Icons.handyman,
  'cleaning_services': Icons.cleaning_services,
  'train': Icons.train,
  'two_wheeler': Icons.two_wheeler,
  'local_taxi': Icons.local_taxi,
  'hotel': Icons.hotel,
  'beach_access': Icons.beach_access,
  'sports_soccer': Icons.sports_soccer,
  'category': Icons.category,
};

/// Các icon cho người dùng chọn khi tạo danh mục riêng.
List<String> get pickableIconNames => kCategoryIcons.keys.toList();

IconData iconFromName(String? name) => kCategoryIcons[name] ?? Icons.category;

/// Đổi chuỗi `#RRGGBB` thành [Color]. Trả [fallback] nếu chuỗi không hợp lệ.
Color parseHexColor(String? hex, {Color fallback = AppColors.textSecondary}) {
  if (hex == null) return fallback;
  var h = hex.trim();
  if (h.isEmpty) return fallback;
  if (h.startsWith('#')) h = h.substring(1);
  if (h.length == 3) {
    h = h.split('').map((c) => '$c$c').join();
  }
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return fallback;
  final value = int.tryParse(h, radix: 16);
  return value == null ? fallback : Color(value);
}

/// Bảng màu cho người dùng chọn khi tạo danh mục / nhãn.
const List<String> kPickableColors = [
  '#FFD700',
  '#FF4500',
  '#22C55E',
  '#3B82F6',
  '#8B5CF6',
  '#EC4899',
  '#F59E0B',
  '#14B8A6',
  '#EF4444',
  '#6366F1',
  '#84CC16',
  '#06B6D4',
  '#F97316',
  '#A855F7',
  '#64748B',
];
