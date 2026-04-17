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
  String _xanax = '< 0.5';
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
      'xanax': _xanax,
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

  Widget _buildRadioPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Xanax?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          RadioListTile<String>(
            title: const Text('< 0.5'),
            value: '< 0.5',
            groupValue: _xanax,
            onChanged: (val) => setState(() => _xanax = val!),
          ),
          RadioListTile<String>(
            title: const Text('0.5 <= 1.0'),
            value: '0.5 <= 1.0',
            groupValue: _xanax,
            onChanged: (val) => setState(() => _xanax = val!),
          ),
          RadioListTile<String>(
            title: const Text('1.0 <= 1.5'),
            value: '1.0 <= 1.5',
            groupValue: _xanax,
            onChanged: (val) => setState(() => _xanax = val!),
          ),
          RadioListTile<String>(
            title: const Text('None'),
            value: 'None',
            groupValue: _xanax,
            onChanged: (val) => setState(() => _xanax = val!),
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
