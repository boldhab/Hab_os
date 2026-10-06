import 'package:flutter/material.dart';
import '../screens/search/global_search_modal.dart';

/// Universal search action button to embed in any AppBar actions array (UC-167)
class AppBarSearchButton extends StatelessWidget {
  const AppBarSearchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search_rounded),
      tooltip: 'Global Search',
      onPressed: () => GlobalSearchModal.show(context),
    );
  }
}
