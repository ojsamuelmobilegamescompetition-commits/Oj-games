OJ SAMUEL — INTERNATIONAL MOBILE GAMES COMPETITION
=================================================
This is a NEW multi-page website starter built for GitHub Pages + Supabase.

PAGES
-----
index.html             Public homepage
tournaments.html       Tournament centre
tournament.html        Tournament details (uses ?id=)
matches.html           Live match centre
leaderboard.html       Global leaderboard
players.html            Player directory
news.html               News and updates
rewards.html             Rewards centre
about.html               About the competition
contact.html             Contact/support form
login.html               Player login
register.html            Player registration
player.html              Player dashboard
admin.html               Staff admin dashboard
super-admin.html         Separate super-admin interface

FIRST SETUP
-----------
1. Create a NEW GitHub repository for this website.
2. Upload the complete contents of this folder to the repository root.
3. In Supabase, create a NEW project (or select the intended project).
4. Open SQL Editor and run supabase/schema.sql.
5. Open config.js and replace YOUR-PROJECT and YOUR_SUPABASE_ANON_KEY.
   Use only the public anon/publishable key. NEVER paste service_role key here.
6. Enable Email authentication in Supabase Auth.
7. In Supabase Auth URL Configuration, add your GitHub Pages URL, e.g.
   https://YOUR-USERNAME.github.io/YOUR-REPOSITORY/
   Also add the same URL as a redirect URL.
8. Deploy Edge Function supabase/functions/admin-action using Supabase CLI.
   Set SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY as Edge
   Function secrets. The service role key must remain server-side only.
9. In Supabase Storage create a private bucket named `competition-media`.
   Add Storage policies for authorized staff uploads before enabling upload UI.
10. In Supabase SQL Editor, after creating your own account, find its UUID in
    Authentication > Users. Assign the first super-admin role using SQL:
    insert into public.staff_roles(user_id,role,active)
    values('YOUR-AUTH-USER-UUID','super_admin',true);
11. Enable GitHub Pages: repository Settings > Pages > Deploy from branch > main
    and root folder. Wait for deployment and open the published URL.

IMPORTANT SECURITY / FUNCTIONAL NOTES
-------------------------------------
- The homepage and CMS modules include demonstration content. Local demo edits
  are stored in the current browser only until the Supabase data adapters are
  connected. They do not publish to all visitors.
- Database schema includes role-aware RLS policies. Review and test policies
  with separate test accounts for every staff role before public launch.
- Never grant super_admin to ordinary staff. Do not expose Supabase service role.
- Do not mark sponsor logos as official partners until written permission exists.
- Prize pools and prices are illustrative and must be confirmed before publishing.
- Payment records are not a payment gateway. Integrate a reputable payment
  provider via a verified server-side webhook before accepting entry fees.
- Anti-cheat cannot be guaranteed by a static website. Use match evidence,
  referee review, audit logs and platform/game-specific integrations.
- The UI currently includes a safe foundation and demo/local interactions;
  production-grade uploads, bracket generation, payment verification, global
  analytics and staff workflows need their server-side adapters and testing.
- Do not advertise fake live scores or unverified rankings.

LOCAL PREVIEW
-------------
Open index.html in a local server (not file:// for auth testing), or use:
  python -m http.server 8000
Then visit http://localhost:8000

DESIGN
------
Dark #02040B / navy #06132D, electric blue #006BFF and cyan #00D9FF.
The logo lockup was cropped from the OJ Samuel visual reference image supplied
in the conversation. Replace assets/oj-samuel-logo.png with the original
transparent logo file if you have a higher-resolution standalone asset.
