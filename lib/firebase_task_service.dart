import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime taskDate;

  Task({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
    required this.taskDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'taskDate': taskDate.toIso8601String(),
    };
  }

  factory Task.fromMap(String id, Map<String, dynamic> map) {
    return Task(
      id: id,
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      taskDate: DateTime.parse(map['taskDate'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class FirebaseTaskService {
  static final FirebaseTaskService _instance = FirebaseTaskService._internal();
  factory FirebaseTaskService() => _instance;
  FirebaseTaskService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tasks';

  // Adicionar uma nova tarefa
  Future<void> addTask(String title, DateTime taskDate) async {
    try {
      await _firestore.collection(_collection).add({
        'title': title,
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
        'taskDate': taskDate.toIso8601String(),
      });
    } catch (e) {
      print('Erro ao adicionar tarefa: $e');
      rethrow;
    }
  }

  // Obter todas as tarefas
  Stream<List<Task>> getTasks() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Obter tarefas de uma data específica
  Stream<List<Task>> getTasksByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return _firestore
        .collection(_collection)
        .where('taskDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('taskDate', isLessThanOrEqualTo: endOfDay.toIso8601String())
        .orderBy('taskDate')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Alternar status de conclusão da tarefa
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'isCompleted': isCompleted,
      });
    } catch (e) {
      print('Erro ao atualizar tarefa: $e');
      rethrow;
    }
  }

  // Remover uma tarefa
  Future<void> removeTask(String taskId) async {
    try {
      await _firestore.collection(_collection).doc(taskId).delete();
    } catch (e) {
      print('Erro ao remover tarefa: $e');
      rethrow;
    }
  }
}