//
//  Static plugin registrant - replaces the auto-generated file.
//  We exclude flutter_inappwebview_windows because the desktop
//  build uses earth_view_desktop (no WebView).
//

// clang-format off

#include "plugin_registrant.h"

#include <geolocator_windows/geolocator_windows.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  GeolocatorWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("GeolocatorWindows"));
}
