import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/character_model.dart';
import '../../core/services/character_service.dart';

final characterServiceProvider = Provider<CharacterService>(
  (ref) => CharacterService(),
);

final charactersProvider = FutureProvider.family<List<CharacterModel>, int>((
  ref,
  bookId,
) {
  return ref.read(characterServiceProvider).getCharacters(bookId);
});
