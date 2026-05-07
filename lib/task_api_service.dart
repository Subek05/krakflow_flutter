import 'dart:convert';
import 'package:http/http.dart' as http;
import 'task.dart';

class TaskApiService {
  static const String baseUrl = "https://dummyjson.com";

  static Future<List<Task>> fetchTasks() async {
    final response = await http.get(
      Uri.parse("$baseUrl/todos"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final List todos = data["todos"];

      return todos.map((todo) {
        return Task(
          title: todo["todo"],
          deadline: "brak",
          done: todo["completed"],
          priority: "średni",
        );
      }).toList();
    } else {
      throw Exception("Błąd pobierania danych");
    }
  }
}