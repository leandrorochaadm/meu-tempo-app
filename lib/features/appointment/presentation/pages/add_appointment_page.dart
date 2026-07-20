import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_primary_button.dart';

/// Resultado da criação de compromisso devolvido via `Navigator.pop`.
class NewAppointment {
  const NewAppointment({
    required this.title,
    required this.startMinute,
    required this.durationMinutes,
  });

  final String title;
  final int startMinute;
  final int durationMinutes;
}

/// Formulário de novo compromisso — campo de título **no topo**; hora e duração
/// via chips.
class AddAppointmentPage extends StatefulWidget {
  const AddAppointmentPage({super.key});

  @override
  State<AddAppointmentPage> createState() => _AddAppointmentPageState();
}

class _AddAppointmentPageState extends State<AddAppointmentPage> {
  final _title = TextEditingController();
  int _startMinute = 9 * 60; // 09:00
  int _duration = 60;

  static const _hourOptions = [7, 8, 9, 10, 12, 14, 15, 18, 20];
  static const _durationOptions = [30, 60, 90, 120];

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(NewAppointment(
      title: title,
      startMinute: _startMinute,
      durationMinutes: _duration,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo compromisso')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(context.space.lg),
          children: [
            TextField(
              controller: _title,
              autofocus: true,
              style: context.text.bodyMedium,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            SizedBox(height: context.space.xl),
            Text('Início', style: context.text.labelLarge),
            SizedBox(height: context.space.sm),
            Wrap(
              spacing: context.space.sm,
              children: [
                for (final h in _hourOptions)
                  ChoiceChip(
                    label: Text('${h}h'),
                    selected: _startMinute == h * 60,
                    onSelected: (_) => setState(() => _startMinute = h * 60),
                  ),
              ],
            ),
            SizedBox(height: context.space.xl),
            Text('Duração', style: context.text.labelLarge),
            SizedBox(height: context.space.sm),
            Wrap(
              spacing: context.space.sm,
              children: [
                for (final d in _durationOptions)
                  ChoiceChip(
                    label: Text('$d min'),
                    selected: _duration == d,
                    onSelected: (_) => setState(() => _duration = d),
                  ),
              ],
            ),
            SizedBox(height: context.space.xxxl),
            AppPrimaryButton(label: 'Criar compromisso', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
