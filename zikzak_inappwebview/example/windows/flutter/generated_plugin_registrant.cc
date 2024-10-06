//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <url_launcher_windows/url_launcher_windows.h>
#include <zikzak_inappwebview_windows/flutter_inappwebview_windows_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  UrlLauncherWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherWindows"));
  FlutterInappwebviewWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterInappwebviewWindowsPluginCApi"));
}
