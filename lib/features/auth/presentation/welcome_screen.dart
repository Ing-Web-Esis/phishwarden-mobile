import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';
import '../data/models/link_models.dart';
import 'welcome_view_model.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.repository,
    required this.themeMode,
    required this.onThemeChanged,
    this.onLinked,
    this.isDemo = false,
  });
  final AuthRepository repository;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<LinkResult>? onLinked;
  final bool isDemo;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _email = TextEditingController();
  late final WelcomeViewModel _model;

  @override
  void initState() {
    super.initState();
    _model = WelcomeViewModel(widget.repository);
  }

  @override
  void dispose() {
    _code.dispose();
    _email.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_model.isLoading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final result = await _model.submit(_code.text, _email.text);
    if (!mounted || result == null) return;
    if (!result.isDemo) {
      widget.onLinked?.call(result);
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.verified_user_outlined, size: 36),
        title: Text(
          result.isDemo ? '¡Prueba completada!' : 'Solicitud procesada',
        ),
        content: Text(
          result.isDemo
              ? 'El formulario funciona correctamente.\n\nSala / empresa: ${result.companyCode}\nCorreo: ${result.email}\n\nEsta es una simulación: tu dispositivo todavía no está vinculado a un servidor.'
              : 'La solicitud se ha procesado. Continúa con la verificación indicada por tu organización.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
    if (mounted) widget.onLinked?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ListenableBuilder(
                listenable: _model,
                builder: (context, _) => Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TU ALIADO DIGITAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: .7,
                                    color: dark ? AppTheme.gold : AppTheme.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'PhishWarden MJ',
                                  style: theme.textTheme.titleLarge,
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<ThemeMode>(
                            tooltip: 'Cambiar apariencia',
                            initialValue: widget.themeMode,
                            onSelected: widget.onThemeChanged,
                            icon: Icon(
                              dark
                                  ? Icons.dark_mode_outlined
                                  : Icons.light_mode_outlined,
                              size: 21,
                            ),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: ThemeMode.light,
                                child: Text('Claro'),
                              ),
                              PopupMenuItem(
                                value: ThemeMode.dark,
                                child: Text('Oscuro'),
                              ),
                              PopupMenuItem(
                                value: ThemeMode.system,
                                child: Text('Sistema'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      const _ShieldIllustration(),
                      const SizedBox(height: 24),
                      Text(
                        'Más confianza.\nMenos engaños.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aprende a reconocer amenazas en solo\n1–2 minutos, a tu ritmo.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _FieldLabel(text: 'Código de Sala / Empresa'),
                      const SizedBox(height: 7),
                      TextFormField(
                        key: const Key('companyCode'),
                        controller: _code,
                        enabled: !_model.isLoading,
                        validator: WelcomeViewModel.validateCode,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'Código proporcionado por tu empresa',
                          prefixIcon: Icon(Icons.apartment_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel(text: 'Correo corporativo'),
                      const SizedBox(height: 7),
                      TextFormField(
                        key: const Key('corporateEmail'),
                        controller: _email,
                        enabled: !_model.isLoading,
                        validator: WelcomeViewModel.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        enableSuggestions: false,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          hintText: 'nombre@empresa.com',
                          prefixIcon: Icon(
                            Icons.mail_outline_rounded,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '¿No tienes código? Pídelo a tu equipo de TI.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: dark ? AppTheme.gold : AppTheme.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_model.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _model.errorMessage!,
                            style: TextStyle(color: colors.error),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton(
                        key: const Key('linkButton'),
                        onPressed: _model.isLoading ? null : _submit,
                        child: _model.isLoading
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    widget.isDemo
                                        ? 'Vinculando…'
                                        : 'Ingresando…',
                                  ),
                                ],
                              )
                            : Text(
                                widget.isDemo
                                    ? 'Vincular mi dispositivo'
                                    : 'Ingresar',
                              ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 19,
                              color: dark
                                  ? AppTheme.gold
                                  : colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'En las simulaciones registramos el evento, nunca las credenciales ingresadas.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        widget.isDemo
                            ? 'Empresa y cuenta ficticias · Vista de demostración'
                            : 'Ingresa con el código y correo registrados por tu empresa.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _ShieldIllustration extends StatelessWidget {
  const _ShieldIllustration();
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Center(
        child: SizedBox(
          width: 208,
          height: 144,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surfaceContainerHighest,
                ),
              ),
              Container(
                width: 88,
                height: 104,
                decoration: BoxDecoration(
                  color: AppTheme.gold,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  size: 53,
                  color: AppTheme.ink,
                ),
              ),
              Positioned(
                right: 4,
                top: 10,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 19,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              Positioned(
                left: 4,
                bottom: 12,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.outline),
                  ),
                  child: Icon(
                    Icons.mail_outline_rounded,
                    size: 21,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.gold
                        : AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
