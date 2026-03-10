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
  String get homepage_four_life_elements => '4 phía cạnh';

  @override
  String get homepage_plugin => 'Plugin';

  @override
  String get record_achievement => 'GHI LẠI THÀNH TỰU';

  @override
  String get update_achievement => 'CẬP NHẬT THÀNH TỰU';

  @override
  String get achievement_title_label =>
      'Tiêu đề thành tựu (VD: Đu dây trong 2h)';

  @override
  String get system_exp_reward => 'Thưởng EXP hệ thống';

  @override
  String get image_url => 'URL hình ảnh';

  @override
  String get cancel => 'HỦY';

  @override
  String get achievement_recorded => 'THÀNH TỰU ĐÃ ĐƯỢC GHI LẠI';

  @override
  String get achievement_updated => 'THÀNH TỰU ĐÃ ĐƯỢC CẬP NHẬT';

  @override
  String system_error(String error) {
    return 'LỖI HỆ THỐNG: $error';
  }

  @override
  String get record_feat => 'GHI LẠI CÔNG TRẠNG';

  @override
  String get update_feat => 'CẬP NHẬT CÔNG TRẠNG';

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
  String get ranking => 'XẾP HẠNG';

  @override
  String get relationships => 'MỐI QUAN HỆ';

  @override
  String get achievements => 'THÀNH TỰU';

  @override
  String get current_rankings => 'Xếp hạng hiện tại';

  @override
  String updated_time_ago(String time) {
    return 'CẬP NHẬT $time TRƯỚC';
  }

  @override
  String get no_data_global_board =>
      'Không có dữ liệu trong Bảng xếp hạng thế giới.';

  @override
  String get calorie_tracker => 'Bộ theo dõi calo';

  @override
  String get nutrition_dashboard => 'Bảng điều khiển dinh dưỡng';

  @override
  String get net_calories => 'Calo thực';

  @override
  String goal_kcal(int goal) {
    return 'Mục tiêu: $goal kcal';
  }

  @override
  String get under_goal => 'Dưới mục tiêu';

  @override
  String get on_track => 'Đúng mục tiêu';

  @override
  String get over_goal => 'Vượt mục tiêu';

  @override
  String percent_of_daily_goal(String percent) {
    return '$percent% mục tiêu hàng ngày';
  }

  @override
  String get consumed => 'Đã nạp';

  @override
  String get burned => 'Đã đốt';

  @override
  String get remaining => 'Còn lại';

  @override
  String get total_burn => 'Tổng đốt';

  @override
  String get add_food => 'Thêm món ăn';

  @override
  String get lidar_scan => 'Quét LiDAR';

  @override
  String get log_exercise => 'Ghi lại bài tập';

  @override
  String get calories_burned_label => 'Lượng calo đã đốt';

  @override
  String get quick_add_exercise => 'Thêm nhanh bài tập';

  @override
  String added_food_msg(String name, int cal) {
    return 'Đã thêm $name ($cal kcal)';
  }

  @override
  String get lidar_ios_only => 'Quét LiDAR chỉ có trên thiết bị iOS.';

  @override
  String get lidar_completed => 'Quét LiDAR hoàn tất! Đang xử lý dữ liệu...';

  @override
  String level(int level) {
    return 'Cấp $level';
  }

  @override
  String progress_to_level(int level) {
    return 'Tiến trình đến Cấp $level';
  }

  @override
  String get analysis => 'Phân tích';

  @override
  String get health => 'Sức khỏe';

  @override
  String get finance => 'Tài chính';

  @override
  String get social => 'Xã hội';

  @override
  String get projects => 'Dự án';

  @override
  String get steps => 'Bước chân';

  @override
  String get kcal_consume => 'Calo nạp';

  @override
  String get sleep => 'Ngủ';

  @override
  String get hr => 'Nhịp tim';

  @override
  String get balance => 'Số dư';

  @override
  String get spent => 'Đã chi';

  @override
  String get income => 'Thu nhập';

  @override
  String get savings => 'Tiết kiệm';

  @override
  String get total_users => 'Tổng người dùng';

  @override
  String get friends => 'Bạn bè';

  @override
  String get mutual => 'Tương tác';

  @override
  String get username => 'Tên người dùng';

  @override
  String get done => 'Hoàn tất';

  @override
  String get active => 'Hoạt động';

  @override
  String get projs => 'Dự án';

  @override
  String get tasks => 'Nhiệm vụ';

  @override
  String get edit => 'Sửa';

  @override
  String get add_app_plugin => 'Thêm bản mở rộng';

  @override
  String get plugin_desc =>
      'Chọn một bản mở rộng để mở rộng bảng điều khiển của bạn';

  @override
  String get add => 'Thêm';

  @override
  String get canvas_add_custom_widget => 'Thêm Widget tùy chỉnh';

  @override
  String get canvas_add_widget_desc =>
      'Nhập tên và URL của trang web bạn muốn thêm.';

  @override
  String get canvas_notification_center => 'Trung tâm thông báo';

  @override
  String get canvas_notification_desc =>
      'Quản lý thông báo và lịch sử tập trung';

  @override
  String get canvas_goal_center => 'Trung tâm mục tiêu';

  @override
  String get canvas_goal_desc => 'Theo dõi sự phát triển sức khỏe hàng ngày';

  @override
  String get goal_target_evolution => 'MỤC TIÊU PHÁT TRIỂN';

  @override
  String get goal_mission => 'NHIỆM VỤ';

  @override
  String get goal_mission_desc =>
      'Cấu hình các thông số thể chất của bạn để đảm bảo đồng bộ hóa AI tối ưu và hiệu suất thực địa.';

  @override
  String get goal_step_target => 'MỤC TIÊU BƯỚC CHÂN';

  @override
  String get goal_calorie_limit => 'HẠN MỨC CALO';

  @override
  String get goal_water_target => 'MỤC TIÊU NƯỚC';

  @override
  String get goal_focus_target => 'MỤC TIÊU TẬP TRUNG';

  @override
  String get goal_exercise_target => 'MỤC TIÊU TẬP LUYỆN';

  @override
  String get goal_sleep_target => 'MỤC TIÊU NGỦ';

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
  String get scoring_health => '🏃 Sức khỏe';

  @override
  String get scoring_career => '💼 Sự nghiệp (Dự án)';

  @override
  String get scoring_finance => '💰 Tài chính';

  @override
  String get scoring_social => '❤️ Xã hội';

  @override
  String rule_health_steps(int steps) {
    return '1 Điểm cho mỗi $steps bước đi';
  }

  @override
  String rule_health_calories(int points, int limit) {
    return '$points Điểm cho việc duy trì dưới $limit kcal/ngày';
  }

  @override
  String get rule_health_auto =>
      'Điểm tự động cập nhật khi các chỉ số sức khỏe được ghi lại';

  @override
  String rule_career_project(int points) {
    return '$points Điểm cơ bản cho việc hoàn thành dự án';
  }

  @override
  String rule_career_task(int points) {
    return '$points Điểm cho mỗi nhiệm vụ hoàn thành';
  }

  @override
  String rule_career_bonus_5(int points) {
    return '$points Điểm thưởng cho dự án có 5+ nhiệm vụ';
  }

  @override
  String rule_career_bonus_10(int points) {
    return '$points Điểm thưởng cho dự án có 10+ nhiệm vụ';
  }

  @override
  String rule_career_bonus_doc(int points) {
    return '$points Điểm thưởng cho việc có 3+ ghi chú nghiên cứu';
  }

  @override
  String rule_career_bonus_week(int points) {
    return '$points Điểm thưởng cho dự án hoạt động trong 7+ ngày';
  }

  @override
  String rule_finance_savings(int points, int milestone) {
    return '$points Điểm cho mỗi \$$milestone tiết kiệm được (Giá trị tài sản ròng)';
  }

  @override
  String rule_finance_investment(int points, int threshold) {
    return '$points Điểm cho mỗi $threshold% lợi nhuận đầu tư';
  }

  @override
  String get rule_finance_auto =>
      'Điểm cập nhật khi số dư tài khoản và giá trị tài sản thay đổi';

  @override
  String rule_social_contact(int points) {
    return '$points Điểm cho mỗi liên lạc duy nhất được thêm';
  }

  @override
  String rule_social_affection(int points, int unit) {
    return '$points Điểm cho mỗi $unit điểm thân thiết đạt được';
  }

  @override
  String get rule_social_maintain =>
      'Duy trì các mối quan hệ để giữ điểm xã hội của bạn cao';

  @override
  String get how_it_works => 'Cách thức hoạt động';

  @override
  String get scoring_intro =>
      'Hệ thống tính điểm Ice Gate đo lường sự phát triển của bạn qua bốn yếu tố cuộc sống then chốt. Cấp độ toàn cầu của bạn được tính từ tổng số điểm này. Duy trì điểm số cao để mở khóa trạng thái huyền thoại.';

  @override
  String get scoring_footer =>
      'Cân bằng sự phát triển về thể chất, xã hội, tài chính và không gian làm việc để trở thành một Huyền thoại.';

  @override
  String get personal_info_title => 'Thông tin cá nhân';

  @override
  String get personal_info_identification => 'Định danh';

  @override
  String get personal_info_professional_matrix => 'Ma trận nghề nghiệp';

  @override
  String get personal_info_education_node => 'Điểm học vấn';

  @override
  String get personal_info_location => 'Vị trí';

  @override
  String get personal_info_digital => 'Kỹ thuật số';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get save => 'Lưu';

  @override
  String get bio => 'Tiểu sử';

  @override
  String get first_name_label => 'Tên';

  @override
  String get last_name_label => 'Họ';

  @override
  String get email_label => 'eMail';

  @override
  String get phone_number_label => 'Số điện thoại';

  @override
  String get role_label => 'Vai trò';

  @override
  String get organization_label => 'Tổ chức';

  @override
  String get institution_label => 'Học viện';

  @override
  String get education_level_label => 'Trình độ học vấn';

  @override
  String get country_label => 'Quốc gia';

  @override
  String get city_label => 'Thành phố';

  @override
  String get github_label => 'GitHub';

  @override
  String get linkedin_label => 'LinkedIn';

  @override
  String get personal_web_label => 'Web cá nhân';

  @override
  String get msg_personal_info_saved => 'Đã lưu thông tin cá nhân thành công';

  @override
  String msg_err_save_failed(String error) {
    return 'Không thể lưu thay đổi: $error';
  }

  @override
  String get msg_avatar_updated => 'Đã cập nhật ảnh đại diện!';

  @override
  String get msg_avatar_cancelled => 'Đã hủy tải lên ảnh đại diện';

  @override
  String get msg_cover_updated => 'Đã cập nhật ảnh bìa!';

  @override
  String get msg_cover_cancelled => 'Đã hủy tải lên ảnh bìa';

  @override
  String msg_err_upload_failed(String error) {
    return 'Tải lên thất bại: $error';
  }

  @override
  String get msg_err_not_authenticated => 'Lỗi: Chưa xác thực';

  @override
  String get change_cover => 'Thay đổi ảnh bìa';

  @override
  String get change_avatar => 'Thay đổi ảnh đại diện';

  @override
  String analysis_user_title(String name) {
    return 'Phân tích của $name';
  }

  @override
  String get tagline => 'CỔNG VÀO CUỘC SỐNG';

  @override
  String get username_email_hint => 'TÊN ĐĂNG NHẬP / EMAIL';

  @override
  String get password_hint => 'MẬT KHẨU';

  @override
  String get go_to_gate => 'BẮT ĐẦU';

  @override
  String get secure_login => 'BẢO MẬT';

  @override
  String get google_login => 'GOOGLE';

  @override
  String get guest_access => 'KHÁCH TÀI KHOẢN';

  @override
  String get enroll_hub => 'ĐĂNG KÝ NGAY';

  @override
  String get msg_enter_credentials => 'Vui lòng nhập tên đăng nhập và mật khẩu';

  @override
  String msg_secure_login_failed(String error) {
    return 'Đăng nhập bảo mật thất bại: $error';
  }

  @override
  String get performance => 'Hiệu suất';

  @override
  String get overview => 'Tổng quan';

  @override
  String get guest_mode => 'Chế độ khách';

  @override
  String get sync_desc => 'Đồng bộ hóa để lưu lại tiến trình của bạn.';

  @override
  String get sync => 'Đồng bộ';

  @override
  String get score_balance => 'CÂN BẰNG ĐIỂM SỐ';

  @override
  String percent_to_level(int percent, int level) {
    return '$percent% đến cấp $level';
  }

  @override
  String total_xp(int xp) {
    return 'Tổng XP: $xp';
  }

  @override
  String get breakdown_steps => 'BƯỚC CHÂN';

  @override
  String get breakdown_diet => 'CHẾ ĐỘ ĂN';

  @override
  String get breakdown_exercise => 'TẬP LUYỆN';

  @override
  String get breakdown_focus => 'TẬP TRUNG';

  @override
  String get breakdown_water => 'NƯỚC';

  @override
  String get breakdown_sleep => 'NGỦ';

  @override
  String get breakdown_contacts => 'LIÊN LẠC';

  @override
  String get breakdown_affection => 'THÂN THIẾT';

  @override
  String get breakdown_quests => 'NHIỆM VỤ';

  @override
  String get breakdown_accounts => 'TÀI KHOẢN';

  @override
  String get breakdown_assets => 'TÀI SẢN';

  @override
  String get breakdown_tasks => 'NHIỆM VỤ';

  @override
  String get breakdown_projects => 'DỰ ÁN';

  @override
  String get breakdown_system => 'HỆ THỐNG';

  @override
  String get app_settings_title => 'Cài đặt ứng dụng';

  @override
  String get guest_user => 'Khách';

  @override
  String get msg_sign_in_to_sync => 'Đăng nhập để đồng bộ dữ liệu';

  @override
  String get member_status => 'Thành viên';

  @override
  String get account_section => 'Tài khoản';

  @override
  String get edit_profile => 'Chỉnh sửa hồ sơ';

  @override
  String get edit_profile_subtitle => 'Cập nhật tên và ảnh của bạn';

  @override
  String get change_password => 'Đổi mật khẩu';

  @override
  String get change_username => 'Đổi tên đăng nhập';

  @override
  String get preferences_section => 'Tùy chọn';

  @override
  String get change_theme => 'Thay đổi giao diện';

  @override
  String get system_notifications => 'Thông báo hệ thống';

  @override
  String get notifications_active => 'Thông báo đang hoạt động';

  @override
  String get notifications_paused => 'Thông báo đang tạm dừng';

  @override
  String get about_support_section => 'Giới thiệu & Hỗ trợ';

  @override
  String get manual => 'Hướng dẫn sử dụng';

  @override
  String get version => 'Phiên bản';

  @override
  String get reset_database_title => 'Đặt lại cơ sở dữ liệu?';

  @override
  String get reset_database_msg =>
      'Hành động này sẽ xóa vĩnh viễn tất cả dữ liệu cục bộ của bạn bao gồm các phiên tập trung, nhật ký sức khỏe và cài đặt. Hành động này không thể hoàn tác.';

  @override
  String get msg_database_reset_success => 'Đặt lại cơ sở dữ liệu thành công.';

  @override
  String get btn_reset_all_data => 'XÓA TẤT CẢ DỮ LIỆU';

  @override
  String get security_title => 'Bảo mật';

  @override
  String get set_password => 'Thiết lập mật khẩu';

  @override
  String get msg_password_requirement =>
      'Mật khẩu mới của bạn phải có ít nhất 6 ký tự và khác với các mật khẩu trước đó.';

  @override
  String get msg_no_local_password =>
      'Bạn chưa thiết lập mật khẩu cục bộ. Hãy tạo một mật khẩu để bật đăng nhập bằng email/mật khẩu.';

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
  String get err_enter_password => 'Vui lòng nhập mật khẩu';

  @override
  String get err_password_length => 'Mật khẩu phải có ít nhất 6 ký tự';

  @override
  String get confirm_password_label => 'Xác nhận mật khẩu';

  @override
  String get confirm_new_password_hint => 'Xác nhận mật khẩu mới';

  @override
  String get err_confirm_password => 'Vui lòng xác nhận mật khẩu của bạn';

  @override
  String get err_passwords_not_match => 'Mật khẩu không khớp';

  @override
  String get btn_update_password => 'Cập nhật mật khẩu';

  @override
  String get msg_password_success => 'Thiết lập mật khẩu thành công!';

  @override
  String err_unexpected(String error) {
    return 'Đã xảy ra lỗi không mong muốn: $error';
  }

  @override
  String get err_verification_failed =>
      'Xác minh mật khẩu hiện tại thất bại. Vui lòng kiểm tra lại thông tin.';

  @override
  String get change_username_title => 'Đổi tên đăng nhập';

  @override
  String get unique_username_header => 'Tên đăng nhập duy nhất của bạn';

  @override
  String get username_description =>
      'Tên đăng nhập được sử dụng để đăng nhập và định danh bạn trong ứng dụng. Nó phải có ít nhất 3 ký tự.';

  @override
  String get username_label => 'Tên đăng nhập';

  @override
  String get enter_new_username_hint => 'Nhập tên đăng nhập mới';

  @override
  String get err_enter_username => 'Vui lòng nhập tên đăng nhập';

  @override
  String get err_username_length => 'Tên đăng nhập phải có ít nhất 3 ký tự';

  @override
  String get err_username_invalid_char =>
      'Tên đăng nhập không được chứa ký tự \"@\"';

  @override
  String get btn_update_username => 'CẬP NHẬT TÊN ĐĂNG NHẬP';

  @override
  String get msg_username_success => 'Cập nhật tên đăng nhập thành công!';

  @override
  String err_username_failed(String error) {
    return 'Cập nhật tên đăng nhập thất bại: $error';
  }

  @override
  String added_calories_burned(int cal) {
    return 'Đã thêm $cal kcal đã đốt';
  }

  @override
  String get change_language => 'Đổi ngôn ngữ';

  @override
  String get health_insights => 'Thống kê';

  @override
  String get health_log_water => 'Ghi nước';

  @override
  String get health_log_food => 'Ghi thức ăn';

  @override
  String get health_exercise => 'Tập luyện';

  @override
  String get health_focus => 'Tập trung';

  @override
  String get health_log_exercise => 'Ghi bài tập';

  @override
  String get health_calories_burned_label => 'Calo đã đốt';

  @override
  String get health_quick_add_exercise => 'Thêm nhanh bài tập';

  @override
  String get health_walking_30min => 'Đi bộ 30 phút';

  @override
  String get health_running_30min => 'Chạy bộ 30 phút';

  @override
  String get health_cycling_30min => 'Đạp xe 30 phút';

  @override
  String get health_swimming_30min => 'Bơi lội 30 phút';

  @override
  String get health_yoga_30min => 'Yoga 30 phút';

  @override
  String get health_water_log => 'Nhật ký nước';

  @override
  String get health_water_goal => 'MỤC TIÊU';

  @override
  String get health_water_points => 'ĐIỂM';

  @override
  String get health_water_left => 'CÒN LẠI';

  @override
  String health_water_of_ml(int goal) {
    return 'TRÊN $goal ML';
  }

  @override
  String get health_stay_hydrated => 'GIỮ ĐỦ NƯỚC';

  @override
  String get health_custom_intake => 'LƯỢNG TÙY CHỈNH';

  @override
  String get health_unit_ml => 'ML';

  @override
  String get health_sleep_tracker => 'Theo dõi giấc ngủ';

  @override
  String get health_healthkit_sleep => 'Giấc ngủ HealthKit';

  @override
  String get health_last_24h_apple => '24 giờ qua từ Apple Health';

  @override
  String get health_last_session => 'Phiên gần nhất';

  @override
  String get health_no_sleep_records => 'Chưa có phiên giấc ngủ nào.';

  @override
  String get health_log_sleep => 'Ghi giấc ngủ';

  @override
  String get health_bedtime => 'Giờ ngủ';

  @override
  String get health_wake_up => 'Giờ thức';

  @override
  String get health_quality => 'Chất lượng';

  @override
  String get health_save_session => 'Lưu phiên';

  @override
  String get health_history => 'Lịch sử';

  @override
  String get health_sleep_saved => 'Đã lưu phiên giấc ngủ!';

  @override
  String health_hrs(String hours) {
    return '$hours giờ';
  }

  @override
  String health_quality_stars(String stars) {
    return 'Chất lượng: $stars';
  }

  @override
  String get health_activity_tracker => 'Theo dõi hoạt động';

  @override
  String get health_syncing_data => 'Đang đồng bộ dữ liệu sức khỏe...';

  @override
  String get health_refresh_steps => 'Làm mới bước chân';

  @override
  String get health_steps_dashboard => 'Bảng thống kê bước chân';

  @override
  String get health_steps_taken => 'Bước đã đi';

  @override
  String health_percent_completed(String percent) {
    return '$percent% Hoàn thành';
  }

  @override
  String get health_daily_statistics => 'Thống kê hàng ngày';

  @override
  String get health_lifetime_total => 'Tổng tích lũy';

  @override
  String get health_remaining => 'Còn lại';

  @override
  String get health_distance => 'Khoảng cách';

  @override
  String get health_calories => 'Calo';

  @override
  String get health_active_time => 'Thời gian hoạt động';

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
  String get health_metrics_steps => 'Bước chân';

  @override
  String get health_metrics_heart_rate => 'Nhịp tim';

  @override
  String get health_metrics_sleep => 'Giấc ngủ';

  @override
  String get health_metrics_calories_consumed => 'Calo tiêu thụ';

  @override
  String get health_metrics_calories_burned => 'Calo đã đốt';

  @override
  String get health_metrics_net_calories => 'Calo ròng';

  @override
  String get health_metrics_weight => 'Cân nặng';

  @override
  String health_metrics_detail_coming_soon(String name) {
    return 'Trang chi tiết cho $name sắp ra mắt!';
  }

  @override
  String get health_subtitle_todays_intake => 'Lượng nạp hôm nay';

  @override
  String health_subtitle_goal_steps(int goal) {
    return 'Mục tiêu: $goal';
  }

  @override
  String get health_subtitle_current_weight => 'Cân nặng hiện tại';

  @override
  String health_subtitle_goal_ml(int goal) {
    return 'Mục tiêu: $goal ml';
  }

  @override
  String health_subtitle_goal_min(int goal) {
    return 'Mục tiêu: $goal phút';
  }

  @override
  String health_subtitle_goal_hours(String goal) {
    return 'Mục tiêu: $goal giờ';
  }

  @override
  String get health_subtitle_study_time => 'Thời gian học tập';

  @override
  String get health_subtitle_health_first => 'Sức khỏe là trên hết';

  @override
  String get health_heart_resting => 'Lúc nghỉ ngơi';

  @override
  String get health_heart_normal => 'Bình thường';

  @override
  String get health_heart_elevated => 'Hơi cao';

  @override
  String get health_heart_high => 'Cao';
}
