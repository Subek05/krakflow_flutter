import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'models/task.dart';
import 'services/task_sync_service.dart';
import 'services/task_local_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("tasks");
  runApp(const MyApp());
}

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = "wszystkie";

  late Future<List<Task>> tasksFuture;

  List<Task> _localTasks = [];

  // 5.12 liczniki
  int allTasksCount = 0;
  int doneTasksCount = 0;
  int todoTasksCount = 0;

  @override
  void initState() {
    super.initState();
    tasksFuture = loadTasks();
  }

  Future<List<Task>> loadTasks() async {
    final tasks = await TaskSyncService.getTasks();

    setState(() {
      _localTasks = tasks;

      // aktualizacja liczników
      allTasksCount = tasks.length;
      doneTasksCount =
          tasks.where((task) => task.done).length;
      todoTasksCount =
          tasks.where((task) => !task.done).length;
    });

    return tasks;
  }

  // dodawanie zadania
  Future<void> addTask(Task task) async {
    await TaskLocalDatabase.addTask(task);
    await loadTasks();
  }

  // usuwanie pojedynczego zadania
  Future<void> deleteTask(int id) async {
    await TaskLocalDatabase.deleteTask(id);
    await loadTasks();
  }

  // usuwanie wszystkich zadań
  Future<void> deleteAllTasks() async {
    await TaskLocalDatabase.deleteAllTasks();
    await loadTasks();
  }

  void _retry() {
    setState(() {
      tasksFuture = loadTasks();
    });
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
                decoration: const InputDecoration(
                  labelText: "Nazwa zadania",
                ),
              ),
              TextField(
                controller: deadlineController,
                decoration: const InputDecoration(
                  labelText: "Termin",
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(
                  labelText: "Priorytet",
                ),
                items: const [
                  DropdownMenuItem(
                    value: "wysoki",
                    child: Text("Wysoki"),
                  ),
                  DropdownMenuItem(
                    value: "średni",
                    child: Text("Średni"),
                  ),
                  DropdownMenuItem(
                    value: "niski",
                    child: Text("Niski"),
                  ),
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
              onPressed: () async {
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

                  await addTask(newTask);

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
    return Scaffold(
      appBar: AppBar(
        title: const Text("KrakFlow"),
        actions: [
          IconButton(
            onPressed: () async {
              await deleteAllTasks();
            },
            icon: const Icon(Icons.delete_forever),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Task>>(
        future: tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const LoadingView();
          }

          if (snapshot.hasError &&
              TaskLocalDatabase.isEmpty()) {
            return ErrorView(onRetry: _retry);
          }

          List<Task> filteredTasks = _localTasks;

          if (selectedFilter == "wykonane") {
            filteredTasks =
                _localTasks.where((task) => task.done).toList();
          } else if (selectedFilter ==
              "do zrobienia") {
            filteredTasks =
                _localTasks.where((task) => !task.done).toList();
          }

          return Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Wykonałeś dzisiaj $doneTasksCount zadań",
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Text(
                  "Masz dzisiaj $allTasksCount zadań",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  "Do zrobienia: $todoTasksCount",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
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

                      // 5.10 aktualizacja checkboxa
                      onChanged: (value) async {
                        final updatedTask = Task(
                          id: task.id,
                          title: task.title,
                          deadline: task.deadline,
                          priority: task.priority,
                          done: value ?? false,
                        );

                        await TaskLocalDatabase
                            .updateTask(updatedTask);

                        setState(() {
                          tasksFuture = loadTasks();
                        });
                      },

                      // 5.11 usuwanie pojedynczego
                      onDelete: () async {
                        await deleteTask(task.id);
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
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 72,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              "Nie udało się pobrać zadań",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Sprawdź połączenie z internetem i spróbuj ponownie.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
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
      padding:
      const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          "wszystkie",
          "do zrobienia",
          "wykonane",
        ].map((filter) {
          final bool active =
              selectedFilter == filter;

          return TextButton(
            onPressed: () =>
                onFilterChanged(filter),
            style: TextButton.styleFrom(
              foregroundColor: active
                  ? Colors.blue
                  : Colors.grey,
              textStyle: TextStyle(
                fontWeight: active
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
      return Colors.red;

    case 'średni':
      return Colors.orange;

    case 'niski':
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
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.priority,
    this.onChanged,
    this.onDelete,
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
            decoration: done
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color:
            done ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 13,
              color: done
                  ? Colors.grey[400]
                  : Colors.grey[700],
            ),
            children: [
              const TextSpan(text: "termin: "),
              TextSpan(
                text: subtitle
                    .split('|')[0]
                    .replaceFirst(
                  'termin: ',
                  '',
                )
                    .trim(),
              ),
              const TextSpan(
                text: " | priorytet: ",
              ),
              TextSpan(
                text: priority,
                style: TextStyle(
                  color: done
                      ? Colors.grey[400]
                      : _priorityColor(priority),
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          onPressed: onDelete,
          icon: const Icon(
            Icons.delete,
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}