import 'package:flutter/material.dart';
import 'dart:math' as math;

// Главная функция запуска приложения
void main() {
  // Стартуем наше приложение
  runApp(MyApp());
}

// Корневой виджет приложения
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Возвращаем MaterialApp с настройками
    return MaterialApp(
      title: 'Калькулятор',
      theme: ThemeData.dark(), // Используем темную тему
      debugShowCheckedModeBanner: false, // Убираем debug баннер
      home: CalculatorApp(), // Главный экран
    );
  }
}

// Класс калькулятора с состоянием
class CalculatorApp extends StatefulWidget {
  @override
  _CalculatorAppState createState() => _CalculatorAppState();
}

// Состояние калькулятора
class _CalculatorAppState extends State<CalculatorApp> {
  // Отображаемый текст
  String _displayText = '0';
  // Текущий ввод пользователя
  String _currentInput = '';
  // Первое число для операций
  double? _firstNumber;
  // Текущий оператор
  String? _currentOperator;
  // Флаг для очистки дисплея
  bool _clearDisplayNext = false;
  // История операций
  final List<String> _history = [];
  
  // Обработка нажатия кнопок
  void _handleButtonPress(String button) {
    setState(() {
      // Если на экране ошибка, сбрасываем калькулятор
      if (_displayText == 'Ошибка!' || _displayText.contains('много')) {
        _resetCalculator();
        return;
      }
      
      // Обработка разных типов кнопок
      switch (button) {
        case 'C': 
          _resetCalculator();
          break;
        case '⌫': 
          _deleteLastDigit();
          break;
        case '=': 
          _performCalculation();
          break;
        case '√': 
          _calculateSquareRoot();
          break;
        case '+':
        case '-':
        case '×':
        case '÷':
        case '^':
          _handleOperator(button);
          break;
        default: 
          _handleDigitOrDot(button);
      }
    });
  }
  
  // Полный сброс калькулятора
  void _resetCalculator() {
    _displayText = '0';
    _currentInput = '';
    _firstNumber = null;
    _currentOperator = null;
    _clearDisplayNext = false;
    // Добавляем в историю
    if (_history.length > 10) _history.removeAt(0);
    _history.add('Сброс калькулятора');
  }
  
  // Удаление последней цифры
  void _deleteLastDigit() {
    if (_currentInput.isNotEmpty) {
      // Удаляем последний символ
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      // Если строка пустая, показываем 0
      _displayText = _currentInput.isEmpty ? '0' : _currentInput;
    }
  }
  
  // Вычисление квадратного корня
  void _calculateSquareRoot() {
    if (_currentInput.isEmpty) return;
    
    try {
      final number = double.parse(_currentInput);
      
      // Проверка на отрицательное число
      if (number < 0) {
        _displayText = 'Ошибка!';
        _currentInput = _displayText;
        _history.add('√($number) = Ошибка (отрицательное число)');
        return;
      }
      
      final result = math.sqrt(number);
      _showResult(result);
      _history.add('√($number) = $_displayText');
      _currentInput = _displayText;
      _clearDisplayNext = true;
    } catch (e) {
      _displayText = 'Ошибка!';
      _currentInput = _displayText;
    }
  }
  
  // Обработка операторов
  void _handleOperator(String operator) {
    if (_currentInput.isEmpty) return;
    
    _firstNumber = double.parse(_currentInput);
    _currentOperator = operator;
    // Показываем оператор на дисплее
    _displayText = '$_currentInput $operator ';
    _currentInput = '';
  }
  
  // Обработка цифр и точки
  void _handleDigitOrDot(String button) {
    // Если нужно очистить дисплей
    if (_clearDisplayNext) {
      _currentInput = '';
      _clearDisplayNext = false;
    }
    
    // Ограничение на количество цифр
    if (_currentInput.length >= 15) {
      _displayText = 'Слишком длинное число';
      _history.add('Превышен лимит цифр');
      return;
    }
    
    // Обработка точки
    if (button == '.') {
      if (!_currentInput.contains('.')) {
        _currentInput = _currentInput.isEmpty ? '0.' : '$_currentInput.';
      }
    } 
    // Обработка цифр
    else {
      if (_currentInput == '0' || _currentInput.isEmpty) {
        _currentInput = button;
      } else {
        _currentInput = '$_currentInput$button';
      }
    }
    
    _displayText = _currentInput;
  }
  
