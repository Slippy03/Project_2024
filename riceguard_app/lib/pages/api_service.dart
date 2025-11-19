import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // เปลี่ยน URL ตามสภาพแวดล้อม
  static const String _baseUrl = "http://10.0.2.2:8000"; // Android Emulator
  // static const String _baseUrl = "http://localhost:8000"; // iOS Simulator
  // static const String _baseUrl = "http://YOUR_IP:8000"; // Real Device

  /// ส่งรูปภาพไปทำนายโรคข้าว
  ///
  /// [imageUrl] - URL ของรูปภาพที่อัปโหลดไปยัง Firebase Storage
  ///
  /// Returns: Map<String, dynamic> ที่มีผลการทำนาย หรือ null ถ้าเกิดข้อผิดพลาด
  static Future<Map<String, dynamic>?> predictImage(String imageUrl) async {
    final String apiUrl = "$_baseUrl/predict/";

    try {
      print("🔄 กำลังส่งคำขอไปยัง API: $apiUrl");
      print("📷 URL รูปภาพ: $imageUrl");

      final response = await http
          .post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode({"image_url": imageUrl}),
      )
          .timeout(
        Duration(seconds: 60), // Timeout 60 วินาที
        onTimeout: () {
          throw Exception('การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง');
        },
      );

      print("📊 Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        // Decode UTF-8 เพื่อรองรับภาษาไทย
        final result = json.decode(utf8.decode(response.bodyBytes));
        print("✅ ได้รับผลลัพธ์: ${result['predicted_class']}");

        return result;
      } else {
        print("❌ Error Response: ${response.body}");
        return {
          'status': 'error',
          'message': 'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์: ${response.statusCode}',
        };
      }
    } catch (e) {
      print("❌ Exception: $e");
      return {
        'status': 'error',
        'message': 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์: ${e.toString()}',
      };
    }
  }

  /// แปลงผลการทำนายเป็นข้อความแสดงผล
  ///
  /// [result] - ผลลัพธ์จาก API
  ///
  /// Returns: ข้อความที่จัดรูปแบบแล้ว
  static String formatPredictionResult(Map<String, dynamic> result) {
    // ตรวจสอบว่ามี error หรือไม่
    if (result['status'] == 'error') {
      return result['message'] ?? 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';
    }

    // ตรวจสอบว่ามีข้อมูลครบถ้วนหรือไม่
    if (result['predicted_class'] == null ||
        result['confidence_score'] == null ||
        result['top_3_predictions'] == null) {
      return 'ข้อมูลผลลัพธ์ไม่ครบถ้วน';
    }

    final String predictedClass = result['predicted_class'];
    final String confidenceScore = result['confidence_score'];
    final List<dynamic> top3 = result['top_3_predictions'];

    // ตรวจสอบว่าความมั่นใจเพียงพอหรือไม่
    if (result['status'] == 'low_confidence') {
      return "⚠️ ความมั่นใจในการทำนาย: $confidenceScore\n\n"
          "ไม่สามารถระบุโรคได้อย่างแม่นยำ\n"
          "เนื่องจากความมั่นใจไม่เพียงพอ (ต่ำกว่า 80%)\n\n"
          "💡 คำแนะนำ:\n"
          "• ถ่ายรูปใหม่ในที่ที่มีแสงสว่างเพียงพอ\n"
          "• ถ่ายรูปใกล้ชิดกับใบข้าวที่มีอาการ\n"
          "• หลีกเลี่ยงภาพเบลอหรือมีเงามาก\n\n"
          "โรคที่เป็นไปได้:\n"
          "${_formatTop3Predictions(top3)}";
    }

    // กรณีทำนายสำเร็จ
    return "✅ ผลการวิเคราะห์\n\n"
        "🔬 โรคที่พบ: $predictedClass\n"
        "📊 ความมั่นใจ: $confidenceScore\n\n"
        "📋 โรคที่เป็นไปได้ตามลำดับ:\n"
        "${_formatTop3Predictions(top3)}\n"
        "⚠️ คำเตือน:\n"
        "ผลการวิเคราะห์นี้เป็นเพียงข้อมูลเบื้องต้น\n"
        "โปรดปรึกษาผู้เชี่ยวชาญหรือศึกษาข้อมูลเพิ่มเติม\n"
        "เพื่อประกอบการตัดสินใจในการรักษา";
  }

  /// จัดรูปแบบ Top 3 Predictions
  static String _formatTop3Predictions(List<dynamic> top3) {
    String result = '';
    for (int i = 0; i < top3.length && i < 3; i++) {
      final pred = top3[i];
      result += "${i + 1}. ${pred['class']} (${pred['confidence']})\n";
    }
    return result;
  }

  /// ตรวจสอบสถานะของ API Server
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse("$_baseUrl/health"),
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      print("❌ Health Check Failed: $e");
      return false;
    }
  }

  /// ดึงรายการโรคทั้งหมดจาก API
  static Future<List<Map<String, dynamic>>?> getAvailableClasses() async {
    try {
      final response = await http
          .get(
            Uri.parse("$_baseUrl/classes"),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = json.decode(utf8.decode(response.bodyBytes));
        return List<Map<String, dynamic>>.from(result['classes']);
      }
      return null;
    } catch (e) {
      print("❌ Get Classes Failed: $e");
      return null;
    }
  }
}
