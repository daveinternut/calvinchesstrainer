import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService();
});

class FeedbackService {
  static const _baseUrl =
      'https://secure.passports.com/funcs/etc/cct.cfc';

  Future<bool> sendFeedback(String message) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'method': 'feedback',
        'msg': message,
      });
      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      dev.log('FeedbackService: failed to send feedback: $e');
      return false;
    }
  }
}
