import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

/** Health check: valida GEMINI_API_KEY do secret (sem enviar chave no cliente). */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const key = (Deno.env.get("GEMINI_API_KEY") ?? "").trim();
  if (!key) {
    return new Response(
      JSON.stringify({
        success: false,
        error: "GEMINI_API_KEY não configurado nos secrets da função",
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  try {
    const testUrl =
      `https://generativelanguage.googleapis.com/v1beta/models?key=${
        encodeURIComponent(key)
      }`;
    const gemRes = await fetch(testUrl);
    if (!gemRes.ok) {
      const err = await gemRes.text();
      throw new Error(err);
    }
    return new Response(
      JSON.stringify({ success: true, provider: "gemini" }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return new Response(
      JSON.stringify({ success: false, error: message }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
