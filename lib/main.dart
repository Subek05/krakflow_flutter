import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'task.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = "wszystkie";

  late Future<List<Task>> tasksFuture;

  @override
  void initState() {
    super.initState();

    tasksFuture = TaskApiService.fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KrakFlow"),
      ),

        body: FutureBuilder<List<Task>>(
          future: tasksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  "Błąd pobierania danych",
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            final tasks = snapshot.data ?? [];

            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskCard(
                  title: task.title,
                  subtitle: "termin: ${task.deadline} | priorytet: ${task.priority}",
                  done: task.done,
                  priority: task.priority,
                  onChanged: (value) {
                    setState(() {
                      task.done = value!;
                    });
                  },
                );
              },
            );
          },
        ),
    );
  }
}

class FilterBar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const FilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),

      child: Row(
        children:
        ["wszystkie", "do zrobienia", "wykonane"]
            .map((filter) {

          final bool active = selectedFilter == filter;

          return TextButton(
            onPressed: () => onFilterChanged(filter),

            style: TextButton.styleFrom(
              foregroundColor:
              active ? Colors.blue : Colors.grey,

              textStyle: TextStyle(
                fontWeight:
                active
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),

            child: Text(
              filter[0].toUpperCase() +
                  filter.substring(1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

Color _priorityColor(String priority) {
  switch (priority.toLowerCase()) {
    case 'wysoki':
    case 'high':
      return Colors.red;

    case 'średni':
    case 'medium':
      return Colors.orange;

    case 'niski':
    case 'low':
      return Colors.green;

    default:
      return Colors.grey;
  }
}

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool done;
  final String priority;

  final ValueChanged<bool?>? onChanged;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.priority,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: done,
          onChanged: onChanged,
        ),

        title: Text(
          title,

          style: TextStyle(
            decoration:
            done
                ? TextDecoration.lineThrough
                : TextDecoration.none,

            color:
            done
                ? Colors.grey
                : Colors.black,
          ),
        ),

        subtitle: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 13,
              color:
              done
                  ? Colors.grey[400]
                  : Colors.grey[700],
            ),

            children: [

              const TextSpan(text: "termin: "),

              TextSpan(
                text:
                subtitle
                    .split('|')[0]
                    .replaceFirst('termin: ', '')
                    .trim(),
              ),

              const TextSpan(text: " | priorytet: "),

              TextSpan(
                text: priority,

                style: TextStyle(
                  color:
                  done
                      ? Colors.grey[400]
                      : _priorityColor(priority),

                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}