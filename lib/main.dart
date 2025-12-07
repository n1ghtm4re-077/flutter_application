import 'package:flutter/material.dart';

void startApp() {
  runApp(Converter());
}

class Converter extends StatelessWidget {
  const Converter({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Конвертер',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatelessWidget {
  final items = [
    _ItemData('📏', 'Расстояние', Colors.blueAccent, 'dist'),
    _ItemData('⚖️', 'Масса', Colors.green, 'mass'),
    _ItemData('🌡️', 'Тепло', Colors.red, 'heat'),
    _ItemData('⏳', 'Длительность', Colors.orange, 'dur'),
    _ItemData('🧪', 'Жидкости', Colors.purple, 'liquid'),
    _ItemData('💎', 'Богатство', Colors.amber, 'cash'),
  ];

  MainScreen({super.key});

  String _helper(String code) {
    switch (code) {
      case 'dist': return 'метры, футы, сажени';
      case 'mass': return 'пуды, фунты, килограммы';
      case 'heat': return 'градусы разные';
      case 'dur': return 'часы, минуты, сутки';
      case 'liquid': return 'ведра, бочки, литры';
      case 'cash': return 'рубли, талеры';
      default: return 'кое-что';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Переводчик величин'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text(
              'Что будем переводить?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              'Есть такие варианты:',
              style: TextStyle(color: Colors.brown),
            ),
            SizedBox(height: 16),
            Expanded(
              child: _buildGrid(),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                border: Border.all(color: Colors.yellow),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Тапните по плитке чтобы перейти',
                    style: TextStyle(color: Colors.brown),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        return _tile(items[index], ctx);
      },
    );
  }

  Widget _tile(_ItemData data, BuildContext ctx) {
    return InkWell(
      onTap: () {
        Navigator.of(ctx).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => CalculationScreen(
              header: data.name,
              mainColor: data.color,
              what: data.code,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: data.color.withOpacity(0.1),
          border: Border.all(color: data.color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(data.emoji, style: TextStyle(fontSize: 48)),
            SizedBox(height: 6),
            Text(
              data.name,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: data.color,
              ),
            ),
            SizedBox(height: 3),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _helper(data.code),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemData {
  final String emoji;
  final String name;
  final Color color;
  final String code;

  _ItemData(this.emoji, this.name, this.color, this.code);
}

class CalculationScreen extends StatefulWidget {
  final String header;
  final Color mainColor;
  final String what;

  const CalculationScreen({
    super.key,
    required this.header,
    required this.mainColor,
    required this.what,
  });

  @override
  State<CalculationScreen> createState() => _CalculationScreenState();
}

class _CalculationScreenState extends State<CalculationScreen> {
  final TextEditingController inputController = TextEditingController();
  double outputValue = 0.0;
  String leftUnit = '';
  String rightUnit = '';
  List<String> available = [];

  final Map<String, Map<String, double>> ratios = {
    'dist': {'метр': 1, 'километр': 1000, 'фут': 0.3048, 'сажень': 2.1336, 'верста': 1066.8},
    'mass': {'килограмм': 1, 'грамм': 0.001, 'пуд': 16.38, 'фунт': 0.4095, 'центнер': 100},
    'dur': {'секунда': 1, 'минута': 60, 'час': 3600, 'сутки': 86400, 'неделя': 604800},
    'liquid': {'литр': 1, 'миллилитр': 0.001, 'ведро': 12.3, 'бочка': 492, 'галлон': 3.785},
    'cash': {'рубль': 1, 'доллар': 0.011, 'евро': 0.01, 'тенге': 5.2, 'юань': 0.08},
  };

  @override
  void initState() {
    super.initState();
    _setup();
    inputController.addListener(_recalc);
  }

  void _setup() {
    if (widget.what == 'dist') {
      available = ['метр', 'километр', 'фут', 'сажень', 'верста'];
    } else if (widget.what == 'mass') {
      available = ['килограмм', 'грамм', 'пуд', 'фунт', 'центнер'];
    } else if (widget.what == 'heat') {
      available = ['Цельсий', 'Фаренгейт', 'Кельвин', 'Реомюр'];
    } else if (widget.what == 'dur') {
      available = ['секунда', 'минута', 'час', 'сутки', 'неделя'];
    } else if (widget.what == 'liquid') {
      available = ['литр', 'миллилитр', 'ведро', 'бочка', 'галлон'];
    } else if (widget.what == 'cash') {
      available = ['рубль', 'доллар', 'евро', 'тенге', 'юань'];
    } else {
      available = ['Штука', 'Штука другая'];
    }

    leftUnit = available.first;
    rightUnit = available.length > 1 ? available[1] : available.first;
  }

  void _recalc() {
    if (inputController.text.isEmpty) {
      setState(() {
        outputValue = 0;
      });
      return;
    }

    var text = inputController.text.replaceAll(',', '.');
    double? v = double.tryParse(text);
    if (v == null) {
      setState(() {
        outputValue = 0;
      });
      return;
    }

    double r = _compute(v, leftUnit, rightUnit);
    setState(() {
      outputValue = r;
    });
  }

  double _compute(double v, String l, String r) {
    if (l == r) return v;

    if (widget.what == 'heat') {
      if (l == 'Цельсий' && r == 'Фаренгейт') return v * 9 / 5 + 32;
      if (l == 'Фаренгейт' && r == 'Цельсий') return (v - 32) * 5 / 9;
      if (l == 'Цельсий' && r == 'Кельвин') return v + 273.15;
      if (l == 'Кельвин' && r == 'Цельсий') return v - 273.15;
      if (l == 'Цельсий' && r == 'Реомюр') return v * 4 / 5;
      if (l == 'Реомюр' && r == 'Цельсий') return v * 5 / 4;
      return v;
    }

    var map = ratios[widget.what];
    if (map == null) return v;

    double? leftMul = map[l];
    double? rightMul = map[r];
    if (leftMul == null || rightMul == null) return v;

    double meters = v * leftMul;
    return meters / rightMul;
  }

  void _flip() {
    setState(() {
      var t = leftUnit;
      leftUnit = rightUnit;
      rightUnit = t;
      _recalc();
    });
  }

  void _press(String s) {
    if (s == 'C') {
      inputController.clear();
      return;
    }
    if (s == '<') {
      if (inputController.text.isNotEmpty) {
        inputController.text = inputController.text.substring(0, inputController.text.length - 1);
      }
      return;
    }
    if (s == '.' && inputController.text.contains('.')) {
      return;
    }
    if (inputController.text == '0' && s != '.') {
      inputController.text = s;
    } else {
      inputController.text += s;
    }
  }

  String _trim(double x) {
    var s = x.toString();
    if (!s.contains('.')) return s;
    while (s.endsWith('0')) {
      s = s.substring(0, s.length - 1);
    }
    if (s.endsWith('.')) {
      s = s.substring(0, s.length - 1);
    }
    if (s == '-0') return '0';
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.header),
        backgroundColor: widget.mainColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.swap_vert),
            onPressed: _flip,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          children: [
            _topBox(),
            SizedBox(height: 24),
            Icon(Icons.import_export, color: widget.mainColor, size: 32),
            SizedBox(height: 24),
            _bottomBox(),
            SizedBox(height: 30),
            _keyboard(),
          ],
        ),
      ),
    );
  }

  Widget _topBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Откуда', style: TextStyle(color: Colors.grey[600])),
          SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: inputController,
                  keyboardType: TextInputType.none,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    suffixText: leftUnit,
                    suffixStyle: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 22, letterSpacing: 1),
                ),
              ),
              SizedBox(width: 10),
              Container(
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButton<String>(
                  value: leftUnit,
                  items: available.map((e) {
                    return DropdownMenuItem<String>(
                      value: e,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(e, overflow: TextOverflow.ellipsis),
                      ),
                    );
                  }).toList(),
                  onChanged: (newVal) {
                    if (newVal != null) {
                      setState(() {
                        leftUnit = newVal;
                        _recalc();
                      });
                    }
                  },
                  isExpanded: true,
                  underline: SizedBox(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomBox() {
    return Container(
      decoration: BoxDecoration(
        color: widget.mainColor.withOpacity(0.05),
        border: Border.all(color: widget.mainColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Куда', style: TextStyle(color: Colors.grey[600])),
          SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _trim(outputValue),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: widget.mainColor,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Container(
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButton<String>(
                  value: rightUnit,
                  items: available.map((e) {
                    return DropdownMenuItem<String>(
                      value: e,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(e, overflow: TextOverflow.ellipsis),
                      ),
                    );
                  }).toList(),
                  onChanged: (newVal) {
                    if (newVal != null) {
                      setState(() {
                        rightUnit = newVal;
                        _recalc();
                      });
                    }
                  },
                  isExpanded: true,
                  underline: SizedBox(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _keyboard() {
    List<List<String>> layout = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      ['C', '0', '.', '<'],
    ];

    return Expanded(
      child: Column(
        children: layout.map((row) {
          return Expanded(
            child: Row(
              children: row.map((key) {
                bool isAction = key == 'C' || key == '<';
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: ElevatedButton(
                      onPressed: () => _press(key),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAction ? Colors.grey[200] : Colors.white,
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        key == '<' ? '←' : key,
                        style: TextStyle(
                          fontSize: key == '<' ? 20 : 24,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }
}