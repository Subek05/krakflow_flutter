class Task {
  final String title;
  final String deadline;
  bool done;
  final String priority;

  Task({required this.title, required this.deadline, required this.done, required this.priority});
}

class TaskRepository {
  static List<Task> tasks = [
    Task(title: "Kolokwium", deadline: "jutro", done: false, priority: "srednie"),
    Task(title: "Zadanie z PSI", deadline: "czwartek", done: false, priority: "niskie"),
    Task(title: "Projekt z AD", deadline: "piątek", done: false, priority: "niskie"),
    Task(title: "Meczyk w League of Legends", deadline: "za chwilę", done: true, priority: "wysokie"),
  ];
}