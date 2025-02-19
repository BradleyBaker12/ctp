// This is a mock file to handle dart:html imports for non-web platforms

class Window {
  Navigator get navigator => Navigator();
}

class Navigator {
  MediaDevices? get mediaDevices => null;
}

class MediaDevices {
  Future<MediaStream?> getUserMedia(Map<String, dynamic> constraints) async => null;
}

class MediaStream {
  List<dynamic> getTracks() => [];
}

class VideoElement {
  bool autoplay = false;
  dynamic srcObject;
  Stream<Event> get onLoadedMetadata => Stream.empty();
  dynamic context2D;
  String toDataUrl(String type) => '';
}

class Event {}

Window window = Window();
