import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const GEMINI_FLASH = "gemini-2.5-flash";
const GEMINI_FLASH_IMAGE = "gemini-2.5-flash-image";

type Briefing = {
  product_description?: string;
  target_audience?: string;
  tone?: string;
  additional_info?: string;
};

type DirectionItem = {
  direction: string;
  prompt: string;
  changes?: string;
  id?: string;
  active?: boolean;
};

type ReqBody = {
  mode?: string;
  generation_id?: string;
  variant_count?: number | null;
  briefing?: Briefing;
  analysis?: Record<string, unknown> | null;
  directions?: DirectionItem[];
};

type AiSecrets = {
  gemini_api_key: string;
};

function loadAiSecrets(): AiSecrets {
  return { gemini_api_key: Deno.env.get("GEMINI_API_KEY")?.trim() ?? "" };
}

async function getUserIdFromJwt(
  supabaseUrl: string,
  anonKey: string,
  jwt: string,
): Promise<string> {
  const client = createClient(supabaseUrl, anonKey);
  const { data: { user }, error } = await client.auth.getUser(jwt);
  if (error || !user?.id) {
    throw new Error("Sessão inválida ou expirada");
  }
  return user.id;
}

function detectMimeType(url: string, bytes: Uint8Array): string {
  if (bytes[0] === 0xFF && bytes[1] === 0xD8) return "image/jpeg";
  if (bytes[0] === 0x89 && bytes[1] === 0x50) return "image/png";
  const u = url.toLowerCase();
  if (u.includes(".jpg") || u.includes(".jpeg")) return "image/jpeg";
  if (u.includes(".png")) return "image/png";
  return "image/jpeg";
}

function uint8ArrayToBase64(bytes: Uint8Array): string {
  let binary = "";
  const chunkSize = 8192;
  for (let i = 0; i < bytes.length; i += chunkSize) {
    const chunk = bytes.subarray(i, i + chunkSize);
    binary += String.fromCharCode(...chunk);
  }
  return btoa(binary);
}

function base64ToUint8Array(b64: string): Uint8Array {
  const binary = atob(b64);
  const out = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    out[i] = binary.charCodeAt(i);
  }
  return out;
}

function stripMarkdownFences(text: string): string {
  return text.replace(/```json/gi, "").replace(/```/g, "").trim();
}

function parseJsonObject(text: string): Record<string, unknown> {
  const t = stripMarkdownFences(text);
  const start = t.indexOf("{");
  const end = t.lastIndexOf("}");
  if (start < 0 || end <= start) {
    throw new Error("Resposta do modelo não contém JSON objeto válido");
  }
  return JSON.parse(t.slice(start, end + 1)) as Record<string, unknown>;
}

function parseJsonArray(text: string): unknown[] {
  const t = stripMarkdownFences(text);
  const start = t.indexOf("[");
  const end = t.lastIndexOf("]");
  if (start < 0 || end <= start) {
    throw new Error("Resposta do modelo não contém JSON array válido");
  }
  return JSON.parse(t.slice(start, end + 1)) as unknown[];
}

function briefingContext(briefing: Briefing | undefined): string {
  if (!briefing?.product_description?.trim()) return "";
  return `\nContexto: ${briefing.product_description}. Público: ${
    briefing.target_audience || "geral"
  }. Tom: ${briefing.tone || "profissional"}. ${briefing.additional_info || ""}`;
}

