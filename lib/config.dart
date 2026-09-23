/// Environment. The anon key is public by design (RLS does the protecting);
/// the service-role key never ships. Base URL moves to the api. subdomain once
/// Luuk points it at the Vercel project (PRD Phase 0).
library;

const apiBaseUrl = 'https://api.cropsyapp.com';
const websiteUrl = 'https://www.cropsyapp.com';
const supabaseUrl = 'https://trjqvikbtqpmxytzmhsb.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRyanF2aWtidHFwbXh5dHptaHNiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUxNjY0MjcsImV4cCI6MjEwMDc0MjQyN30.GtnXxtTKCTUBfBcfd8R_D3owFZhLadqpziHyoqZ3tjU';

/// Deep-link scheme registered in supabase/config.toml for magic links.
const authRedirect = 'com.cropsyapp.app://login-callback';

/// RevenueCat public SDK keys (safe in the app). Empty = purchases off: the
/// paywall explains, everything stays free-tier. Filled once the App Store
/// Connect products exist (PRD §9, Luuk).
const revenueCatIosKey = 'appl_TyAhhbWkvGilYzwOHWpVEuoQtWX';
const revenueCatAndroidKey = 'goog_TdnQhLhENRoFBAyWerWXZRLuJPd';

/// Entitlement identifier configured in RevenueCat.
const premiumEntitlement = 'premium';

/// Sentry DSN (PRD §5.9 / §10: crash reporting, EU region — the only telemetry
/// besides RevenueCat). Empty = Sentry never starts and nothing is sent, which
/// is what every debug build and every fork should do. Fill it from a Sentry
/// project created in the EU region; the region lives in the DSN host
/// (`...ingest.de.sentry.io`). Public by design, like the RevenueCat key.
const sentryDsn =
    'https://7545420733ca8c81f26d14f1bce7cdab@o4511725089980417.ingest.de.sentry.io/4512107691901008';


/// PostHog project API key and host (EU cloud — `eu.i.posthog.com`, so no
/// personal data leaves the EU). Empty key = analytics never starts, whatever
/// the person answered. The key is public by design: it can only write events.
const posthogApiKey = 'phc_ms7yptHMxY6JRoLLvHKXBYXnv3QqDpQ6nQikHM2DVMb7';
const posthogHost = 'https://eu.i.posthog.com';
