import 'package:flutter/material.dart';

import '../core/pwa_install_controller.dart';

class PwaInstallFab extends StatefulWidget {
  const PwaInstallFab({super.key});

  @override
  State<PwaInstallFab> createState() => _PwaInstallFabState();
}

class _PwaInstallFabState extends State<PwaInstallFab> {
  final PwaInstallController _controller = PwaInstallController();
  bool _prompting = false;

  @override
  void initState() {
    super.initState();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleInstallTap() async {
    if (_prompting) {
      return;
    }

    setState(() {
      _prompting = true;
    });

    try {
      await _controller.promptInstall();
    } finally {
      if (mounted) {
        setState(() {
          _prompting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (!_controller.canInstall) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 16),
              child: FloatingActionButton.extended(
                heroTag: 'pwa-install-fab',
                onPressed: _prompting ? null : _handleInstallTap,
                icon: _prompting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_for_offline_outlined),
                label: Text(_prompting ? 'Memproses...' : 'Install App'),
              ),
            ),
          ),
        );
      },
    );
  }
}
