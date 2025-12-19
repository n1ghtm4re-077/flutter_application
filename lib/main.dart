import 'package:flutter/material.dart';

class CalendarApp extends StatelessWidget {
  const CalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CalendarScreen(),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _current = DateTime.now();
  DateTime _selected = DateTime.now();
  final List<String> _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  List<DateTime?> _getDays() {
    var days = <DateTime?>[];
    var first = DateTime(_current.year, _current.month, 1);
    var last = DateTime(_current.year, _current.month + 1, 0);
    
    var pad = first.weekday - 1;
    for (var i = 0; i < pad; i++) days.add(null);
    
    for (var d = 1; d <= last.day; d++) {
      days.add(DateTime(_current.year, _current.month, d));
    }
    
    while (days.length < 42) days.add(null);
    return days;
  }

  String _getTitle() {
    var months = ['Январь','Февраль','Март','Апрель','Май','Июнь',
                  'Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'];
    return '${months[_current.month-1]} ${_current.year}';
  }

  void _prevMonth() => setState(() {
    _current = _current.month == 1 
      ? DateTime(_current.year-1, 12) 
      : DateTime(_current.year, _current.month-1);
  });

  void _nextMonth() => setState(() {
    _current = _current.month == 12 
      ? DateTime(_current.year+1, 1) 
      : DateTime(_current.year, _current.month+1);
  });

  void _prevYear() => setState(() {
    _current = DateTime(_current.year-1, _current.month);
  });

  void _nextYear() => setState(() {
    _current = DateTime(_current.year+1, _current.month);
  });

  void _goToday() => setState(() {
    var now = DateTime.now();
    _current = now;
    _selected = now;
  });

  void _pick(DateTime d) => setState(() => _selected = d);

  bool _isToday(DateTime d) {
    var n = DateTime.now();
    return d.year==n.year && d.month==n.month && d.day==n.day;
  }

  bool _isSelected(DateTime d) {
    return d.year==_selected.year && d.month==_selected.month && d.day==_selected.day;
  }

  Widget _cell(DateTime? d) {
    if (d==null) return Container(margin: EdgeInsets.all(2));
    
    var today = _isToday(d);
    var sel = _isSelected(d);
    var col = today ? Colors.blueAccent : (sel ? Colors.lightBlue[100]! : Colors.white);
    var txtCol = today ? Colors.white : (sel ? Colors.black : Colors.black87);
    var bold = today ? FontWeight.bold : (sel ? FontWeight.w500 : FontWeight.normal);
    
    return GestureDetector(
      onTap: () => _pick(d),
      child: Container(
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: col,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: today ? Colors.blueAccent : Colors.lightBlue[100]!,
            width: 1.5,
          ),
          boxShadow: today||sel ? [
            BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 4, offset: Offset(0,2))
          ] : null,
        ),
        child: Center(child: Text('${d.day}',style: TextStyle(color: txtCol, fontWeight: bold, fontSize: 16))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[100],
        elevation: 4,
        title: Text('Календарь', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 12, offset: Offset(0,4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_current.year}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: Colors.blueGrey)),
              SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(icon: Icon(Icons.first_page), color: Colors.blueGrey, onPressed: _prevYear),
                IconButton(icon: Icon(Icons.chevron_left), color: Colors.blueGrey, onPressed: _prevMonth),
                Container(padding: EdgeInsets.symmetric(horizontal:20, vertical:10), child: Text(_getTitle(), style: TextStyle(fontSize:18, fontWeight: FontWeight.w500, color: Colors.blueGrey))),
                IconButton(icon: Icon(Icons.chevron_right), color: Colors.blueGrey, onPressed: _nextMonth),
                IconButton(icon: Icon(Icons.last_page), color: Colors.blueGrey, onPressed: _nextYear),
              ]),
              SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: _weekdays.map((w)=>Padding(
                padding: EdgeInsets.symmetric(horizontal:8, vertical:12),
                child: Text(w, style: TextStyle(fontWeight: FontWeight.w400, color: Colors.blueGrey, fontSize:14))
              )).toList()),
              SizedBox(height: 8),
              Expanded(child: GridView.builder(
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:7, childAspectRatio:1.2, mainAxisSpacing:2, crossAxisSpacing:2),
                itemCount: _getDays().length,
                itemBuilder: (c,i) => _cell(_getDays()[i]),
              )),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _goToday,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[100],
                  foregroundColor: Colors.blueGrey,
                  padding: EdgeInsets.symmetric(horizontal:24, vertical:12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Сегодня', style: TextStyle(fontSize:16)),
              ),
              SizedBox(height:8),
              Text('Выбрано: ${_selected.day}.${_selected.month}.${_selected.year}', style: TextStyle(color:Colors.blueGrey, fontSize:14)),
            ],
          ),
        ),
      ),
    );
  }
}

void main() => runApp(const CalendarApp());