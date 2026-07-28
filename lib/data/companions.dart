/// "Good neighbours" — companion planting suggestions. The crop data doesn't
/// carry this yet, so this is a small curated prototype map (common, well-known
/// pairings). Returns crop slugs; unknown crops get an empty list and the UI
/// shows a graceful placeholder.
library;

const _companions = <String, List<String>>{
  'tomato': ['basil', 'carrot', 'chives', 'lettuce'],
  'basil': ['tomato', 'pepper'],
  'carrot': ['leek', 'lettuce', 'onion', 'radish'],
  'lettuce': ['carrot', 'radish', 'strawberry', 'chives'],
  'cucumber': ['dill', 'pea', 'radish', 'sweetcorn'],
  'courgette': ['french-bean', 'sweetcorn'],
  'pepper': ['basil', 'onion'],
  'cabbage': ['dill', 'onion', 'beetroot'],
  'onion': ['carrot', 'beetroot', 'lettuce'],
  'strawberry': ['lettuce', 'spinach', 'chives'],
  'pea': ['carrot', 'cucumber', 'radish'],
  'french-bean': ['courgette', 'sweetcorn', 'cucumber'],
  'spinach': ['strawberry', 'pea'],
  'radish': ['carrot', 'cucumber', 'lettuce', 'pea'],
  'beetroot': ['onion', 'cabbage'],
};

List<String> companionsOf(String slug) => _companions[slug] ?? const [];

/// "Bad neighbours" — antagonist pairings that compete or attract shared pests
/// (GrowIt shows these alongside good neighbours). Curated prototype data.
const _antagonists = <String, List<String>>{
  'tomato': ['potato', 'cabbage', 'french-bean'],
  'potato': ['tomato', 'cucumber', 'pumpkin'],
  'carrot': ['dill', 'parsnip'],
  'dill': ['carrot', 'tomato'],
  'onion': ['pea', 'french-bean'],
  'pea': ['onion', 'garlic', 'shallot'],
  'french-bean': ['onion', 'garlic', 'tomato'],
  'cucumber': ['potato', 'sage'],
  'cabbage': ['tomato', 'strawberry'],
  'strawberry': ['cabbage', 'broccoli'],
  'lettuce': ['broccoli'],
  'fennel': ['tomato', 'bean'],
};

List<String> antagonistsOf(String slug) => _antagonists[slug] ?? const [];
