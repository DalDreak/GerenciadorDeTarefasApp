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
           
           // Separar tarefas pendentes e concluídas
           final pendingTasks = tasks.where((task) => !task.isCompleted).toList();
           final completedTasks = tasks.where((task) => task.isCompleted).toList();
           
           // Ordenar alfabeticamente
           pendingTasks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
           completedTasks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
           
           return SingleChildScrollView(
             padding: const EdgeInsets.all(16.0),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 // Seção de Tarefas Pendentes
                 Card(
                   elevation: 4,
                   child: Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           children: [
                             Icon(Icons.pending_actions, color: Colors.orange),
                             const SizedBox(width: 8),
                             Text(
                               'Tarefas Pendentes (${pendingTasks.length})',
                               style: const TextStyle(
                                 fontSize: 18,
                                 fontWeight: FontWeight.bold,
                                 color: Colors.orange,
                               ),
                             ),
                           ],
                         ),
                         const SizedBox(height: 12),
                         if (pendingTasks.isEmpty)
                           const Padding(
                             padding: EdgeInsets.symmetric(vertical: 16.0),
                             child: Text(
                               'Nenhuma tarefa pendente',
                               style: TextStyle(color: Colors.grey, fontSize: 16),
                             ),
                           )
                         else
                           ...pendingTasks.map((task) => Card(
                             margin: const EdgeInsets.only(bottom: 8),
                             child: ListTile(
                               leading: Checkbox(
                                 value: task.isCompleted,
                                 onChanged: (value) => _toggleTask(task.id, value ?? false),
                               ),
                               title: Text(
                                 task.title,
                                 style: const TextStyle(fontSize: 16),
                               ),
                               trailing: IconButton(
                                 icon: const Icon(Icons.delete, color: Colors.red),
                                 onPressed: () => _removeTask(task.id),
                               ),
                             ),
                           )).toList(),
                       ],
                     ),
                   ),
                 ),
                 
                 const SizedBox(height: 16),
                 
                 // Seção de Tarefas Concluídas
                 Card(
                   elevation: 4,
                   child: Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           children: [
                             Icon(Icons.check_circle, color: Colors.green),
                             const SizedBox(width: 8),
                             Text(
                               'Tarefas Concluídas (${completedTasks.length})',
                               style: const TextStyle(
                                 fontSize: 18,
                                 fontWeight: FontWeight.bold,
                                 color: Colors.green,
                               ),
                             ),
                           ],
                         ),
                         const SizedBox(height: 12),
                         if (completedTasks.isEmpty)
                           const Padding(
                             padding: EdgeInsets.symmetric(vertical: 16.0),
                             child: Text(
                               'Nenhuma tarefa concluída',
                               style: TextStyle(color: Colors.grey, fontSize: 16),
                             ),
                           )
                         else
                           ...completedTasks.map((task) => Card(
                             margin: const EdgeInsets.only(bottom: 8),
                             child: ListTile(
                               leading: Checkbox(
                                 value: task.isCompleted,
                                 onChanged: (value) => _toggleTask(task.id, value ?? false),
                               ),
                               title: Text(
                                 task.title,
                                 style: const TextStyle(
                                   fontSize: 16,
                                   decoration: TextDecoration.lineThrough,
                                   color: Colors.grey,
                                 ),
                               ),
                               trailing: IconButton(
                                 icon: const Icon(Icons.delete, color: Colors.red),
                                 onPressed: () => _removeTask(task.id),
                               ),
                             ),
                           )).toList(),
                       ],
                     ),
                   ),
                 ),
               ],
             ),
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