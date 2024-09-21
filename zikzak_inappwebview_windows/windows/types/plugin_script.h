#ifndef zikzak_inappWEBVIEW_PLUGIN_PLUGIN_SCRIPT_H_
#define zikzak_inappWEBVIEW_PLUGIN_PLUGIN_SCRIPT_H_

#include "user_script.h"

namespace zikzak_inappwebview_plugin
{
  class PluginScript : public UserScript
  {
  public:

    PluginScript(
      const std::optional<std::string>& groupName,
      const std::string& source,
      const UserScriptInjectionTime& injectionTime,
      const std::vector<std::string>& allowedOriginRules,
      std::shared_ptr<ContentWorld> contentWorld,
      const bool& requiredInAllContentWorlds
    );
    ~PluginScript();

    bool isRequiredInAllContentWorlds() const
    {
      return requiredInAllContentWorlds_;
    }

    std::shared_ptr<PluginScript> copyAndSet(const std::shared_ptr<ContentWorld> cw) const;

  private:
    bool requiredInAllContentWorlds_;
  };
}
#endif //zikzak_inappWEBVIEW_PLUGIN_PLUGIN_SCRIPT_H_
