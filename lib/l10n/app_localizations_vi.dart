// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get quick_actions => 'Ghi chú & thời gian';

  @override
  String get new_label => 'Tạo mới';

  @override
  String get my_projects_label => 'Không gian làm việc';

  @override
  String get completed_projects_label => 'Dự án đã xong';

  @override
  String get active_tasks_label => 'Nhiệm vụ đang chạy';

  @override
  String get recent_notes_label => 'Ghi chú gần đây';

  @override
  String get projects_tile_reminders => 'Lời nhắc';

  @override
  String get projects_tile_calendar => 'Lịch';

  @override
  String get projects_tile_sdlc => 'SDLC';

  @override
  String get projects_calendar_projects_created => 'Dự án được tạo';

  @override
  String get projects_calendar_day_empty =>
      'Không có nhiệm vụ hay dự án mới trong ngày này.';

  @override
  String get projects_calendar_day_empty_not_connected =>
      'Chưa kết nối lịch. Dùng “Kết nối lịch” phía trên, rồi đồng bộ.';

  @override
  String projects_calendar_day_empty_other_days(int count) {
    return 'Không có sự kiện trong ngày này. Có $count sự kiện ở ngày khác trong tháng — thử các ô được tô trên lịch.';
  }

  @override
  String get projects_calendar_google_events => 'Google Calendar';

  @override
  String get projects_calendar_reminders => 'Nhắc nhở';

  @override
  String get projects_calendar_connect_google => 'Kết nối Google Calendar';

  @override
  String get projects_calendar_disconnect_google => 'Ngắt Google Calendar';

  @override
  String get projects_calendar_google_connected => 'Đã kết nối Google Calendar';

  @override
  String get projects_calendar_sign_in_failed =>
      'Không thể kết nối Google Calendar';

  @override
  String get projects_calendar_sign_in_cancelled => 'Đã hủy đăng nhập Google';

  @override
  String get projects_calendar_scope_denied =>
      'Chưa cấp quyền Lịch. Hãy cho phép trong tài khoản Google của bạn.';

  @override
  String projects_calendar_api_not_enabled(String projectId) {
    return 'Google Calendar API chưa bật cho app macOS (dự án GCP $projectId). Vào Google Cloud Console → bật \"Google Calendar API\" cho dự án đó, đợi vài phút rồi thử lại.';
  }

  @override
  String get projects_calendar_insufficient_scopes =>
      'Chưa cấp quyền Lịch. Ngắt kết nối Google, kết nối lại và chấp nhận đủ quyền.';

  @override
  String get projects_calendar_connect_hint =>
      'Đăng nhập Google để đồng bộ mọi lịch Google lên màn hình Lịch.';

  @override
  String get projects_calendar_add_reminder => 'Thêm nhắc nhở';

  @override
  String get projects_calendar_add_event => 'Thêm sự kiện';

  @override
  String get projects_calendar_event_title => 'Tiêu đề sự kiện';

  @override
  String get projects_calendar_event_title_required => 'Nhập tiêu đề sự kiện';

  @override
  String get projects_calendar_event_start => 'Bắt đầu';

  @override
  String get projects_calendar_event_end => 'Kết thúc';

  @override
  String get projects_calendar_event_saved => 'Đã lưu sự kiện vào lịch';

  @override
  String projects_calendar_event_moved(String time) {
    return 'Đã chuyển sang $time';
  }

  @override
  String get projects_calendar_event_deleted => 'Đã xóa sự kiện';

  @override
  String get projects_calendar_event_failed => 'Không thể lưu sự kiện';

  @override
  String get projects_calendar_edit_event => 'Sửa sự kiện';

  @override
  String get projects_calendar_delete_event => 'Xóa sự kiện';

  @override
  String get projects_calendar_env_title => 'Kiểm tra bối cảnh';

  @override
  String get projects_calendar_env_ready =>
      'Phù hợp — bạn có thể hoàn thành ngay.';

  @override
  String get projects_calendar_env_caution =>
      'Có thể làm, nhưng vài yếu tố cần lưu ý.';

  @override
  String get projects_calendar_env_not_ready =>
      'Khó hoàn thành lúc này — cân nhắc đổi giờ.';

  @override
  String projects_calendar_env_score(int score) {
    return 'Sẵn sàng $score%';
  }

  @override
  String get projects_calendar_env_start_focus => 'Bắt đầu phiên tập trung';

  @override
  String get projects_calendar_env_past => 'Khung giờ này đã qua';

  @override
  String get projects_calendar_env_too_early => 'Còn hơn 2 giờ nữa mới tới';

  @override
  String get projects_calendar_env_starting_soon => 'Sắp bắt đầu trong 15 phút';

  @override
  String get projects_calendar_env_low_mood => 'Tâm trạng gần đây thấp';

  @override
  String get projects_calendar_env_neutral_mood => 'Tâm trạng trung tính';

  @override
  String get projects_calendar_env_good_mood => 'Tâm trạng hỗ trợ tập trung';

  @override
  String get projects_calendar_env_no_mood => 'Chưa ghi tâm trạng hôm nay';

  @override
  String get projects_calendar_env_heavy_overlap => 'Trùng lịch nhiều';

  @override
  String get projects_calendar_env_some_overlap => 'Có sự kiện trùng giờ';

  @override
  String get projects_calendar_env_focus_fatigue =>
      'Đã tập trung 2+ giờ hôm nay';

  @override
  String get projects_calendar_env_low_sleep => 'Ngủ ít đêm qua';

  @override
  String get projects_calendar_env_good_sleep => 'Ngủ đủ';

  @override
  String get projects_calendar_edit_reminder => 'Sửa nhắc nhở';

  @override
  String get projects_calendar_save => 'Lưu';

  @override
  String get projects_calendar_select_calendar => 'Lịch';

  @override
  String get projects_calendar_tap_day_add_hint =>
      'Chạm lại ngày đã chọn để thêm sự kiện';

  @override
  String get projects_calendar_hold_day_add_hint => 'Giữ ngày để thêm sự kiện';

  @override
  String get projects_calendar_timeline_empty =>
      'Không có sự kiện theo giờ trong ngày';

  @override
  String get projects_calendar_timeline_tap_slot =>
      'Chạm khung giờ để thêm · chạm sự kiện để sửa · kéo đổi giờ (↑↓ + Enter trên desktop, giữ trên mobile)';

  @override
  String get projects_calendar_scroll_for_more => 'Cuộn xem nhiệm vụ';

  @override
  String get projects_calendar_drag_hint_desktop =>
      'Kéo để đổi giờ. Phím mũi tên chỉnh giờ, Enter xác nhận, Escape hủy.';

  @override
  String get projects_calendar_drag_hint_mobile =>
      'Giữ rồi kéo sang khung giờ khác.';

  @override
  String projects_calendar_drag_move_to(String time) {
    return 'Chuyển sang $time';
  }

  @override
  String get projects_calendar_timeline_remove => 'Ẩn khỏi timeline';

  @override
  String projects_calendar_timeline_remove_confirm(String title) {
    return 'Ẩn \"$title\" khỏi timeline ngày này?';
  }

  @override
  String get projects_calendar_day_timeline => 'Dòng thời gian';

  @override
  String get projects_calendar_reminder_title => 'Tiêu đề nhắc nhở';

  @override
  String get projects_calendar_sync_google => 'Đồng bộ sự kiện';

  @override
  String get projects_calendar_all_day => 'Cả ngày';

  @override
  String get projects_calendar_integrations => 'Kết nối lịch';

  @override
  String get projects_calendar_connect_device => 'Kết nối lịch trên máy';

  @override
  String get projects_calendar_connect_apple => 'Kết nối Apple Calendar';

  @override
  String get projects_calendar_disconnect_device => 'Ngắt lịch trên máy';

  @override
  String get projects_calendar_disconnect_apple => 'Ngắt Apple Calendar';

  @override
  String get projects_calendar_device_connected => 'Đã kết nối lịch trên máy';

  @override
  String get projects_calendar_apple_connected => 'Đã kết nối Apple Calendar';

  @override
  String get projects_calendar_device_events => 'Lịch trên máy';

  @override
  String get projects_calendar_apple_events => 'Apple Calendar';

  @override
  String get projects_calendar_device_hint =>
      'Cho phép truy cập Lịch để xem sự kiện từ các lịch trên thiết bị.';

  @override
  String get projects_calendar_sync_device => 'Đồng bộ sự kiện máy';

  @override
  String get projects_calendar_device_denied =>
      'Chưa cấp quyền Lịch. Bật trong Cài đặt.';

  @override
  String get integration_hub_title => 'Trung tâm kết nối';

  @override
  String get integration_hub_subtitle =>
      'Lịch, sức khỏe và thiết bị — một trung tâm kết nối.';

  @override
  String get integration_hub_google_fit => 'Google Fit';

  @override
  String get integration_hub_google_fit_hint =>
      'Dùng chung đăng nhập Google với Lịch và Drive.';

  @override
  String get integration_hub_sensors_section => 'Thiết bị & cảm biến';

  @override
  String get integration_hub_open_sensor_hub => 'Mở Sensor Hub';

  @override
  String get integration_hub_sensor_hub_hint =>
      'Đồng hồ, IoT, SSH và cấu hình Huawei.';

  @override
  String get integration_hub_huawei_sensor_hint =>
      'Cấu hình Huawei trong Sensor Hub trước.';

  @override
  String get projects_calendar_all_calendars_events => 'Mọi lịch';

  @override
  String projects_calendar_synced_count(int count) {
    return 'Đã tải $count sự kiện trong tháng này';
  }

  @override
  String get projects_calendar_sync_empty_month =>
      'Đã kết nối — không có sự kiện trong tháng này. Thử tháng khác hoặc kiểm tra Google Calendar.';

  @override
  String get integration_hub_calendars_section => 'Lịch';

  @override
  String get integration_hub_health_section => 'Sức khỏe';

  @override
  String get integration_hub_notes_section => 'Ghi chú & tài liệu';

  @override
  String get integration_hub_google_drive_hint =>
      'Đồng bộ ghi chú dự án và tệp vault từ Google Drive.';

  @override
  String get integration_hub_notion_hint =>
      'Nhập trang và cơ sở dữ liệu Notion được chia sẻ vào vault.';

  @override
  String get integration_hub_connect => 'Kết nối';

  @override
  String get integration_hub_status_connected => 'Đã kết nối';

  @override
  String get integration_hub_apple_health => 'Apple Health';

  @override
  String get integration_hub_apple_health_hint =>
      'Bước chân, giấc ngủ, nhịp tim từ HealthKit.';

  @override
  String get integration_hub_huawei_health => 'Huawei Health';

  @override
  String get integration_hub_huawei_health_hint =>
      'Đồng bộ từ tài khoản Huawei cloud.';

  @override
  String get integration_hub_phase2_notice =>
      'Lịch và đăng nhập Google hoạt động tại đây. Cấu hình Huawei: dùng Sensor Hub bên dưới.';

  @override
  String get integration_hub_sign_in_required =>
      'Hãy đăng nhập icegate trước, rồi kết nối tích hợp.';

  @override
  String get integration_hub_health_coming_soon =>
      'Nguồn sức khỏe này chưa khả dụng.';

  @override
  String get integration_hub_open => 'Mở trung tâm kết nối';

  @override
  String get projects_tile_focus => 'Tập trung';

  @override
  String get projects_tile_pomodoro => 'Cà chua';

  @override
  String get projects_tile_canvas => 'Bảng ghép';

  @override
  String get projects_tile_whiteboard => 'Bảng trắng';

  @override
  String get projects_whiteboard_clear_title => 'Xóa bảng trắng?';

  @override
  String get projects_whiteboard_clear_message =>
      'Mọi nét vẽ sẽ bị xóa. Không thể hoàn tác.';

  @override
  String get projects_whiteboard_clear_confirm => 'Xóa hết';

  @override
  String get undo => 'Hoàn tác';

  @override
  String get projects_plan_section_title => 'Kế hoạch';

  @override
  String get projects_diagrams_title => 'Sơ đồ dự án';

  @override
  String get projects_diagrams_empty =>
      'Chưa có sơ đồ. Chạm + chọn dự án để vẽ.';

  @override
  String get projects_diagrams_new => 'Sơ đồ mới';

  @override
  String get projects_diagrams_pick_project => 'Chọn dự án';

  @override
  String get projects_diagrams_no_projects => 'Hãy tạo dự án trước.';

  @override
  String get projects_diagrams_steps => 'bước';

  @override
  String get plan_workspace_breadcrumb => 'KHÔNG GIAN • DỰ ÁN';

  @override
  String get plan_schedule_card_title => 'Lịch trình';

  @override
  String get plan_schedule_empty => 'Chưa có bước nào.';

  @override
  String get plan_focus_notes_title => 'Ghi chú tập trung';

  @override
  String get plan_notes_hint => 'Gõ ghi chú tại đây…';

  @override
  String get plan_add_step => 'Thêm bước';

  @override
  String get plan_drop_steps => 'Thả bước vào đây';

  @override
  String get plan_add_first_step => 'Thêm bước đầu tiên';

  @override
  String get plan_add_block_schedule => 'Khối lịch trình';

  @override
  String get plan_add_block_notes => 'Khối ghi chú tập trung';

  @override
  String get plan_add_block_goals => 'Khối mục tiêu';

  @override
  String get plan_add_block_flow => 'Khối quy trình';

  @override
  String get plan_connect_hint =>
      'Chạm block nguồn, rồi chạm block đích để nối.';

  @override
  String get plan_link_added => 'Đã nối block';

  @override
  String get plan_goals_empty => 'Chưa có mục tiêu.';

  @override
  String get plan_add_goal => 'Thêm mục tiêu';

  @override
  String get plan_manage_blocks => 'Quản lý khối';

  @override
  String get projects_tile_social_blocker => 'Chặn mạng xã hội';

  @override
  String get social_shield_turn_on => 'Bật Shield';

  @override
  String get social_shield_subtitle_no_auth =>
      'Chạm dòng để cấp quyền Thời gian sử dụng';

  @override
  String get social_shield_subtitle_pick_apps =>
      'Chạm dòng chọn app — chặn theo quy tắc bên dưới';

  @override
  String get social_shield_subtitle_ready =>
      'Đang bật — chỉ chặn khi quy tắc khớp giờ';

  @override
  String get social_shield_subtitle_off =>
      'Đang tắt — tạm dừng lịch và quy tắc focus';

  @override
  String get social_shield_choose_apps => 'Chọn app cần chặn';

  @override
  String get social_shield_choose_apps_done => 'Chạm để đổi danh sách app';

  @override
  String get social_shield_pick_apps_required =>
      'Chọn ít nhất một app (hoặc tắt Shield).';

  @override
  String get social_shield_apps_saved => 'Đã cập nhật danh sách app chặn.';

  @override
  String get social_shield_unsupported_platform =>
      'Chặn app chỉ có trên iOS và macOS.';

  @override
  String get projects_plugin_open => 'Mở';

  @override
  String get projects_plugin_location_tracker => 'Theo dõi vị trí';

  @override
  String get projects_plugin_live_map => 'Bản đồ trực tiếp';

  @override
  String get projects_remove_plugin_title => 'Gỡ lối tắt?';

  @override
  String projects_remove_plugin_body(String name) {
    return 'Gỡ \"$name\" khỏi lối tắt nhanh?';
  }

  @override
  String get projects_remove_plugin_confirm => 'Gỡ';

  @override
  String get integrations_title => 'Tích hợp';

  @override
  String get integrations_subtitle => 'Quản lý nguồn tài liệu của bạn';

  @override
  String get integrations_active_services => 'Dịch vụ đang bật';

  @override
  String get integrations_total_notes => 'Tổng ghi chú';

  @override
  String get integrations_search_hint => 'Tìm nguồn...';

  @override
  String get integrations_enabled_connections => 'KẾT NỐI ĐANG BẬT';

  @override
  String get integrations_filters => 'Bộ lọc';

  @override
  String get integrations_internal_notes => 'Ghi chú nội bộ';

  @override
  String get integrations_primary_vault => 'Kho chính (cục bộ)';

  @override
  String get integrations_explore => 'Khám phá';

  @override
  String get integrations_google_drive => 'Google Drive';

  @override
  String get integrations_synced_cloud => 'Đã đồng bộ đám mây';

  @override
  String get integrations_cloud_storage => 'Lưu trữ đám mây';

  @override
  String get integrations_sync_now => 'Đồng bộ ngay';

  @override
  String get integrations_connect => 'Kết nối';

  @override
  String get integrations_notion_sync => 'Đồng bộ Notion';

  @override
  String get integrations_database_pipeline => 'Luồng cơ sở dữ liệu';

  @override
  String get integrations_fetch => 'Tải về';

  @override
  String get integrations_setup => 'Thiết lập';

  @override
  String get integrations_slack_docs => 'Tài liệu Slack';

  @override
  String get integrations_shared_channels => 'Kênh dùng chung';

  @override
  String get integrations_notify_me => 'Báo khi có';

  @override
  String get integrations_notion_config_title => 'Cấu hình Notion';

  @override
  String get integrations_notion_secret_label => 'Mã tích hợp nội bộ';

  @override
  String get integrations_save_fetch => 'Lưu & tải về';

  @override
  String get integrations_marketplace_soon => 'Chợ nguồn sắp ra mắt!';

  @override
  String get vault_breadcrumb_root => 'Kho ghi chú';

  @override
  String get vault_section_folders => 'Thư mục';

  @override
  String get vault_section_notes => 'Ghi chú';

  @override
  String get vault_section_media => 'Ảnh & media';

  @override
  String get vault_section_other => 'Tệp khác';

  @override
  String get vault_search_files => 'Tìm trong thư mục…';

  @override
  String get vault_empty_folder => 'Thư mục trống';

  @override
  String vault_stats_folders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thư mục',
      one: '1 thư mục',
    );
    return '$_temp0';
  }

  @override
  String vault_stats_notes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ghi chú',
      one: '1 ghi chú',
    );
    return '$_temp0';
  }

  @override
  String vault_stats_media(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tệp',
      one: '1 tệp',
    );
    return '$_temp0';
  }

  @override
  String get projects_workspace_empty =>
      'Chưa có không gian làm việc nào được thiết lập.';

  @override
  String get projects_workspace_start => 'Bắt đầu ngay';

  @override
  String get project_drive_sync => 'Đồng bộ Mây';

  @override
  String get project_drive_sync_tooltip => 'Đồng bộ với Google Drive';

  @override
  String get project_sync_success => 'Đồng bộ thành công!';

  @override
  String project_sync_failed(String error) {
    return 'Đồng bộ thất bại: $error';
  }

  @override
  String get project_created_msg => 'Đã tạo dự án với đầy đủ thành phần!';

  @override
  String project_create_failed(String error) {
    return 'Lỗi khi tạo dự án: $error';
  }

  @override
  String get create_project_title => 'Tạo Widget Dự án';

  @override
  String get project_name_label => 'Tên Dự án';

  @override
  String get project_name_required => 'Vui lòng nhập tên';

  @override
  String get description => 'Mô tả';

  @override
  String get project_initial_investment_label => 'Đầu tư ban đầu';

  @override
  String get project_internal_path_label => 'Đường dẫn nội bộ (Tùy chọn)';

  @override
  String get create => 'TẠO';

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
  String get health_motivation_engine_title => 'Động cơ động lực';

  @override
  String get health_notification_engine_title => 'Động cơ thông báo';

  @override
  String health_notification_engine_desc(int count) {
    return '$count nhắc nhở đang bật';
  }

  @override
  String get health_motivation_all_done =>
      'Đã chạm mọi mục tiêu hôm nay—đà của bạn đang lên.';

  @override
  String get health_motivation_strong => 'Tiến độ tốt—giữ chuỗi thói quen nhé.';

  @override
  String get health_motivation_mid =>
      'Đang đi đều—thêm một chiến thắng nhỏ nữa.';

  @override
  String get health_motivation_low =>
      'Bắt đầu bằng nước hoặc vài bước chân—từng chút đều có ích.';

  @override
  String get health_motivation_empty =>
      'Đặt mục tiêu và chúng tôi sẽ đồng hành cả ngày.';

  @override
  String get health_update_weight => 'Cập nhật cân nặng';

  @override
  String get health_smart_scale_title => 'Cân thông minh';

  @override
  String get health_smart_scale_desc =>
      'Đồng bộ từ Apple Health hoặc Health Connect (Withings, Eufy, Xiaomi, v.v.)';

  @override
  String get health_smart_scale_sync => 'Đồng bộ cân thông minh';

  @override
  String get health_smart_scale_syncing => 'Đang đồng bộ…';

  @override
  String get health_smart_scale_sync_ok =>
      'Đã đồng bộ cân nặng từ cân thông minh';

  @override
  String get health_smart_scale_sync_empty =>
      'Chưa có dữ liệu. Cân trước, rồi nhấn đồng bộ.';

  @override
  String get health_smart_scale_sync_denied =>
      'Chưa cấp quyền Health. Bật trong Cài đặt.';

  @override
  String get health_smart_scale_desktop =>
      'Đồng bộ cân thông minh chỉ có trên iPhone và Android.';

  @override
  String get health_smart_scale_import => 'Nhập từ cân thông minh';

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
  String get health_insights => 'Sức khoẻ';

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
  String get notification_category_social => 'Tinh thần';

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
  String get nutri_add_meal => 'Thêm bữa ăn';

  @override
  String get nutri_analyzing => 'Đang phân tích...';

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
  String get nutri_what_eat => 'Bạn đã ăn gì?';

  @override
  String get nutri_save_record => 'LƯU HỒ SƠ';

  @override
  String get nutri_info_title => 'THÔNG TIN DINH DƯỠNG';

  @override
  String get nutri_camera => 'Máy ảnh';

  @override
  String get nutri_gallery => 'Bộ sưu tập';

  @override
  String get nutri_delete_meal => 'Xóa bữa ăn';

  @override
  String get nutri_delete_confirm =>
      'Bạn có chắc chắn muốn xóa bữa ăn này không?';

  @override
  String get nutri_meal_deleted => 'Đã xóa bữa ăn';

  @override
  String get nutri_yesterday => 'Hôm qua';

  @override
  String get nutri_ai_saved_retry_later =>
      'Đã lưu bữa ăn trên máy. Máy chủ AI tạm lỗi — chạm Thử lại phân tích trên bảng điều khiển khi hệ thống sẵn sàng.';

  @override
  String get nutri_ai_retry => 'Thử lại phân tích AI';

  @override
  String get nutri_calories_pending => 'Chưa tính calo';

  @override
  String get common_cancel => 'Hủy';

  @override
  String get common_delete => 'Xóa';

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
  String get health_metrics_oxygen_saturation => 'Oxy máu';

  @override
  String get health_spo2_page_title => 'Oxy máu (SpO₂)';

  @override
  String get health_spo2_today => 'Hôm nay';

  @override
  String get health_spo2_chart_section => 'Biểu đồ trong ngày';

  @override
  String get health_spo2_percent_unit => '% SpO₂';

  @override
  String health_spo2_latest(String time) {
    return 'Gần nhất: $time';
  }

  @override
  String health_spo2_target_line(int n) {
    return 'Mục tiêu $n%';
  }

  @override
  String health_spo2_target_row(int n) {
    return 'Mục tiêu: $n%';
  }

  @override
  String get health_spo2_edit_target => 'Đổi mục tiêu';

  @override
  String get health_spo2_target_dialog_title => 'Mục tiêu SpO₂';

  @override
  String get health_spo2_save => 'Lưu';

  @override
  String health_spo2_day_avg(String n) {
    return 'Trung bình ngày: $n%';
  }

  @override
  String get health_spo2_summary_min => 'Thấp nhất';

  @override
  String get health_spo2_summary_max => 'Cao nhất';

  @override
  String get health_spo2_educational_title => 'Thông tin về SpO₂';

  @override
  String get health_spo2_educational_body =>
      'Độ oxi máu từ 95%-100% giúp cơ thể tập trung hơn, cải thiện tâm trạng';

  @override
  String get health_spo2_motivation_peak =>
      'Oxy hóa tuyệt vời—khi SpO₂ cao, tập trung sắc hơn và nhịp thở đều hơn.';

  @override
  String get health_spo2_motivation_high =>
      'Chỉ số mạnh. Oxy ổn định giúp tư duy rõ ràng và tâm trí điềm tĩnh hơn.';

  @override
  String get health_spo2_motivation_on_target =>
      'Bạn đạt mục tiêu—tiếp tục thở nhẹ nhàng.';

  @override
  String get health_spo2_motivation_near =>
      'Gần mục tiêu rồi—vài nhịp thở chậm có thể đưa bạn vào vùng an toàn.';

  @override
  String get health_spo2_motivation_low =>
      'Hôm nay thấp hơn mục tiêu—nghỉ ngơi, uống nước và thở chậm.';

  @override
  String get health_spo2_motivation_empty =>
      'Đeo thiết bị và quay lại sau—lần đo tiếp theo gợi ý sự điềm tĩnh của bạn.';

  @override
  String get health_metrics_air_quality => 'AQI';

  @override
  String get health_metrics_weather => 'Thời tiết';

  @override
  String get health_air_quality => 'AQI';

  @override
  String get health_weather => 'Thời tiết';

  @override
  String get health_temperature_subtitle => 'Nhiệt độ hiện tại';

  @override
  String get health_temperature_env_title => 'Thời tiết & không khí';

  @override
  String get health_env_condition => 'Điều kiện';

  @override
  String get health_env_particles => 'Hạt bụi';

  @override
  String get health_env_pm25 => 'PM2.5';

  @override
  String get health_env_pm10 => 'PM10';

  @override
  String get health_env_sources => 'Open-Meteo · WAQI';

  @override
  String health_env_updated(String time) {
    return 'Cập nhật $time';
  }

  @override
  String get health_aqi_unit => 'AQI';

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
  String get health_at_a_glance => 'Tổng quan sức khỏe của bạn.';

  @override
  String get health_analyzing_meal => 'Đang phân tích bữa ăn…';

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
  String get apple_login => 'APPLE';

  @override
  String get enroll_hub => 'ĐĂNG KÝ';

  @override
  String msg_secure_login_failed(String error) {
    return 'Đăng nhập bảo mật thất bại: $error';
  }

  @override
  String get err_invalid_credentials =>
      'Sai email hoặc mật khẩu. Vui lòng thử lại.';

  @override
  String get err_email_not_confirmed =>
      'Vui lòng kiểm tra hộp thư để xác nhận email của bạn.';

  @override
  String get err_user_not_found => 'Không tìm thấy tài khoản với email này.';

  @override
  String get err_network_fail =>
      'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng.';

  @override
  String get err_auth_timeout => 'Đăng nhập quá lâu. Vui lòng thử lại.';

  @override
  String get err_passkey_canceled => 'Đã hủy đăng nhập bằng Passkey.';

  @override
  String get err_google_canceled => 'Đã hủy đăng nhập Google.';

  @override
  String get err_google_failed =>
      'Đăng nhập Google thất bại. Bật Google trên Supabase và thêm web client ID.';

  @override
  String get err_passkey_failed =>
      'Xác thực bảo mật thất bại. Vui lòng thử lại.';

  @override
  String get err_biometric_unsupported =>
      'Thiết bị không hỗ trợ đăng nhập sinh trắc học.';

  @override
  String get err_biometric_disabled =>
      'Đăng nhập sinh trắc học chưa được bật cho tài khoản này.';

  @override
  String get err_too_many_attempts =>
      'Quá nhiều lần thử thất bại. Vui lòng thử lại sau.';

  @override
  String get msg_enter_credentials => 'Vui lòng nhập thông tin đăng nhập';

  @override
  String get forgot_password => 'Quên mật khẩu?';

  @override
  String get forgot_password_title => 'Đặt lại mật khẩu';

  @override
  String get forgot_password_body =>
      'Nhập email tài khoản. Chúng tôi sẽ gửi liên kết để đặt mật khẩu mới.';

  @override
  String get forgot_password_send => 'Gửi liên kết';

  @override
  String get forgot_password_success =>
      'Nếu tồn tại tài khoản với email này, bạn sẽ nhận liên kết đặt lại mật khẩu.';

  @override
  String get err_forgot_password_empty_email => 'Vui lòng nhập địa chỉ email.';

  @override
  String get err_forgot_password_invalid_email => 'Vui lòng nhập email hợp lệ.';

  @override
  String get register_page_title => 'Tạo tài khoản';

  @override
  String get register_username_hint => 'Tên đăng nhập';

  @override
  String get register_first_name => 'Tên';

  @override
  String get register_last_name => 'Họ';

  @override
  String get register_password_confirm => 'Xác nhận mật khẩu';

  @override
  String get btn_create_account => 'Đăng ký';

  @override
  String msg_register_check_email(String email) {
    return 'Chúng tôi đã gửi liên kết xác nhận tới $email. Mở liên kết trong ứng dụng này để hoàn tất đăng ký.';
  }

  @override
  String get msg_resend_confirm_sent =>
      'Nếu địa chỉ hợp lệ, email xác nhận mới đã được gửi.';

  @override
  String get register_resend_email => 'Gửi lại email';

  @override
  String get register_back_to_login => 'Quay lại đăng nhập';

  @override
  String get err_register_password_mismatch => 'Mật khẩu nhập lại không khớp.';

  @override
  String get title_set_new_password => 'Đặt mật khẩu mới';

  @override
  String get msg_password_recovery_body =>
      'Chọn mật khẩu mới cho tài khoản của bạn.';

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
  String get scoring_social => 'Tinh thần';

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
  String get breakdown_screentime => 'Thời gian sử dụng';

  @override
  String get date_today => 'Hôm nay';

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
  String get btn_enter => 'VÀO';

  @override
  String apple_signin_error(String error) {
    return 'Lỗi đăng nhập Apple: $error';
  }

  @override
  String google_signin_error(String error) {
    return 'Lỗi đăng nhập Google: $error';
  }

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
  String get email_label => 'Địa chỉ email';

  @override
  String get phone_number_label => 'Số điện thoại';

  @override
  String get personal_info_professional_matrix => 'Tổ chức';

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
  String get personal_info_digital => 'Tài khoản';

  @override
  String get github_label => 'GitHub';

  @override
  String get linkedin_label => 'LinkedIn';

  @override
  String get personal_web_label => 'Website';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get identity_evolution => 'TIẾN HÓA ĐỊNH DANH';

  @override
  String get identity_evolution_desc =>
      'Cấp 1: Google. Thiết lập mật khẩu cục bộ để nâng cấp bậc bảo mật.';

  @override
  String get btn_set => 'THIẾT LẬP';

  @override
  String get security_accuracy => 'Bảo mật';

  @override
  String get passkey_settings => 'Cài đặt Passkey';

  @override
  String get fast_track_active => 'Truy cập nhanh đang hoạt động (Bảo mật)';

  @override
  String get upgrade_biometric => 'Nâng cấp lên Truy cập nhanh Sinh trắc học';

  @override
  String get hint_enter_your => 'Nhập vào...';

  @override
  String get user_default => 'Người dùng';

  @override
  String get tooltip_save => 'Lưu';

  @override
  String get tooltip_edit => 'Chỉnh sửa';

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
  String get social_dashboard => 'Bảng điều khiển Tinh thần';

  @override
  String get social => 'Tinh thần';

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
  String get social_options => 'Tùy chọn Tinh thần';

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
  String get social_no_achievements_msg =>
      'Chưa có thành tích nào được ghi nhận.';

  @override
  String get achievement_story_section => 'Khoảnh khắc';

  @override
  String get achievement_story_empty_hint =>
      'Chạm + để giữ lại một khoảnh khắc.';

  @override
  String get achievement_story_add => 'Thêm';

  @override
  String get achievement_feats_section => 'Dòng thời gian';

  @override
  String get achievement_insights_title => 'Nhìn lại';

  @override
  String achievement_insights_summary(
    int count,
    String meaning,
    String impact,
  ) {
    return 'Tổng kết tháng: $count thành tích. Ý nghĩa TB: $meaning, Tác động TB: $impact';
  }

  @override
  String get achievement_story_title_dialog => 'Đặt tên thành tích';

  @override
  String get achievement_story_title_hint => 'Bạn đã làm gì?';

  @override
  String get achievement_story_added => 'Đã lưu story vào thành tích.';

  @override
  String get achievement_story_save_failed => 'Không lưu được ảnh.';

  @override
  String get achievement_filter_label => 'Lọc';

  @override
  String get achievement_filter_all_months => 'Mọi tháng';

  @override
  String get achievement_filter_all_projects => 'Mọi dự án';

  @override
  String get plan_action_tab => 'KẾ HOẠCH';

  @override
  String get plan_action_empty =>
      'Lên kế hoạch hành động với điểm kỳ vọng, sau đó ghi điểm thực tế khi hoàn thành.';

  @override
  String get plan_action_timeline => 'Dòng thời gian';

  @override
  String get plan_action_scoreboard => 'Bảng điểm';

  @override
  String get plan_action_pending => 'Chờ ghi';

  @override
  String get plan_action_no_pending =>
      'Đã ghi hết hành động trong khung nhìn này.';

  @override
  String get plan_action_add => 'Lên kế hoạch';

  @override
  String get plan_action_edit => 'Sửa hành động';

  @override
  String get plan_action_log_real => 'Ghi thực tế';

  @override
  String get plan_action_title_label => 'Bạn sẽ làm gì?';

  @override
  String get plan_action_title_required => 'Nhập tên hành động.';

  @override
  String get plan_action_expected_label => 'Điểm kỳ vọng (0–100)';

  @override
  String get plan_action_real_label => 'Điểm thực tế (0–100)';

  @override
  String get plan_action_real_hint => 'Để trống cho đến khi xong';

  @override
  String get plan_action_points_invalid => 'Điểm phải từ 0–100.';

  @override
  String get plan_action_expected_short => 'Kỳ vọng';

  @override
  String get plan_action_real_short => 'Thực tế';

  @override
  String plan_action_expected_value(int points) {
    return 'Kỳ vọng: $points điểm';
  }

  @override
  String plan_action_delta_value(int delta) {
    String _temp0 = intl.Intl.pluralLogic(
      delta,
      locale: localeName,
      other: '$delta',
      zero: 'bằng',
    );
    return '$_temp0';
  }

  @override
  String plan_action_month_summary(int count) {
    return '$count hành động trong khung nhìn này';
  }

  @override
  String get plan_action_total_expected => 'Tổng kỳ vọng';

  @override
  String get plan_action_total_real => 'Tổng thực tế';

  @override
  String get plan_action_delta => 'Chênh lệch';

  @override
  String get achievement_on_this_day_title => 'Ngày này năm ấy';

  @override
  String achievement_on_this_day_subtitle(String date) {
    return 'Kỷ niệm ngày $date';
  }

  @override
  String achievement_years_ago(int years) {
    return 'Cách đây $years năm';
  }

  @override
  String get achievement_archive_empty =>
      'Chưa có kỷ niệm. Ghi chép và ảnh journal sẽ hiện ở đây.';

  @override
  String achievement_archive_month_summary(int count) {
    return '$count kỷ niệm trong khung nhìn này';
  }

  @override
  String get achievement_open_project => 'Mở dự án';

  @override
  String get social_delete_feat_title => 'Xóa thành tích';

  @override
  String get social_delete_feat_body => 'Xóa mục này? Không thể hoàn tác.';

  @override
  String get social_feat => 'Chiến công';

  @override
  String get mind_how_feeling => 'Bạn cảm thấy thế nào?';

  @override
  String get mind_what_up_to => 'Bạn đang làm gì thế?';

  @override
  String get mind_add_note_hint => 'Thêm ghi chú (tùy chọn)';

  @override
  String get mind_save_entry => 'Lưu ghi chép';

  @override
  String get mind_log_saved => 'Đã lưu ghi chép! Suy ngẫm đã cập nhật.';

  @override
  String get mind_error_login =>
      'Lỗi: Không tìm thấy phiên người dùng. Vui lòng đăng nhập lại.';

  @override
  String mind_error_save(String error) {
    return 'Lưu ghi chép thất bại: $error';
  }

  @override
  String get mood_awful => 'Tồi tệ';

  @override
  String get mood_bad => 'Kém';

  @override
  String get mood_meh => 'Bình thường';

  @override
  String get mood_good => 'Tốt';

  @override
  String get mood_rad => 'Tuyệt vời';

  @override
  String get mood_no_data => 'N/A';

  @override
  String get mind_current_mood => 'Tâm trạng';

  @override
  String get mind_day_average => 'TB trong ngày';

  @override
  String get mind_latest_log => 'Ghi chép cuối';

  @override
  String get mind_never => 'Chưa có';

  @override
  String get mind_status => 'Trạng thái';

  @override
  String get mind_stable => 'Ổn định';

  @override
  String get mind_needs_care => 'Quan tâm';

  @override
  String get mind_focus_current => 'Tập trung';

  @override
  String get mind_focus_none => 'Chưa chọn';

  @override
  String get mind_quick_entry_hint => 'Bạn đang nghĩ gì thế?';

  @override
  String get mindset_learn_title => 'Nhật ký tư duy';

  @override
  String get mindset_learn_subtitle =>
      'Ghi lại nguyên tắc và bài học bạn đang nội hóa.';

  @override
  String get mindset_learn_topic => 'Chủ đề / nguyên tắc';

  @override
  String get mindset_learn_topic_hint =>
      'vd. Kiên nhẫn, ship nhỏ, tư duy phát triển';

  @override
  String get mindset_learn_lesson => 'Tôi học được gì';

  @override
  String get mindset_learn_feeling => 'Chấm (0–5)';

  @override
  String get mindset_learn_save => 'Lưu bài học';

  @override
  String get mindset_learn_saved => 'Đã lưu bài học tư duy';

  @override
  String get mindset_learn_validation => 'Hãy nhập chủ đề và bài học.';

  @override
  String get mindset_learn_history => 'Bài học trước';

  @override
  String get mindset_learn_empty =>
      'Chưa có ghi chú tư duy. Hãy ghi bài học đầu tiên ở trên.';

  @override
  String get mindset_learn_open => 'Tư duy';

  @override
  String get mind_focus_title => 'KHU VỰC TẬP TRUNG';

  @override
  String get mind_focus_weekly_title => 'Trọng tâm tuần này';

  @override
  String get mind_focus_monthly_title => 'Trọng tâm tháng này';

  @override
  String mind_focus_goal_level(int level) {
    return 'Mục tiêu: Lv. $level';
  }

  @override
  String mind_focus_xp_progress(int current, int cap) {
    return '$current / $cap XP';
  }

  @override
  String get mind_focus_badge => 'FOCUS';

  @override
  String get mind_total_level => 'Level tổng';

  @override
  String get mind_streak_label => 'Chuỗi';

  @override
  String mind_streak_days(int days) {
    return '$days ngày';
  }

  @override
  String get mind_streak_bonus => '+15% EXP bonus';

  @override
  String get mind_skill_tree_title => 'Cây kỹ năng';

  @override
  String get mind_skill_certificates_title => 'Chứng nhận';

  @override
  String get mind_focus_subtitle =>
      'Định nghĩa xu hướng theo tuần để biết nên tập trung vào đâu.';

  @override
  String get mind_focus_empty =>
      'Chưa có khu vực tập trung. Chọn mẫu hoặc tạo mới.';

  @override
  String get mind_focus_add => 'Khu vực mới';

  @override
  String get mind_focus_edit => 'Sửa khu vực';

  @override
  String get mind_focus_save => 'Lưu khu vực';

  @override
  String get mind_focus_weekly_goal => 'Số nhật ký / tuần (mục tiêu)';

  @override
  String get mind_focus_this_week => 'Tuần này';

  @override
  String get mind_focus_select_hint =>
      'Chạm để tập trung. Nhật ký gần đây khớp khu vực này:';

  @override
  String get mind_focus_template_gym => 'Tuần gym';

  @override
  String get mind_focus_template_learn => 'Tuần học';

  @override
  String get mind_focus_template_invest => 'Tuần đầu tư';

  @override
  String get mind_focus_name_hint => 'Tên (vd. Tuần gym)';

  @override
  String get mind_focus_activities_label => 'Hoạt động liên kết';

  @override
  String get mind_focus_name_required => 'Nhập tên khu vực tập trung';

  @override
  String get mind_focus_activities_required => 'Chọn ít nhất một hoạt động';

  @override
  String get mind_focus_icon_label => 'Biểu tượng';

  @override
  String get mind_focus_color_label => 'Màu';

  @override
  String get mind_focus_no_logs_yet => 'Chưa có nhật ký khớp khu vực này.';

  @override
  String get mind_focus_log_now => 'Ghi nhật ký';

  @override
  String mind_focus_log_for_area(String name) {
    return 'Khu vực: $name';
  }

  @override
  String get mind_focus_todos => 'Việc cần làm';

  @override
  String get mind_focus_open_projects => 'Dự án';

  @override
  String get mind_focus_no_todos =>
      'Chưa có việc trong dự án. Thêm ở trang Dự án.';

  @override
  String mind_focus_more_todos(int count) {
    return '+$count việc khác trong Dự án';
  }

  @override
  String get mind_dashboard_today => 'Hôm nay';

  @override
  String get mind_dashboard_title => 'Kỹ năng của tôi';

  @override
  String get mind_dashboard_weekly_topic => 'Chủ đề tuần này';

  @override
  String get mind_dashboard_edit_topic => 'Sửa chủ đề tuần này';

  @override
  String get mind_dashboard_topic_title => 'Tiêu đề chủ đề';

  @override
  String get mind_dashboard_topic_title_hint => 'vd. Tuần thuyết trình';

  @override
  String get mind_dashboard_topic_quote_hint =>
      'Câu quote hoặc ghi chú tập trung tuần này';

  @override
  String get mind_dashboard_topic_saved => 'Đã lưu chủ đề tuần vào quotes';

  @override
  String get mind_dashboard_target_skills => 'Kỹ năng mục tiêu';

  @override
  String get mind_dashboard_in_progress => 'Đang thực hiện';

  @override
  String get mind_dashboard_focus_week => 'Tập trung tuần này';

  @override
  String get mind_dashboard_add_task => '+ Thêm nhiệm vụ';

  @override
  String get mind_dashboard_no_linked_projects =>
      'Gắn kỹ năng mục tiêu với dự án để xem việc cần làm ở đây.';

  @override
  String get mind_dashboard_status_done => 'XONG';

  @override
  String get mind_dashboard_status_waiting => 'CHỜ';

  @override
  String get mind_dashboard_certificates => 'Chứng chỉ kỹ năng';

  @override
  String get mind_dashboard_see_all => 'Xem tất cả';

  @override
  String get mind_dashboard_verified => 'Verified';

  @override
  String mind_focus_avg_mood(String score) {
    return 'Tâm trạng TB tuần này: $score';
  }

  @override
  String get mind_focus_history => 'Lịch sử tuần';

  @override
  String get mind_focus_history_title => 'Lịch sử khu vực tập trung';

  @override
  String mind_focus_history_week_range(String start, String end) {
    return '$start – $end';
  }

  @override
  String mind_focus_history_logs(int count, int goal) {
    return '$count / $goal nhật ký';
  }

  @override
  String get mind_focus_history_no_logs => 'Chưa có nhật ký';

  @override
  String get mind_focus_linked_project => 'Dự án liên kết';

  @override
  String get mind_focus_linked_project_none => 'Không (mọi dự án)';

  @override
  String mind_focus_linked_project_label(String name) {
    return 'Dự án: $name';
  }

  @override
  String get mind_focus_add_task_title => 'Thêm việc';

  @override
  String get mind_focus_add_task_name => 'Tên việc';

  @override
  String get mind_focus_add_task_desc => 'Mô tả (tuỳ chọn)';

  @override
  String get mind_focus_add_task_confirm => 'Thêm';

  @override
  String get mind_focus_add_task_need_project =>
      'Tạo dự án trước, rồi thêm việc ở đây.';

  @override
  String get mind_focus_assign_project => 'Dự án';

  @override
  String get mind_focus_all_tasks_mood =>
      'Hoàn thành mọi việc — đã ghi tâm trạng +6.';

  @override
  String mind_focus_daily_cap(int max) {
    return 'Giới hạn: $max việc mỗi ngày trong khu vực này.';
  }

  @override
  String mind_focus_daily_progress(int added, int max, int done) {
    return 'Hôm nay $added/$max · xong $done';
  }

  @override
  String get mind_focus_daily_hint =>
      'Thêm 2–5 việc mỗi ngày. Hoàn thành hơn 3 việc để nhận tâm trạng +6.';

  @override
  String get mind_focus_weekly_hint =>
      'Thêm 2–5 việc mỗi tuần. Hoàn thành hơn 3 việc để nhận tâm trạng +6.';

  @override
  String get mind_focus_monthly_hint =>
      'Thêm 2–5 việc mỗi tháng. Hoàn thành hơn 3 việc để nhận tâm trạng +6.';

  @override
  String get mind_focus_special_mood =>
      'Hơn 3 việc xong — đã ghi tâm trạng +6!';

  @override
  String get mind_skills_session_title => 'Phiên kỹ năng';

  @override
  String get mind_skills_session_subtitle =>
      'Chọn kỹ năng, tập trung, ghi lại điều học được.';

  @override
  String get mind_skills_session_start => 'Bắt đầu phiên';

  @override
  String get mind_skills_session_empty_month =>
      'Chưa có phiên kỹ năng trong tháng này.';

  @override
  String mind_skills_session_skill_meta(int sessions, int minutes) {
    return '$sessions phiên · $minutes phút';
  }

  @override
  String mind_skills_session_empty(int days) {
    return 'Chưa có phiên kỹ năng trong $days ngày qua.';
  }

  @override
  String mind_skills_session_stats(int sessions, int minutes, String skill) {
    return '$sessions phiên · $minutes phút · nổi bật: $skill';
  }

  @override
  String get mind_skills_session_live => 'ĐANG TẬP TRUNG';

  @override
  String get mind_skills_session_tap_start => 'CHẠM GIỮA ĐỂ BẮT ĐẦU';

  @override
  String get mind_skills_session_tap_finish => 'CHẠM GIỮA ĐỂ DỪNG SỚM';

  @override
  String get mind_skills_session_listening =>
      'ĐANG TẬP TRUNG · TỰ GHI KHI NHẠC KẾT THÚC';

  @override
  String get mind_skills_session_pick_skills =>
      'Chọn ít nhất một kỹ năng trước khi bắt đầu.';

  @override
  String get mind_skills_my_list => 'Kỹ năng của tôi';

  @override
  String get mind_skills_add_skill => 'Thêm kỹ năng';

  @override
  String get mind_skills_tap_list => 'Chạm kỹ năng trong danh sách để chọn';

  @override
  String get mind_skills_tap_list_project => 'Chọn kỹ năng · XP dự án khi ghi';

  @override
  String get mind_skills_status_in_session => 'Đang tập trung';

  @override
  String get mind_skills_status_selected => 'Đã chọn';

  @override
  String mind_skills_level_short(int level) {
    return 'Cấp $level';
  }

  @override
  String mind_skills_session_logged(int minutes, int xp) {
    return 'Đã ghi phiên · $minutes phút · +$xp XP';
  }

  @override
  String get mind_skills_celebration_title => 'Đã lưu bằng chứng luyện tập';

  @override
  String mind_skills_celebration_proof(int minutes, int xp) {
    return 'Bạn tập trung $minutes phút và +$xp XP — đã ghi vào hồ sơ kỹ năng.';
  }

  @override
  String mind_skills_celebration_level_up(String skills) {
    return 'Lên cấp: $skills';
  }

  @override
  String mind_skills_celebration_streak(int days) {
    return 'Chuỗi $days ngày — giữ nhịp luyện tập.';
  }

  @override
  String get mind_skills_celebration_goal =>
      'Phiên hôm nay là nền cho phiên bản bạn ngày mai.';

  @override
  String get mind_skill_name_invalid => 'Tên kỹ năng từ 1–24 ký tự.';

  @override
  String get mind_skill_name_duplicate => 'Kỹ năng này đã có trong danh sách.';

  @override
  String get mind_skill_add_title => 'Thêm kỹ năng';

  @override
  String get mind_skill_edit_title => 'Sửa tên kỹ năng';

  @override
  String get mind_skill_delete_title => 'Xóa kỹ năng?';

  @override
  String mind_skill_delete_body(String name) {
    return 'Gỡ “$name” khỏi thư viện kỹ năng?';
  }

  @override
  String get mind_skill_certificate_header => 'CHỨNG NHẬN LUYỆN TẬP';

  @override
  String get mind_skill_certificate_subtitle =>
      'Năng lực con người · tiến độ đã xác minh';

  @override
  String get mind_skill_certificate_awarded_to =>
      'Trao tặng cho quá trình rèn luyện kỹ năng';

  @override
  String get mind_skill_certificate_level => 'Cấp bậc';

  @override
  String get mind_skill_certificate_xp => 'Kinh nghiệm';

  @override
  String get mind_skill_certificate_streak => 'Chuỗi ngày';

  @override
  String get mind_skill_certificate_proof =>
      'Bản ghi này từ các phiên thật trên ice_gate — bằng chứng tiến bộ của bạn.';

  @override
  String get mind_skill_certificate_seal => 'ẤN ICEGATE';

  @override
  String get mind_skill_certificate_select_session => 'Chọn cho phiên';

  @override
  String get mind_skill_certificate_close => 'Đóng';

  @override
  String get mind_skill_certificate_created => 'Ngày tạo';

  @override
  String get mind_skill_certificate_updated => 'Cập nhật lần cuối';

  @override
  String get mind_skill_certificate_description => 'Mô tả';

  @override
  String get mind_skill_certificate_description_hint =>
      'Ý nghĩa kỹ năng này với bạn, hoặc cách bạn đạt được…';

  @override
  String get mind_skill_certificate_edit => 'Sửa chứng nhận';

  @override
  String get mind_skill_certificate_save => 'Lưu chứng nhận';

  @override
  String get mind_skill_certificates_table_title => 'Chứng nhận luyện tập';

  @override
  String get mind_skill_certificates_table_empty =>
      'Chưa có kỹ năng trong thư viện. Mở Kỹ năng để bắt đầu tích lũy chứng nhận.';

  @override
  String get mind_skill_certificates_col_skill => 'Kỹ năng';

  @override
  String get mood_trends_title => 'XU HƯỚNG TÂM TRẠNG';

  @override
  String get social_notes_title => 'GHI CHÉP TINH THẦN';

  @override
  String get social_empty_state_title => 'Câu chuyện của bạn bắt đầu tại đây';

  @override
  String get social_empty_state_subtitle =>
      'Ghi lại những khoảnh khắc, suy nghĩ và ý tưởng.';

  @override
  String get btn_new_reflection => 'Suy ngẫm mới';

  @override
  String get mind_insights_title => 'THÔNG TIN TINH THẦN';

  @override
  String get mind_insights_subtitle => 'Phân tích nhật ký của bạn';

  @override
  String get mind_question => 'Bạn cảm thấy thế nào?';

  @override
  String get mind_activities_question => 'Bạn đã làm gì?';

  @override
  String get mind_note_hint => 'Thêm ghi chú (tùy chọn)';

  @override
  String get mind_save_btn => 'Lưu mục nhập';

  @override
  String get mind_activity_custom_chip => 'Tùy chỉnh';

  @override
  String get mind_activity_custom_dialog_title => 'Hoạt động mới';

  @override
  String get mind_activity_custom_hint => 'Đặt tên hoạt động';

  @override
  String get mind_activity_custom_add => 'Thêm';

  @override
  String get mind_activity_custom_invalid_char => 'Không được dùng ký tự này';

  @override
  String get mind_save_success =>
      'Đã lưu nhật ký tinh thần! Cập nhật suy ngẫm.';

  @override
  String mind_feeling_format(String mood) {
    return 'Hôm nay tôi cảm thấy $mood.';
  }

  @override
  String get mind_logged_mood => 'Đã ghi lại tâm trạng';

  @override
  String get todays_reflections => 'SUY NGẪM HÔM NAY';

  @override
  String get daily_step_distribution => 'PHÂN BỔ BƯỚC CHÂN HÀNG NGÀY';

  @override
  String get stat_entries => 'MỤC NHẬP';

  @override
  String get stat_images => 'HÌNH ẢNH';

  @override
  String get stat_sentiment => 'TÂM TRẠNG';

  @override
  String get stat_mind_logs => 'Log (30 ngày)';

  @override
  String get stat_active_days => 'Ngày có log';

  @override
  String get stat_avg_mood => 'Mood TB';

  @override
  String get journal_hourly_logs => 'Log theo giờ (hôm nay)';

  @override
  String get mind_insights_skill_title => 'Luyện kỹ năng (30 ngày)';

  @override
  String mind_insights_skill_summary(int sessions, int minutes) {
    return '$sessions phiên · $minutes phút';
  }

  @override
  String mind_insights_top_skill_streak(String skill, int days) {
    return 'Chuỗi · $skill · $days ngày';
  }

  @override
  String get mind_insights_open_notes => 'Ghi chép tinh thần';

  @override
  String get mind_insights_open_skills => 'Chứng nhận kỹ năng';

  @override
  String get mind_insights_open_gratitude => 'Biết ơn';

  @override
  String get gratitude_page_subtitle =>
      'Ghi lại những người và vật bạn trân trọng mỗi ngày.';

  @override
  String get gratitude_section_people => 'Người biết ơn';

  @override
  String get gratitude_section_things => 'Vật biết ơn';

  @override
  String gratitude_count(int count) {
    return '$count mục';
  }

  @override
  String get gratitude_quick_entry_hint => 'Ghi nhật ký biết ơn hôm nay...';

  @override
  String get gratitude_empty_title => 'Cờ biết ơn của bạn';

  @override
  String get gratitude_empty_subtitle =>
      'Chạm nút bên dưới để ghi tên người hoặc vật bạn biết ơn.';

  @override
  String get gratitude_kind_person => 'Người';

  @override
  String get gratitude_kind_thing => 'Vật';

  @override
  String get gratitude_add_title => 'Thêm biết ơn';

  @override
  String get gratitude_name_label => 'Tên';

  @override
  String get gratitude_note_hint => 'Lời biết ơn (tuỳ chọn)';

  @override
  String get gratitude_facebook_link_label => 'Link Facebook';

  @override
  String get gratitude_facebook_link_hint => 'Dán link profile Facebook';

  @override
  String get gratitude_pick_avatar => 'Chọn ảnh đại diện';

  @override
  String get gratitude_change_photo => 'Đổi ảnh';

  @override
  String get gratitude_open_facebook => 'Mở Facebook';

  @override
  String get gratitude_update_flag => 'Cập nhật cờ';

  @override
  String get gratitude_edit_title => 'Sửa biết ơn';

  @override
  String get gratitude_tags_label => 'Nhãn';

  @override
  String get gratitude_filter_all => 'Tất cả';

  @override
  String get gratitude_filter_things => 'Vật';

  @override
  String get gratitude_tag_play => 'Chơi';

  @override
  String get gratitude_tag_learn => 'Học';

  @override
  String get gratitude_tag_work => 'Làm việc';

  @override
  String get gratitude_tag_health => 'Sức khỏe';

  @override
  String get gratitude_tag_social => 'Xã hội';

  @override
  String get gratitude_tag_family => 'Gia đình';

  @override
  String get gratitude_invalid_facebook_link => 'Link Facebook không hợp lệ';

  @override
  String get gratitude_delete_confirm => 'Xoá mục biết ơn này?';

  @override
  String get gratitude_pick_title => 'Bạn biết ơn ai / vật gì?';

  @override
  String get gratitude_pick_required =>
      'Chọn người hoặc vật biết ơn trước khi lưu.';

  @override
  String get weekly_mood_trend => 'XU HƯỚNG TÂM TRẠNG TUẦN';

  @override
  String get no_records_last_7_days => 'Không có dữ liệu trong 7 ngày qua';

  @override
  String get frequent_activities => 'HOẠT ĐỘNG THƯỜNG XUYÊN';

  @override
  String get track_patterns_msg => 'Theo dõi thêm để thấy quy luật';

  @override
  String get monthly_reflection => 'SUY NGẪM HÀNG THÁNG';

  @override
  String get cat_productivity => 'Năng suất';

  @override
  String get cat_health => 'Sức khỏe';

  @override
  String get cat_social => 'Xã hội';

  @override
  String get cat_rest => 'Nghỉ ngơi';

  @override
  String get act_deep_work => 'Làm việc sâu';

  @override
  String get act_learning => 'Học tập';

  @override
  String get act_finance => 'Tài chính';

  @override
  String get act_planning => 'Lập kế hoạch';

  @override
  String get act_exercise => 'Tập thể dục';

  @override
  String get act_meditation => 'Thiền';

  @override
  String get act_healthy_meal => 'Bữa ăn lành mạnh';

  @override
  String get act_great_sleep => 'Ngủ ngon';

  @override
  String get act_family => 'Gia đình';

  @override
  String get act_friends => 'Bạn bè';

  @override
  String get act_dating => 'Hẹn hò';

  @override
  String get act_kindness => 'Tử tế';

  @override
  String get act_gratitude => 'Biết ơn';

  @override
  String get act_gaming => 'Chơi game';

  @override
  String get act_reading => 'Đọc sách';

  @override
  String get act_cinema => 'Xem phim';

  @override
  String get act_walking => 'Đi dạo';

  @override
  String get act_focus_todos_streak => 'Hoàn thành 4+ việc tập trung';

  @override
  String get act_focus_todos_complete => 'Hoàn thành việc tập trung';

  @override
  String get act_logging => 'Ghi chép';

  @override
  String get act_productivity => 'Năng suất';

  @override
  String get add_app_plugin => 'Thêm Plugin ứng dụng';

  @override
  String get plugin_desc => 'Thêm tính năng mới cho giao diện của bạn';

  @override
  String get plugin_ssh => 'SSH';

  @override
  String get plugin_ssh_opencode => 'Điều khiển OpenCode SSH';

  @override
  String get plugin_ssh_desc =>
      'Terminal hỗ trợ AI để điều phối hệ thống từ xa';

  @override
  String get config_ai_prompt => 'Cấu hình Prompt AI';

  @override
  String get homepage_four_life_elements => '4 phía cạnh';

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
  String get auth_error_session_not_found =>
      'Lỗi: Không tìm thấy phiên người dùng. Vui lòng đăng nhập lại.';

  @override
  String get projects => 'Dự án';

  @override
  String get projects_page_tagline =>
      'Tập trung theo phiên, nhiệm vụ và ghi chú cùng một nơi.';

  @override
  String get projects_summary_workspaces => 'Không gian';

  @override
  String get projects_summary_plugins => 'Tiện ích';

  @override
  String get projects_quick_more => 'Lối tắt thêm';

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
  String get home_indices_title => 'Chỉ số nhanh';

  @override
  String get home_index_steps => 'Bước chân';

  @override
  String get home_index_calories => 'Calo';

  @override
  String get home_index_balance => 'Số dư';

  @override
  String get home_index_spending => 'Chi tiêu';

  @override
  String get home_index_mood => 'Tâm trạng';

  @override
  String get home_index_projects => 'Dự án';

  @override
  String get home_index_weight => 'Cân nặng';

  @override
  String get home_index_water => 'Nước uống';

  @override
  String get home_index_daily => 'Hàng ngày';

  @override
  String get home_index_usage => 'Sử dụng';

  @override
  String get home_index_focus => 'Tập trung';

  @override
  String get home_index_xp => 'XP Hôm nay';

  @override
  String get home_index_total => 'Tổng cộng';

  @override
  String get home_projects_done => 'Dự án xong';

  @override
  String get home_projects_active => 'Dự án chạy';

  @override
  String get home_tasks_done => 'Nhiệm vụ xong';

  @override
  String get home_tasks_active => 'Nhiệm vụ chạy';

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
    return '$points điểm cho mỗi phiên hỗ trợ hoặc kết nối ý nghĩa.';
  }

  @override
  String rule_social_affection(int points, int unit) {
    return '$points điểm cho mỗi $unit mức độ ổn định đạt được.';
  }

  @override
  String get rule_social_maintain =>
      'Thực hành chánh niệm để duy trì sự ổn định Tinh thần.';

  @override
  String get how_it_works => 'Cách thức hoạt động';

  @override
  String get scoring_intro =>
      'Hệ thống điểm số của chúng tôi đánh giá hiệu suất hàng ngày của bạn qua bốn trụ cột chính. Điểm được thưởng dựa trên tính nhất quán, các mốc quan trọng và hiệu quả.';

  @override
  String get scoring_footer =>
      'Điểm số được xử lý bởi Life Orchestration Engine (LOE) vào mỗi nửa đêm giờ UTC.';

  @override
  String get canvas_notification_center => 'Thông báo';

  @override
  String get canvas_notification_desc =>
      'Điều khiển và kiểm soát mọi thông báo hệ thống';

  @override
  String get canvas_goal_center => 'Mục tiêu';

  @override
  String get dev_quick_tabs_title => 'Software Dev';

  @override
  String get dev_quick_tabs_subtitle =>
      'Tab trình duyệt — Northflank, Supabase, n8n và hơn thế.';

  @override
  String get dev_quick_tabs_empty => 'Chưa có tab. Bấm + để thêm.';

  @override
  String get dev_quick_tabs_add => 'Thêm tab';

  @override
  String get dev_quick_tabs_open => 'Mở';

  @override
  String get dev_quick_tabs_edit => 'Sửa tab';

  @override
  String get dev_quick_tabs_label => 'Tên';

  @override
  String get dev_quick_tabs_url => 'URL cục bộ (LAN)';

  @override
  String get dev_quick_tabs_remote_url => 'URL từ xa';

  @override
  String get dev_quick_tabs_remote_url_hint =>
      'Dùng khi không vào được LAN (VPN, Tailscale, host công khai).';

  @override
  String get dev_quick_tabs_validation_error =>
      'Tên và ít nhất một URL không được để trống';

  @override
  String get dev_quick_tabs_delete_title => 'Xóa tab?';

  @override
  String dev_quick_tabs_delete_message(String title) {
    return 'Xóa \"$title\" khỏi truy cập nhanh.';
  }

  @override
  String get dev_quick_tabs_delete_confirm => 'Xóa';

  @override
  String get dev_quick_tabs_credentials => 'Đăng nhập đã lưu';

  @override
  String get dev_quick_tabs_credentials_subtitle =>
      'HTTP login và tin SSL theo từng host.';

  @override
  String get dev_quick_tabs_credentials_login => 'Đã lưu đăng nhập';

  @override
  String get dev_quick_tabs_credentials_ssl => 'Đã tin SSL';

  @override
  String get dev_quick_tabs_credentials_none => 'Chưa lưu gì';

  @override
  String get dev_quick_tabs_credentials_set_login => 'Đặt đăng nhập';

  @override
  String get dev_quick_tabs_credentials_username => 'Tên đăng nhập';

  @override
  String get dev_quick_tabs_credentials_password => 'Mật khẩu';

  @override
  String get dev_quick_tabs_credentials_passkey => 'Passkey / API key';

  @override
  String get dev_quick_tabs_credentials_saved => 'Đã lưu thông tin đăng nhập';

  @override
  String get dev_quick_tabs_credentials_ssl_hint =>
      'Cho HTTPS homelab tự ký (vd. OPNsense).';

  @override
  String get dev_quick_tabs_credentials_clear => 'Xóa hết';

  @override
  String get dev_quick_tabs_credentials_clear_title => 'Xóa dữ liệu đã lưu?';

  @override
  String dev_quick_tabs_credentials_clear_message(String host) {
    return 'Xóa đăng nhập và tin SSL cho $host.';
  }

  @override
  String get dev_quick_tabs_credentials_revoke_ssl => 'Thu hồi tin SSL';

  @override
  String get dev_quick_tabs_login_type => 'Kiểu đăng nhập';

  @override
  String get dev_quick_tabs_login_type_html_form =>
      'Form HTML (OPNsense, homelab)';

  @override
  String get dev_quick_tabs_login_type_email_password =>
      'Email + mật khẩu (SPA)';

  @override
  String get dev_quick_tabs_login_type_http_basic => 'Chỉ HTTP Basic';

  @override
  String get dev_quick_tabs_login_type_api_key => 'API key / token';

  @override
  String get dev_quick_tabs_login_type_bearer_token =>
      'Bearer token (K8s Dashboard)';

  @override
  String get dev_quick_tabs_login_type_external_browser => 'Mở Safari / Chrome';

  @override
  String get dev_quick_tabs_login_type_oauth =>
      'OAuth / SSO (WebView thủ công)';

  @override
  String get dev_quick_tabs_login_type_none => 'Không tự điền';

  @override
  String get dev_quick_tabs_credentials_email => 'Email';

  @override
  String get dev_quick_tabs_credentials_bearer_token => 'Bearer token';

  @override
  String get dev_quick_tabs_login_type_external_browser_hint =>
      'Mở bằng trình duyệt hệ thống — phù hợp GitHub, Google SSO và passkey.';

  @override
  String get dev_quick_tabs_login_type_oauth_hint =>
      'Đăng nhập GitHub/Google không tự điền được. Đăng nhập thủ công.';

  @override
  String get webview_connection_error => 'Lỗi kết nối';

  @override
  String get webview_retry => 'Thử lại';

  @override
  String get webview_ssl_trust_title => 'Tin chứng chỉ homelab?';

  @override
  String webview_ssl_trust_message(String host) {
    return 'Chứng chỉ của $host không được tin (thường gặp với OPNsense/LAN). Chỉ tiếp tục trên mạng bạn tin tưởng.';
  }

  @override
  String get webview_ssl_trust_continue => 'Tin và tiếp tục';

  @override
  String get webview_choose_url => 'Chọn URL';

  @override
  String get webview_ssl_protocol_hint =>
      'Thường do máy chủ chỉ dùng HTTP, không phải HTTPS. Sửa URL tab sang http:// hoặc bấm Thử HTTP bên dưới.';

  @override
  String get webview_ssl_protocol_tailscale_hint =>
      'HTTPS trên Tailscale thường qua tên máy (https://ten.tailnet.ts.net cổng 443, Tailscale Serve), không phải https://100.x.x.x:9001. Cổng 9001 thường chỉ HTTP phía sau proxy — hãy dùng URL Serve trong URL từ xa.';

  @override
  String get webview_try_http => 'Thử HTTP';

  @override
  String get canvas_goal_desc => 'Điều chỉnh mục tiêu';

  @override
  String get canvas_finance_reports_title => 'Báo cáo tài chính';

  @override
  String get canvas_finance_reports_desc =>
      'Tóm tắt trong ngày, nhắc nhở cục bộ và lối tắt';

  @override
  String get canvas_finance_n8n_title => 'Báo cáo qua email';

  @override
  String get canvas_finance_n8n_desc =>
      'Tóm tắt tài chính và sức khỏe gửi qua n8n';

  @override
  String get canvas_finance_n8n_send_success => 'Đã gửi báo cáo tới n8n.';

  @override
  String get canvas_finance_n8n_send_failed =>
      'Không gửi được báo cáo. Thử lại sau.';

  @override
  String get canvas_finance_n8n_not_configured =>
      'Chưa cấu hình webhook n8n trong môi trường ứng dụng.';

  @override
  String get canvas_finance_n8n_no_email =>
      'Thêm email vào hồ sơ trước khi gửi báo cáo.';

  @override
  String get canvas_finance_n8n_confirm_title => 'Gửi báo cáo qua email?';

  @override
  String canvas_finance_n8n_confirm_message(String email) {
    return 'Tóm tắt tài chính và sức khỏe hôm nay sẽ được gửi tới n8n để chuyển tới $email.';
  }

  @override
  String get canvas_mail_summary_recipient => 'Người nhận';

  @override
  String get canvas_mail_summary_finance => 'Tài chính hôm nay';

  @override
  String get canvas_mail_summary_health => 'Sức khỏe hôm nay';

  @override
  String get canvas_mail_summary_send => 'Gửi báo cáo email';

  @override
  String get canvas_mail_summary_auto_title => 'Email tự động hàng ngày';

  @override
  String get canvas_mail_summary_auto_subtitle =>
      'Sau giờ này, gửi một lần mỗi ngày khi ứng dụng đang mở';

  @override
  String get mail_suggestion_title => 'Gợi ý báo cáo';

  @override
  String get mail_suggestion_ai_loading => 'AI đang phân tích ngày của bạn…';

  @override
  String get mail_suggestion_ai_fallback =>
      'Gợi ý ngoại tuyến — cấu hình MAIL_SUGGESTIONS_AGENT_URL để dùng AI.';

  @override
  String get mail_suggestion_negative_net =>
      'Chi tiêu hôm nay vượt thu nhập — xem lại giao dịch gần đây.';

  @override
  String get mail_suggestion_no_transactions =>
      'Chưa ghi giao dịch hôm nay — thêm chi tiêu để báo cáo chính xác.';

  @override
  String mail_suggestion_budget_high(String percent) {
    return 'Đã dùng $percent% ngân sách tháng — cân nhắc tiết chế chi tiêu.';
  }

  @override
  String get mail_suggestion_monthly_deficit =>
      'Chi tiêu tháng vượt thu nhập — cân nhắc cắt giảm chi phí cố định.';

  @override
  String mail_suggestion_steps_low(String percent) {
    return 'Bước chân đạt $percent% mục tiêu — đi bộ ngắn giúp bạn tiến gần hơn.';
  }

  @override
  String get mail_suggestion_water_low =>
      'Lượng nước dưới một nửa mục tiêu — uống đều trong ngày.';

  @override
  String get mail_suggestion_sleep_low =>
      'Giấc ngủ dưới mục tiêu — thử đi ngủ sớm hơn tối nay.';

  @override
  String get mail_suggestion_log_mood =>
      'Chưa ghi mood hôm nay — check-in nhanh giúp theo dõi xu hướng.';

  @override
  String get mail_suggestion_focus_low =>
      'Thời gian tập trung còn thấp — lên lịch một phiên deep work ngắn.';

  @override
  String mail_suggestion_tasks_many(String count) {
    return '$count task đang mở — chọn một ưu tiên cho ngày mai.';
  }

  @override
  String get reports_hub_title => 'Báo cáo qua mail';

  @override
  String get reports_hub_subtitle =>
      'Báo cáo tài chính trên máy, gửi email qua n8n';

  @override
  String get system_monitor_title => 'Giám sát hệ thống';

  @override
  String get system_monitor_subtitle =>
      'Homelab, tài khoản dev, DB & đồng bộ — chỉ quản trị viên.';

  @override
  String get system_monitor_denied_title => 'Cần quyền quản trị';

  @override
  String get system_monitor_denied_body =>
      'Trang này chỉ dành cho tài khoản có vai trò admin.';

  @override
  String system_monitor_denied_roles(String local, String remote) {
    return 'Cục bộ: $local · Máy chủ: $remote';
  }

  @override
  String get system_monitor_denied_hint =>
      'Đặt role = admin trong Supabase → Table Editor → user_accounts (không phải Auth metadata). Sau đó bấm Làm mới vai trò.';

  @override
  String get system_monitor_retry => 'Làm mới vai trò';

  @override
  String get system_monitor_overview_section => 'Tổng quan';

  @override
  String get system_monitor_db_section => 'Cơ sở dữ liệu cục bộ';

  @override
  String get system_monitor_sync_section => 'Động cơ đồng bộ';

  @override
  String get system_monitor_app_version => 'Phiên bản app';

  @override
  String get system_monitor_platform => 'Nền tảng';

  @override
  String get system_monitor_role => 'Vai trò';

  @override
  String get system_monitor_auth_status => 'Trạng thái đăng nhập';

  @override
  String get system_monitor_supabase_user => 'Người dùng Supabase';

  @override
  String get system_monitor_running_checks => 'Đang chạy kiểm tra…';

  @override
  String get system_monitor_healthy => 'Cơ sở dữ liệu ổn định';

  @override
  String get system_monitor_issues => 'Phát hiện sự cố';

  @override
  String get system_monitor_smoke_test => 'Kiểm tra nhanh';

  @override
  String get system_monitor_sync_active => 'Đang đồng bộ';

  @override
  String get system_monitor_sync_status => 'Trạng thái gần nhất';

  @override
  String get system_monitor_uptime => 'Thời gian phiên';

  @override
  String get system_monitor_open_sync_engine => 'Mở Sync Engine';

  @override
  String get dev_launcher_web_title => 'Web app (homelab)';

  @override
  String get dev_launcher_accounts_title => 'Tài khoản dev & cloud';

  @override
  String get dev_launcher_accounts_empty =>
      'Lưu OPNsense, Supabase, Northflank, n8n. Mật khẩu chỉ trên máy.';

  @override
  String get dev_launcher_add_web => 'Thêm web app';

  @override
  String get dev_launcher_add_account => 'Thêm tài khoản dev';

  @override
  String get dev_launcher_name => 'Tên';

  @override
  String get dev_launcher_url => 'URL';

  @override
  String get dev_launcher_service => 'Dịch vụ';

  @override
  String get dev_launcher_username => 'Tên đăng nhập';

  @override
  String get dev_launcher_password => 'Mật khẩu / API key';

  @override
  String get dev_launcher_copied => 'Đã sao chép';

  @override
  String get dev_launcher_pin_canvas => 'Ghim lên Canvas';

  @override
  String get dev_launcher_pinned => 'Đã thêm vào widget Canvas';

  @override
  String get dev_launcher_add_from_catalog => 'Từ danh mục plugin';

  @override
  String get dev_launcher_pick_plugin => 'Plugin web homelab';

  @override
  String get infra_api_section_title => 'API hạ tầng';

  @override
  String get infra_api_section_subtitle =>
      'Kết nối Cloudflare, Tailscale, Northflank. Token chỉ lưu trên máy.';

  @override
  String infra_api_configure(String provider) {
    return 'Cấu hình $provider';
  }

  @override
  String get infra_api_token_label => 'API token / key';

  @override
  String get infra_api_tailnet_label => 'Tên tailnet';

  @override
  String get infra_api_tailnet_hint => 'Dùng - cho tailnet mặc định';

  @override
  String get infra_api_clear => 'Xóa';

  @override
  String get infra_api_test => 'Thử kết nối';

  @override
  String get infra_api_not_configured => 'Chưa cấu hình';

  @override
  String get infra_api_connected => 'Đã kết nối';

  @override
  String get infra_api_token_saved => 'Đã lưu token — bấm Thử';

  @override
  String infra_api_test_ok(String summary) {
    return 'OK · $summary';
  }

  @override
  String infra_api_test_fail(String message) {
    return 'Lỗi · $message';
  }

  @override
  String get island_system_monitor => 'GIÁM SÁT HỆ THỐNG';

  @override
  String get reports_mail_section_title => 'Gửi qua n8n';

  @override
  String get reports_mail_section_subtitle =>
      'Tóm tắt tài chính và sức khỏe gửi bằng email';

  @override
  String get reports_finance_section => 'Báo cáo tài chính trên máy';

  @override
  String get reports_recipient_hint => 'nguoi-nhan@example.com';

  @override
  String get reports_recipient_save => 'Lưu người nhận';

  @override
  String get reports_recipient_saved => 'Đã lưu người nhận báo cáo.';

  @override
  String reports_recipient_profile_fallback(String email) {
    return 'Mặc định từ hồ sơ: $email';
  }

  @override
  String get canvas_finance_n8n_confirm_send => 'Gửi';

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
  String get note_type_picker_title => 'Chọn loại ghi chú';

  @override
  String get note_type_markdown => 'Markdown (.md)';

  @override
  String get note_type_plain_text => 'Văn bản thuần (.txt)';

  @override
  String get note_type_word => 'Word (.docx)';

  @override
  String get project_journal_label => 'Nhật ký';

  @override
  String get project_no_journal =>
      'Chưa có nhật ký. Nhấn + để ghi mood và tiến độ.';

  @override
  String get project_journal_entry => 'Nhật ký dự án';

  @override
  String project_log_context(String name) {
    return 'Dự án: $name';
  }

  @override
  String get project_journal_mood_label => 'Tâm trạng';

  @override
  String get project_journal_desc_label => 'Mô tả';

  @override
  String get project_journal_save => 'Lưu nhật ký';

  @override
  String get project_journal_composer_hint =>
      'Chạm để ghi lại cảm giác khi làm dự án.';

  @override
  String project_journal_count(int count) {
    return '$count';
  }

  @override
  String get project_no_notes => 'Chưa có ghi chú nào. Nhấn + để tạo.';

  @override
  String get project_no_notes_list => 'Không tìm thấy ghi chú nào';

  @override
  String get project_choose_document_type => 'Chọn loại tài liệu';

  @override
  String get project_doc_blank_note => 'Ghi chú trống';

  @override
  String get project_doc_blank_note_desc => 'Bắt đầu từ trang trắng';

  @override
  String get project_doc_tech => 'Tài liệu kỹ thuật';

  @override
  String get project_doc_tech_desc => 'Mẫu kiến trúc và triển khai';

  @override
  String get project_doc_api => 'Đặc tả API';

  @override
  String get project_doc_api_desc => 'Mẫu endpoint và schema';

  @override
  String get project_doc_tech_title => 'Tài liệu kỹ thuật';

  @override
  String get project_doc_api_title => 'Đặc tả API';

  @override
  String get project_finance_label => 'Tài chính';

  @override
  String get project_no_finance =>
      'Chưa có bản ghi tài chính nào cho dự án này.';

  @override
  String get project_skills_label => 'Kỹ năng';

  @override
  String get project_no_skills =>
      'Chưa có kỹ năng nào. Nhấn + để theo dõi thứ bạn cải thiện khi làm dự án.';

  @override
  String get project_add_skill_title => 'Thêm kỹ năng';

  @override
  String get project_skill_name_hint => 'VD: Flutter, debug, thiết kế hệ thống';

  @override
  String project_skill_streak_days(int count) {
    return '$count ngày liên tiếp';
  }

  @override
  String get project_skill_streak_none => 'Chưa có chuỗi';

  @override
  String project_skill_xp_hint(int total, int remaining) {
    return '$total XP · còn $remaining XP lên cấp';
  }

  @override
  String get project_skill_xp_on_complete =>
      'Hoàn thành nhiệm vụ để nhận +15 XP mỗi kỹ năng';

  @override
  String get project_skill_log_session =>
      'Ghi phiên Skill Boost để tăng cấp kỹ năng này.';

  @override
  String get project_skill_practice => 'Mở Skill Boost';

  @override
  String get project_skill_tap_to_start =>
      'Chọn một hoặc nhiều kỹ năng, rồi bắt đầu phiên';

  @override
  String project_skill_start_session(int count) {
    return 'Bắt đầu phiên ($count)';
  }

  @override
  String get project_skill_catalog_hint =>
      'Chọn từ các kỹ năng giống tab Skills trong Mind.';

  @override
  String get project_auto_add_all_skills => 'Tạo kỹ năng mới';

  @override
  String get project_auto_add_all_skills_subtitle =>
      'Tạo kỹ năng hoàn toàn mới cho Mind và dự án này';

  @override
  String get project_skill_already_exists => 'Kỹ năng này đã tồn tại';

  @override
  String get project_skill_name_too_long =>
      'Tên kỹ năng quá dài (tối đa 24 ký tự)';

  @override
  String get project_skills_all_on_project =>
      'Tất cả kỹ năng Mind đã có trong dự án';

  @override
  String project_skills_added_count(int count) {
    return 'Đã thêm $count kỹ năng';
  }

  @override
  String project_skill_delete_confirm(String name) {
    return 'Xóa \"$name\" khỏi dự án này?';
  }

  @override
  String get project_skill_added => 'Đã thêm kỹ năng';

  @override
  String project_skill_xp_granted(int xp) {
    return 'Kỹ năng +$xp XP';
  }

  @override
  String get project_sub_projects_label => 'Dự án con';

  @override
  String get project_no_sub_projects => 'Chưa có dự án con. Nhấn + để thêm.';

  @override
  String get project_add_sub_project_title => 'Dự án con mới';

  @override
  String get project_sub_project_name_hint => 'Tên dự án con';

  @override
  String get project_add_task_title => 'Nhiệm vụ mới';

  @override
  String get project_task_assign_to => 'Gán cho dự án';

  @override
  String get project_task_title_hint => 'Tiêu đề nhiệm vụ';

  @override
  String get project_sdlc_board_title => 'Bảng SDLC';

  @override
  String get project_sdlc_open => 'Mở bảng SDLC';

  @override
  String get project_sdlc_add_task_title => 'Thêm nhiệm vụ SDLC';

  @override
  String get project_sdlc_move_phase => 'Giai đoạn SDLC';

  @override
  String get project_sdlc_due_date => 'Hạn hoàn thành';

  @override
  String get project_sdlc_due_date_none => 'Chưa đặt hạn';

  @override
  String get project_sdlc_clear_due_date => 'Xóa hạn';

  @override
  String get project_sdlc_default_purpose =>
      'Xác định dự án cần giao gì và vì sao.';

  @override
  String get project_sdlc_empty =>
      'Chưa có nhiệm vụ đang làm. Chạm + để thêm vào một giai đoạn.';

  @override
  String get project_sdlc_column_empty => 'Chưa có nhiệm vụ';

  @override
  String get project_sdlc_add_to_phase => 'Thêm nhiệm vụ vào giai đoạn này';

  @override
  String get project_sdlc_drop_here => 'Thả để chuyển sang đây';

  @override
  String project_sdlc_task_moved(String phase) {
    return 'Đã chuyển sang $phase';
  }

  @override
  String project_sdlc_phase_stat(int phase, int count) {
    return 'P$phase: $count';
  }

  @override
  String get project_sdlc_phase_planning_title => 'Lập kế hoạch & yêu cầu';

  @override
  String get project_sdlc_phase_planning_hint => 'SRS, khả thi';

  @override
  String get project_sdlc_phase_design_title => 'Kiến trúc & thiết kế';

  @override
  String get project_sdlc_phase_design_hint => 'Tech stack, UI';

  @override
  String get project_sdlc_phase_implementation_title => 'Triển khai';

  @override
  String get project_sdlc_phase_implementation_hint => 'Code, Git, review';

  @override
  String get project_sdlc_phase_testing_title => 'Kiểm thử & QA';

  @override
  String get project_sdlc_phase_testing_hint => 'Unit, tích hợp, UAT';

  @override
  String get project_sdlc_phase_deployment_title => 'Triển khai sản phẩm';

  @override
  String get project_sdlc_phase_deployment_hint => 'CI/CD, phát hành';

  @override
  String get project_sdlc_phase_maintenance_title => 'Vận hành & bảo trì';

  @override
  String get project_sdlc_phase_maintenance_hint => 'Giám sát, vá lỗi, mở rộng';

  @override
  String get project_sdlc_no_project => 'Hãy tạo dự án trước khi mở bảng SDLC.';

  @override
  String get project_sdlc_pick_project => 'Chọn dự án cho bảng SDLC';

  @override
  String get task_delete_tooltip => 'Xóa nhiệm vụ';

  @override
  String get task_delete_confirm_title => 'Xóa nhiệm vụ';

  @override
  String task_delete_confirm_msg(String name) {
    return 'Bạn có chắc chắn muốn xóa \"$name\"? Không thể hoàn tác.';
  }

  @override
  String get task_deleted_msg => 'Đã xóa nhiệm vụ';

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
  String get recent_updates => 'Cập nhật gần đây';

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
  String get note_editor_write_hint => 'Bắt đầu viết ghi chú…';

  @override
  String note_editor_saved_label(String when) {
    return 'Đã lưu $when';
  }

  @override
  String get note_editor_saved_just_now => 'vừa xong';

  @override
  String note_editor_saved_minutes(int count) {
    return '$count phút trước';
  }

  @override
  String note_editor_saved_hours(int count) {
    return '$count giờ trước';
  }

  @override
  String get note_editor_unsaved => 'Chưa lưu';

  @override
  String get note_editor_saving => 'Đang lưu…';

  @override
  String get focus_select_project => 'CHẠM ĐỂ CHỌN DỰ ÁN';

  @override
  String get focus_select_task => 'CHỌN NHIỆM VỤ';

  @override
  String focus_active_exercise(String type) {
    return 'BÀI TẬP ĐANG HOẠT ĐỘNG: $type';
  }

  @override
  String get focus_flow_active => 'TRẠNG THÁI TẬP TRUNG';

  @override
  String get focus_breathing => 'ĐANG THỞ';

  @override
  String get focus_fetching_audio => 'ĐANG TẢI ÂM THANH...';

  @override
  String get entry_scanning => 'ĐANG QUÉT';

  @override
  String get entry_assembling => 'ĐANG LẮP RÁP';

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
  String get delete_account => 'Xóa tài khoản';

  @override
  String get delete_account_subtitle => 'Đăng xuất và xóa hồ sơ đám mây';

  @override
  String get delete_account_plan_title => 'Kế hoạch đề xuất trước khi xóa';

  @override
  String get delete_account_plan_intro => 'Xem các bước khi bạn tiếp tục:';

  @override
  String get delete_account_plan_step1 =>
      'Bạn sẽ đăng xuất trên thiết bị này và dữ liệu đăng nhập đã lưu trong bộ nhớ bảo mật sẽ bị xóa.';

  @override
  String get delete_account_plan_step2 =>
      'Nếu dự án triển khai Edge Function Supabase \"delete-account\", tài khoản xác thực và dòng liên quan có thể được xóa phía máy chủ.';

  @override
  String get delete_account_plan_step3 =>
      'Trước khi có endpoint đó, dữ liệu đám mây có thể vẫn tồn tại — liên hệ hỗ trợ hoặc yêu cầu xóa đầy đủ theo chính sách bảo mật.';

  @override
  String get delete_account_acknowledge =>
      'Tôi hiểu tài khoản có thể chưa bị xóa hoàn toàn trên máy chủ cho đến khi backend bật xóa.';

  @override
  String get delete_account_type_key_word => 'XOA-TAI-KHOAN';

  @override
  String delete_account_type_key_prompt(String word) {
    return 'Nhập $word để xác nhận:';
  }

  @override
  String get delete_account_confirm => 'Xóa và đăng xuất';

  @override
  String get delete_account_cancel => 'Hủy';

  @override
  String get delete_account_success =>
      'Bạn đã đăng xuất. Việc xóa hoàn toàn trên đám mây có thể mất tới 48 giờ sau khi bật.';

  @override
  String get delete_account_err_not_signed_in => 'Không có phiên đăng nhập.';

  @override
  String get remaining => 'Còn lại';

  @override
  String get notification_manager_title => 'Thông báo';

  @override
  String get notification_hunter_hub => 'Trung tâm thông báo';

  @override
  String get notification_tab_active => 'ĐANG CHẠY';

  @override
  String get notification_tab_reminders => 'NHẮC NHỞ';

  @override
  String get notification_tab_wisdom => 'TRÍ TUỆ';

  @override
  String get notification_ai_no_data => 'Không có dữ liệu.';

  @override
  String get notification_ai_advice => 'LỜI KHUYÊN';

  @override
  String get notification_ai_waiting => 'Đang thu thập tình báo...';

  @override
  String get notification_ai_analysis => 'PHÂN TÍCH AI';

  @override
  String get notification_daily_quest => 'NHIỆM VỤ HÀNG NGÀY';

  @override
  String get notification_no_active_quests =>
      'Chưa có nhiệm vụ đang hoạt động. Hoàn thành công việc trong Dự án để nhận nhiệm vụ hàng ngày.';

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
  String get notification_system_preferences => 'TÙY CHỌN HỆ THỐNG';

  @override
  String get notification_pomodoro_reminder_title => 'Nhắc Pomodoro';

  @override
  String get notification_pomodoro_reminder_subtitle =>
      'Nhận thông báo khi hoàn thành một phiên Pomodoro hoặc kết thúc giờ nghỉ.';

  @override
  String get notification_live_activities_title => 'Hoạt động trực tiếp';

  @override
  String get notification_live_activities_subtitle =>
      'Theo dõi bộ đếm tập trung trên Màn hình khóa.';

  @override
  String get notification_morning_briefing_subtitle =>
      'Lịch hôm nay, tóm tắt hôm qua và động lực khi mở Home lần đầu (5:00–11:59).';

  @override
  String get notification_status_on => 'bật';

  @override
  String get notification_status_off => 'tắt';

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
  String get notification_inbox_title => 'Thông báo';

  @override
  String get notification_mission_history => 'Lịch sử nhiệm vụ';

  @override
  String get notification_mission_success => 'NHIỆM VỤ THÀNH CÔNG';

  @override
  String get notification_focus_complete => 'TẬP TRUNG HOÀN TẤT';

  @override
  String get notification_task_success => 'NHIỆM VỤ XONG';

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
  String get finance_txn_source_account => 'Chi từ';

  @override
  String get finance_txn_source_account_none => 'Không chọn';

  @override
  String get finance_txn_source_account_empty =>
      'Hãy lưu ví/tài khoản trước, sau đó chọn nguồn khi ghi chi tiêu.';

  @override
  String get finance_txn_source_account_add => 'Thêm tài khoản';

  @override
  String get finance_txn_source_account_required =>
      'Hãy chọn ví/tài khoản chi tiền.';

  @override
  String get finance_recurring_income => 'Thu nhập định kỳ';

  @override
  String get finance_recurring_interval => 'Lặp lại mỗi';

  @override
  String get finance_fixed_income_title => 'Thu nhập cố định';

  @override
  String get finance_fixed_income_subtitle =>
      'Vốn con người (kỹ năng), lương, tiền thuê và các khoản thu ổn định khác';

  @override
  String get finance_fixed_income_monthly_total => 'Tổng / tháng';

  @override
  String get finance_fixed_income_empty => 'Chưa có thu nhập cố định';

  @override
  String get finance_shortcut_transaction => 'Giao dịch';

  @override
  String get finance_shortcut_account => 'Tài khoản';

  @override
  String get finance_shortcut_asset => 'Tài sản';

  @override
  String get finance_shortcut_income => 'Thu nhập';

  @override
  String get finance_fixed_income_add => 'Thêm thu nhập cố định';

  @override
  String get finance_fixed_income_new => 'Thu nhập cố định mới';

  @override
  String get finance_fixed_income_edit => 'Sửa thu nhập cố định';

  @override
  String get finance_fixed_income_name => 'Tên khoản thu';

  @override
  String get finance_fixed_income_next => 'Lần nhận tiếp theo';

  @override
  String get finance_fixed_income_delete_confirm =>
      'Xóa lịch thu nhập cố định này?';

  @override
  String get finance_insight_title => 'Phân tích';

  @override
  String get finance_insight_suggestions => 'Gợi ý';

  @override
  String get finance_insight_enter_amount =>
      'Nhập số tiền để xem ảnh hưởng tới tháng này.';

  @override
  String finance_insight_fixed_after(String amount) {
    return 'Sau khi lưu: khoảng $amount/tháng thu nhập cố định.';
  }

  @override
  String finance_insight_covers_spending(String percent, String spent) {
    return 'Bao phủ khoảng $percent% chi tiêu đã ghi trong tháng ($spent).';
  }

  @override
  String finance_insight_shortfall(String amount) {
    return 'Vẫn thiếu khoảng $amount so với chi tiêu tháng.';
  }

  @override
  String finance_insight_surplus(String amount) {
    return 'Còn khoảng $amount/tháng sau chi tiêu thường.';
  }

  @override
  String finance_insight_duplicate_fixed(String name) {
    return 'Bạn đã có thu nhập cố định “$name” — tránh ghi trùng.';
  }

  @override
  String finance_insight_expense_share(String percent) {
    return 'Khoản này chiếm khoảng $percent% chi tiêu tháng này.';
  }

  @override
  String get finance_insight_expense_large =>
      'Chi tiêu lớn một lần — kiểm tra lại danh mục.';

  @override
  String finance_insight_income_share(String percent) {
    return 'Tăng khoảng $percent% thu nhập đã ghi trong tháng.';
  }

  @override
  String finance_insight_recurring_equiv(String amount) {
    return 'Nếu lặp lại: thêm khoảng $amount/tháng ngoài thu cố định.';
  }

  @override
  String finance_insight_savings_total(String amount) {
    return 'Số dư tiết kiệm sẽ khoảng $amount.';
  }

  @override
  String get finance_interval_weekly => 'Tuần';

  @override
  String get finance_interval_monthly => 'Tháng';

  @override
  String get finance_interval_yearly => 'Năm';

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
  String get finance_daily_report_title => 'Báo cáo trong ngày';

  @override
  String get finance_daily_report_reminder => 'Nhắc hàng ngày';

  @override
  String get finance_daily_report_reminder_subtitle =>
      'Thông báo cục bộ mở báo cáo này';

  @override
  String get finance_daily_report_open => 'Mở báo cáo trong ngày';

  @override
  String get finance_daily_report_income => 'Thu nhập';

  @override
  String get finance_daily_report_expense => 'Chi tiêu';

  @override
  String get finance_daily_report_net => 'Chênh lệch';

  @override
  String get finance_daily_report_spending_by_category =>
      'Chi tiêu theo hạng mục';

  @override
  String get finance_daily_report_today_transactions => 'Hoạt động hôm nay';

  @override
  String get finance_daily_report_empty_day => 'Chưa có giao dịch trong ngày.';

  @override
  String get finance_daily_report_notifications_off =>
      'Bật thông báo hệ thống trong Cài đặt để dùng nhắc nhở.';

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
  String get finance_subscriptions_active_header => 'ĐĂNG KÝ ĐANG HOẠT ĐỘNG';

  @override
  String get finance_subscriptions_monthly_total => 'TỔNG HÀNG THÁNG';

  @override
  String get finance_subscriptions_next_month_header => 'KẾ HOẠCH THÁNG SAU';

  @override
  String get finance_subscriptions_next_month_total => 'TỔNG DỰ KIẾN';

  @override
  String get finance_subscriptions_next_month_empty =>
      'Không có khoản đăng ký nào trong tháng sau.';

  @override
  String get finance_subscriptions_next_month_remove_tooltip =>
      'Bỏ khỏi kế hoạch tháng này';

  @override
  String get finance_subscriptions_next_month_remove_title =>
      'BỎ KHỎI KẾ HOẠCH';

  @override
  String get finance_subscriptions_next_month_remove_message =>
      'Chỉ bỏ khoản này khỏi kế hoạch tháng sau. Đăng ký vẫn hoạt động và sẽ hiện lại khi đến tháng thanh toán đó.';

  @override
  String get finance_subscriptions_next_month_remove_confirm => 'BỎ';

  @override
  String get finance_subscriptions_next_month_remove_action =>
      'BỎ KHỎI KẾ HOẠCH';

  @override
  String get finance_subscription_due_today => 'HẾT HẠN HÔM NAY';

  @override
  String finance_subscription_days_left(int days) {
    return 'CÒN $days NGÀY';
  }

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
  String get finance_cat_human_capital => 'Vốn con người';

  @override
  String get finance_inflow_pillar_human_capital => 'Vốn con người';

  @override
  String get finance_inflow_pillar_liquidity => 'Thanh khoản';

  @override
  String get finance_inflow_pillar_fixed_income => 'Thu nhập cố định';

  @override
  String get finance_inflow_pillar_investment => 'Đầu tư';

  @override
  String get finance_inflow_pillar_cashflow => 'Dòng tiền';

  @override
  String get finance_inflow_pillars_title => 'Các lớp thu vào';

  @override
  String get finance_inflow_pillars_subtitle =>
      'Kỹ năng & việc làm, tiền mặt, thu ổn định, tài sản tăng trưởng, hệ thống định kỳ';

  @override
  String get finance_asset_pillars_title => 'Lớp tài sản';

  @override
  String get finance_asset_pillars_subtitle =>
      'Thanh khoản, thu nhập cố định, đầu tư, dòng tiền';

  @override
  String get finance_asset_pillar_liquidity => 'Thanh khoản';

  @override
  String get finance_asset_pillar_fixed_income => 'Thu nhập cố định';

  @override
  String get finance_asset_pillar_investment => 'Đầu tư';

  @override
  String get finance_asset_pillar_cashflow => 'Dòng tiền';

  @override
  String get finance_record_section_title => 'Ghi nhận';

  @override
  String get finance_record_section_subtitle =>
      'Thêm tài khoản, tài sản, vốn con người và subscription';

  @override
  String get finance_record_human_capital => 'Vốn con người';

  @override
  String get finance_record_human_capital_hint =>
      'Năng lực / capacity (ước tính)';

  @override
  String get finance_record_liquidity_account => 'TK thanh khoản';

  @override
  String get finance_record_liquidity_hint => 'Tiền mặt, ngân hàng';

  @override
  String get finance_record_fixed_income_asset => 'TS thu nhập cố định';

  @override
  String get finance_record_fixed_income_hint => 'Trái phiếu, tiết kiệm';

  @override
  String get finance_record_investment_account => 'TK đầu tư';

  @override
  String get finance_record_investment_account_hint =>
      'CTCK, crypto, ví broker';

  @override
  String get finance_record_investment_holding => 'TS đầu tư';

  @override
  String get finance_record_investment_holding_hint => 'Cổ phiếu, crypto, BĐS';

  @override
  String get finance_account_type_checking => 'Thanh toán';

  @override
  String get finance_account_type_savings => 'Tiết kiệm';

  @override
  String get finance_account_type_cash => 'Tiền mặt';

  @override
  String get finance_account_type_credit_card => 'Thẻ tín dụng';

  @override
  String get finance_account_type_deposit => 'Gửi có kỳ hạn';

  @override
  String get finance_account_type_investment => 'Tài khoản đầu tư';

  @override
  String get finance_budget_limit_title => 'Giới hạn chi tiêu';

  @override
  String get finance_budget_limit_label => 'Số tiền giới hạn';

  @override
  String get finance_budget_limit_per_week => 'Theo tuần';

  @override
  String get finance_budget_limit_per_month => 'Theo tháng';

  @override
  String get finance_add_account_title => 'Thêm tài khoản';

  @override
  String get finance_account_type_section => 'Loại tài khoản';

  @override
  String get finance_accounts_liquidity_title => 'Tài khoản thanh khoản';

  @override
  String get finance_accounts_investment_title => 'Tài khoản đầu tư';

  @override
  String get finance_account_investment_name_hint =>
      'VD: VNDirect, SSI, Binance';

  @override
  String get finance_record_cashflow_asset => 'TS dòng tiền';

  @override
  String get finance_record_cashflow_hint => 'SaaS, hệ thống định kỳ';

  @override
  String get finance_record_subscription => 'Subscription';

  @override
  String get finance_record_subscription_hint => 'Chi phí lặp lại';

  @override
  String get finance_record_contract_hint => 'Thu nhập một lần theo hợp đồng';

  @override
  String get finance_record_bonus_hint => 'Thưởng một lần';

  @override
  String get finance_bonus_section_title => 'Thưởng & Hợp đồng';

  @override
  String get finance_bonus_section_subtitle =>
      'Thu nhập một lần từ thưởng và hợp đồng';

  @override
  String get finance_bonus_section_total => 'Tổng';

  @override
  String get finance_bonus_section_empty =>
      'Chưa có thu nhập thưởng hay hợp đồng';

  @override
  String get finance_total_income_title => 'Tổng thu nhập';

  @override
  String get finance_total_income_recurring => 'Định kỳ / tháng';

  @override
  String get finance_total_income_onetime => 'Một lần';

  @override
  String get finance_hc_capacity_label => 'Capacity';

  @override
  String get finance_hc_realized_label => 'Đã nhận';

  @override
  String get finance_hc_gap_title => 'Vốn con người';

  @override
  String finance_hc_gap_message(String capacity, String received, String gap) {
    return 'Capacity $capacity · nhận $received · chênh $gap';
  }

  @override
  String get finance_add_asset_title => 'Thêm tài sản';

  @override
  String get finance_add_asset_category => 'Loại tài sản';

  @override
  String get finance_add_asset_name => 'Tên / mã';

  @override
  String get finance_add_asset_value => 'Giá trị ước tính';

  @override
  String get finance_add_asset_save => 'Lưu tài sản';

  @override
  String get finance_asset_cat_stock => 'Cổ phiếu';

  @override
  String get finance_asset_cat_crypto => 'Crypto';

  @override
  String get finance_asset_cat_bond => 'Trái phiếu';

  @override
  String get finance_asset_cat_deposit => 'Tiết kiệm';

  @override
  String get finance_asset_cat_real_estate => 'Bất động sản';

  @override
  String get finance_asset_cat_cashflow => 'Dòng tiền (SaaS)';

  @override
  String get finance_cat_skills => 'Kỹ năng';

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
  String get finance_cat_impulse => 'Thắng xung động';

  @override
  String get finance_quick_save_title => 'Ghi tiết kiệm';

  @override
  String get finance_quick_save_subtitle =>
      'Số tiền bạn giữ lại—thường vì đã không chi.';

  @override
  String get finance_quick_note_label => 'Đã không mua gì (tuỳ chọn)';

  @override
  String get finance_quick_full_form => 'Đầy đủ thông tin';

  @override
  String get finance_quick_log => 'Lưu';

  @override
  String get finance_quick_chip_impulse => 'Cưỡng lại';

  @override
  String get finance_quick_chip_coffee => 'Bỏ món nhỏ';

  @override
  String get finance_quick_chip_shopping => 'Không mua';

  @override
  String get finance_quick_chip_sale => 'Bỏ sale';

  @override
  String get finance_quick_chip_goal => 'Gửi mục tiêu';

  @override
  String get finance_quick_chip_emergency => 'Dự phòng';

  @override
  String get finance_quick_desc_impulse => 'Cưỡng lại cơn muốn mua';

  @override
  String get finance_quick_desc_coffee => 'Bỏ cà phê/ăn vặt';

  @override
  String get finance_quick_desc_shopping => 'Từ bỏ một món định mua';

  @override
  String get finance_quick_desc_sale => 'Không mua theo sale';

  @override
  String get finance_quick_desc_goal => 'Gửi thêm cho mục tiêu';

  @override
  String get finance_quick_desc_emergency => 'Thêm quỹ dự phòng';

  @override
  String get finance_quick_affirm_impulse => 'Bạn vừa trả cho tương lai.';

  @override
  String get finance_quick_affirm_coffee => 'Bỏ một món nhỏ, giữ kỷ luật lớn.';

  @override
  String get finance_quick_affirm_shopping =>
      'Bạn chọn bình yên thay vì giỏ hàng.';

  @override
  String get finance_quick_affirm_sale =>
      'Bạn không để giảm giá quyết định thay bạn.';

  @override
  String get finance_quick_affirm_goal => 'Thêm một bước.';

  @override
  String get finance_quick_affirm_emergency => 'Lưới an toàn vững hơn.';

  @override
  String get finance_quick_affirm_default => 'Đã tiết kiệm. Kiên trì sinh lãi.';

  @override
  String get finance_quick_chip_custom => 'Tuỳ chỉnh';

  @override
  String get finance_award_unlocked => 'PHẦN THƯỞNG MỚI';

  @override
  String get finance_award_first_save_title => 'Viên gạch đầu tiên';

  @override
  String get finance_award_first_save_desc =>
      'Bạn vừa ghi lần tiết kiệm đầu tiên.';

  @override
  String get finance_award_three_streak_title => 'Ba ngày liên tiếp';

  @override
  String get finance_award_three_streak_desc => 'Ba ngày liền chọn tiết kiệm.';

  @override
  String get finance_award_seven_streak_title => 'Tuần ý chí';

  @override
  String get finance_award_seven_streak_desc => 'Bảy ngày liên tiếp tiết kiệm.';

  @override
  String get finance_award_thirty_streak_title => 'Tâm trí gộp lãi';

  @override
  String get finance_award_thirty_streak_desc =>
      'Ba mươi ngày đứng về phía bản thân.';

  @override
  String get finance_award_hundred_title => 'Trăm đầu tiên';

  @override
  String get finance_award_hundred_desc => 'Tổng tiết kiệm đã vượt một trăm.';

  @override
  String get finance_award_thousand_title => 'Bốn chữ số';

  @override
  String get finance_award_thousand_desc =>
      'Hơn một nghìn để dành. Đà đang lên.';

  @override
  String get finance_award_impulse_ten_title => 'Bậc thầy cơn thèm';

  @override
  String get finance_award_impulse_ten_desc =>
      'Mười lần thắng xung động. Dần đổi cách phản ứng.';

  @override
  String finance_streak_best(int count) {
    return 'Kỷ lục: $count ngày';
  }

  @override
  String get finance_streak_day_one => 'Bắt đầu chuỗi';

  @override
  String get finance_streak_keep => 'Đừng đứt chuỗi';

  @override
  String get finance_streak_strong => 'Bạn đang xây thứ thật sự.';

  @override
  String get finance_overview_streak_accessibility => 'Mở chuỗi tiết kiệm';

  @override
  String get finance_streak_label => 'CHUỖI';

  @override
  String finance_streak_days(int count) {
    return '$count ngày liên tiếp';
  }

  @override
  String get finance_quick_mood_prompt => 'Bạn đang cảm thấy thế nào?';

  @override
  String get finance_quick_why_label => 'Vì sao bạn tiết kiệm?';

  @override
  String get finance_cat_crypto => 'Tiền điện tử';

  @override
  String get finance_cat_stock => 'Tiết kiệm';

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
  String get ssh_connect_host_first =>
      'Hãy kết nối máy chủ trước khi quản lý phiên tmux.';

  @override
  String get ssh_cursor_api_title => 'Cursor API';

  @override
  String get ssh_cursor_api_subtitle =>
      'Lưu API key để dùng cursor-agent trên máy chủ từ xa.';

  @override
  String get ssh_cursor_api_key_hint => 'cursor_…';

  @override
  String get ssh_cursor_api_key_stored => 'Đã lưu API key trên thiết bị.';

  @override
  String get ssh_cursor_api_save => 'Lưu key';

  @override
  String get ssh_cursor_api_test => 'Kiểm tra kết nối';

  @override
  String get ssh_cursor_api_open_terminal => 'Mở SSH (chế độ Cursor)';

  @override
  String get ssh_cursor_api_saved => 'Đã lưu Cursor API key.';

  @override
  String get ssh_cursor_api_test_ok => 'Cursor API key hợp lệ.';

  @override
  String get ssh_cursor_api_missing_key =>
      'Nhập hoặc lưu Cursor API key trước.';

  @override
  String get cursor_hub_title => 'Cursor';

  @override
  String get cursor_hub_page_subtitle =>
      'Điều khiển Cursor trên Mac qua My Machines và Cloud Agents — không cần SSH.';

  @override
  String get cursor_hub_canvas_subtitle =>
      'Worker My Machines, gửi task API, bảng agents';

  @override
  String get cursor_hub_integration_subtitle =>
      'API key, thiết lập worker, gửi task từ điện thoại';

  @override
  String get cursor_hub_section_title => 'AI & tự động hóa';

  @override
  String get cursor_hub_key_ready => 'API key đã xác minh';

  @override
  String get cursor_hub_open_full => 'Mở Cursor Hub';

  @override
  String get cursor_hub_open_agents => 'Mở Agents';

  @override
  String get cursor_hub_worker_title => 'Worker My Machine';

  @override
  String get cursor_hub_worker_body =>
      'Trên Mac, chạy lệnh sau trong Terminal và giữ cửa sổ mở. Máy sẽ hiện tại cursor.com/agents.';

  @override
  String get cursor_hub_copy_worker_cmd => 'Sao chép lệnh';

  @override
  String get cursor_hub_worker_copied => 'Đã sao chép: agent worker start';

  @override
  String get cursor_hub_send_title => 'Gửi tác vụ';

  @override
  String get cursor_hub_target_machine => 'Mac của tôi';

  @override
  String get cursor_hub_target_cloud => 'Repo cloud';

  @override
  String get cursor_hub_machine_name => 'Tên máy (tùy chọn)';

  @override
  String get cursor_hub_machine_name_hint => 'Như trong menu môi trường Agents';

  @override
  String get cursor_hub_pick_repo => 'Kho lưu trữ của bạn';

  @override
  String get cursor_hub_refresh_repos => 'Làm mới danh sách repo';

  @override
  String get cursor_hub_repos_empty =>
      'Không tìm thấy repo. Nhập URL bên dưới hoặc dùng trên Mac để quét ~/Code.';

  @override
  String get cursor_hub_usage_limit =>
      'Cloud agent bị chặn: bật usage-based pricing trên cursor.com (~\$2). Dùng chế độ Mac của tôi.';

  @override
  String get cursor_hub_repo_url => 'URL repo GitHub';

  @override
  String get cursor_hub_prompt_label => 'Agent cần làm gì?';

  @override
  String get cursor_hub_send_task => 'Gửi tới Cursor';

  @override
  String get cursor_hub_task_sent => 'Đã gửi — đang mở agent…';

  @override
  String cursor_hub_task_failed(String reason) {
    return 'Không khởi chạy agent: $reason';
  }

  @override
  String get cursor_hub_recent_title => 'Agents gần đây';

  @override
  String get island_cursor_ssh_standby => 'Chờ kết nối SSH';

  @override
  String get island_cursor_no_api_key => 'Thiếu API key';

  @override
  String ssh_cursor_api_test_fail(String reason) {
    return 'Kết nối thất bại: $reason';
  }

  @override
  String get ssh_go_to_terminal => 'MỞ TERMINAL';

  @override
  String get ssh_no_tmux_sessions => 'Không có phiên tmux đang chạy.';

  @override
  String get journal => 'Nhật ký';

  @override
  String get social_notes => 'Ghi chú Tinh thần';

  @override
  String get btn_send_feedback => 'Gửi phản hồi';

  @override
  String get feedback_subtitle => 'Báo lỗi hoặc đề xuất tính năng mới';

  @override
  String get sync_engine_title => 'Động cơ đồng bộ';

  @override
  String get system_health => 'SỨC KHỎE HỆ THỐNG';

  @override
  String get uptime => 'THỜI GIAN HOẠT ĐỘNG';

  @override
  String get sync_method => 'PHƯƠNG THỨC ĐỒNG BỘ';

  @override
  String get refresh_rate => 'TẦN SUẤT LÀM MỚI';

  @override
  String get initialize_drive => 'KHỞI TẠO DRIVE';

  @override
  String get test_connection => 'KIỂM TRA KẾT NỐI';

  @override
  String get recent_activity => 'HOẠT ĐỘNG GẦN ĐÂY';

  @override
  String get live_logs => 'NHẬT KÝ TRỰC TIẾP';

  @override
  String get select_folder => 'CHỌN THƯ MỤC';

  @override
  String get my_drive => 'Drive của tôi';

  @override
  String get breadcrumb_separator => '>';

  @override
  String get drive_notion_complete => 'Drive → Notion Hoàn tất';

  @override
  String get scheduled_sweep => 'Quét định kỳ';

  @override
  String get standby => 'CHỜ';

  @override
  String get target_folder_id => 'ID THƯ MỤC MỤC TIÊU';

  @override
  String get internal_integration_token => 'MÃ TÍCH HỢP NỘI BỘ';

  @override
  String get database_schema_id => 'ID SƠ ĐỒ CƠ SỞ DỮ LIỆU';

  @override
  String get add_widget => 'Thêm Widget';

  @override
  String get app_shortcut => 'Lối tắt ứng dụng';

  @override
  String get web_widget => 'Tiện ích web';

  @override
  String get please_select_app_page => 'Vui lòng chọn một trang ứng dụng';

  @override
  String get widget_added_success => 'Đã thêm widget thành công';

  @override
  String error_adding_widget(String error) {
    return 'Lỗi khi thêm widget: $error';
  }

  @override
  String get please_select_plugin => 'Vui lòng chọn một plugin';

  @override
  String get please_fill_all_fields => 'Vui lòng điền đầy đủ các trường';

  @override
  String get widget_name_hint => 'Tên Widget (ví dụ: Facebook)';

  @override
  String get url_hint => 'URL (ví dụ: facebook.com)';

  @override
  String get plugins => 'Tiện ích';

  @override
  String get custom_url => 'URL tùy chỉnh';

  @override
  String get settings_title => 'Cài đặt';

  @override
  String get mind_latest_note => 'Ghi chú gần nhất';

  @override
  String get common_done => 'Xong';

  @override
  String get island_app_name => 'ICE GATE';

  @override
  String get island_app_blocker => 'CHẶN ỨNG DỤNG';

  @override
  String get island_initializing => 'ĐANG KHỞI TẠO…';

  @override
  String get island_notifications => 'THÔNG BÁO';

  @override
  String get island_inbox => 'HỘP THƯ';

  @override
  String get island_documentation => 'TÀI LIỆU';

  @override
  String get island_canvas => 'BẢNG GHÉP';

  @override
  String get island_mind => 'TÂM TRÍ';

  @override
  String get island_health_data => 'DỮ LIỆU';

  @override
  String get island_nutrition => 'DINH DƯỠNG';

  @override
  String get island_activity => 'VẬN ĐỘNG';

  @override
  String get island_hydration => 'NƯỚC UỐNG';

  @override
  String get island_focus => 'TẬP TRUNG';

  @override
  String get island_steps => 'BƯỚC CHÂN';

  @override
  String get island_vitals => 'CHỈ SỐ SỐNG';

  @override
  String get island_sleep => 'GIẤC NGỦ';

  @override
  String get island_calories => 'CALO';

  @override
  String get island_spo2 => 'SpO₂';

  @override
  String get island_biometrics => 'SINH TRẮC';

  @override
  String get finance_tab_overview => 'TỔNG QUAN';

  @override
  String get finance_tab_history => 'LỊCH SỬ';

  @override
  String get finance_tab_daily => 'TRONG NGÀY';

  @override
  String get finance_tab_daily_subtitle =>
      'Chi tiêu vui và thu nhập trong ngày — chọn ngày trên lịch.';

  @override
  String get finance_tab_achievements => 'THÀNH TỰU';

  @override
  String get finance_tab_career => 'SỰ NGHIỆP';

  @override
  String get finance_job_title => 'Vị trí công việc';

  @override
  String get finance_job_subtitle =>
      'Theo dõi nhà tuyển dụng, hợp đồng và thâm niên';

  @override
  String get finance_job_empty => 'Chưa có vị trí công việc';

  @override
  String get finance_job_current => 'Đang làm';

  @override
  String get finance_job_ended => 'Đã kết thúc';

  @override
  String finance_job_tenure(int months) {
    return '$months tháng';
  }

  @override
  String get finance_job_add => 'Thêm vị trí';

  @override
  String get finance_job_new => 'Vị trí mới';

  @override
  String get finance_job_edit => 'Sửa vị trí';

  @override
  String get finance_job_employer => 'Nhà tuyển dụng / công ty';

  @override
  String get finance_job_role => 'Chức danh / vai trò';

  @override
  String get finance_job_contract_type => 'Loại hợp đồng';

  @override
  String get finance_job_contract_full_time => 'Toàn thời gian';

  @override
  String get finance_job_contract_part_time => 'Bán thời gian';

  @override
  String get finance_job_contract_freelance => 'Freelance';

  @override
  String get finance_job_contract_internship => 'Thực tập';

  @override
  String get finance_job_contract_contract => 'Hợp đồng';

  @override
  String get finance_job_start_date => 'Ngày bắt đầu';

  @override
  String get finance_job_end_date => 'Ngày kết thúc';

  @override
  String get finance_job_end_date_hint => 'Để trống nếu đang làm';

  @override
  String get finance_job_notes => 'Ghi chú';

  @override
  String get finance_job_salary => 'Thu nhập / tháng';

  @override
  String get finance_job_salary_hint =>
      'Tạo thu nhập cố định gắn với công việc này';

  @override
  String get finance_job_income_type => 'Loại thu nhập';

  @override
  String get finance_job_income_salary => 'Lương';

  @override
  String get finance_job_income_contract => 'Thu nhập hợp đồng';

  @override
  String get finance_job_income_bonus => 'Thưởng';

  @override
  String finance_job_salary_suffix(String amount) {
    return '$amount / tháng';
  }

  @override
  String get finance_job_on_day => 'Công việc trong ngày';

  @override
  String get finance_job_delete_confirm => 'Xóa vị trí công việc này?';

  @override
  String get finance_job_end_confirm => 'Đánh dấu vị trí này kết thúc hôm nay?';

  @override
  String get finance_job_work_days => 'Ngày làm việc';

  @override
  String get finance_job_log_today => 'Ghi hôm nay';

  @override
  String finance_job_work_streak(int count) {
    return '$count ngày liên tiếp';
  }

  @override
  String get finance_job_time_sheet_subtitle =>
      'Kế hoạch thời gian và bắt đầu làm việc';

  @override
  String get finance_job_time_plan => 'Kế hoạch hôm nay';

  @override
  String get finance_job_time_category => 'Loại công việc';

  @override
  String get finance_job_time_start => 'Bắt đầu';

  @override
  String get finance_job_time_log_now => 'Log ngay';

  @override
  String get finance_job_time_start_timer => 'Bấm giờ';

  @override
  String finance_job_time_logged(int minutes) {
    return 'Đã log $minutes phút';
  }

  @override
  String get finance_job_time_stop => 'Dừng';

  @override
  String finance_job_time_minutes(int minutes) {
    return '$minutes phút';
  }

  @override
  String finance_job_time_elapsed(int minutes) {
    return 'Đã làm $minutes phút';
  }

  @override
  String finance_job_time_actual_summary(int actual, int planned) {
    return 'Thực tế: $actual phút / kế hoạch: $planned phút';
  }

  @override
  String get finance_job_time_category_code_vibe => 'Vibe code';

  @override
  String get finance_job_time_category_code_manual => 'Code tay';

  @override
  String get finance_job_time_category_sales_desk => 'Sales bàn';

  @override
  String get finance_job_time_category_sales_field => 'Sales ngoài đường';

  @override
  String get finance_job_time_category_communication => 'Giao tiếp';

  @override
  String get finance_job_time_category_meditation => 'Thiền';

  @override
  String get finance_job_task_group_code => 'Code';

  @override
  String get finance_job_task_group_sales => 'Sales';

  @override
  String get finance_job_task_group_speech => 'Nói';

  @override
  String get finance_job_task_group_health => 'Sức khỏe';

  @override
  String get finance_job_task_group_time_log => 'Log thời gian';

  @override
  String get finance_job_task_add_job => 'Thêm task';

  @override
  String get finance_job_sub_task_name => 'Tên task';

  @override
  String get finance_job_time_log => 'Log thời gian';

  @override
  String get finance_job_time_log_title => 'Log thời gian';

  @override
  String get finance_job_task_read_docs => 'Đọc tài liệu';

  @override
  String get finance_job_task_sales_customer => 'Tiếp xúc khách hàng';

  @override
  String get finance_job_task_sales_report => 'Làm báo cáo';

  @override
  String get finance_job_task_pick_group => 'Chọn loại công việc';

  @override
  String get finance_job_task_full_time => 'Full-time';

  @override
  String get finance_job_task_part_time => 'Part-time';

  @override
  String get finance_job_task_part_time_hours => 'Số giờ làm';

  @override
  String get finance_job_task_part_time_save => 'Ghi giờ';

  @override
  String get finance_job_task_pick_detail => 'Chọn chi tiết';

  @override
  String get finance_job_history => 'Lịch sử';

  @override
  String get finance_job_history_title => 'Lịch sử làm việc';

  @override
  String get finance_job_history_subtitle =>
      'Đồng bộ từ log thời gian công việc';

  @override
  String get finance_job_history_empty => 'Chưa có thời gian được ghi';

  @override
  String get finance_job_present => 'đến nay';

  @override
  String get finance_job_time_notes => 'Ghi chú';

  @override
  String get finance_job_time_notes_hint => 'Bạn đã làm gì?';

  @override
  String get finance_job_customer_title => 'Khách hàng';

  @override
  String get finance_job_customer_name => 'Tên khách hàng';

  @override
  String get finance_job_customer_company => 'Công ty';

  @override
  String get finance_job_customer_phone => 'Số điện thoại';

  @override
  String get finance_job_customer_save => 'Lưu khách hàng';

  @override
  String finance_job_customer_existing(int count) {
    return 'Đã có $count khách hàng';
  }

  @override
  String get finance_job_customer_open_form => 'Mở form thêm khách';

  @override
  String get finance_achievements_subtitle =>
      'Thành tựu tài chính lớn theo tháng và năm.';

  @override
  String get finance_period_month => 'Tháng';

  @override
  String get finance_period_year => 'Năm';

  @override
  String get finance_daily_in => 'Tiền vào';

  @override
  String get finance_daily_out => 'Tiền ra';

  @override
  String get finance_daily_empty => 'Chưa có giao dịch trong ngày này';

  @override
  String get finance_achievements_empty => 'Chưa có thành tựu lớn trong kỳ này';

  @override
  String get finance_achievements_add => 'Ghi thành tựu';

  @override
  String get finance_milestone_month_income => 'Thu nhập tháng';

  @override
  String get finance_milestone_month_savings => 'Tiết kiệm tháng';

  @override
  String get finance_milestone_year_total => 'Tổng thu năm';

  @override
  String get finance_tab_billing => 'HÓA ĐƠN';

  @override
  String get finance_tab_saving => 'TIẾT KIỆM';

  @override
  String get island_documents => 'TÀI LIỆU';

  @override
  String get island_editor => 'SOẠN THẢO';

  @override
  String get island_identity => 'DANH TÍNH';

  @override
  String get island_id_update => 'CẬP NHẬT ID';

  @override
  String get island_protocols => 'QUY TRÌNH';

  @override
  String get island_sync_core => 'ĐỒNG BỘ';

  @override
  String get island_settings => 'CÀI ĐẶT';

  @override
  String get island_remote_ssh => 'SSH TỪ XA';

  @override
  String get island_connected => 'ĐÃ KẾT NỐI';

  @override
  String get island_not_active => 'CHƯA HOẠT ĐỘNG';

  @override
  String get island_connect => 'KẾT NỐI';

  @override
  String get island_tmux_active => 'TMUX ĐANG CHẠY';

  @override
  String get daily_loop_title => 'Vòng hôm nay';

  @override
  String get daily_loop_subtitle => 'Hoàn thành cả 4 trụ cột để giữ chuỗi';

  @override
  String get daily_loop_complete => 'Xong vòng hôm nay — quá đỉnh!';

  @override
  String daily_loop_streak(int count) {
    return '$count ngày';
  }

  @override
  String daily_loop_progress(int done, int total) {
    return '$done / $total xong';
  }

  @override
  String get daily_loop_health => 'Sức khỏe';

  @override
  String get daily_loop_finance => 'Tài chính';

  @override
  String get daily_loop_mind => 'Tâm trạng';

  @override
  String get daily_loop_projects => 'Dự án';

  @override
  String get morning_loop_reminder_title => 'Thông báo đẩy buổi sáng';

  @override
  String get morning_loop_reminder_subtitle =>
      'Tùy chọn trên điện thoại — tóm tắt trong app trên Home vẫn hoạt động khi tắt';

  @override
  String get morning_briefing_toggle => 'Tóm tắt sáng trên Home';

  @override
  String get morning_briefing_today_schedule => 'Lịch hôm nay';

  @override
  String get morning_briefing_today_empty =>
      'Không có sự kiện — một ngày trống để lên kế hoạch.';

  @override
  String get morning_briefing_today_connect_hint =>
      'Kết nối Google hoặc lịch máy để xem sự kiện hôm nay tại đây.';

  @override
  String morning_briefing_today_more(int count) {
    return '+$count sự kiện nữa trong lịch';
  }

  @override
  String get morning_briefing_all_day => 'Cả ngày';

  @override
  String get morning_briefing_open_calendar => 'Mở lịch';

  @override
  String get morning_briefing_title => 'Chào buổi sáng';

  @override
  String morning_briefing_title_name(String name) {
    return 'Chào buổi sáng, $name';
  }

  @override
  String get morning_briefing_subtitle =>
      'Chăm cơ thể, ổn định tinh thần — rồi hoàn thành vòng 4 trụ cột trong ngày.';

  @override
  String get morning_briefing_yesterday_title => 'Hôm qua';

  @override
  String get morning_briefing_yesterday_empty =>
      'Ngày êm ả — hôm nay là khởi đầu mới.';

  @override
  String morning_briefing_yesterday_steps(int steps) {
    return '$steps bước chân';
  }

  @override
  String morning_briefing_yesterday_water(int ml) {
    return '$ml ml nước';
  }

  @override
  String morning_briefing_yesterday_sleep(String hours) {
    return 'Ngủ $hours giờ';
  }

  @override
  String morning_briefing_yesterday_loop(int done, int total) {
    return 'Hoàn thành $done/$total trụ cột';
  }

  @override
  String get morning_briefing_motivation_title => 'Động lực hôm nay';

  @override
  String get morning_briefing_motivation_empty =>
      'Hôm qua nhẹ nhàng — một chiến thắng nhỏ hôm nay là đủ để lấy lại nhịp.';

  @override
  String get morning_briefing_motivation_all_done =>
      'Bạn kết thúc hôm qua rất tốt — giữ đà đó sang hôm nay nhé.';

  @override
  String get morning_briefing_motivation_strong =>
      'Tiến bộ vững hôm qua — thêm một trụ cột hôm nay để giữ chuỗi.';

  @override
  String get morning_briefing_motivation_mid =>
      'Bạn đã tiến lên hôm qua — thêm một bước nhỏ sáng nay.';

  @override
  String get morning_briefing_motivation_low =>
      'Hôm qua là ngày nghỉ — uống nước, đi bộ hoặc ghi tâm trạng cũng là khởi đầu tốt.';

  @override
  String morning_briefing_progress(int done, int total) {
    return 'Đã xong $done/$total trụ cột hôm nay';
  }

  @override
  String get morning_briefing_start => 'Bắt đầu ngày mới';

  @override
  String get morning_briefing_log_mood => 'Ghi tâm trạng trước';
}
