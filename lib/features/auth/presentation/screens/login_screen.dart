import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../../../../core/router/app_routes.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    final error = await ref.read(authControllerProvider.notifier).login();

    if (!mounted) return;

    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _register() {
    context.push(AppRoutes.register);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height,
          ),
          child: Column(
            children: [
              _Hero(theme: theme, cs: cs),

              // Card overlapping the hero
              Transform.translate(
                offset: const Offset(0, -44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _LoginCard(
                    loading: _loading,
                    onLogin: _login,
                    onRegister: _register,
                  ),
                ),
              ),

              // Footer
              Transform.translate(
                offset: const Offset(0, -24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Secure authentication',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SafeArea(
                top: false,
                child: Text(
                  'Travel more. Worry less. ✈️',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient header with decorative shapes, logo, title and destination chips.
class _Hero extends StatelessWidget {
  const _Hero({required this.theme, required this.cs});

  final ThemeData theme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final onHero = cs.onPrimary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.tertiary],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Stack(
        children: [
          // Decorative "sun" and "clouds"
          Positioned(
            top: -40,
            right: -30,
            child: _Circle(size: 160, color: onHero.withValues(alpha: 0.10)),
          ),
          Positioned(
            top: 90,
            left: -50,
            child: _Circle(size: 120, color: onHero.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: 60,
            right: 30,
            child: Icon(
              Icons.flight_rounded,
              size: 34,
              color: onHero.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            top: 70,
            left: 28,
            child: Icon(
              Icons.cloud_rounded,
              size: 30,
              color: onHero.withValues(alpha: 0.25),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 80),
              child: Column(
                children: [
                  Image.asset(
                    'assets/icon/app_icon_foreground.png',
                    width: 160,
                    height: 160,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tour Explorer',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: onHero,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Discover amazing places and\ncreate unforgettable journeys.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: onHero.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _Chip(icon: Icons.beach_access_rounded, label: 'Beaches'),
                      _Chip(icon: Icons.terrain_rounded, label: 'Mountains'),
                      _Chip(
                        icon: Icons.temple_buddhist_rounded,
                        label: 'Culture',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final onHero = Theme.of(context).colorScheme.onPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: onHero.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: onHero.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: onHero),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: onHero,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.loading,
    required this.onLogin,
    required this.onRegister,
  });

  final bool loading;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Ready for your next adventure?',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Login to continue your journey',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 20),

          // Trip stats strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _Stat(
                  icon: Icons.place_rounded,
                  value: '500+',
                  label: 'Places',
                ),
                _divider(cs),
                _Stat(icon: Icons.map_rounded, value: '120', label: 'Tours'),
                _divider(cs),
                _Stat(
                  icon: Icons.groups_rounded,
                  value: '10k',
                  label: 'Travelers',
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: loading ? null : onLogin,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: loading
                  ? const SizedBox.shrink()
                  : const Icon(Icons.flight_takeoff_rounded),
              label: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text(
                      'Start Exploring',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(child: Divider(color: cs.outlineVariant)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'New here?',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(child: Divider(color: cs.outlineVariant)),
            ],
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: loading ? null : onRegister,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text(
                'Create an account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme cs) =>
      Container(width: 1, height: 32, color: cs.outlineVariant);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
