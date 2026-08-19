# ClayEstates database setup

## 1. Create the database

1. Create a Supabase project.
2. Open the SQL Editor and run `database/schema.sql`.
3. Enable email authentication in Supabase Auth.
4. Add a profile row for each authenticated user in `public.profiles`.

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

The page will load active listings from Supabase when this object is configured. Without it, the existing localStorage demo mode remains available.

## Authentication note

The current demo UI keeps its sign-in and sign-up flow in localStorage. The database policies intentionally allow listing writes only for Supabase-authenticated users. Listing reads will work immediately after configuration; move the UI auth methods to Supabase Auth before enabling production listing creation, profile updates, favorites, or inquiries.
