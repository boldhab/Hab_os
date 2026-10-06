import 'package:flutter/material.dart';
import 'global_search_modal.dart';

/// Full-screen entrypoint for Global Search accessible via `/search` route (UC-167)
class GlobalSearchScreen extends StatelessWidget {
  const GlobalSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: const SafeArea(
        child: GlobalSearchModal(),
      ),
    );
  }
}
