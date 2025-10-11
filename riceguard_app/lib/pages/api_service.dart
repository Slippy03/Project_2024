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

        double confidenceScore =
            double.parse(result['confidence_score'].replaceAll('%', ''));

        if (confidenceScore >= 80) {
          return "มีโอกาศที่อาจจะเป็นโรคตามลําดังนี้ : "
              " 1). ${result['predicted_class']}\n"
              " 2). ${result['top2_n_predictions']}\n"
              " 3). ${result['top3_n_predictions']}\n"
              "โปรดศึกษาข้อมูลเพิ่มเติมจากแหล่งอื่นเพื่อประกอบการตัดสินใจ\n";
        } else {
          return "Confidence Score: ${result['confidence_score']}\n"
              "ไม่สามารถประเมินโรคจากรูปภาพได้เนื่องจากความมันใจไม่เพียงพอ";
        }
      } else {
        return "Error: ${response.body}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }
}
