import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(ToDo());
}

class ToDo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomeScreen());
  }
}

class Task {
  String id;
  String title;
  bool done;

  Task({required this.id, required this.title, this.done = false});

  Map<String, dynamic> toJson() {
    return {'title': title, 'done': done};
  }

  static Task fromJson(String id, Map<String, dynamic> json) {
    return Task(id: id, title: json['title'] ?? '', done: json['done'] == true);
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> items = [];
  bool loading = true;
  final searchText = TextEditingController();
  String query = '';
  int filterType = 0;

  @override
  void initState() {
    loadItems();
    searchText.addListener(() {
      setState(() {
        query = searchText.text;
      });
    });
    super.initState();
  }

  void loadItems() async {
    await Future.delayed(Duration(milliseconds: 200));
    try {
      final storage = await SharedPreferences.getInstance();
      final saved = storage.getString('tasks');
      if (saved == null) {
        setState(() {
          loading = false;
        });
        return;
      }
      final decoded = json.decode(saved);
      final loadedItems = [];
      (decoded as Map).forEach((key, value) {
        loadedItems.add(Task.fromJson(key.toString(), Map<String, dynamic>.from(value)));
      });
      loadedItems.sort((a, b) => b.id.compareTo(a.id));
      setState(() {
        items = loadedItems;
        loading = false;
      });
    } catch (err) {
      print(err);
      setState(() {
        loading = false;
      });
    }
  }

  void persist() async {
    final storage = await SharedPreferences.getInstance();
    Map<String, dynamic> data = {};
    for (var item in items) {
      data[item.id] = item.toJson();
    }
    storage.setString('tasks', json.encode(data));
  }

  void addNew() {
    TextEditingController input = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Добавить'),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(controller: input),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Отмена')),
              TextButton(
                onPressed: () {
                  if (input.text.trim().isNotEmpty) {
                    Navigator.pop(ctx, input.text.trim());
                  }
                },
                child: Text('Добавить'),
              ),
            ],
          )
        ],
      ),
    ).then((text) {
      if (text != null) {
        String newId = DateTime.now().microsecondsSinceEpoch.toString();
        Task newItem = Task(id: newId, title: text);
        setState(() {
          items.insert(0, newItem);
        });
        persist();
      }
    });
  }

  void toggleDone(Task item) {
    int pos = items.indexWhere((t) => t.id == item.id);
    if (pos >= 0) {
      setState(() {
        items[pos].done = !items[pos].done;
      });
      persist();
    }
  }

  void removeItem(Task item) {
    setState(() {
      items.removeWhere((t) => t.id == item.id);
    });
    persist();
  }

  void changeTitle(Task item) {
    TextEditingController input = TextEditingController(text: item.title);
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Изменить'),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(controller: input),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Отмена')),
              TextButton(
                onPressed: () {
                  if (input.text.trim().isNotEmpty) {
                    Navigator.pop(ctx, input.text.trim());
                  }
                },
                child: Text('Изменить'),
              ),
            ],
          )
        ],
      ),
    ).then((newText) {
      if (newText != null) {
        int pos = items.indexWhere((t) => t.id == item.id);
        if (pos >= 0) {
          setState(() {
            items[pos].title = newText;
          });
          persist();
        }
      }
    });
  }

  List<Task> get visibleItems {
    List<Task> list = List.from(items);
    if (query.isNotEmpty) {
      list = list.where((t) => t.title.toLowerCase().contains(query.toLowerCase())).toList();
    }
    if (filterType == 1) {
      list = list.where((t) => !t.done).toList();
    } else if (filterType == 2) {
      list = list.where((t) => t.done).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Загружаем...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Список дел'),
        actions: [
          DropdownButton<int>(
            value: filterType,
            items: [
              DropdownMenuItem(value: 0, child: Text('Все')),
              DropdownMenuItem(value: 1, child: Text('Не сделано')),
              DropdownMenuItem(value: 2, child: Text('Сделано')),
            ],
            onChanged: (v) {
              setState(() {
                filterType = v ?? 0;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              controller: searchText,
              decoration: InputDecoration(
                labelText: 'Поиск',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 16, bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Количество: ${visibleItems.length}', style: TextStyle(fontSize: 14)),
            ),
          ),
          Expanded(
            child: visibleItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox, size: 70, color: Colors.blueGrey[300]),
                        SizedBox(height: 20),
                        Text(query.isEmpty ? 'Нет задач' : 'Ничего не найдено'),
                        if (query.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              searchText.clear();
                            },
                            child: Text('Очистить поиск'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: visibleItems.length,
                    itemBuilder: (ctx, index) {
                      final item = visibleItems[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Card(
                          elevation: 2,
                          child: Row(
                            children: [
                              Checkbox(
                                value: item.done,
                                onChanged: (_) => toggleDone(item),
                              ),
                              Expanded(
                                child: ListTile(
                                  title: Text(
                                    item.title,
                                    style: TextStyle(
                                      decoration: item.done ? TextDecoration.lineThrough : null,
                                      color: item.done ? Colors.grey : null,
                                    ),
                                  ),
                                  onTap: () => toggleDone(item),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => changeTitle(item),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => removeItem(item),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addNew,
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    searchText.dispose();
    super.dispose();
  }
}