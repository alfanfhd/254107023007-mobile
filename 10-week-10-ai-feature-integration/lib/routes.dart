class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const announcement = '/pengumuman/:id';
  static const notes = '/notes';
  static const aiChat = '/ai-chat';
}

String routeFromMessage(Map<String, dynamic> data) {
  final route = data['route']?.toString() ?? '/';
  return route.startsWith('/') ? route : '/$route';
}
