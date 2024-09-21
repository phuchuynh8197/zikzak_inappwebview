#ifndef zikzak_inappWEBVIEW_PLUGIN_CHANNEL_DELEGATE_H_
#define zikzak_inappWEBVIEW_PLUGIN_CHANNEL_DELEGATE_H_

#include <flutter/method_channel.h>

namespace zikzak_inappwebview_plugin
{
  class ChannelDelegate
  {
    using FlutterMethodChannel = std::shared_ptr<flutter::MethodChannel<flutter::EncodableValue>>;

  public:
    FlutterMethodChannel channel;
    flutter::BinaryMessenger* messenger;

    ChannelDelegate(flutter::BinaryMessenger* messenger, const std::string& name);
    virtual ~ChannelDelegate();

    virtual void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  };
}

#endif //zikzak_inappWEBVIEW_PLUGIN_CHANNEL_DELEGATE_H_
