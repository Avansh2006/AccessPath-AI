import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccessSearchBar extends StatefulWidget {
  const AccessSearchBar({super.key});

  @override
  State<AccessSearchBar> createState() => _AccessSearchBarState();
}

class _AccessSearchBarState extends State<AccessSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (_controller.text != state.searchQuery) {
      _controller.text = state.searchQuery;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadii.borderRadiusMd,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: TextField(
        controller: _controller,
        onChanged: context.read<AppState>().search,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search accessible places...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            tooltip: 'Voice search',
            onPressed: () async {
              final message = await context.read<AppState>().startVoiceSearch();
              if (message != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            },
            icon: Icon(state.isListening ? Icons.mic : Icons.mic_none),
          ),
        ),
      ),
    );
  }
}
