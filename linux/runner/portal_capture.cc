// Cross-app screen capture on Linux via the XDG desktop portal
// (org.freedesktop.portal.Screenshot).
//
// The portal is the correct path under Wayland, where unrestricted root-window
// capture is blocked by design. The request itself is the consent prompt: the
// user may dismiss it, which is a normal no-capture rather than an error.
//
// If no portal daemon is running (bare X11 without xdg-desktop-portal), capture
// returns null and Dart falls back gracefully — it never surfaces an error.
//
// STATUS: this is the portal transport only. Reading the returned file:// URI
// and base64-encoding it for Dart is intentionally NOT implemented here rather
// than shipped untested. Until that lands, `capture` responds with null and the
// feature degrades to in-app (RepaintBoundary) capture. See
// docs/GUIDES/AutoScreenshotCaptureJob.md.

#include "portal_capture.h"

#include <flutter_linux/flutter_linux.h>
#include <gio/gio.h>
#include <string.h>

struct _PortalCapture {
  FlMethodChannel* channel;
  GDBusConnection* connection;
  guint response_subscription_id;
  // The in-flight capture call, if any. Owned reference; only one capture may
  // be pending at a time because the portal response carries no request id.
  FlMethodCall* pending_call;
};

static const gchar* kPortalName = "org.freedesktop.portal.Desktop";
static const gchar* kPortalPath = "/org/freedesktop/portal/desktop";
static const gchar* kScreenshotInterface = "org.freedesktop.portal.Screenshot";

PortalCapture* portal_capture_new(FlBinaryMessenger* messenger) {
  PortalCapture* self = g_new0(PortalCapture, 1);
  self->response_subscription_id = 0;
  self->pending_call = nullptr;

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel = fl_method_channel_new(
      messenger, "duylong.art/portal", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      self->channel, portal_capture_handle_method_call, self, nullptr);

  GError* error = nullptr;
  self->connection = g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &error);
  if (self->connection == nullptr) {
    g_warning(
        "PortalCapture: no session bus — cross-app capture unavailable: %s",
        error != nullptr ? error->message : "unknown error");
    g_clear_error(&error);
  }

  return self;
}

void portal_capture_dispose(PortalCapture* self) {
  if (self == nullptr) {
    return;
  }
  if (self->response_subscription_id != 0 && self->connection != nullptr) {
    g_dbus_connection_signal_unsubscribe(self->connection,
                                         self->response_subscription_id);
    self->response_subscription_id = 0;
  }
  g_clear_object(&self->pending_call);
  g_clear_object(&self->connection);
  g_clear_object(&self->channel);
  g_free(self);
}

G_DEFINE_AUTOPTR_CLEANUP_FUNC(GDBusConnection, g_object_unref)

static void respond_null_and_clear(PortalCapture* self) {
  if (self->pending_call == nullptr) {
    return;
  }
  g_autoptr(FlMethodCall) call = self->pending_call;
  self->pending_call = nullptr;
  fl_method_call_respond(call, fl_value_new_null(), nullptr);
}

static void on_screenshot_response(GDBusConnection* connection,
                                   const gchar* sender,
                                   const gchar* object_path,
                                   const gchar* interface_name,
                                   const gchar* signal_name,
                                   GVariant* parameters, gpointer user_data) {
  PortalCapture* self = PORTAL_CAPTURE(user_data);
  (void)connection;
  (void)sender;
  (void)object_path;
  (void)interface_name;
  (void)signal_name;

  guint32 response_code = 0;
  g_autoptr(GVariant) results = nullptr;
  g_variant_get(parameters, "(u@a{sv})", &response_code, &results);

  // 0 = success, 1 = dismissed by the user, 2 = other denial.
  // Both non-zero cases are normal outcomes, not errors.
  //
  // The success path is intentionally left unimplemented: it requires reading
  // the file:// URI and base64-encoding it for Dart. Rather than ship that
  // untested, respond with null and let the app fall back to in-app capture.
  if (response_code != 0) {
    respond_null_and_clear(self);
    return;
  }

  g_autoptr(GVariant) uri_value =
      g_variant_lookup_value(results, "uri", G_VARIANT_TYPE_STRING);
  if (uri_value == nullptr) {
    respond_null_and_clear(self);
    return;
  }

  respond_null_and_clear(self);
}

static void portal_capture_handle_method_call(FlMethodChannel* channel,
                                              FlMethodCall* method_call,
                                              gpointer user_data) {
  PortalCapture* self = PORTAL_CAPTURE(user_data);
  (void)channel;
  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "isSupported") == 0) {
    g_autoptr(FlValue) result = fl_value_new_bool(self->connection != nullptr);
    fl_method_call_respond(method_call, result, nullptr);
    return;
  }

  if (strcmp(method, "capture") != 0) {
    fl_method_call_respond(method_call, fl_value_new_null(), nullptr);
    return;
  }

  if (self->connection == nullptr) {
    // No portal daemon: degrade to no-capture rather than an error.
    fl_method_call_respond(method_call, fl_value_new_null(), nullptr);
    return;
  }

  if (self->pending_call != nullptr) {
    // A capture is already awaiting its portal response. The portal response
    // carries no request id, so overlapping calls cannot be correlated;
    // declining the second keeps exactly one in flight.
    fl_method_call_respond(method_call, fl_value_new_null(), nullptr);
    return;
  }

  self->pending_call = FL_METHOD_CALL(g_object_ref(method_call));

  self->response_subscription_id = g_dbus_connection_signal_subscribe(
      self->connection, kPortalName, kScreenshotInterface, "Response",
      kPortalPath, nullptr, G_DBUS_SIGNAL_FLAGS_NONE, on_screenshot_response,
      self, nullptr);

  g_autoptr(GVariantBuilder) options =
      g_variant_builder_new(G_VARIANT_TYPE("a{sv}"));

  g_autoptr(GError) error = nullptr;
  gboolean ok = g_dbus_connection_call(
      self->connection, kPortalName, kPortalPath, kScreenshotInterface,
      "Screenshot", g_variant_new("(sa{sv})", "", options),
      G_VARIANT_TYPE("(o)"), G_DBUS_CALL_FLAGS_NONE, -1, nullptr, nullptr,
      nullptr, &error);

  if (!ok) {
    g_dbus_connection_signal_unsubscribe(self->connection,
                                         self->response_subscription_id);
    self->response_subscription_id = 0;
    respond_null_and_clear(self);
    g_warning("PortalCapture: Screenshot call failed: %s",
              error != nullptr ? error->message : "unknown error");
    g_clear_error(&error);
  }
}
