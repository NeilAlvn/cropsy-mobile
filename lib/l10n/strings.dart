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
  static const tabHome = LocalizedText(nl: 'Home', en: 'Home', de: 'Home');
  static const tabGarden = LocalizedText(
    nl: 'Mijn tuin',
    en: 'My garden',
    de: 'Mein Garten',
  );
  static const tabSeason = LocalizedText(
    nl: 'Seizoenspad',
    en: 'Season path',
    de: 'Saisonpfad',
  );
  static const tabExplore = LocalizedText(
    nl: 'Ontdek',
    en: 'Explore',
    de: 'Entdecken',
  );
  static const tabDiagnose = LocalizedText(
    nl: 'Diagnose',
    en: 'Diagnose',
    de: 'Diagnose',
  );

  // ── home ──────────────────────────────────────────────────────────────────
  static const greeting = LocalizedText(
    nl: 'Hoi',
    en: 'Hey there',
    de: 'Hallo',
  );
  static LocalizedText greetingNamed(String name) =>
      LocalizedText(nl: 'Hoi, $name', en: 'Hey, $name', de: 'Hallo, $name');
  static const greetingSub = LocalizedText(
    nl: 'Dit staat er deze week in je tuin.',
    en: 'Here is your garden this week.',
    de: 'Das ist dein Garten diese Woche.',
  );
  static const searchCrops = LocalizedText(
    nl: 'Zoek groenten',
    en: 'Search vegetables',
    de: 'Gemüse suchen',
  );
  static LocalizedText todaysCare(int open) => LocalizedText(
    nl: 'Vandaag te doen ($open)',
    en: "Today's care ($open)",
    de: 'Heute zu tun ($open)',
  );
  static LocalizedText upcomingHarvest(int n) => LocalizedText(
    nl: 'Binnenkort oogsten ($n)',
    en: 'Upcoming harvest ($n)',
    de: 'Bald ernten ($n)',
  );
  static LocalizedText whatToGrow(LocalizedText month) => LocalizedText(
    nl: 'Wat te zaaien in ${month.nl}',
    en: 'What to grow in ${month.en}',
    de: 'Was anbauen im ${month.pick('de')}',
  );
  static LocalizedText checklistFor(LocalizedText month) => LocalizedText(
    nl: 'Checklist voor ${month.nl}',
    en: 'Checklist for ${month.en}',
    de: 'Checkliste für ${month.pick('de')}',
  );
  static const unlockLifetime = LocalizedText(
    nl: 'Levenslang, één prijs, voorgoed',
    en: 'Unlock lifetime, one price, forever',
    de: 'Lebenslang freischalten, ein Preis, für immer',
  );
  static const startStreak = LocalizedText(
    nl: 'Begin vandaag een reeks',
    en: 'Start a streak today',
    de: 'Starte heute eine Serie',
  );
  static LocalizedText streakDays(int days) => LocalizedText(
    nl: '$days ${days == 1 ? 'dag' : 'dagen'} op rij',
    en: '$days-day streak',
    de: '$days ${days == 1 ? 'Tag' : 'Tage'} in Folge',
  );

  // ── the season path ───────────────────────────────────────────────────────
  static const season = LocalizedText(
    nl: 'Seizoen',
    en: 'Season',
    de: 'Saison',
  );
  static LocalizedText yearInGarden(int year) => LocalizedText(
    nl: '$year in jouw tuin',
    en: '$year in your garden',
    de: '$year in deinem Garten',
  );
  static const today = LocalizedText(nl: 'Vandaag', en: 'Today', de: 'Heute');
  static const tomorrow = LocalizedText(
    nl: 'Morgen',
    en: 'Tomorrow',
    de: 'Morgen',
  );
  static LocalizedText stepPlannedOn(LocalizedText step, String day) =>
      LocalizedText(
        nl: '${step.nl} · gepland $day',
        en: '${step.en} · planned $day',
        de: '${step.pick('de')} · geplant für $day',
      );
  static const nothingToDoToday = LocalizedText(
    nl: 'Niets te doen vandaag. Geniet ervan.',
    en: 'Nothing to do today. Enjoy it.',
    de: 'Heute nichts zu tun. Genieß es.',
  );
  static LocalizedText thingsToDoToday(int n) => LocalizedText(
    nl: n == 1 ? 'Eén ding te doen vandaag.' : '$n dingen te doen vandaag.',
    en: n == 1 ? '1 thing to do today.' : '$n things to do today.',
    de: n == 1 ? 'Heute ist 1 Sache zu tun.' : 'Heute sind $n Sachen zu tun.',
  );
  static LocalizedText removeKeepsYourHarvests(String name) => LocalizedText(
    nl:
        'Dit haalt $name uit je tuin. Oogsten die je al logde blijven in '
        'je seizoensgeschiedenis staan.',
    en:
        'This takes $name out of your garden. Any harvests you already '
        'logged stay in your season history.',
    de:
        'Damit nimmst du $name aus deinem Garten. Ernten, die du schon '
        'eingetragen hast, bleiben in deinem Saisonverlauf.',
  );
  static const symptoms = LocalizedText(
    nl: 'Symptomen',
    en: 'Symptoms',
    de: 'Symptome',
  );
  static const pickSomething = LocalizedText(
    nl: 'Kies iets ',
    en: 'Pick something ',
    de: 'Wähl etwas ',
  );
  static const toGrow = LocalizedText(
    nl: 'om te telen',
    en: 'to grow',
    de: 'zum Anbauen',
  );
  static const minSoilTemp = LocalizedText(
    nl: 'Min. bodemtemperatuur',
    en: 'Min soil temp',
    de: 'Min. Bodentemp.',
  );
  static const minPotSize = LocalizedText(
    nl: 'Min. potmaat',
    en: 'Min pot size',
    de: 'Min. Topfgröße',
  );
  static const containerFriendly = LocalizedText(
    nl: 'Geschikt voor potten',
    en: 'Container-friendly',
    de: 'Topfgeeignet',
  );
  static const yes = LocalizedText(nl: 'Ja', en: 'Yes', de: 'Ja');
  static const balconySuitability = LocalizedText(
    nl: 'Geschikt voor NL-balkon',
    en: 'NL balcony suitability',
    de: 'Eignung für NL-Balkone',
  );
  static const balconyGreat = LocalizedText(
    nl: 'Prima',
    en: 'Great',
    de: 'Super',
  );
  static const balconyAfterIjsheiligen = LocalizedText(
    nl: 'Goed na de ijsheiligen',
    en: 'Good after IJsheiligen',
    de: 'Gut nach den Eisheiligen',
  );
  static const balconyNeedsBed = LocalizedText(
    nl: 'Heeft een bed nodig',
    en: 'Needs a bed',
    de: 'Braucht ein Beet',
  );
  static const moveBackToPlanning = LocalizedText(
    nl: 'Terug naar gepland',
    en: 'Move back to planning',
    de: 'Zurück in die Planung',
  );
  static const removeFromGarden = LocalizedText(
    nl: 'Uit de tuin halen',
    en: 'Remove from garden',
    de: 'Aus dem Garten entfernen',
  );
  static LocalizedText removeKeepsHarvests(String name) => LocalizedText(
    nl:
        'Dit haalt $name uit je tuin. Gelogde oogsten blijven in je '
        'seizoensgeschiedenis staan.',
    en:
        'This takes $name out of your garden. Logged harvests stay in your '
        'season history.',
    de:
        'Damit nimmst du $name aus deinem Garten. Eingetragene Ernten bleiben '
        'in deinem Saisonverlauf.',
  );
  static const tapPlanToGrow = LocalizedText(
    nl: 'Tik op "Wil ik telen" bij een gewas om het hier te zetten.',
    en: 'Tap "Plan to grow" on any crop to add it here.',
    de: 'Tippe bei einer Pflanze auf „Einplanen“, um sie hier hinzuzufügen.',
  );
  static const tapGrowingIt = LocalizedText(
    nl: 'Tik op "Staat er al" bij een gewas, of start een gepland gewas.',
    en: 'Tap "Growing it" on a crop, or start a planned one.',
    de: 'Tippe bei einer Pflanze auf „Wächst schon“ oder starte eine geplante.',
  );
  static const sowIndoors = LocalizedText(
    nl: 'Binnen zaaien',
    en: 'Sow indoors',
    de: 'Vorziehen',
  );
  static const plantOut = LocalizedText(
    nl: 'Uitplanten',
    en: 'Plant out',
    de: 'Auspflanzen',
  );
  static const sowOutdoors = LocalizedText(
    nl: 'Buiten zaaien',
    en: 'Sow outdoors',
    de: 'Draußen säen',
  );
  static const treatmentOrganicFirst = LocalizedText(
    nl: 'Aanpak (biologisch eerst)',
    en: 'Treatment (organic first)',
    de: 'Behandlung (zuerst biologisch)',
  );
  static const prevention = LocalizedText(
    nl: 'Voorkomen',
    en: 'Prevention',
    de: 'Vorbeugung',
  );
  static const lastFrostRow = LocalizedText(
    nl: 'Laatste vorst',
    en: 'Last frost',
    de: 'Letzter Frost',
  );
  static const firstFrostRow = LocalizedText(
    nl: 'Eerste vorst',
    en: 'First frost',
    de: 'Erster Frost',
  );
  static const preferredSun = LocalizedText(
    nl: 'Voorkeur zon',
    en: 'Preferred sun',
    de: 'Lichtbedarf',
  );
  static const frostTender = LocalizedText(
    nl: 'Vorstgevoelig',
    en: 'Frost tender',
    de: 'Frostempfindlich',
  );
  static const yesWaitForLastFrost = LocalizedText(
    nl: 'Ja, wacht op de laatste vorst',
    en: 'Yes, wait for last frost',
    de: 'Ja, letzten Frost abwarten',
  );
  static const no = LocalizedText(nl: 'Nee', en: 'No', de: 'Nein');

  static const empty = LocalizedText(nl: '', en: '', de: '');
  static const sow = LocalizedText(nl: 'Zaaien', en: 'Sow', de: 'Säen');
  static const startIndoors = LocalizedText(
    nl: 'Binnen starten',
    en: 'Start indoors',
    de: 'Vorziehen',
  );
  static const plantOutside = LocalizedText(
    nl: 'Buiten planten',
    en: 'Plant outside',
    de: 'Auspflanzen',
  );
  static const easyFilter = LocalizedText(
    nl: 'Makkelijk',
    en: 'Easy',
    de: 'Einfach',
  );
  static const whatIsWrongHere = LocalizedText(
    nl: 'Wat klopt hier niet?',
    en: 'What is wrong here?',
    de: 'Was stimmt hier nicht?',
  );
  static const whatWouldBeBetter = LocalizedText(
    nl: 'Wat zou dit beter maken?',
    en: 'What would make this better?',
    de: 'Was würde es besser machen?',
  );
  static const climateNormals = LocalizedText(
    nl: 'KNMI/Open-Meteo klimaatnormalen',
    en: 'KNMI/Open-Meteo climate normals',
    de: 'KNMI/Open-Meteo-Klimamittel',
  );
  static const regionalPreset = LocalizedText(
    nl: 'NL regiovoorinstelling',
    en: 'NL regional preset',
    de: 'NL-Regionalvorgabe',
  );

  /// The crop data's own sun values, said in words.
  static LocalizedText sunNeed(String value) => switch (value) {
    'full' => const LocalizedText(
      nl: 'volle zon',
      en: 'full sun',
      de: 'volle Sonne',
    ),
    'partial' => const LocalizedText(
      nl: 'halfschaduw',
      en: 'partial',
      de: 'Halbschatten',
    ),
    'shade-tolerant' => const LocalizedText(
      nl: 'verdraagt schaduw',
      en: 'shade-tolerant',
      de: 'schattenverträglich',
    ),
    _ => LocalizedText(nl: value, en: value, de: value),
  };
  static LocalizedText daysToHarvest(num min, num max) => LocalizedText(
    nl: '$min-$max dagen',
    en: '$min-$max days',
    de: '$min-$max Tage',
  );
  static const stageSprout = LocalizedText(
    nl: 'Kiem',
    en: 'Sprout',
    de: 'Keimling',
  );
  static const dayOne = LocalizedText(nl: 'Dag 1', en: 'Day 1', de: 'Tag 1');
  static LocalizedText dayRange(num from, num to) => LocalizedText(
    nl: 'Dag $from-$to',
    en: 'Day $from-$to',
    de: 'Tag $from-$to',
  );
  static const enoughRainBadge = LocalizedText(
    nl: 'Genoeg regen',
    en: 'Enough rain',
    de: 'Genug Regen',
  );
  static const heatComingBadge = LocalizedText(
    nl: 'Hitte op komst',
    en: 'Heat coming',
    de: 'Hitze kommt',
  );
  static const soilTooColdBadge = LocalizedText(
    nl: 'Grond te koud',
    en: 'Soil too cold',
    de: 'Boden zu kalt',
  );
  static const gardenKindBalcony = LocalizedText(
    nl: 'Balkon',
    en: 'Balcony',
    de: 'Balkon',
  );
  static const gardenKindGarden = LocalizedText(
    nl: 'Tuin',
    en: 'Garden',
    de: 'Garten',
  );
  static const gardenKindAllotment = LocalizedText(
    nl: 'Volkstuin',
    en: 'Allotment',
    de: 'Kleingarten',
  );
  static const contactUs = LocalizedText(
    nl: 'Contact',
    en: 'Contact us',
    de: 'Kontakt',
  );
  static const privacy = LocalizedText(
    nl: 'Privacy',
    en: 'Privacy',
    de: 'Datenschutz',
  );
  static const terms = LocalizedText(nl: 'Voorwaarden', en: 'Terms', de: 'AGB');
  static const yourHarvests = LocalizedText(
    nl: 'Jouw oogsten',
    en: 'Your harvests',
    de: 'Deine Ernten',
  );
  static const placeGround = LocalizedText(
    nl: 'In de volle grond',
    en: 'In the ground',
    de: 'Im Boden',
  );
  static const placeRaisedBed = LocalizedText(
    nl: 'Verhoogde bak',
    en: 'Raised bed',
    de: 'Hochbeet',
  );
  static const placePotOutside = LocalizedText(
    nl: 'Pot buiten',
    en: 'Pot outside',
    de: 'Topf draußen',
  );
  static const placePotInside = LocalizedText(
    nl: 'Pot binnen',
    en: 'Pot inside',
    de: 'Topf drinnen',
  );
  static const methodSowedIndoors = LocalizedText(
    nl: 'Binnen gezaaid',
    en: 'Sowed indoors',
    de: 'Vorgezogen',
  );
  static const methodSowedOutside = LocalizedText(
    nl: 'Buiten gezaaid',
    en: 'Sowed outside',
    de: 'Draußen gesät',
  );
  static const methodPlantedSeedling = LocalizedText(
    nl: 'Zaailing geplant',
    en: 'Planted a seedling',
    de: 'Jungpflanze gesetzt',
  );
  static const methodPlantedSets = LocalizedText(
    nl: 'Geplant (bollen / knollen)',
    en: 'Planted (sets / tubers)',
    de: 'Gesteckt (Zwiebeln / Knollen)',
  );
  // ── the how-tos table ─────────────────────────────────────────────────────
  static const sowDepth = LocalizedText(
    nl: 'Zaaidiepte',
    en: 'Sow depth',
    de: 'Saattiefe',
  );
  static const germination = LocalizedText(
    nl: 'Kieming',
    en: 'Germination',
    de: 'Keimung',
  );
  static const plantOutAfter = LocalizedText(
    nl: 'Uitplanten na',
    en: 'Plant out after',
    de: 'Auspflanzen nach',
  );
  static const spacing = LocalizedText(
    nl: 'Plantafstand',
    en: 'Spacing',
    de: 'Abstand',
  );
  static const perSquare = LocalizedText(
    nl: 'Per vak van 30 cm',
    en: 'Per 30 cm square',
    de: 'Pro 30-cm-Quadrat',
  );
  static const care = LocalizedText(nl: 'Verzorging', en: 'Care', de: 'Pflege');
  static const waterSmallPot = LocalizedText(
    nl: 'Water (kleine pot)',
    en: 'Water (small pot)',
    de: 'Gießen (kleiner Topf)',
  );
  static const waterInGround = LocalizedText(
    nl: 'Water (volle grond)',
    en: 'Water (in ground)',
    de: 'Gießen (im Boden)',
  );
  static const feed = LocalizedText(nl: 'Bijmesten', en: 'Feed', de: 'Düngen');
  static const perennial = LocalizedText(
    nl: 'Meerjarig',
    en: 'Perennial',
    de: 'Mehrjährig',
  );
  static const firstHarvest = LocalizedText(
    nl: 'Eerste oogst',
    en: 'First harvest',
    de: 'Erste Ernte',
  );
  static LocalizedText aboutDays(int n) =>
      LocalizedText(nl: '~$n dagen', en: '~$n days', de: '~$n Tage');
  static LocalizedText daysIndoors(int n) => LocalizedText(
    nl: '~$n dagen binnen',
    en: '~$n days indoors',
    de: '~$n Tage drinnen',
  );
  static LocalizedText everyDays(int n) => LocalizedText(
    nl: n == 1 ? 'elke dag' : 'elke $n dagen',
    en: n == 1 ? 'every 1 day' : 'every $n days',
    de: n == 1 ? 'jeden Tag' : 'alle $n Tage',
  );
  static LocalizedText everyDaysEstablished(int n) => LocalizedText(
    nl: 'elke $n dagen zodra hij aanslaat',
    en: 'every $n days once established',
    de: 'alle $n Tage, sobald sie angewachsen ist',
  );
  static const comesBackNextYear = LocalizedText(
    nl: 'komt volgend jaar terug',
    en: 'comes back next year',
    de: 'kommt nächstes Jahr wieder',
  );
  static LocalizedText daysAfterPlantOut(num min, num max) => LocalizedText(
    nl: '$min-$max dagen na het uitplanten',
    en: '$min-$max days after planting out',
    de: '$min-$max Tage nach dem Auspflanzen',
  );

  // ── onboarding chrome ─────────────────────────────────────────────────────
  static const heroKnowWhatToDo = LocalizedText(
    nl: 'Weet wat je\n',
    en: 'Know what to do\n',
    de: 'Wissen, was\n',
  );
  static const heroThisWeek = LocalizedText(
    nl: 'deze week',
    en: 'this week',
    de: 'diese Woche',
  );
  static const heroInYourGarden = LocalizedText(
    nl: ' moet doen in je tuin.',
    en: ' in your garden.',
    de: ' im Garten ansteht.',
  );
  static const heroSubtitle = LocalizedText(
    nl:
        'Plantdata en herinneringen afgestemd op het Nederlandse en Europese '
        'weer, gemaakt voor balkons en potten.',
    en:
        'Planting dates and reminders tuned to Dutch and EU weather, built for '
        'balconies and containers.',
    de: 'Pflanztermine und Erinnerungen, abgestimmt auf niederländisches und EU-Wetter, gemacht für Balkone und Töpfe.',
  );
  static const getStarted = LocalizedText(
    nl: 'Beginnen',
    en: 'Get started',
    de: 'Los geht\'s',
  );
  static const continueLabel = LocalizedText(
    nl: 'Verder',
    en: 'Continue',
    de: 'Weiter',
  );
  static const datesCheckedTitle = LocalizedText(
    nl: 'Elke datum gelegd naast Nederlandse zaaikalenders',
    en: 'Every date checked against Dutch seed calendars',
    de: 'Jedes Datum mit niederländischen Aussaatkalendern abgeglichen',
  );
  static const datesCheckedBody = LocalizedText(
    nl:
        'Elk gewas is gelegd naast minstens twee NL-bronnen, IVN, Tuinadvies, '
        'zaaitijden.nl en Groei & Bloei, voordat het bij jou komt. En als het '
        'leven ertussen komt, schuift het plan met je mee. Niets is ooit "te '
        'laat".',
    en:
        'Each crop is cross-checked against at least two NL sources, IVN, '
        'Tuinadvies, zaaitijden.nl and Groei & Bloei, before it reaches you. '
        'And when life gets in the way, the plan moves with you. Nothing is '
        'ever "overdue".',
    de: 'Jede Pflanze wird mit mindestens zwei NL-Quellen abgeglichen, IVN, Tuinadvies, zaaitijden.nl und Groei & Bloei, bevor sie bei dir ankommt. Und wenn das Leben dazwischenkommt, zieht der Plan mit. Nichts ist je „zu spät“.',
  );
  static const getToKnowTitle = LocalizedText(
    nl: 'Hoi! Even kennismaken',
    en: "Hi! Let's get to know each other",
    de: 'Hallo! Lernen wir uns kennen',
  );
  static const getToKnowBody = LocalizedText(
    nl:
        'Een paar korte vragen over je ruimte en wat je graag eet. Twee '
        'minuten, dan staat je plan klaar.',
    en:
        'A few quick questions about your space and what you like to eat. Two '
        'minutes, then your plan is ready.',
    de: 'Ein paar kurze Fragen zu deinem Platz und dazu, was du gern isst. Zwei Minuten, dann steht dein Plan.',
  );
  static const whatSpace = LocalizedText(
    nl: 'Welke ruimte heb je om te telen?',
    en: 'What space do you have to grow in?',
    de: 'Wo kannst du anbauen?',
  );
  static const experienceReassure = LocalizedText(
    nl:
        'Mooi, dan beginnen we bij het begin. Je krijgt per stap te zien wat je '
        'moet doen, en waarom.',
    en:
        "Good — then we start at the beginning. You'll get every step as it "
        'comes, and the reason behind it.',
    de: 'Gut — dann fangen wir ganz vorne an. Du bekommst jeden Schritt, wenn er dran ist, und den Grund dazu.',
  );
  static const pickAllThatApply = LocalizedText(
    nl: 'Kies alles wat past.',
    en: 'Pick all that apply.',
    de: 'Wähl alles, was passt.',
  );
  static const spaceBackyard = LocalizedText(
    nl: 'Tuin',
    en: 'Garden',
    de: 'Garten',
  );
  static const spaceBalcony = LocalizedText(
    nl: 'Balkon',
    en: 'Balcony',
    de: 'Balkon',
  );
  static const spaceIndoor = LocalizedText(
    nl: 'Binnen',
    en: 'Indoors',
    de: 'Drinnen',
  );
  static const spaceAllotment = LocalizedText(
    nl: 'Volkstuin',
    en: 'Allotment',
    de: 'Kleingarten',
  );
  static const spaceOther = LocalizedText(
    nl: 'Ergens anders',
    en: 'Somewhere else',
    de: 'Woanders',
  );
  static const howMuchSpace = LocalizedText(
    nl: 'Hoeveel ruimte?',
    en: 'How much space?',
    de: 'Wie viel Platz?',
  );
  static const howMuchSpaceSub = LocalizedText(
    nl: 'Ongeveer, het bepaalt hoeveel planten passen.',
    en: 'Roughly, it sets how many plants fit.',
    de: 'Ungefähr, das bestimmt, wie viele Pflanzen passen.',
  );
  static const howMuchSun = LocalizedText(
    nl: 'Hoeveel zon?',
    en: 'How much sun?',
    de: 'Wie viel Sonne?',
  );
  static const howMuchSunSub = LocalizedText(
    nl: 'Op een heldere dag, hoe lang staat het in de volle zon?',
    en: 'On a clear day, how long is it in direct sun?',
    de: 'Wie lange scheint an einem klaren Tag die Sonne direkt hin?',
  );
  static const sunFull = LocalizedText(
    nl: 'Volle zon (6u+)',
    en: 'Full sun (6h+)',
    de: 'Volle Sonne (6h+)',
  );
  static const sunPartial = LocalizedText(
    nl: 'Halfschaduw (3-6u)',
    en: 'Partial (3-6h)',
    de: 'Halbschatten (3-6h)',
  );
  static const sunShade = LocalizedText(
    nl: 'Schaduw (< 3u)',
    en: 'Shade (< 3h)',
    de: 'Schatten (< 3h)',
  );
  static const grownBefore = LocalizedText(
    nl: 'Eerder iets geteeld?',
    en: 'Grown anything before?',
    de: 'Schon mal etwas angebaut?',
  );
  static const grownBeforeSub = LocalizedText(
    nl: 'Zo stemmen we het advies af.',
    en: 'So we pitch the advice right.',
    de: 'Damit unsere Tipps zu dir passen.',
  );
  static const experienceNever = LocalizedText(
    nl: 'Nooit',
    en: 'Never',
    de: 'Nie',
  );
  static const experienceSome = LocalizedText(
    nl: 'Een seizoen of twee',
    en: 'A season or two',
    de: 'Ein, zwei Saisons',
  );
  static const experiencePlenty = LocalizedText(
    nl: 'Genoeg',
    en: 'Plenty',
    de: 'Viel',
  );
  static const whatDoYouEat = LocalizedText(
    nl: 'Wat eet je graag?',
    en: 'What do you like to eat?',
    de: 'Was isst du gern?',
  );
  static const foodVegetables = LocalizedText(
    nl: 'Groente',
    en: 'Vegetables',
    de: 'Gemüse',
  );
  static const foodHerbs = LocalizedText(
    nl: 'Kruiden',
    en: 'Herbs',
    de: 'Kräuter',
  );
  static const foodSalad = LocalizedText(
    nl: 'Slablad',
    en: 'Salad leaves',
    de: 'Blattsalate',
  );
  static const foodFruit = LocalizedText(nl: 'Fruit', en: 'Fruit', de: 'Obst');
  static const foodRoots = LocalizedText(
    nl: 'Wortelgroente',
    en: 'Root veg',
    de: 'Wurzelgemüse',
  );
  static const whatMattersMost = LocalizedText(
    nl: 'Wat is het belangrijkst?',
    en: "What's most important?",
    de: 'Was ist dir am wichtigsten?',
  );
  static const interestEasy = LocalizedText(
    nl: 'Makkelijk te telen',
    en: 'Easy to grow',
    de: 'Leicht anzubauen',
  );
  static const interestFast = LocalizedText(
    nl: 'Snel oogsten',
    en: 'Fast harvest',
    de: 'Schnelle Ernte',
  );
  static const interestYield = LocalizedText(
    nl: 'Veel opbrengst',
    en: 'High yield',
    de: 'Hoher Ertrag',
  );
  static const interestKids = LocalizedText(
    nl: 'Leuk met kinderen',
    en: 'Fun with kids',
    de: 'Spaß mit Kindern',
  );
  static const interestCost = LocalizedText(
    nl: 'Scheelt geld',
    en: 'Saves money',
    de: 'Spart Geld',
  );
  static const buildMyPlan = LocalizedText(
    nl: 'Bouw mijn plan',
    en: 'Build my plan',
    de: 'Plan erstellen',
  );
  static const yourLocationWord = LocalizedText(
    nl: 'jouw locatie',
    en: 'your location',
    de: 'deinen Standort',
  );
  static const planReady = LocalizedText(
    nl: 'Je plan staat klaar',
    en: 'Your plan is ready',
    de: 'Dein Plan ist fertig',
  );
  static const planBuilding = LocalizedText(
    nl: 'Je teeltplan wordt gemaakt…',
    en: 'Creating your growing plan…',
    de: 'Dein Anbauplan entsteht…',
  );
  static LocalizedText planFrostLine(
    String region,
    String last,
    String first,
  ) => LocalizedText(
    nl: 'Vorstdatums voor $region: laatste $last, eerste $first',
    en: 'Frost dates for $region: last $last, first $first',
    de: 'Frostdaten für $region: letzter $last, erster $first',
  );
  static LocalizedText planMatches(int n) => LocalizedText(
    nl: n == 1
        ? '1 gewas past deze maand in je ruimte'
        : '$n gewassen passen deze maand in je ruimte',
    en: n == 1
        ? '1 crop fits your space this month'
        : '$n crops fit your space this month',
    de: n == 1
        ? '1 Pflanze passt diesen Monat zu deinem Platz'
        : '$n Pflanzen passen diesen Monat zu deinem Platz',
  );
  static const planMatching = LocalizedText(
    nl: 'Gewassen zoeken die in je ruimte passen…',
    en: 'Matching crops to your space…',
    de: 'Pflanzen werden auf deinen Platz abgestimmt…',
  );
  static const planFirstTaskWaits = LocalizedText(
    nl: 'De eerste taak komt zodra er een venster opengaat',
    en: 'First task lands as soon as a window opens',
    de: 'Die erste Aufgabe kommt, sobald sich ein Zeitfenster öffnet',
  );
  static LocalizedText planFirstTask(String task) => LocalizedText(
    nl: 'Eerste taak: $task',
    en: 'First task: $task',
    de: 'Erste Aufgabe: $task',
  );
  static const planFindingFirstTask = LocalizedText(
    nl: 'Je eerste taak zoeken…',
    en: 'Finding your first task…',
    de: 'Erste Aufgabe wird gesucht…',
  );
  static const noLocationPickRegion = LocalizedText(
    nl: 'Geen locatie, vul een postcode in of kies hieronder een regio.',
    en: 'No location, enter a postcode or pick a region below.',
    de: 'Kein Standort. Gib eine Postleitzahl ein oder wähl unten eine Region.',
  );
  static const postcodeNotFoundPickRegion = LocalizedText(
    nl:
        'Postcode niet gevonden (1234AB), of je bent offline. Kies hieronder '
        'een regio.',
    en: 'Postcode not found (1234AB), or you are offline. Pick a region below.',
    de: 'Postleitzahl nicht gefunden (1234AB) oder du bist offline. Wähl unten eine Region.',
  );
  static LocalizedText foundFrostDates(String last, String first) =>
      LocalizedText(
        nl: 'Gevonden. Laatste vorst rond $last, eerste vorst rond $first.',
        en: 'Found it. Last frost around $last, first frost around $first.',
        de: 'Gefunden. Letzter Frost etwa $last, erster Frost etwa $first.',
      );
  static const whatToDo = LocalizedText(
    nl: 'Wat te doen ',
    en: 'What to do ',
    de: 'Was zu tun ist ',
  );
  static const inYourGarden = LocalizedText(
    nl: 'in je tuin',
    en: 'in your garden',
    de: 'in deinem Garten',
  );
  static const plotWord = LocalizedText(nl: 'tuin', en: 'plot', de: 'Garten');
  static const yourLocation = LocalizedText(
    nl: 'Jouw locatie',
    en: 'Your location',
    de: 'Dein Standort',
  );
  static LocalizedText noLocationMatch(String query) => LocalizedText(
    nl:
        'Geen match voor "$query". Probeer een stad in de buurt, een '
        'postcode (1234AB), of kies een regio.',
    en:
        'No match for "$query". Try a nearby city, a postcode (1234AB), or '
        'pick a region.',
    de:
        'Kein Treffer für „$query“. Versuch eine Stadt in der Nähe, eine '
        'Postleitzahl (1234AB) oder wähl eine Region.',
  );
  static const useCurrentLocation = LocalizedText(
    nl: 'Gebruik mijn huidige locatie',
    en: 'Use my current location',
    de: 'Aktuellen Standort nutzen',
  );
  static const detectingLocation = LocalizedText(
    nl: 'Locatie bepalen…',
    en: 'Detecting your location…',
    de: 'Standort wird ermittelt…',
  );
  static const renewsYearly = LocalizedText(
    nl:
        'Verlengt jaarlijks. Beheren of opzeggen doe je in de App Store / Play '
        'Store.',
    en: 'Renews yearly. Manage or cancel in the App Store / Play Store.',
    de: 'Verlängert sich jährlich. Verwalten oder kündigen im App Store / Play Store.',
  );
  static const couldNotDeleteAccount = LocalizedText(
    nl: 'Account verwijderen lukte niet. Probeer het later opnieuw.',
    en: 'Could not delete the account. Try again later.',
    de: 'Das Konto konnte nicht gelöscht werden. Versuch es später noch einmal.',
  );
  static const scanOpensWithBeta = LocalizedText(
    nl: 'Fotoscannen is nu niet beschikbaar. De probleemgids werkt offline.',
    en:
        'Photo scanning is not available right now. The common-problems '
        'browser works offline.',
    de: 'Foto-Scans sind gerade nicht verfügbar. Die Übersicht häufiger Probleme funktioniert offline.',
  );
  static const scanQuotaReached = LocalizedText(
    nl:
        'Dagelijkse scanlimiet bereikt. Morgen weer, of ontgrendel levenslang '
        'voor meer.',
    en:
        'Daily scan limit reached. Tomorrow again, or unlock lifetime for '
        'more.',
    de: 'Tägliches Scan-Limit erreicht. Morgen geht es weiter, oder schalte Lebenslang für mehr frei.',
  );
  static LocalizedText scanFailed(String code) => LocalizedText(
    nl: 'Scannen mislukt ($code). Probeer opnieuw.',
    en: 'Scan failed ($code). Try again.',
    de: 'Scan fehlgeschlagen ($code). Versuch es noch einmal.',
  );
  static const snapTipsIdentify = LocalizedText(
    nl: 'Fototips: één plant, een blad of bloem vult het beeld, daglicht.',
    en: 'Snap tips: one plant, a leaf or flower filling the frame, daylight.',
    de: 'Foto-Tipps: eine Pflanze, ein Blatt oder eine Blüte füllt das Bild, Tageslicht.',
  );
  static const snapTipsDiagnose = LocalizedText(
    nl:
        'Fototips: het aangetaste deel scherp en dichtbij, plus één wijdere '
        'foto als je twijfelt.',
    en:
        'Snap tips: the damaged part sharp and close, plus one wider shot if '
        'unsure.',
    de: 'Foto-Tipps: die beschädigte Stelle scharf und nah, dazu eine weitere Aufnahme, wenn du unsicher bist.',
  );
  static LocalizedText rainSkipsWatering(int mm) => LocalizedText(
    nl:
        'Er viel $mm mm in de laatste drie dagen. Water geven rond vandaag '
        'wordt overgeslagen.',
    en:
        'Rained $mm mm in the last three days. Waterings around today are '
        'skipped.',
    de:
        'In den letzten drei Tagen sind $mm mm Regen gefallen. Das Gießen '
        'rund um heute fällt aus.',
  );
  static const heatAhead = LocalizedText(
    nl:
        'Hitte op komst (30°C+). Potten drogen in een dag uit, dus water geven '
        'schuift naar voren.',
    en:
        'Heat ahead (30°C+). Containers dry out in a day, so waterings move '
        'earlier.',
    de: 'Hitze im Anmarsch (30 °C+). Töpfe trocknen an einem Tag aus, darum rückt das Gießen nach vorne.',
  );
  static const forecastCalm = LocalizedText(
    nl: 'Niets bijzonders in de verwachting. Het plan blijft staan.',
    en: 'Nothing dramatic in the forecast. The plan stands.',
    de: 'Nichts Dramatisches in der Vorhersage. Der Plan steht.',
  );
  static const youAreHere = LocalizedText(
    nl: 'Hier ben je',
    en: 'You are here',
    de: 'Du bist hier',
  );
  static LocalizedText cropsSuitMonth(int n) => LocalizedText(
    nl: '$n gewassen passen',
    en: '$n crops suit it',
    de: '$n Pflanzen passen',
  );
  static LocalizedText cropsCanGoIn(int n) => LocalizedText(
    nl: 'Er kunnen nog $n gewassen in',
    en: '$n crops can still go in',
    de: '$n Pflanzen können noch rein',
  );
  static LocalizedText nothingPlanned(LocalizedText month) => LocalizedText(
    nl: 'Nog niets gepland voor ${month.nl}',
    en: 'Nothing planned for ${month.en}',
    de: 'Nichts geplant im ${month.pick('de')}',
  );
  static LocalizedText stillSowable(LocalizedText month) => LocalizedText(
    nl: 'Nog te zaaien in ${month.nl}',
    en: 'Still sowable in ${month.en}',
    de: 'Im ${month.pick('de')} noch zu säen',
  );
  static LocalizedText openAndDone(int open, int done) => LocalizedText(
    nl: '$open nu open · $done gedaan',
    en: '$open open now · $done done',
    de: '$open jetzt offen · $done erledigt',
  );
  static LocalizedText doneNothingOpen(int done) => LocalizedText(
    nl: '$done gedaan · niets open vandaag',
    en: '$done done · nothing open today',
    de: '$done erledigt · heute nichts offen',
  );

  // ── the path's own stops ──────────────────────────────────────────────────
  static LocalizedText sowCrop(LocalizedText crop) => LocalizedText(
    nl: '${crop.nl} zaaien',
    en: 'Sow ${crop.en}',
    de: '${crop.pick('de')} säen',
  );
  static LocalizedText harvestCrop(LocalizedText crop) => LocalizedText(
    nl: '${crop.nl} oogsten',
    en: 'Harvest ${crop.en}',
    de: '${crop.pick('de')} ernten',
  );
  static LocalizedText followOn(LocalizedText crop) => LocalizedText(
    nl: 'Daarna: ${crop.nl}',
    en: 'Follow on: ${crop.en}',
    de: 'Danach: ${crop.pick('de')}',
  );

  /// "Tomaat bijmesten" reads right in Dutch, "Feed Tomato" in English, so the
  /// two languages put the crop on different sides of the verb.
  static LocalizedText stepOnCrop(LocalizedText step, LocalizedText crop) =>
      LocalizedText(
        nl: '${crop.nl} ${step.nl.toLowerCase()}',
        en: '${step.en} ${crop.en}',
        de: '${crop.pick('de')} ${step.pick('de').toLowerCase()}',
      );

  static const ijsheiligen = LocalizedText(
    nl: 'IJsheiligen',
    en: 'IJsheiligen',
    de: 'Eisheiligen',
  );
  static const ijsheiligenSub = LocalizedText(
    nl: 'Vorstgevoelige gewassen blijven tot 15 mei binnen',
    en: 'Tender crops stay in until 15 May',
    de: 'Empfindliche Pflanzen bleiben bis 15. Mai drinnen',
  );
  static const lastFrost = LocalizedText(
    nl: 'Laatste vorst, gemiddeld',
    en: 'Last frost, on average',
    de: 'Letzter Frost, im Schnitt',
  );
  static const lastFrostSub = LocalizedText(
    nl: 'Daarna mogen vorstgevoelige gewassen naar buiten',
    en: 'After this, tender crops can go out',
    de: 'Danach dürfen empfindliche Pflanzen raus',
  );
  static const firstFrost = LocalizedText(
    nl: 'Eerste vorst, gemiddeld',
    en: 'First frost, on average',
    de: 'Erster Frost, im Schnitt',
  );
  static const firstFrostSub = LocalizedText(
    nl: 'Haal vorstgevoelige gewassen hiervoor binnen',
    en: 'Bring tender crops in before this',
    de: 'Hol empfindliche Pflanzen vorher rein',
  );
  static const orderSeed = LocalizedText(
    nl: 'Bestel je zaad',
    en: 'Order your seed',
    de: 'Saatgut bestellen',
  );
  static LocalizedText cropsOnList(int n) => LocalizedText(
    nl: '$n gewassen op je lijst',
    en: '$n crops on your list',
    de: '$n Pflanzen auf deiner Liste',
  );
  static const monthPhoto = LocalizedText(
    nl: 'Maak de foto van deze maand',
    en: "Snap this month's photo",
    de: 'Mach das Foto des Monats',
  );
  static const seasonInPictures = LocalizedText(
    nl: 'Je seizoen, in beeld',
    en: 'Your season, in pictures',
    de: 'Deine Saison in Bildern',
  );
  static const seasonTally = LocalizedText(
    nl: 'Seizoensoogst',
    en: 'Season tally',
    de: 'Saisonbilanz',
  );
  static LocalizedText tallySoFar(int euros, String kilos) => LocalizedText(
    nl: '€$euros en $kilos kg tot nu toe',
    en: '€$euros and $kilos kg so far',
    de: '$euros € und $kilos kg bisher',
  );
  static const tallyEmpty = LocalizedText(
    nl: 'Log een oogst en het telt hier op',
    en: 'Log a harvest and it adds up here',
    de: 'Trag eine Ernte ein, dann summiert sie sich hier',
  );
  static LocalizedText recapTitle(int year) => LocalizedText(
    nl: 'Jouw $year, op één kaart',
    en: 'Your $year, in one card',
    de: 'Dein $year auf einer Karte',
  );
  static const recapSub = LocalizedText(
    nl: 'Wat je teelde, plukte en bespaarde',
    en: 'What you grew, picked and saved',
    de: 'Was du angebaut, geerntet und gespart hast',
  );
  static LocalizedText recapPicked(int euros) => LocalizedText(
    nl: '€$euros geplukt tot nu toe',
    en: '€$euros picked so far',
    de: '$euros € bisher geerntet',
  );
  static const plantsGrown = LocalizedText(
    nl: 'Planten geteeld',
    en: 'Plants grown',
    de: 'Angebaute Pflanzen',
  );
  static const picked = LocalizedText(
    nl: 'Geoogst',
    en: 'Picked',
    de: 'Geerntet',
  );
  static const saved = LocalizedText(
    nl: 'Bespaard',
    en: 'Saved',
    de: 'Gespart',
  );

  // ── the weather, when it moves something ──────────────────────────────────
  static const rainDidIt = LocalizedText(
    nl: 'De regen deed het water geven',
    en: 'Rain did the watering',
    de: 'Der Regen hat gegossen',
  );
  static const rainDidItSub = LocalizedText(
    nl: 'Overgeslagen, je reeks telt door',
    en: 'Skipped for you, the streak still counts',
    de: 'Für dich übersprungen, die Serie zählt trotzdem',
  );
  static const heatComing = LocalizedText(
    nl: 'Hitte op komst',
    en: 'Heat on the way',
    de: 'Hitze im Anmarsch',
  );
  static const heatComingSub = LocalizedText(
    nl: 'Eerder water geven dan gepland',
    en: 'Water earlier than planned',
    de: 'Früher gießen als geplant',
  );
  static const soilCold = LocalizedText(
    nl: 'Bodem nog te koud',
    en: 'Soil still too cold',
    de: 'Boden noch zu kalt',
  );
  static const soilColdSub = LocalizedText(
    nl: 'Zaaien wacht tot het warmer is',
    en: 'Sowing held until it warms',
    de: 'Gesät wird, sobald er wärmer ist',
  );

  // ── browse: Explore and Grow ──────────────────────────────────────────────
  static const explore = LocalizedText(
    nl: 'Ontdek',
    en: 'Explore',
    de: 'Entdecken',
  );
  static const findNextCrop = LocalizedText(
    nl: 'Vind je volgende gewas',
    en: 'Find your next crop',
    de: 'Finde deine nächste Pflanze',
  );
  static const identifyFromPhoto = LocalizedText(
    nl: 'Herken een plant van een foto',
    en: 'Identify a plant from a photo',
    de: 'Pflanze per Foto bestimmen',
  );
  static const grow = LocalizedText(nl: 'Kweken', en: 'Grow', de: 'Anbauen');
  static LocalizedText searchCropCount(int n) => LocalizedText(
    nl: 'Zoek in $n gewassen…',
    en: 'Search $n crops…',
    de: 'In $n Pflanzen suchen…',
  );
  static LocalizedText results(int n) =>
      LocalizedText(nl: '$n resultaten', en: '$n results', de: '$n Ergebnisse');
  static const profile = LocalizedText(
    nl: 'Profiel',
    en: 'Profile',
    de: 'Profil',
  );

  // ── crop detail ───────────────────────────────────────────────────────────
  static const planToGrow = LocalizedText(
    nl: 'Plan het',
    en: 'Plan to grow',
    de: 'Einplanen',
  );
  static const growingIt = LocalizedText(
    nl: 'Ik kweek het',
    en: 'Growing it',
    de: 'Wächst schon',
  );
  static const goodNeighbours = LocalizedText(
    nl: 'Goede buren',
    en: 'Good neighbours',
    de: 'Gute Nachbarn',
  );
  static const badNeighbours = LocalizedText(
    nl: 'Slechte buren',
    en: 'Bad neighbours',
    de: 'Schlechte Nachbarn',
  );
  static const noCompanionData = LocalizedText(
    nl: 'Nog geen buurgegevens.',
    en: 'No companion data yet.',
    de: 'Noch keine Nachbarschaftsdaten.',
  );
  static const draftMatrix = LocalizedText(
    nl: 'Concept. De gecontroleerde matrix komt met de contentupdate',
    en: 'Draft. The verified matrix lands in the content update',
    de: 'Entwurf. Die geprüfte Tabelle kommt mit dem Inhalts-Update',
  );
  static LocalizedText verifiedAgainst(int n) => LocalizedText(
    nl: 'Gecontroleerd tegen $n NL-bronnen',
    en: 'Verified against $n NL sources',
    de: 'Geprüft mit $n NL-Quellen',
  );
  static LocalizedText basedOn(String region) => LocalizedText(
    nl: 'Op basis van: $region',
    en: 'Based on: $region',
    de: 'Grundlage: $region',
  );
  static LocalizedText potLitres(num litres) => LocalizedText(
    nl: '$litres L pot',
    en: '$litres L pot',
    de: '$litres-L-Topf',
  );
  static LocalizedText harvestInDays(int days) => LocalizedText(
    nl: 'Oogst over $days dagen',
    en: 'Harvest in $days days',
    de: 'Ernte in $days ${days == 1 ? 'Tag' : 'Tagen'}',
  );
  static const readyToHarvest = LocalizedText(
    nl: 'Klaar om te oogsten',
    en: 'Ready to harvest',
    de: 'Erntereif',
  );
  static LocalizedText harvestDays(int min, int max) => LocalizedText(
    nl: '$min–$max dagen',
    en: '$min–$max days',
    de: '$min–$max Tage',
  );

  // ── settings ──────────────────────────────────────────────────────────────
  static const settings = LocalizedText(
    nl: 'Instellingen',
    en: 'Settings',
    de: 'Einstellungen',
  );
  static const account = LocalizedText(
    nl: 'Account',
    en: 'Account',
    de: 'Konto',
  );
  static const membership = LocalizedText(
    nl: 'Lidmaatschap',
    en: 'Membership',
    de: 'Mitgliedschaft',
  );
  static const yourData = LocalizedText(
    nl: 'Jouw gegevens',
    en: 'Your data',
    de: 'Deine Daten',
  );
  static const appearance = LocalizedText(
    nl: 'Weergave',
    en: 'Appearance',
    de: 'Darstellung',
  );
  static const language = LocalizedText(
    nl: 'Taal',
    en: 'Language',
    de: 'Sprache',
  );
  static const help = LocalizedText(nl: 'Help', en: 'Help', de: 'Hilfe');
  static const themeSystem = LocalizedText(
    nl: 'Systeem',
    en: 'System',
    de: 'System',
  );
  static const themeLight = LocalizedText(nl: 'Licht', en: 'Light', de: 'Hell');
  static const themeDark = LocalizedText(
    nl: 'Donker',
    en: 'Dark',
    de: 'Dunkel',
  );
  static const themeFollows = LocalizedText(
    nl: 'Systeem volgt je telefoon.',
    en: 'System follows your phone.',
    de: 'System folgt deinem Handy.',
  );
  static const langNote = LocalizedText(
    nl:
        'De interface spreekt zes talen. Een teeltuitleg die nog niet vertaald '
        'is, lees je in het Engels; dat staat er dan bij.',
    en:
        'The interface speaks six languages. A growing guide that is not '
        'translated yet reads in English, and says so.',
    de: 'Die App spricht sechs Sprachen. Eine Anbauanleitung, die noch nicht übersetzt ist, erscheint auf Englisch und sagt das auch.',
  );
  static const signInBlurb = LocalizedText(
    nl:
        'Log in om je tuin te bewaren en te synchroniseren. Zonder account '
        'werkt alles gewoon offline door.',
    en:
        'Sign in to back up and sync your garden. Everything keeps working '
        'offline without it.',
    de: 'Melde dich an, um deinen Garten zu sichern und zu synchronisieren. Ohne Anmeldung funktioniert alles weiter offline.',
  );
  static const email = LocalizedText(nl: 'E-mail', en: 'E-mail', de: 'E-Mail');
  static const sendLink = LocalizedText(
    nl: 'Stuur me een inloglink',
    en: 'Send me a sign-in link',
    de: 'Anmeldelink senden',
  );
  static const checkYourMail = LocalizedText(
    nl: 'Kijk in je mail. De link logt je in.',
    en: 'Check your mail. The link signs you in.',
    de: 'Schau in dein Postfach. Der Link meldet dich an.',
  );
  static const passwordOptional = LocalizedText(
    nl: 'Wachtwoord (optioneel)',
    en: 'Password (optional)',
    de: 'Passwort (optional)',
  );
  static const signIn = LocalizedText(
    nl: 'Inloggen',
    en: 'Sign in',
    de: 'Anmelden',
  );
  static const createAccount = LocalizedText(
    nl: 'Account maken',
    en: 'Create account',
    de: 'Konto erstellen',
  );
  static const accountCreated = LocalizedText(
    nl: 'Account aangemaakt. Bevestig via de mail die we stuurden.',
    en: 'Account created. Confirm via the mail we sent.',
    de: 'Konto erstellt. Bestätige es über die Mail, die wir dir geschickt haben.',
  );
  static const signedIn = LocalizedText(
    nl: 'Ingelogd',
    en: 'Signed in',
    de: 'Angemeldet',
  );
  static const syncNow = LocalizedText(
    nl: 'Sync nu',
    en: 'Sync now',
    de: 'Synchronisieren',
  );
  static const signOut = LocalizedText(
    nl: 'Uitloggen',
    en: 'Sign out',
    de: 'Abmelden',
  );
  static const syncing = LocalizedText(
    nl: 'Synchroniseren…',
    en: 'Syncing…',
    de: 'Sync läuft…',
  );
  static const notSyncedYet = LocalizedText(
    nl: 'Nog niet gesynchroniseerd.',
    en: 'Not synced yet.',
    de: 'Noch nicht synchronisiert.',
  );
  static LocalizedText lastSync(String time) => LocalizedText(
    nl: 'Laatste sync $time',
    en: 'Last sync $time',
    de: 'Zuletzt synchronisiert $time',
  );
  static const someTablesFailed = LocalizedText(
    nl: ' · een deel is mislukt',
    en: ' · some tables failed',
    de: ' · teils fehlgeschlagen',
  );
  static const alreadyInStep = LocalizedText(
    nl: 'Alles liep al gelijk.',
    en: 'Everything was already in step.',
    de: 'Alles war schon auf dem neuesten Stand.',
  );
  static const deleteAccount = LocalizedText(
    nl: 'Account verwijderen',
    en: 'Delete account',
    de: 'Konto löschen',
  );
  static const deleteAccountAsk = LocalizedText(
    nl: 'Account verwijderen?',
    en: 'Delete account?',
    de: 'Konto löschen?',
  );
  static const deleteAccountBody = LocalizedText(
    nl:
        'Verwijdert je account en elke gesynchroniseerde tuin, plant en log. '
        'Dit kan niet ongedaan worden gemaakt.',
    en:
        'Removes your account and every synced garden, plant and log. This '
        'cannot be undone.',
    de: 'Entfernt dein Konto und jeden synchronisierten Garten, jede Pflanze und jeden Eintrag. Das lässt sich nicht rückgängig machen.',
  );
  static const deleted = LocalizedText(
    nl: 'Account verwijderd. Je lokale gegevens blijven op deze telefoon.',
    en: 'Account deleted. Your local data stays on this phone.',
    de: 'Konto gelöscht. Deine lokalen Daten bleiben auf diesem Handy.',
  );
  static const cancel = LocalizedText(
    nl: 'Annuleren',
    en: 'Cancel',
    de: 'Abbrechen',
  );
  static const delete = LocalizedText(
    nl: 'Verwijderen',
    en: 'Delete',
    de: 'Löschen',
  );
  static const exportData = LocalizedText(
    nl: 'Exporteer mijn data (JSON)',
    en: 'Export my data (JSON)',
    de: 'Meine Daten exportieren (JSON)',
  );
  static const seasonMailTitle = LocalizedText(
    nl: 'Seizoensmail',
    en: 'Seasonal email',
    de: 'Saison-E-Mail',
  );
  static const seasonMailBlurb = LocalizedText(
    nl: 'Twee mails per jaar: in februari als het zaaiseizoen begint, in oktober je oogstoverzicht. Verder niets, en uitschrijven kan met één klik.',
    en: 'Two emails a year: in February when the sowing season starts, in October your harvest summary. Nothing else, and one click unsubscribes.',
    de: 'Zwei E-Mails im Jahr: im Februar, wenn die Aussaat beginnt, im Oktober deine Erntebilanz. Sonst nichts, und ein Klick meldet dich ab.',
  );
  static const seasonMailNeedsAccount = LocalizedText(
    nl: 'Log in met een e-mailadres om dit aan te zetten.',
    en: 'Sign in with an email address to turn this on.',
    de: 'Melde dich mit einer E-Mail-Adresse an, um das einzuschalten.',
  );

  static const forgotPassword = LocalizedText(
    nl: 'Wachtwoord vergeten?',
    en: 'Forgot your password?',
    de: 'Passwort vergessen?',
  );
  static const resetMailSent = LocalizedText(
    nl: 'Check je mail voor een link om een nieuw wachtwoord te kiezen.',
    en: 'Check your mail for a link to choose a new password.',
    de: 'Schau in dein Postfach: Dort wartet ein Link, mit dem du ein neues Passwort wählst.',
  );
  static const changePassword = LocalizedText(
    nl: 'Wachtwoord wijzigen',
    en: 'Change password',
    de: 'Passwort ändern',
  );
  static const changeEmail = LocalizedText(
    nl: 'E-mailadres wijzigen',
    en: 'Change email address',
    de: 'E-Mail-Adresse ändern',
  );
  static const newPassword = LocalizedText(
    nl: 'Nieuw wachtwoord',
    en: 'New password',
    de: 'Neues Passwort',
  );
  static const newEmail = LocalizedText(
    nl: 'Nieuw e-mailadres',
    en: 'New email address',
    de: 'Neue E-Mail-Adresse',
  );
  static const passwordChanged = LocalizedText(
    nl: 'Je wachtwoord is gewijzigd.',
    en: 'Your password has been changed.',
    de: 'Dein Passwort wurde geändert.',
  );
  static const emailChangeSent = LocalizedText(
    nl: 'Check allebei je mailboxen: het oude en het nieuwe adres moeten bevestigen.',
    en: 'Check both mailboxes: the old and the new address each have to confirm.',
    de: 'Schau in beide Postfächer: Die alte und die neue Adresse müssen jeweils bestätigen.',
  );
  static const emailChangeBlurb = LocalizedText(
    nl: 'Je tuin, logboek en oogsten verhuizen mee.',
    en: 'Your garden, journal and harvests come along.',
    de: 'Dein Garten, dein Tagebuch und deine Ernten kommen mit.',
  );
  static const recoveryTitle = LocalizedText(
    nl: 'Kies een nieuw wachtwoord',
    en: 'Choose a new password',
    de: 'Wähl ein neues Passwort',
  );
  static const recoveryBody = LocalizedText(
    nl: 'Je bent binnen via de herstellink. Kies nu een nieuw wachtwoord, dan ben je weer de enige met de sleutel.',
    en: 'You came in through the recovery link. Pick a new password now, so you are the only one with the key again.',
    de: 'Du bist über den Wiederherstellungslink gekommen. Wähl jetzt ein neues Passwort, damit wieder nur du den Schlüssel hast.',
  );

  static const analyticsTitle = LocalizedText(
    nl: 'Anonieme gebruiksgegevens delen',
    en: 'Share anonymous usage data',
    de: 'Anonyme Nutzungsdaten teilen',
  );
  static const analyticsBlurb = LocalizedText(
    nl: 'Welke schermen je opent en wanneer je een plant toevoegt — nooit je notities, foto\'s of locatie. Uit laten mag; de app werkt hetzelfde.',
    en: 'Which screens you open and when you add a plant — never your notes, photos or location. Leaving it off is fine; the app works the same.',
    de: 'Welche Bildschirme du öffnest und wann du eine Pflanze hinzufügst — nie deine Notizen, Fotos oder dein Standort. Ausgeschaltet lassen ist okay; die App funktioniert genauso.',
  );
  static const analyticsAskTitle = LocalizedText(
    nl: 'Help Cropsy beter te maken?',
    en: 'Help make Cropsy better?',
    de: 'Hilfst du, Cropsy besser zu machen?',
  );
  static const analyticsAskBody = LocalizedText(
    nl: 'We kijken graag welke schermen gebruikt worden en waar mensen vastlopen. Anoniem, in de EU verwerkt, en nooit je notities, foto\'s of locatie. Je kunt dit altijd wijzigen in Instellingen.',
    en: 'We would like to see which screens get used and where people get stuck. Anonymous, processed in the EU, and never your notes, photos or location. You can change this any time in Settings.',
    de: 'Wir würden gern sehen, welche Bildschirme genutzt werden und wo es hakt. Anonym, in der EU verarbeitet und nie deine Notizen, Fotos oder dein Standort. Du kannst das jederzeit in den Einstellungen ändern.',
  );
  static const analyticsAskYes = LocalizedText(
    nl: 'Prima',
    en: 'Sure',
    de: 'Klar',
  );
  static const analyticsAskNo = LocalizedText(
    nl: 'Liever niet',
    en: 'No thanks',
    de: 'Nein danke',
  );

  static const exportBlurb = LocalizedText(
    nl: 'Kopieert alles naar het klembord.',
    en: 'Copies everything to the clipboard.',
    de: 'Kopiert alles in die Zwischenablage.',
  );
  static const copied = LocalizedText(
    nl: 'Gekopieerd naar het klembord.',
    en: 'Copied to clipboard.',
    de: 'In die Zwischenablage kopiert.',
  );
  static const seePlans = LocalizedText(
    nl: 'Bekijk plannen',
    en: 'See plans',
    de: 'Tarife ansehen',
  );
  static const managePlan = LocalizedText(
    nl: 'Beheer plan',
    en: 'Manage plan',
    de: 'Tarif verwalten',
  );
  static const restore = LocalizedText(
    nl: 'Herstellen',
    en: 'Restore',
    de: 'Wiederherstellen',
  );
  static const checkedWithStore = LocalizedText(
    nl: 'Gecontroleerd bij de store.',
    en: 'Checked with the store.',
    de: 'Beim Store nachgefragt.',
  );
  static const syncUnavailable = LocalizedText(
    nl: 'Synchroniseren zit niet in deze build.',
    en: 'Sync is not available in this build.',
    de: 'Synchronisieren ist in diesem Build nicht verfügbar.',
  );
  static const planFree = LocalizedText(nl: 'Gratis', en: 'Free', de: 'Gratis');
  static const planLifetime = LocalizedText(
    nl: 'Levenslang',
    en: 'Lifetime',
    de: 'Lebenslang',
  );
  static const planYearly = LocalizedText(
    nl: 'Jaarlijks',
    en: 'Yearly',
    de: 'Jährlich',
  );
  static const lifetimeNothingToCancel = LocalizedText(
    nl: 'Levenslang. Niets op te zeggen.',
    en: 'Lifetime. Nothing to cancel.',
    de: 'Lebenslang. Nichts zu kündigen.',
  );
  static const freeTierBlurb = LocalizedText(
    nl:
        '1 tuin · 6 groeiende planten · volledige tijdlijn, herinneringen en '
        'elk gewas.',
    en: '1 garden · 6 growing plants · full timeline, reminders and every crop.',
    de: '1 Garten · 6 wachsende Pflanzen · ganzer Zeitplan, Erinnerungen und jede Pflanze.',
  );
  static LocalizedText cropDataVersion(String version) => LocalizedText(
    nl: 'Cropsy · gewasdata $version',
    en: 'Cropsy · crop data $version',
    de: 'Cropsy · Pflanzendaten $version',
  );
  static LocalizedText frostDates(String region, String source) =>
      LocalizedText(
        nl: 'Vorstdatums: $region ($source)',
        en: 'Frost dates: $region ($source)',
        de: 'Frostdaten: $region ($source)',
      );

  // ── this week ─────────────────────────────────────────────────────────────
  static const thisWeek = LocalizedText(
    nl: 'Deze week',
    en: 'This week',
    de: 'Diese Woche',
  );
  static const nothingDueThisWeek = LocalizedText(
    nl: 'Deze week staat er niets te doen',
    en: 'Nothing due this week',
    de: 'Diese Woche steht nichts an',
  );
  static const addPlantsToSee = LocalizedText(
    nl: 'Voeg planten toe bij Kweken om te zien wat er te doen is.',
    en: 'Add plants in Grow to see what to do.',
    de: 'Füg unter Anbauen Pflanzen hinzu, um zu sehen, was zu tun ist.',
  );

  // ── harvest ───────────────────────────────────────────────────────────────
  static const harvest = LocalizedText(nl: 'Oogst', en: 'Harvest', de: 'Ernte');
  static const thisSeason = LocalizedText(
    nl: 'DIT SEIZOEN',
    en: 'THIS SEASON',
    de: 'DIESE SAISON',
  );
  static const nothingYet = LocalizedText(
    nl: 'Nog niets',
    en: 'Nothing yet',
    de: 'Noch nichts',
  );
  static LocalizedText savedAtPrices(String euros) => LocalizedText(
    nl: '≈ €$euros bespaard tegen NL supermarktprijzen',
    en: '≈ €$euros saved at NL supermarket prices',
    de: '≈ $euros € gespart nach NL-Supermarktpreisen',
  );
  static LocalizedText unpricedCount(int n) => LocalizedText(
    nl: n == 1 ? '1 zonder prijs' : '$n zonder prijs',
    en: n == 1 ? '1 unpriced' : '$n unpriced',
    de: n == 1 ? '1 ohne Preis' : '$n ohne Preis',
  );
  static LocalizedText harvestsLogged(int n) => LocalizedText(
    nl: n == 1 ? '1 oogst gelogd' : '$n oogsten gelogd',
    en: n == 1 ? '1 harvest logged' : '$n harvests logged',
    de: n == 1 ? '1 Ernte eingetragen' : '$n Ernten eingetragen',
  );
  static const planFreePrice = LocalizedText(nl: '€0', en: '€0', de: '0 €');
  static const planLifetimePrice = LocalizedText(
    nl: '€49,99 eenmalig',
    en: '€49.99 once',
    de: '49,99 € einmalig',
  );
  static const planYearlyPrice = LocalizedText(
    nl: '€29,99 / jaar',
    en: '€29.99 / year',
    de: '29,99 € / Jahr',
  );
  static const planFreeBlurb = LocalizedText(
    nl:
        '1 tuin · 6 planten in de grond · volledige tijdlijn, herinneringen en '
        'alle gewassen · 20 fotos · 2 streakbevriezingen per maand',
    en:
        '1 garden · 6 growing plants · full timeline, reminders and every crop '
        '· 20 photos · 2 streak freezes a month',
    de: '1 Garten · 6 wachsende Pflanzen · ganzer Zeitplan, Erinnerungen und jede Pflanze · 20 Fotos · 2 Serien-Pausen pro Monat',
  );
  static const planLifetimeBlurb = LocalizedText(
    nl:
        'Onbeperkt tuinen en planten · plannerraster · diagnose · onbeperkt '
        "fotos en bevriezingen · export",
    en:
        'Unlimited gardens and plants · planner grid · diagnose · unlimited '
        'photos and freezes · export',
    de: 'Unbegrenzt Gärten und Pflanzen · Beetplaner · Diagnose · unbegrenzt Fotos und Pausen · Export',
  );
  static const planYearlyBlurb = LocalizedText(
    nl:
        'Alles uit Levenslang, als abonnement. Zeg elk moment op in de App '
        'Store.',
    en:
        'Everything in Lifetime, as a subscription. Cancel in the App Store '
        'any time.',
    de: 'Alles aus Lebenslang, als Abo. Jederzeit im App Store kündbar.',
  );
  static const noPriceForUnit = LocalizedText(
    nl: 'Nog geen prijs voor deze eenheid',
    en: 'No price for this unit yet',
    de: 'Für diese Einheit gibt es noch keinen Preis',
  );

  // ── diagnose ──────────────────────────────────────────────────────────────
  static const diagnose = LocalizedText(
    nl: 'Diagnose',
    en: 'Diagnose',
    de: 'Diagnose',
  );
  static const autoDiagnose = LocalizedText(
    nl: 'Diagnose van een foto',
    en: 'Auto diagnose from a photo',
    de: 'Automatische Diagnose per Foto',
  );
  static const autoDiagnoseSub = LocalizedText(
    nl: 'Altijd een gok, nooit een oordeel. Premium.',
    en: 'Always a guess, never a verdict. Premium.',
    de: 'Immer eine Vermutung, nie ein Urteil. Premium.',
  );
  static const commonProblems = LocalizedText(
    nl: 'Veelvoorkomende problemen',
    en: 'Common problems',
    de: 'Häufige Probleme',
  );
  static const byPlantPart = LocalizedText(
    nl: 'Per plantdeel',
    en: 'By plant part',
    de: 'Nach Pflanzenteil',
  );
  static const all = LocalizedText(nl: 'Alles', en: 'All', de: 'Alle');
  static const nothingForThatPart = LocalizedText(
    nl: 'Hier staat nog niets voor dat deel.',
    en: 'Nothing listed for that part yet.',
    de: 'Für diesen Teil ist noch nichts gelistet.',
  );
  static const partWhole = LocalizedText(
    nl: 'Hele plant',
    en: 'Whole plant',
    de: 'Ganze Pflanze',
  );
  static const partLeaves = LocalizedText(
    nl: 'Blad',
    en: 'Leaves',
    de: 'Blätter',
  );
  static const partStems = LocalizedText(
    nl: 'Stengels',
    en: 'Stems',
    de: 'Stängel',
  );
  static const partFlowers = LocalizedText(
    nl: 'Bloemen',
    en: 'Flowers',
    de: 'Blüten',
  );
  static const partFruits = LocalizedText(
    nl: 'Vruchten',
    en: 'Fruits',
    de: 'Früchte',
  );
  static const partRoots = LocalizedText(
    nl: 'Wortels',
    en: 'Roots',
    de: 'Wurzeln',
  );

  // ── the garden tab ────────────────────────────────────────────────────────
  static const myGarden = LocalizedText(
    nl: 'Mijn tuin',
    en: 'My garden',
    de: 'Mein Garten',
  );
  static const planning = LocalizedText(
    nl: 'Gepland',
    en: 'Planning',
    de: 'Planung',
  );
  static const growing = LocalizedText(
    nl: 'Groeit',
    en: 'Growing',
    de: 'Im Anbau',
  );
  // Short enough to sit in a four-way segmented control.
  static const reminders = LocalizedText(
    nl: 'Meldingen',
    en: 'Reminders',
    de: 'Erinnerungen',
  );
  static const start = LocalizedText(nl: 'Starten', en: 'Start', de: 'Start');
  static const remove = LocalizedText(
    nl: 'Verwijderen',
    en: 'Remove',
    de: 'Entfernen',
  );
  static LocalizedText removeAsk(String name) => LocalizedText(
    nl: '$name verwijderen?',
    en: 'Remove $name?',
    de: '$name entfernen?',
  );
  static LocalizedText removedFromGarden(String name) => LocalizedText(
    nl: '$name is uit je tuin gehaald',
    en: '$name removed from your garden',
    de: '$name wurde aus deinem Garten entfernt',
  );
  static const editGarden = LocalizedText(
    nl: 'Tuin bewerken',
    en: 'Edit garden',
    de: 'Garten bearbeiten',
  );
  static const gardenName = LocalizedText(
    nl: 'Naam van de tuin',
    en: 'Garden name',
    de: 'Name des Gartens',
  );
  static const growingSituation = LocalizedText(
    nl: 'Waar tuinier je?',
    en: 'Growing situation',
    de: 'Anbausituation',
  );
  static LocalizedText sunHours(int hours) => LocalizedText(
    nl: 'Uren zon per dag: ${hours}u',
    en: 'Hours of sun a day: ${hours}h',
    de: 'Sonnenstunden pro Tag: ${hours}h',
  );
  static const saveChanges = LocalizedText(
    nl: 'Opslaan',
    en: 'Save changes',
    de: 'Änderungen speichern',
  );
  static const nothingPlannedYet = LocalizedText(
    nl: 'Nog niets gepland',
    en: 'Nothing planned yet',
    de: 'Noch nichts geplant',
  );
  static const nothingGrowingYet = LocalizedText(
    nl: 'Nog niets aan het groeien',
    en: 'Nothing growing yet',
    de: 'Noch nichts im Anbau',
  );
  static const balcony = LocalizedText(
    nl: 'Balkon',
    en: 'Balcony',
    de: 'Balkon',
  );
  static const gardenKind = LocalizedText(
    nl: 'Tuin',
    en: 'Garden',
    de: 'Garten',
  );
  static const allotment = LocalizedText(
    nl: 'Volkstuin',
    en: 'Allotment',
    de: 'Kleingarten',
  );

  // ── a plant ───────────────────────────────────────────────────────────────
  static const growingGuide = LocalizedText(
    nl: 'Teeltgids →',
    en: 'Growing guide →',
    de: 'Anbauanleitung →',
  );
  static const growthLog = LocalizedText(
    nl: 'Groeilog',
    en: 'Growth log',
    de: 'Verlauf',
  );
  static const logHarvest = LocalizedText(
    nl: 'Oogst loggen',
    en: 'Log harvest',
    de: 'Ernte eintragen',
  );
  static const harvestLogged = LocalizedText(
    nl: 'Oogst gelogd',
    en: 'Harvest logged',
    de: 'Ernte eingetragen',
  );
  static LocalizedText movedToPlanning(String crop) => LocalizedText(
    nl: '$crop staat weer bij Gepland',
    en: '$crop moved to planning',
    de: '$crop ist wieder in der Planung',
  );
  static const noEntriesYet = LocalizedText(
    nl: 'Nog geen notities. Voeg er een toe om de tijdlijn te starten.',
    en: 'No entries yet. Add one to start the timeline.',
    de: 'Noch keine Einträge. Füg einen hinzu, um die Zeitleiste zu starten.',
  );
  static const howMuch = LocalizedText(
    nl: 'Hoeveel?',
    en: 'How much?',
    de: 'Wie viel?',
  );
  static const howMuchHint = LocalizedText(
    nl: 'bijv. 6 of 0,4',
    en: 'e.g. 6 or 0.4',
    de: 'z. B. 6 oder 0,4',
  );
  static const pieces = LocalizedText(nl: 'stuks', en: 'pieces', de: 'Stück');
  static const saveHarvest = LocalizedText(
    nl: 'Oogst opslaan',
    en: 'Save harvest',
    de: 'Ernte speichern',
  );
  static const editPlant = LocalizedText(
    nl: 'Plant bewerken',
    en: 'Edit plant',
    de: 'Pflanze bearbeiten',
  );
  static const potSizeLitres = LocalizedText(
    nl: 'Potmaat (liter)',
    en: 'Pot size (litres)',
    de: 'Topfgröße (Liter)',
  );
  static const leaveBlankInGround = LocalizedText(
    nl: 'leeg laten voor in de volle grond',
    en: 'leave blank for in-ground',
    de: 'leer lassen, wenn im Boden',
  );
  static const planted = LocalizedText(
    nl: 'Geplant',
    en: 'Planted',
    de: 'Gepflanzt',
  );
  static const growthStage = LocalizedText(
    nl: 'Groeifase',
    en: 'Growth stage',
    de: 'Wachstumsphase',
  );
  static const yourPath = LocalizedText(
    nl: 'Jouw pad',
    en: 'Your path',
    de: 'Dein Pfad',
  );
  static const journal = LocalizedText(
    nl: 'Logboek',
    en: 'Journal',
    de: 'Tagebuch',
  );
  static const yourSeason = LocalizedText(
    nl: 'Jouw seizoen',
    en: 'Your season',
    de: 'Deine Saison',
  );
  static const bedFreesUp = LocalizedText(
    nl: 'Plek komt vrij',
    en: 'Bed frees up',
    de: 'Beet wird frei',
  );
  static const about = LocalizedText(nl: 'Over', en: 'About', de: 'Infos');
  static const yourCrops = LocalizedText(
    nl: 'Jouw gewassen',
    en: 'Your crops',
    de: 'Deine Pflanzen',
  );
  static const plannedSection = LocalizedText(
    nl: 'Gepland',
    en: 'Planned',
    de: 'Geplant',
  );
  static const types = LocalizedText(nl: 'Rassen', en: 'Types', de: 'Sorten');

  /// A crop page's sections: the jump chip and the heading say the same thing.
  static LocalizedText cropSection(String id) => switch (id) {
    'Calendar' => const LocalizedText(
      nl: 'Kalender',
      en: 'Calendar',
      de: 'Kalender',
    ),
    'Timeline' => const LocalizedText(
      nl: 'Tijdlijn',
      en: 'Timeline',
      de: 'Zeitleiste',
    ),
    'Difficulty' => const LocalizedText(
      nl: 'Moeilijkheid',
      en: 'Difficulty',
      de: 'Schwierigkeit',
    ),
    'Location' => const LocalizedText(
      nl: 'Standplaats',
      en: 'Location',
      de: 'Standort',
    ),
    'Soil' => const LocalizedText(nl: 'Grond', en: 'Soil', de: 'Boden'),
    'How-tos' => const LocalizedText(
      nl: 'Zo doe je het',
      en: 'How-tos',
      de: 'Anleitungen',
    ),
    'Neighbours' => const LocalizedText(
      nl: 'Buren',
      en: 'Neighbours',
      de: 'Nachbarn',
    ),
    'Benefits' => const LocalizedText(
      nl: 'Waarom telen',
      en: 'Benefits',
      de: 'Vorteile',
    ),
    'FAQ' => const LocalizedText(nl: 'Vragen', en: 'FAQ', de: 'FAQ'),
    _ => LocalizedText(nl: id, en: id, de: id),
  };
  static const plantingCalendar = LocalizedText(
    nl: 'Zaaikalender',
    en: 'Planting calendar',
    de: 'Aussaatkalender',
  );
  static const growthTimeline = LocalizedText(
    nl: 'Groeitijdlijn',
    en: 'Growth timeline',
    de: 'Wachstumsverlauf',
  );
  static const suitableLocation = LocalizedText(
    nl: 'Geschikte standplaats',
    en: 'Suitable location',
    de: 'Geeigneter Standort',
  );
  static const soilPrep = LocalizedText(
    nl: 'Grond voorbereiden',
    en: 'Soil prep',
    de: 'Bodenvorbereitung',
  );
  static const whyGrowIt = LocalizedText(
    nl: 'Waarom telen',
    en: 'Why grow it',
    de: 'Warum anbauen',
  );
  static const comingSoil = LocalizedText(
    nl: 'Grond voorbereiden',
    en: 'Soil preparation',
    de: 'Bodenvorbereitung',
  );
  static const comingHowTos = LocalizedText(
    nl: 'Stap voor stap per fase',
    en: 'Step-by-step how-tos per stage',
    de: 'Schritt-für-Schritt-Anleitungen pro Phase',
  );
  static const comingFaq = LocalizedText(
    nl: 'Vragen, nagekeken door telers',
    en: 'Grower-reviewed FAQ',
    de: 'Von Gärtnern geprüfte FAQ',
  );
  static const comingBenefits = LocalizedText(
    nl: 'Voeding en gezondheid (NEVO)',
    en: 'Nutrition and benefits (NEVO)',
    de: 'Nährwerte und Vorteile (NEVO)',
  );
  static LocalizedText contentComing(LocalizedText what) => LocalizedText(
    nl:
        '${what.nl}: wordt geschreven en nagekeken voor Nederlandse tuinen. '
        'Komt in de contentupdate.',
    en:
        '${what.en}: being written and checked for Dutch gardens. '
        'Coming in the content update.',
    de:
        '${what.pick('de')}: wird für niederländische Gärten geschrieben und '
        'geprüft. Kommt mit dem Inhalts-Update.',
  );

  /// Said above a guide we only have in one language yet.
  static LocalizedText guideOnlyIn(String lang) => switch (lang) {
    'de' => const LocalizedText(
      nl: 'Deze uitleg is er nu alleen in het Duits.',
      en: 'This guide is in German for now.',
      de: 'Diese Anleitung gibt es vorerst nur auf Deutsch.',
    ),
    'nl' => const LocalizedText(
      nl: 'Deze uitleg is er nu alleen in het Nederlands.',
      en: 'This guide is in Dutch for now.',
      de: 'Diese Anleitung gibt es vorerst nur auf Niederländisch.',
    ),
    _ => const LocalizedText(
      nl: 'Deze uitleg is er nu alleen in het Engels.',
      en: 'This guide is in English for now.',
      de: 'Diese Anleitung gibt es vorerst nur auf Englisch.',
    ),
  };
  static LocalizedText atSupplier(String supplier) => LocalizedText(
    nl: 'bij $supplier',
    en: 'at $supplier',
    de: 'bei $supplier',
  );
  static const oftenOn = LocalizedText(
    nl: 'Vaak bij',
    en: 'Often on',
    de: 'Häufig an',
  );
  static const insightsForYou = LocalizedText(
    nl: 'Wat nu belangrijk is',
    en: 'Insights for you',
    de: 'Tipps für dich',
  );
  static LocalizedText plantedOn(String day) => LocalizedText(
    nl: 'geplant $day',
    en: 'planted $day',
    de: 'gepflanzt am $day',
  );
  static const countsTowardsTally = LocalizedText(
    nl: 'Telt mee voor je seizoensoogst.',
    en: 'Counts towards your season tally.',
    de: 'Zählt zu deiner Saisonbilanz.',
  );
  static const noShopPrice = LocalizedText(
    nl:
        'Voor dit gewas is nog geen winkelprijs bekend, dus het telt mee voor '
        'de opbrengst maar niet voor het bespaarde bedrag.',
    en:
        'This crop has no shop price yet, so it counts towards the yield but '
        'not towards money saved.',
    de: 'Für diese Pflanze gibt es noch keinen Ladenpreis, darum zählt sie zum Ertrag, aber nicht zum gesparten Geld.',
  );
  static LocalizedText pricedPerUnit(LocalizedText unit) => LocalizedText(
    nl:
        'Je telling rekent dit gewas per ${unit.nl}, dus dit telt mee voor '
        'de opbrengst maar niet voor het bespaarde bedrag.',
    en:
        'Your tally prices this crop per ${unit.en}, so this adds to the '
        'yield but not to money saved.',
    de:
        'Deine Bilanz rechnet diese Pflanze pro ${unit.pick('de')}, darum '
        'zählt das zum Ertrag, aber nicht zum gesparten Geld.',
  );
  static const unitKg = LocalizedText(nl: 'kg', en: 'kg', de: 'kg');

  // ── the growth log ────────────────────────────────────────────────────────
  static LocalizedText howIsItDoing(LocalizedText crop) => LocalizedText(
    nl: 'Hoe gaat het met je ${crop.nl}?',
    en: 'How is your ${crop.en} doing?',
    de: '${crop.pick('de')}: Wie läuft es?',
  );
  static LocalizedText photosCount(int n) => LocalizedText(
    nl: "Foto's ($n/9)",
    en: 'Photos ($n/9)',
    de: 'Fotos ($n/9)',
  );
  static const noteOptional = LocalizedText(
    nl: 'Notitie (optioneel)',
    en: 'Note (optional)',
    de: 'Notiz (optional)',
  );
  static const noteHint = LocalizedText(
    nl: 'Eerste bloemen, luis op de toppen…',
    en: 'First flowers, aphids on the tips…',
    de: 'Erste Blüten, Läuse an den Spitzen…',
  );
  static const saveLog = LocalizedText(
    nl: 'Log opslaan',
    en: 'Save log',
    de: 'Eintrag speichern',
  );
  static const moodBad = LocalizedText(nl: 'Slecht', en: 'Bad', de: 'Schlecht');
  static const moodOkay = LocalizedText(nl: 'Gaat wel', en: 'Okay', de: 'Okay');
  static const moodGood = LocalizedText(nl: 'Goed', en: 'Good', de: 'Gut');
  static const moodExcellent = LocalizedText(
    nl: 'Uitstekend',
    en: 'Excellent',
    de: 'Super',
  );
  static const stageStarting = LocalizedText(
    nl: 'Gestart',
    en: 'Starting',
    de: 'Beginn',
  );
  static const stageSeedling = LocalizedText(
    nl: 'Zaailing',
    en: 'Seedling',
    de: 'Sämling',
  );
  static const stageVegetative = LocalizedText(
    nl: 'Groeiend',
    en: 'Vegetative',
    de: 'Wachstum',
  );
  static const stageFlowering = LocalizedText(
    nl: 'Bloeiend',
    en: 'Flowering',
    de: 'Blüte',
  );
  static const stageHarvesting = LocalizedText(
    nl: 'Oogsten',
    en: 'Harvesting',
    de: 'Ernte',
  );
  static const stageHarvested = LocalizedText(
    nl: 'Geoogst',
    en: 'Harvested',
    de: 'Geerntet',
  );

  // ── adding a plant ────────────────────────────────────────────────────────
  static const setPlantDetails = LocalizedText(
    nl: 'Plantgegevens',
    en: 'Set plant details',
    de: 'Pflanzendetails festlegen',
  );
  static const plantDetailsSub = LocalizedText(
    nl: 'Hiermee bepalen we de oogsttiming en de herinneringen.',
    en: 'Your input sets the harvest timing and care reminders.',
    de: 'Deine Angaben bestimmen den Erntezeitpunkt und die Pflege-Erinnerungen.',
  );
  static const plantingDate = LocalizedText(
    nl: 'Plantdatum',
    en: 'Planting date',
    de: 'Pflanzdatum',
  );
  static const howDidItStart = LocalizedText(
    nl: 'Hoe is het begonnen?',
    en: 'How did it start?',
    de: 'Wie hat sie angefangen?',
  );
  static const whereDoesItLive = LocalizedText(
    nl: 'Waar staat het?',
    en: 'Where does it live?',
    de: 'Wo wächst sie?',
  );
  static LocalizedText atLeastLitres(int litres) => LocalizedText(
    nl: 'Minstens $litres L voor dit gewas',
    en: 'At least $litres L for this crop',
    de: 'Mindestens $litres L für diese Pflanze',
  );
  static const varietyOptional = LocalizedText(
    nl: 'Ras (optioneel)',
    en: 'Variety (optional)',
    de: 'Sorte (optional)',
  );
  static const varietyHint = LocalizedText(
    nl: 'bijv. Moneymaker',
    en: 'e.g. Moneymaker',
    de: 'z. B. Moneymaker',
  );

  // ── logging a node ────────────────────────────────────────────────────────
  static const didItToday = LocalizedText(
    nl: 'Vandaag gedaan',
    en: 'Did it today',
    de: 'Heute erledigt',
  );
  static const didItOn = LocalizedText(
    nl: 'Ik deed dit op…',
    en: 'I did this on…',
    de: 'Erledigt am…',
  );
  static const skipThisOne = LocalizedText(
    nl: 'Sla deze over',
    en: 'Skip this one',
    de: 'Diesmal überspringen',
  );
  static const gotIt = LocalizedText(
    nl: 'Duidelijk',
    en: 'Got it',
    de: 'Verstanden',
  );
  static const now = LocalizedText(nl: 'Nu', en: 'Now', de: 'Jetzt');
  static const skipped = LocalizedText(
    nl: 'Overgeslagen',
    en: 'Skipped',
    de: 'Übersprungen',
  );
  static LocalizedText doneOn(String day) =>
      LocalizedText(nl: 'Gedaan $day', en: 'Done $day', de: 'Erledigt am $day');
  static LocalizedText movedFrom(String day, LocalizedText reason) =>
      LocalizedText(
        nl: 'Verzet vanaf $day · ${reason.nl}',
        en: 'Moved from $day · ${reason.en}',
        de: 'Verschoben vom $day · ${reason.pick('de')}',
      );

  // ── the planner ───────────────────────────────────────────────────────────
  static const gardenPlanner = LocalizedText(
    nl: 'Tuinplanner',
    en: 'Garden planner',
    de: 'Gartenplaner',
  );
  static const plannerBlurb = LocalizedText(
    nl: 'Leg je bed uit in vakjes van 30 cm.',
    en: 'Lay out your bed in 30 cm squares.',
    de: 'Plane dein Beet in 30-cm-Quadraten.',
  );
  static const save = LocalizedText(nl: 'Opslaan', en: 'Save', de: 'Speichern');
  static const layoutSaved = LocalizedText(
    nl: 'Indeling opgeslagen',
    en: 'Layout saved',
    de: 'Plan gespeichert',
  );
  static const pickACrop = LocalizedText(
    nl: 'Kies hieronder een gewas en tik dan op de vakjes.',
    en: 'Pick a crop below, then tap cells.',
    de: 'Wähl unten eine Pflanze und tippe dann auf Felder.',
  );
  static LocalizedText painting(LocalizedText crop) => LocalizedText(
    nl: '${crop.nl} plaatsen. Tik een gevuld vakje om het leeg te maken.',
    en: 'Painting ${crop.en}. Tap a filled cell to clear it.',
    de: '${crop.pick('de')} setzen. Tippe auf ein volles Feld, um es zu leeren.',
  );
  static const redCells = LocalizedText(
    nl: 'Rode vakjes staan naast een gewas dat ze niet liggen.',
    en: 'Red cells sit next to a crop they dislike.',
    de: 'Rote Felder liegen neben einem schlechten Nachbarn.',
  );
  static const planIt = LocalizedText(
    nl: 'Plan het',
    en: 'Plan it',
    de: 'Einplanen',
  );
  static LocalizedText addedToPlanning(String crop) => LocalizedText(
    nl: '$crop staat bij Gepland',
    en: '$crop added to Planning',
    de: '$crop ist jetzt in der Planung',
  );

  // ── profile ───────────────────────────────────────────────────────────────
  static const dayStreak = LocalizedText(
    nl: 'Dagen op rij',
    en: 'Day streak',
    de: 'Tage in Folge',
  );
  static const growingNow = LocalizedText(
    nl: 'Groeit nu',
    en: 'Growing now',
    de: 'Wächst gerade',
  );
  static const harvested = LocalizedText(
    nl: 'Geoogst',
    en: 'Harvested',
    de: 'Geerntet',
  );
  static const yourGarden = LocalizedText(
    nl: 'Jouw tuin',
    en: 'Your garden',
    de: 'Dein Garten',
  );
  static const region = LocalizedText(nl: 'Regio', en: 'Region', de: 'Region');
  static const settingsAndSync = LocalizedText(
    nl: 'Instellingen en sync',
    en: 'Settings and sync',
    de: 'Einstellungen und Sync',
  );
  static const signInToSync = LocalizedText(
    nl: 'Log in om te synchroniseren',
    en: 'Sign in to sync',
    de: 'Für Sync anmelden',
  );
  static const yourName = LocalizedText(
    nl: 'Je naam',
    en: 'Your name',
    de: 'Dein Name',
  );
  static const gardener = LocalizedText(
    nl: 'Tuinier',
    en: 'Gardener',
    de: 'Gärtner',
  );
  static const onThisDeviceOnly = LocalizedText(
    nl: 'Alleen op deze telefoon',
    en: 'On this device only',
    de: 'Nur auf diesem Gerät',
  );

  // ── scanning ──────────────────────────────────────────────────────────────
  static const identifyAPlant = LocalizedText(
    nl: 'Herken een plant',
    en: 'Identify a plant',
    de: 'Pflanze bestimmen',
  );
  static const diagnoseAPlant = LocalizedText(
    nl: 'Stel een diagnose',
    en: 'Diagnose a plant',
    de: 'Pflanze untersuchen',
  );
  static const whatIsIt = LocalizedText(
    nl: 'Wat is dit?',
    en: 'What is it?',
    de: 'Was ist das?',
  );
  static const isItOk = LocalizedText(
    nl: 'Is het gezond?',
    en: 'Is it OK?',
    de: 'Alles okay?',
  );
  static const takePhoto = LocalizedText(
    nl: 'Foto maken',
    en: 'Take photo',
    de: 'Foto aufnehmen',
  );
  static const fromPhotos = LocalizedText(
    nl: "Uit foto's",
    en: 'From photos',
    de: 'Aus Fotos',
  );
  static const noConnectionScan = LocalizedText(
    nl: 'Geen verbinding. Scannen heeft internet nodig; de rest werkt offline.',
    en: 'No connection. Scans need the network; everything else works offline.',
    de: 'Keine Verbindung. Scans brauchen das Netz; alles andere funktioniert offline.',
  );
  static const notOneOfOurCrops = LocalizedText(
    nl: 'Nog niet een van onze gewassen',
    en: 'Not one of our crops yet',
    de: 'Noch nicht in unserer Liste',
  );
  static const noGuideYet = LocalizedText(
    nl: 'Hier is nog geen gids voor',
    en: 'No guide for this one yet',
    de: 'Dafür gibt es noch keine Anleitung',
  );
  static LocalizedText scansUsed(int used, int limit) => LocalizedText(
    nl: '$used van $limit scans vandaag gebruikt',
    en: '$used of $limit scans used today',
    de: '$used von $limit Scans heute genutzt',
  );

  // ── the paywall ───────────────────────────────────────────────────────────
  static const payOnce = LocalizedText(
    nl:
        'Betaal één keer voor meer ruimte. Geen proefperiode, geen kaart, geen '
        'verrassing bij verlenging.',
    en: 'Pay once for more room. No trial, no card, no auto-renew surprise.',
    de: 'Einmal zahlen für mehr Platz. Kein Probe-Abo, keine Karte, keine Verlängerungs-Überraschung.',
  );
  static const oneMoment = LocalizedText(
    nl: 'Momentje…',
    en: 'One moment…',
    de: 'Einen Moment…',
  );
  static const keepItFree = LocalizedText(
    nl: 'Hou het gratis',
    en: 'Keep it free',
    de: 'Gratis bleiben',
  );
  static LocalizedText continueWith(String plan) => LocalizedText(
    nl: 'Verder met $plan',
    en: 'Continue with $plan',
    de: 'Weiter mit $plan',
  );
  static const purchasesOpenLater = LocalizedText(
    nl: 'Kopen is nu niet mogelijk. Er wordt niets afgeschreven.',
    en: 'Purchases are not available right now. Nothing is charged.',
    de: 'Käufe sind gerade nicht verfügbar. Es wird nichts berechnet.',
  );
  static const purchasesRestored = LocalizedText(
    nl: 'Aankopen hersteld.',
    en: 'Purchases restored.',
    de: 'Käufe wiederhergestellt.',
  );
  static const nothingToRestore = LocalizedText(
    nl: 'Geen eerdere aankopen gevonden voor dit Apple-account.',
    en: 'No earlier purchases found for this Apple account.',
    de: 'Keine früheren Käufe für diesen Apple-Account gefunden.',
  );
  static const restorePurchases = LocalizedText(
    nl: 'Aankopen herstellen',
    en: 'Restore purchases',
    de: 'Käufe wiederherstellen',
  );
  static const lifetimeNothingEver = LocalizedText(
    nl: 'Levenslang: nooit iets op te zeggen.',
    en: 'Lifetime: nothing to cancel, ever.',
    de: 'Lebenslang: nie etwas zu kündigen.',
  );

  // ── where you grow ────────────────────────────────────────────────────────
  static const whereDoYouGrow = LocalizedText(
    nl: 'Waar tuinier je?',
    en: 'Where do you grow?',
    de: 'Wo gärtnerst du?',
  );
  static const townOrPostcode = LocalizedText(
    nl: 'Plaats, regio of postcode',
    en: 'Town, region or postcode',
    de: 'Ort, Region oder Postleitzahl',
  );
  static LocalizedText usePostcode(String code) => LocalizedText(
    nl: 'Gebruik postcode $code',
    en: 'Use postcode $code',
    de: 'Postleitzahl $code nutzen',
  );
  static const looksUpFrost = LocalizedText(
    nl: 'Zoekt de vorstdatums voor dat gebied op.',
    en: 'Looks up the frost dates for that cell.',
    de: 'Sucht die Frostdaten für dieses Gebiet.',
  );
  static const snapToRegion = LocalizedText(
    nl: 'Kies de dichtstbijzijnde teeltregio',
    en: 'Snap to the nearest growing region',
    de: 'Auf die nächste Anbauregion setzen',
  );
  static const noLocation = LocalizedText(
    nl: 'Geen locatie gevonden. Kies een regio of vul een postcode in.',
    en: 'Could not get a location. Pick a region or enter a postcode.',
    de: 'Kein Standort gefunden. Wähl eine Region oder gib eine Postleitzahl ein.',
  );
  static const postcodeNotFound = LocalizedText(
    nl: 'Postcode niet gevonden (verwacht 1234AB), of je bent offline.',
    en: 'Postcode not found (expected 1234AB), or you are offline.',
    de: 'Postleitzahl nicht gefunden (erwartet 1234AB) oder du bist offline.',
  );
  static const useMyLocation = LocalizedText(
    nl: 'Gebruik mijn locatie',
    en: 'Use my location',
    de: 'Meinen Standort nutzen',
  );
  static const lookingUp = LocalizedText(
    nl: 'Zoeken…',
    en: 'Looking up…',
    de: 'Suche…',
  );
  static const postcodeHint = LocalizedText(
    nl: 'Postcode, bijv. 1012AB',
    en: 'Postcode, e.g. 1012AB',
    de: 'Postleitzahl, z. B. 1012AB',
  );
  static const lookUp = LocalizedText(
    nl: 'Zoek op',
    en: 'Look up',
    de: 'Suchen',
  );
  static const orPickRegion = LocalizedText(
    nl: 'Of kies een regio',
    en: 'Or pick a region',
    de: 'Oder wähl eine Region',
  );

  // ── feedback on content ───────────────────────────────────────────────────
  static const isThisUseful = LocalizedText(
    nl: 'Heb je hier iets aan?',
    en: 'Is this information useful?',
    de: 'Ist diese Info hilfreich?',
  );
  static const reportError = LocalizedText(
    nl: 'Fout melden',
    en: 'Report error',
    de: 'Fehler melden',
  );
  static const whatIsWrong = LocalizedText(
    nl: 'Wat klopt er niet?',
    en: 'What is wrong?',
    de: 'Was stimmt nicht?',
  );
  static const whatIsWrongHint = LocalizedText(
    nl: 'bijv. het zaaivenster is te vroeg voor Groningen',
    en: 'e.g. sowing window is too early for Groningen',
    de: 'z. B. Aussaatfenster ist für Groningen zu früh',
  );
  static const send = LocalizedText(nl: 'Versturen', en: 'Send', de: 'Senden');
  static const thanksChecked = LocalizedText(
    nl: 'Dank je. We kijken elke melding binnen een week na.',
    en: 'Thanks. We check every report within a week.',
    de: 'Danke. Wir prüfen jede Meldung innerhalb einer Woche.',
  );
  static const thanksFeedback = LocalizedText(
    nl: 'Dank voor je feedback.',
    en: 'Thanks for the feedback.',
    de: 'Danke für das Feedback.',
  );
  static const thanksNoted = LocalizedText(
    nl: 'Dank, genoteerd.',
    en: 'Thanks, noted.',
    de: 'Danke, notiert.',
  );
  static const likeThis = LocalizedText(
    nl: 'Hier heb ik wat aan',
    en: 'I like this',
    de: 'Gefällt mir',
  );
  static const errorInContent = LocalizedText(
    nl: 'Fout in de inhoud',
    en: 'Error in content',
    de: 'Fehler im Inhalt',
  );
  static const suggestion = LocalizedText(
    nl: 'Suggestie',
    en: 'Suggestion',
    de: 'Vorschlag',
  );

  static const overallDifficulty = LocalizedText(
    nl: 'Moeilijkheid',
    en: 'Overall difficulty',
    de: 'Schwierigkeit insgesamt',
  );

  /// Problem kind pills on the Diagnose tab (data carries the English key).
  static LocalizedText problemKind(String kind) => switch (kind) {
    'pest' => const LocalizedText(nl: 'plaag', en: 'pest', de: 'Schädling'),
    'disease' => const LocalizedText(
      nl: 'ziekte',
      en: 'disease',
      de: 'Krankheit',
    ),
    'disorder' => const LocalizedText(
      nl: 'stoornis',
      en: 'disorder',
      de: 'Störung',
    ),
    _ => LocalizedText(nl: kind, en: kind, de: kind),
  };

  static const draftBadge = LocalizedText(
    nl: 'Concept',
    en: 'Draft',
    de: 'Entwurf',
  );
  static const draftBadgeLong = LocalizedText(
    nl: 'Concept, nog niet gecontroleerd',
    en: 'Draft, not verified yet',
    de: 'Entwurf, noch nicht geprüft',
  );

  // ── onboarding ────────────────────────────────────────────────────────────
  static const skip = LocalizedText(
    nl: 'Overslaan',
    en: 'Skip',
    de: 'Überspringen',
  );
  static const alreadyHaveAccount = LocalizedText(
    nl: 'Heb je al een account? Inloggen',
    en: 'Already have an account? Sign in',
    de: 'Schon ein Konto? Anmelden',
  );
  static const seasonAsOnePath = LocalizedText(
    nl: 'Je seizoen, als één pad',
    en: 'Your season, as one path',
    de: 'Deine Saison als ein Pfad',
  );
  static const seasonAsOnePathBody = LocalizedText(
    nl:
        'Zaaien, verpotten, oogsten, de vorstdatums die dat bepalen, en de '
        'maanden waarin nog niets gepland staat. Vink een stap af en alles '
        'daarna schuift met je mee.',
    en:
        'Sowing, potting on, harvest, the frost dates that govern them, and '
        'the months when nothing is planned yet. Tick a step off and '
        'everything after it moves with you.',
    de: 'Säen, umtopfen, ernten, die Frostdaten, die das alles bestimmen, und die Monate, in denen noch nichts geplant ist. Hak einen Schritt ab, und alles danach zieht mit.',
  );
  static const frostBackbone = LocalizedText(
    nl:
        'Bepaalt je vorstdatums, de basis onder elke plantdatum. Afgerond op '
        '~1 km, nooit gevolgd.',
    en:
        'Sets your frost dates, the backbone of every planting date. Rounded '
        'to ~1 km, never tracked.',
    de: 'Bestimmt deine Frostdaten, die Grundlage jedes Pflanztermins. Auf ~1 km gerundet, nie verfolgt.',
  );
  static const whatWillYouGrow = LocalizedText(
    nl: 'Wat ga je kweken?',
    en: 'What will you grow?',
    de: 'Was willst du anbauen?',
  );
  static const pickAFewToStart = LocalizedText(
    nl: 'Kies er een paar om te beginnen. Later bijzetten kan altijd.',
    en: 'Pick a few to start. Add more anytime.',
    de: 'Wähl ein paar für den Anfang. Mehr geht jederzeit.',
  );
  static const remindBlurb = LocalizedText(
    nl:
        'Een zetje op de dag zelf? Eén herinnering per ochtend, alleen als er '
        'iets te doen is, en stil als het geregend heeft.',
    en:
        'Want a nudge on the day? One reminder a morning, only when there is '
        'something to do, and it stays quiet when it rained.',
    de: 'Ein kleiner Stups am richtigen Tag? Eine Erinnerung am Morgen, nur wenn etwas zu tun ist, und still, wenn es geregnet hat.',
  );
  static const remindMe = LocalizedText(
    nl: 'Herinner me',
    en: 'Remind me',
    de: 'Erinnere mich',
  );
  static const maybeLater = LocalizedText(
    nl: 'Misschien later',
    en: 'Maybe later',
    de: 'Vielleicht später',
  );

  // ── the paywall's headline ────────────────────────────────────────────────
  static const oneFreeGarden = LocalizedText(
    nl: 'Eén gratis tuin,\nvoor altijd.',
    en: 'One free garden,\nfree forever.',
    de: 'Ein Garten gratis,\nfür immer.',
  );

  // ── odds and ends ─────────────────────────────────────────────────────────
  static const whatToGrowShort = LocalizedText(
    nl: 'Wat te zaaien in…',
    en: 'What to grow in…',
    de: 'Was anbauen im…',
  );
  static const whichPlant = LocalizedText(
    nl: 'Welke plant?',
    en: 'Which plant?',
    de: 'Welche Pflanze?',
  );
  static LocalizedText plantIn(String months) => LocalizedText(
    nl: 'Planten in: $months',
    en: 'Plant in: $months',
    de: 'Pflanzzeit: $months',
  );
  static LocalizedText sources(String list) => LocalizedText(
    nl: 'Bronnen: $list',
    en: 'Sources: $list',
    de: 'Quellen: $list',
  );
  static LocalizedText frostRelative(
    String anchor,
    String region,
  ) => LocalizedText(
    nl:
        'Deze data zijn vorst-relatief (gekoppeld aan $anchor voor $region), '
        'dus ze schuiven mee met je regio in plaats van met een vaste kalender.',
    en:
        'These dates are frost-relative (anchored to $anchor for $region), '
        'so they shift with your region, not a fixed calendar.',
    de:
        'Diese Daten richten sich nach dem Frost (verankert an $anchor für '
        '$region), darum verschieben sie sich mit deiner Region statt mit '
        'einem festen Kalender.',
  );
  static LocalizedText firstHarvestAround(
    String region,
    String date,
  ) => LocalizedText(
    nl:
        'In $region ligt je eerste oogst rond $date, berekend uit de '
        'vorstdatums van de regio.',
    en:
        'At $region, your first harvest lands around $date, computed from '
        "the region's frost dates.",
    de:
        'In $region liegt deine erste Ernte um den $date, berechnet aus den '
        'Frostdaten der Region.',
  );

  // ── the weather card on Home ──────────────────────────────────────────────
  static const weatherToday = LocalizedText(
    nl: 'Het weer vandaag',
    en: "Today's weather",
    de: 'Wetter heute',
  );
  static LocalizedText weatherRange(int high, int low) => LocalizedText(
    nl: '$high° / $low°',
    en: '$high° / $low°',
    de: '$high° / $low°',
  );
  static LocalizedText weatherRain(String mm) =>
      LocalizedText(nl: '$mm mm regen', en: '$mm mm rain', de: '$mm mm Regen');
  static const weatherDry = LocalizedText(
    nl: 'Droog',
    en: 'Dry',
    de: 'Trocken',
  );
  static const weatherNothingMoved = LocalizedText(
    nl: 'Het weer verzet vandaag niets.',
    en: 'The weather moves nothing today.',
    de: 'Das Wetter verschiebt heute nichts.',
  );
  static const weatherUnavailable = LocalizedText(
    nl: 'Geen weerbericht. Het basisschema staat.',
    en: 'No forecast. The base schedule stands.',
    de: 'Keine Vorhersage. Der Grundplan steht.',
  );

  /// Open-Meteo WMO condition groups, named for the card and the strip.
  static const weatherClear = LocalizedText(
    nl: 'Helder',
    en: 'Clear',
    de: 'Klar',
  );
  static const weatherPartlyCloudy = LocalizedText(
    nl: 'Half bewolkt',
    en: 'Partly cloudy',
    de: 'Teils bewölkt',
  );
  static const weatherOvercast = LocalizedText(
    nl: 'Bewolkt',
    en: 'Overcast',
    de: 'Bedeckt',
  );
  static const weatherFog = LocalizedText(nl: 'Mist', en: 'Fog', de: 'Nebel');
  static const weatherDrizzle = LocalizedText(
    nl: 'Motregen',
    en: 'Drizzle',
    de: 'Nieselregen',
  );
  static const weatherRainy = LocalizedText(
    nl: 'Regen',
    en: 'Rain',
    de: 'Regen',
  );
  static const weatherSnow = LocalizedText(
    nl: 'Sneeuw',
    en: 'Snow',
    de: 'Schnee',
  );
  static const weatherThunder = LocalizedText(
    nl: 'Onweer',
    en: 'Thunder',
    de: 'Gewitter',
  );

  // ── the path's new stops ──────────────────────────────────────────────────
  static const pathChecklistCaption = LocalizedText(
    nl: 'Klusje voor deze maand',
    en: 'A job for this month',
    de: 'Eine Aufgabe für diesen Monat',
  );
  static LocalizedText pathCompanion(LocalizedText partner) => LocalizedText(
    nl: 'Zet ${partner.nl} erbij',
    en: 'Plant ${partner.en} alongside',
    de: '${partner.pick('de')} dazupflanzen',
  );
  static LocalizedText pathCompanionCaption(LocalizedText have) =>
      LocalizedText(
        nl: 'Goede buur voor je ${have.nl}',
        en: 'A good neighbour for your ${have.en}',
        de: 'Ein guter Nachbar für ${have.pick('de')}',
      );
  static const pathCollectionCaption = LocalizedText(
    nl: 'Een lijstje om uit te kiezen',
    en: 'A list to pick from',
    de: 'Eine Liste zum Auswählen',
  );

  // ── the settings hub ──────────────────────────────────────────────────────
  static const accessibility = LocalizedText(
    nl: 'Toegankelijkheid',
    en: 'Accessibility',
    de: 'Bedienungshilfen',
  );
  static const hapticsTitle = LocalizedText(
    nl: 'Trillingen',
    en: 'Haptics',
    de: 'Haptik',
  );
  static const hapticsBlurb = LocalizedText(
    nl: 'Een korte trilling bij afvinken en indrukken.',
    en: 'A short buzz when you tick something off or press it.',
    de: 'Ein kurzes Vibrieren, wenn du etwas abhakst oder drückst.',
  );
  static const reduceMotionTitle = LocalizedText(
    nl: 'Minder beweging',
    en: 'Reduce motion',
    de: 'Bewegung reduzieren',
  );
  static const reduceMotionBlurb = LocalizedText(
    nl:
        'Animaties worden een directe wissel. Staat ook aan als je telefoon '
        'erom vraagt.',
    en:
        'Animations become an instant change. Also on when your phone asks '
        'for it.',
    de: 'Animationen werden zu einem sofortigen Wechsel. Auch an, wenn dein Handy das verlangt.',
  );
  static const gardenProfile = LocalizedText(
    nl: 'Je tuin aanpassen',
    en: 'Edit your garden',
    de: 'Garten bearbeiten',
  );
  static const gardenProfileBlurb = LocalizedText(
    nl: 'Verhuisd, of meer ruimte gevonden?',
    en: 'Moved house, or found more room?',
    de: 'Umgezogen oder mehr Platz gefunden?',
  );
  static const gardenSize = LocalizedText(
    nl: 'Oppervlakte',
    en: 'Size',
    de: 'Größe',
  );
  static LocalizedText gardenSizeM2(int m2) =>
      LocalizedText(nl: '$m2 m²', en: '$m2 m²', de: '$m2 m²');
  static const gardenSizeHint = LocalizedText(
    nl: 'Hoeveel vierkante meter heb je om te telen?',
    en: 'How many square metres do you have to grow in?',
    de: 'Wie viele Quadratmeter hast du zum Anbauen?',
  );
  static const sunHoursLabel = LocalizedText(
    nl: 'Uren zon',
    en: 'Hours of sun',
    de: 'Sonnenstunden',
  );
  static const sunHoursHint = LocalizedText(
    nl: 'Op een heldere dag in juni.',
    en: 'On a clear day in June.',
    de: 'An einem klaren Tag im Juni.',
  );
  static const gardenSaved = LocalizedText(
    nl: 'Tuin bijgewerkt',
    en: 'Garden updated',
    de: 'Garten aktualisiert',
  );
  static const faq = LocalizedText(
    nl: 'Veelgestelde vragen',
    en: 'Frequently asked questions',
    de: 'Häufige Fragen',
  );
  static const helpAndSupport = LocalizedText(
    nl: 'Help en ondersteuning',
    en: 'Help & support',
    de: 'Hilfe & Support',
  );
  static const notSignedIn = LocalizedText(
    nl: 'Niet aangemeld',
    en: 'Not signed in',
    de: 'Nicht angemeldet',
  );
  static const onThisDevice = LocalizedText(
    nl: 'Op deze telefoon',
    en: 'On this phone',
    de: 'Auf diesem Handy',
  );

  // ── searching the problems ────────────────────────────────────────────────
  static const searchProblems = LocalizedText(
    nl: 'Zoek een probleem',
    en: 'Search a problem',
    de: 'Problem suchen',
  );
  static LocalizedText problemsFound(int n) => LocalizedText(
    nl: '$n ${n == 1 ? 'probleem' : 'problemen'}',
    en: '$n problem${n == 1 ? '' : 's'}',
    de: '$n ${n == 1 ? 'Problem' : 'Probleme'}',
  );
  static const noProblemsFound = LocalizedText(
    nl: 'Niets gevonden. Probeer een ander woord.',
    en: 'Nothing found. Try another word.',
    de: 'Nichts gefunden. Versuch ein anderes Wort.',
  );

  // ── the path's milestone stops (what the gardener already did) ────────────
  static const pathFirstSow = LocalizedText(
    nl: 'Je eerste zaaisel',
    en: 'Your first sowing',
    de: 'Deine erste Aussaat',
  );
  static LocalizedText pathFirstSowCaption(LocalizedText crop) => LocalizedText(
    nl: 'Het seizoen begon met ${crop.nl}',
    en: 'The season began with ${crop.en}',
    de: 'Die Saison begann mit ${crop.pick('de')}',
  );
  static LocalizedText pathHarvest(int n) => LocalizedText(
    nl: 'Oogst nummer $n',
    en: 'Harvest number $n',
    de: 'Ernte Nummer $n',
  );
  static LocalizedText pathHarvestCaption(LocalizedText crop) => LocalizedText(
    nl: 'Geplukt: ${crop.nl}',
    en: 'Picked: ${crop.en}',
    de: 'Geerntet: ${crop.pick('de')}',
  );
  static LocalizedText pathStreak(int days) => LocalizedText(
    nl: '$days dagen op rij',
    en: '$days days in a row',
    de: '$days Tage in Folge',
  );
  static const pathStreakCaption = LocalizedText(
    nl: 'Je hield het vol',
    en: 'You kept it going',
    de: 'Du bist drangeblieben',
  );
  static const pathPhotoCompare = LocalizedText(
    nl: 'Kijk hoe ver het is',
    en: 'See how far it has come',
    de: 'Sieh, wie weit sie gekommen ist',
  );
  static LocalizedText pathPhotoCompareCaption(LocalizedText month) =>
      LocalizedText(
        nl: 'Naast je foto van ${month.nl}',
        en: 'Next to your photo from ${month.en}',
        de: 'Neben deinem Foto vom ${month.pick('de')}',
      );

  // ── reminders ─────────────────────────────────────────────────────────────
  static const reminderOneThing = LocalizedText(
    nl: 'Eén ding te doen vandaag',
    en: 'One thing to do today',
    de: 'Heute ist eine Sache zu tun',
  );
  static LocalizedText reminderThings(int n) => LocalizedText(
    nl: '$n dingen te doen vandaag',
    en: '$n things to do today',
    de: 'Heute sind $n Sachen zu tun',
  );

  // ── months, for every sentence that names one ─────────────────────────────
  static const months = <LocalizedText>[
    LocalizedText(nl: 'januari', en: 'January', de: 'Januar'),
    LocalizedText(nl: 'februari', en: 'February', de: 'Februar'),
    LocalizedText(nl: 'maart', en: 'March', de: 'März'),
    LocalizedText(nl: 'april', en: 'April', de: 'April'),
    LocalizedText(nl: 'mei', en: 'May', de: 'Mai'),
    LocalizedText(nl: 'juni', en: 'June', de: 'Juni'),
    LocalizedText(nl: 'juli', en: 'July', de: 'Juli'),
    LocalizedText(nl: 'augustus', en: 'August', de: 'August'),
    LocalizedText(nl: 'september', en: 'September', de: 'September'),
    LocalizedText(nl: 'oktober', en: 'October', de: 'Oktober'),
    LocalizedText(nl: 'november', en: 'November', de: 'November'),
    LocalizedText(nl: 'december', en: 'December', de: 'Dezember'),
  ];

  /// The month's name, capitalised for a heading. Dutch writes months in lower
  /// case inside a sentence, so the capital belongs to the caller.
  static LocalizedText month(int month1to12) => months[month1to12 - 1];

  static LocalizedText monthTitle(int month1to12) {
    final m = months[month1to12 - 1];
    String up(String s) => s[0].toUpperCase() + s.substring(1);
    return LocalizedText(nl: up(m.nl), en: m.en, de: m.pick('de'));
  }

  /// Three letters, for a marker on the path.
  static LocalizedText monthShort(int month1to12) {
    final m = months[month1to12 - 1];
    return LocalizedText(
      nl: m.nl.substring(0, 3).toUpperCase(),
      en: m.en.substring(0, 3).toUpperCase(),
      de: m.pick('de').substring(0, 3).toUpperCase(),
    );
  }
}
