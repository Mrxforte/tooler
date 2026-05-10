import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/connectivity_service.dart';

/// Wraps any screen and shows connectivity status banners.
///
/// Performance note: the per-second countdown is isolated inside
/// [_AutoRefreshCountdown] so only that single Text widget rebuilds
/// every second — the rest of the banner and all screen content stay stable.
class OfflineBanner extends StatefulWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  ConnectivityService? _connectivity;
  bool _wasOnline = true;
  bool _showOnlineNotice = false;
  Timer? _onlineNoticeTimer;

  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _connectivity = context.read<ConnectivityService>();
      _wasOnline = _connectivity!.isOnline;
      _connectivity!.addListener(_onConnectivityChanged);
    });
  }

  void _onConnectivityChanged() {
    if (!mounted) return;
    final isOnline = _connectivity!.isOnline;

    if (isOnline && !_wasOnline) {
      setState(() => _showOnlineNotice = true);
      _slideCtrl.forward(from: 0);
      _onlineNoticeTimer?.cancel();
      _onlineNoticeTimer = Timer(const Duration(seconds: 6), () {
        if (!mounted) return;
        _slideCtrl.reverse().then((_) {
          if (mounted) setState(() => _showOnlineNotice = false);
        });
      });
    } else if (!isOnline) {
      _onlineNoticeTimer?.cancel();
      _slideCtrl.reverse();
      setState(() => _showOnlineNotice = false);
    }

    _wasOnline = isOnline;
  }

  @override
  void dispose() {
    _connectivity?.removeListener(_onConnectivityChanged);
    _onlineNoticeTimer?.cancel();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityService>().isOnline;

    return Column(
      children: [
        if (!isOnline) const _OfflineBadge(),
        if (isOnline && _showOnlineNotice)
          SlideTransition(
            position: _slideAnim,
            child: const _OnlineBadge(),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}

// ── Offline badge ─────────────────────────────────────────────────────────────

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFB71C1C),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Офлайн режим',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Интернет недоступен — данные из локального хранилища.\n'
                'Все изменения синхронизируются автоматически при восстановлении сети.',
                style: TextStyle(
                  color: Color(0xFFFFCDD2),
                  fontSize: 11,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Online / reconnected badge ─────────────────────────────────────────────────

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1B5E20),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_done_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Подключение восстановлено',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Данные синхронизируются. ',
                    style: TextStyle(color: Color(0xFFC8E6C9), fontSize: 11),
                  ),
                  // Only this widget rebuilds every second:
                  _AutoRefreshCountdown(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Countdown widget — rebuilds every second in isolation ─────────────────────

class _AutoRefreshCountdown extends StatefulWidget {
  const _AutoRefreshCountdown();

  @override
  State<_AutoRefreshCountdown> createState() => _AutoRefreshCountdownState();
}

class _AutoRefreshCountdownState extends State<_AutoRefreshCountdown> {
  int _seconds = 20;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _seconds = _seconds > 1 ? _seconds - 1 : 20);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Обновление через $_seconds сек.',
      style: const TextStyle(color: Color(0xFFC8E6C9), fontSize: 11),
    );
  }
}
