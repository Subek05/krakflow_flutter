import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final List<Task> items = [
    Task(title: "Kolokwium", deadline: "jutro",done: false,priority: "srednie"),
    Task(title: "Zadanie z PSI", deadline: "czwartek", done: false,priority: "niskie"),
    Task(title: "Projekt z AD", deadline: "piątek",done: false,priority: "niskie"),
    Task(title: "Meczyk w League of Legends", deadline: "za chwilę",done: true,priority: "wysokie"),
  ];

  @override
  Widget build(BuildContext context) {
    final int ZadaniaWykonane = items.where((task) => task.done).length;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("KrakFlow, wykonales dzis ${ZadaniaWykonane} zadan"),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Masz Dzisiaj ${items.length} zadania",
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Dzisiejsze zadania",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final task = items[index];
                  return TaskCard(
                    title: task.title,
                    subtitle: "termin: ${task.deadline}",
                    icon: task.done ? Icons.check_circle : Icons.radio_button_unchecked,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Task {
  final String title;
  final String deadline;
  final bool done;
  final String priority;

  Task({required this.title, required this.deadline,required this.done, required this.priority});
}
class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
