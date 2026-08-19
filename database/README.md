# ClayEstates database setup

## 1. Create the database

1. Create a Supabase project.
2. Open the SQL Editor and run `database/schema.sql`.
3. Enable email authentication in Supabase Auth.
4. Add a profile row for each authenticated user in `public.profiles`. The `avatar` column stores the profile picture URL or data URL used by the account profile.
5. Listing prices are stored as numeric values in Indian rupees. The `listings.currency` column is explicitly set to `INR`.

If the database was created from an older version of the schema, run `database/schema.sql` again. The schema includes an idempotent migration for the `profiles.avatar` column.

## 2. Connect the website

Before the Babel application script in `index.html`, define the public Supabase URL and anon key:

```html
<script>
  window.CLAYESTATES_SUPABASE = {
    url: 'https://YOUR_PROJECT.supabase.co',
    anonKey: 'YOUR_PUBLIC_ANON_KEY'
  };
</script>
```

The anon key previously embedded in this page was invalid and returned `401 Invalid API key`. Paste the current public anon key from Supabase Project Settings > API into `anonKey`. Do not put a service-role key in the browser. Until a valid anon key is configured, the app intentionally uses localStorage mode without making failed database requests.

The page will load active listings from Supabase when this object is configured. Without it, the existing localStorage demo mode remains available.

## Authentication note

When a valid Supabase URL and public anon key are configured, the UI uses Supabase Auth for sign-in, sign-up, sessions, logout, and profile updates. Run this schema after enabling email authentication so users can create their own profile rows. With no valid Supabase configuration, the page uses localStorage fallback mode for development only.
