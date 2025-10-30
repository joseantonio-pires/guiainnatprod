import 'package:flutter/material.dart';

class FeedbackDialog extends StatefulWidget {
  final String imageId;
  final String predictedClass;
  final double confidence;
  final List<String> allClasses;
  final void Function(String feedback, String? correctClass) onFeedback;

  const FeedbackDialog({
    super.key,
    required this.imageId,
    required this.predictedClass,
    required this.confidence,
    required this.allClasses,
    required this.onFeedback,
  });

  @override
  // ignore: library_private_types_in_public_api
  _FeedbackDialogState createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  String? _selectedCorrectClass;
  bool _isCorrect = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Avaliar Classificação'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Espécie identificada: ${widget.predictedClass}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Confiança: ${(widget.confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: widget.confidence > 0.8
                    ? Colors.green
                    : widget.confidence > 0.6
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'A classificação está correta?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _isCorrect = true;
                  _selectedCorrectClass = null;
                });
              },
              child: Row(
                children: [
                  Icon(
                    _isCorrect
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: _isCorrect
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text('Sim, está correta'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _isCorrect = false;
                });
              },
              child: Row(
                children: [
                  Icon(
                    !_isCorrect
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: !_isCorrect
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text('Não, está incorreta'),
                ],
              ),
            ),
            if (!_isCorrect) ...[
              const SizedBox(height: 16),
              const Text(
                'Qual é a espécie correta?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCorrectClass,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Selecione a espécie correta',
                ),
                items: widget.allClasses.map((String class_) {
                  return DropdownMenuItem<String>(
                    value: class_,
                    child: Text(class_.replaceAll('_', ' ').toUpperCase()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCorrectClass = newValue;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isCorrect || _selectedCorrectClass != null
              ? () {
                  final feedback = _isCorrect ? 'correct' : 'incorrect';
                  widget.onFeedback(feedback, _selectedCorrectClass);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
