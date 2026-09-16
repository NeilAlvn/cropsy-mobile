/// The interface's own words, in both languages.
///
/// Content (crops, problems, guides) already carries its two sides in the data;
/// this is for the chrome around it. Same shape as the mascot deck: a constant
/// per string, Dutch first, resolved with `.of(context)`.
///
/// Not every screen is here yet. A string moves in when its screen does, so the
/// file grows as the interface is translated rather than all at once.
library;

import '../timing/types.dart';

abstract final class Str {
  // ── tabs, read by the screen reader (base 8.8) ────────────────────────────
  static const tabHome = LocalizedText(nl: 'Home', en: 'Home');
  static const tabGarden = LocalizedText(nl: 'Mijn tuin', en: 'My garden');
  static const tabSeason = LocalizedText(nl: 'Seizoenspad', en: 'Season path');
  static const tabExplore = LocalizedText(nl: 'Ontdek', en: 'Explore');
  static const tabDiagnose = LocalizedText(nl: 'Diagnose', en: 'Diagnose');

  // ── home ──────────────────────────────────────────────────────────────────
  static const greeting = LocalizedText(nl: 'Hoi', en: 'Hey there');
  static LocalizedText greetingNamed(String name) =>
      LocalizedText(nl: 'Hoi, $name', en: 'Hey, $name');
  static const greetingSub = LocalizedText(
    nl: 'Dit staat er deze week in je tuin.',
    en: 'Here is your garden this week.',
  );
  static const searchCrops = LocalizedText(
    nl: 'Zoek groenten',
    en: 'Search vegetables',
  );
  static LocalizedText todaysCare(int open) =>
      LocalizedText(nl: 'Vandaag te doen ($open)', en: "Today's care ($open)");
  static LocalizedText upcomingHarvest(int n) =>
      LocalizedText(nl: 'Binnenkort oogsten ($n)', en: 'Upcoming harvest ($n)');
  static LocalizedText whatToGrow(LocalizedText month) => LocalizedText(
        nl: 'Wat te zaaien in ${month.nl}',
        en: 'What to grow in ${month.en}',
      );
  static LocalizedText checklistFor(LocalizedText month) => LocalizedText(
        nl: 'Checklist voor ${month.nl}',
        en: 'Checklist for ${month.en}',
      );
  static const unlockLifetime = LocalizedText(
    nl: 'Lifetime, één prijs, voorgoed',
    en: 'Unlock lifetime, one price, forever',
  );
  static const startStreak = LocalizedText(
    nl: 'Begin vandaag een reeks',
    en: 'Start a streak today',
  );
  static LocalizedText streakDays(int days) => LocalizedText(
        nl: '$days ${days == 1 ? 'dag' : 'dagen'} op rij',
        en: '$days-day streak',
      );

  // ── the season path ───────────────────────────────────────────────────────
  static const season = LocalizedText(nl: 'Seizoen', en: 'Season');
  static LocalizedText yearInGarden(int year) =>
      LocalizedText(nl: '$year in jouw tuin', en: '$year in your garden');
  static const today = LocalizedText(nl: 'Vandaag', en: 'Today');
  static const youAreHere = LocalizedText(nl: 'Hier ben je', en: 'You are here');
  static LocalizedText cropsSuitMonth(int n) =>
      LocalizedText(nl: '$n gewassen passen', en: '$n crops suit it');
  static LocalizedText cropsCanGoIn(int n) => LocalizedText(
        nl: 'Er kunnen nog $n gewassen in',
        en: '$n crops can still go in',
      );
  static LocalizedText nothingPlanned(LocalizedText month) => LocalizedText(
        nl: 'Nog niets gepland voor ${month.nl}',
        en: 'Nothing planned for ${month.en}',
      );
  static LocalizedText stillSowable(LocalizedText month) => LocalizedText(
        nl: 'Nog te zaaien in ${month.nl}',
        en: 'Still sowable in ${month.en}',
      );
  static LocalizedText openAndDone(int open, int done) => LocalizedText(
        nl: '$open nu open · $done gedaan',
        en: '$open open now · $done done',
      );
  static LocalizedText doneNothingOpen(int done) => LocalizedText(
        nl: '$done gedaan · niets open vandaag',
        en: '$done done · nothing open today',
      );

  // ── the path's own stops ──────────────────────────────────────────────────
  static LocalizedText sowCrop(LocalizedText crop) =>
      LocalizedText(nl: '${crop.nl} zaaien', en: 'Sow ${crop.en}');
  static LocalizedText harvestCrop(LocalizedText crop) =>
      LocalizedText(nl: '${crop.nl} oogsten', en: 'Harvest ${crop.en}');
  static LocalizedText followOn(LocalizedText crop) => LocalizedText(
        nl: 'Daarna: ${crop.nl}',
        en: 'Follow on: ${crop.en}',
      );
  /// "Tomaat bijmesten" reads right in Dutch, "Feed Tomato" in English, so the
  /// two languages put the crop on different sides of the verb.
  static LocalizedText stepOnCrop(LocalizedText step, LocalizedText crop) =>
      LocalizedText(nl: '${crop.nl} ${step.nl.toLowerCase()}', en: '${step.en} ${crop.en}');

