import 'package:flutter/material.dart';
import 'package:maternalhealthcare/doctor_side/auth/signin_screen.dart';
import 'package:maternalhealthcare/patient_side/auth/login_page.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the global theme set in main.dart
    final theme = Theme.of(context);

    return Scaffold(
      // The background color is now automatically handled by your global theme,
      // but you can always override it if needed.
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.health_and_safety_outlined,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please select your role to continue.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 48),
                _AnimatedRoleButton(
                  title: 'I am a Patient',
                  icon: Icons.personal_injury_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PatientLoginScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _AnimatedRoleButton(
                  title: 'I am a Doctor',
                  icon: Icons.medical_services_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DoctorLoginScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedRoleButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _AnimatedRoleButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_AnimatedRoleButton> createState() => _AnimatedRoleButtonState();
}

class _AnimatedRoleButtonState extends State<_AnimatedRoleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse().then((_) {
      widget.onTap();
    });
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.secondary.withOpacity(0.6),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 28, color: theme.colorScheme.surface),
              const SizedBox(width: 12),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      theme
                          .colorScheme
                          .surface, // Uses the surface color (white) for contrast
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
