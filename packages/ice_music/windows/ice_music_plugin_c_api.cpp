#include "include/ice_music/ice_music_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "ice_music_plugin.h"

void IceMusicPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ice_music::IceMusicPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
