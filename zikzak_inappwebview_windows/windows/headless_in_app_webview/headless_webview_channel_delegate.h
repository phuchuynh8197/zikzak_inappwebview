#ifndef zikzak_inappWEBVIEW_PLUGIN_HEADLESS_WEBVIEW_CHANNEL_DELEGATE_H_
#define zikzak_inappWEBVIEW_PLUGIN_HEADLESS_WEBVIEW_CHANNEL_DELEGATE_H_

#include "../types/channel_delegate.h"
#include <flutter/method_channel.h>

namespace zikzak_inappwebview_plugin
{
  class HeadlessInAppWebView;

  class HeadlessWebViewChannelDelegate : public ChannelDelegate
  {
  public:
    HeadlessInAppWebView* webView;

    HeadlessWebViewChannelDelegate(HeadlessInAppWebView* webView, flutter::BinaryMessenger* messenger);
    ~HeadlessWebViewChannelDelegate();

    void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    void onWebViewCreated() const;
  };
}

#endif //zikzak_inappWEBVIEW_PLUGIN_HEADLESS_WEBVIEW_CHANNEL_DELEGATE_H_
