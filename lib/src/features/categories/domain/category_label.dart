import '../../../core/l10n/l10n.dart';

/// Tên hiển thị của một danh mục.
///
/// 25 danh mục mặc định nằm sẵn trong DB với `user_id = null`, và policy
/// `"Users can manage own categories" ... using (auth.uid() = user_id)` khiến
/// người dùng KHÔNG sửa hay xoá được chúng. Nhờ vậy tên tiếng Anh trong seed là
/// một khoá dịch ổn định: bản ghi vẫn phải ở lại DB (giao dịch trỏ tới bằng
/// khoá ngoại `category_id`, và các RPC thống kê tự gộp theo danh mục), nhưng
/// cột `name` của chúng chỉ còn đóng vai trò khoá — chữ hiển thị lấy từ ARB.
///
/// Danh mục người dùng tự tạo giữ nguyên tên họ đặt.
///
/// Hạn chế đã biết: `get_analytics`, `get_period_summary` và
/// `get_budget_progress` chỉ trả về chuỗi tên, không kèm `is_default`, nên việc
/// nhận dạng phải dựa vào tên. Ai tự tạo một danh mục trùng đúng tên tiếng Anh
/// mặc định (ví dụ đặt tên "Shopping") thì cũng được dịch theo. Muốn chuẩn
/// tuyệt đối thì phải sửa ba RPC đó để trả thêm `is_default`.
String categoryLabel(AppLocalizations l10n, String? rawName) {
  final name = rawName?.trim();
  if (name == null || name.isEmpty) return l10n.commonOther;
  return switch (name) {
    // --- Chi ---
    'Food & Dining' => l10n.catFoodDining,
    'Health' => l10n.catHealth,
    'Beauty' => l10n.catBeauty,
    'Job' => l10n.catJob,
    'Shopping' => l10n.catShopping,
    'Transportation' => l10n.catTransportation,
    'Housing' => l10n.catHousing,
    'Entertainment' => l10n.catEntertainment,
    'Education' => l10n.catEducation,
    'Sports' => l10n.catSports,
    'Social' => l10n.catSocial,
    'Clothing' => l10n.catClothing,
    'Car' => l10n.catCar,
    'Electronics' => l10n.catElectronics,
    'Travel' => l10n.catTravel,
    'Pets' => l10n.catPets,
    'Gifts' => l10n.catGifts,
    'Donations' => l10n.catDonations,
    'Family' => l10n.catFamily,
    // --- Thu ---
    'Salary' => l10n.catSalary,
    'Bonus' => l10n.catBonus,
    'Investment' => l10n.catInvestment,
    'Freelance' => l10n.catFreelance,
    'Gifts Received' => l10n.catGiftsReceived,
    'Others' => l10n.catOthers,
    // `get_analytics` thay danh mục rỗng bằng chuỗi 'Khác' cứng trong SQL
    // (`coalesce(c.name, 'Khác')`), nên phải nhận ở đây thì giao diện tiếng Anh
    // mới không lòi ra chữ tiếng Việt.
    'Khác' => l10n.commonOther,
    _ => name,
  };
}
