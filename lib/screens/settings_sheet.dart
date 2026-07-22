import 'package:flutter/material.dart';

import '../app.dart';
import '../services/audio_service.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
import 'webview_screen.dart';

Future<void> showSettingsSheet(BuildContext context) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => const _SettingsDialog(),
  );
}

class _SettingsDialog extends StatelessWidget {
  const _SettingsDialog();

  @override
  Widget build(BuildContext context) {
    final state = GameState.instance;
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GlassPanel(
              color: AppColors.waterDeep.withValues(alpha: 0.9),
              child: ListenableBuilder(
                listenable: state,
                builder: (context, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text('Settings', style: AppText.title(26)),
                        const Spacer(),
                        CircleIconButton(
                          icon: Icons.close,
                          size: 40,
                          onTap: () {
                            AudioService.instance.playSfx(AudioService.click);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _toggle(
                      label: 'Music',
                      icon: Icons.music_note,
                      value: state.musicOn,
                      onChanged: (_) => state.toggleMusic(),
                    ),
                    const SizedBox(height: 10),
                    _toggle(
                      label: 'Sound Effects',
                      icon: Icons.volume_up,
                      value: state.soundOn,
                      onChanged: (_) => state.toggleSound(),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: GradientButton(
                            label: 'Privacy',
                            fontSize: 16,
                            gradient: AppColors.blueButton,
                            onTap: () {
                              // Capture the navigator before popping this dialog,
                              // otherwise the (now unmounted) context can't push.
                              final nav = Navigator.of(context);
                              AudioService.instance.playSfx(AudioService.click);
                              nav.pop();
                              nav.push(fadeSlideRoute(const WebViewScreen.privacy()));
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GradientButton(
                            label: 'Support',
                            fontSize: 16,
                            gradient: AppColors.blueButton,
                            onTap: () {
                              final nav = Navigator.of(context);
                              AudioService.instance.playSfx(AudioService.click);
                              nav.pop();
                              nav.push(fadeSlideRoute(const WebViewScreen.support()));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GradientButton(
                      label: 'Reset Progress',
                      icon: Icons.restart_alt,
                      fontSize: 16,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF6C4D), Color(0xFFC0392B)],
                      ),
                      onTap: () => _confirmReset(context, state),
                    ),
                    const SizedBox(height: 10),
                    Text('Wingwhirl Run v1.0 · Offline',
                        style: AppText.bodyStyle(12, color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggle({
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Text(label, style: AppText.heavy(18)),
          const Spacer(),
          Switch(
            value: value,
            activeThumbColor: AppColors.gold,
            onChanged: (v) {
              AudioService.instance.playSfx(AudioService.click);
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, GameState state) {
    AudioService.instance.playSfx(AudioService.click);
    showDialog(
      context: context,
      builder: (_) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassPanel(
            color: AppColors.waterDeep.withValues(alpha: 0.95),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Reset all progress?', style: AppText.title(22)),
                const SizedBox(height: 8),
                Text(
                  'This deletes your coins, collection and upgrades.',
                  textAlign: TextAlign.center,
                  style: AppText.bodyStyle(15, color: Colors.white),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        label: 'Cancel',
                        fontSize: 16,
                        gradient: AppColors.blueButton,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GradientButton(
                        label: 'Reset',
                        fontSize: 16,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF6C4D), Color(0xFFC0392B)],
                        ),
                        onTap: () async {
                          // Capture the navigator once; it stays valid across
                          // both pops (confirm dialog + settings dialog).
                          final nav = Navigator.of(context);
                          await state.resetProgress();
                          nav.pop();
                          nav.pop();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
