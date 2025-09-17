import 'package:flutter/material.dart';
import 'firebase_task_service.dart';

class TaskListPage extends StatefulWidget {
  final DateTime selectedDate;
  
  const TaskListPage({super.key, required this.selectedDate});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final TextEditingController _taskController = TextEditingController();
  final FirebaseTaskService _taskService = FirebaseTaskService();

  void _addTask() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar Tarefa'),
        content: TextField(
          controller: _taskController,
          decoration: InputDecoration(
            hintText: 'Digite a tarefa...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (_taskController.text.isNotEmpty) {
                try {
                  await _taskService.addTask(_taskController.text.trim(), widget.selectedDate);
                  _taskController.clear();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tarefa adicionada com sucesso!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao adicionar tarefa: $e')),
                  );
                }
              }
            },
            child: Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _removeTask(String taskId) async {
    try {
      await _taskService.removeTask(taskId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarefa removida com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover tarefa: $e')),
      );
    }
  }

  void _toggleTask(String taskId, bool isCompleted) async {
    try {
      await _taskService.toggleTaskCompletion(taskId, isCompleted);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar tarefa: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tarefas - ${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}'),
      ),
      body: StreamBuilder<List<Task>>(
         stream: _taskService.getTasksByDate(widget.selectedDate),
         builder: (context, snapshot) {
           if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
           }
           
           if (snapshot.hasError) {
             return Center(
               child: Text(
                 'Erro ao carregar tarefas: ${snapshot.error}',
                 style: const TextStyle(fontSize: 18, color: Colors.red),
               ),
             );
           }
           
           final tasks = snapshot.data ?? [];
           
           if (tasks.isEmpty) {
             return const Center(
               child: Text(
                 'Nenhuma tarefa adicionada',
                 style: TextStyle(fontSize: 18, color: Colors.grey),
               ),
             );
           }
           
           return ListView.builder(
             itemCount: tasks.length,
             itemBuilder: (context, index) {
               final task = tasks[index];
               return ListTile(
                 leading: Checkbox(
                   value: task.isCompleted,
                   onChanged: (value) => _toggleTask(task.id, task.isCompleted),
                 ),
                 title: Text(
                   task.title,
                   style: TextStyle(
                     decoration: task.isCompleted
                         ? TextDecoration.lineThrough
                         : TextDecoration.none,
                   ),
                 ),
                 trailing: IconButton(
                   icon: const Icon(Icons.delete, color: Colors.red),
                   onPressed: () => _removeTask(task.id),
                 ),
               );
             },
           );
         },
       ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}