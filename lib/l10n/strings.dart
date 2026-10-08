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
  static const tabHome = LocalizedText(
    nl: 'Home',
    en: 'Home',
    de: 'Home',
    fr: 'Accueil',
  );
  static const tabGarden = LocalizedText(
    nl: 'Mijn tuin',
    en: 'My garden',
    de: 'Mein Garten',
    fr: 'Mon potager',
  );
  static const tabSeason = LocalizedText(
    nl: 'Seizoenspad',
    en: 'Season path',
    de: 'Saisonpfad',
    fr: 'Parcours',
  );
  static const tabExplore = LocalizedText(
    nl: 'Ontdek',
    en: 'Explore',
    de: 'Entdecken',
    fr: 'Explorer',
  );
  static const tabDiagnose = LocalizedText(
    nl: 'Diagnose',
    en: 'Diagnose',
    de: 'Diagnose',
    fr: 'Diagnostic',
  );

  // ── home ──────────────────────────────────────────────────────────────────
  static const greeting = LocalizedText(
    nl: 'Hoi',
    en: 'Hey there',
    de: 'Hallo',
    fr: 'Salut',
  );
  static LocalizedText greetingNamed(String name) => LocalizedText(
    nl: 'Hoi, $name',
    en: 'Hey, $name',
    de: 'Hallo, $name',
    fr: 'Salut, $name',
  );
  static const greetingSub = LocalizedText(
    nl: 'Dit staat er deze week in je tuin.',
    en: 'Here is your garden this week.',
    de: 'Das steht diese Woche in deinem Garten an.',
    fr: 'Voici ton potager cette semaine.',
  );
  static const searchCrops = LocalizedText(
    nl: 'Zoek groenten',
    en: 'Search vegetables',
    de: 'Gemüse suchen',
    fr: 'Chercher un légume',
  );
  static LocalizedText todaysCare(int open) => LocalizedText(
    nl: 'Vandaag te doen ($open)',
    en: "Today's care ($open)",
    de: 'Heute zu tun ($open)',
    fr: 'À faire aujourd\'hui ($open)',
  );
  static LocalizedText upcomingHarvest(int n) => LocalizedText(
    nl: 'Binnenkort oogsten ($n)',
    en: 'Upcoming harvest ($n)',
    de: 'Bald ernten ($n)',
    fr: 'Récolte bientôt ($n)',
  );
  static LocalizedText whatToGrow(LocalizedText month) => LocalizedText(
    nl: 'Wat te zaaien in ${month.nl}',
    en: 'What to grow in ${month.en}',
    de: 'Was anbauen im ${month.pick('de')}',
    fr: 'Que cultiver en ${month.pick('fr')}',
  );
  static LocalizedText checklistFor(LocalizedText month) => LocalizedText(
    nl: 'Checklist voor ${month.nl}',
    en: 'Checklist for ${month.en}',
    de: 'Checkliste für ${month.pick('de')}',
    fr: 'À faire en ${month.pick('fr')}',
  );
  static const unlockLifetime = LocalizedText(
    nl: 'Levenslang, één prijs, voorgoed',
    en: 'Unlock lifetime, one price, forever',
    de: 'Lifetime freischalten: ein Preis, für immer',
    fr: 'Débloque Lifetime : un seul prix, pour toujours',
  );
  static const startStreak = LocalizedText(
    nl: 'Begin vandaag een reeks',
    en: 'Start a streak today',
    de: 'Starte heute eine Serie',
    fr: 'Lance une série aujourd\'hui',
  );
  static LocalizedText streakDays(int days) => LocalizedText(
    nl: '$days ${days == 1 ? 'dag' : 'dagen'} op rij',
    en: '$days-day streak',
    de: '$days ${days == 1 ? 'Tag' : 'Tage'} in Folge',
    fr: '$days ${days <= 1 ? 'jour' : 'jours'} d\'affilée',
  );

  // ── the season path ───────────────────────────────────────────────────────
  static const season = LocalizedText(
    nl: 'Seizoen',
    en: 'Season',
    de: 'Saison',
    fr: 'Saison',
  );
  static LocalizedText yearInGarden(int year) => LocalizedText(
    nl: '$year in jouw tuin',
    en: '$year in your garden',
    de: '$year in deinem Garten',
    fr: '$year dans ton potager',
  );
  static const today = LocalizedText(
    nl: 'Vandaag',
    en: 'Today',
    de: 'Heute',
    fr: 'Aujourd\'hui',
  );
  static const tomorrow = LocalizedText(
    nl: 'Morgen',
    en: 'Tomorrow',
    de: 'Morgen',
    fr: 'Demain',
  );
  static LocalizedText stepPlannedOn(LocalizedText step, String day) =>
      LocalizedText(
        nl: '${step.nl} · gepland $day',
        en: '${step.en} · planned $day',
        de: '${step.pick('de')} · geplant am $day',
        fr: '${step.pick('fr')} · prévu le $day',
      );
  static const nothingToDoToday = LocalizedText(
    nl: 'Niets te doen vandaag. Geniet ervan.',
    en: 'Nothing to do today. Enjoy it.',
    de: 'Heute nichts zu tun. Genieß es.',
    fr: 'Rien à faire aujourd\'hui. Profites-en.',
  );
  static LocalizedText thingsToDoToday(int n) => LocalizedText(
    nl: n == 1 ? 'Eén ding te doen vandaag.' : '$n dingen te doen vandaag.',
    en: n == 1 ? '1 thing to do today.' : '$n things to do today.',
    de: n == 1 ? 'Heute steht 1 Aufgabe an.' : 'Heute stehen $n Aufgaben an.',
    fr: n <= 1
        ? '$n chose à faire aujourd\'hui.'
        : '$n choses à faire aujourd\'hui.',
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
    fr:
        'Ça retire $name de ton potager. Les récoltes que tu as déjà notées '
        'restent dans l\'historique de ta saison.',
  );
  static const symptoms = LocalizedText(
    nl: 'Symptomen',
    en: 'Symptoms',
    de: 'Symptome',
    fr: 'Symptômes',
  );
  static const pickSomething = LocalizedText(
    nl: 'Kies iets ',
    en: 'Pick something ',
    de: 'Wähl etwas ',
    fr: 'Choisis quelque chose ',
  );
  static const toGrow = LocalizedText(
    nl: 'om te telen',
    en: 'to grow',
    de: 'zum Anbauen',
    fr: 'à cultiver',
  );
  static const minSoilTemp = LocalizedText(
    nl: 'Min. bodemtemperatuur',
    en: 'Min soil temp',
    de: 'Min. Bodentemp.',
    fr: 'Temp. du sol min.',
  );
  static const minPotSize = LocalizedText(
    nl: 'Min. potmaat',
    en: 'Min pot size',
    de: 'Min. Topfgröße',
    fr: 'Taille de pot min.',
  );
  static const containerFriendly = LocalizedText(
    nl: 'Geschikt voor potten',
    en: 'Container-friendly',
    de: 'Topfgeeignet',
    fr: 'Convient en pot',
  );
  static const yes = LocalizedText(nl: 'Ja', en: 'Yes', de: 'Ja', fr: 'Oui');
  static const balconySuitability = LocalizedText(
    nl: 'Geschikt voor NL-balkon',
    en: 'NL balcony suitability',
    de: 'Eignung für NL-Balkone',
    fr: 'Adaptation aux balcons NL',
  );
  static const balconyGreat = LocalizedText(
    nl: 'Prima',
    en: 'Great',
    de: 'Super',
    fr: 'Parfait',
  );
  static const balconyAfterIjsheiligen = LocalizedText(
    nl: 'Goed na de ijsheiligen',
    en: 'Good after IJsheiligen',
    de: 'Gut nach den Eisheiligen',
    fr: 'Bien après les saints de glace',
  );
  static const balconyNeedsBed = LocalizedText(
    nl: 'Heeft een bed nodig',
    en: 'Needs a bed',
    de: 'Braucht ein Beet',
    fr: 'Demande un carré',
  );
  static const moveBackToPlanning = LocalizedText(
    nl: 'Terug naar gepland',
    en: 'Move back to planning',
    de: 'Zurück in die Planung',
    fr: 'Remettre en planification',
  );
  static const removeFromGarden = LocalizedText(
    nl: 'Uit de tuin halen',
    en: 'Remove from garden',
    de: 'Aus dem Garten entfernen',
    fr: 'Retirer du potager',
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
    fr:
        'Ça retire $name de ton potager. Les récoltes notées restent dans '
        'l\'historique de ta saison.',
  );
  static const tapPlanToGrow = LocalizedText(
    nl: 'Tik op "Wil ik telen" bij een gewas om het hier te zetten.',
    en: 'Tap "Plan to grow" on any crop to add it here.',
    de: 'Tippe bei einer Pflanze auf „Einplanen“, um sie hier hinzuzufügen.',
    fr: 'Touche « Planifier » sur une plante pour l\'ajouter ici.',
  );
  static const tapGrowingIt = LocalizedText(
    nl: 'Tik op "Staat er al" bij een gewas, of start een gepland gewas.',
    en: 'Tap "Growing it" on a crop, or start a planned one.',
    de: 'Tippe bei einer Pflanze auf „Wächst schon“ oder starte eine geplante.',
    fr: 'Touche « Déjà planté » sur une plante, ou démarre une plante planifiée.',
  );
  static const sowIndoors = LocalizedText(
    nl: 'Binnen zaaien',
    en: 'Sow indoors',
    de: 'Vorziehen',
    fr: 'Semer en intérieur',
  );
  static const plantOut = LocalizedText(
    nl: 'Uitplanten',
    en: 'Plant out',
    de: 'Auspflanzen',
    fr: 'Repiquer',
  );
  static const sowOutdoors = LocalizedText(
    nl: 'Buiten zaaien',
    en: 'Sow outdoors',
    de: 'Draußen säen',
    fr: 'Semer en extérieur',
  );
  static const treatmentOrganicFirst = LocalizedText(
    nl: 'Aanpak (biologisch eerst)',
    en: 'Treatment (organic first)',
    de: 'Behandlung (zuerst biologisch)',
    fr: 'Traitement (bio d\'abord)',
  );
  static const prevention = LocalizedText(
    nl: 'Voorkomen',
    en: 'Prevention',
    de: 'Vorbeugung',
    fr: 'Prévention',
  );
  static const lastFrostRow = LocalizedText(
    nl: 'Laatste vorst',
    en: 'Last frost',
    de: 'Letzter Frost',
    fr: 'Dernières gelées',
  );
  static const firstFrostRow = LocalizedText(
    nl: 'Eerste vorst',
    en: 'First frost',
    de: 'Erster Frost',
    fr: 'Premières gelées',
  );
  static const preferredSun = LocalizedText(
    nl: 'Voorkeur zon',
    en: 'Preferred sun',
    de: 'Lichtbedarf',
    fr: 'Ensoleillement',
  );
  static const frostTender = LocalizedText(
    nl: 'Vorstgevoelig',
    en: 'Frost tender',
    de: 'Frostempfindlich',
    fr: 'Sensible au gel',
  );
  static const yesWaitForLastFrost = LocalizedText(
    nl: 'Ja, wacht op de laatste vorst',
    en: 'Yes, wait for last frost',
    de: 'Ja, letzten Frost abwarten',
    fr: 'Oui, attends les dernières gelées',
  );
  static const no = LocalizedText(nl: 'Nee', en: 'No', de: 'Nein', fr: 'Non');

  static const empty = LocalizedText(nl: '', en: '', de: '', fr: '');
  static const sow = LocalizedText(
    nl: 'Zaaien',
    en: 'Sow',
    de: 'Säen',
    fr: 'Semer',
  );
  static const startIndoors = LocalizedText(
    nl: 'Binnen starten',
    en: 'Start indoors',
    de: 'Vorziehen',
    fr: 'Semer en intérieur',
  );
  static const plantOutside = LocalizedText(
    nl: 'Buiten planten',
    en: 'Plant outside',
    de: 'Auspflanzen',
    fr: 'Repiquer',
  );
  static const easyFilter = LocalizedText(
    nl: 'Makkelijk',
    en: 'Easy',
    de: 'Einfach',
    fr: 'Facile',
  );
  static const whatIsWrongHere = LocalizedText(
    nl: 'Wat klopt hier niet?',
    en: 'What is wrong here?',
    de: 'Was stimmt hier nicht?',
    fr: 'Qu\'est-ce qui ne va pas ici ?',
  );
  static const whatWouldBeBetter = LocalizedText(
    nl: 'Wat zou dit beter maken?',
    en: 'What would make this better?',
    de: 'Was würde es besser machen?',
    fr: 'Qu\'est-ce qui rendrait ça meilleur ?',
  );
  static const climateNormals = LocalizedText(
    nl: 'KNMI/Open-Meteo klimaatnormalen',
    en: 'KNMI/Open-Meteo climate normals',
    de: 'KNMI/Open-Meteo-Klimamittel',
    fr: 'Normales climatiques KNMI/Open-Meteo',
  );
  static const regionalPreset = LocalizedText(
    nl: 'NL regiovoorinstelling',
    en: 'NL regional preset',
    de: 'NL-Regionalvorgabe',
    fr: 'Préréglage régional NL',
  );

  /// The crop data's own sun values, said in words.
  static LocalizedText sunNeed(String value) => switch (value) {
    'full' => const LocalizedText(
      nl: 'volle zon',
      en: 'full sun',
      de: 'volle Sonne',
      fr: 'plein soleil',
    ),
    'partial' => const LocalizedText(
      nl: 'halfschaduw',
      en: 'partial',
      de: 'Halbschatten',
      fr: 'mi-ombre',
    ),
    'shade-tolerant' => const LocalizedText(
      nl: 'verdraagt schaduw',
      en: 'shade-tolerant',
      de: 'schattenverträglich',
      fr: 'tolère l\'ombre',
    ),
    _ => LocalizedText(nl: value, en: value, de: value, fr: value),
  };
  static LocalizedText daysToHarvest(num min, num max) => LocalizedText(
    nl: '$min-$max dagen',
    en: '$min-$max days',
    de: '$min-$max Tage',
    fr: '$min-$max jours',
  );
  static const stageSprout = LocalizedText(
    nl: 'Kiem',
    en: 'Sprout',
    de: 'Keimling',
    fr: 'Pousse',
  );
  static const dayOne = LocalizedText(
    nl: 'Dag 1',
    en: 'Day 1',
    de: 'Tag 1',
    fr: 'Jour 1',
  );
  static LocalizedText dayRange(num from, num to) => LocalizedText(
    nl: 'Dag $from-$to',
    en: 'Day $from-$to',
    de: 'Tag $from-$to',
    fr: 'Jour $from-$to',
  );
  static const enoughRainBadge = LocalizedText(
    nl: 'Genoeg regen',
    en: 'Enough rain',
    de: 'Genug Regen',
    fr: 'Assez de pluie',
  );
  static const heatComingBadge = LocalizedText(
    nl: 'Hitte op komst',
    en: 'Heat coming',
    de: 'Hitze kommt',
    fr: 'Chaleur en vue',
  );
  static const soilTooColdBadge = LocalizedText(
    nl: 'Grond te koud',
    en: 'Soil too cold',
    de: 'Boden zu kalt',
    fr: 'Sol trop froid',
  );
  static const gardenKindBalcony = LocalizedText(
    nl: 'Balkon',
    en: 'Balcony',
    de: 'Balkon',
    fr: 'Balcon',
  );
  static const gardenKindGarden = LocalizedText(
    nl: 'Tuin',
    en: 'Garden',
    de: 'Garten',
    fr: 'Jardin',
  );
  static const gardenKindAllotment = LocalizedText(
    nl: 'Volkstuin',
    en: 'Allotment',
    de: 'Kleingarten',
    fr: 'Jardin familial',
  );
  static const contactUs = LocalizedText(
    nl: 'Contact',
    en: 'Contact us',
    de: 'Kontakt',
    fr: 'Nous contacter',
  );
  static const privacy = LocalizedText(
    nl: 'Privacy',
    en: 'Privacy',
    de: 'Datenschutz',
    fr: 'Confidentialité',
  );
  static const terms = LocalizedText(
    nl: 'Voorwaarden',
    en: 'Terms',
    de: 'AGB',
    fr: 'Conditions',
  );
  static const yourHarvests = LocalizedText(
    nl: 'Jouw oogsten',
    en: 'Your harvests',
    de: 'Deine Ernten',
    fr: 'Tes récoltes',
  );
  static const placeGround = LocalizedText(
    nl: 'In de volle grond',
    en: 'In the ground',
    de: 'Im Boden',
    fr: 'En pleine terre',
  );
  static const placeRaisedBed = LocalizedText(
    nl: 'Verhoogde bak',
    en: 'Raised bed',
    de: 'Hochbeet',
    fr: 'Carré potager',
  );
  static const placePotOutside = LocalizedText(
    nl: 'Pot buiten',
    en: 'Pot outside',
    de: 'Topf draußen',
    fr: 'Pot dehors',
  );
  static const placePotInside = LocalizedText(
    nl: 'Pot binnen',
    en: 'Pot inside',
    de: 'Topf drinnen',
    fr: 'Pot dedans',
  );
  static const methodSowedIndoors = LocalizedText(
    nl: 'Binnen gezaaid',
    en: 'Sowed indoors',
    de: 'Vorgezogen',
    fr: 'Semé en intérieur',
  );
  static const methodSowedOutside = LocalizedText(
    nl: 'Buiten gezaaid',
    en: 'Sowed outside',
    de: 'Draußen gesät',
    fr: 'Semé en extérieur',
  );
  static const methodPlantedSeedling = LocalizedText(
    nl: 'Zaailing geplant',
    en: 'Planted a seedling',
    de: 'Jungpflanze gesetzt',
    fr: 'Plant mis en terre',
  );
  static const methodPlantedSets = LocalizedText(
    nl: 'Geplant (bollen / knollen)',
    en: 'Planted (sets / tubers)',
    de: 'Gesteckt (Zwiebeln / Knollen)',
    fr: 'Planté (bulbilles / tubercules)',
  );
  // ── the how-tos table ─────────────────────────────────────────────────────
  static const sowDepth = LocalizedText(
    nl: 'Zaaidiepte',
    en: 'Sow depth',
    de: 'Saattiefe',
    fr: 'Profondeur de semis',
  );
  static const germination = LocalizedText(
    nl: 'Kieming',
    en: 'Germination',
    de: 'Keimung',
    fr: 'Germination',
  );
  static const plantOutAfter = LocalizedText(
    nl: 'Uitplanten na',
    en: 'Plant out after',
    de: 'Auspflanzen nach',
    fr: 'Repiquer après',
  );
  static const spacing = LocalizedText(
    nl: 'Plantafstand',
    en: 'Spacing',
    de: 'Abstand',
    fr: 'Espacement',
  );
  static const perSquare = LocalizedText(
    nl: 'Per vak van 30 cm',
    en: 'Per 30 cm square',
    de: 'Pro 30-cm-Quadrat',
    fr: 'Par carré de 30 cm',
  );
  static const care = LocalizedText(
    nl: 'Verzorging',
    en: 'Care',
    de: 'Pflege',
    fr: 'Entretien',
  );
  static const waterSmallPot = LocalizedText(
    nl: 'Water (kleine pot)',
    en: 'Water (small pot)',
    de: 'Gießen (kleiner Topf)',
    fr: 'Arrosage (petit pot)',
  );
  static const waterInGround = LocalizedText(
    nl: 'Water (volle grond)',
    en: 'Water (in ground)',
    de: 'Gießen (im Boden)',
    fr: 'Arrosage (pleine terre)',
  );
  static const feed = LocalizedText(
    nl: 'Bijmesten',
    en: 'Feed',
    de: 'Düngen',
    fr: 'Fertiliser',
  );
  static const perennial = LocalizedText(
    nl: 'Meerjarig',
    en: 'Perennial',
    de: 'Mehrjährig',
    fr: 'Vivace',
  );
  static const firstHarvest = LocalizedText(
    nl: 'Eerste oogst',
    en: 'First harvest',
    de: 'Erste Ernte',
    fr: 'Première récolte',
  );
  static LocalizedText aboutDays(int n) => LocalizedText(
    nl: '~$n dagen',
    en: '~$n days',
    de: '~$n Tage',
    fr: '~$n ${n <= 1 ? 'jour' : 'jours'}',
  );
  static LocalizedText daysIndoors(int n) => LocalizedText(
    nl: '~$n dagen binnen',
    en: '~$n days indoors',
    de: '~$n Tage drinnen',
    fr: '~$n ${n <= 1 ? 'jour' : 'jours'} en intérieur',
  );
  static LocalizedText everyDays(int n) => LocalizedText(
    nl: n == 1 ? 'elke dag' : 'elke $n dagen',
    en: n == 1 ? 'every 1 day' : 'every $n days',
    de: n == 1 ? 'jeden Tag' : 'alle $n Tage',
    fr: n <= 1 ? 'chaque jour' : 'tous les $n jours',
  );
  static LocalizedText everyDaysEstablished(int n) => LocalizedText(
    nl: 'elke $n dagen zodra hij aanslaat',
    en: 'every $n days once established',
    de: 'alle $n Tage, sobald sie angewachsen ist',
    fr: 'tous les $n jours une fois installée',
  );
  static const comesBackNextYear = LocalizedText(
    nl: 'komt volgend jaar terug',
    en: 'comes back next year',
    de: 'kommt nächstes Jahr wieder',
    fr: 'revient l\'an prochain',
  );
  static LocalizedText daysAfterPlantOut(num min, num max) => LocalizedText(
    nl: '$min-$max dagen na het uitplanten',
    en: '$min-$max days after planting out',
    de: '$min-$max Tage nach dem Auspflanzen',
    fr: '$min-$max jours après le repiquage',
  );

  // ── onboarding chrome ─────────────────────────────────────────────────────
  static const heroKnowWhatToDo = LocalizedText(
    nl: 'Weet wat je\n',
    en: 'Know what to do\n',
    de: 'Wissen, was\n',
    fr: 'Sache quoi faire\n',
  );
  static const heroThisWeek = LocalizedText(
    nl: 'deze week',
    en: 'this week',
    de: 'diese Woche',
    fr: 'cette semaine',
  );
  static const heroInYourGarden = LocalizedText(
    nl: ' moet doen in je tuin.',
    en: ' in your garden.',
    de: ' im Garten ansteht.',
    fr: ' dans ton potager.',
  );
  static const heroSubtitle = LocalizedText(
    nl:
        'Plantdata en herinneringen afgestemd op het Nederlandse en Europese '
        'weer, gemaakt voor balkons en potten.',
    en:
        'Planting dates and reminders tuned to Dutch and EU weather, built for '
        'balconies and containers.',
    de: 'Pflanztermine und Erinnerungen, abgestimmt auf niederländisches und EU-Wetter, gemacht für Balkone und Töpfe.',
    fr: 'Des dates de plantation et des rappels adaptés à la météo des Pays-Bas et de l\'UE, pensés pour les balcons et les pots.',
  );
  static const getStarted = LocalizedText(
    nl: 'Beginnen',
    en: 'Get started',
    de: 'Los geht\'s',
    fr: 'C\'est parti',
  );
  static const continueLabel = LocalizedText(
    nl: 'Verder',
    en: 'Continue',
    de: 'Weiter',
    fr: 'Continuer',
  );
  static const datesCheckedTitle = LocalizedText(
    nl: 'Elke datum gelegd naast Nederlandse zaaikalenders',
    en: 'Every date checked against Dutch seed calendars',
    de: 'Jedes Datum mit niederländischen Aussaatkalendern abgeglichen',
    fr: 'Chaque date vérifiée dans des calendriers des semis néerlandais',
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
    fr: 'Chaque plante est vérifiée auprès d\'au moins deux sources néerlandaises, IVN, Tuinadvies, zaaitijden.nl et Groei & Bloei, avant d\'arriver chez toi. Et quand la vie s\'en mêle, le plan bouge avec toi. Rien n\'est jamais « trop tard ».',
  );
  static const getToKnowTitle = LocalizedText(
    nl: 'Hoi! Even kennismaken',
    en: "Hi! Let's get to know each other",
    de: 'Hallo! Lernen wir uns kennen',
    fr: 'Salut ! Faisons connaissance',
  );
  static const getToKnowBody = LocalizedText(
    nl:
        'Een paar korte vragen over je ruimte en wat je graag eet. Twee '
        'minuten, dan staat je plan klaar.',
    en:
        'A few quick questions about your space and what you like to eat. Two '
        'minutes, then your plan is ready.',
    de: 'Ein paar kurze Fragen zu deinem Platz und dazu, was du gern isst. Zwei Minuten, dann steht dein Plan.',
    fr: 'Quelques questions rapides sur ton espace et ce que tu aimes manger. Deux minutes, et ton plan est prêt.',
  );
  static const whatSpace = LocalizedText(
    nl: 'Welke ruimte heb je om te telen?',
    en: 'What space do you have to grow in?',
    de: 'Wo kannst du anbauen?',
    fr: 'Où peux-tu cultiver ?',
  );
  static const experienceReassure = LocalizedText(
    nl:
        'Mooi, dan beginnen we bij het begin. Je krijgt per stap te zien wat je '
        'moet doen, en waarom.',
    en:
        "Good — then we start at the beginning. You'll get every step as it "
        'comes, and the reason behind it.',
    de: 'Gut — dann fangen wir ganz vorne an. Du bekommst jeden Schritt, wenn er dran ist, und den Grund dazu.',
    fr: 'Très bien — on commence par le début. Tu auras chaque étape au bon moment, avec la raison derrière.',
  );
  static const pickAllThatApply = LocalizedText(
    nl: 'Kies alles wat past.',
    en: 'Pick all that apply.',
    de: 'Wähl alles, was passt.',
    fr: 'Choisis tout ce qui convient.',
  );
  static const spaceBackyard = LocalizedText(
    nl: 'Tuin',
    en: 'Garden',
    de: 'Garten',
    fr: 'Jardin',
  );
  static const spaceBalcony = LocalizedText(
    nl: 'Balkon',
    en: 'Balcony',
    de: 'Balkon',
    fr: 'Balcon',
  );
  static const spaceIndoor = LocalizedText(
    nl: 'Binnen',
    en: 'Indoors',
    de: 'Drinnen',
    fr: 'Intérieur',
  );
  static const spaceAllotment = LocalizedText(
    nl: 'Volkstuin',
    en: 'Allotment',
    de: 'Kleingarten',
    fr: 'Jardin familial',
  );
  static const spaceOther = LocalizedText(
    nl: 'Ergens anders',
    en: 'Somewhere else',
    de: 'Woanders',
    fr: 'Ailleurs',
  );
  static const howMuchSpace = LocalizedText(
    nl: 'Hoeveel ruimte?',
    en: 'How much space?',
    de: 'Wie viel Platz?',
    fr: 'Combien de place ?',
  );
  static const howMuchSpaceSub = LocalizedText(
    nl: 'Ongeveer, het bepaalt hoeveel planten passen.',
    en: 'Roughly, it sets how many plants fit.',
    de: 'Ungefähr, das bestimmt, wie viele Pflanzen passen.',
    fr: 'En gros, ça décide combien de plantes tiennent.',
  );
  static const howMuchSun = LocalizedText(
    nl: 'Hoeveel zon?',
    en: 'How much sun?',
    de: 'Wie viel Sonne?',
    fr: 'Combien de soleil ?',
  );
  static const howMuchSunSub = LocalizedText(
    nl: 'Op een heldere dag, hoe lang staat het in de volle zon?',
    en: 'On a clear day, how long is it in direct sun?',
    de: 'Wie lange scheint an einem klaren Tag die Sonne direkt hin?',
    fr: 'Par temps clair, combien de temps est-ce au soleil direct ?',
  );
  static const sunFull = LocalizedText(
    nl: 'Volle zon (6u+)',
    en: 'Full sun (6h+)',
    de: 'Volle Sonne (6h+)',
    fr: 'Plein soleil (6 h+)',
  );
  static const sunPartial = LocalizedText(
    nl: 'Halfschaduw (3-6u)',
    en: 'Partial (3-6h)',
    de: 'Halbschatten (3-6h)',
    fr: 'Mi-ombre (3-6 h)',
  );
  static const sunShade = LocalizedText(
    nl: 'Schaduw (< 3u)',
    en: 'Shade (< 3h)',
    de: 'Schatten (< 3h)',
    fr: 'Ombre (< 3 h)',
  );
  static const grownBefore = LocalizedText(
    nl: 'Eerder iets geteeld?',
    en: 'Grown anything before?',
    de: 'Schon mal etwas angebaut?',
    fr: 'Déjà cultivé quelque chose ?',
  );
  static const grownBeforeSub = LocalizedText(
    nl: 'Zo stemmen we het advies af.',
    en: 'So we pitch the advice right.',
    de: 'Damit unsere Tipps zu dir passen.',
    fr: 'Pour que nos conseils te correspondent.',
  );
  static const experienceNever = LocalizedText(
    nl: 'Nooit',
    en: 'Never',
    de: 'Nie',
    fr: 'Jamais',
  );
  static const experienceSome = LocalizedText(
    nl: 'Een seizoen of twee',
    en: 'A season or two',
    de: 'Ein, zwei Saisons',
    fr: 'Une saison ou deux',
  );
  static const experiencePlenty = LocalizedText(
    nl: 'Genoeg',
    en: 'Plenty',
    de: 'Viel',
    fr: 'Beaucoup',
  );
  static const whatDoYouEat = LocalizedText(
    nl: 'Wat eet je graag?',
    en: 'What do you like to eat?',
    de: 'Was isst du gern?',
    fr: 'Qu\'est-ce que tu aimes manger ?',
  );
  static const foodVegetables = LocalizedText(
    nl: 'Groente',
    en: 'Vegetables',
    de: 'Gemüse',
    fr: 'Légumes',
  );
  static const foodHerbs = LocalizedText(
    nl: 'Kruiden',
    en: 'Herbs',
    de: 'Kräuter',
    fr: 'Herbes aromatiques',
  );
  static const foodSalad = LocalizedText(
    nl: 'Slablad',
    en: 'Salad leaves',
    de: 'Blattsalate',
    fr: 'Salades',
  );
  static const foodFruit = LocalizedText(
    nl: 'Fruit',
    en: 'Fruit',
    de: 'Obst',
    fr: 'Fruits',
  );
  static const foodRoots = LocalizedText(
    nl: 'Wortelgroente',
    en: 'Root veg',
    de: 'Wurzelgemüse',
    fr: 'Légumes-racines',
  );
  static const whatMattersMost = LocalizedText(
    nl: 'Wat is het belangrijkst?',
    en: "What's most important?",
    de: 'Was ist dir am wichtigsten?',
    fr: 'Qu\'est-ce qui compte le plus ?',
  );
  static const interestEasy = LocalizedText(
    nl: 'Makkelijk te telen',
    en: 'Easy to grow',
    de: 'Leicht anzubauen',
    fr: 'Facile à cultiver',
  );
  static const interestFast = LocalizedText(
    nl: 'Snel oogsten',
    en: 'Fast harvest',
    de: 'Schnelle Ernte',
    fr: 'Récolte rapide',
  );
  static const interestYield = LocalizedText(
    nl: 'Veel opbrengst',
    en: 'High yield',
    de: 'Hoher Ertrag',
    fr: 'Bon rendement',
  );
  static const interestKids = LocalizedText(
    nl: 'Leuk met kinderen',
    en: 'Fun with kids',
    de: 'Spaß mit Kindern',
    fr: 'Avec les enfants',
  );
  static const interestCost = LocalizedText(
    nl: 'Scheelt geld',
    en: 'Saves money',
    de: 'Spart Geld',
    fr: 'Fait économiser',
  );
  static const buildMyPlan = LocalizedText(
    nl: 'Bouw mijn plan',
    en: 'Build my plan',
    de: 'Plan erstellen',
    fr: 'Créer mon plan',
  );
  static const yourLocationWord = LocalizedText(
    nl: 'jouw locatie',
    en: 'your location',
    de: 'deinen Standort',
    fr: 'ta position',
  );
  static const planReady = LocalizedText(
    nl: 'Je plan staat klaar',
    en: 'Your plan is ready',
    de: 'Dein Plan ist fertig',
    fr: 'Ton plan est prêt',
  );
  static const planBuilding = LocalizedText(
    nl: 'Je teeltplan wordt gemaakt…',
    en: 'Creating your growing plan…',
    de: 'Dein Anbauplan entsteht…',
    fr: 'Ton plan de culture se prépare…',
  );
  static LocalizedText planFrostLine(
    String region,
    String last,
    String first,
  ) => LocalizedText(
    nl: 'Vorstdatums voor $region: laatste $last, eerste $first',
    en: 'Frost dates for $region: last $last, first $first',
    de: 'Frostdaten für $region: letzter $last, erster $first',
    fr: 'Dates de gel pour $region : dernières $last, premières $first',
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
    fr: n <= 1
        ? '$n plante convient à ton espace ce mois-ci'
        : '$n plantes conviennent à ton espace ce mois-ci',
  );
  static const planMatching = LocalizedText(
    nl: 'Gewassen zoeken die in je ruimte passen…',
    en: 'Matching crops to your space…',
    de: 'Pflanzen werden auf deinen Platz abgestimmt…',
    fr: 'On adapte les plantes à ton espace…',
  );
  static const planFirstTaskWaits = LocalizedText(
    nl: 'De eerste taak komt zodra er een venster opengaat',
    en: 'First task lands as soon as a window opens',
    de: 'Die erste Aufgabe kommt, sobald sich ein Zeitfenster öffnet',
    fr: 'La première tâche arrive dès qu\'une fenêtre s\'ouvre',
  );
  static LocalizedText planFirstTask(String task) => LocalizedText(
    nl: 'Eerste taak: $task',
    en: 'First task: $task',
    de: 'Erste Aufgabe: $task',
    fr: 'Première tâche : $task',
  );
  static const planFindingFirstTask = LocalizedText(
    nl: 'Je eerste taak zoeken…',
    en: 'Finding your first task…',
    de: 'Erste Aufgabe wird gesucht…',
    fr: 'On cherche ta première tâche…',
  );
  static const noLocationPickRegion = LocalizedText(
    nl: 'Geen locatie, vul een postcode in of kies hieronder een regio.',
    en: 'No location, enter a postcode or pick a region below.',
    de: 'Kein Standort. Gib eine Postleitzahl ein oder wähl unten eine Region.',
    fr: 'Pas de position. Entre un code postal ou choisis une région ci-dessous.',
  );
  static const postcodeNotFoundPickRegion = LocalizedText(
    nl:
        'Postcode niet gevonden (1234AB), of je bent offline. Kies hieronder '
        'een regio.',
    en: 'Postcode not found (1234AB), or you are offline. Pick a region below.',
    de: 'Postleitzahl nicht gefunden (1234AB) oder du bist offline. Wähl unten eine Region.',
    fr: 'Code postal introuvable (1234AB), ou tu es hors ligne. Choisis une région ci-dessous.',
  );
  static LocalizedText foundFrostDates(
    String last,
    String first,
  ) => LocalizedText(
    nl: 'Gevonden. Laatste vorst rond $last, eerste vorst rond $first.',
    en: 'Found it. Last frost around $last, first frost around $first.',
    de: 'Gefunden. Letzter Frost etwa $last, erster Frost etwa $first.',
    fr: 'Trouvé. Dernières gelées vers le $last, premières gelées vers le $first.',
  );
  static const whatToDo = LocalizedText(
    nl: 'Wat te doen ',
    en: 'What to do ',
    de: 'Was zu tun ist ',
    fr: 'Quoi faire ',
  );
  static const inYourGarden = LocalizedText(
    nl: 'in je tuin',
    en: 'in your garden',
    de: 'in deinem Garten',
    fr: 'dans ton potager',
  );
  static const plotWord = LocalizedText(
    nl: 'tuin',
    en: 'plot',
    de: 'Garten',
    fr: 'potager',
  );
  static const yourLocation = LocalizedText(
    nl: 'Jouw locatie',
    en: 'Your location',
    de: 'Dein Standort',
    fr: 'Ta position',
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
    fr:
        'Aucun résultat pour « $query ». Essaie une ville proche, un code '
        'postal (1234AB) ou choisis une région.',
  );
  static const useCurrentLocation = LocalizedText(
    nl: 'Gebruik mijn huidige locatie',
    en: 'Use my current location',
    de: 'Aktuellen Standort nutzen',
    fr: 'Utiliser ma position actuelle',
  );
  static const detectingLocation = LocalizedText(
    nl: 'Locatie bepalen…',
    en: 'Detecting your location…',
    de: 'Standort wird ermittelt…',
    fr: 'On cherche ta position…',
  );
  static const renewsYearly = LocalizedText(
    nl:
        'Verlengt jaarlijks. Beheren of opzeggen doe je in de App Store / Play '
        'Store.',
    en: 'Renews yearly. Manage or cancel in the App Store / Play Store.',
    de: 'Verlängert sich jährlich. Verwalten oder kündigen im App Store / Play Store.',
    fr: 'Renouvellement annuel. Gère ou résilie dans l\'App Store / le Play Store.',
  );
  static const couldNotDeleteAccount = LocalizedText(
    nl: 'Account verwijderen lukte niet. Probeer het later opnieuw.',
    en: 'Could not delete the account. Try again later.',
    de: 'Das Konto konnte nicht gelöscht werden. Versuch es später noch einmal.',
    fr: 'Impossible de supprimer le compte. Réessaie plus tard.',
  );
  static const scanOpensWithBeta = LocalizedText(
    nl: 'Fotoscannen is nu niet beschikbaar. De probleemgids werkt offline.',
    en:
        'Photo scanning is not available right now. The common-problems '
        'browser works offline.',
    de: 'Foto-Scans sind gerade nicht verfügbar. Die Übersicht häufiger Probleme funktioniert offline.',
    fr: 'Le scan photo n\'est pas disponible pour l\'instant. La liste des problèmes courants marche hors ligne.',
  );
  static const scanQuotaReached = LocalizedText(
    nl:
        'Dagelijkse scanlimiet bereikt. Morgen weer, of ontgrendel levenslang '
        'voor meer.',
    en:
        'Daily scan limit reached. Tomorrow again, or unlock lifetime for '
        'more.',
    de: 'Tägliches Scan-Limit erreicht. Morgen geht es weiter, oder schalte Lifetime für mehr frei.',
    fr: 'Limite de scans du jour atteinte. Reviens demain, ou débloque Lifetime pour en avoir plus.',
  );
  static LocalizedText scanFailed(String code) => LocalizedText(
    nl: 'Scannen mislukt ($code). Probeer opnieuw.',
    en: 'Scan failed ($code). Try again.',
    de: 'Scan fehlgeschlagen ($code). Versuch es noch einmal.',
    fr: 'Échec du scan ($code). Réessaie.',
  );
  static const snapTipsIdentify = LocalizedText(
    nl: 'Fototips: één plant, een blad of bloem vult het beeld, daglicht.',
    en: 'Snap tips: one plant, a leaf or flower filling the frame, daylight.',
    de: 'Foto-Tipps: eine Pflanze, ein Blatt oder eine Blüte füllt das Bild, Tageslicht.',
    fr: 'Conseils photo : une seule plante, une feuille ou une fleur qui remplit le cadre, la lumière du jour.',
  );
  static const snapTipsDiagnose = LocalizedText(
    nl:
        'Fototips: het aangetaste deel scherp en dichtbij, plus één wijdere '
        'foto als je twijfelt.',
    en:
        'Snap tips: the damaged part sharp and close, plus one wider shot if '
        'unsure.',
    de: 'Foto-Tipps: die beschädigte Stelle scharf und nah, dazu eine weitere Aufnahme, wenn du unsicher bist.',
    fr: 'Conseils photo : la partie abîmée nette et de près, plus une vue plus large en cas de doute.',
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
    fr:
        'Il est tombé $mm mm ces trois derniers jours. Les arrosages autour '
        'd\'aujourd\'hui sont passés.',
  );
  static const heatAhead = LocalizedText(
    nl:
        'Hitte op komst (30°C+). Potten drogen in een dag uit, dus water geven '
        'schuift naar voren.',
    en:
        'Heat ahead (30°C+). Containers dry out in a day, so waterings move '
        'earlier.',
    de: 'Hitze im Anmarsch (30 °C+). Töpfe trocknen an einem Tag aus, darum rückt das Gießen nach vorne.',
    fr: 'Chaleur en vue (30 °C+). Les pots sèchent en une journée, alors les arrosages avancent.',
  );
  static const forecastCalm = LocalizedText(
    nl: 'Niets bijzonders in de verwachting. Het plan blijft staan.',
    en: 'Nothing dramatic in the forecast. The plan stands.',
    de: 'Nichts Dramatisches in der Vorhersage. Der Plan steht.',
    fr: 'Rien de spécial dans les prévisions. Le plan tient.',
  );
  static const youAreHere = LocalizedText(
    nl: 'Hier ben je',
    en: 'You are here',
    de: 'Du bist hier',
    fr: 'Tu es ici',
  );
  static LocalizedText cropsSuitMonth(int n) => LocalizedText(
    nl: n == 1 ? '1 gewas past' : '$n gewassen passen',
    en: n == 1 ? '1 crop suits it' : '$n crops suit it',
    de: n == 1 ? '1 Pflanze passt' : '$n Pflanzen passen',
    fr: n <= 1 ? '$n plante convient' : '$n plantes conviennent',
  );
  static LocalizedText cropsCanGoIn(int n) => LocalizedText(
    nl: n == 1 ? 'Er kan nog 1 gewas in' : 'Er kunnen nog $n gewassen in',
    en: n == 1 ? '1 crop can still go in' : '$n crops can still go in',
    de: n == 1 ? '1 Pflanze kann noch rein' : '$n Pflanzen können noch rein',
    fr: n <= 1
        ? '$n plante peut encore aller en terre'
        : '$n plantes peuvent encore aller en terre',
  );
  static LocalizedText nothingPlanned(LocalizedText month) => LocalizedText(
    nl: 'Nog niets gepland voor ${month.nl}',
    en: 'Nothing planned for ${month.en}',
    de: 'Nichts geplant im ${month.pick('de')}',
    fr: 'Rien de planifié en ${month.pick('fr')}',
  );
  static LocalizedText stillSowable(LocalizedText month) => LocalizedText(
    nl: 'Nog te zaaien in ${month.nl}',
    en: 'Still sowable in ${month.en}',
    de: 'Im ${month.pick('de')} noch zu säen',
    fr: 'Encore à semer en ${month.pick('fr')}',
  );
  static LocalizedText openAndDone(int open, int done) => LocalizedText(
    nl: '$open nu open · $done gedaan',
    en: '$open open now · $done done',
    de: '$open jetzt offen · $done erledigt',
    fr: '$open à faire · $done ${done <= 1 ? 'faite' : 'faites'}',
  );
  static LocalizedText doneNothingOpen(int done) => LocalizedText(
    nl: '$done gedaan · niets open vandaag',
    en: '$done done · nothing open today',
    de: '$done erledigt · heute nichts offen',
    fr: '$done ${done <= 1 ? 'faite' : 'faites'} · rien à faire aujourd\'hui',
  );

  // ── the path's own stops ──────────────────────────────────────────────────
  static LocalizedText sowCrop(LocalizedText crop) => LocalizedText(
    nl: '${crop.nl} zaaien',
    en: 'Sow ${crop.en}',
    de: '${crop.pick('de')} säen',
    fr: 'Semer ${crop.pick('fr')}',
  );
  static LocalizedText harvestCrop(LocalizedText crop) => LocalizedText(
    nl: '${crop.nl} oogsten',
    en: 'Harvest ${crop.en}',
    de: '${crop.pick('de')} ernten',
    fr: 'Récolter ${crop.pick('fr')}',
  );
  static LocalizedText followOn(LocalizedText crop) => LocalizedText(
    nl: 'Daarna: ${crop.nl}',
    en: 'Follow on: ${crop.en}',
    de: 'Danach: ${crop.pick('de')}',
    fr: 'Ensuite : ${crop.pick('fr')}',
  );

  /// "Tomaat bijmesten" reads right in Dutch, "Feed Tomato" in English, so the
  /// two languages put the crop on different sides of the verb.
  /// [step] must be verb-led (nl/de lowercase it after the crop): today the
  /// season list passes pot on, plant out, thin and feed only.
  static LocalizedText stepOnCrop(LocalizedText step, LocalizedText crop) =>
      LocalizedText(
        nl: '${crop.nl} ${step.nl.toLowerCase()}',
        en: '${step.en} ${crop.en}',
        de: '${crop.pick('de')} ${step.pick('de').toLowerCase()}',
        fr: '${step.pick('fr')} ${crop.pick('fr')}',
      );

  static const ijsheiligen = LocalizedText(
    nl: 'IJsheiligen',
    en: 'IJsheiligen',
    de: 'Eisheiligen',
    fr: 'Saints de glace',
  );
  static const ijsheiligenSub = LocalizedText(
    nl: 'Vorstgevoelige gewassen blijven tot 15 mei binnen',
    en: 'Tender crops stay in until 15 May',
    de: 'Empfindliche Pflanzen bleiben bis 15. Mai drinnen',
    fr: 'Les plantes sensibles restent à l\'abri jusqu\'au 15 mai',
  );
  static const lastFrost = LocalizedText(
    nl: 'Laatste vorst, gemiddeld',
    en: 'Last frost, on average',
    de: 'Letzter Frost, im Schnitt',
    fr: 'Dernières gelées, en moyenne',
  );
  static const lastFrostSub = LocalizedText(
    nl: 'Daarna mogen vorstgevoelige gewassen naar buiten',
    en: 'After this, tender crops can go out',
    de: 'Danach dürfen empfindliche Pflanzen raus',
    fr: 'Après ça, les plantes sensibles peuvent sortir',
  );
  static const firstFrost = LocalizedText(
    nl: 'Eerste vorst, gemiddeld',
    en: 'First frost, on average',
    de: 'Erster Frost, im Schnitt',
    fr: 'Premières gelées, en moyenne',
  );
  static const firstFrostSub = LocalizedText(
    nl: 'Haal vorstgevoelige gewassen hiervoor binnen',
    en: 'Bring tender crops in before this',
    de: 'Hol empfindliche Pflanzen vorher rein',
    fr: 'Rentre les plantes sensibles avant ça',
  );
  static const orderSeed = LocalizedText(
    nl: 'Bestel je zaad',
    en: 'Order your seed',
    de: 'Saatgut bestellen',
    fr: 'Commande tes graines',
  );
  static LocalizedText cropsOnList(int n) => LocalizedText(
    nl: n == 1 ? '1 gewas op je lijst' : '$n gewassen op je lijst',
    en: n == 1 ? '1 crop on your list' : '$n crops on your list',
    de: n == 1 ? '1 Pflanze auf deiner Liste' : '$n Pflanzen auf deiner Liste',
    fr: n <= 1 ? '$n plante sur ta liste' : '$n plantes sur ta liste',
  );
  static const monthPhoto = LocalizedText(
    nl: 'Maak de foto van deze maand',
    en: "Snap this month's photo",
    de: 'Mach das Foto des Monats',
    fr: 'Prends la photo du mois',
  );
  static const seasonInPictures = LocalizedText(
    nl: 'Je seizoen, in beeld',
    en: 'Your season, in pictures',
    de: 'Deine Saison in Bildern',
    fr: 'Ta saison en images',
  );
  static const seasonTally = LocalizedText(
    nl: 'Seizoensoogst',
    en: 'Season tally',
    de: 'Saisonbilanz',
    fr: 'Bilan de saison',
  );
  static LocalizedText tallySoFar(int euros, String kilos) => LocalizedText(
    nl: '€$euros en $kilos kg tot nu toe',
    en: '€$euros and $kilos kg so far',
    de: '$euros € und $kilos kg bisher',
    fr: '$euros € et $kilos kg pour l\'instant',
  );
  static const tallyEmpty = LocalizedText(
    nl: 'Log een oogst en het telt hier op',
    en: 'Log a harvest and it adds up here',
    de: 'Trag eine Ernte ein, dann summiert sie sich hier',
    fr: 'Note une récolte et elle s\'additionne ici',
  );
  static LocalizedText recapTitle(int year) => LocalizedText(
    nl: 'Jouw $year, op één kaart',
    en: 'Your $year, in one card',
    de: 'Dein $year auf einer Karte',
    fr: 'Ton $year, en une carte',
  );
  static const recapSub = LocalizedText(
    nl: 'Wat je teelde, plukte en bespaarde',
    en: 'What you grew, picked and saved',
    de: 'Was du angebaut, geerntet und gespart hast',
    fr: 'Ce que tu as cultivé, récolté et économisé',
  );
  static LocalizedText recapPicked(int euros) => LocalizedText(
    nl: '€$euros geplukt tot nu toe',
    en: '€$euros picked so far',
    de: '$euros € bisher geerntet',
    fr: '$euros € récoltés pour l\'instant',
  );
  static const plantsGrown = LocalizedText(
    nl: 'Planten geteeld',
    en: 'Plants grown',
    de: 'Angebaute Pflanzen',
    fr: 'Plantes cultivées',
  );
  static const picked = LocalizedText(
    nl: 'Geoogst',
    en: 'Picked',
    de: 'Geerntet',
    fr: 'Récolté',
  );
  static const saved = LocalizedText(
    nl: 'Bespaard',
    en: 'Saved',
    de: 'Gespart',
    fr: 'Économisé',
  );

  // ── the weather, when it moves something ──────────────────────────────────
  static const rainDidIt = LocalizedText(
    nl: 'De regen deed het water geven',
    en: 'Rain did the watering',
    de: 'Der Regen hat gegossen',
    fr: 'La pluie a arrosé',
  );
  static const rainDidItSub = LocalizedText(
    nl: 'Overgeslagen, je reeks telt door',
    en: 'Skipped for you, the streak still counts',
    de: 'Für dich übersprungen, die Serie zählt trotzdem',
    fr: 'Passé pour toi, la série compte quand même',
  );
  static const heatComing = LocalizedText(
    nl: 'Hitte op komst',
    en: 'Heat on the way',
    de: 'Hitze im Anmarsch',
    fr: 'Chaleur en vue',
  );
  static const heatComingSub = LocalizedText(
    nl: 'Eerder water geven dan gepland',
    en: 'Water earlier than planned',
    de: 'Früher gießen als geplant',
    fr: 'Arrose plus tôt que prévu',
  );
  static const soilCold = LocalizedText(
    nl: 'Bodem nog te koud',
    en: 'Soil still too cold',
    de: 'Boden noch zu kalt',
    fr: 'Sol encore trop froid',
  );
  static const soilColdSub = LocalizedText(
    nl: 'Zaaien wacht tot het warmer is',
    en: 'Sowing held until it warms',
    de: 'Gesät wird, sobald er wärmer ist',
    fr: 'Le semis attend qu\'il se réchauffe',
  );

  // ── browse: Explore and Grow ──────────────────────────────────────────────
  static const explore = LocalizedText(
    nl: 'Ontdek',
    en: 'Explore',
    de: 'Entdecken',
    fr: 'Explorer',
  );
  static const findNextCrop = LocalizedText(
    nl: 'Vind je volgende gewas',
    en: 'Find your next crop',
    de: 'Finde deine nächste Pflanze',
    fr: 'Trouve ta prochaine plante',
  );
  static const identifyFromPhoto = LocalizedText(
    nl: 'Herken een plant van een foto',
    en: 'Identify a plant from a photo',
    de: 'Pflanze per Foto bestimmen',
    fr: 'Identifier une plante en photo',
  );
  static const grow = LocalizedText(
    nl: 'Kweken',
    en: 'Grow',
    de: 'Anbauen',
    fr: 'Cultiver',
  );
  static LocalizedText searchCropCount(int n) => LocalizedText(
    nl: n == 1 ? 'Zoek in 1 gewas…' : 'Zoek in $n gewassen…',
    en: n == 1 ? 'Search 1 crop…' : 'Search $n crops…',
    de: n == 1 ? 'In 1 Pflanze suchen…' : 'In $n Pflanzen suchen…',
    fr: n <= 1 ? 'Chercher parmi $n plante…' : 'Chercher parmi $n plantes…',
  );
  static LocalizedText results(int n) => LocalizedText(
    nl: n == 1 ? '1 resultaat' : '$n resultaten',
    en: n == 1 ? '1 result' : '$n results',
    de: n == 1 ? '1 Ergebnis' : '$n Ergebnisse',
    fr: n <= 1 ? '$n résultat' : '$n résultats',
  );
  static const profile = LocalizedText(
    nl: 'Profiel',
    en: 'Profile',
    de: 'Profil',
    fr: 'Profil',
  );

  // ── crop detail ───────────────────────────────────────────────────────────
  static const planToGrow = LocalizedText(
    nl: 'Plan het',
    en: 'Plan to grow',
    de: 'Einplanen',
    fr: 'Planifier',
  );
  static const growingIt = LocalizedText(
    nl: 'Ik kweek het',
    en: 'Growing it',
    de: 'Wächst schon',
    fr: 'Déjà planté',
  );
  static const goodNeighbours = LocalizedText(
    nl: 'Goede buren',
    en: 'Good neighbours',
    de: 'Gute Nachbarn',
    fr: 'Bons voisins',
  );
  static const badNeighbours = LocalizedText(
    nl: 'Slechte buren',
    en: 'Bad neighbours',
    de: 'Schlechte Nachbarn',
    fr: 'Mauvais voisins',
  );
  static const noCompanionData = LocalizedText(
    nl: 'Nog geen buurgegevens.',
    en: 'No companion data yet.',
    de: 'Noch keine Nachbarschaftsdaten.',
    fr: 'Pas encore de données d\'association.',
  );
  static const draftMatrix = LocalizedText(
    nl: 'Concept. De gecontroleerde matrix komt met de contentupdate',
    en: 'Draft. The verified matrix lands in the content update',
    de: 'Entwurf. Die geprüfte Tabelle kommt mit dem Inhalts-Update',
    fr: 'Brouillon. Le tableau vérifié arrive avec la mise à jour du contenu',
  );
  static LocalizedText verifiedAgainst(int n) => LocalizedText(
    nl: 'Gecontroleerd tegen $n NL-bronnen',
    en: 'Verified against $n NL sources',
    de: 'Geprüft mit $n NL-Quellen',
    fr: 'Vérifié avec $n sources NL',
  );
  static LocalizedText basedOn(String region) => LocalizedText(
    nl: 'Op basis van: $region',
    en: 'Based on: $region',
    de: 'Grundlage: $region',
    fr: 'Basé sur : $region',
  );
  static LocalizedText potLitres(num litres) => LocalizedText(
    nl: '$litres L pot',
    en: '$litres L pot',
    de: '$litres-L-Topf',
    fr: 'Pot de $litres L',
  );
  static LocalizedText harvestInDays(int days) => LocalizedText(
    nl: 'Oogst over $days dagen',
    en: 'Harvest in $days days',
    de: 'Ernte in $days ${days == 1 ? 'Tag' : 'Tagen'}',
    fr: 'Récolte dans $days ${days <= 1 ? 'jour' : 'jours'}',
  );
  static const readyToHarvest = LocalizedText(
    nl: 'Klaar om te oogsten',
    en: 'Ready to harvest',
    de: 'Erntereif',
    fr: 'Prêt à récolter',
  );
  static LocalizedText harvestDays(int min, int max) => LocalizedText(
    nl: '$min–$max dagen',
    en: '$min–$max days',
    de: '$min–$max Tage',
    fr: '$min–$max jours',
  );

  // ── settings ──────────────────────────────────────────────────────────────
  static const settings = LocalizedText(
    nl: 'Instellingen',
    en: 'Settings',
    de: 'Einstellungen',
    fr: 'Réglages',
  );
  static const account = LocalizedText(
    nl: 'Account',
    en: 'Account',
    de: 'Konto',
    fr: 'Compte',
  );
  static const membership = LocalizedText(
    nl: 'Lidmaatschap',
    en: 'Membership',
    de: 'Mitgliedschaft',
    fr: 'Abonnement',
  );
  static const yourData = LocalizedText(
    nl: 'Jouw gegevens',
    en: 'Your data',
    de: 'Deine Daten',
    fr: 'Tes données',
  );
  static const appearance = LocalizedText(
    nl: 'Weergave',
    en: 'Appearance',
    de: 'Darstellung',
    fr: 'Apparence',
  );
  static const language = LocalizedText(
    nl: 'Taal',
    en: 'Language',
    de: 'Sprache',
    fr: 'Langue',
  );
  static const help = LocalizedText(
    nl: 'Help',
    en: 'Help',
    de: 'Hilfe',
    fr: 'Aide',
  );
  static const themeSystem = LocalizedText(
    nl: 'Systeem',
    en: 'System',
    de: 'System',
    fr: 'Système',
  );
  static const themeLight = LocalizedText(
    nl: 'Licht',
    en: 'Light',
    de: 'Hell',
    fr: 'Clair',
  );
  static const themeDark = LocalizedText(
    nl: 'Donker',
    en: 'Dark',
    de: 'Dunkel',
    fr: 'Sombre',
  );
  static const themeFollows = LocalizedText(
    nl: 'Systeem volgt je telefoon.',
    en: 'System follows your phone.',
    de: 'System folgt deinem Handy.',
    fr: '« Système » suit ton téléphone.',
  );
  static const langNote = LocalizedText(
    nl:
        'De interface spreekt meerdere talen. Een teeltuitleg die nog niet '
        'vertaald is, lees je in het Engels; dat staat er dan bij.',
    en:
        'The interface speaks several languages. A growing guide that is not '
        'translated yet reads in English, and says so.',
    de: 'Die App spricht mehrere Sprachen. Eine Anbauanleitung, die noch nicht übersetzt ist, erscheint auf Englisch und sagt das auch.',
    fr: 'L\'app parle plusieurs langues. Un guide de culture pas encore traduit s\'affiche en anglais, et le dit.',
  );
  static const signInBlurb = LocalizedText(
    nl:
        'Log in om je tuin te bewaren en te synchroniseren. Zonder account '
        'werkt alles gewoon offline door.',
    en:
        'Sign in to back up and sync your garden. Everything keeps working '
        'offline without it.',
    de: 'Melde dich an, um deinen Garten zu sichern und zu synchronisieren. Ohne Anmeldung funktioniert alles weiter offline.',
    fr: 'Connecte-toi pour sauvegarder et synchroniser ton potager. Sans compte, tout continue de marcher hors ligne.',
  );
  static const email = LocalizedText(
    nl: 'E-mail',
    en: 'E-mail',
    de: 'E-Mail',
    fr: 'E-mail',
  );
  static const sendLink = LocalizedText(
    nl: 'Stuur me een inloglink',
    en: 'Send me a sign-in link',
    de: 'Anmeldelink senden',
    fr: 'M\'envoyer un lien de connexion',
  );
  static const checkYourMail = LocalizedText(
    nl: 'Kijk in je mail. De link logt je in.',
    en: 'Check your mail. The link signs you in.',
    de: 'Schau in dein Postfach. Der Link meldet dich an.',
    fr: 'Regarde tes e-mails. Le lien te connecte.',
  );
  static const passwordOptional = LocalizedText(
    nl: 'Wachtwoord (optioneel)',
    en: 'Password (optional)',
    de: 'Passwort (optional)',
    fr: 'Mot de passe (facultatif)',
  );
  static const signIn = LocalizedText(
    nl: 'Inloggen',
    en: 'Sign in',
    de: 'Anmelden',
    fr: 'Se connecter',
  );
  static const createAccount = LocalizedText(
    nl: 'Account maken',
    en: 'Create account',
    de: 'Konto erstellen',
    fr: 'Créer un compte',
  );
  static const accountCreated = LocalizedText(
    nl: 'Account aangemaakt. Bevestig via de mail die we stuurden.',
    en: 'Account created. Confirm via the mail we sent.',
    de: 'Konto erstellt. Bestätige es über die Mail, die wir dir geschickt haben.',
    fr: 'Compte créé. Confirme-le via l\'e-mail qu\'on t\'a envoyé.',
  );
  static const signedIn = LocalizedText(
    nl: 'Ingelogd',
    en: 'Signed in',
    de: 'Angemeldet',
    fr: 'Connecté',
  );
  static const syncNow = LocalizedText(
    nl: 'Sync nu',
    en: 'Sync now',
    de: 'Synchronisieren',
    fr: 'Synchroniser',
  );
  static const signOut = LocalizedText(
    nl: 'Uitloggen',
    en: 'Sign out',
    de: 'Abmelden',
    fr: 'Se déconnecter',
  );
  static const syncing = LocalizedText(
    nl: 'Synchroniseren…',
    en: 'Syncing…',
    de: 'Sync läuft…',
    fr: 'Synchronisation…',
  );
  static const notSyncedYet = LocalizedText(
    nl: 'Nog niet gesynchroniseerd.',
    en: 'Not synced yet.',
    de: 'Noch nicht synchronisiert.',
    fr: 'Pas encore synchronisé.',
  );
  static LocalizedText lastSync(String time) => LocalizedText(
    nl: 'Laatste sync $time',
    en: 'Last sync $time',
    de: 'Zuletzt synchronisiert $time',
    fr: 'Dernière synchro $time',
  );
  static const someTablesFailed = LocalizedText(
    nl: ' · een deel is mislukt',
    en: ' · some tables failed',
    de: ' · teils fehlgeschlagen',
    fr: ' · échec partiel',
  );
  static const alreadyInStep = LocalizedText(
    nl: 'Alles liep al gelijk.',
    en: 'Everything was already in step.',
    de: 'Alles war schon auf dem neuesten Stand.',
    fr: 'Tout était déjà à jour.',
  );
  static const deleteAccount = LocalizedText(
    nl: 'Account verwijderen',
    en: 'Delete account',
    de: 'Konto löschen',
    fr: 'Supprimer le compte',
  );
  static const deleteAccountAsk = LocalizedText(
    nl: 'Account verwijderen?',
    en: 'Delete account?',
    de: 'Konto löschen?',
    fr: 'Supprimer le compte ?',
  );
  static const deleteAccountBody = LocalizedText(
    nl:
        'Verwijdert je account en elke gesynchroniseerde tuin, plant en log. '
        'Dit kan niet ongedaan worden gemaakt.',
    en:
        'Removes your account and every synced garden, plant and log. This '
        'cannot be undone.',
    de: 'Entfernt dein Konto und jeden synchronisierten Garten, jede Pflanze und jeden Eintrag. Das lässt sich nicht rückgängig machen.',
    fr: 'Supprime ton compte et chaque potager, plante et entrée synchronisés. C\'est irréversible.',
  );
  static const deleted = LocalizedText(
    nl: 'Account verwijderd. Je lokale gegevens blijven op deze telefoon.',
    en: 'Account deleted. Your local data stays on this phone.',
    de: 'Konto gelöscht. Deine lokalen Daten bleiben auf diesem Handy.',
    fr: 'Compte supprimé. Tes données locales restent sur ce téléphone.',
  );
  static const cancel = LocalizedText(
    nl: 'Annuleren',
    en: 'Cancel',
    de: 'Abbrechen',
    fr: 'Annuler',
  );
  static const delete = LocalizedText(
    nl: 'Verwijderen',
    en: 'Delete',
    de: 'Löschen',
    fr: 'Supprimer',
  );
  static const exportData = LocalizedText(
    nl: 'Exporteer mijn data (JSON)',
    en: 'Export my data (JSON)',
    de: 'Meine Daten exportieren (JSON)',
    fr: 'Exporter mes données (JSON)',
  );
  static const seasonMailTitle = LocalizedText(
    nl: 'Seizoensmail',
    en: 'Seasonal email',
    de: 'Saison-E-Mail',
    fr: 'E-mail de saison',
  );
  static const seasonMailBlurb = LocalizedText(
    nl: 'Twee mails per jaar: in februari als het zaaiseizoen begint, in oktober je oogstoverzicht. Verder niets, en uitschrijven kan met één klik.',
    en: 'Two emails a year: in February when the sowing season starts, in October your harvest summary. Nothing else, and one click unsubscribes.',
    de: 'Zwei E-Mails im Jahr: im Februar, wenn die Aussaat beginnt, im Oktober deine Erntebilanz. Sonst nichts, und ein Klick meldet dich ab.',
    fr: 'Deux e-mails par an : en février quand la saison des semis commence, en octobre ton bilan de récolte. Rien d\'autre, et un clic suffit pour te désabonner.',
  );
  static const seasonMailNeedsAccount = LocalizedText(
    nl: 'Log in met een e-mailadres om dit aan te zetten.',
    en: 'Sign in with an email address to turn this on.',
    de: 'Melde dich mit einer E-Mail-Adresse an, um das einzuschalten.',
    fr: 'Connecte-toi avec une adresse e-mail pour activer ça.',
  );

  static const forgotPassword = LocalizedText(
    nl: 'Wachtwoord vergeten?',
    en: 'Forgot your password?',
    de: 'Passwort vergessen?',
    fr: 'Mot de passe oublié ?',
  );
  static const resetMailSent = LocalizedText(
    nl: 'Check je mail voor een link om een nieuw wachtwoord te kiezen.',
    en: 'Check your mail for a link to choose a new password.',
    de: 'Schau in dein Postfach: Dort wartet ein Link, mit dem du ein neues Passwort wählst.',
    fr: 'Regarde tes e-mails : un lien t\'attend pour choisir un nouveau mot de passe.',
  );
  static const changePassword = LocalizedText(
    nl: 'Wachtwoord wijzigen',
    en: 'Change password',
    de: 'Passwort ändern',
    fr: 'Changer de mot de passe',
  );
  static const changeEmail = LocalizedText(
    nl: 'E-mailadres wijzigen',
    en: 'Change email address',
    de: 'E-Mail-Adresse ändern',
    fr: 'Changer d\'adresse e-mail',
  );
  static const newPassword = LocalizedText(
    nl: 'Nieuw wachtwoord',
    en: 'New password',
    de: 'Neues Passwort',
    fr: 'Nouveau mot de passe',
  );
  static const newEmail = LocalizedText(
    nl: 'Nieuw e-mailadres',
    en: 'New email address',
    de: 'Neue E-Mail-Adresse',
    fr: 'Nouvelle adresse e-mail',
  );
  static const passwordChanged = LocalizedText(
    nl: 'Je wachtwoord is gewijzigd.',
    en: 'Your password has been changed.',
    de: 'Dein Passwort wurde geändert.',
    fr: 'Ton mot de passe a été changé.',
  );
  static const emailChangeSent = LocalizedText(
    nl: 'Check allebei je mailboxen: het oude en het nieuwe adres moeten bevestigen.',
    en: 'Check both mailboxes: the old and the new address each have to confirm.',
    de: 'Schau in beide Postfächer: Die alte und die neue Adresse müssen jeweils bestätigen.',
    fr: 'Regarde les deux boîtes mail : l\'ancienne et la nouvelle adresse doivent chacune confirmer.',
  );
  static const emailChangeBlurb = LocalizedText(
    nl: 'Je tuin, logboek en oogsten verhuizen mee.',
    en: 'Your garden, journal and harvests come along.',
    de: 'Dein Garten, dein Tagebuch und deine Ernten kommen mit.',
    fr: 'Ton potager, ton journal et tes récoltes suivent.',
  );
  static const recoveryTitle = LocalizedText(
    nl: 'Kies een nieuw wachtwoord',
    en: 'Choose a new password',
    de: 'Wähl ein neues Passwort',
    fr: 'Choisis un nouveau mot de passe',
  );
  static const recoveryBody = LocalizedText(
    nl: 'Je bent binnen via de herstellink. Kies nu een nieuw wachtwoord, dan ben je weer de enige met de sleutel.',
    en: 'You came in through the recovery link. Pick a new password now, so you are the only one with the key again.',
    de: 'Du bist über den Wiederherstellungslink gekommen. Wähl jetzt ein neues Passwort, damit wieder nur du den Schlüssel hast.',
    fr: 'Tu as utilisé le lien de récupération. Choisis maintenant un nouveau mot de passe, pour que personne d\'autre n\'ait la clé.',
  );

  static const analyticsTitle = LocalizedText(
    nl: 'Anonieme gebruiksgegevens delen',
    en: 'Share anonymous usage data',
    de: 'Anonyme Nutzungsdaten teilen',
    fr: 'Partager des données d\'usage anonymes',
  );
  static const analyticsBlurb = LocalizedText(
    nl: 'Welke schermen je opent en wanneer je een plant toevoegt — nooit je notities, foto\'s of locatie. Uit laten mag; de app werkt hetzelfde.',
    en: 'Which screens you open and when you add a plant — never your notes, photos or location. Leaving it off is fine; the app works the same.',
    de: 'Welche Bildschirme du öffnest und wann du eine Pflanze hinzufügst — nie deine Notizen, Fotos oder dein Standort. Ausgeschaltet lassen ist okay; die App funktioniert genauso.',
    fr: 'Les écrans que tu ouvres et quand tu ajoutes une plante — jamais tes notes, photos ou ta position. Tu peux laisser ça désactivé ; l\'app marche pareil.',
  );
  static const analyticsAskTitle = LocalizedText(
    nl: 'Help Cropsy beter te maken?',
    en: 'Help make Cropsy better?',
    de: 'Hilfst du, Cropsy besser zu machen?',
    fr: 'Tu nous aides à améliorer Cropsy ?',
  );
  static const analyticsAskBody = LocalizedText(
    nl: 'We kijken graag welke schermen gebruikt worden en waar mensen vastlopen. Anoniem, in de EU verwerkt, en nooit je notities, foto\'s of locatie. Je kunt dit altijd wijzigen in Instellingen.',
    en: 'We would like to see which screens get used and where people get stuck. Anonymous, processed in the EU, and never your notes, photos or location. You can change this any time in Settings.',
    de: 'Wir würden gern sehen, welche Bildschirme genutzt werden und wo es hakt. Anonym, in der EU verarbeitet und nie deine Notizen, Fotos oder dein Standort. Du kannst das jederzeit in den Einstellungen ändern.',
    fr: 'On aimerait voir quels écrans servent et où ça bloque. Anonyme, traité dans l\'UE, et jamais tes notes, photos ou ta position. Tu peux changer ça à tout moment dans les Réglages.',
  );
  static const analyticsAskYes = LocalizedText(
    nl: 'Prima',
    en: 'Sure',
    de: 'Klar',
    fr: 'Volontiers',
  );
  static const analyticsAskNo = LocalizedText(
    nl: 'Liever niet',
    en: 'No thanks',
    de: 'Nein danke',
    fr: 'Non merci',
  );

  static const exportBlurb = LocalizedText(
    nl: 'Kopieert alles naar het klembord.',
    en: 'Copies everything to the clipboard.',
    de: 'Kopiert alles in die Zwischenablage.',
    fr: 'Copie tout dans le presse-papiers.',
  );
  static const copied = LocalizedText(
    nl: 'Gekopieerd naar het klembord.',
    en: 'Copied to clipboard.',
    de: 'In die Zwischenablage kopiert.',
    fr: 'Copié dans le presse-papiers.',
  );
  static const seePlans = LocalizedText(
    nl: 'Bekijk plannen',
    en: 'See plans',
    de: 'Tarife ansehen',
    fr: 'Voir les offres',
  );
  static const managePlan = LocalizedText(
    nl: 'Beheer plan',
    en: 'Manage plan',
    de: 'Tarif verwalten',
    fr: 'Gérer l\'offre',
  );
  static const restore = LocalizedText(
    nl: 'Herstellen',
    en: 'Restore',
    de: 'Wiederherstellen',
    fr: 'Restaurer',
  );
  static const checkedWithStore = LocalizedText(
    nl: 'Gecontroleerd bij de store.',
    en: 'Checked with the store.',
    de: 'Beim Store nachgefragt.',
    fr: 'Vérifié auprès du store.',
  );
  static const syncUnavailable = LocalizedText(
    nl: 'Synchroniseren zit niet in deze build.',
    en: 'Sync is not available in this build.',
    de: 'Synchronisieren ist in diesem Build nicht verfügbar.',
    fr: 'La synchronisation n\'est pas disponible dans cette version.',
  );
  static const planFree = LocalizedText(
    nl: 'Gratis',
    en: 'Free',
    de: 'Gratis',
    fr: 'Gratuit',
  );
  static const planLifetime = LocalizedText(
    nl: 'Levenslang',
    en: 'Lifetime',
    de: 'Lifetime',
    fr: 'Lifetime',
  );
  static const planYearly = LocalizedText(
    nl: 'Jaarlijks',
    en: 'Yearly',
    de: 'Jährlich',
    fr: 'Annuel',
  );
  static const lifetimeNothingToCancel = LocalizedText(
    nl: 'Levenslang. Niets op te zeggen.',
    en: 'Lifetime. Nothing to cancel.',
    de: 'Einmalkauf. Nichts zu kündigen.',
    fr: 'Achat unique. Rien à résilier.',
  );
  static const freeTierBlurb = LocalizedText(
    nl:
        '1 tuin · 6 groeiende planten · volledige tijdlijn, herinneringen en '
        'elk gewas.',
    en: '1 garden · 6 growing plants · full timeline, reminders and every crop.',
    de: '1 Garten · 6 wachsende Pflanzen · ganze Zeitleiste, Erinnerungen und alle Pflanzenarten.',
    fr: '1 potager · 6 plantes en culture · chronologie complète, rappels et toutes les plantes.',
  );
  static LocalizedText cropDataVersion(String version) => LocalizedText(
    nl: 'Cropsy · gewasdata $version',
    en: 'Cropsy · crop data $version',
    de: 'Cropsy · Pflanzendaten $version',
    fr: 'Cropsy · données des plantes $version',
  );
  static LocalizedText frostDates(String region, String source) =>
      LocalizedText(
        nl: 'Vorstdatums: $region ($source)',
        en: 'Frost dates: $region ($source)',
        de: 'Frostdaten: $region ($source)',
        fr: 'Dates de gel : $region ($source)',
      );

  // ── this week ─────────────────────────────────────────────────────────────
  static const thisWeek = LocalizedText(
    nl: 'Deze week',
    en: 'This week',
    de: 'Diese Woche',
    fr: 'Cette semaine',
  );
  static const nothingDueThisWeek = LocalizedText(
    nl: 'Deze week staat er niets te doen',
    en: 'Nothing due this week',
    de: 'Diese Woche steht nichts an',
    fr: 'Rien de prévu cette semaine',
  );
  static const addPlantsToSee = LocalizedText(
    nl: 'Voeg planten toe bij Kweken om te zien wat er te doen is.',
    en: 'Add plants in Grow to see what to do.',
    de: 'Füg unter Anbauen Pflanzen hinzu, um zu sehen, was zu tun ist.',
    fr: 'Ajoute des plantes dans Cultiver pour voir quoi faire.',
  );

  // ── harvest ───────────────────────────────────────────────────────────────
  static const harvest = LocalizedText(
    nl: 'Oogst',
    en: 'Harvest',
    de: 'Ernte',
    fr: 'Récolte',
  );
  static const thisSeason = LocalizedText(
    nl: 'DIT SEIZOEN',
    en: 'THIS SEASON',
    de: 'DIESE SAISON',
    fr: 'CETTE SAISON',
  );
  static const nothingYet = LocalizedText(
    nl: 'Nog niets',
    en: 'Nothing yet',
    de: 'Noch nichts',
    fr: 'Rien pour l\'instant',
  );
  static LocalizedText savedAtPrices(String euros) => LocalizedText(
    nl: '≈ €$euros bespaard tegen NL supermarktprijzen',
    en: '≈ €$euros saved at NL supermarket prices',
    de: '≈ $euros € gespart nach NL-Supermarktpreisen',
    fr: '≈ $euros € économisés aux prix des supermarchés NL',
  );
  static LocalizedText unpricedCount(int n) => LocalizedText(
    nl: n == 1 ? '1 zonder prijs' : '$n zonder prijs',
    en: n == 1 ? '1 unpriced' : '$n unpriced',
    de: n == 1 ? '1 ohne Preis' : '$n ohne Preis',
    fr: '$n sans prix',
  );
  static LocalizedText harvestsLogged(int n) => LocalizedText(
    nl: n == 1 ? '1 oogst gelogd' : '$n oogsten gelogd',
    en: n == 1 ? '1 harvest logged' : '$n harvests logged',
    de: n == 1 ? '1 Ernte eingetragen' : '$n Ernten eingetragen',
    fr: n <= 1 ? '$n récolte notée' : '$n récoltes notées',
  );
  static const planFreePrice = LocalizedText(
    nl: '€0',
    en: '€0',
    de: '0 €',
    fr: '0 €',
  );
  static const planLifetimePrice = LocalizedText(
    nl: '€49,99 eenmalig',
    en: '€49.99 once',
    de: '49,99 € einmalig',
    fr: '49,99 € en une fois',
  );
  static const planYearlyPrice = LocalizedText(
    nl: '€29,99 / jaar',
    en: '€29.99 / year',
    de: '29,99 € / Jahr',
    fr: '29,99 € / an',
  );
  static const planFreeBlurb = LocalizedText(
    nl:
        '1 tuin · 6 planten in de grond · volledige tijdlijn, herinneringen en '
        'alle gewassen · 20 fotos · 2 streakbevriezingen per maand',
    en:
        '1 garden · 6 growing plants · full timeline, reminders and every crop '
        '· 20 photos · 2 streak freezes a month',
    de: '1 Garten · 6 wachsende Pflanzen · ganze Zeitleiste, Erinnerungen und alle Pflanzenarten · 20 Fotos · 2 Pausentage pro Monat',
    fr: '1 potager · 6 plantes en culture · chronologie complète, rappels et toutes les plantes · 20 photos · 2 jours de pause par mois',
  );
  static const planLifetimeBlurb = LocalizedText(
    nl:
        'Onbeperkt tuinen en planten · plannerraster · diagnose · onbeperkt '
        "fotos en bevriezingen · export",
    en:
        'Unlimited gardens and plants · planner grid · diagnose · unlimited '
        'photos and freezes · export',
    de: 'Unbegrenzt viele Gärten und Pflanzen · Beetplaner · Diagnose · unbegrenzt viele Fotos und Pausentage · Export',
    fr: 'Potagers et plantes illimités · plan de carré · diagnostic · photos et jours de pause illimités · export',
  );
  static const planYearlyBlurb = LocalizedText(
    nl:
        'Alles uit Levenslang, als abonnement. Zeg elk moment op in de App '
        'Store.',
    en:
        'Everything in Lifetime, as a subscription. Cancel in the App Store '
        'any time.',
    de: 'Alles aus Lifetime, als Abo. Jederzeit im App Store kündbar.',
    fr: 'Tout ce qu\'offre Lifetime, en abonnement. Résiliable à tout moment dans l\'App Store.',
  );
  static const noPriceForUnit = LocalizedText(
    nl: 'Nog geen prijs voor deze eenheid',
    en: 'No price for this unit yet',
    de: 'Für diese Einheit gibt es noch keinen Preis',
    fr: 'Pas encore de prix pour cette unité',
  );

  // ── diagnose ──────────────────────────────────────────────────────────────
  static const diagnose = LocalizedText(
    nl: 'Diagnose',
    en: 'Diagnose',
    de: 'Diagnose',
    fr: 'Diagnostic',
  );
  static const autoDiagnose = LocalizedText(
    nl: 'Diagnose van een foto',
    en: 'Auto diagnose from a photo',
    de: 'Automatische Diagnose per Foto',
    fr: 'Diagnostic automatique par photo',
  );
  static const autoDiagnoseSub = LocalizedText(
    nl: 'Altijd een gok, nooit een oordeel. Premium.',
    en: 'Always a guess, never a verdict. Premium.',
    de: 'Immer eine Vermutung, nie ein Urteil. Premium.',
    fr: 'Toujours une hypothèse, jamais un verdict. Premium.',
  );
  static const commonProblems = LocalizedText(
    nl: 'Veelvoorkomende problemen',
    en: 'Common problems',
    de: 'Häufige Probleme',
    fr: 'Problèmes courants',
  );
  static const byPlantPart = LocalizedText(
    nl: 'Per plantdeel',
    en: 'By plant part',
    de: 'Nach Pflanzenteil',
    fr: 'Par partie de la plante',
  );
  static const all = LocalizedText(
    nl: 'Alles',
    en: 'All',
    de: 'Alle',
    fr: 'Tout',
  );
  static const nothingForThatPart = LocalizedText(
    nl: 'Hier staat nog niets voor dat deel.',
    en: 'Nothing listed for that part yet.',
    de: 'Für diesen Teil ist noch nichts gelistet.',
    fr: 'Rien de listé pour cette partie pour l\'instant.',
  );
  static const partWhole = LocalizedText(
    nl: 'Hele plant',
    en: 'Whole plant',
    de: 'Ganze Pflanze',
    fr: 'Plante entière',
  );
  static const partLeaves = LocalizedText(
    nl: 'Blad',
    en: 'Leaves',
    de: 'Blätter',
    fr: 'Feuilles',
  );
  static const partStems = LocalizedText(
    nl: 'Stengels',
    en: 'Stems',
    de: 'Stängel',
    fr: 'Tiges',
  );
  static const partFlowers = LocalizedText(
    nl: 'Bloemen',
    en: 'Flowers',
    de: 'Blüten',
    fr: 'Fleurs',
  );
  static const partFruits = LocalizedText(
    nl: 'Vruchten',
    en: 'Fruits',
    de: 'Früchte',
    fr: 'Fruits',
  );
  static const partRoots = LocalizedText(
    nl: 'Wortels',
    en: 'Roots',
    de: 'Wurzeln',
    fr: 'Racines',
  );

  // ── the garden tab ────────────────────────────────────────────────────────
  static const myGarden = LocalizedText(
    nl: 'Mijn tuin',
    en: 'My garden',
    de: 'Mein Garten',
    fr: 'Mon potager',
  );
  static const planning = LocalizedText(
    nl: 'Gepland',
    en: 'Planning',
    de: 'Planung',
    fr: 'Planifié',
  );
  static const growing = LocalizedText(
    nl: 'Groeit',
    en: 'Growing',
    de: 'Im Anbau',
    fr: 'En culture',
  );
  // Short enough to sit in a four-way segmented control.
  static const reminders = LocalizedText(
    nl: 'Meldingen',
    en: 'Reminders',
    de: 'Erinnerungen',
    fr: 'Rappels',
  );
  static const start = LocalizedText(
    nl: 'Starten',
    en: 'Start',
    de: 'Start',
    fr: 'Démarrer',
  );
  static const remove = LocalizedText(
    nl: 'Verwijderen',
    en: 'Remove',
    de: 'Entfernen',
    fr: 'Retirer',
  );
  static LocalizedText removeAsk(String name) => LocalizedText(
    nl: '$name verwijderen?',
    en: 'Remove $name?',
    de: '$name entfernen?',
    fr: 'Retirer $name ?',
  );
  static LocalizedText removedFromGarden(String name) => LocalizedText(
    nl: '$name is uit je tuin gehaald',
    en: '$name removed from your garden',
    de: '$name wurde aus deinem Garten entfernt',
    fr: '$name a été retiré de ton potager',
  );
  static const editGarden = LocalizedText(
    nl: 'Tuin bewerken',
    en: 'Edit garden',
    de: 'Garten bearbeiten',
    fr: 'Modifier le potager',
  );
  static const gardenName = LocalizedText(
    nl: 'Naam van de tuin',
    en: 'Garden name',
    de: 'Name des Gartens',
    fr: 'Nom du potager',
  );
  static const growingSituation = LocalizedText(
    nl: 'Waar tuinier je?',
    en: 'Growing situation',
    de: 'Anbausituation',
    fr: 'Conditions de culture',
  );
  static LocalizedText sunHours(int hours) => LocalizedText(
    nl: 'Uren zon per dag: ${hours}u',
    en: 'Hours of sun a day: ${hours}h',
    de: 'Sonnenstunden pro Tag: ${hours}h',
    fr: 'Heures de soleil par jour : $hours h',
  );
  static const saveChanges = LocalizedText(
    nl: 'Opslaan',
    en: 'Save changes',
    de: 'Änderungen speichern',
    fr: 'Enregistrer',
  );
  static const nothingPlannedYet = LocalizedText(
    nl: 'Nog niets gepland',
    en: 'Nothing planned yet',
    de: 'Noch nichts geplant',
    fr: 'Rien de planifié pour l\'instant',
  );
  static const nothingGrowingYet = LocalizedText(
    nl: 'Nog niets aan het groeien',
    en: 'Nothing growing yet',
    de: 'Noch nichts im Anbau',
    fr: 'Rien en culture pour l\'instant',
  );
  static const balcony = LocalizedText(
    nl: 'Balkon',
    en: 'Balcony',
    de: 'Balkon',
    fr: 'Balcon',
  );
  static const gardenKind = LocalizedText(
    nl: 'Tuin',
    en: 'Garden',
    de: 'Garten',
    fr: 'Jardin',
  );
  static const allotment = LocalizedText(
    nl: 'Volkstuin',
    en: 'Allotment',
    de: 'Kleingarten',
    fr: 'Jardin familial',
  );

  // ── a plant ───────────────────────────────────────────────────────────────
  static const growingGuide = LocalizedText(
    nl: 'Teeltgids →',
    en: 'Growing guide →',
    de: 'Anbauanleitung →',
    fr: 'Guide de culture →',
  );
  static const growthLog = LocalizedText(
    nl: 'Groeilog',
    en: 'Growth log',
    de: 'Verlauf',
    fr: 'Historique',
  );
  static const logHarvest = LocalizedText(
    nl: 'Oogst loggen',
    en: 'Log harvest',
    de: 'Ernte eintragen',
    fr: 'Noter une récolte',
  );
  static const harvestLogged = LocalizedText(
    nl: 'Oogst gelogd',
    en: 'Harvest logged',
    de: 'Ernte eingetragen',
    fr: 'Récolte notée',
  );
  static LocalizedText movedToPlanning(String crop) => LocalizedText(
    nl: '$crop staat weer bij Gepland',
    en: '$crop moved to planning',
    de: '$crop ist wieder in der Planung',
    fr: '$crop est de retour dans Planifié',
  );
  static const noEntriesYet = LocalizedText(
    nl: 'Nog geen notities. Voeg er een toe om de tijdlijn te starten.',
    en: 'No entries yet. Add one to start the timeline.',
    de: 'Noch keine Einträge. Füg einen hinzu, um die Zeitleiste zu starten.',
    fr: 'Pas encore d\'entrées. Ajoutes-en une pour lancer la chronologie.',
  );
  static const howMuch = LocalizedText(
    nl: 'Hoeveel?',
    en: 'How much?',
    de: 'Wie viel?',
    fr: 'Combien ?',
  );
  static const howMuchHint = LocalizedText(
    nl: 'bijv. 6 of 0,4',
    en: 'e.g. 6 or 0.4',
    de: 'z. B. 6 oder 0,4',
    fr: 'ex. 6 ou 0,4',
  );
  static const pieces = LocalizedText(
    nl: 'stuks',
    en: 'pieces',
    de: 'Stück',
    fr: 'pièces',
  );
  static const saveHarvest = LocalizedText(
    nl: 'Oogst opslaan',
    en: 'Save harvest',
    de: 'Ernte speichern',
    fr: 'Enregistrer la récolte',
  );
  static const editPlant = LocalizedText(
    nl: 'Plant bewerken',
    en: 'Edit plant',
    de: 'Pflanze bearbeiten',
    fr: 'Modifier la plante',
  );
  static const potSizeLitres = LocalizedText(
    nl: 'Potmaat (liter)',
    en: 'Pot size (litres)',
    de: 'Topfgröße (Liter)',
    fr: 'Taille du pot (litres)',
  );
  static const leaveBlankInGround = LocalizedText(
    nl: 'leeg laten voor in de volle grond',
    en: 'leave blank for in-ground',
    de: 'leer lassen, wenn im Boden',
    fr: 'laisse vide si en pleine terre',
  );
  static const planted = LocalizedText(
    nl: 'Geplant',
    en: 'Planted',
    de: 'Gepflanzt',
    fr: 'Planté',
  );
  static const growthStage = LocalizedText(
    nl: 'Groeifase',
    en: 'Growth stage',
    de: 'Wachstumsphase',
    fr: 'Stade de croissance',
  );
  static const yourPath = LocalizedText(
    nl: 'Jouw pad',
    en: 'Your path',
    de: 'Dein Pfad',
    fr: 'Ton parcours',
  );
  static const journal = LocalizedText(
    nl: 'Logboek',
    en: 'Journal',
    de: 'Tagebuch',
    fr: 'Journal',
  );
  static const yourSeason = LocalizedText(
    nl: 'Jouw seizoen',
    en: 'Your season',
    de: 'Deine Saison',
    fr: 'Ta saison',
  );
  static const bedFreesUp = LocalizedText(
    nl: 'Plek komt vrij',
    en: 'Bed frees up',
    de: 'Beet wird frei',
    fr: 'Le carré se libère',
  );
  static const about = LocalizedText(
    nl: 'Over',
    en: 'About',
    de: 'Infos',
    fr: 'À propos',
  );
  static const yourCrops = LocalizedText(
    nl: 'Jouw gewassen',
    en: 'Your crops',
    de: 'Deine Pflanzen',
    fr: 'Tes plantes',
  );
  static const plannedSection = LocalizedText(
    nl: 'Gepland',
    en: 'Planned',
    de: 'Geplant',
    fr: 'Planifié',
  );
  static const types = LocalizedText(
    nl: 'Rassen',
    en: 'Types',
    de: 'Sorten',
    fr: 'Variétés',
  );

  /// A crop page's sections: the jump chip and the heading say the same thing.
  static LocalizedText cropSection(String id) => switch (id) {
    'Calendar' => const LocalizedText(
      nl: 'Kalender',
      en: 'Calendar',
      de: 'Kalender',
      fr: 'Calendrier',
    ),
    'Timeline' => const LocalizedText(
      nl: 'Tijdlijn',
      en: 'Timeline',
      de: 'Zeitleiste',
      fr: 'Chronologie',
    ),
    'Difficulty' => const LocalizedText(
      nl: 'Moeilijkheid',
      en: 'Difficulty',
      de: 'Schwierigkeit',
      fr: 'Difficulté',
    ),
    'Location' => const LocalizedText(
      nl: 'Standplaats',
      en: 'Location',
      de: 'Standort',
      fr: 'Emplacement',
    ),
    'Soil' => const LocalizedText(
      nl: 'Grond',
      en: 'Soil',
      de: 'Boden',
      fr: 'Sol',
    ),
    'How-tos' => const LocalizedText(
      nl: 'Zo doe je het',
      en: 'How-tos',
      de: 'Anleitungen',
      fr: 'Pas à pas',
    ),
    'Neighbours' => const LocalizedText(
      nl: 'Buren',
      en: 'Neighbours',
      de: 'Nachbarn',
      fr: 'Voisins',
    ),
    'Benefits' => const LocalizedText(
      nl: 'Waarom telen',
      en: 'Benefits',
      de: 'Vorteile',
      fr: 'Bienfaits',
    ),
    'FAQ' => const LocalizedText(nl: 'Vragen', en: 'FAQ', de: 'FAQ', fr: 'FAQ'),
    _ => LocalizedText(nl: id, en: id, de: id, fr: id),
  };
  static const plantingCalendar = LocalizedText(
    nl: 'Zaaikalender',
    en: 'Planting calendar',
    de: 'Aussaatkalender',
    fr: 'Calendrier des semis',
  );
  static const growthTimeline = LocalizedText(
    nl: 'Groeitijdlijn',
    en: 'Growth timeline',
    de: 'Wachstumsverlauf',
    fr: 'Chronologie de croissance',
  );
  static const suitableLocation = LocalizedText(
    nl: 'Geschikte standplaats',
    en: 'Suitable location',
    de: 'Geeigneter Standort',
    fr: 'Emplacement adapté',
  );
  static const soilPrep = LocalizedText(
    nl: 'Grond voorbereiden',
    en: 'Soil prep',
    de: 'Bodenvorbereitung',
    fr: 'Préparation du sol',
  );
  static const whyGrowIt = LocalizedText(
    nl: 'Waarom telen',
    en: 'Why grow it',
    de: 'Warum anbauen',
    fr: 'Pourquoi la cultiver',
  );
  static const comingSoil = LocalizedText(
    nl: 'Grond voorbereiden',
    en: 'Soil preparation',
    de: 'Bodenvorbereitung',
    fr: 'Préparation du sol',
  );
  static const comingHowTos = LocalizedText(
    nl: 'Stap voor stap per fase',
    en: 'Step-by-step how-tos per stage',
    de: 'Schritt-für-Schritt-Anleitungen pro Phase',
    fr: 'Guides pas à pas pour chaque stade',
  );
  static const comingFaq = LocalizedText(
    nl: 'Vragen, nagekeken door telers',
    en: 'Grower-reviewed FAQ',
    de: 'Von Gärtnern geprüfte FAQ',
    fr: 'FAQ relue par des jardiniers',
  );
  static const comingBenefits = LocalizedText(
    nl: 'Voeding en gezondheid (NEVO)',
    en: 'Nutrition and benefits (NEVO)',
    de: 'Nährwerte und Vorteile (NEVO)',
    fr: 'Nutrition et bienfaits (NEVO)',
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
    fr:
        '${what.pick('fr')} : en cours d\'écriture et de vérification pour les '
        'jardins néerlandais. Arrive avec la mise à jour du contenu.',
  );

  /// Said above a guide we only have in one language yet.
  static LocalizedText guideOnlyIn(String lang) => switch (lang) {
    'de' => const LocalizedText(
      nl: 'Deze uitleg is er nu alleen in het Duits.',
      en: 'This guide is in German for now.',
      de: 'Diese Anleitung gibt es vorerst nur auf Deutsch.',
      fr: 'Ce guide n\'existe pour l\'instant qu\'en allemand.',
    ),
    'nl' => const LocalizedText(
      nl: 'Deze uitleg is er nu alleen in het Nederlands.',
      en: 'This guide is in Dutch for now.',
      de: 'Diese Anleitung gibt es vorerst nur auf Niederländisch.',
      fr: 'Ce guide n\'existe pour l\'instant qu\'en néerlandais.',
    ),
    'fr' => const LocalizedText(
      nl: 'Deze uitleg is er nu alleen in het Frans.',
      en: 'This guide is in French for now.',
      de: 'Diese Anleitung gibt es vorerst nur auf Französisch.',
      fr: 'Ce guide n\'existe pour l\'instant qu\'en français.',
    ),
    _ => const LocalizedText(
      nl: 'Deze uitleg is er nu alleen in het Engels.',
      en: 'This guide is in English for now.',
      de: 'Diese Anleitung gibt es vorerst nur auf Englisch.',
      fr: 'Ce guide n\'existe pour l\'instant qu\'en anglais.',
    ),
  };
  static LocalizedText atSupplier(String supplier) => LocalizedText(
    nl: 'bij $supplier',
    en: 'at $supplier',
    de: 'bei $supplier',
    fr: 'chez $supplier',
  );
  static const oftenOn = LocalizedText(
    nl: 'Vaak bij',
    en: 'Often on',
    de: 'Häufig an',
    fr: 'Souvent sur',
  );
  static const insightsForYou = LocalizedText(
    nl: 'Wat nu belangrijk is',
    en: 'Insights for you',
    de: 'Tipps für dich',
    fr: 'Conseils pour toi',
  );
  static LocalizedText plantedOn(String day) => LocalizedText(
    nl: 'geplant $day',
    en: 'planted $day',
    de: 'gepflanzt am $day',
    fr: 'planté le $day',
  );
  static const countsTowardsTally = LocalizedText(
    nl: 'Telt mee voor je seizoensoogst.',
    en: 'Counts towards your season tally.',
    de: 'Zählt zu deiner Saisonbilanz.',
    fr: 'Compte dans ton bilan de saison.',
  );
  static const noShopPrice = LocalizedText(
    nl:
        'Voor dit gewas is nog geen winkelprijs bekend, dus het telt mee voor '
        'de opbrengst maar niet voor het bespaarde bedrag.',
    en:
        'This crop has no shop price yet, so it counts towards the yield but '
        'not towards money saved.',
    de: 'Für diese Pflanze gibt es noch keinen Ladenpreis, darum zählt sie zum Ertrag, aber nicht zum gesparten Geld.',
    fr: 'Cette plante n\'a pas encore de prix en magasin, elle compte donc dans le rendement mais pas dans l\'argent économisé.',
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
    fr:
        'Ton bilan compte cette plante par ${unit.pick('fr')}, donc ça '
        's\'ajoute au rendement mais pas à l\'argent économisé.',
  );
  static const unitKg = LocalizedText(nl: 'kg', en: 'kg', de: 'kg', fr: 'kg');

  // ── the growth log ────────────────────────────────────────────────────────
  static LocalizedText howIsItDoing(LocalizedText crop) => LocalizedText(
    nl: 'Hoe gaat het met je ${crop.nl}?',
    en: 'How is your ${crop.en} doing?',
    de: '${crop.pick('de')}: Wie läuft es?',
    fr: '${crop.pick('fr')} : comment ça pousse ?',
  );
  static LocalizedText photosCount(int n) => LocalizedText(
    nl: "Foto's ($n/9)",
    en: 'Photos ($n/9)',
    de: 'Fotos ($n/9)',
    fr: 'Photos ($n/9)',
  );
  static const noteOptional = LocalizedText(
    nl: 'Notitie (optioneel)',
    en: 'Note (optional)',
    de: 'Notiz (optional)',
    fr: 'Note (facultatif)',
  );
  static const noteHint = LocalizedText(
    nl: 'Eerste bloemen, luis op de toppen…',
    en: 'First flowers, aphids on the tips…',
    de: 'Erste Blüten, Läuse an den Spitzen…',
    fr: 'Premières fleurs, pucerons sur les pointes…',
  );
  static const saveLog = LocalizedText(
    nl: 'Log opslaan',
    en: 'Save log',
    de: 'Eintrag speichern',
    fr: 'Enregistrer l\'entrée',
  );
  static const moodBad = LocalizedText(
    nl: 'Slecht',
    en: 'Bad',
    de: 'Schlecht',
    fr: 'Mauvais',
  );
  static const moodOkay = LocalizedText(
    nl: 'Gaat wel',
    en: 'Okay',
    de: 'Okay',
    fr: 'Moyen',
  );
  static const moodGood = LocalizedText(
    nl: 'Goed',
    en: 'Good',
    de: 'Gut',
    fr: 'Bien',
  );
  static const moodExcellent = LocalizedText(
    nl: 'Uitstekend',
    en: 'Excellent',
    de: 'Super',
    fr: 'Excellent',
  );
  static const stageStarting = LocalizedText(
    nl: 'Gestart',
    en: 'Starting',
    de: 'Beginn',
    fr: 'Début',
  );
  static const stageSeedling = LocalizedText(
    nl: 'Zaailing',
    en: 'Seedling',
    de: 'Sämling',
    fr: 'Jeune plant',
  );
  static const stageVegetative = LocalizedText(
    nl: 'Groeiend',
    en: 'Vegetative',
    de: 'Wachstum',
    fr: 'Croissance',
  );
  static const stageFlowering = LocalizedText(
    nl: 'Bloeiend',
    en: 'Flowering',
    de: 'Blüte',
    fr: 'Floraison',
  );
  static const stageHarvesting = LocalizedText(
    nl: 'Oogsten',
    en: 'Harvesting',
    de: 'Ernte',
    fr: 'Récolte',
  );
  static const stageHarvested = LocalizedText(
    nl: 'Geoogst',
    en: 'Harvested',
    de: 'Geerntet',
    fr: 'Récolté',
  );

  // ── adding a plant ────────────────────────────────────────────────────────
  static const setPlantDetails = LocalizedText(
    nl: 'Plantgegevens',
    en: 'Set plant details',
    de: 'Pflanzendetails festlegen',
    fr: 'Détails de la plante',
  );
  static const plantDetailsSub = LocalizedText(
    nl: 'Hiermee bepalen we de oogsttiming en de herinneringen.',
    en: 'Your input sets the harvest timing and care reminders.',
    de: 'Deine Angaben bestimmen den Erntezeitpunkt und die Pflege-Erinnerungen.',
    fr: 'Tes réponses fixent le moment de la récolte et les rappels d\'entretien.',
  );
  static const plantingDate = LocalizedText(
    nl: 'Plantdatum',
    en: 'Planting date',
    de: 'Pflanzdatum',
    fr: 'Date de plantation',
  );
  static const howDidItStart = LocalizedText(
    nl: 'Hoe is het begonnen?',
    en: 'How did it start?',
    de: 'Wie hat sie angefangen?',
    fr: 'Comment a-t-elle commencé ?',
  );
  static const whereDoesItLive = LocalizedText(
    nl: 'Waar staat het?',
    en: 'Where does it live?',
    de: 'Wo wächst sie?',
    fr: 'Où pousse-t-elle ?',
  );
  static LocalizedText atLeastLitres(int litres) => LocalizedText(
    nl: 'Minstens $litres L voor dit gewas',
    en: 'At least $litres L for this crop',
    de: 'Mindestens $litres L für diese Pflanze',
    fr: 'Au moins $litres L pour cette plante',
  );
  static const varietyOptional = LocalizedText(
    nl: 'Ras (optioneel)',
    en: 'Variety (optional)',
    de: 'Sorte (optional)',
    fr: 'Variété (facultatif)',
  );
  static const varietyHint = LocalizedText(
    nl: 'bijv. Moneymaker',
    en: 'e.g. Moneymaker',
    de: 'z. B. Moneymaker',
    fr: 'ex. Moneymaker',
  );

  // ── logging a node ────────────────────────────────────────────────────────
  static const didItToday = LocalizedText(
    nl: 'Vandaag gedaan',
    en: 'Did it today',
    de: 'Heute erledigt',
    fr: 'Fait aujourd\'hui',
  );
  static const didItOn = LocalizedText(
    nl: 'Ik deed dit op…',
    en: 'I did this on…',
    de: 'Erledigt am…',
    fr: 'Je l\'ai fait le…',
  );
  static const skipThisOne = LocalizedText(
    nl: 'Sla deze over',
    en: 'Skip this one',
    de: 'Diesmal überspringen',
    fr: 'Passer cette fois',
  );
  static const gotIt = LocalizedText(
    nl: 'Duidelijk',
    en: 'Got it',
    de: 'Verstanden',
    fr: 'Compris',
  );
  static const now = LocalizedText(
    nl: 'Nu',
    en: 'Now',
    de: 'Jetzt',
    fr: 'Maintenant',
  );
  static const skipped = LocalizedText(
    nl: 'Overgeslagen',
    en: 'Skipped',
    de: 'Übersprungen',
    fr: 'Passé',
  );
  static LocalizedText doneOn(String day) => LocalizedText(
    nl: 'Gedaan $day',
    en: 'Done $day',
    de: 'Erledigt am $day',
    fr: 'Fait le $day',
  );
  static LocalizedText movedFrom(String day, LocalizedText reason) =>
      LocalizedText(
        nl: 'Verzet vanaf $day · ${reason.nl}',
        en: 'Moved from $day · ${reason.en}',
        de: 'Verschoben vom $day · ${reason.pick('de')}',
        fr: 'Déplacé du $day · ${reason.pick('fr')}',
      );

  // ── the planner ───────────────────────────────────────────────────────────
  static const gardenPlanner = LocalizedText(
    nl: 'Tuinplanner',
    en: 'Garden planner',
    de: 'Gartenplaner',
    fr: 'Planificateur de potager',
  );
  static const plannerBlurb = LocalizedText(
    nl: 'Leg je bed uit in vakjes van 30 cm.',
    en: 'Lay out your bed in 30 cm squares.',
    de: 'Plane dein Beet in 30-cm-Quadraten.',
    fr: 'Organise ton carré en cases de 30 cm.',
  );
  static const save = LocalizedText(
    nl: 'Opslaan',
    en: 'Save',
    de: 'Speichern',
    fr: 'Enregistrer',
  );
  static const layoutSaved = LocalizedText(
    nl: 'Indeling opgeslagen',
    en: 'Layout saved',
    de: 'Plan gespeichert',
    fr: 'Plan enregistré',
  );
  static const pickACrop = LocalizedText(
    nl: 'Kies hieronder een gewas en tik dan op de vakjes.',
    en: 'Pick a crop below, then tap cells.',
    de: 'Wähl unten eine Pflanze und tippe dann auf Felder.',
    fr: 'Choisis une plante ci-dessous, puis touche des cases.',
  );
  static LocalizedText painting(LocalizedText crop) => LocalizedText(
    nl: '${crop.nl} plaatsen. Tik een gevuld vakje om het leeg te maken.',
    en: 'Painting ${crop.en}. Tap a filled cell to clear it.',
    de: '${crop.pick('de')} setzen. Tippe auf ein volles Feld, um es zu leeren.',
    fr: 'Placement : ${crop.pick('fr')}. Touche une case remplie pour la vider.',
  );
  static const redCells = LocalizedText(
    nl: 'Rode vakjes staan naast een gewas dat ze niet liggen.',
    en: 'Red cells sit next to a crop they dislike.',
    de: 'Rote Felder liegen neben einem schlechten Nachbarn.',
    fr: 'Les cases rouges sont à côté d\'un mauvais voisin.',
  );
  static const planIt = LocalizedText(
    nl: 'Plan het',
    en: 'Plan it',
    de: 'Einplanen',
    fr: 'Planifier',
  );
  static LocalizedText addedToPlanning(String crop) => LocalizedText(
    nl: '$crop staat bij Gepland',
    en: '$crop added to Planning',
    de: '$crop ist jetzt in der Planung',
    fr: '$crop ajouté à Planifié',
  );

  // ── profile ───────────────────────────────────────────────────────────────
  static const dayStreak = LocalizedText(
    nl: 'Dagen op rij',
    en: 'Day streak',
    de: 'Tage in Folge',
    fr: 'Jours d\'affilée',
  );
  static const growingNow = LocalizedText(
    nl: 'Groeit nu',
    en: 'Growing now',
    de: 'Wächst gerade',
    fr: 'En culture',
  );
  static const harvested = LocalizedText(
    nl: 'Geoogst',
    en: 'Harvested',
    de: 'Geerntet',
    fr: 'Récolté',
  );
  static const yourGarden = LocalizedText(
    nl: 'Jouw tuin',
    en: 'Your garden',
    de: 'Dein Garten',
    fr: 'Ton potager',
  );
  static const region = LocalizedText(
    nl: 'Regio',
    en: 'Region',
    de: 'Region',
    fr: 'Région',
  );
  static const settingsAndSync = LocalizedText(
    nl: 'Instellingen en sync',
    en: 'Settings and sync',
    de: 'Einstellungen und Sync',
    fr: 'Réglages et synchro',
  );
  static const signInToSync = LocalizedText(
    nl: 'Log in om te synchroniseren',
    en: 'Sign in to sync',
    de: 'Für Sync anmelden',
    fr: 'Se connecter pour synchroniser',
  );
  static const yourName = LocalizedText(
    nl: 'Je naam',
    en: 'Your name',
    de: 'Dein Name',
    fr: 'Ton prénom',
  );
  static const gardener = LocalizedText(
    nl: 'Tuinier',
    en: 'Gardener',
    de: 'Gärtner',
    fr: 'Jardinier',
  );
  static const onThisDeviceOnly = LocalizedText(
    nl: 'Alleen op deze telefoon',
    en: 'On this device only',
    de: 'Nur auf diesem Gerät',
    fr: 'Sur cet appareil uniquement',
  );

  // ── scanning ──────────────────────────────────────────────────────────────
  static const identifyAPlant = LocalizedText(
    nl: 'Herken een plant',
    en: 'Identify a plant',
    de: 'Pflanze bestimmen',
    fr: 'Identifier une plante',
  );
  static const diagnoseAPlant = LocalizedText(
    nl: 'Stel een diagnose',
    en: 'Diagnose a plant',
    de: 'Pflanze untersuchen',
    fr: 'Diagnostiquer une plante',
  );
  static const whatIsIt = LocalizedText(
    nl: 'Wat is dit?',
    en: 'What is it?',
    de: 'Was ist das?',
    fr: 'Qu\'est-ce que c\'est ?',
  );
  static const isItOk = LocalizedText(
    nl: 'Is het gezond?',
    en: 'Is it OK?',
    de: 'Alles okay?',
    fr: 'Tout va bien ?',
  );
  static const takePhoto = LocalizedText(
    nl: 'Foto maken',
    en: 'Take photo',
    de: 'Foto aufnehmen',
    fr: 'Prendre une photo',
  );
  static const fromPhotos = LocalizedText(
    nl: "Uit foto's",
    en: 'From photos',
    de: 'Aus Fotos',
    fr: 'Depuis les photos',
  );
  static const noConnectionScan = LocalizedText(
    nl: 'Geen verbinding. Scannen heeft internet nodig; de rest werkt offline.',
    en: 'No connection. Scans need the network; everything else works offline.',
    de: 'Keine Verbindung. Scans brauchen das Netz; alles andere funktioniert offline.',
    fr: 'Pas de connexion. Les scans ont besoin du réseau ; tout le reste marche hors ligne.',
  );
  static const notOneOfOurCrops = LocalizedText(
    nl: 'Nog niet een van onze gewassen',
    en: 'Not one of our crops yet',
    de: 'Noch nicht in unserer Liste',
    fr: 'Pas encore dans notre liste',
  );
  static const noGuideYet = LocalizedText(
    nl: 'Hier is nog geen gids voor',
    en: 'No guide for this one yet',
    de: 'Dafür gibt es noch keine Anleitung',
    fr: 'Pas encore de guide pour celle-ci',
  );
  static LocalizedText scansUsed(int used, int limit) => LocalizedText(
    nl: '$used van $limit scans vandaag gebruikt',
    en: '$used of $limit scans used today',
    de: '$used von $limit Scans heute genutzt',
    fr: '$used scans sur $limit utilisés aujourd\'hui',
  );

  // ── the paywall ───────────────────────────────────────────────────────────
  static const payOnce = LocalizedText(
    nl:
        'Betaal één keer voor meer ruimte. Geen proefperiode, geen kaart, geen '
        'verrassing bij verlenging.',
    en: 'Pay once for more room. No trial, no card, no auto-renew surprise.',
    de: 'Einmal zahlen für mehr Platz. Kein Probe-Abo, keine Karte, keine Verlängerungs-Überraschung.',
    fr: 'Paie une fois pour plus de place. Pas d\'essai, pas de carte, pas de renouvellement surprise.',
  );
  static const oneMoment = LocalizedText(
    nl: 'Momentje…',
    en: 'One moment…',
    de: 'Einen Moment…',
    fr: 'Un instant…',
  );
  static const keepItFree = LocalizedText(
    nl: 'Hou het gratis',
    en: 'Keep it free',
    de: 'Gratis bleiben',
    fr: 'Rester gratuit',
  );
  static LocalizedText continueWith(String plan) => LocalizedText(
    nl: 'Verder met $plan',
    en: 'Continue with $plan',
    de: 'Weiter mit $plan',
    fr: 'Continuer avec $plan',
  );
  static const purchasesOpenLater = LocalizedText(
    nl: 'Kopen is nu niet mogelijk. Er wordt niets afgeschreven.',
    en: 'Purchases are not available right now. Nothing is charged.',
    de: 'Käufe sind gerade nicht verfügbar. Es wird nichts berechnet.',
    fr: 'Les achats ne sont pas disponibles pour l\'instant. Rien n\'est facturé.',
  );
  static const purchasesRestored = LocalizedText(
    nl: 'Aankopen hersteld.',
    en: 'Purchases restored.',
    de: 'Käufe wiederhergestellt.',
    fr: 'Achats restaurés.',
  );
  static const nothingToRestore = LocalizedText(
    nl: 'Geen eerdere aankopen gevonden voor dit Apple-account.',
    en: 'No earlier purchases found for this Apple account.',
    de: 'Keine früheren Käufe für diesen Apple-Account gefunden.',
    fr: 'Aucun achat précédent trouvé pour ce compte Apple.',
  );
  static const restorePurchases = LocalizedText(
    nl: 'Aankopen herstellen',
    en: 'Restore purchases',
    de: 'Käufe wiederherstellen',
    fr: 'Restaurer les achats',
  );
  static const lifetimeNothingEver = LocalizedText(
    nl: 'Levenslang: nooit iets op te zeggen.',
    en: 'Lifetime: nothing to cancel, ever.',
    de: 'Einmalkauf: nie etwas zu kündigen.',
    fr: 'Achat unique : jamais rien à résilier.',
  );

  // ── where you grow ────────────────────────────────────────────────────────
  static const whereDoYouGrow = LocalizedText(
    nl: 'Waar tuinier je?',
    en: 'Where do you grow?',
    de: 'Wo gärtnerst du?',
    fr: 'Où cultives-tu ?',
  );
  static const townOrPostcode = LocalizedText(
    nl: 'Plaats, regio of postcode',
    en: 'Town, region or postcode',
    de: 'Ort, Region oder Postleitzahl',
    fr: 'Ville, région ou code postal',
  );
  static LocalizedText usePostcode(String code) => LocalizedText(
    nl: 'Gebruik postcode $code',
    en: 'Use postcode $code',
    de: 'Postleitzahl $code nutzen',
    fr: 'Utiliser le code postal $code',
  );
  static const looksUpFrost = LocalizedText(
    nl: 'Zoekt de vorstdatums voor dat gebied op.',
    en: 'Looks up the frost dates for that cell.',
    de: 'Sucht die Frostdaten für dieses Gebiet.',
    fr: 'Cherche les dates de gel pour cette zone.',
  );
  static const snapToRegion = LocalizedText(
    nl: 'Kies de dichtstbijzijnde teeltregio',
    en: 'Snap to the nearest growing region',
    de: 'Auf die nächste Anbauregion setzen',
    fr: 'Prendre la région de culture la plus proche',
  );
  static const noLocation = LocalizedText(
    nl: 'Geen locatie gevonden. Kies een regio of vul een postcode in.',
    en: 'Could not get a location. Pick a region or enter a postcode.',
    de: 'Kein Standort gefunden. Wähl eine Region oder gib eine Postleitzahl ein.',
    fr: 'Position introuvable. Choisis une région ou entre un code postal.',
  );
  static const postcodeNotFound = LocalizedText(
    nl: 'Postcode niet gevonden (verwacht 1234AB), of je bent offline.',
    en: 'Postcode not found (expected 1234AB), or you are offline.',
    de: 'Postleitzahl nicht gefunden (erwartet 1234AB) oder du bist offline.',
    fr: 'Code postal introuvable (format attendu 1234AB), ou tu es hors ligne.',
  );
  static const useMyLocation = LocalizedText(
    nl: 'Gebruik mijn locatie',
    en: 'Use my location',
    de: 'Meinen Standort nutzen',
    fr: 'Utiliser ma position',
  );
  static const lookingUp = LocalizedText(
    nl: 'Zoeken…',
    en: 'Looking up…',
    de: 'Suche…',
    fr: 'Recherche…',
  );
  static const postcodeHint = LocalizedText(
    nl: 'Postcode, bijv. 1012AB',
    en: 'Postcode, e.g. 1012AB',
    de: 'Postleitzahl, z. B. 1012AB',
    fr: 'Code postal, ex. 1012AB',
  );
  static const lookUp = LocalizedText(
    nl: 'Zoek op',
    en: 'Look up',
    de: 'Suchen',
    fr: 'Chercher',
  );
  static const orPickRegion = LocalizedText(
    nl: 'Of kies een regio',
    en: 'Or pick a region',
    de: 'Oder wähl eine Region',
    fr: 'Ou choisis une région',
  );

  // ── feedback on content ───────────────────────────────────────────────────
  static const isThisUseful = LocalizedText(
    nl: 'Heb je hier iets aan?',
    en: 'Is this information useful?',
    de: 'Ist diese Info hilfreich?',
    fr: 'Cette info t\'est utile ?',
  );
  static const reportError = LocalizedText(
    nl: 'Fout melden',
    en: 'Report error',
    de: 'Fehler melden',
    fr: 'Signaler une erreur',
  );
  static const whatIsWrong = LocalizedText(
    nl: 'Wat klopt er niet?',
    en: 'What is wrong?',
    de: 'Was stimmt nicht?',
    fr: 'Qu\'est-ce qui ne va pas ?',
  );
  static const whatIsWrongHint = LocalizedText(
    nl: 'bijv. het zaaivenster is te vroeg voor Groningen',
    en: 'e.g. sowing window is too early for Groningen',
    de: 'z. B. Aussaatfenster ist für Groningen zu früh',
    fr: 'ex. la période de semis est trop tôt pour Groningue',
  );
  static const send = LocalizedText(
    nl: 'Versturen',
    en: 'Send',
    de: 'Senden',
    fr: 'Envoyer',
  );
  static const thanksChecked = LocalizedText(
    nl: 'Dank je. We kijken elke melding binnen een week na.',
    en: 'Thanks. We check every report within a week.',
    de: 'Danke. Wir prüfen jede Meldung innerhalb einer Woche.',
    fr: 'Merci. On vérifie chaque signalement sous une semaine.',
  );
  static const thanksFeedback = LocalizedText(
    nl: 'Dank voor je feedback.',
    en: 'Thanks for the feedback.',
    de: 'Danke für das Feedback.',
    fr: 'Merci pour ton retour.',
  );
  static const thanksNoted = LocalizedText(
    nl: 'Dank, genoteerd.',
    en: 'Thanks, noted.',
    de: 'Danke, notiert.',
    fr: 'Merci, c\'est noté.',
  );
  static const likeThis = LocalizedText(
    nl: 'Hier heb ik wat aan',
    en: 'I like this',
    de: 'Gefällt mir',
    fr: 'J\'aime bien',
  );
  static const errorInContent = LocalizedText(
    nl: 'Fout in de inhoud',
    en: 'Error in content',
    de: 'Fehler im Inhalt',
    fr: 'Erreur dans le contenu',
  );
  static const suggestion = LocalizedText(
    nl: 'Suggestie',
    en: 'Suggestion',
    de: 'Vorschlag',
    fr: 'Suggestion',
  );

  static const overallDifficulty = LocalizedText(
    nl: 'Moeilijkheid',
    en: 'Overall difficulty',
    de: 'Schwierigkeit insgesamt',
    fr: 'Difficulté globale',
  );

  /// Problem kind pills on the Diagnose tab (data carries the English key).
  static LocalizedText problemKind(String kind) => switch (kind) {
    'pest' => const LocalizedText(
      nl: 'plaag',
      en: 'pest',
      de: 'Schädling',
      fr: 'ravageur',
    ),
    'disease' => const LocalizedText(
      nl: 'ziekte',
      en: 'disease',
      de: 'Krankheit',
      fr: 'maladie',
    ),
    'disorder' => const LocalizedText(
      nl: 'stoornis',
      en: 'disorder',
      de: 'Störung',
      fr: 'trouble',
    ),
    _ => LocalizedText(nl: kind, en: kind, de: kind, fr: kind),
  };

  static const draftBadge = LocalizedText(
    nl: 'Concept',
    en: 'Draft',
    de: 'Entwurf',
    fr: 'Brouillon',
  );
  static const draftBadgeLong = LocalizedText(
    nl: 'Concept, nog niet gecontroleerd',
    en: 'Draft, not verified yet',
    de: 'Entwurf, noch nicht geprüft',
    fr: 'Brouillon, pas encore vérifié',
  );

  // ── onboarding ────────────────────────────────────────────────────────────
  static const skip = LocalizedText(
    nl: 'Overslaan',
    en: 'Skip',
    de: 'Überspringen',
    fr: 'Passer',
  );
  static const alreadyHaveAccount = LocalizedText(
    nl: 'Heb je al een account? Inloggen',
    en: 'Already have an account? Sign in',
    de: 'Schon ein Konto? Anmelden',
    fr: 'Déjà un compte ? Se connecter',
  );
  static const seasonAsOnePath = LocalizedText(
    nl: 'Je seizoen, als één pad',
    en: 'Your season, as one path',
    de: 'Deine Saison als ein Pfad',
    fr: 'Ta saison, en un seul parcours',
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
    de: 'Aussaat, Umtopfen, Ernte, die Frostdaten, die das alles bestimmen, und die Monate, in denen noch nichts geplant ist. Hak einen Schritt ab, und alles danach zieht mit.',
    fr: 'Semis, rempotage, récolte, les dates de gel qui décident de tout, et les mois où rien n\'est encore planifié. Coche une étape, et tout ce qui suit bouge avec toi.',
  );
  static const frostBackbone = LocalizedText(
    nl:
        'Bepaalt je vorstdatums, de basis onder elke plantdatum. Afgerond op '
        '~1 km, nooit gevolgd.',
    en:
        'Sets your frost dates, the backbone of every planting date. Rounded '
        'to ~1 km, never tracked.',
    de: 'Bestimmt deine Frostdaten, die Grundlage jedes Pflanztermins. Auf ~1 km gerundet, nie verfolgt.',
    fr: 'Fixe tes dates de gel, la base de chaque date de plantation. Arrondi à ~1 km, jamais suivi.',
  );
  static const whatWillYouGrow = LocalizedText(
    nl: 'Wat ga je kweken?',
    en: 'What will you grow?',
    de: 'Was willst du anbauen?',
    fr: 'Que vas-tu cultiver ?',
  );
  static const pickAFewToStart = LocalizedText(
    nl: 'Kies er een paar om te beginnen. Later bijzetten kan altijd.',
    en: 'Pick a few to start. Add more anytime.',
    de: 'Wähl ein paar für den Anfang. Mehr geht jederzeit.',
    fr: 'Choisis-en quelques-unes pour commencer. Tu pourras en ajouter quand tu veux.',
  );
  static const remindBlurb = LocalizedText(
    nl:
        'Een zetje op de dag zelf? Eén herinnering per ochtend, alleen als er '
        'iets te doen is, en stil als het geregend heeft.',
    en:
        'Want a nudge on the day? One reminder a morning, only when there is '
        'something to do, and it stays quiet when it rained.',
    de: 'Ein kleiner Stups am richtigen Tag? Eine Erinnerung am Morgen, nur wenn etwas zu tun ist, und still, wenn es geregnet hat.',
    fr: 'Un petit coup de pouce le jour J ? Un rappel le matin, seulement s\'il y a quelque chose à faire, et rien quand il a plu.',
  );
  static const remindMe = LocalizedText(
    nl: 'Herinner me',
    en: 'Remind me',
    de: 'Erinnere mich',
    fr: 'Me le rappeler',
  );
  static const maybeLater = LocalizedText(
    nl: 'Misschien later',
    en: 'Maybe later',
    de: 'Vielleicht später',
    fr: 'Plus tard',
  );

  // ── the paywall's headline ────────────────────────────────────────────────
  static const oneFreeGarden = LocalizedText(
    nl: 'Eén gratis tuin,\nvoor altijd.',
    en: 'One free garden,\nfree forever.',
    de: 'Ein Garten gratis,\nfür immer.',
    fr: 'Un potager gratuit,\npour toujours.',
  );

  // ── odds and ends ─────────────────────────────────────────────────────────
  static const whatToGrowShort = LocalizedText(
    nl: 'Wat te zaaien in…',
    en: 'What to grow in…',
    de: 'Was anbauen im…',
    fr: 'Que cultiver en…',
  );
  static const whichPlant = LocalizedText(
    nl: 'Welke plant?',
    en: 'Which plant?',
    de: 'Welche Pflanze?',
    fr: 'Quelle plante ?',
  );
  static LocalizedText plantIn(String months) => LocalizedText(
    nl: 'Planten in: $months',
    en: 'Plant in: $months',
    de: 'Pflanzzeit: $months',
    fr: 'Planter en : $months',
  );
  static LocalizedText sources(String list) => LocalizedText(
    nl: 'Bronnen: $list',
    en: 'Sources: $list',
    de: 'Quellen: $list',
    fr: 'Sources : $list',
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
    fr:
        'Ces dates dépendent du gel (calées sur $anchor pour $region), elles '
        'se décalent donc avec ta région, pas avec un calendrier fixe.',
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
    fr:
        'Pour $region, ta première récolte tombe vers le $date, calculée à '
        'partir des dates de gel de la région.',
  );

  // ── the weather card on Home ──────────────────────────────────────────────
  static const weatherToday = LocalizedText(
    nl: 'Het weer vandaag',
    en: "Today's weather",
    de: 'Wetter heute',
    fr: 'Météo du jour',
  );
  static LocalizedText weatherRange(int high, int low) => LocalizedText(
    nl: '$high° / $low°',
    en: '$high° / $low°',
    de: '$high° / $low°',
    fr: '$high° / $low°',
  );
  static LocalizedText weatherRain(String mm) => LocalizedText(
    nl: '$mm mm regen',
    en: '$mm mm rain',
    de: '$mm mm Regen',
    fr: '$mm mm de pluie',
  );
  static const weatherDry = LocalizedText(
    nl: 'Droog',
    en: 'Dry',
    de: 'Trocken',
    fr: 'Sec',
  );
  static const weatherNothingMoved = LocalizedText(
    nl: 'Het weer verzet vandaag niets.',
    en: 'The weather moves nothing today.',
    de: 'Das Wetter verschiebt heute nichts.',
    fr: 'La météo ne déplace rien aujourd\'hui.',
  );
  static const weatherUnavailable = LocalizedText(
    nl: 'Geen weerbericht. Het basisschema staat.',
    en: 'No forecast. The base schedule stands.',
    de: 'Keine Vorhersage. Der Grundplan steht.',
    fr: 'Pas de prévisions. Le plan de base tient.',
  );

  /// Open-Meteo WMO condition groups, named for the card and the strip.
  static const weatherClear = LocalizedText(
    nl: 'Helder',
    en: 'Clear',
    de: 'Klar',
    fr: 'Dégagé',
  );
  static const weatherPartlyCloudy = LocalizedText(
    nl: 'Half bewolkt',
    en: 'Partly cloudy',
    de: 'Teils bewölkt',
    fr: 'Partiellement nuageux',
  );
  static const weatherOvercast = LocalizedText(
    nl: 'Bewolkt',
    en: 'Overcast',
    de: 'Bedeckt',
    fr: 'Couvert',
  );
  static const weatherFog = LocalizedText(
    nl: 'Mist',
    en: 'Fog',
    de: 'Nebel',
    fr: 'Brouillard',
  );
  static const weatherDrizzle = LocalizedText(
    nl: 'Motregen',
    en: 'Drizzle',
    de: 'Nieselregen',
    fr: 'Bruine',
  );
  static const weatherRainy = LocalizedText(
    nl: 'Regen',
    en: 'Rain',
    de: 'Regen',
    fr: 'Pluie',
  );
  static const weatherSnow = LocalizedText(
    nl: 'Sneeuw',
    en: 'Snow',
    de: 'Schnee',
    fr: 'Neige',
  );
  static const weatherThunder = LocalizedText(
    nl: 'Onweer',
    en: 'Thunder',
    de: 'Gewitter',
    fr: 'Orage',
  );

  // ── the path's new stops ──────────────────────────────────────────────────
  static const pathChecklistCaption = LocalizedText(
    nl: 'Klusje voor deze maand',
    en: 'A job for this month',
    de: 'Eine Aufgabe für diesen Monat',
    fr: 'Une tâche pour ce mois-ci',
  );
  static LocalizedText pathCompanion(LocalizedText partner) => LocalizedText(
    nl: 'Zet ${partner.nl} erbij',
    en: 'Plant ${partner.en} alongside',
    de: '${partner.pick('de')} dazupflanzen',
    fr: 'Plante ${partner.pick('fr')} à côté',
  );
  static LocalizedText pathCompanionCaption(LocalizedText have) =>
      LocalizedText(
        nl: 'Goede buur voor je ${have.nl}',
        en: 'A good neighbour for your ${have.en}',
        de: 'Ein guter Nachbar für ${have.pick('de')}',
        fr: 'Un bon voisin pour ${have.pick('fr')}',
      );
  static const pathCollectionCaption = LocalizedText(
    nl: 'Een lijstje om uit te kiezen',
    en: 'A list to pick from',
    de: 'Eine Liste zum Auswählen',
    fr: 'Une liste où choisir',
  );

  // ── the settings hub ──────────────────────────────────────────────────────
  static const accessibility = LocalizedText(
    nl: 'Toegankelijkheid',
    en: 'Accessibility',
    de: 'Bedienungshilfen',
    fr: 'Accessibilité',
  );
  static const hapticsTitle = LocalizedText(
    nl: 'Trillingen',
    en: 'Haptics',
    de: 'Haptik',
    fr: 'Vibrations',
  );
  static const hapticsBlurb = LocalizedText(
    nl: 'Een korte trilling bij afvinken en indrukken.',
    en: 'A short buzz when you tick something off or press it.',
    de: 'Ein kurzes Vibrieren, wenn du etwas abhakst oder drückst.',
    fr: 'Une courte vibration quand tu coches ou touches quelque chose.',
  );
  static const reduceMotionTitle = LocalizedText(
    nl: 'Minder beweging',
    en: 'Reduce motion',
    de: 'Bewegung reduzieren',
    fr: 'Réduire les animations',
  );
  static const reduceMotionBlurb = LocalizedText(
    nl:
        'Animaties worden een directe wissel. Staat ook aan als je telefoon '
        'erom vraagt.',
    en:
        'Animations become an instant change. Also on when your phone asks '
        'for it.',
    de: 'Animationen werden zu einem sofortigen Wechsel. Auch an, wenn dein Handy das verlangt.',
    fr: 'Les animations deviennent un changement instantané. Activé aussi quand ton téléphone le demande.',
  );
  static const gardenProfile = LocalizedText(
    nl: 'Je tuin aanpassen',
    en: 'Edit your garden',
    de: 'Garten bearbeiten',
    fr: 'Modifier ton potager',
  );
  static const gardenProfileBlurb = LocalizedText(
    nl: 'Verhuisd, of meer ruimte gevonden?',
    en: 'Moved house, or found more room?',
    de: 'Umgezogen oder mehr Platz gefunden?',
    fr: 'Tu as déménagé, ou trouvé plus de place ?',
  );
  static const gardenSize = LocalizedText(
    nl: 'Oppervlakte',
    en: 'Size',
    de: 'Größe',
    fr: 'Surface',
  );
  static LocalizedText gardenSizeM2(int m2) =>
      LocalizedText(nl: '$m2 m²', en: '$m2 m²', de: '$m2 m²', fr: '$m2 m²');
  static const gardenSizeHint = LocalizedText(
    nl: 'Hoeveel vierkante meter heb je om te telen?',
    en: 'How many square metres do you have to grow in?',
    de: 'Wie viele Quadratmeter hast du zum Anbauen?',
    fr: 'Combien de mètres carrés as-tu pour cultiver ?',
  );
  static const sunHoursLabel = LocalizedText(
    nl: 'Uren zon',
    en: 'Hours of sun',
    de: 'Sonnenstunden',
    fr: 'Heures de soleil',
  );
  static const sunHoursHint = LocalizedText(
    nl: 'Op een heldere dag in juni.',
    en: 'On a clear day in June.',
    de: 'An einem klaren Tag im Juni.',
    fr: 'Par une journée claire de juin.',
  );
  static const gardenSaved = LocalizedText(
    nl: 'Tuin bijgewerkt',
    en: 'Garden updated',
    de: 'Garten aktualisiert',
    fr: 'Potager mis à jour',
  );
  static const faq = LocalizedText(
    nl: 'Veelgestelde vragen',
    en: 'Frequently asked questions',
    de: 'Häufige Fragen',
    fr: 'Questions fréquentes',
  );
  static const helpAndSupport = LocalizedText(
    nl: 'Help en ondersteuning',
    en: 'Help & support',
    de: 'Hilfe & Support',
    fr: 'Aide et assistance',
  );
  static const notSignedIn = LocalizedText(
    nl: 'Niet aangemeld',
    en: 'Not signed in',
    de: 'Nicht angemeldet',
    fr: 'Non connecté',
  );
  static const onThisDevice = LocalizedText(
    nl: 'Op deze telefoon',
    en: 'On this phone',
    de: 'Auf diesem Handy',
    fr: 'Sur ce téléphone',
  );

  // ── searching the problems ────────────────────────────────────────────────
  static const searchProblems = LocalizedText(
    nl: 'Zoek een probleem',
    en: 'Search a problem',
    de: 'Problem suchen',
    fr: 'Chercher un problème',
  );
  static LocalizedText problemsFound(int n) => LocalizedText(
    nl: '$n ${n == 1 ? 'probleem' : 'problemen'}',
    en: '$n problem${n == 1 ? '' : 's'}',
    de: '$n ${n == 1 ? 'Problem' : 'Probleme'}',
    fr: '$n ${n <= 1 ? 'problème' : 'problèmes'}',
  );
  static const noProblemsFound = LocalizedText(
    nl: 'Niets gevonden. Probeer een ander woord.',
    en: 'Nothing found. Try another word.',
    de: 'Nichts gefunden. Versuch ein anderes Wort.',
    fr: 'Rien trouvé. Essaie un autre mot.',
  );

  // ── the path's milestone stops (what the gardener already did) ────────────
  static const pathFirstSow = LocalizedText(
    nl: 'Je eerste zaaisel',
    en: 'Your first sowing',
    de: 'Deine erste Aussaat',
    fr: 'Ton premier semis',
  );
  static LocalizedText pathFirstSowCaption(LocalizedText crop) => LocalizedText(
    nl: 'Het seizoen begon met ${crop.nl}',
    en: 'The season began with ${crop.en}',
    de: 'Die Saison begann mit ${crop.pick('de')}',
    fr: 'La saison a commencé avec ${crop.pick('fr')}',
  );
  static LocalizedText pathHarvest(int n) => LocalizedText(
    nl: 'Oogst nummer $n',
    en: 'Harvest number $n',
    de: 'Ernte Nummer $n',
    fr: 'Récolte n° $n',
  );
  static LocalizedText pathHarvestCaption(LocalizedText crop) => LocalizedText(
    nl: 'Geplukt: ${crop.nl}',
    en: 'Picked: ${crop.en}',
    de: 'Geerntet: ${crop.pick('de')}',
    fr: 'Récolté : ${crop.pick('fr')}',
  );
  static LocalizedText pathStreak(int days) => LocalizedText(
    nl: '$days dagen op rij',
    en: '$days days in a row',
    de: '$days Tage in Folge',
    fr: '$days ${days <= 1 ? 'jour' : 'jours'} d\'affilée',
  );
  static const pathStreakCaption = LocalizedText(
    nl: 'Je hield het vol',
    en: 'You kept it going',
    de: 'Du bist drangeblieben',
    fr: 'Tu as tenu bon',
  );
  static const pathPhotoCompare = LocalizedText(
    nl: 'Kijk hoe ver het is',
    en: 'See how far it has come',
    de: 'Sieh, wie weit sie gekommen ist',
    fr: 'Vois tout le chemin parcouru',
  );
  static LocalizedText pathPhotoCompareCaption(LocalizedText month) =>
      LocalizedText(
        nl: 'Naast je foto van ${month.nl}',
        en: 'Next to your photo from ${month.en}',
        de: 'Neben deinem Foto vom ${month.pick('de')}',
        fr: 'À côté de ta photo prise en ${month.pick('fr')}',
      );

  // ── reminders ─────────────────────────────────────────────────────────────
  static const reminderOneThing = LocalizedText(
    nl: 'Eén ding te doen vandaag',
    en: 'One thing to do today',
    de: 'Heute steht eine Aufgabe an',
    fr: 'Une chose à faire aujourd\'hui',
  );
  static LocalizedText reminderThings(int n) => LocalizedText(
    nl: '$n dingen te doen vandaag',
    en: '$n things to do today',
    de: 'Heute stehen $n Aufgaben an',
    fr: '$n choses à faire aujourd\'hui',
  );

  // ── task and step names (kindLine, nodeKindLine) ──────────────────────────
  static const taskWater = LocalizedText(
    nl: 'Water geven',
    en: 'Water',
    de: 'Gießen',
    fr: 'Arroser',
  );
  static const taskHarvest = LocalizedText(
    nl: 'Oogsten',
    en: 'Harvest',
    de: 'Ernten',
    fr: 'Récolter',
  );
  static const taskPotOn = LocalizedText(
    nl: 'Verpotten',
    en: 'Pot on',
    de: 'Umtopfen',
    fr: 'Rempoter',
  );
  static const taskThin = LocalizedText(
    nl: 'Uitdunnen',
    en: 'Thin',
    de: 'Vereinzeln',
    fr: 'Éclaircir',
  );
  static const thinSeedlings = LocalizedText(
    nl: 'Uitdunnen',
    en: 'Thin seedlings',
    de: 'Vereinzeln',
    fr: 'Éclaircir',
  );
  static const harvestWindow = LocalizedText(
    nl: 'Oogstvenster',
    en: 'Harvest window',
    de: 'Erntefenster',
    fr: 'Période de récolte',
  );

  // ── difficulty (difficultyLine; easy is easyFilter) ───────────────────────
  static const difficultyMedium = LocalizedText(
    nl: 'Gemiddeld',
    en: 'Medium',
    de: 'Mittel',
    fr: 'Moyen',
  );
  static const difficultyHard = LocalizedText(
    nl: 'Lastig',
    en: 'Hard',
    de: 'Schwierig',
    fr: 'Difficile',
  );

  // ── skipping a step ───────────────────────────────────────────────────────
  static const skipRained = LocalizedText(
    nl: 'Het regende',
    en: 'It rained',
    de: 'Es hat geregnet',
    fr: 'Il a plu',
  );
  static const skipNotNeeded = LocalizedText(
    nl: 'Niet nodig',
    en: 'Not needed',
    de: 'Nicht nötig',
    fr: 'Pas nécessaire',
  );
  static const skipNoTime = LocalizedText(
    nl: 'Geen tijd',
    en: 'No time',
    de: 'Keine Zeit',
    fr: 'Pas le temps',
  );

  // ── streak freezes ────────────────────────────────────────────────────────
  static const freezesUnlimited = LocalizedText(
    nl: 'Onbeperkt vriesdagen.',
    en: 'Unlimited freeze days.',
    de: 'Unbegrenzt viele Pausentage.',
    fr: 'Jours de pause illimités.',
  );
  static LocalizedText freezesLeft(int n) => LocalizedText(
    nl:
        'Nog $n '
        '${n == 1 ? 'vriesdag' : 'vriesdagen'} deze maand.',
    en:
        '$n freeze '
        'day${n == 1 ? '' : 's'} left this month.',
    de: 'Noch $n ${n == 1 ? 'Pausentag' : 'Pausentage'} diesen Monat.',
    fr: 'Encore $n ${n <= 1 ? 'jour de pause' : 'jours de pause'} ce mois-ci.',
  );

  // ── weather adjustments (timing/weather_adjust.dart) ──────────────────────
  static LocalizedText adjustRainSkip(num mm) => LocalizedText(
    nl: 'Genoeg regen rond deze dag ($mm mm). Overslaan.',
    en: 'Enough rain around this day ($mm mm). Skip watering.',
    de: 'Genug Regen rund um diesen Tag ($mm mm). Gießen fällt aus.',
    fr: 'Assez de pluie autour de ce jour ($mm mm). Pas d\'arrosage.',
  );
  static LocalizedText adjustHeat(num t) => LocalizedText(
    nl: 'Hitte verwacht ($t°C). Eerder water geven.',
    en: 'Heat expected ($t°C). Water earlier.',
    de: 'Hitze erwartet ($t °C). Früher gießen.',
    fr: 'Chaleur prévue ($t °C). Arrose plus tôt.',
  );
  static LocalizedText adjustSoilCold(num gate) => LocalizedText(
    nl: 'Bodem nog te koud (< $gate°C). Uitgesteld tot het warmer is.',
    en: 'Soil still too cold (< $gate°C). Held until it warms up.',
    de: 'Boden noch zu kalt (< $gate °C). Verschoben, bis es wärmer ist.',
    fr: 'Sol encore trop froid (< $gate °C). En attente jusqu\'à ce qu\'il se réchauffe.',
  );
  static LocalizedText adjustSoilStaysCold(num gate) => LocalizedText(
    nl: 'Bodem blijft te koud (< $gate°C). Nog even wachten.',
    en: 'Soil staying too cold (< $gate°C). Wait a little longer.',
    de: 'Boden bleibt zu kalt (< $gate °C). Noch etwas warten.',
    fr: 'Le sol reste trop froid (< $gate °C). Encore un peu de patience.',
  );
  static const weatherMovedTask = LocalizedText(
    nl: 'Het weer heeft een taak verzet',
    en: 'The weather moved a task',
    de: 'Das Wetter hat eine Aufgabe verschoben',
    fr: 'La météo a déplacé une tâche',
  );

  // ── replanning (timing/replan.dart) ───────────────────────────────────────
  // The step as the subject of "… was later than planned". German opens the
  // sentence after the colon, so its side carries article and capital.
  static const stepSowing = LocalizedText(
    nl: 'zaaien',
    en: 'sowing',
    de: 'Die Aussaat',
    fr: 'le semis',
  );
  static const stepPottingOn = LocalizedText(
    nl: 'verpotten',
    en: 'potting on',
    de: 'Das Umtopfen',
    fr: 'le rempotage',
  );
  static const stepPlantingOut = LocalizedText(
    nl: 'uitplanten',
    en: 'planting out',
    de: 'Das Auspflanzen',
    fr: 'le repiquage',
  );
  static const stepThinning = LocalizedText(
    nl: 'uitdunnen',
    en: 'thinning',
    de: 'Das Vereinzeln',
    fr: 'l\'éclaircissage',
  );
  static const stepFeeding = LocalizedText(
    nl: 'bemesten',
    en: 'feeding',
    de: 'Das Düngen',
    fr: 'la fertilisation',
  );
  static const stepWatering = LocalizedText(
    nl: 'water geven',
    en: 'watering',
    de: 'Das Gießen',
    fr: 'l\'arrosage',
  );
  static const stepHarvest = LocalizedText(
    nl: 'oogsten',
    en: 'harvest',
    de: 'Die Ernte',
    fr: 'la récolte',
  );
  static const stepHarvested = LocalizedText(
    nl: 'geoogst',
    en: 'harvested',
    de: 'Die Ernte',
    fr: 'la récolte',
  );
  static LocalizedText replanMoved(
    String sign,
    int days,
    LocalizedText step,
    bool later,
  ) => LocalizedText(
    nl:
        'Verplaatst ($sign$days dagen): ${step.nl} was '
        '${later ? 'later' : 'eerder'} dan gepland.',
    en:
        'Moved ($sign$days days): ${step.en} was '
        '${later ? 'later' : 'earlier'} than planned.',
    de:
        'Verschoben ($sign$days Tage): ${step.pick('de')} war '
        '${later ? 'später' : 'früher'} als geplant.',
    fr:
        'Déplacé ($sign$days ${days <= 1 ? 'jour' : 'jours'}) : ${step.pick('fr')} a eu lieu '
        '${later ? 'plus tard' : 'plus tôt'} que prévu.',
  );
  static LocalizedText replanFrostWarning(
    String end,
    String firstFrost,
  ) => LocalizedText(
    nl:
        'De oogst loopt nu tot $end, dicht bij de eerste vorst '
        '($firstFrost). Toch doorgaan, of een sneller ras kiezen?',
    en:
        'Harvest now runs until $end, close to first frost '
        '($firstFrost). Grow it anyway, or swap for a faster variety?',
    de:
        'Die Ernte läuft jetzt bis $end, nah am ersten Frost '
        '($firstFrost). Trotzdem weitermachen oder eine schnellere Sorte wählen?',
    fr:
        'La récolte court maintenant jusqu\'au $end, près des premières gelées '
        '($firstFrost). Continuer quand même, ou choisir une variété plus rapide ?',
  );

  // ── succession (timing/season.dart) ───────────────────────────────────────
  /// [after] is null when the earlier crop is not in the snapshot; its slug
  /// stands in.
  static LocalizedText successionNote(
    LocalizedText? after,
    String afterSlug,
    String freeFrom,
    LocalizedText crop,
    String until,
  ) => LocalizedText(
    nl: 'Plek vrij na ${after?.nl ?? afterSlug} ($freeFrom) — ${crop.nl} zaaien kan nog tot $until.',
    en: 'Space frees up after ${after?.en ?? afterSlug} ($freeFrom) — ${crop.en} can still be sown until $until.',
    de: 'Platz frei nach ${after?.pick('de') ?? afterSlug} ($freeFrom) — ${crop.pick('de')} kannst du noch bis $until säen.',
    fr: 'Place libre après ${after?.pick('fr') ?? afterSlug} ($freeFrom) — tu peux encore semer ${crop.pick('fr')} jusqu\'au $until.',
  );

  // ── help: questions and answers ───────────────────────────────────────────
  static const faqDatesQ = LocalizedText(
    nl: 'Waar komen de plantdata vandaan?',
    en: 'Where do the planting dates come from?',
    de: 'Woher kommen die Pflanztermine?',
    fr: 'D\'où viennent les dates de plantation ?',
  );
  static const faqDatesA = LocalizedText(
    nl:
        'Uit de vorstdatums voor jouw locatie (KNMI / Open-Meteo '
        'klimaatnormalen, afgerond op ~1 km), gecombineerd met teeltregels '
        'die tegen minstens twee Nederlandse zaaikalenders zijn gelegd.',
    en:
        'From the frost dates for your location (KNMI / Open-Meteo climate '
        'normals, rounded to ~1 km) combined with crop rules cross-checked '
        'against at least two Dutch seed calendars.',
    de:
        'Aus den Frostdaten für deinen Standort (KNMI-/Open-Meteo-Klimamittel, '
        'auf ~1 km gerundet), kombiniert mit Anbauregeln, die mit mindestens '
        'zwei niederländischen Aussaatkalendern abgeglichen sind.',
    fr: 'Des dates de gel de ta position (normales climatiques KNMI / Open-Meteo, arrondies à ~1 km) combinées à des règles de culture vérifiées dans au moins deux calendriers des semis néerlandais.',
  );
  static const faqBehindQ = LocalizedText(
    nl: 'Ik loop achter. Is mijn plan verpest?',
    en: 'I fell behind. Is my plan ruined?',
    de: 'Ich hänge hinterher. Ist mein Plan jetzt hin?',
    fr: 'J\'ai pris du retard. Mon plan est fichu ?',
  );
  static const faqBehindA = LocalizedText(
    nl:
        'Nee. Log wat je echt hebt gedaan en wanneer; elke volgende stap '
        'schuift mee. Niets is ooit "te laat", het is "verzet".',
    en:
        'No. Log what you actually did and when; every later step moves with '
        'it. Nothing is ever "overdue", it is "moved".',
    de:
        'Nein. Trag ein, was du wirklich gemacht hast und wann; jeder spätere '
        'Schritt zieht mit. Nichts ist je „zu spät“, es ist „verschoben“.',
    fr: 'Non. Note ce que tu as vraiment fait et quand ; chaque étape suivante bouge avec. Rien n\'est jamais « trop tard », c\'est « déplacé ».',
  );
  static const faqWateringQ = LocalizedText(
    nl: 'Waarom is een waterbeurt verdwenen?',
    en: 'Why did a watering disappear?',
    de: 'Warum ist ein Gießtermin verschwunden?',
    fr: 'Pourquoi un arrosage a disparu ?',
  );
  static const faqWateringA = LocalizedText(
    nl:
        'Het heeft rond die dag genoeg geregend, of er is regen voorspeld. '
        'De weerregel op Home vertelt wat er veranderde.',
    en:
        'It rained enough around that day, or rain is forecast. The weather '
        'line on Home says what changed.',
    de:
        'Rund um diesen Tag hat es genug geregnet, oder es ist Regen '
        'vorhergesagt. Die Wetterzeile auf Home sagt dir, was sich geändert hat.',
    fr: 'Il a assez plu autour de ce jour-là, ou de la pluie est prévue. La ligne météo sur l\'Accueil dit ce qui a changé.',
  );
  static const faqOfflineQ = LocalizedText(
    nl: 'Werkt het offline?',
    en: 'Does it work offline?',
    de: 'Funktioniert es offline?',
    fr: 'Ça marche hors ligne ?',
  );
  static const faqOfflineA = LocalizedText(
    nl:
        'Ja. Gewassen, data, herinneringen en de tijdlijn draaien op de '
        'telefoon. Weerhints en synchroniseren hebben verbinding nodig.',
    en:
        'Yes. Crops, dates, reminders and the timeline all run on the phone. '
        'Weather hints and sync need a connection.',
    de:
        'Ja. Pflanzen, Termine, Erinnerungen und die Zeitleiste laufen auf dem '
        'Handy. Wetterhinweise und Synchronisierung brauchen eine Verbindung.',
    fr: 'Oui. Plantes, dates, rappels et chronologie tournent sur le téléphone. Les infos météo et la synchro ont besoin d\'une connexion.',
  );
  static const faqFreeQ = LocalizedText(
    nl: 'Wat zit er in de gratis versie?',
    en: 'What does the free tier include?',
    de: 'Was ist in der Gratisversion drin?',
    fr: 'Que comprend la version gratuite ?',
  );
  static const faqFreeA = LocalizedText(
    nl:
        'Eén tuin, zes groeiende planten, de volledige tijdlijn, '
        'herinneringen en elk gewas, voorgoed. Lifetime geeft meer ruimte.',
    en:
        'One garden, six growing plants, the full timeline, reminders and '
        'every crop, forever. Lifetime unlocks more room.',
    de:
        'Ein Garten, sechs wachsende Pflanzen, die ganze Zeitleiste, '
        'Erinnerungen und alle Pflanzenarten, für immer. Lifetime gibt dir mehr Platz.',
    fr: 'Un potager, six plantes en culture, la chronologie complète, les rappels et toutes les plantes, pour toujours. Lifetime te donne plus de place.',
  );
  static const faqDeleteQ = LocalizedText(
    nl: 'Hoe verwijder ik mijn account?',
    en: 'How do I delete my account?',
    de: 'Wie lösche ich mein Konto?',
    fr: 'Comment supprimer mon compte ?',
  );
  static const faqDeleteA = LocalizedText(
    nl:
        'Profiel → Account → Account verwijderen. Dat wist je account '
        'en elke gesynchroniseerde rij; lokale gegevens blijven op deze '
        'telefoon tot je de app verwijdert.',
    en:
        'Profile → Account → Delete account. It removes your account and '
        'every synced row; local data stays on this phone until you delete '
        'the app.',
    de:
        'Profil → Konto → Konto löschen. Das entfernt dein Konto und jede '
        'synchronisierte Zeile; lokale Daten bleiben auf diesem Handy, bis du '
        'die App löschst.',
    fr: 'Profil → Compte → Supprimer le compte. Ça supprime ton compte et chaque ligne synchronisée ; les données locales restent sur ce téléphone jusqu\'à ce que tu supprimes l\'app.',
  );

  // ── months, for every sentence that names one ─────────────────────────────
  static const months = <LocalizedText>[
    LocalizedText(nl: 'januari', en: 'January', de: 'Januar', fr: 'janvier'),
    LocalizedText(nl: 'februari', en: 'February', de: 'Februar', fr: 'février'),
    LocalizedText(nl: 'maart', en: 'March', de: 'März', fr: 'mars'),
    LocalizedText(nl: 'april', en: 'April', de: 'April', fr: 'avril'),
    LocalizedText(nl: 'mei', en: 'May', de: 'Mai', fr: 'mai'),
    LocalizedText(nl: 'juni', en: 'June', de: 'Juni', fr: 'juin'),
    LocalizedText(nl: 'juli', en: 'July', de: 'Juli', fr: 'juillet'),
    LocalizedText(nl: 'augustus', en: 'August', de: 'August', fr: 'août'),
    LocalizedText(
      nl: 'september',
      en: 'September',
      de: 'September',
      fr: 'septembre',
    ),
    LocalizedText(nl: 'oktober', en: 'October', de: 'Oktober', fr: 'octobre'),
    LocalizedText(
      nl: 'november',
      en: 'November',
      de: 'November',
      fr: 'novembre',
    ),
    LocalizedText(
      nl: 'december',
      en: 'December',
      de: 'Dezember',
      fr: 'décembre',
    ),
  ];

  /// The month's name, capitalised for a heading. Dutch writes months in lower
  /// case inside a sentence, so the capital belongs to the caller.
  static LocalizedText month(int month1to12) => months[month1to12 - 1];

  static LocalizedText monthTitle(int month1to12) {
    final m = months[month1to12 - 1];
    String up(String s) => s[0].toUpperCase() + s.substring(1);
    return LocalizedText(
      nl: up(m.nl),
      en: m.en,
      de: m.pick('de'),
      fr: up(m.pick('fr')),
    );
  }

  /// Three letters, for a marker on the path.
  static LocalizedText monthShort(int month1to12) {
    final m = months[month1to12 - 1];
    return LocalizedText(
      nl: m.nl.substring(0, 3).toUpperCase(),
      en: m.en.substring(0, 3).toUpperCase(),
      de: m.pick('de').substring(0, 3).toUpperCase(),
      // juin and juillet share JUI; French markers use JUN / JUL.
      fr: switch (month1to12) {
        6 => 'JUN',
        7 => 'JUL',
        _ => m.pick('fr').substring(0, 3).toUpperCase(),
      },
    );
  }
}
