#ifndef zikzak_inappWEBVIEW_PLUGIN_SIZE_2D_H_
#define zikzak_inappWEBVIEW_PLUGIN_SIZE_2D_H_

#include <flutter/standard_method_codec.h>
#include <optional>

#include "../utils/flutter.h"

namespace zikzak_inappwebview_plugin
{
  class Size2D
  {
  public:
    const double width;
    const double height;

    Size2D(const double& width, const double& height);
    Size2D(const flutter::EncodableMap& map);
    ~Size2D() = default;

    bool Size2D::operator==(const Size2D& other)
    {
      return width == other.width && height == other.height;
    }
    bool Size2D::operator!=(const Size2D& other)
    {
      return !(*this == other);
    }

    flutter::EncodableMap toEncodableMap() const;
  };
}

#endif //zikzak_inappWEBVIEW_PLUGIN_SIZE_2D_H_
