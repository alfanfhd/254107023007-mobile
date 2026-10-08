import 'package:dio/dio.dart';

String getFriendlyErrorMessage(Object e) {
  if (e is DioException) {
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return 'Koneksi terputus. Periksa jaringan Anda.';
    }
    if (e.response?.statusCode == 401) {
      return 'Sesi berakhir, silakan login kembali.';
    }
    return 'Terjadi kesalahan pada server.';
  }
  return 'Terjadi kesalahan tidak terduga.';
}
