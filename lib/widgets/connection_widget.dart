import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// ---------------------------------------------------------------------------
/// ConnectionWidget — the main connection control.
/// ---------------------------------------------------------------------------
/// Reflects the REAL VPN service state passed in by the caller:
/// DISCONNECTED / CONNECTING / CONNECTED / DISCONNECTING (+ loading flag
/// while configs are being fetched). The button never fakes a state.
class ConnectionWidget extends StatefulWidget {
  const ConnectionWidget({
    super.key,
    required this.onTap,
    required this.isLoading,
    required this.status,
    this.size = 180,
  });

  final GestureTapCallback onTap;
  final bool isLoading;

  /// Raw V2Ray service state string.
  final String status;

  final double size;

  @override
  State<ConnectionWidget> createState() => _ConnectionWidgetState();
}

class _ConnectionWidgetState extends State<ConnectionWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppDurations.pulse,
  );

  bool get _connecting =>
      widget.isLoading || widget.status == 'CONNECTING';

  bool get _connected => widget.status == 'CONNECTED';

  bool get _disconnecting => widget.status == 'DISCONNECTING';

  @override
  void initState() {
    super.initState();
    if (_connecting) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ConnectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_connecting && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!_connecting && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  (Color, IconData, String) _resolveState(SahandPalette palette) {
    if (_disconnecting) {
      return (palette.warning, Icons.power_settings_new, '');
    }
    if (_connecting) {
      return (palette.warning, Icons.power_settings_new, '');
    }
    if (_connected) {
      return (palette.success, Icons.power_settings_new, '');
    }
    return (palette.idle, Icons.power_settings_new, '');
  }

  @override
  Widget build(BuildContext context) {
    final SahandPalette palette = SahandPalette.of(context);
    final (Color stateColor, IconData icon, _) =
        _resolveState(palette);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (BuildContext context, Widget? child) {
            final double t = Curves.easeOut.transform(_pulse.value);
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: stateColor.withValues(
                      alpha: _connecting
                          ? 0.10 + 0.14 * t
                          : _connected
                              ? 0.16
                              : 0.0,
                    ),
                    blurRadius: _connected
                        ? 42
                        : _connecting
                            ? 30 + 18 * t
                            : 0,
                    spreadRadius: _connecting ? 2 + 3 * t : 0,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _connecting ? null : widget.onTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.surface,
                  border: Border.all(
                    color: stateColor.withValues(alpha: 0.55),
                    width: 2.5,
                  ),
                ),
                child: Center(
                  child: _connecting || _disconnecting
                      ? SizedBox(
                          width: widget.size * 0.42,
                          height: widget.size * 0.42,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            strokeCap: StrokeCap.round,
                            color: stateColor,
                          ),
                        )
                      : Icon(
                          icon,
                          size: widget.size * 0.36,
                          color: stateColor,
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
