import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_empty_state.dart';
import '../../../../core/ui/app_list_skeleton.dart';
import '../../../../core/utils/formatters/duration_formatter.dart';
import '../bloc/settings_bloc.dart';

/// Configurações do dia. Por ora: horas disponíveis para o "cabe no dia"
/// (Req. 4) — um valor que o usuário define uma vez, via chips.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// Presets de horas disponíveis por dia (2h a 12h), em minutos.
  static const List<int> _presetsMinutes = [
    120, 180, 240, 300, 360, 420, 480, 540, 600, 660, 720,
  ];

  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(const SettingsStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: SafeArea(
        top: false,
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return switch (state) {
              SettingsLoading() => const AppListSkeleton(),
              SettingsError() => const AppEmptyState(
                  icon: Icons.settings_rounded,
                  title: 'Não foi possível carregar',
                  message: 'Tente novamente em instantes.',
                ),
              SettingsLoaded(:final availableMinutesPerDay) => _SettingsBody(
                  selectedMinutes: availableMinutesPerDay,
                  presets: _presetsMinutes,
                  onSelected: (m) => context
                      .read<SettingsBloc>()
                      .add(AvailableMinutesChanged(m)),
                ),
            };
          },
        ),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.selectedMinutes,
    required this.presets,
    required this.onSelected,
  });

  final int selectedMinutes;
  final List<int> presets;
  final void Function(int minutes) onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(context.space.lg),
      children: [
        Text('Horas disponíveis por dia', style: context.text.titleMedium),
        SizedBox(height: context.space.xs),
        Text(
          'Usado no aviso "cabe no dia" ao planejar tarefas e compromissos.',
          style: context.text.bodySmall,
        ),
        SizedBox(height: context.space.md),
        Wrap(
          spacing: context.space.sm,
          runSpacing: context.space.sm,
          children: [
            for (final m in presets)
              ChoiceChip(
                label: Text(DurationFormatter.hm(m)),
                selected: m == selectedMinutes,
                onSelected: (_) => onSelected(m),
              ),
          ],
        ),
      ],
    );
  }
}