  // Выполнение вычислений
  void _performCalculation() {
    // Проверяем, есть ли что вычислять
    if (_currentOperator == null || _currentInput.isEmpty) return;
    
    try {
      final secondNumber = double.parse(_currentInput);
      
      // Проверка деления на ноль
      if (_currentOperator == '÷' && secondNumber == 0) {
        _displayText = 'Деление на 0!';
        _currentInput = _displayText;
        _currentOperator = null;
        _clearDisplayNext = true;
        _history.add('Ошибка: деление на ноль');
        return;
      }
      
      double? result;
      String operationText = '$_firstNumber $_currentOperator $secondNumber';
      
      // Выполнение операции
      switch (_currentOperator) {
        case '+':
          result = _firstNumber! + secondNumber;
          break;
        case '-':
          result = _firstNumber! - secondNumber;
          break;
        case '×':
          result = _firstNumber! * secondNumber;
          break;
        case '÷':
          result = _firstNumber! / secondNumber;
          break;
        case '^': // Возведение в степень
          try {
            result = math.pow(_firstNumber!, secondNumber).toDouble();
            // Проверка на переполнение
            if (result.isInfinite) {
              result = null;
            }
          } catch (e) {
            result = null;
          }
          break;
      }
      
      // Обработка результата
      if (result != null) {
        _showResult(result);
        _history.add('$operationText = $_displayText');
      } else {
        _displayText = 'Переполнение!';
        _history.add('$operationText = Ошибка переполнения');
      }
      
      _currentInput = _displayText;
      _currentOperator = null;
      _clearDisplayNext = true;
      
    } catch (e) {
      _displayText = 'Ошибка вычисления';
      _currentInput = _displayText;
    }
  }
  
  // Отображение результата
  void _showResult(double result) {
    // Проверка на специальные значения
    if (result.isInfinite || result.isNaN) {
      _displayText = 'Ошибка!';
      return;
    }
    
    String resultString = result.toString();
    
    // Убираем .0 в конце целых чисел
    if (resultString.endsWith('.0')) {
      resultString = resultString.substring(0, resultString.length - 2);
    }
    
    // Форматирование для отображения
    if (resultString.length > 12) {
      if (resultString.contains('.')) {
        try {
          // Пытаемся округлить
          final rounded = result.toStringAsPrecision(10);
          // Убираем лишние нули
          _displayText = double.parse(rounded).toString();
        } catch (e) {
          _displayText = 'Очень большое число';
        }
      } else {
        _displayText = 'Число слишком длинное';
      }
    } else {
      _displayText = resultString;
    }
  }
  
  // Построение кнопки калькулятора
  Widget _buildCalculatorButton(String label, Color backgroundColor, Color textColor, {double size = 80}) {
    return Container(
      margin: const EdgeInsets.all(4), // Небольшие отступы
      child: ElevatedButton(
        onPressed: () => _handleButtonPress(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40), // Скругленные углы
          ),
          padding: EdgeInsets.zero, // Убираем стандартные отступы
          minimumSize: Size(size, size),
          elevation: 3, // Тень
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 28,
            color: textColor,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Калькулятор'),
        backgroundColor: Colors.grey[900],
        actions: [
          // Кнопка истории
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('История операций'),
                  content: Container(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_history.reversed.toList()[index]),
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Закрыть'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Дисплей
            Expanded(
              flex: 1,
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(
                    _displayText,
                    style: const TextStyle(
                      fontSize: 64,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
            
            // Разделитель
            Container(
              height: 1,
              color: const Color(0xFF333333),
              margin: const EdgeInsets.symmetric(horizontal: 20),
            ),
            
            // Панель кнопок
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildButtonRow(['C', '⌫', '√', '÷']),
                    _buildButtonRow(['7', '8', '9', '×']),
                    _buildButtonRow(['4', '5', '6', '-']),
                    _buildButtonRow(['1', '2', '3', '+']),
                    _buildButtonRow(['.', '0', '^', '=']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Построение строки кнопок
  Widget _buildButtonRow(List<String> buttons) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons.map((button) {
        // Определяем тип кнопки для стилизации
        final isNumber = int.tryParse(button) != null;
        final isDot = button == '.';
        final isEquals = button == '=';
        final isOperator = ['+', '-', '×', '÷', '^'].contains(button);
        final isSpecial = ['C', '⌫', '√'].contains(button);
        
        Color backgroundColor;
        Color textColor = Colors.white;
        double size = 75;
        
        if (isSpecial) {
          backgroundColor = const Color(0xFFA5A5A5);
          textColor = Colors.black;
        } else if (isOperator || isEquals) {
          backgroundColor = const Color(0xFFFF9500);
          if (isEquals) size = 75; // Кнопка "=" такого же размера
        } else if (isNumber || isDot) {
          backgroundColor = const Color(0xFF333333);
        } else {
          backgroundColor = Colors.grey[800]!;
        }
        
        return _buildCalculatorButton(button, backgroundColor, textColor, size: size);
      }).toList(),
    );
  }
}