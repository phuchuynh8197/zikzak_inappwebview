#ifndef zikzak_inappWEBVIEW_PLUGIN_IN_APP_BROWSER_CHANNEL_DELEGATE_H_
#define zikzak_inappWEBVIEW_PLUGIN_IN_APP_BROWSER_CHANNEL_DELEGATE_H_

#include <flutter/method_channel.h>
#include <flutter/standard_message_codec.h>

#include "../types/channel_delegate.h"

namespace zikzak_inappwebview_plugin
{
  class InAppBrowserChannelDelegate : public ChannelDelegate
  {
  public:
    InAppBrowserChannelDelegate(const std::string& id, flutter::BinaryMessenger* messenger);
    ~InAppBrowserChannelDelegate();

    void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    void onBrowserCreated() const;
    void onExit() const;
  };
}

#endif //zikzak_inappWEBVIEW_PLUGIN_IN_APP_BROWSER_CHANNEL_DELEGATE_H_
