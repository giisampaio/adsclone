// Gera o site estático em dist/ (padrão) ou a prévia de arquivo único em previa/ (--previa).
// Não tem dependências: basta Node 18 ou mais recente.

import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { createHash } from "node:crypto";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { site } from "./data/site.js";
import { carregarPares } from "./src/lib.js";
import * as R from "./src/render.js";

const raiz = path.dirname(fileURLToPath(import.meta.url));
const modoPrevia = process.argv.includes("--previa");

const pares = carregarPares();
const css = await readFile(path.join(raiz, "src/styles.css"), "utf8");
const js = await readFile(path.join(raiz, "src/app.js"), "utf8");

const FONTES =
  '<link rel="preconnect" href="https://fonts.googleapis.com">' +
  '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>' +
  '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bodoni+Moda:ital,opsz,wght@0,6..96,400..700;1,6..96,400..700&family=IBM+Plex+Mono:wght@400;500&family=Instrument+Sans:wght@400..700&display=swap">';

const CORES_TEMA = { feminino: "#f6e9e7", masculino: "#0e181c", "": "#f4efec" };

const FAVICON = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40"><path d="M14 6c5 7 8 12 8 17a8 8 0 0 1-16 0c0-5 3-10 8-17z" fill="#7c3a4e"/><path d="M27 10c4.4 6 7 10.4 7 14.6a7 7 0 0 1-14 0C20 20.4 22.6 16 27 10z" fill="none" stroke="#7c3a4e" stroke-width="2"/></svg>`;

function todasAsPaginas(ctx) {
  return [
    R.paginaInicio(pares, ctx),
    R.paginaGenero("feminino", pares, ctx),
    R.paginaGenero("masculino", pares, ctx),
    ...pares.map((p) => R.paginaPar(p, pares, ctx)),
    R.paginaMetodo(pares, ctx),
  ];
}

const jsonSeguro = (obj) => JSON.stringify(obj).replace(/</g, "\\u003c");
const hash = (texto) => createHash("sha1").update(texto).digest("hex").slice(0, 10);

function documento(pg, ctx, assets) {
  const base = site.basePath;
  const canonical = `${site.url}${base}${pg.caminho}`;
  const eh404 = pg.rota === "404";
  return `<!doctype html>
<html lang="pt-BR"${pg.genero ? ` data-genero="${pg.genero}"` : ""}>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>${R.esc(pg.titulo)}</title>
<meta name="description" content="${R.esc(pg.descricao)}">
${eh404 ? '<meta name="robots" content="noindex">' : `<link rel="canonical" href="${canonical}">`}
<meta name="theme-color" content="${CORES_TEMA[pg.genero || ""]}">
<meta property="og:type" content="website">
<meta property="og:locale" content="pt_BR">
<meta property="og:site_name" content="${R.esc(site.nome)}">
<meta property="og:title" content="${R.esc(pg.titulo)}">
<meta property="og:description" content="${R.esc(pg.descricao)}">
${eh404 ? "" : `<meta property="og:url" content="${canonical}">`}
<meta name="twitter:card" content="summary">
<link rel="icon" href="${base}favicon.svg" type="image/svg+xml">
${FONTES}
<link rel="stylesheet" href="${assets.css}">
${pg.jsonld ? `<script type="application/ld+json">${jsonSeguro(pg.jsonld)}</script>` : ""}
</head>
<body>
<a class="pular" href="#conteudo">Pular para o conteúdo</a>
${R.cabecalho(ctx, pg.ativo)}
<main id="conteudo">
${pg.corpo}
</main>
${R.rodape(ctx)}
<script src="${assets.js}" defer></script>
</body>
</html>
`;
}

async function salvar(destino, conteudo) {
  await mkdir(path.dirname(destino), { recursive: true });
  await writeFile(destino, conteudo);
}

async function gerarSite() {
  const saida = path.join(raiz, "dist");
  await rm(saida, { recursive: true, force: true });
  const ctx = R.criarContexto("site");
  const nomeCss = `styles.${hash(css)}.css`;
  const nomeJs = `app.${hash(js)}.js`;
  const assets = { css: `${site.basePath}assets/${nomeCss}`, js: `${site.basePath}assets/${nomeJs}` };

  await salvar(path.join(saida, "assets", nomeCss), css);
  await salvar(path.join(saida, "assets", nomeJs), js);
  await salvar(path.join(saida, "favicon.svg"), FAVICON);

  const paginas = todasAsPaginas(ctx);
  for (const pg of paginas) {
    await salvar(path.join(saida, pg.caminho, "index.html"), documento(pg, ctx, assets));
  }
  await salvar(path.join(saida, "404.html"), documento(R.pagina404(ctx), ctx, assets));

  const urls = paginas.map((pg) => `  <url><loc>${site.url}${site.basePath}${pg.caminho}</loc></url>`).join("\n");
  await salvar(
    path.join(saida, "sitemap.xml"),
    `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls}\n</urlset>\n`
  );
  await salvar(path.join(saida, "robots.txt"), `User-agent: *\nAllow: /\n\nSitemap: ${site.url}${site.basePath}sitemap.xml\n`);

  console.log(`Site gerado em dist/ com ${paginas.length + 1} páginas (${pares.length} comparações).`);
}

async function gerarPrevia() {
  const ctx = R.criarContexto("previa");
  const paginas = todasAsPaginas(ctx);
  const rotas = paginas
    .map(
      (pg, i) =>
        `<div class="rota" data-rota="${pg.rota}" data-tema="${pg.genero}" data-ativo="${pg.ativo}" data-titulo="${R.esc(pg.titulo)}"${i === 0 ? "" : " hidden"}>${pg.corpo}</div>`
    )
    .join("\n");
  const html = `<title>${R.esc(site.nome)}</title>
${FONTES}
<style>
${css}
</style>
${R.cabecalho(ctx, "inicio")}
<main id="conteudo">
${rotas}
</main>
${R.rodape(ctx)}
<script>
${js}
</script>
`;
  const destino = path.join(raiz, "previa", "essencia-gemea.html");
  await salvar(destino, html);
  console.log(`Prévia de arquivo único gerada em previa/essencia-gemea.html (${(html.length / 1024).toFixed(0)} KB).`);
}

if (modoPrevia) await gerarPrevia();
else await gerarSite();
