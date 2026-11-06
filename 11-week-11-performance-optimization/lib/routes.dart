class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const announcement = '/pengumuman/:id';
  static const announcementFeed = '/pengumuman';
  static const notes = '/notes';
  static const aiChat = '/ai-chat';
  static const performanceLab = '/performance-lab';
}

String routeFromMessage(Map<String, dynamic> data) {
  final route = data['route']?.toString() ?? '/';
  return route.startsWith('/') ? route : '/$route';
}
