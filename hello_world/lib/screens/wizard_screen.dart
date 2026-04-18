import 'package:flutter/material.dart';

class WizardScreen extends StatefulWidget {
  const WizardScreen({Key? key}) : super(key: key);

  @override
  _WizardScreenState createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 7;

  // Wizard Data
  double _mood = 5;
  double _sleep = 5;
  String _x = '1';
  double _workload = 5;
  double _clouds = 0;
  double _bubs = 5;
  double _energy = 5;

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishWizard();
    }
  }

  void _finishWizard() {
    final result = <String, dynamic>{
      'mood': _mood.toInt(),
      'sleep': _sleep.toInt(),
      'x': _x,
      'workload': _workload.toInt(),
      'clouds': _clouds.toInt(),
      'bubs': _bubs.toInt(),
      'energy': _energy.toInt(),
    };
    Navigator.pop(context, result);
  }

  Widget _buildDialPage({
    required String question,
    required double value,
    required ValueChanged<double> onChanged,
    double min = 1,
    double max = 10,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            question,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Text(
            value.toInt().toString(),
            style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            label: value.toInt().toString(),
            onChanged: onChanged,
          ),
          const SizedBox(height: 16),
          Text(
            'Page ${_currentPage + 1} of $_totalPages',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _nextPage,
            child: Text(_currentPage == _totalPages - 1 ? 'Finish' : 'Next'),
          )
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('X Scale'),
        content: const Text('1 = 0\n2 = < 1\n3 = > 1'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'X',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.cyanAccent),
                tooltip: '1 = 0, 2 = < 1, 3 = > 1',
                onPressed: _showInfoDialog,
              ),
            ],
          ),
          const SizedBox(height: 32),
          RadioListTile<String>(
            title: const Text('1'),
            value: '1',
            groupValue: _x,
            onChanged: (val) => setState(() => _x = val!),
          ),
          RadioListTile<String>(
            title: const Text('2'),
            value: '2',
            groupValue: _x,
            onChanged: (val) => setState(() => _x = val!),
          ),
          RadioListTile<String>(
            title: const Text('3'),
            value: '3',
            groupValue: _x,
            onChanged: (val) => setState(() => _x = val!),
          ),
          const SizedBox(height: 16),
          Text(
            'Page ${_currentPage + 1} of $_totalPages',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _nextPage,
            child: const Text('Next'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Check-In'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (idx) => setState(() => _currentPage = idx),
        children: [
          _buildDialPage(
            question: 'How are you today?',
            value: _mood,
            onChanged: (val) => setState(() => _mood = val),
          ),
          _buildDialPage(
            question: 'How did you feel your sleep was last night?',
            value: _sleep,
            onChanged: (val) => setState(() => _sleep = val),
          ),
          _buildRadioPage(),
          _buildDialPage(
            question: 'How much do you have going on at work?',
            value: _workload,
            onChanged: (val) => setState(() => _workload = val),
          ),
          _buildDialPage(
            question: 'How many clouds since the last entry?',
            value: _clouds,
            min: 0,
            max: 20,
            onChanged: (val) => setState(() => _clouds = val),
          ),
          _buildDialPage(
            question: 'Bubs?',
            value: _bubs,
            onChanged: (val) => setState(() => _bubs = val),
          ),
          _buildDialPage(
            question: 'Energy level?',
            value: _energy,
            onChanged: (val) => setState(() => _energy = val),
          ),
        ],
      ),
    );
  }
}
