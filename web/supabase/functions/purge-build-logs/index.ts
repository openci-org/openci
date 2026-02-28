import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (_req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data, error } = await supabase.rpc("purge_old_build_logs");
  if (error) {
    console.error("purge_old_build_logs error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  console.log(`Purged ${data} old build log rows`);
  return new Response(JSON.stringify({ deleted: data }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
