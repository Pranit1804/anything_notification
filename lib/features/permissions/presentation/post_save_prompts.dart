import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n_context.dart';
import 'permissions_cubit.dart';

/// What to ask for right after a reminder is saved: the notification
/// permission if it is missing, and, once, a short explanation of why exact
/// alarms matter. Asking in context, not at launch, is what makes people say
/// yes. Used by both the editor and quick-add.
Future<void> askPermissionsAfterSave(BuildContext context) async {
  final permissions = context.read<PermissionsCubit>();
  final l10n = context.l10n;

  await permissions.ensureNotifications();
  if (!context.mounted) return;
  if (!await permissions.shouldExplainExactAlarms() || !context.mounted) return;

  final allow = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.exactDialogTitle),
      content: Text(l10n.exactDialogBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.notNow),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.permAllow),
        ),
      ],
    ),
  );
  if (allow ?? false) await permissions.requestExactAlarms();
}