async function geminiGenerateText(
  apiKey: string,
  model: string,
  parts: Array<{ text?: string; inlineData?: { mimeType: string; data: string } }>,
): Promise<string> {
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${
      encodeURIComponent(apiKey)
    }`;
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ contents: [{ parts }] }),
  });
  const data = await res.json() as {
    candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
    error?: { message?: string };
  };
  if (!res.ok) {
    throw new Error(
      data.error?.message ?? `Gemini ${model}: ${JSON.stringify(data)}`,
    );
  }
  if (!data.candidates?.[0]) {
    throw new Error("Gemini error: " + JSON.stringify(data));
  }
  return data.candidates[0].content?.parts?.map((x) => x.text ?? "").join("") ??
    "";
}

type DoAnalysisParams = {
  briefing: Briefing | undefined;
  mimeType: string;
  base64Image: string;
  gemini_api_key: string;
};

async function doAnalysis(p: DoAnalysisParams): Promise<Record<string, unknown>> {
  const ctx = briefingContext(p.briefing);
  const prompt =
    `Olhe esta imagem de um anúncio de Facebook Ads e descreva tudo que você vê.${ctx}

Retorne APENAS JSON sem backticks:
{"produto":"o que está sendo vendido","proposta_valor":"qual o benefício","cta":"texto do botão/call to action","cores_hex":["#hex das cores principais"],"estilo":"estilo visual","layout":"onde fica cada elemento","tom":"tom da comunicação","elementos_chave":["lista de elementos visuais"],"textos_exatos":["todos os textos que aparecem"],"formato":"vertical ou horizontal","o_que_funciona":"por que funciona bem"}`;

  const text = await geminiGenerateText(p.gemini_api_key, GEMINI_FLASH, [
    { inlineData: { mimeType: p.mimeType, data: p.base64Image } },
    { text: prompt },
  ]);
  return parseJsonObject(text);
}

type DoDirectionsParams = {
  analysis: Record<string, unknown>;
  briefing: Briefing | undefined;
  count: number;
  gemini_api_key: string;
};

async function doDirections(p: DoDirectionsParams): Promise<DirectionItem[]> {
  const ctx = briefingContext(p.briefing);
  const prompt =
    `Este é um anúncio que está performando bem no Facebook Ads: ${JSON.stringify(p.analysis)}${ctx}

Crie ${p.count} variações SUTIS deste anúncio para teste A/B.

REGRAS IMPORTANTES:
- MANTENHA exatamente os mesmos textos, mesma estrutura, mesmo layout, mesmas posições
- MANTENHA o mesmo produto, mesma oferta, mesmo CTA
- Mude APENAS a paleta de cores (fundo, botões, destaques)
- Cada variação deve usar uma combinação de cores DIFERENTE
- Pense como um media buyer: quer testar qual COR converte mais

Exemplos de mudanças:
- Variação 1: fundo azul escuro com textos brancos e botão amarelo
- Variação 2: fundo verde claro com textos pretos e botão laranja
- Variação 3: fundo rosa suave com textos escuros e botão verde

O prompt deve descrever a imagem COMPLETA com as novas cores aplicadas, mantendo tudo mais igual.

Retorne APENAS JSON array sem backticks:
[{"direction":"nome da paleta de cores em português","prompt":"complete visual description in English of the same ad with new color scheme applied - keep same text, same layout, same elements, only change colors","changes":"quais cores mudam"}]`;

  const text = await geminiGenerateText(p.gemini_api_key, GEMINI_FLASH, [
    { text: prompt },
  ]);
  const arr = parseJsonArray(text);
  return normalizeDirectionArray(arr);
}

function normalizeDirectionArray(arr: unknown[]): DirectionItem[] {
  const out: DirectionItem[] = [];
  for (const raw of arr) {
    if (!raw || typeof raw !== "object") continue;
    const o = raw as Record<string, unknown>;
    const direction = String(o.direction ?? o.title ?? "").trim();
    const prompt = String(o.prompt ?? "").trim();
    const changes = String(o.changes ?? o.description ?? "").trim();
    if (!prompt && !direction) continue;
    out.push({
      direction: direction || "Variação",
      prompt: prompt || direction,
      changes,
    });
  }
  return out;
}

type GenerateImageCtx = {
  supabase: ReturnType<typeof createClient>;
  generation_id: string;
  mimeType: string;
  base64Image: string;
  gemini_api_key: string;
};

async function generateImage(
  direction: DirectionItem,
  ctx: GenerateImageCtx,
): Promise<void> {
  const { data: variant, error: insErr } = await ctx.supabase.from("variants")
    .insert({
      generation_id: ctx.generation_id,
      prompt_used: direction.prompt,
      direction: direction.direction,
      status: "generating",
    })
    .select()
    .single();

  if (insErr || !variant) {
    throw new Error(insErr?.message ?? "Failed to insert variant");
  }

  const variantId = variant.id as string;

  try {
    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_FLASH_IMAGE}:generateContent?key=${
        encodeURIComponent(ctx.gemini_api_key)
      }`;
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{
          parts: [
            {
              text:
                `Recreate this exact same ad but with a different color scheme: ${direction.prompt}. Keep the same layout, same texts, same structure. Only change the colors.`,
            },
            {
              inlineData: {
                mimeType: ctx.mimeType,
                data: ctx.base64Image,
              },
            },
          ],
        }],
        generationConfig: {
          responseModalities: ["IMAGE"],
          imageConfig: { aspectRatio: "1:1" },
        },
      }),
    });
    const result = await res.json() as {
      candidates?: Array<{ content?: { parts?: Array<Record<string, unknown>> } }>;
      error?: { message?: string };
    };
    if (!res.ok) {
      throw new Error(
        result.error?.message ??
          "Gemini Image error: " + JSON.stringify(result),
      );
    }
    if (!result.candidates?.[0]?.content?.parts) {
      throw new Error("Gemini Image error: " + JSON.stringify(result));
    }
    const parts = result.candidates[0].content.parts;
    let imgPart: Record<string, unknown> | undefined;
    for (const p of parts) {
      const id = p as { inlineData?: { data?: string }; inline_data?: { data?: string } };
      if (id.inlineData?.data || id.inline_data?.data) {
        imgPart = p;
        break;
      }
    }
    if (!imgPart) throw new Error("No image in Gemini response");
    const idata = (imgPart as { inlineData?: { data?: string }; inline_data?: { data?: string } })
      .inlineData?.data ??
      (imgPart as { inline_data?: { data?: string } }).inline_data?.data;
    if (!idata) throw new Error("No image in Gemini response");
    const imgBytes = base64ToUint8Array(idata);

    const filePath = `variants/${ctx.generation_id}/${variantId}.png`;
    const { error: upErr } = await ctx.supabase.storage.from("creatives").upload(
      filePath,
      imgBytes,
      { contentType: "image/png", upsert: true },
    );
    if (upErr) throw upErr;

    const { data: urlData } = ctx.supabase.storage.from("creatives")
      .getPublicUrl(filePath);

    await ctx.supabase.from("variants").update({
      image_url: urlData.publicUrl,
      status: "completed",
    }).eq("id", variantId);
  } catch (_err) {
    await ctx.supabase.from("variants").update({ status: "failed" }).eq(
      "id",
      variantId,
    );
    throw _err;
  }
}

