import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<String?> predictImage(String imageUrl) async {
    final String apiUrl = "http://10.0.2.2:8000/predict/"; // URL ของ FastAPI

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"image_url": imageUrl}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        return "Predicted Class: ${result['predicted_class']}\n"
            "Confidence Score: ${result['confidence_score']}\n"
            "Warning: ${result['warning']}\n"
            "Top2 = ${result['top2_n_predictions']}\n"
            "Top3 = ${result['top3_n_predictions']}\n";
            
            
      } else {
        return "Error: ${response.body}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }
}