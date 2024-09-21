#ifndef zikzak_inappWEBVIEW_PLUGIN_WEB_HISTORY_H_
#define zikzak_inappWEBVIEW_PLUGIN_WEB_HISTORY_H_

#include <flutter/standard_method_codec.h>
#include <optional>

#include "../utils/flutter.h"
#include "web_history_item.h"

namespace zikzak_inappwebview_plugin
{
  class WebHistory
  {
  public:
    const std::optional<int64_t> currentIndex;
    const std::optional<std::vector<std::shared_ptr<WebHistoryItem>>> list;

    WebHistory(const std::optional<int64_t> currentIndex, const std::optional<std::vector<std::shared_ptr<WebHistoryItem>>>& list);
    WebHistory(const flutter::EncodableMap& map);
    ~WebHistory() = default;

    flutter::EncodableMap toEncodableMap() const;
  };
}

#endif //zikzak_inappWEBVIEW_PLUGIN_WEB_HISTORY_H_
