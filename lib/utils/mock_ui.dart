// This is a mock file to handle dart:ui imports for non-web platforms

class PlatformViewRegistry {
  void registerViewFactory(String viewId, dynamic cb) {}
}

final platformViewRegistry = PlatformViewRegistry();
