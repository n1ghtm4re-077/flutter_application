import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(home: TodoScreen());
}

class TodoItem {
  String id;
  String text;
  bool done;

  TodoItem({required this.id, required this.text, this.done = false});
}

class TodoScreen extends StatefulWidget {
  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final List<TodoItem> _list = [];
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  int _mode = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getData();
    _searchCtrl.addListener(() {
      setState(() {
        _query = _searchCtrl.text;
      });
    });
  }

  void _getData() async {
    await Future.delayed(Duration(milliseconds: 300));
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('list');
      if (raw == null) {
        setState(() => _loading = false);
        return;
      }
      final parsed = jsonDecode(raw);
      final temp = <TodoItem>[];
      parsed.forEach((key, val) {
        temp.add(TodoItem(
          id: key.toString(),
          text: val['text'] ?? '',
          done: val['done'] == true,
        ));
      });
      _list.clear();
      _list.addAll(temp);
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _store() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, dynamic>{};
      for (var el in _list) {
        map[el.id] = {'text': el.text, 'done': el.done};
      }
      prefs.setString('list', jsonEncode(map));
    } catch (_) {}
  }

  List<TodoItem> _visible() {
    var out = List<TodoItem>.from(_list);
    if (_query.isNotEmpty) {
      out = out.where((el) => el.text.toLowerCase().contains(_query.toLowerCase())).toList();
    }
    if (_mode == 1) {
      out = out.where((el) => !el.done).toList();
    } else if (_mode == 2) {
      out = out.where((el) => el.done).toList();
    }
    out.sort((a, b) => int.parse(b.id).compareTo(int.parse(a.id)));
    return out;
  }

  void _add() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Добавить'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Отмена')),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) Navigator.pop(ctx, ctrl.text.trim());
            },
            child: Text('Ок'),
          ),
        ],
      ),
    ).then((val) {
      if (val != null) {
        setState(() {
          _list.insert(0, TodoItem(id: DateTime.now().millisecondsSinceEpoch.toString(), text: val));
        });
        _store();
      }
    });
  }

  void _toggle(TodoItem item) {
    final idx = _list.indexWhere((el) => el.id == item.id);
    if (idx >= 0) {
      setState(() => _list[idx].done = !_list[idx].done);
      _store();
    }
  }

  void _edit(TodoItem item) {
    final ctrl = TextEditingController(text: item.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Править'),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Отмена')),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) Navigator.pop(ctx, ctrl.text.trim());
            },
            child: Text('Сохранить'),
          ),
        ],
      ),
    ).then((val) {
      if (val != null) {
        final idx = _list.indexWhere((el) => el.id == item.id);
        if (idx >= 0) {
          setState(() => _list[idx].text = val);
          _store();
        }
      }
    });
  }

  void _remove(TodoItem item) {
    setState(() => _list.removeWhere((el) => el.id == item.id));
    _store();
  }

  void _confirm(TodoItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Удалить'),
        content: Text('${item.text}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Нет')),
          TextButton(
            onPressed: () {
              _remove(item);
              Navigator.pop(ctx);
            },
            child: Text('Да'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final items = _visible();
    return Scaffold(
      appBar: AppBar(
        title: Text('Задачи'),
        actions: [
          PopupMenuButton(
            onSelected: (v) => setState(() => _mode = v),
            itemBuilder: (_) => [
              PopupMenuItem(value: 0, child: Text('Все')),
              PopupMenuItem(value: 1, child: Text('Активные')),
              PopupMenuItem(value: 2, child: Text('Сделаны')),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(hintText: 'Искать...', prefixIcon: Icon(Icons.search)),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Показано: ${items.length}'),
                Spacer(),
                Text('Всего: ${_list.length}'),
              ],
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.list, size: 70, color: Colors.grey[400]),
                        SizedBox(height: 10),
                        Text(_query.isEmpty ? 'Пусто' : 'Не найдено'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final el = items[i];
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Checkbox(value: el.done, onChanged: (_) => _toggle(el)),
                          title: Text(
                            el.text,
                            style: TextStyle(
                              decoration: el.done ? TextDecoration.lineThrough : null,
                              color: el.done ? Colors.grey : Colors.black,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, size: 20),
                                onPressed: () => _edit(el),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () => _confirm(el),
                              ),
                            ],
                          ),
                          onTap: () => _toggle(el),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}
