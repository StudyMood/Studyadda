class MediaResolverService {
  static String resolveMediaUrl(Map<String, dynamic>? app, String id) {
    if (id.isEmpty) return '';
    final path = app != null && app['path'] != null ? app['path'].toString() : '';
    final raw = path + id;

    if (RegExp(r'^https?:\/\/', caseSensitive: false).hasMatch(id)) {
      return id;
    }

    final m = RegExp(r"https?:\/\/[^\s\x22'#]+", caseSensitive: false).firstMatch(raw);
    if (m != null) {
      final matched = m.group(0);
      if (matched != null) {
        try {
          return Uri.decodeFull(matched);
        } catch (_) {
          return matched;
        }
      }
    }

    final paramMatch = RegExp(r'[?&](?:url|link|src|video|stream)=([^&]+)', caseSensitive: false).firstMatch(raw);
    if (paramMatch != null) {
      final matchedParam = paramMatch.group(1);
      if (matchedParam != null) {
        try {
          return Uri.decodeComponent(matchedParam);
        } catch (_) {
          return matchedParam;
        }
      }
    }

    final scheme = app != null ? app['scheme']?.toString() : null;
    if (scheme == 'http' || scheme == 'https') {
      return '$scheme://$path$id';
    }

    final encMatch = RegExp(r"https?%3A%2F%2F[^\s\x22'#&]+", caseSensitive: false).firstMatch(raw);
    if (encMatch != null) {
      final matchedEnc = encMatch.group(0);
      if (matchedEnc != null) {
        try {
          return Uri.decodeComponent(matchedEnc);
        } catch (_) {}
      }
    }

    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id.trim())) {
      return 'https://www.youtube.com/watch?v=${id.trim()}';
    }

    final finalScheme = scheme != null && scheme.isNotEmpty ? '$scheme://' : 'https://';
    return '$finalScheme$raw';
  }

  static bool isYouTube(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  static String? extractYouTubeId(String url) {
    final ym = RegExp(r'(?:v=|\/embed\/|youtu\.be\/|\/v\/)([^&?#/]+)').firstMatch(url);
    if (ym != null) return ym.group(1);
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url.trim())) return url.trim();
    return null;
  }

  static bool isHlsStream(String url) {
    return url.toLowerCase().contains('.m3u8');
  }
}
