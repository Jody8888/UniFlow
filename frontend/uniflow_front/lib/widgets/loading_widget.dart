import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/constants.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
    required this.message,
    this.isError = false,
    this.onRetry,
  });

  final String message;
  final bool isError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isError)
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.danger,
              )
            else
              const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.medium),
            Text(message, textAlign: TextAlign.center),
            if (isError && onRetry != null) ...[
              const SizedBox(height: AppSpacing.medium),
              FilledButton(
                onPressed: onRetry,
                child: Text(l10n.retryLoad),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
