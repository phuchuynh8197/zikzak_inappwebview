#ifndef zikzak_inappWEBVIEW_PLUGIN_RECT_H_
#define zikzak_inappWEBVIEW_PLUGIN_RECT_H_

#include <flutter/standard_method_codec.h>
#include <optional>

#include "../utils/flutter.h"

namespace zikzak_inappwebview_plugin
{
  class Rect
  {
  public:
    const double x;
    const double y;
    const double width;
    const double height;

    Rect(const double& x, const double& y, const double& width, const double& height);
    Rect(const flutter::EncodableMap& map);
    ~Rect() = default;

    bool Rect::operator==(const Rect& other)
    {
      return x == other.x && y == other.y && width == other.width && height == other.height;
    }
    bool Rect::operator!=(const Rect& other)
    {
      return !(*this == other);
    }

    flutter::EncodableMap toEncodableMap() const;
  };
}

#endif //zikzak_inappWEBVIEW_PLUGIN_RECT_H_
