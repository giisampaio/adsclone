// Servidor local simples para conferir o site gerado em dist/ (sem dependências).
// Uso: npm run dev  →  http://localhost:4173

import { createServer } from "node:http";
import { readFile, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const pasta = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "dist");
const porta = Number(process.env.PORT) || 4173;
const tipos = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".svg": "image/svg+xml",
  ".xml": "application/xml; charset=utf-8",
  ".txt": "text/plain; charset=utf-8",
};

async function resolver(url) {
  const limpo = decodeURIComponent(new URL(url, "http://x").pathname);
  let arquivo = path.normalize(path.join(pasta, limpo));
  if (!arquivo.startsWith(pasta)) return null;
  try {
    const info = await stat(arquivo);
    if (info.isDirectory()) arquivo = path.join(arquivo, "index.html");
    await stat(arquivo);
    return arquivo;
  } catch {
    return null;
  }
}

createServer(async (req, res) => {
  const arquivo = await resolver(req.url);
  if (!arquivo) {
    res.writeHead(404, { "content-type": tipos[".html"] });
    res.end(await readFile(path.join(pasta, "404.html")));
    return;
  }
  res.writeHead(200, { "content-type": tipos[path.extname(arquivo)] || "application/octet-stream" });
  res.end(await readFile(arquivo));
}).listen(porta, () => console.log(`Abra http://localhost:${porta}`));
