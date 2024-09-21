#ifndef zikzak_inappWEBVIEW_PLUGIN_WEBVIEW_ENVIRONMENT_CREATION_PARAMS_H_
#define zikzak_inappWEBVIEW_PLUGIN_WEBVIEW_ENVIRONMENT_CREATION_PARAMS_H_

#include <flutter/standard_method_codec.h>
#include <optional>
#include <string>

#include "../zikzak_inappwebview_windows_plugin.h"

namespace zikzak_inappwebview_plugin
{
  class WebViewEnvironmentSettings
  {
  public:
    const std::optional<std::string> browserExecutableFolder;
    const std::optional<std::string> userDataFolder;
    const std::optional<std::string> additionalBrowserArguments;
    const std::optional<bool> allowSingleSignOnUsingOSPrimaryAccount;
    const std::optional<std::string> language;
    const std::optional<std::string> targetCompatibleBrowserVersion;

    WebViewEnvironmentSettings() = default;
    WebViewEnvironmentSettings(const flutter::EncodableMap& map);
    ~WebViewEnvironmentSettings() = default;

    flutter::EncodableMap toEncodableMap() const;
  };
}
#endif //zikzak_inappWEBVIEW_PLUGIN_WEBVIEW_ENVIRONMENT_CREATION_PARAMS_H_
