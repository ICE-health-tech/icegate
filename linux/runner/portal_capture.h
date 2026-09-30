#ifndef FLUTTER_MY_APPLICATION_PORTAL_CAPTURE_H_
#define FLUTTER_MY_APPLICATION_PORTAL_CAPTURE_H_

#include <flutter_linux/flutter_linux.h>
#include <glib-object.h>

G_BEGIN_DECLS

#ifdef __cplusplus
extern "C" {
#endif

// Cross-app screen capture via the XDG desktop portal.
// See portal_capture.cc for the transport and its current limitations.
G_DECLARE_FINAL_TYPE(PortalCapture, portal_capture, PORTAL_CAPTURE, GObject)

PortalCapture* portal_capture_new(FlBinaryMessenger* messenger);
void portal_capture_dispose(PortalCapture* self);

// Forward declaration: used as the channel's method-call handler and defined
// in portal_capture.cc.
void portal_capture_handle_method_call(FlMethodChannel* channel,
                                       FlMethodCall* method_call,
                                       gpointer user_data);

#ifdef __cplusplus
}  // extern "C"
#endif

G_END_DECLS

#endif  // FLUTTER_MY_APPLICATION_PORTAL_CAPTURE_H_
