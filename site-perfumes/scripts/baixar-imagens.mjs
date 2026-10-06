// Baixa a foto de cada perfume para imagens/perfumes/<id>.jpg (ou .png/.webp).
// Usa a URL de data/imagens.js (sua URL em `fotos` ou a do Fragrantica).
//
// Uso:
//   npm run imagens            baixa só as que ainda não existem
//   npm run imagens -- --forcar  baixa todas de novo

import { mkdir, readdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { carregarPares, fonteDaFoto } from "../src/lib.js";

const pasta = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "imagens", "perfumes");
const forcar = process.argv.includes("--forcar");
const EXTENSOES = { "image/jpeg": "jpg", "image/jpg": "jpg", "image/png": "png", "image/webp": "webp" };

await mkdir(pasta, { recursive: true });
const existentes = new Set((await readdir(pasta)).map((a) => a.replace(/\.(jpe?g|png|webp)$/i, "")));

const perfumes = new Map();
for (const par of carregarPares()) {
  for (const p of [par.original, par.alt, par.nacional].filter(Boolean)) perfumes.set(p.id, p);
}

const fila = [...perfumes.values()].filter((p) => forcar || !existentes.has(p.id));
const falhas = [];
let baixadas = 0;

async function baixar(p) {
  const url = fonteDaFoto(p);
  if (!url) return falhas.push(`${p.id}: sem URL em data/imagens.js`);
  try {
    const resposta = await fetch(url, {
      headers: {
        "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36",
        accept: "image/avif,image/webp,image/*,*/*;q=0.8",
        referer: url.includes("fimgs.net") ? "https://www.fragrantica.com/" : new URL(url).origin + "/",
      },
    });
    const tipo = (resposta.headers.get("content-type") || "").split(";")[0].trim();
    if (!resposta.ok) throw new Error(`HTTP ${resposta.status}`);
    if (!EXTENSOES[tipo]) throw new Error(`não é imagem (${tipo || "sem tipo"})`);
    const dados = Buffer.from(await resposta.arrayBuffer());
    if (dados.length < 3000) throw new Error(`arquivo pequeno demais (${dados.length} bytes)`);
    await writeFile(path.join(pasta, `${p.id}.${EXTENSOES[tipo]}`), dados);
    baixadas++;
    console.log(`ok   ${p.id}`);
  } catch (erro) {
    falhas.push(`${p.id}: ${erro.message} (${url})`);
    console.log(`erro ${p.id}: ${erro.message}`);
  }
}

// Até 4 downloads ao mesmo tempo.
const trabalhadores = Array.from({ length: 4 }, async () => {
  while (fila.length) await baixar(fila.shift());
});
await Promise.all(trabalhadores);

console.log(`\n${baixadas} fotos baixadas para imagens/perfumes/. ${falhas.length} falhas.`);
if (falhas.length) {
  console.log(falhas.map((f) => `  - ${f}`).join("\n"));
  process.exitCode = 1;
}
