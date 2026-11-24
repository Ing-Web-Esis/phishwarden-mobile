import 'package:flutter/material.dart';

import 'main_bottom_nav.dart';

class MainTabs extends StatelessWidget {
  const MainTabs({
    super.key,
    required this.profile,
    required this.training,
    required this.ranking,
    this.profileRequest,
  });

  final Widget profile;
  final Widget training;
  final Widget ranking;
  final Listenable? profileRequest;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    animationDuration: const Duration(milliseconds: 240),
    child: Builder(
      builder: (context) {
        final tabs = DefaultTabController.of(context);
        return _ProfileRequestListener(
          request: profileRequest,
          onRequest: () => tabs.animateTo(MainBottomNav.profileIndex),
          child: Scaffold(
            body: TabBarView(
              children: [
                for (final page in [profile, training, ranking])
                  _RetainedTab(child: page),
              ],
            ),
            bottomNavigationBar: ListenableBuilder(
              listenable: tabs,
              builder: (context, _) => MainBottomNav(
                selectedIndex: tabs.index,
                onProfile: () => tabs.animateTo(MainBottomNav.profileIndex),
                onTraining: () => tabs.animateTo(MainBottomNav.trainingIndex),
                onRanking: () => tabs.animateTo(MainBottomNav.rankingIndex),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _ProfileRequestListener extends StatefulWidget {
  const _ProfileRequestListener({
    required this.request,
    required this.onRequest,
    required this.child,
  });
  final Listenable? request;
  final VoidCallback onRequest;
  final Widget child;
  @override
  State<_ProfileRequestListener> createState() =>
      _ProfileRequestListenerState();
}

class _ProfileRequestListenerState extends State<_ProfileRequestListener> {
  void _request() => widget.onRequest();
  @override
  void initState() {
    super.initState();
    widget.request?.addListener(_request);
  }

  @override
  void dispose() {
    widget.request?.removeListener(_request);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _RetainedTab extends StatefulWidget {
  const _RetainedTab({required this.child});
  final Widget child;

  @override
  State<_RetainedTab> createState() => _RetainedTabState();
}

class _RetainedTabState extends State<_RetainedTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
