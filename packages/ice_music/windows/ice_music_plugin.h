#ifndef FLUTTER_PLUGIN_ICE_MUSIC_PLUGIN_H_
#define FLUTTER_PLUGIN_ICE_MUSIC_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace ice_music {

class IceMusicPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  IceMusicPlugin();

  virtual ~IceMusicPlugin();

  // Disallow copy and assign.
  IceMusicPlugin(const IceMusicPlugin&) = delete;
  IceMusicPlugin& operator=(const IceMusicPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace ice_music

#endif  // FLUTTER_PLUGIN_ICE_MUSIC_PLUGIN_H_