  static const ijsheiligen = LocalizedText(nl: 'IJsheiligen', en: 'IJsheiligen');
  static const ijsheiligenSub = LocalizedText(
    nl: 'Vorstgevoelige gewassen blijven tot 15 mei binnen',
    en: 'Tender crops stay in until 15 May',
  );
  static const lastFrost = LocalizedText(
    nl: 'Laatste vorst, gemiddeld',
    en: 'Last frost, on average',
  );
  static const lastFrostSub = LocalizedText(
    nl: 'Daarna mogen vorstgevoelige gewassen naar buiten',
    en: 'After this, tender crops can go out',
  );
  static const firstFrost = LocalizedText(
    nl: 'Eerste vorst, gemiddeld',
    en: 'First frost, on average',
  );
  static const firstFrostSub = LocalizedText(
    nl: 'Haal vorstgevoelige gewassen hiervoor binnen',
    en: 'Bring tender crops in before this',
  );
  static const orderSeed = LocalizedText(nl: 'Bestel je zaad', en: 'Order your seed');
  static LocalizedText cropsOnList(int n) =>
      LocalizedText(nl: '$n gewassen op je lijst', en: '$n crops on your list');
  static const monthPhoto = LocalizedText(
    nl: 'Maak de foto van deze maand',
    en: "Snap this month's photo",
  );
  static const seasonInPictures = LocalizedText(
    nl: 'Je seizoen, in beeld',
    en: 'Your season, in pictures',
  );
  static const seasonTally = LocalizedText(nl: 'Seizoensoogst', en: 'Season tally');
  static LocalizedText tallySoFar(int euros, String kilos) => LocalizedText(
        nl: '€$euros en $kilos kg tot nu toe',
        en: '€$euros and $kilos kg so far',
      );
  static const tallyEmpty = LocalizedText(
    nl: 'Log een oogst en het telt hier op',
    en: 'Log a harvest and it adds up here',
  );
  static LocalizedText recapTitle(int year) =>
      LocalizedText(nl: 'Jouw $year, op één kaart', en: 'Your $year, in one card');
  static const recapSub = LocalizedText(
    nl: 'Wat je teelde, plukte en bespaarde',
    en: 'What you grew, picked and saved',
  );
  static LocalizedText recapPicked(int euros) =>
      LocalizedText(nl: '€$euros geplukt tot nu toe', en: '€$euros picked so far');
  static const plantsGrown = LocalizedText(nl: 'Planten geteeld', en: 'Plants grown');
  static const picked = LocalizedText(nl: 'Geoogst', en: 'Picked');
  static const saved = LocalizedText(nl: 'Bespaard', en: 'Saved');

  // ── the weather, when it moves something ──────────────────────────────────
  static const rainDidIt = LocalizedText(
    nl: 'De regen deed het water geven',
    en: 'Rain did the watering',
  );
  static const rainDidItSub = LocalizedText(
    nl: 'Overgeslagen, je reeks telt door',
    en: 'Skipped for you, the streak still counts',
  );
  static const heatComing = LocalizedText(nl: 'Hitte op komst', en: 'Heat on the way');
  static const heatComingSub = LocalizedText(
    nl: 'Eerder water geven dan gepland',
    en: 'Water earlier than planned',
  );
  static const soilCold = LocalizedText(
    nl: 'Bodem nog te koud',
    en: 'Soil still too cold',
  );
  static const soilColdSub = LocalizedText(
    nl: 'Zaaien wacht tot het warmer is',
    en: 'Sowing held until it warms',
  );

  // ── months, for every sentence that names one ─────────────────────────────
  static const months = <LocalizedText>[
    LocalizedText(nl: 'januari', en: 'January'),
    LocalizedText(nl: 'februari', en: 'February'),
    LocalizedText(nl: 'maart', en: 'March'),
    LocalizedText(nl: 'april', en: 'April'),
    LocalizedText(nl: 'mei', en: 'May'),
    LocalizedText(nl: 'juni', en: 'June'),
    LocalizedText(nl: 'juli', en: 'July'),
    LocalizedText(nl: 'augustus', en: 'August'),
    LocalizedText(nl: 'september', en: 'September'),
    LocalizedText(nl: 'oktober', en: 'October'),
    LocalizedText(nl: 'november', en: 'November'),
    LocalizedText(nl: 'december', en: 'December'),
  ];

  /// The month's name, capitalised for a heading. Dutch writes months in lower
  /// case inside a sentence, so the capital belongs to the caller.
  static LocalizedText month(int month1to12) => months[month1to12 - 1];

  static LocalizedText monthTitle(int month1to12) {
    final m = months[month1to12 - 1];
    String up(String s) => s[0].toUpperCase() + s.substring(1);
    return LocalizedText(nl: up(m.nl), en: m.en);
  }

  /// Three letters, for a marker on the path.
  static LocalizedText monthShort(int month1to12) {
    final m = months[month1to12 - 1];
    return LocalizedText(
      nl: m.nl.substring(0, 3).toUpperCase(),
      en: m.en.substring(0, 3).toUpperCase(),
    );
  }
}
