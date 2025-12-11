import 'package:dio/dio.dart';

import '../config/api_config.dart';

class ApiClient {
  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: kBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
        responseType: ResponseType.json,
      ),
    )..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['ApiKey'] = kApiKey;
           
            return handler.next(options);
          },
          onError: (e, handler) {
            // print('API error: ${e.response?.statusCode} ${e.message}');
            return handler.next(e);
          },
        ),
      );
  }
}
