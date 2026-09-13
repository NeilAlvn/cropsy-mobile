/// Environment. The anon key is public by design (RLS does the protecting);
/// the service-role key never ships. Base URL moves to the api. subdomain once
/// Luuk points it at the Vercel project (PRD Phase 0).
library;

const apiBaseUrl = 'https://api.cropsyapp.com';
const websiteUrl = 'https://cropsy.app';
const supabaseUrl = 'https://trjqvikbtqpmxytzmhsb.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRyanF2aWtidHFwbXh5dHptaHNiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUxNjY0MjcsImV4cCI6MjEwMDc0MjQyN30.GtnXxtTKCTUBfBcfd8R_D3owFZhLadqpziHyoqZ3tjU';

/// Deep-link scheme registered in supabase/config.toml for magic links.
const authRedirect = 'com.cropsyapp.app://login-callback';

/// RevenueCat public SDK keys (safe in the app). Empty = purchases off: the
/// paywall explains, everything stays free-tier. Filled once the App Store
/// Connect products exist (PRD §9, Luuk).
const revenueCatIosKey = 'appl_TyAhhbWkvGilYzwOHWpVEuoQtWX';
const revenueCatAndroidKey = '';

/// Entitlement identifier configured in RevenueCat.
const premiumEntitlement = 'premium';
