import 'package:flutter/material.dart';
import 'task.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = "wszystkie";

  void _showDeleteAllDialog() {
    if (TaskRepository.tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Brak zadań do usunięcia"), duration: Duration(seconds: 2)),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Potwierdzenie"),
          content: Text("Czy na pewno chcesz usunąć wszystkie zadania?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Anuluj"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  TaskRepository.tasks.clear();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Usunięto wszystkie zadania"), duration: Duration(seconds: 2)),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text("Usuń"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Task> filteredTasks = TaskRepository.tasks;
    if (selectedFilter == "wykonane") {
      filteredTasks = TaskRepository.tasks.where((task) => task.done).toList();
    } else if (selectedFilter == "do zrobienia") {
      filteredTasks = TaskRepository.tasks.where((task) => !task.done).toList();
    }
    final int zadaniaWykonane = TaskRepository.tasks.where((task) => task.done).length;
    final bool isEmpty = TaskRepository.tasks.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text("KrakFlow, wykonales dzis ${zadaniaWykonane} zadan"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: isEmpty ? Colors.grey[400] : null),
            onPressed: _showDeleteAllDialog,
            tooltip: isEmpty ? "Brak zadań" : "Usuń wszystkie",
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Masz Dzisiaj ${TaskRepository.tasks.length} zadania",
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Dzisiejsze zadania",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                return Dismissible(
                  key: ValueKey(task.title),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.red,
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    final removedTitle = task.title;
                    setState(() {
                      TaskRepository.tasks.remove(task);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Usunięto zadanie: "$removedTitle"'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: TaskCard(
                    title: task.title,
                    subtitle: "termin: ${task.deadline} | priorytet: ${task.priority}",
                    done: task.done,
                    priority: task.priority,
                    onChanged: (value) {
                      setState(() {
                        task.done = value!;
                      });
                    },
                    onTap: () async {
                      final Task? updatedTask = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditTaskScreen(task: task),
                        ),
                      );
                      if (updatedTask != null) {
                        setState(() {
                          final i = TaskRepository.tasks.indexOf(task);
                          TaskRepository.tasks[i] = updatedTask;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Task? newTask = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => AddTaskScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final offsetAnimation = Tween(
                  begin: Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
                return SlideTransition(position: offsetAnimation, child: child);
              },
            ),
          );
          if (newTask != null) {
            setState(() {
              TaskRepository.tasks.add(newTask);
            });
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class FilterBar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  const FilterBar({super.key, required this.selectedFilter, required this.onFilterChanged});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: ["wszystkie", "do zrobienia", "wykonane"].map((filter) {
          final bool active = selectedFilter == filter;
          return TextButton(
            onPressed: () => onFilterChanged(filter),
            style: TextButton.styleFrom(
              foregroundColor: active ? Colors.blue : Colors.grey,
              textStyle: TextStyle(fontWeight: active ? FontWeight.bold : FontWeight.normal),
            ),
            child: Text(filter[0].toUpperCase() + filter.substring(1)),
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
  final VoidCallback? onTap;
  const TaskCard({super.key, required this.title, required this.subtitle, required this.done, required this.priority, this.onChanged, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(value: done, onChanged: onChanged),
        title: Text(
          title,
          style: TextStyle(
            decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
            color: done ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 13, color: done ? Colors.grey[400] : Colors.grey[700]),
            children: [
              TextSpan(text: "termin: "),
              TextSpan(text: subtitle.split('|')[0].replaceFirst('termin: ', '').trim()),
              TextSpan(text: " | priorytet: "),
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
        trailing: Icon(Icons.chevron_right),
      ),
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});
  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nowe zadanie")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "Tytuł zadania", border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            TextField(
              controller: deadlineController,
              decoration: InputDecoration(labelText: "Termin", border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            TextField(
              controller: priorityController,
              decoration: InputDecoration(labelText: "Priorytet", border: OutlineInputBorder()),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final newTask = Task(
                  title: titleController.text,
                  deadline: deadlineController.text,
                  priority: priorityController.text,
                  done: false,
                );
                Navigator.pop(context, newTask);
              },
              child: Text("Zapisz"),
            ),
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatelessWidget {
  final Task task;
  EditTaskScreen({super.key, required this.task});
  late final TextEditingController titleController = TextEditingController(text: task.title);
  late final TextEditingController deadlineController = TextEditingController(text: task.deadline);
  late final TextEditingController priorityController = TextEditingController(text: task.priority);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edytuj zadanie")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "Tytuł zadania", border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            TextField(
              controller: deadlineController,
              decoration: InputDecoration(labelText: "Termin", border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            TextField(
              controller: priorityController,
              decoration: InputDecoration(labelText: "Priorytet", border: OutlineInputBorder()),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final updatedTask = Task(
                  title: titleController.text,
                  deadline: deadlineController.text,
                  priority: priorityController.text,
                  done: task.done,
                );
                Navigator.pop(context, updatedTask);
              },
              child: Text("Zapisz"),
            ),
          ],
        ),
      ),
    );
  }
}