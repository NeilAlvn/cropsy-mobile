/// Explore — themed collections (GrowIt-style discovery), tuned to our
/// container/balcony wedge. Rows of photo cards grouped by use-case.
library;

import 'package:flutter/material.dart';

import '../../data/collections.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/widgets.dart';
import '../../timing/types.dart';
import '../grow/crop_detail_screen.dart';
import '../repository_scope.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final collections = repo.collections;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Explore', style: AppText.kicker(context)),
                const SizedBox(height: 2),
                Text.rich(TextSpan(
                  style: AppText.display(context),
                  children: const [
                    TextSpan(text: 'Find your next '),
                    TextSpan(
                        text: 'crop',
                        style: TextStyle(color: AppColors.sprout)),
                  ],
                )),
              ],
            ),
          ),
          for (final c in collections) _CollectionRow(collection: c),
        ],
      ),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({required this.collection});
  final Collection collection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 2),
          child: Text(collection.title, style: AppText.heading(context)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(collection.subtitle, style: AppText.caption(context)),
        ),
        SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: collection.crops.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final Crop crop = collection.crops[i];
              return PhotoCard(
                crop: crop,
                width: 150,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CropDetailScreen(crop: crop))),
              );
            },
          ),
        ),
      ],
    );
  }
}
