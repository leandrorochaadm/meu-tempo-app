import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/utils/formatters/duration_formatter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/active_timer_bloc.dart';
import '../pages/edit_task_args.dart';
import '../pages/edit_task_page.dart';

/// Barra "now playing" do cronômetro — fixa no rodapé, visível em todas as telas
/// enquanto uma **folha de tarefa** está em contagem. Mostra nome, trilha e o
/// tempo ao vivo, com ações de editar, concluir (com confirmação) e parar.
///
/// Reage ao [AuthBloc] para (re)assinar os fluxos ao logar e limpar ao sair — o
/// `uid` só existe autenticado. Some sozinha quando não há cronômetro (estado
/// [ActiveTimerHidden]), inclusive na tela de login.
class ActiveTimerBar extends StatefulWidget {
  const ActiveTimerBar({super.key});

  @override
  State<ActiveTimerBar> createState() => _ActiveTimerBarState();
}

class _ActiveTimerBarState extends State<ActiveTimerBar> {
  /// Mede a altura renderizada da barra para posicionar o snackbar de erro logo
  /// acima dela (a barra varia de altura conforme tenha trilha ou não).
  final GlobalKey _barKey = GlobalKey();

  void _showError(BuildContext context, String message) {
    final barHeight = _barKey.currentContext?.size?.height ?? 0;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(
          context.space.lg,
          0,
          context.space.lg,
          barHeight + context.space.sm,
        ),
      ));
  }

  @override
  void initState() {
    super.initState();
    // Sessão já autenticada ao montar (login persistente): assina de imediato.
    if (context.read<AuthBloc>().state is AuthAuthenticated) {
      context.read<ActiveTimerBloc>().add(const ActiveTimerStarted());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
          listener: (context, state) {
            final bloc = context.read<ActiveTimerBloc>();
            if (state is AuthAuthenticated) {
              bloc.add(const ActiveTimerStarted());
            } else {
              bloc.add(const ActiveTimerReset());
            }
          },
        ),
        // Falha de parar/concluir/editar → aviso, sem sumir com a barra.
        BlocListener<ActiveTimerBloc, ActiveTimerState>(
          listenWhen: (_, curr) => curr is ActiveTimerActionFailed,
          listener: (context, state) {
            if (state is ActiveTimerActionFailed) {
              _showError(context, state.message);
            }
          },
        ),
      ],
      child: BlocBuilder<ActiveTimerBloc, ActiveTimerState>(
        // Ignora o efeito de falha: a barra mantém o estado renderizado antes.
        buildWhen: (_, curr) => curr is! ActiveTimerActionFailed,
        builder: (context, state) {
          final motion = context.motion;
          // Entra/sai deslizando em altura + fade (movimento sutil do design).
          return AnimatedSwitcher(
            key: _barKey,
            duration: motion.medium,
            switchInCurve: motion.curve,
            switchOutCurve: motion.curve,
            transitionBuilder: (child, animation) => SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: switch (state) {
              ActiveTimerHidden() =>
                const SizedBox.shrink(key: ValueKey('active-timer-hidden')),
              ActiveTimerRunning() =>
                _Bar(key: const ValueKey('active-timer-running'), state: state),
              // Inalcançável em runtime: `buildWhen` ignora o estado de falha.
              ActiveTimerActionFailed() => const SizedBox.shrink(),
            },
          );
        },
      ),
    );
  }
}

class _Bar extends StatefulWidget {
  const _Bar({super.key, required this.state});

  final ActiveTimerRunning state;

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> {
  /// Bloqueia reentrância enquanto uma ação assíncrona (navegar/confirmar) está
  /// em andamento — impede toque duplo abrir duas telas/diálogos.
  bool _busy = false;

  ActiveTimerRunning get state => widget.state;

  Future<void> _edit() async {
    if (_busy) return;
    setState(() => _busy = true);
    final bloc = context.read<ActiveTimerBloc>();
    final args = EditTaskArgs.fromContext(state.editContext, state.lists);
    final result = await context.push<EditTaskResult>(
      Routes.editTask,
      extra: args,
    );
    if (result != null) {
      bloc.add(ActiveTimerEditSubmitted(state.taskId, result));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _complete() async {
    if (_busy) return;
    setState(() => _busy = true);
    final bloc = context.read<ActiveTimerBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Concluir tarefa?'),
        content: Text(
          'Marcar "${state.title}" como concluída? '
          'O cronômetro será parado e o tempo desta sessão, salvo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Concluir'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      bloc.add(ActiveTimerCompleteRequested(state.taskId));
    }
    if (mounted) setState(() => _busy = false);
  }

  void _stop() =>
      context.read<ActiveTimerBloc>().add(const ActiveTimerStopRequested());

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasTrail = state.ancestryLabel.isNotEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.timerActiveSurface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.space.lg,
            context.space.md,
            context.space.sm,
            context.space.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium
                    ?.copyWith(color: colors.textPrimary),
              ),
              if (hasTrail) ...[
                SizedBox(height: context.space.xs),
                Text(
                  state.ancestryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall
                      ?.copyWith(color: colors.textSecondary),
                ),
              ],
              SizedBox(height: context.space.sm),
              Row(
                children: [
                  _LiveElapsed(startedAt: state.startedAt),
                  const Spacer(),
                  IconButton(
                    onPressed: _busy ? null : _edit,
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_rounded),
                    color: colors.textSecondary,
                  ),
                  IconButton(
                    onPressed: _busy ? null : _complete,
                    tooltip: 'Concluir',
                    icon: const Icon(Icons.check_circle_rounded),
                    color: colors.success,
                  ),
                  IconButton(
                    onPressed: _busy ? null : _stop,
                    tooltip: 'Parar',
                    icon: const Icon(Icons.stop_circle_rounded),
                    color: colors.danger,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Contador ao vivo (hh:mm:ss) da sessão atual, com pulso suave no ícone —
/// derivação de apresentação do tempo (não é regra de negócio). Espelha a lógica
/// do `TaskRunningBadge`, em tamanho maior para o destaque da barra.
class _LiveElapsed extends StatefulWidget {
  const _LiveElapsed({required this.startedAt});

  final DateTime startedAt;

  @override
  State<_LiveElapsed> createState() => _LiveElapsedState();
}

class _LiveElapsedState extends State<_LiveElapsed>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;
  late int _elapsedSeconds;

  late final AnimationController _pulse;
  late final Animation<double> _pulseOpacity;
  bool _pulseStarted = false;

  @override
  void initState() {
    super.initState();
    _recompute();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(_recompute);
    });
    _pulse = AnimationController(vsync: this);
    _pulseOpacity = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_pulseStarted) {
      _pulse.duration = context.motion.pulse;
      _pulse.repeat(reverse: true);
      _pulseStarted = true;
    }
  }

  @override
  void didUpdateWidget(_LiveElapsed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startedAt != widget.startedAt) {
      setState(_recompute);
    }
  }

  void _recompute() {
    final diff = DateTime.now().difference(widget.startedAt).inSeconds;
    _elapsedSeconds = diff < 0 ? 0 : diff;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _pulseOpacity,
          child: Icon(
            Icons.timelapse_rounded,
            size: 20,
            color: context.colors.timerActive,
          ),
        ),
        SizedBox(width: context.space.sm),
        Text(
          DurationFormatter.hms(_elapsedSeconds),
          style: context.text.titleLarge?.copyWith(
            color: context.colors.timerActive,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
