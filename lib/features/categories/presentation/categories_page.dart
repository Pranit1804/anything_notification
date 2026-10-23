import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n_context.dart';
import '../../../core/widgets/empty_state.dart';
import 'categories_cubit.dart';
import 'category_editor_sheet.dart';
import 'category_visuals.dart';

/// Lists the categories; tapping one edits it.
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCategoryEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.categoriesNew),
      ),
      body: BlocBuilder<CategoriesCubit, CategoriesState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(title: Text(l10n.categoriesTitle)),
              if (state.loaded && state.categories.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.label_outline_rounded,
                    title: l10n.categoriesEmptyTitle,
                    body: l10n.categoriesEmptyBody,
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: state.categories.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final category = state.categories[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          leading: CategoryAvatar(
                            colorValue: category.colorValue,
                            iconKey: category.iconKey,
                          ),
                          title: Text(
                            category.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () =>
                              showCategoryEditor(context, existing: category),
                        ),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ],
          );
        },
      ),
    );
  }
}
