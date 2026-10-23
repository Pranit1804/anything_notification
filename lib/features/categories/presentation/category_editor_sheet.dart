import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n_context.dart';
import '../domain/category.dart';
import '../domain/category_options.dart';
import 'categories_cubit.dart';
import 'category_visuals.dart';

/// Creates a category, or edits [existing]. Returns the saved category, or
/// null when the sheet was dismissed (or the category was deleted).
Future<Category?> showCategoryEditor(
  BuildContext context, {
  Category? existing,
}) {
  final cubit = context.read<CategoriesCubit>();
  return showModalBottomSheet<Category>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _CategoryEditor(existing: existing),
    ),
  );
}

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({required this.existing});

  final Category? existing;

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  late final TextEditingController _name;
  late int _color;
  late String _icon;
  bool _nameMissing = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _color = existing?.colorValue ?? categoryColors.first;
    _icon = existing?.iconKey ?? categoryIconKeys.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameMissing = true);
      return;
    }
    setState(() => _busy = true);
    final saved = await context.read<CategoriesCubit>().save(
      CategoryDraft(name: name, colorValue: _color, iconKey: _icon),
      existing: widget.existing,
    );
    if (mounted) Navigator.pop(context, saved);
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final category = widget.existing!;
    final cubit = context.read<CategoriesCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.categoryDeleteTitle(category.name)),
        content: Text(l10n.categoryDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await cubit.delete(category);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tones = categoryTones(_color, theme.brightness);
    final isNew = widget.existing == null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isNew ? l10n.categoryNewTitle : l10n.categoryEditTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CategoryAvatar(colorValue: _color, iconKey: _icon),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _name,
                    autofocus: isNew,
                    maxLength: 24,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: l10n.categoryNameHint,
                      errorText: _nameMissing
                          ? l10n.categoryNameRequired
                          : null,
                      counterText: '',
                    ),
                    onChanged: (_) {
                      if (_nameMissing) setState(() => _nameMissing = false);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(l10n.categoryColorLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final color in categoryColors)
                  Semantics(
                    button: true,
                    selected: color == _color,
                    child: InkResponse(
                      onTap: () => setState(() => _color = color),
                      radius: 26,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(color),
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.square(
                          dimension: 40,
                          child: color == _color
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(l10n.categoryIconLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final key in categoryIconKeys)
                  Semantics(
                    button: true,
                    selected: key == _icon,
                    label: key,
                    child: Material(
                      color: key == _icon
                          ? tones.container
                          : theme.colorScheme.surfaceContainerHigh,
                      shape: CircleBorder(
                        side: key == _icon
                            ? BorderSide(color: tones.onContainer, width: 2)
                            : BorderSide.none,
                      ),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _icon = key),
                        child: SizedBox.square(
                          dimension: 48,
                          child: Icon(
                            categoryIcon(key),
                            color: key == _icon
                                ? tones.onContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (!isNew)
                  TextButton.icon(
                    onPressed: _busy ? null : _delete,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(l10n.categoryDelete),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: Text(l10n.editorSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
