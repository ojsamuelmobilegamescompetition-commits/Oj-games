
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });
  const auth = req.headers.get("Authorization") || "";
  const url = Deno.env.get("SUPABASE_URL")!;
  const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
  const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const caller = createClient(url, anon, { global: { headers: { Authorization: auth } } });
  const { data: { user }, error } = await caller.auth.getUser();
  if (error || !user) return Response.json({ error: "Unauthorized" }, { status: 401 });
  const { data: role } = await admin.from("staff_roles").select("role,active").eq("user_id", user.id).maybeSingle();
  if (!role?.active || role.role !== "super_admin") return Response.json({ error: "Forbidden" }, { status: 403 });
  const body = await req.json().catch(() => ({}));
  // Keep this allow-list narrow. Extend with audited, validated actions as the platform grows.
  if (body.action === "grant_staff_role") {
    const allowed = ["platform_admin","tournament_director","competition_manager","moderator","results_officer","finance_officer","support_officer"];
    if (!allowed.includes(body.role) || !body.user_id) return Response.json({ error: "Invalid role request" }, { status: 400 });
    const { error: writeError } = await admin.from("staff_roles").upsert({ user_id: body.user_id, role: body.role, active: true });
    if (writeError) return Response.json({ error: writeError.message }, { status: 400 });
    await admin.from("audit_logs").insert({ actor_id: user.id, action: "grant_staff_role", target_table: "staff_roles", target_id: body.user_id, details: { role: body.role } });
    return Response.json({ ok: true });
  }
  return Response.json({ error: "Unsupported action" }, { status: 400 });
});
