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

  void _retry() {
    setState(() {
      tasksFuture = TaskApiService.fetchTasks();
    });
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
            return const LoadingView();
          }

          if (snapshot.hasError) {
            return ErrorView(onRetry: _retry);
          }

          final tasks = snapshot.data ?? [];

          List<Task> filteredTasks = tasks;

          if (selectedFilter == "wykonane") {
            filteredTasks = tasks.where((task) => task.done).toList();
          } else if (selectedFilter == "do zrobienia") {
            filteredTasks = tasks.where((task) => !task.done).toList();
          }

          final int zadaniaWykonane =
              tasks.where((task) => task.done).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Wykonałeś dzisiaj $zadaniaWykonane zadań",
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Masz dzisiaj ${tasks.length} zadań",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FilterBar(
                selectedFilter: selectedFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    selectedFilter = filter;
                  });
                },
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];

                    return TaskCard(
                      title: task.title,
                      subtitle:
                      "termin: ${task.deadline} | priorytet: ${task.priority}",
                      done: task.done,
                      priority: task.priority,
                      onChanged: (value) {
                        setState(() {
                          task.done = value!;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            "Ładowanie zadań...",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 72, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              "Nie udało się pobrać zadań",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Sprawdź połączenie z internetem i spróbuj ponownie.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Spróbuj ponownie"),
            ),
          ],
        ),
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
        children: ["wszystkie", "do zrobienia", "wykonane"].map((filter) {
          final bool active = selectedFilter == filter;

          return TextButton(
            onPressed: () => onFilterChanged(filter),
            style: TextButton.styleFrom(
              foregroundColor: active ? Colors.blue : Colors.grey,
              textStyle: TextStyle(
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            child: Text(
              filter[0].toUpperCase() + filter.substring(1),
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
            decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
            color: done ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 13,
              color: done ? Colors.grey[400] : Colors.grey[700],
            ),
            children: [
              const TextSpan(text: "termin: "),
              TextSpan(
                text: subtitle
                    .split('|')[0]
                    .replaceFirst('termin: ', '')
                    .trim(),
              ),
              const TextSpan(text: " | priorytet: "),
              TextSpan(
                text: priority,
                style: TextStyle(
                  color: done ? Colors.grey[400] : _priorityColor(priority),
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