function jsonErr(
  status: number,
  message: string,
): Response {
  return new Response(
    JSON.stringify({ success: false, error: message }),
    {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const effectiveAnon = (Deno.env.get("SUPABASE_ANON_KEY") ?? "").trim();
  if (!effectiveAnon) {
    return jsonErr(
      500,
      "Função sem SUPABASE_ANON_KEY — defina o secret no dashboard",
    );
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const jwt = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!jwt) {
    return jsonErr(401, "Autenticação necessária");
  }

  let userId: string;
  try {
    userId = await getUserIdFromJwt(supabaseUrl, effectiveAnon, jwt);
  } catch {
    return jsonErr(401, "Sessão inválida ou expirada");
  }

  let body: ReqBody;
  try {
    body = await req.json() as ReqBody;
  } catch {
    return jsonErr(400, "JSON inválido");
  }

  const generation_id = body.generation_id;
  if (!generation_id) {
    return jsonErr(400, "generation_id obrigatório");
  }

  const mode = (body.mode ?? "full").trim().toLowerCase();

  const secrets = loadAiSecrets();
  const gemini_api_key = secrets.gemini_api_key;

  const usesAnalysis =
    mode === "analyze" || mode === "directions" || mode === "full";
  const usesImage = mode === "generate" || mode === "full";

  if ((usesAnalysis || usesImage) && !gemini_api_key) {
    return jsonErr(
      400,
      "Defina o secret GEMINI_API_KEY nas Edge Functions",
    );
  }

  const supabase = createClient(
    supabaseUrl,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: gen, error: genErr } = await supabase
    .from("generations")
    .select("*")
    .eq("id", generation_id)
    .single();

  if (genErr || !gen) {
    return jsonErr(404, "Generation not found");
  }

  const ownerId = gen.user_id != null ? String(gen.user_id) : "";
  if (!ownerId || ownerId !== userId) {
    return jsonErr(403, "Acesso negado a este projeto");
  }

  const count = Math.min(
    Math.max(
      typeof body.variant_count === "number" && Number.isFinite(body.variant_count)
        ? body.variant_count
        : (gen.variant_count as number) ?? 3,
      1,
    ),
    20,
  );

  try {
    const imageResponse = await fetch(gen.original_image_url as string);
    if (!imageResponse.ok) {
      throw new Error(`Falha ao baixar imagem: ${imageResponse.status}`);
    }
    const imageBuffer = await imageResponse.arrayBuffer();
    const imageBytes = new Uint8Array(imageBuffer);
    const mimeType = detectMimeType(
      gen.original_image_url as string,
      imageBytes,
    );
    const base64Image = uint8ArrayToBase64(imageBytes);

    const imgCtx: GenerateImageCtx = {
      supabase,
      generation_id,
      mimeType,
      base64Image,
      gemini_api_key,
    };

    if (mode === "analyze") {
      await supabase.from("generations").update({ status: "analyzing" }).eq(
        "id",
        generation_id,
      );
      const analysis = await doAnalysis({
        briefing: body.briefing,
        mimeType,
        base64Image,
        gemini_api_key,
      });
      await supabase.from("generations").update({
        analysis,
        status: "analyzed",
      }).eq("id", generation_id);
      return new Response(JSON.stringify({ success: true, analysis }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (mode === "directions") {
      const analysis = body.analysis ??
        (gen.analysis as Record<string, unknown> | null);
      if (!analysis || typeof analysis !== "object") {
        return jsonErr(400, "analysis necessário para mode directions");
      }
      const directions = await doDirections({
        analysis,
        briefing: body.briefing,
        count,
        gemini_api_key,
      });
      return new Response(JSON.stringify({ success: true, directions }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (mode === "generate") {
      const provided = body.directions;
      if (!Array.isArray(provided) || provided.length === 0) {
        return jsonErr(400, "directions obrigatório para mode generate");
      }
      const active = provided.filter((d) =>
        d && d.active !== false &&
        (String(d.prompt ?? "").trim() || String(d.direction ?? "").trim())
      ) as DirectionItem[];
      if (active.length === 0) {
        return jsonErr(400, "nenhuma direção ativa com prompt/direction");
      }

      await supabase.from("generations").update({ status: "generating" }).eq(
        "id",
        generation_id,
      );

      for (const d of active) {
        await generateImage(d, imgCtx);
      }

      await supabase.from("generations").update({ status: "completed" }).eq(
        "id",
        generation_id,
      );
      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // full
    await supabase.from("generations").update({ status: "analyzing" }).eq(
      "id",
      generation_id,
    );
    const analysis = await doAnalysis({
      briefing: body.briefing,
      mimeType,
      base64Image,
      gemini_api_key,
    });
    await supabase.from("generations").update({
      analysis,
      status: "generating",
    }).eq("id", generation_id);

    const directions = await doDirections({
      analysis,
      briefing: body.briefing,
      count,
      gemini_api_key,
    });

    for (const d of directions) {
      await generateImage(d, imgCtx);
    }

    await supabase.from("generations").update({ status: "completed" }).eq(
      "id",
      generation_id,
    );
    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    await supabase.from("generations").update({ status: "failed" }).eq(
      "id",
      generation_id,
    );
    const message = error instanceof Error ? error.message : String(error);
    return new Response(
      JSON.stringify({ success: false, error: message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
