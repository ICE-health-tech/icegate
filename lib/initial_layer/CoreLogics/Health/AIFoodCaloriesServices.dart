import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:ice_gate/data_layer/Protocol/Health/CaloriesProtocol.dart';

class Aifoodcaloriesservices {
  final String _baseUrl = "https://lang.duylong.art/runs/stream";

  Future<CaloriesProtocol> getCalories(String foodName, {File? image}) async {
    try {
      String? base64Image;
      if (image != null) {
        base64Image = base64Encode(await image.readAsBytes());
      }

      final Map<String, dynamic> requestBody = {
        "assistant_id": "agent",
        "input": {
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text": "Please analyze this $foodName image.",
                },
                if (base64Image != null)
                  {
                    "type": "image_url",
                    "image_url": {"url": "data:image/jpeg;base64,$base64Image"},
                  },
              ],
            },
          ],
        },
        "stream_mode": "values",
      };

      final request = http.Request('POST', Uri.parse(_baseUrl))
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(requestBody);

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        String lastDataChunk = "";

        // Listen to the stream and capture the LAST 'data' block
        await for (var line
            in streamedResponse.stream
                .transform(utf8.decoder)
                .transform(const LineSplitter())) {
          if (line.startsWith('data: ')) {
            lastDataChunk = line.substring(6);
          }
        }

        if (lastDataChunk.isNotEmpty) {
          final Map<String, dynamic> fullState = jsonDecode(lastDataChunk);

          // LangGraph "values" mode returns the full state including the messages list
          final List<dynamic> messages = fullState['messages'] ?? [];

          // Find the last message with content (the AI's JSON string)
          final aiMessage = messages.lastWhere(
            (m) =>
                (m['type'] == 'ai' || m['type'] == 'tool') &&
                m['content'].toString().isNotEmpty,
            orElse: () => null,
          );
          // print(aiMessage);
          if (aiMessage != null) {
            // The content itself is a JSON string: "{"fat": 20, ...}"
            final Map<String, dynamic> calorieData = jsonDecode(
              aiMessage['content'],
            );
            return CaloriesProtocol.fromJson(calorieData);
          }
        }
      }
      throw Exception('Failed to get valid data from stream');
    } catch (e) {
      print("Error in AIFoodCaloriesServices: $e");
      return CaloriesProtocol.empty();
    }
  }
}
