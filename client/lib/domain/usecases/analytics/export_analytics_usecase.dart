import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../models/retrospective_model.dart';

class ExportAnalyticsUseCase {
  final Dio _dio;

  ExportAnalyticsUseCase(this._dio);

  Future<Uint8List> exportReport({
    required bool isPdf,
    required String period,
    String? timezone,
  }) async {
    final endpoint = isPdf
        ? ApiEndpoints.analyticsExportPdf
        : ApiEndpoints.analyticsExportCsv;

    final response = await _dio.get<List<int>>(
      endpoint,
      queryParameters: {
        'period': period,
        'timezone': timezone ?? DateTime.now().timeZoneName,
      },
      options: Options(
        responseType: ResponseType.bytes,
      ),
    );

    if (response.data == null) {
      throw Exception('Failed to download report stream');
    }

    return Uint8List.fromList(response.data!);
  }
}
