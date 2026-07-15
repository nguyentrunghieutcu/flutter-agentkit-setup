import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:example/core/constants/app_spacing.dart';
import 'package:example/features/home/presentation/providers/app_info_provider.dart';
import 'package:example/features/home/presentation/widgets/architecture_card.dart';
import 'package:example/shared/widgets/app_error_view.dart';
import 'package:example/shared/widgets/app_loading_indicator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter AgentKit')),
      body: Consumer<AppInfoProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const AppLoadingIndicator();
          if (provider.error != null) {
            return AppErrorView(
              message: provider.error!,
              onRetry: provider.load,
            );
          }

          final info = provider.info;
          if (info == null) return const SizedBox.shrink();

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ArchitectureCard(
                title: info.title,
                description: info.description,
              ),
            ),
          );
        },
      ),
    );
  }
}
