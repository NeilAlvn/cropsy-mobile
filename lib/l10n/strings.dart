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


  // ── browse: Explore and Grow ──────────────────────────────────────────────
  static const explore = LocalizedText(nl: 'Ontdek', en: 'Explore');
  static const findNextCrop = LocalizedText(
    nl: 'Vind je volgende gewas',
    en: 'Find your next crop',
  );
  static const identifyFromPhoto = LocalizedText(
    nl: 'Herken een plant van een foto',
    en: 'Identify a plant from a photo',
  );
  static const grow = LocalizedText(nl: 'Kweken', en: 'Grow');
  static LocalizedText searchCropCount(int n) =>
      LocalizedText(nl: 'Zoek in $n gewassen…', en: 'Search $n crops…');
  static LocalizedText results(int n) =>
      LocalizedText(nl: '$n resultaten', en: '$n results');
  static const profile = LocalizedText(nl: 'Profiel', en: 'Profile');

  // ── crop detail ───────────────────────────────────────────────────────────
  static const planToGrow = LocalizedText(nl: 'Plan het', en: 'Plan to grow');
  static const growingIt = LocalizedText(nl: 'Ik kweek het', en: 'Growing it');
  static const goodNeighbours = LocalizedText(nl: 'Goede buren', en: 'Good neighbours');
  static const badNeighbours = LocalizedText(nl: 'Slechte buren', en: 'Bad neighbours');
  static const noCompanionData = LocalizedText(
    nl: 'Nog geen buurgegevens.',
    en: 'No companion data yet.',
  );
  static const draftMatrix = LocalizedText(
    nl: 'Concept. De gecontroleerde matrix komt met de contentupdate',
    en: 'Draft. The verified matrix lands in the content update',
  );
  static LocalizedText verifiedAgainst(int n) => LocalizedText(
        nl: 'Gecontroleerd tegen $n NL-bronnen',
        en: 'Verified against $n NL sources',
      );
  static LocalizedText basedOn(String region) =>
      LocalizedText(nl: 'Op basis van: $region', en: 'Based on: $region');
  static LocalizedText potLitres(int litres) =>
      LocalizedText(nl: 'pot van $litres L', en: '$litres L pot');
  static LocalizedText harvestDays(int min, int max) => LocalizedText(
        nl: '$min–$max dagen',
        en: '$min–$max days',
      );

  // ── settings ──────────────────────────────────────────────────────────────
  static const settings = LocalizedText(nl: 'Instellingen', en: 'Settings');
  static const account = LocalizedText(nl: 'Account', en: 'Account');
  static const membership = LocalizedText(nl: 'Lidmaatschap', en: 'Membership');
  static const yourData = LocalizedText(nl: 'Jouw gegevens', en: 'Your data');
  static const appearance = LocalizedText(nl: 'Weergave', en: 'Appearance');
  static const language = LocalizedText(nl: 'Taal', en: 'Language');
  static const help = LocalizedText(nl: 'Help', en: 'Help');
  static const themeSystem = LocalizedText(nl: 'Systeem', en: 'System');
  static const themeLight = LocalizedText(nl: 'Licht', en: 'Light');
  static const themeDark = LocalizedText(nl: 'Donker', en: 'Dark');
  static const themeFollows = LocalizedText(
    nl: 'Systeem volgt je telefoon.',
    en: 'System follows your phone.',
  );
  static const langNote = LocalizedText(
    nl: 'Gewasinformatie en de mascotte spreken beide talen. De rest van de '
        'interface volgt met de contentupdate.',
    en: 'Crop content and the mascot speak both languages. The rest of the '
        'interface follows in the content update.',
  );
  static const signInBlurb = LocalizedText(
    nl: 'Log in om je tuin te bewaren en te synchroniseren. Zonder account '
        'werkt alles gewoon offline door.',
    en: 'Sign in to back up and sync your garden. Everything keeps working '
        'offline without it.',
  );
  static const email = LocalizedText(nl: 'E-mail', en: 'E-mail');
  static const sendLink = LocalizedText(
    nl: 'Stuur me een inloglink',
    en: 'Send me a sign-in link',
  );
  static const checkYourMail = LocalizedText(
    nl: 'Kijk in je mail. De link logt je in.',
    en: 'Check your mail. The link signs you in.',
  );
  static const passwordOptional = LocalizedText(
    nl: 'Wachtwoord (optioneel)',
    en: 'Password (optional)',
  );
  static const signIn = LocalizedText(nl: 'Inloggen', en: 'Sign in');
  static const createAccount = LocalizedText(nl: 'Account maken', en: 'Create account');
  static const accountCreated = LocalizedText(
    nl: 'Account aangemaakt. Bevestig via de mail die we stuurden.',
    en: 'Account created. Confirm via the mail we sent.',
  );
  static const signedIn = LocalizedText(nl: 'Ingelogd', en: 'Signed in');
  static const syncNow = LocalizedText(nl: 'Sync nu', en: 'Sync now');
  static const signOut = LocalizedText(nl: 'Uitloggen', en: 'Sign out');
  static const syncing = LocalizedText(nl: 'Synchroniseren…', en: 'Syncing…');
  static const notSyncedYet = LocalizedText(
    nl: 'Nog niet gesynchroniseerd.',
    en: 'Not synced yet.',
  );
  static LocalizedText lastSync(String time) =>
      LocalizedText(nl: 'Laatste sync $time', en: 'Last sync $time');
  static const someTablesFailed = LocalizedText(
    nl: ' · een deel is mislukt',
    en: ' · some tables failed',
  );
  static const alreadyInStep = LocalizedText(
    nl: 'Alles liep al gelijk.',
    en: 'Everything was already in step.',
  );
  static const deleteAccount = LocalizedText(nl: 'Account verwijderen', en: 'Delete account');
  static const deleteAccountAsk = LocalizedText(
    nl: 'Account verwijderen?',
    en: 'Delete account?',
  );
  static const deleteAccountBody = LocalizedText(
    nl: 'Verwijdert je account en elke gesynchroniseerde tuin, plant en log. '
        'Dit kan niet ongedaan worden gemaakt.',
    en: 'Removes your account and every synced garden, plant and log. This '
        'cannot be undone.',
  );
  static const deleted = LocalizedText(
    nl: 'Account verwijderd. Je lokale gegevens blijven op deze telefoon.',
    en: 'Account deleted. Your local data stays on this phone.',
  );
  static const cancel = LocalizedText(nl: 'Annuleren', en: 'Cancel');
  static const delete = LocalizedText(nl: 'Verwijderen', en: 'Delete');
  static const exportData = LocalizedText(
    nl: 'Exporteer mijn data (JSON)',
    en: 'Export my data (JSON)',
  );
  static const exportBlurb = LocalizedText(
    nl: 'Kopieert alles naar het klembord.',
    en: 'Copies everything to the clipboard.',
  );
  static const copied = LocalizedText(
    nl: 'Gekopieerd naar het klembord.',
    en: 'Copied to clipboard.',
  );
  static const seePlans = LocalizedText(nl: 'Bekijk plannen', en: 'See plans');
  static const managePlan = LocalizedText(nl: 'Beheer plan', en: 'Manage plan');
  static const restore = LocalizedText(nl: 'Herstellen', en: 'Restore');
  static const checkedWithStore = LocalizedText(
    nl: 'Gecontroleerd bij de store.',
    en: 'Checked with the store.',
  );
  static const syncUnavailable = LocalizedText(
    nl: 'Synchroniseren zit niet in deze build.',
    en: 'Sync is not available in this build.',
  );
  static const planFree = LocalizedText(nl: 'Gratis', en: 'Free');
  static const planLifetime = LocalizedText(nl: 'Lifetime', en: 'Lifetime');
  static const planYearly = LocalizedText(nl: 'Jaarlijks', en: 'Yearly');
  static const lifetimeNothingToCancel = LocalizedText(
    nl: 'Lifetime. Niets op te zeggen.',
    en: 'Lifetime. Nothing to cancel.',
  );
  static const freeTierBlurb = LocalizedText(
    nl: '1 tuin · 6 groeiende planten · volledige tijdlijn, herinneringen en '
        'elk gewas.',
    en: '1 garden · 6 growing plants · full timeline, reminders and every crop.',
  );
  static LocalizedText cropDataVersion(String version) => LocalizedText(
        nl: 'Cropsy · gewasdata $version',
        en: 'Cropsy · crop data $version',
      );
  static LocalizedText frostDates(String region, String source) => LocalizedText(
        nl: 'Vorstdatums: $region ($source)',
        en: 'Frost dates: $region ($source)',
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
