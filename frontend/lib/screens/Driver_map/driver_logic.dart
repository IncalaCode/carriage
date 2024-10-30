import 'package:gebetamap/gebetamap.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> initEnv() async {
  await dotenv.load(); // Load environment variables
}

// Retrieve the API key from the .env file
String get apiKey => dotenv.env['GEBETA_API_KEY'] ?? '';

Future<ResponseData> getDirection(Map<String, double> start, Map<String, double> stop) async {
  GebetaMapRequest gmr = GebetaMapRequest();
  return await gmr.direction(start, stop, apiKey);
}

Future<List<List<ResponseData>>> getMatrix(List<List<double>> points) async {
  GebetaMapRequest gmr = GebetaMapRequest();
  return await gmr.matrix(points, apiKey);
}

Future<ResponseData> getTss(List<List<double>> points) async {
  GebetaMapRequest gmr = GebetaMapRequest();
  return await gmr.tss(points, apiKey);
}

Future<List<ResponseData>> getOneToMany(Map<String, double> start, List<List<double>> points) async {
  GebetaMapRequest gmr = GebetaMapRequest();
  return await gmr.OneToMany(start, points, apiKey);
}

Future<dynamic> getGeoCode(String name) async {
  GebetaMapRequest gmr = GebetaMapRequest();
  ResponseData rs = await gmr.geocode(name, apiKey);
  return rs.data;
}

