import 'dart:convert';
import 'dart:math';
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
    final response = await http.get(Uri.parse("$baseUrl/todos"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List todos = data["todos"];

      return todos.map((todo) {
        return Task(
          id: todo["id"] as int,
          title: todo["todo"] as String,
          deadline: "brak",
          done: todo["completed"] as bool,
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
  List<Task> _localTasks = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await TaskApiService.fetchTasks();
      setState(() {
        _localTasks = tasks;
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  void _retry() {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    _loadTasks();
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final deadlineController = TextEditingController();
    String selectedPriority = "średni";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Nowe zadanie"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration:
                const InputDecoration(labelText: "Nazwa zadania"),
              ),
              TextField(
                controller: deadlineController,
                decoration: const InputDecoration(labelText: "Termin"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(labelText: "Priorytet"),
                items: const [
                  DropdownMenuItem(value: "wysoki", child: Text("Wysoki")),
                  DropdownMenuItem(value: "średni", child: Text("Średni")),
                  DropdownMenuItem(value: "niski", child: Text("Niski")),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedPriority = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Anuluj"),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final newTask = Task(
                    id: Random().nextInt(1000000),
                    title: titleController.text,
                    deadline: deadlineController.text.isEmpty
                        ? "brak"
                        : deadlineController.text,
                    done: false,
                    priority: selectedPriority,
                  );

                  setState(() {
                    _localTasks.add(newTask);
                  });

                  Navigator.pop(ctx);
                }
              },
              child: const Text("Dodaj"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: LoadingView());
    }

    if (hasError) {
      return Scaffold(body: ErrorView(onRetry: _retry));
    }

    List<Task> filteredTasks = _localTasks;

    if (selectedFilter == "wykonane") {
      filteredTasks = _localTasks.where((t) => t.done).toList();
    } else if (selectedFilter == "do zrobienia") {
      filteredTasks = _localTasks.where((t) => !t.done).toList();
    }

    final doneCount = _localTasks.where((t) => t.done).length;

    return Scaffold(
      appBar: AppBar(title: const Text("KrakFlow")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Wykonałeś dzisiaj $doneCount zadań",
              style:
              const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Masz dzisiaj ${_localTasks.length} zadań",
              style:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          FilterBar(
            selectedFilter: selectedFilter,
            onFilterChanged: (filter) {
              setState(() => selectedFilter = filter);
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
          Text("Ładowanie zadań..."),
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
      child: ElevatedButton(
        onPressed: onRetry,
        child: const Text("Spróbuj ponownie"),
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
    return Row(
      children: ["wszystkie", "do zrobienia", "wykonane"].map((filter) {
        final active = selectedFilter == filter;

        return TextButton(
          onPressed: () => onFilterChanged(filter),
          child: Text(
            filter,
            style: TextStyle(
              color: active ? Colors.blue : Colors.grey,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }
}

Color _priorityColor(String priority) {
  switch (priority) {
    case "wysoki":
      return Colors.red;
    case "średni":
      return Colors.orange;
    case "niski":
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
            done ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.circle, color: _priorityColor(priority)),
      ),
    );
  }
}