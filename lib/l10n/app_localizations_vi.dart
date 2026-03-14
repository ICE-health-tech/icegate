// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get helloWorld => 'Chào thế giới!';

  @override
  String get app_title => 'Ice Gate';

  @override
  String get home_welcome => 'Chào mừng trở lại';

  @override
  String get health_title => 'Sức khỏe & Thể hình';

  @override
  String get health_steps => 'Bước chân';

  @override
  String get health_sleep => 'Giấc ngủ';

  @override
  String get health_heart_rate => 'Nhịp tim';

  @override
  String get health_water => 'Nước';

  @override
  String get health_weight => 'Cân nặng';

  @override
  String get health_calories => 'Calo';

  @override
  String get health_activity => 'Hoạt động';

  @override
  String get health_goal => 'Mục tiêu';

  @override
  String get health_avg => 'Trung bình';

  @override
  String get health_max => 'Cao nhất';

  @override
  String get health_min => 'Thấp nhất';

  @override
  String get health_last_7_days => '7 ngày qua';

  @override
  String get health_last_30_days => '30 ngày qua';

  @override
  String get health_sync_title => 'Đồng bộ dữ liệu';

  @override
  String get health_sync_msg => 'Đang đồng bộ dữ liệu sức khỏe...';

  @override
  String get health_sync_success => 'Đồng bộ dữ liệu thành công!';

  @override
  String get health_sync_failed => 'Đồng bộ thất bại. Vui lòng thử lại.';

  @override
  String get health_update_weight => 'Cập nhật cân nặng';

  @override
  String get health_log_water => 'Ghi nhận nước';

  @override
  String get health_daily_goal_reached => 'Bạn đã đạt mục tiêu hàng ngày!';

  @override
  String get health_almost_there => 'Gần đạt rồi! Một chút nữa thôi.';

  @override
  String get health_keep_moving => 'Tiếp tục vận động để đạt mục tiêu.';

  @override
  String get health_good_morning => 'Chào buổi sáng';

  @override
  String get health_good_afternoon => 'Chào buổi chiều';

  @override
  String get health_good_evening => 'Chào buổi tối';

  @override
  String get health_good_night => 'Chúc ngủ ngon';

  @override
  String get health_bpm => 'BPM';

  @override
  String get health_kcal => 'kcal';

  @override
  String get health_meters => 'm';

  @override
  String get health_kilometers => 'km';

  @override
  String get health_steps_unit => 'bước';

  @override
  String get health_hours => 'giờ';

  @override
  String get health_minutes => 'phút';

  @override
  String get health_ml => 'ml';

  @override
  String get health_kg => 'kg';

  @override
  String get health_lb => 'lb';

  @override
  String get health_exercise => 'Bài tập';

  @override
  String get health_intensity_low => 'Thấp';

  @override
  String get health_intensity_moderate => 'Vừa phải';

  @override
  String get health_intensity_high => 'Cao';

  @override
  String get health_intensity_extreme => 'Rất cao';

  @override
  String get health_activity_balance => 'CÂN BẰNG HOẠT ĐỘNG';

  @override
  String get health_balance_moving_much =>
      'Bạn vận động rất nhiều! Số bước chân thật tuyệt.';

  @override
  String get health_balance_optimal =>
      'Phân bổ bài tập của bạn hôm nay nhìn rất cân bằng.';

  @override
  String get health_weekly_trends => 'XU HƯỚNG TUẦN';

  @override
  String get health_avg_steps => 'Bước TB';

  @override
  String get health_avg_sleep => 'Ngủ TB';

  @override
  String get health_avg_hr => 'HR TB';

  @override
  String get health_insights_title => 'NHẬN ĐỊNH';

  @override
  String get health_insights => 'Nhận định';

  @override
  String get health_insight_above_avg => 'Trên trung bình';

  @override
  String get health_insight_keep_pushing => 'Tiếp tục cố gắng';

  @override
  String get health_insight_activity_higher =>
      'Mức độ hoạt động của bạn cao hơn trung bình 7 ngày qua.';

  @override
  String health_insight_activity_lower(int steps) {
    return 'Hãy thử đi dạo để đạt mức trung bình hàng ngày là $steps bước.';
  }

  @override
  String get health_insight_goal_reached =>
      'Đã đạt mục tiêu! Bạn hoạt động rất hiệu quả hôm nay.';

  @override
  String health_insight_goal_percent(String percent) {
    return 'Bạn đã hoàn thành $percent% mục tiêu hàng ngày.';
  }

  @override
  String get health_hydration_title => 'Bù nước';

  @override
  String get health_hydration_track_msg =>
      'Bạn đang đi đúng hướng với mục tiêu uống nước hàng ngày!';

  @override
  String get health_bpm_label => 'nhịp/phút';

  @override
  String get health_hours_label => 'giờ';

  @override
  String get project_title_label => 'Tiêu đề';

  @override
  String get notification_reminder_new => 'Nhắc nhở mới';

  @override
  String get notification_reminder_edit => 'Chỉnh sửa nhắc nhở';

  @override
  String get notification_repeat_label => 'Lặp lại';

  @override
  String get notification_date_label => 'Ngày';

  @override
  String get notification_time_label => 'Giờ';

  @override
  String get notification_save_reminder => 'Lưu nhắc nhở';

  @override
  String get notification_update_reminder => 'Cập nhật';

  @override
  String get notification_category_general => 'Chung';

  @override
  String get notification_category_daily => 'Hàng ngày';

  @override
  String get notification_category_health => 'Sức khỏe';

  @override
  String get notification_category_finance => 'Tài chính';

  @override
  String get notification_category_social => 'Xã hội';

  @override
  String get notification_category_projects => 'Dự án';

  @override
  String get notification_priority_low => 'Thấp';

  @override
  String get notification_priority_normal => 'Bình thường';

  @override
  String get notification_priority_high => 'Cao';

  @override
  String get notification_priority_urgent => 'Khẩn cấp';

  @override
  String get notification_freq_once => 'Một lần';

  @override
  String get notification_freq_daily => 'Hàng ngày';

  @override
  String get notification_freq_weekly => 'Hàng tuần';

  @override
  String get notification_enter_title_snack => 'Vui lòng nhập tiêu đề';

  @override
  String get nutri_trends_title => 'Xu hướng dinh dưỡng';

  @override
  String get nutri_weekly_avg => 'Trung bình tuần';

  @override
  String get nutri_insights_title => 'Nhận định dinh dưỡng';

  @override
  String get nutri_advice_low_protein =>
      'Lượng protein của bạn hơi thấp trong tuần này. Hãy thử thêm trứng hoặc thịt nạc.';

  @override
  String get nutri_advice_high_cal =>
      'Bạn đã vượt hạn mức calo gần đây. Hãy cân nhắc các bữa ăn nhẹ hơn vào ngày mai.';

  @override
  String get nutri_advice_good_job =>
      'Tuyệt vời! Bạn đang duy trì sự cân bằng tốt và bám sát mục tiêu.';

  @override
  String get nutri_advice_more_water =>
      'Đừng quên uống nước. Uống đủ nước giúp cải thiện trao đổi chất.';

  @override
  String get nutri_weekly_calories_chart => 'Calo hàng tuần';

  @override
  String get nutri_macro_distribution => 'Phân bổ dinh dưỡng';

  @override
  String get nutrition_dashboard => 'Bảng điều khiển dinh dưỡng';

  @override
  String get nutri_total => 'Tổng cộng';

  @override
  String get nutri_protein => 'Đạm';

  @override
  String get nutri_carbs => 'Tinh bột';

  @override
  String get nutri_fat => 'Chất béo';

  @override
  String get nutri_today => 'Hôm nay';

  @override
  String get nutri_no_meals => 'Chưa có bữa ăn nào được ghi nhận';

  @override
  String get nutri_kcal => 'kcal';

  @override
  String get nutri_cal => 'cal';

  @override
  String get todays_gains => 'Điểm Hôm Nay';

  @override
  String get health_metrics_steps => 'Bước chân';

  @override
  String get health_metrics_heart_rate => 'Nhịp tim';

  @override
  String get health_metrics_sleep => 'Giấc ngủ';

  @override
  String get health_metrics_water => 'Nước';

  @override
  String get health_metrics_exercise => 'Bài tập';

  @override
  String get health_metrics_focus => 'Tập trung';

  @override
  String get health_metrics_distance => 'Khoảng cách';

  @override
  String get health_metrics_calories => 'Calo';

  @override
  String get health_metrics_active_time => 'Thời gian hoạt động';

  @override
  String get health_metrics_calories_burned => 'Calo đã đốt';

  @override
  String get health_metrics_weight => 'Cân nặng';

  @override
  String get health_metrics_net_calories => 'Calo thực';

  @override
  String get health_metrics_calories_consumed => 'Calo nạp';

  @override
  String health_metrics_detail_coming_soon(String name) {
    return 'Trang chi tiết cho $name sắp ra mắt!';
  }

  @override
  String get widget_delete_title => 'Xóa Widget';

  @override
  String widget_delete_msg(String name) {
    return 'Bạn có chắc chắn muốn xóa \"$name\"?';
  }

  @override
  String get cancel => 'HỦY';

  @override
  String get delete => 'XÓA';

  @override
  String get health_subtitle_current_weight => 'Cân nặng hiện tại';

  @override
  String get health_ml_label => 'ml';

  @override
  String health_subtitle_goal_ml(int goal) {
    return 'Mục tiêu: $goal ml';
  }

  @override
  String get health_min_label => 'phút';

  @override
  String health_subtitle_goal_min(int goal) {
    return 'Mục tiêu: $goal phút';
  }

  @override
  String get health_heart_resting => 'Lúc nghỉ';

  @override
  String get health_heart_normal => 'Bình thường';

  @override
  String get health_heart_elevated => 'Hơi cao';

  @override
  String get health_heart_high => 'Cao';

  @override
  String health_subtitle_goal_hours(String goal) {
    return 'Mục tiêu: $goal giờ';
  }

  @override
  String get health_subtitle_study_time => 'Thời gian học tập';

  @override
  String get achievements => 'THÀNH TỰU';

  @override
  String get health_log_food => 'Ghi nhận món ăn';

  @override
  String get health_focus => 'Tập trung';

  @override
  String health_subtitle_goal_steps(int goal) {
    return 'Mục tiêu: $goal bước';
  }

  @override
  String get health_subtitle_health_first => 'Sức khỏe là trên hết';

  @override
  String get health_kcal_label => 'kcal';

  @override
  String get health_subtitle_todays_intake => 'Lượng nạp hôm nay';

  @override
  String get health_steps_label => 'bước';

  @override
  String get health_kg_label => 'kg';

  @override
  String get enter_new_username_hint => 'Nhập tên người dùng mới';

  @override
  String get err_enter_username => 'Vui lòng nhập tên người dùng';

  @override
  String get err_username_length => 'Tên người dùng phải có ít nhất 3 ký tự';

  @override
  String get err_username_invalid_char =>
      'Tên người dùng chứa ký tự không hợp lệ';

  @override
  String get btn_update_username => 'Cập nhật tên người dùng';

  @override
  String get add => 'Thêm';

  @override
  String get canvas_add_custom_widget => 'Thêm Widget tùy chỉnh';

  @override
  String get canvas_add_widget_desc => 'Tạo widget động của riêng bạn';

  @override
  String get ranking => 'XẾP HẠNG';

  @override
  String get relationships => 'MỐI QUAN HỆ';

  @override
  String get err_confirm_password => 'Vui lòng xác nhận mật khẩu';

  @override
  String get err_passwords_not_match => 'Mật khẩu không khớp';

  @override
  String get btn_update_password => 'Cập nhật mật khẩu';

  @override
  String get set_password => 'Đặt mật khẩu';

  @override
  String get msg_username_success => 'Cập nhật tên người dùng thành công';

  @override
  String err_username_failed(String error) {
    return 'Cập nhật tên người dùng thất bại: $error';
  }

  @override
  String get change_username_title => 'Thay đổi tên người dùng';

  @override
  String get unique_username_header => 'Tên người dùng duy nhất';

  @override
  String get username_description =>
      'Chọn một tên người dùng duy nhất để người khác có thể tìm thấy bạn.';

  @override
  String get username_label => 'Tên người dùng';

  @override
  String get msg_no_local_password => 'Chưa đặt mật khẩu cục bộ';

  @override
  String get current_password_label => 'Mật khẩu hiện tại';

  @override
  String get enter_current_password_hint => 'Nhập mật khẩu hiện tại';

  @override
  String get err_enter_current_password => 'Vui lòng nhập mật khẩu hiện tại';

  @override
  String get new_password_label => 'Mật khẩu mới';

  @override
  String get enter_new_password_hint => 'Nhập mật khẩu mới';

  @override
  String get err_enter_password => 'Vui lòng nhập mật khẩu mới';

  @override
  String get err_password_length => 'Mật khẩu phải có ít nhất 6 ký tự';

  @override
  String get confirm_password_label => 'Xác nhận mật khẩu';

  @override
  String get confirm_new_password_hint => 'Xác nhận mật khẩu mới';

  @override
  String get tagline => 'Cuộc sống của bạn, được phối hợp.';

  @override
  String get username_email_hint => 'Tên người dùng hoặc Email';

  @override
  String get password_hint => 'Mật khẩu';

  @override
  String get go_to_gate => 'VÀO CỔNG';

  @override
  String get secure_login => 'BẢO MẬT';

  @override
  String get google_login => 'GMAIL';

  @override
  String get guest_access => 'TRUY CẬP KHÁCH';

  @override
  String get enroll_hub => 'ĐĂNG KÝ';

  @override
  String msg_secure_login_failed(String error) {
    return 'Đăng nhập bảo mật thất bại: $error';
  }

  @override
  String get msg_enter_credentials => 'Vui lòng nhập thông tin đăng nhập';

  @override
  String analysis_user_title(String name) {
    return 'Phân tích của $name';
  }

  @override
  String get performance => 'Hiệu suất';

  @override
  String get overview => 'Tổng quan';

  @override
  String get guest_mode => 'Chế độ Khách';

  @override
  String get sync_desc => 'Dữ liệu của bạn chưa được đồng bộ.';

  @override
  String get sync => 'ĐỒNG BỘ';

  @override
  String percent_to_level(int percent, int level) {
    return '$percent% đến Cấp $level';
  }

  @override
  String progress_to_level(int level) {
    return 'Tiến trình đến Cấp $level';
  }

  @override
  String total_xp(int xp) {
    return 'Tổng XP: $xp';
  }

  @override
  String get scoring_health => 'Sức khỏe';

  @override
  String get scoring_finance => 'Tài chính';

  @override
  String get scoring_social => 'Xã hội';

  @override
  String get scoring_career => 'Sự nghiệp';

  @override
  String get breakdown_steps => 'Bước chân';

  @override
  String get breakdown_diet => 'Chế độ ăn';

  @override
  String get breakdown_exercise => 'Bài tập';

  @override
  String get breakdown_focus => 'Tập trung';

  @override
  String get breakdown_water => 'Nước';

  @override
  String get breakdown_sleep => 'Giấc ngủ';

  @override
  String get breakdown_contacts => 'Liên lạc';

  @override
  String get breakdown_affection => 'Tình cảm';

  @override
  String get breakdown_quests => 'Nhiệm vụ';

  @override
  String get breakdown_accounts => 'Tài khoản';

  @override
  String get breakdown_assets => 'Tài sản';

  @override
  String get breakdown_tasks => 'Công việc';

  @override
  String get breakdown_projects => 'Dự án';

  @override
  String get breakdown_system => 'HỆ THỐNG';

  @override
  String get score_balance => 'CÂN BẰNG ĐIỂM SỐ';

  @override
  String get err_verification_failed => 'Xác minh mật khẩu hiện tại thất bại';

  @override
  String err_unexpected(String error) {
    return 'Đã xảy ra lỗi không mong muốn: $error';
  }

  @override
  String get msg_password_success => 'Cập nhật mật khẩu thành công';

  @override
  String get msg_password_requirement =>
      'Vui lòng nhập mật khẩu hiện tại để tiếp tục.';

  @override
  String get security_title => 'Bảo mật';

  @override
  String get change_password => 'Thay đổi mật khẩu';

  @override
  String get personal_info_title => 'Thông tin cá nhân';

  @override
  String get bio => 'Tiểu sử';

  @override
  String get personal_info_identification => 'Định danh';

  @override
  String get first_name_label => 'Tên';

  @override
  String get last_name_label => 'Họ';

  @override
  String get email_label => 'Email';

  @override
  String get phone_number_label => 'Số điện thoại';

  @override
  String get personal_info_professional_matrix => 'Mạng lưới chuyên nghiệp';

  @override
  String get role_label => 'Vai trò';

  @override
  String get organization_label => 'Tổ chức';

  @override
  String get personal_info_education_node => 'Học vấn';

  @override
  String get institution_label => 'Học viện';

  @override
  String get education_level_label => 'Trình độ học vấn';

  @override
  String get personal_info_location => 'Vị trí';

  @override
  String get country_label => 'Quốc gia';

  @override
  String get city_label => 'Thành phố';

  @override
  String get personal_info_digital => 'Tài khoản số';

  @override
  String get github_label => 'GitHub';

  @override
  String get linkedin_label => 'LinkedIn';

  @override
  String get personal_web_label => 'Website';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get msg_err_not_authenticated => 'Chưa xác thực';

  @override
  String get msg_personal_info_saved => 'Đã lưu thông tin cá nhân';

  @override
  String msg_err_save_failed(String error) {
    return 'Lưu thay đổi thất bại: $error';
  }

  @override
  String get msg_avatar_updated => 'Cập nhật ảnh đại diện thành công';

  @override
  String get msg_avatar_cancelled => 'Đã hủy cập nhật ảnh đại diện';

  @override
  String msg_err_upload_failed(String error) {
    return 'Tải lên thất bại: $error';
  }

  @override
  String get msg_cover_updated => 'Cập nhật ảnh bìa thành công';

  @override
  String get msg_cover_cancelled => 'Đã hủy cập nhật ảnh bìa';

  @override
  String get change_cover => 'Thay đổi ảnh bìa';

  @override
  String get social_share_msg => 'Xem tiến trình của tôi trên Ice Gate!';

  @override
  String get record_achievement => 'Ghi nhận thành tích';

  @override
  String get update_achievement => 'Cập nhật thành tích';

  @override
  String get achievement_title_label => 'Tiêu đề thành tích';

  @override
  String get system_exp_reward => 'Thưởng EXP';

  @override
  String get image_url => 'URL hình ảnh';

  @override
  String get achievement_recorded => 'THÀNH TỰU ĐÃ ĐƯỢC GHI LẠI';

  @override
  String get achievement_updated => 'THÀNH TỰU ĐÃ ĐƯỢC CẬP NHẬT';

  @override
  String system_error(String error) {
    return 'LỖI HỆ THỐNG: $error';
  }

  @override
  String get record_feat => 'Thêm Thành Tựu';

  @override
  String get update_feat => 'Cập Nhập';

  @override
  String get import_from_contacts => 'Nhập từ danh bạ';

  @override
  String get add_manually => 'Thêm thủ công';

  @override
  String get register_agent => 'ĐĂNG KÝ THÀNH VIÊN';

  @override
  String get first_name => 'Tên';

  @override
  String get last_name => 'Họ';

  @override
  String get relationship_type => 'LOẠI MỐI QUAN HỆ';

  @override
  String get create_link => 'TẠO LIÊN KẾT';

  @override
  String get social_dashboard => 'Bảng điều khiển xã hội';

  @override
  String get social => 'Xã hội';

  @override
  String get social_rank_first => 'HẠNG NHẤT';

  @override
  String get social_rank_second => 'HẠNG NHÌ';

  @override
  String get social_rank_third => 'HẠNG BA';

  @override
  String get no_data_global_board =>
      'Không có dữ liệu trong Bảng xếp hạng thế giới.';

  @override
  String get current_rankings => 'Xếp hạng hiện tại';

  @override
  String updated_time_ago(String time) {
    return 'CẬP NHẬT $time TRƯỚC';
  }

  @override
  String get social_points_suffix => ' điểm';

  @override
  String get social_tier_veteran => 'Bậc Lão làng';

  @override
  String get social_empty_network => 'Mạng lưới của bạn đang trống';

  @override
  String get social_trust_level => 'Mức độ tin cậy';

  @override
  String level(int level) {
    return 'Cấp $level';
  }

  @override
  String get social_bond_strengthened => 'Mối liên kết được thắt chặt!';

  @override
  String get social_options => 'Tùy chọn xã hội';

  @override
  String get social_manage_title => 'Quản lý liên kết';

  @override
  String get social_change_friend => 'Đặt là Bạn bè';

  @override
  String get social_change_dating => 'Đặt là Hẹn hò';

  @override
  String get social_change_family => 'Đặt là Người thân';

  @override
  String get social_delete_bond => 'Xóa liên kết';

  @override
  String get social_no_achievements => 'Chưa có thành tích nào';

  @override
  String get social_feat => 'Chiến công';

  @override
  String get add_app_plugin => 'Thêm Plugin ứng dụng';

  @override
  String get plugin_desc => 'Thêm tính năng mới cho giao diện của bạn';

  @override
  String get homepage_four_life_elements => '4 khía cạnh';

  @override
  String get done => 'Hoàn tất';

  @override
  String get edit => 'Sửa';

  @override
  String get analysis => 'Phân tích';

  @override
  String get total_users => 'Tổng người dùng';

  @override
  String get mutual => 'Chung';

  @override
  String get friends => 'Bạn bè';

  @override
  String get projs => 'Dự án';

  @override
  String get active => 'Đang chạy';

  @override
  String get tasks => 'Nhiệm vụ';

  @override
  String get homepage_plugin => 'Plugin';

  @override
  String get health => 'Sức khỏe';

  @override
  String get finance => 'Tài chính';

  @override
  String get projects => 'Dự án';

  @override
  String get kcal_consume => 'Kcal tiêu thụ';

  @override
  String get hr => 'Nhịp tim';

  @override
  String get spent => 'Đã chi';

  @override
  String get income => 'Thu nhập';

  @override
  String get savings => 'Tiết kiệm';

  @override
  String get balance => 'Số dư';

  @override
  String get steps => 'Bước chân';

  @override
  String get sleep => 'Ngủ';

  @override
  String get username => 'Tên người dùng';

  @override
  String get goal_target_evolution => 'Tiến hóa mục tiêu';

  @override
  String get goal_mission => 'NHIỆM VỤ';

  @override
  String get goal_mission_desc =>
      'Điều chỉnh các mục tiêu hàng ngày để tối ưu hóa hiệu suất cuộc sống.';

  @override
  String get goal_step_target => 'Mục tiêu bước chân';

  @override
  String get goal_calorie_limit => 'Hạn mức Calo';

  @override
  String get goal_water_target => 'Mục tiêu nước';

  @override
  String get goal_focus_target => 'Mục tiêu tập trung';

  @override
  String get goal_exercise_target => 'Mục tiêu bài tập';

  @override
  String get goal_sleep_target => 'Mục tiêu giấc ngủ';

  @override
  String get unit_kcal => 'kcal';

  @override
  String get unit_ml => 'ml';

  @override
  String get unit_min => 'phút';

  @override
  String get unit_hours => 'giờ';

  @override
  String get scoring_rules_title => 'Quy tắc tính điểm';

  @override
  String rule_health_steps(int steps) {
    return 'Nhận điểm cho mỗi $steps bước chân.';
  }

  @override
  String rule_health_calories(int calories, int limit) {
    return 'Nhận $calories điểm thưởng nếu bạn nạp ít hơn $limit kcal.';
  }

  @override
  String get rule_health_auto =>
      'Điểm sức khỏe được tính tự động dựa trên dữ liệu đồng bộ.';

  @override
  String rule_career_project(int points) {
    return '$points điểm cho mỗi dự án hoàn thành.';
  }

  @override
  String rule_career_task(int points) {
    return '$points điểm cho mỗi nhiệm vụ hoàn thành.';
  }

  @override
  String rule_career_bonus_5(int bonus) {
    return 'Thưởng $bonus điểm khi hoàn thành 5 nhiệm vụ trong một dự án.';
  }

  @override
  String rule_career_bonus_10(int bonus) {
    return 'Thưởng $bonus điểm khi hoàn thành trên 10 nhiệm vụ trong một dự án.';
  }

  @override
  String rule_career_bonus_doc(int bonus) {
    return 'Thưởng $bonus điểm cho dự án có tài liệu chi tiết.';
  }

  @override
  String rule_career_bonus_week(int bonus) {
    return 'Thưởng $bonus điểm cho dự án hoàn thành trong vòng một tuần.';
  }

  @override
  String rule_finance_savings(int points, int milestone) {
    return 'Nhận $points điểm cho mỗi \$$milestone tiết kiệm được.';
  }

  @override
  String rule_finance_investment(int points, int threshold) {
    return 'Nhận $points điểm cho các khoản đầu tư có lợi nhuận trên $threshold%.';
  }

  @override
  String get rule_finance_auto =>
      'Điểm tài chính cập nhật mỗi 24 giờ dựa trên thay đổi số dư.';

  @override
  String rule_social_contact(int points) {
    return '$points điểm cho mỗi liên lạc ý nghĩa mới được thêm.';
  }

  @override
  String rule_social_affection(int points, int unit) {
    return '$points điểm cho mỗi $unit mức độ tình cảm đạt được.';
  }

  @override
  String get rule_social_maintain =>
      'Duy trì các mối liên kết để ngăn chặn việc giảm điểm theo thời gian.';

  @override
  String get how_it_works => 'Cách thức hoạt động';

  @override
  String get scoring_intro =>
      'Hệ thống điểm số của chúng tôi đánh giá hiệu suất hàng ngày của bạn qua bốn trụ cột chính. Điểm được thưởng dựa trên tính nhất quán, các mốc quan trọng và hiệu quả.';

  @override
  String get scoring_footer =>
      'Điểm số được xử lý bởi Life Orchestration Engine (LOE) vào mỗi nửa đêm giờ UTC.';

  @override
  String get canvas_notification_center => 'Trung tâm thông báo';

  @override
  String get canvas_notification_desc =>
      'Điều khiển và kiểm soát mọi thông báo hệ thống';

  @override
  String get canvas_goal_center => 'Tiến hóa mục tiêu';

  @override
  String get canvas_goal_desc => 'Điều chỉnh các tham số mục tiêu chiến thuật';

  @override
  String get gps_permissions_required => 'Yêu cầu quyền GPS để theo dõi.';

  @override
  String get gps_title => 'THEO DÕI GPS';

  @override
  String get gps_disconnect_tooltip => 'Ngắt kết nối thiết bị';

  @override
  String get gps_map_tab => 'Bản đồ';

  @override
  String get gps_data_tab => 'Dữ liệu';

  @override
  String get gps_system_scan => 'QUÉT HỆ THỐNG';

  @override
  String get gps_connect_receiver => 'Kết nối bộ thu GPS';

  @override
  String get gps_connected => 'Đã kết nối';

  @override
  String get gps_not_connected => 'Chưa kết nối';

  @override
  String get gps_history => 'Lịch sử vị trí';

  @override
  String get gps_label_latitude => 'Vĩ độ';

  @override
  String get gps_label_longitude => 'Kinh độ';

  @override
  String get gps_label_altitude => 'Độ cao';

  @override
  String get gps_label_speed => 'Tốc độ';

  @override
  String get gps_label_heading => 'Hướng';

  @override
  String get gps_label_accuracy => 'Độ chính xác';

  @override
  String get gps_label_time => 'Thời gian';

  @override
  String get gps_waiting_signal => 'Đang chờ tín hiệu GPS';

  @override
  String get gps_waiting_desc =>
      'Đảm bảo bộ thu có hướng nhìn thẳng lên bầu trời.';

  @override
  String get gps_disconnect_title => 'Ngắt kết nối GPS?';

  @override
  String get gps_disconnect_msg =>
      'Bạn có chắc chắn muốn ngắt kết nối với bộ thu GPS?';

  @override
  String get gps_permissions_denied => 'Quyền truy cập GPS bị từ chối.';

  @override
  String get gps_status_tracking => 'Đang theo dõi';

  @override
  String get gps_status_paused => 'Tam dừng';

  @override
  String get gps_btn_start => 'Bắt đầu';

  @override
  String get gps_btn_pause => 'Tạm dừng';

  @override
  String get gps_btn_stop => 'Dừng';

  @override
  String get close => 'Đóng';

  @override
  String get health_analysis_title => 'Phân tích sức khỏe';

  @override
  String get health_no_data => 'Không có dữ liệu sức khỏe';

  @override
  String get health_metabolism_active => 'Năng động';

  @override
  String get health_metabolism_normal => 'Bình thường';

  @override
  String get health_intensity_optimal => 'Tối ưu';

  @override
  String get health_analysis_performance => 'PHÂN TÍCH HIỆU SUẤT';

  @override
  String get health_efficiency => 'Hiệu suất';

  @override
  String get health_consistency => 'Tính nhất quán';

  @override
  String get health_consistency_high => 'Cao';

  @override
  String get health_consistency_medium => 'Trung bình';

  @override
  String get health_consistency_low => 'Thấp';

  @override
  String get health_metabolism => 'Trao đổi chất';

  @override
  String get health_intensity => 'Cường độ';

  @override
  String get health_water_log => 'Ghi nhận nước';

  @override
  String get health_water_goal => 'Mục tiêu ngày';

  @override
  String get health_water_points => 'Điểm tích lũy';

  @override
  String get health_water_left => 'Cần nạp thêm';

  @override
  String get health_stay_hydrated => 'Hãy uống đủ nước hôm nay!';

  @override
  String get health_custom_intake => 'Lượng nước tùy chỉnh';

  @override
  String get health_unit_ml => 'ml';

  @override
  String get health_sleep_tracker => 'Theo dõi giấc ngủ';

  @override
  String get health_last_24h_apple => '24 giờ qua qua Apple Health';

  @override
  String get health_last_session => 'PHIÊN GẦN NHẤT';

  @override
  String health_hrs(String hours) {
    return '$hours giờ';
  }

  @override
  String health_quality_stars(String stars) {
    return 'Chất lượng: $stars';
  }

  @override
  String get health_no_sleep_records => 'Chưa có bản ghi giấc ngủ nào';

  @override
  String get health_log_sleep => 'Ghi nhận giấc ngủ';

  @override
  String get health_quality => 'Chất lượng giấc ngủ';

  @override
  String get health_save_session => 'Lưu phiên';

  @override
  String get health_history => 'Lịch sử';

  @override
  String get health_sleep_saved => 'Đã lưu bản ghi giấc ngủ';

  @override
  String get health_activity_tracker => 'Theo dõi hoạt động';

  @override
  String get health_syncing_data => 'Đang đồng bộ dữ liệu Sức khỏe...';

  @override
  String get health_refresh_steps => 'Làm mới bước chân từ HealthKit';

  @override
  String get health_steps_dashboard => 'Bảng điều khiển bước chân';

  @override
  String get health_steps_taken => 'TỔNG SỐ BƯỚC CHÂN';

  @override
  String get health_daily_statistics => 'Thống kê hàng ngày';

  @override
  String get health_lifetime_total => 'Tổng cộng';

  @override
  String get health_remaining => 'Mục tiêu còn lại';

  @override
  String get health_distance => 'Khoảng cách';

  @override
  String get health_active_time => 'Thời gian hoạt động';

  @override
  String get health_latest_apple => 'MỚI NHẤT TỪ HEALTH';

  @override
  String get health_realtime_sync => 'Đồng bộ thời gian thực từ Watch';

  @override
  String get health_zone_resting => 'Lúc nghỉ';

  @override
  String get health_zone_normal => 'Bình thường';

  @override
  String get health_zone_elevated => 'Hơi cao';

  @override
  String get health_zone_high => 'Cao';

  @override
  String get health_zone_very_high => 'Rất cao';

  @override
  String get health_add_reading_desc => 'Thêm một bản ghi bên dưới để bắt đầu';

  @override
  String get health_average => 'Trung bình';

  @override
  String get health_peak => 'Đỉnh';

  @override
  String get health_samples => 'Mẫu';

  @override
  String get health_manual_entry => 'Nhập thủ công';

  @override
  String get health_enter_bpm => 'Nhập BPM';

  @override
  String get health_quick_entry => 'Nhập nhanh';

  @override
  String get health_exercise_analysis => 'Phân tích bài tập';

  @override
  String get health_no_exercise_history => 'Không tìm thấy lịch sử bài tập';

  @override
  String get health_weekly_minutes => 'SỐ PHÚT HÀNG TUẦN';

  @override
  String get health_intensity_distribution => 'Phân bổ cường độ';

  @override
  String get health_type_distribution => 'Phân bổ loại hình';

  @override
  String get health_exercise_history => 'Lịch sử bài tập';

  @override
  String get project_mark_done_tooltip => 'Đánh dấu đã hoàn thành';

  @override
  String project_completed_msg(int score) {
    return 'Dự án đã hoàn thành! +$score EXP';
  }

  @override
  String get project_delete_tooltip => 'Xóa dự án';

  @override
  String get project_delete_confirm_title => 'Xóa Dự Án';

  @override
  String project_delete_confirm_msg(String name) {
    return 'Bạn có chắc chắn muốn xóa \"$name\"? Không thể hoàn tác hành động này.';
  }

  @override
  String get project_deleted_msg => 'Đã xóa dự án';

  @override
  String get project_complete_label => 'HOÀN THÀNH';

  @override
  String get project_no_tasks => 'Chưa có nhiệm vụ nào. Nhấn + để thêm.';

  @override
  String get project_notes_label => 'Ghi chú';

  @override
  String get project_no_notes => 'Chưa có ghi chú nào. Nhấn + để tạo.';

  @override
  String get project_no_notes_list => 'Không tìm thấy ghi chú nào';

  @override
  String get project_finance_label => 'Tài chính';

  @override
  String get project_no_finance =>
      'Chưa có bản ghi tài chính nào cho dự án này.';

  @override
  String get project_add_task_title => 'Nhiệm vụ mới';

  @override
  String get project_task_title_hint => 'Tiêu đề nhiệm vụ';

  @override
  String get project_add_investment_title => 'Thêm khoản đầu tư';

  @override
  String get project_add_investment_desc =>
      'Ghi nhận chi phí hoặc khoản đầu tư cho dự án này.';

  @override
  String get amount => 'Số tiền';

  @override
  String get description_optional => 'Mô tả (tùy chọn)';

  @override
  String get project_investment_default_desc => 'Đầu tư dự án';

  @override
  String get project_add_investment_btn => 'Thêm khoản đầu tư';

  @override
  String get project_new_note_title => 'Ghi chú mới';

  @override
  String project_last_edited_msg(String date) {
    return 'Chỉnh sửa lần cuối $date';
  }

  @override
  String get project_note_untitled => 'Chưa đặt tên';

  @override
  String get project_unknown_date => 'Không rõ ngày';

  @override
  String get project_delete_note_title => 'Xóa ghi chú';

  @override
  String get project_delete_note_msg =>
      'Bạn có chắc chắn muốn xóa ghi chú này không?';

  @override
  String get project_note_no_content => 'Không có nội dung';

  @override
  String get calorie_tracker => 'Theo dõi Calo';

  @override
  String get net_calories => 'CALO THỰC';

  @override
  String get under_goal => 'Dưới mục tiêu';

  @override
  String get on_track => 'Đúng hướng';

  @override
  String get over_goal => 'Vượt mục tiêu';

  @override
  String goal_kcal(int goal) {
    return 'Mục tiêu: $goal kcal';
  }

  @override
  String percent_of_daily_goal(String percent) {
    return '$percent% mục tiêu hàng ngày';
  }

  @override
  String get consumed => 'Đã nạp';

  @override
  String get burned => 'Đã đốt';

  @override
  String get total_burn => 'Tổng đốt';

  @override
  String get add_food => 'Thêm món ăn';

  @override
  String get lidar_scan => 'Quét LiDAR';

  @override
  String get health_log_exercise => 'Ghi nhận bài tập';

  @override
  String get health_calories_burned_label => 'Lượng calo đã đốt';

  @override
  String added_food_msg(String name, int calories) {
    return 'Đã thêm $name ($calories kcal)';
  }

  @override
  String get lidar_ios_only =>
      'Quét LiDAR chỉ hỗ trợ trên các thiết bị iOS Pro.';

  @override
  String get lidar_completed => 'Quét LiDAR hoàn tất!';

  @override
  String get health_quick_add_exercise => 'Thêm nhanh bài tập';

  @override
  String get health_walking_30min => 'Đi bộ (30 phút)';

  @override
  String get health_running_30min => 'Chạy bộ (30 phút)';

  @override
  String get health_cycling_30min => 'Đạp xe (30 phút)';

  @override
  String get health_swimming_30min => 'Bơi lội (30 phút)';

  @override
  String get health_yoga_30min => 'Yoga (30 phút)';

  @override
  String added_calories_burned(int calories) {
    return 'Đã thêm $calories kcal đã đốt';
  }

  @override
  String get exercise_tracker => 'Theo dõi bài tập';

  @override
  String get daily_routines => 'Thói quen hàng ngày';

  @override
  String get activity_history => 'Lịch sử hoạt động';

  @override
  String get no_activities_recorded => 'Chưa có hoạt động nào được ghi nhận.';

  @override
  String get custom_activity_title => 'HOẠT ĐỘNG TÙY CHỈNH';

  @override
  String get activity_type_label => 'Loại hoạt động (vd: Gym)';

  @override
  String get duration_min_label => 'Thời gian (phút)';

  @override
  String get intensity_label => 'Cường độ';

  @override
  String get log_activity_btn => 'GHI NHẬN HOẠT ĐỘNG';

  @override
  String get app_settings_title => 'Cài đặt';

  @override
  String get account_section => 'Tài khoản';

  @override
  String get preferences_section => 'Tùy chọn';

  @override
  String get about_support_section => 'Thông tin & Hỗ trợ';

  @override
  String get edit_profile => 'Chỉnh sửa hồ sơ';

  @override
  String get edit_profile_subtitle => 'Chi tiết hồ sơ & định danh';

  @override
  String get change_theme => 'Thay đổi giao diện';

  @override
  String get system_notifications => 'Thông báo hệ thống';

  @override
  String get notifications_active => 'Đang bật';

  @override
  String get notifications_paused => 'Đang tạm dừng';

  @override
  String get change_language => 'Thay đổi ngôn ngữ';

  @override
  String get manual => 'Hướng dẫn sử dụng';

  @override
  String get version => 'Phiên bản';

  @override
  String get reset_database_title => 'Đặt lại cơ sở dữ liệu';

  @override
  String get reset_database_msg =>
      'Cảnh báo: Hành động này sẽ xóa toàn bộ dữ liệu cục bộ của bạn. Hành động này không thể hoàn tác.';

  @override
  String get btn_reset_all_data => 'ĐẶT LẠI TOÀN BỘ DỮ LIỆU';

  @override
  String get msg_database_reset_success =>
      'Đã đặt lại cơ sở dữ liệu thành công';

  @override
  String get guest_user => 'Khách';

  @override
  String get msg_sign_in_to_sync => 'Đăng nhập để đồng bộ dữ liệu';

  @override
  String get member_status => 'Thành viên';

  @override
  String get change_username => 'Thay đổi tên người dùng';

  @override
  String get remaining => 'Còn lại';

  @override
  String get notification_manager_title => 'TRUNG TÂM THÔNG BÁO';

  @override
  String get notification_hunter_hub => 'Trung tâm Thợ săn';

  @override
  String get notification_tab_active => 'ĐANG CHẠY';

  @override
  String get notification_tab_reminders => 'NHẮC NHỞ';

  @override
  String get notification_tab_wisdom => 'TRÍ TUỆ';

  @override
  String get notification_ai_no_data => 'Không có dữ liệu chiến thuật.';

  @override
  String get notification_ai_advice => 'LỜI KHUYÊN CHIẾN THUẬT';

  @override
  String get notification_ai_waiting => 'Đang thu thập tình báo...';

  @override
  String get notification_ai_analysis => 'PHÂN TÍCH AI';

  @override
  String get notification_daily_quest => 'NHIỆM VỤ HÀNG NGÀY';

  @override
  String notification_quest_completed_snack(String title, int exp) {
    return 'Đã hoàn thành: $title (+$exp EXP)';
  }

  @override
  String get notification_personal_reminders => 'Nhắc nhở cá nhân';

  @override
  String get notification_add_new => 'THÊM MỚI';

  @override
  String get notification_no_reminders => 'Chưa có nhắc nhở nào.';

  @override
  String get notification_disabled_desc => 'Thông báo hệ thống đang bị tắt.';

  @override
  String get notification_wisdom_board => 'Bảng trí tuệ';

  @override
  String get notification_add_quote => 'THÊM TRÍ TUỆ';

  @override
  String get notification_quote_empty => 'Bảng trí tuệ đang trống.';

  @override
  String get notification_add_wisdom_title => 'Thêm Trí Tuệ';

  @override
  String get notification_wisdom_content => 'Nội dung Trí Tuệ';

  @override
  String get notification_wisdom_author => 'Tác giả';

  @override
  String get notification_inbox_title => 'TRUNG TÂM THÔNG BÁO';

  @override
  String get notification_mission_history => 'Lịch sử nhiệm vụ';

  @override
  String get notification_mission_success => 'NHIỆM VỤ THÀNH CÔNG';

  @override
  String get notification_focus_complete => 'TẬP TRUNG HOÀN TẤT';

  @override
  String get notification_reminder => 'NHẮC NHỞ';

  @override
  String get notification_no_logs => 'LỊCH SỬ TRỐNG';

  @override
  String get notification_empty_desc =>
      'Tất cả các sự kiện hệ thống sẽ được lưu trữ tại đây.';

  @override
  String get finance_add_transaction => 'Ghi nhận giao dịch';

  @override
  String finance_add_type(String type) {
    return 'Thêm $type';
  }

  @override
  String get finance_label_save => 'Tiết kiệm';

  @override
  String get finance_label_spend => 'Chi tiêu';

  @override
  String get finance_label_income => 'Thu nhập';

  @override
  String get finance_tooltip_add_savings => 'Thêm khoản tiết kiệm';

  @override
  String get finance_tooltip_add_expense => 'Thêm khoản chi tiêu';

  @override
  String get finance_tooltip_add_income => 'Thêm khoản thu nhập';

  @override
  String get finance_type_expense => 'Chi tiêu';

  @override
  String get finance_type_income => 'Thu nhập';

  @override
  String get finance_type_savings => 'Tiết kiệm';

  @override
  String get finance_label_amount => 'Số tiền';

  @override
  String get finance_label_category => 'Hạng mục';

  @override
  String get finance_label_description_optional => 'Mô tả (tùy chọn)';

  @override
  String get finance_btn_add => 'Thêm';

  @override
  String get finance_total_net_worth => 'TỔNG TÀI SẢN RÒNG';

  @override
  String finance_monthly_breakdown(String month) {
    return 'Phân bổ $month';
  }

  @override
  String get finance_recent_transactions => 'Giao dịch gần đây';

  @override
  String get finance_no_transactions => 'Chưa có giao dịch nào';

  @override
  String get finance_tap_to_add => 'Nhấn + để thêm giao dịch đầu tiên';

  @override
  String get finance_total_savings => 'Tổng tiết kiệm';

  @override
  String finance_month_spending(String month) {
    return 'Chi tiêu $month';
  }

  @override
  String finance_month_income(String month) {
    return 'Thu nhập $month';
  }

  @override
  String get finance_see_all => 'XEM TẤT CẢ';

  @override
  String get finance_cat_food => 'Ăn uống';

  @override
  String get finance_cat_coffee => 'Cà phê';

  @override
  String get finance_cat_transport => 'Di chuyển';

  @override
  String get finance_cat_software => 'Phần mềm';

  @override
  String get finance_cat_shopping => 'Mua sắm';

  @override
  String get finance_cat_bills => 'Hóa đơn';

  @override
  String get finance_cat_rent => 'Tiền thuê';

  @override
  String get finance_cat_subscriptions => 'Đăng ký dịch vụ';

  @override
  String get finance_cat_entertainment => 'Giải trí';

  @override
  String get finance_cat_health => 'Sức khỏe';

  @override
  String get finance_cat_education => 'Giáo dục';

  @override
  String get finance_cat_investing => 'Đầu tư';

  @override
  String get finance_cat_general => 'Chung';

  @override
  String get finance_cat_salary => 'Lương';

  @override
  String get finance_cat_freelance => 'Làm tự do';

  @override
  String get finance_cat_investment => 'Đầu tư';

  @override
  String get finance_cat_gift => 'Quà tặng';

  @override
  String get finance_cat_bonus => 'Thưởng';

  @override
  String get finance_cat_emergency => 'Khẩn cấp';

  @override
  String get finance_cat_goal => 'Mục tiêu';

  @override
  String get finance_cat_retirement => 'Hưu trí';

  @override
  String get finance_cat_crypto => 'Tiền điện tử';

  @override
  String get finance_cat_stock => 'Chứng khoán';

  @override
  String get finance_cat_real_estate => 'Bất động sản';

  @override
  String get finance_power_points => 'SỨC MẠNH TÀI CHÍNH';

  @override
  String get finance_goal => 'Mục tiêu';

  @override
  String get finance_efficiency => 'Hiệu suất';

  @override
  String get finance_savings_rate => 'Tỷ lệ tiết kiệm';

  @override
  String get finance_points_desc => 'Điểm tích lũy từ tài sản ròng';

  @override
  String get ssh_new_session => 'Phiên SSH mới';

  @override
  String get ssh_host_label => 'IP Máy Chủ hoặc Tên Miền';

  @override
  String get ssh_port_label => 'Cổng';

  @override
  String get ssh_user_label => 'Tên Người Dùng';

  @override
  String get ssh_pass_label => 'Mật Khẩu hoặc Khoá';

  @override
  String get ssh_connect => 'Kết Nối';

  @override
  String get ssh_ask_ai => 'Hỏi AI';

  @override
  String get ssh_ask_ai_desc => 'Mô tả điều bạn muốn thực hiện...';

  @override
  String get ssh_generate => 'Tạo Lệnh';

  @override
  String get ssh_type_command => 'Nhập lệnh...';

  @override
  String get ssh_disconnect => 'Ngắt Kết Nối';

  @override
  String get ssh_search_hint => 'Tìm kiếm...';

  @override
  String get journal => 'Nhật ký';

  @override
  String get social_notes => 'Ghi chú xã hội';

  @override
  String get btn_send_feedback => 'Gửi phản hồi';

  @override
  String get feedback_subtitle => 'Báo lỗi hoặc đề xuất tính năng mới';
}
