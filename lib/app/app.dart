import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/navigation/main_tabs.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/mock_auth_repository.dart';
import '../features/auth/data/api_auth_repository.dart';
import '../features/auth/data/models/link_models.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/ranking/data/ranking_repository.dart';
import '../features/ranking/presentation/ranking_screen.dart';
import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../core/notifications/notification_service.dart';
import '../features/training/data/lesson_repository.dart';
import '../features/training/presentation/lesson_screen.dart';
import '../features/training/presentation/notification_practice_screen.dart';
import '../features/training/data/training_repository.dart';
import '../features/training/presentation/training_screen.dart';
import '../features/training/presentation/training_lesson_screen.dart';

class PhishWardenApp extends StatefulWidget {
  const PhishWardenApp({
    super.key,
    this.repository,
    this.apiClient,
    this.notifications,
    this.lessons,
  });
  final AuthRepository? repository;
  final ApiClient? apiClient;
  final NotificationService? notifications;
  final LessonRepository? lessons;

  @override
  State<PhishWardenApp> createState() => _PhishWardenAppState();
}

class _PhishWardenAppState extends State<PhishWardenApp> {
  late final AuthRepository _repository;
  late final ApiClient _api;
  late final NotificationService _notifications;
  late final LessonRepository _lessons;
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _themeMode = ValueNotifier(ThemeMode.system);
  final _trainingRefresh = ValueNotifier(0);
  final _profileRequest = ValueNotifier(0);
  TrainingRepository? _training;
  int? _pendingTrainingId;

  @override
  void initState() {
    super.initState();
    // La ejecución normal usa NestJS. Los tests pueden inyectar un mock.
    _api = widget.apiClient ?? ApiClient(baseUrl: ApiConfig.baseUrl);
    _repository = widget.repository ?? ApiAuthRepository(_api);
    _notifications = widget.notifications ?? NotificationService();
    _lessons = widget.lessons ?? LocalLessonRepository();
    _notifications.pendingLesson.addListener(_openPendingLesson);
    _openPendingLesson();
  }

  void _openPendingLesson() {
    final id = _notifications.pendingLesson.value;
    if (id == null || id.isEmpty) return;
    _notifications.pendingLesson.value = null;
    final trainingId = int.tryParse(id);
    if (trainingId != null && trainingId > 0) {
      _pendingTrainingId = trainingId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _training != null) {
          _pendingTrainingId = null;
          _openTrainingLesson(trainingId);
        }
      });
      WidgetsBinding.instance.ensureVisualUpdate();
      return;
    }
    // MaterialApp debe haber construido su Navigator antes de abrir la ruta.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openLesson(id);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _openLesson(String id) => _navigatorKey.currentState?.push(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: '/lesson/$id'),
      builder: (_) => LessonScreen(lessonId: id, repository: _lessons),
    ),
  );

  void _openAccess(LinkResult result) {
    final navigator = _navigatorKey.currentState!;
    if (result.isDemo) {
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => NotificationPracticeScreen(
            service: _notifications,
            onProfile: () => navigator.maybePop(),
          ),
        ),
      );
      return;
    }
    final training = HttpTrainingRepository(_api, result);
    _training = training;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => MainTabs(
          profileRequest: _profileRequest,
          profile: ProfileScreen(
            repository: HttpProfileRepository(_api, result),
            themeMode: _themeMode,
            onThemeChanged: (value) => _themeMode.value = value,
            onLesson: () => _openLesson(LocalLessonRepository.practiceLessonId),
            onTrainingLesson: _openTrainingLesson,
            refresh: _trainingRefresh,
            onLogout: _logout,
          ),
          training: TrainingScreen(
            repository: training,
            onLesson: _openTrainingLesson,
            refresh: _trainingRefresh,
          ),
          ranking: RankingScreen(
            repository: HttpRankingRepository(_api, result),
            refresh: _trainingRefresh,
          ),
        ),
      ),
      (_) => false,
    );
    final pending = _pendingTrainingId;
    _pendingTrainingId = null;
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _training != null) _openTrainingLesson(pending);
      });
    }
  }

  void _openTrainingLesson(int id) {
    final repository = _training;
    if (repository == null) return;
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: '/training/$id'),
        builder: (_) => TrainingLessonScreen(
          id: id,
          repository: repository,
          onEvaluated: () => _trainingRefresh.value++,
          onProfile: () {
            _profileRequest.value++;
            _navigatorKey.currentState?.popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }

  void _logout() {
    _training = null;
    _pendingTrainingId = null;
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => _welcome()),
      (_) => false,
    );
  }

  WelcomeScreen _welcome() => WelcomeScreen(
    repository: _repository,
    themeMode: _themeMode.value,
    onThemeChanged: (value) => _themeMode.value = value,
    onLinked: _openAccess,
    isDemo: _repository is MockAuthRepository,
  );

  @override
  void dispose() {
    _notifications.pendingLesson.removeListener(_openPendingLesson);
    _api.close();
    _themeMode.dispose();
    _trainingRefresh.dispose();
    _profileRequest.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: _themeMode,
    builder: (context, mode, _) => MaterialApp(
      title: 'PhishWarden MJ',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: _welcome(),
    ),
  );
}
