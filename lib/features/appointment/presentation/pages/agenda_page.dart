import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_empty_state.dart';
import '../../../../core/ui/app_list_skeleton.dart';
import '../../../../core/utils/formatters/duration_formatter.dart';
import '../../../../core/utils/formatters/time_formatter.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/entities/day_fit.dart';
import '../bloc/agenda_bloc.dart';
import 'add_appointment_page.dart';

/// Agenda do dia: compromissos por horário + aviso "cabe no dia".
class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  @override
  void initState() {
    super.initState();
    context.read<AgendaBloc>().add(const AgendaStarted());
  }

  Future<void> _add() async {
    final bloc = context.read<AgendaBloc>();
    final result = await Navigator.of(context).push<NewAppointment>(
      MaterialPageRoute(builder: (_) => const AddAppointmentPage()),
    );
    if (result != null) {
      bloc.add(AppointmentCreated(
        title: result.title,
        startMinute: result.startMinute,
        durationMinutes: result.durationMinutes,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda de hoje')),
      body: SafeArea(
        top: false,
        child: BlocConsumer<AgendaBloc, AgendaState>(
          listenWhen: (_, c) => c is AgendaError,
          listener: (context, state) {
            if (state is AgendaError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            return switch (state) {
              AgendaLoading() => const AppListSkeleton(),
              AgendaError() => const AppEmptyState(
                  icon: Icons.event_rounded,
                  title: 'Não foi possível carregar',
                  message: 'Tente novamente em instantes.',
                ),
              AgendaLoaded(:final appointments, :final fit) => Column(
                  children: [
                    _FitBanner(fit: fit),
                    Expanded(
                      child: appointments.isEmpty
                          ? const AppEmptyState(
                              icon: Icons.event_available_rounded,
                              title: 'Sem compromissos hoje',
                              message: 'Toque em + para agendar um.',
                            )
                          : ListView.separated(
                              padding: EdgeInsets.all(context.space.lg),
                              itemCount: appointments.length,
                              separatorBuilder: (_, _) =>
                                  SizedBox(height: context.space.sm),
                              itemBuilder: (context, i) => _AppointmentTile(
                                appointment: appointments[i],
                                onDelete: () => context.read<AgendaBloc>().add(
                                    AppointmentDeleted(appointments[i].id)),
                              ),
                            ),
                    ),
                  ],
                ),
            };
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _FitBanner extends StatelessWidget {
  const _FitBanner({required this.fit});
  final DayFit fit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ok = fit.fits;
    final color = ok ? colors.success : colors.warning;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(context.space.lg),
      padding: EdgeInsets.all(context.space.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: context.radius.lgRadius,
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: color, size: 20),
          SizedBox(width: context.space.sm),
          Expanded(
            child: Text(
              ok
                  ? 'Cabe no dia: ${DurationFormatter.hm(fit.plannedMinutes)} de '
                      '${DurationFormatter.hm(fit.availableMinutes)}.'
                  : 'Passou ${DurationFormatter.hm(fit.overflowMinutes)} do '
                      'disponível (${DurationFormatter.hm(fit.availableMinutes)}).',
              style: context.text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.appointment, required this.onDelete});

  final AppointmentEntity appointment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.space.lg,
        vertical: context.space.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: context.radius.lgRadius,
        border: Border(left: BorderSide(color: colors.info, width: 3)),
      ),
      child: Row(
        children: [
          // Ícone próprio de compromisso (distinto do de tarefa).
          Icon(Icons.event_rounded, color: colors.info, size: 22),
          SizedBox(width: context.space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.title, style: context.text.titleMedium),
                SizedBox(height: context.space.xs),
                Text(
                  '${TimeFormatter.clock(appointment.startMinute)}'
                  '–${TimeFormatter.clock(appointment.endMinute)}'
                  ' · ${DurationFormatter.hm(appointment.durationMinutes)}',
                  style: context.text.labelSmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_rounded, color: colors.textMuted),
            tooltip: 'Excluir',
          ),
        ],
      ),
    );
  }
}
