// Templates HTML do site. As mesmas funções geram o site estático (várias páginas)
// e a prévia em arquivo único (navegação por #âncora).

import { site } from "../data/site.js";
import {
  GENEROS,
  TOTAIS,
  CONCENTRACOES,
  PROJECAO,
  normalizar,
  notaPresente,
  linksDeCompra,
  linkDeBusca,
  fonteDaFoto,
  fmtFaixa,
  fmtPorMl,
  fmtNota,
  fmtHoras,
} from "./lib.js";

export const esc = (s) =>
  String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);

const pad2 = (n) => String(n).padStart(2, "0");

// ---------------------------------------------------------------------------
// Contexto de links: site estático ou prévia de arquivo único
// ---------------------------------------------------------------------------

// fotosLocais: Map de id do perfume → nome do arquivo em imagens/perfumes/.
export function criarContexto(modo, fotosLocais = new Map()) {
  const base = site.basePath;
  const prefixoFotos = modo === "previa" ? "img/perfumes/" : `${base}img/perfumes/`;
  const foto = (p) => (fotosLocais.has(p.id) ? prefixoFotos + fotosLocais.get(p.id) : fonteDaFoto(p));
  if (modo === "previa") {
    return {
      modo,
      foto,
      inicio: () => "#inicio",
      genero: (g) => `#${g}`,
      par: (p) => `#${p.slug}`,
      metodo: () => "#como-avaliamos",
    };
  }
  return {
    modo,
    foto,
    inicio: () => base,
    genero: (g) => `${base}${g}/`,
    par: (p) => `${base}${p.genero}/${p.slug}/`,
    metodo: () => `${base}como-avaliamos/`,
  };
}

// ---------------------------------------------------------------------------
// Ilustração do frasco (SVG sem gradientes, para não depender de ids)
// ---------------------------------------------------------------------------

const TAMPAS = {
  ouro: ["#c3a05a", "#ead39b"],
  prata: ["#b9bec5", "#eef0f2"],
  preto: ["#19191c", "#45454c"],
};

function rotulo(x, y, w, h) {
  return `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="2" fill="#fff" fill-opacity=".55"/>` +
    `<rect x="${x + 8}" y="${y + h * 0.36}" width="${w - 16}" height="2.4" fill="#000" fill-opacity=".28"/>` +
    `<rect x="${x + 14}" y="${y + h * 0.62}" width="${w - 28}" height="1.6" fill="#000" fill-opacity=".2"/>`;
}

function formaDoFrasco(forma, cor, tampa, brilho) {
  const contorno = `stroke="currentColor" stroke-opacity=".22" stroke-width="1.2"`;
  switch (forma) {
    case "quadrado":
      return `<rect x="36" y="20" width="48" height="42" rx="2" fill="${tampa}" ${contorno}/>` +
        `<rect x="41" y="25" width="7" height="32" fill="${brilho}" fill-opacity=".55"/>` +
        `<rect x="50" y="62" width="20" height="8" fill="${tampa}"/>` +
        `<rect x="14" y="70" width="92" height="122" rx="4" fill="${cor}" ${contorno}/>` +
        `<rect x="22" y="78" width="8" height="104" rx="3" fill="#fff" fill-opacity=".26"/>` +
        rotulo(34, 112, 52, 36);
    case "alto":
      return `<rect x="44" y="8" width="32" height="40" rx="3" fill="${tampa}" ${contorno}/>` +
        `<rect x="48" y="12" width="6" height="32" rx="2" fill="${brilho}" fill-opacity=".55"/>` +
        `<rect x="50" y="48" width="20" height="10" fill="${tampa}"/>` +
        `<rect x="28" y="58" width="64" height="134" rx="10" fill="${cor}" ${contorno}/>` +
        `<rect x="35" y="68" width="7" height="112" rx="3" fill="#fff" fill-opacity=".26"/>` +
        rotulo(40, 108, 40, 44);
    case "redondo":
      return `<rect x="44" y="12" width="32" height="34" rx="12" fill="${tampa}" ${contorno}/>` +
        `<rect x="49" y="17" width="6" height="24" rx="3" fill="${brilho}" fill-opacity=".55"/>` +
        `<rect x="51" y="44" width="18" height="18" fill="${tampa}"/>` +
        `<ellipse cx="60" cy="130" rx="50" ry="62" fill="${cor}" ${contorno}/>` +
        `<ellipse cx="36" cy="112" rx="7" ry="28" fill="#fff" fill-opacity=".26"/>` +
        rotulo(40, 118, 40, 30);
    case "facetado":
      return `<polygon points="46,16 74,16 82,26 82,52 74,60 46,60 38,52 38,26" fill="${tampa}" ${contorno}/>` +
        `<polygon points="46,22 52,22 52,54 46,54" fill="${brilho}" fill-opacity=".5"/>` +
        `<rect x="50" y="60" width="20" height="8" fill="${tampa}"/>` +
        `<polygon points="32,68 88,68 108,90 108,170 88,192 32,192 12,170 12,90" fill="${cor}" ${contorno}/>` +
        `<polygon points="20,94 28,86 28,176 20,168" fill="#fff" fill-opacity=".26"/>` +
        rotulo(34, 112, 52, 36);
    default:
      return `<rect x="42" y="14" width="36" height="34" rx="3" fill="${tampa}" ${contorno}/>` +
        `<rect x="46" y="18" width="7" height="26" rx="2" fill="${brilho}" fill-opacity=".55"/>` +
        `<rect x="48" y="48" width="24" height="12" fill="${tampa}"/>` +
        `<rect x="16" y="60" width="88" height="132" rx="14" fill="${cor}" ${contorno}/>` +
        `<rect x="25" y="72" width="9" height="108" rx="4" fill="#fff" fill-opacity=".26"/>` +
        rotulo(36, 108, 48, 40);
  }
}

function ilustracao(p, classe) {
  const [tampa, brilho] = TAMPAS[p.tampa] || TAMPAS.ouro;
  return `<svg class="frasco ${classe}" viewBox="0 0 120 200" aria-hidden="true" focusable="false">${formaDoFrasco(p.forma, p.cor, tampa, brilho)}</svg>`;
}

// Foto real do perfume, com a ilustração por baixo caso a foto não carregue.
export function frasco(p, classe, ctx) {
  const src = ctx.foto(p);
  if (!src) return ilustracao(p, classe);
  return `<span class="foto ${classe}"><img src="${esc(src)}" alt="Frasco do perfume ${esc(p.titulo)}" width="375" height="500" loading="lazy" decoding="async" onerror="this.parentNode.classList.add('foto--sem')">${ilustracao(p, "")}</span>`;
}

// ---------------------------------------------------------------------------
// Pequenos componentes
// ---------------------------------------------------------------------------

function anel(valor, classe = "") {
  return `<div class="anel ${classe}" style="--p:${valor}" role="img" aria-label="${valor}% de semelhança">` +
    `<span class="anel__valor">${valor}<small class="pct">%</small></span><span class="anel__leg" aria-hidden="true">semelhança</span></div>`;
}

function gotas(n) {
  let html = "";
  for (let i = 1; i <= 5; i++) html += `<i class="gota${i <= n ? " gota--cheia" : ""}"></i>`;
  return `<span class="gotas" role="img" aria-label="Projeção ${n} de 5">${html}</span>`;
}

function fita(nome, valor) {
  return `<li class="fita"><span class="fita__nome">${esc(nome)}</span>` +
    `<span class="fita__barra" style="--v:${valor}" role="img" aria-label="${esc(nome)}: intensidade ${valor} de 100"><i></i></span></li>`;
}

function nomePerfume(p, tag = "p", classe = "nome") {
  return `<${tag} class="${classe}"><span class="${classe}__marca">${esc(p.marca)}</span> <span class="${classe}__linha">${esc(p.nome)}</span></${tag}>`;
}

function botoesCompra(p) {
  return `<ul class="compra">` +
    linksDeCompra(p)
      .map((l) => `<li><a class="botao botao--${l.id}" href="${esc(l.url)}" target="_blank" rel="sponsored nofollow noopener">${esc(l.nome)}<span class="botao__seta" aria-hidden="true">↗</span></a></li>`)
      .join("") +
    `</ul>`;
}

function textoBusca(par) {
  const partes = [
    par.original.titulo, par.alt.titulo, par.grupo, par.original.familia,
    ...par.acordes.map((a) => a[0]),
    ...Object.values(par.original.notas).flat(),
    ...Object.values(par.alt.notas).flat(),
  ];
  return normalizar(partes.join(" "));
}

// ---------------------------------------------------------------------------
// Cartão de comparação (listas e destaques)
// ---------------------------------------------------------------------------

export function cartao(par, ctx, nivel = 2) {
  const { original: o, alt: a } = par;
  return `<article class="cartao" data-genero="${par.genero}">
  <a class="cartao__link" href="${ctx.par(par)}">
    <h${nivel} class="sr">${esc(o.titulo)} × ${esc(a.titulo)}</h${nivel}>
    <div class="cartao__topo"><span class="cartao__rank">Nº ${pad2(par.rank)}</span><span class="cartao__grupo">${esc(par.grupo)}</span></div>
    <div class="cartao__duo">
      <div class="cartao__lado">
        ${frasco(o, "frasco--cartao", ctx)}
        <p class="papel papel--original">Original</p>
        ${nomePerfume(o)}
        <p class="cartao__preco">${fmtFaixa(o.preco)}<span>${o.ml} ml</span></p>
      </div>
      <div class="cartao__ponte">${anel(par.semelhanca)}</div>
      <div class="cartao__lado">
        ${frasco(a, "frasco--cartao", ctx)}
        <p class="papel papel--alt">Versão em conta</p>
        ${nomePerfume(a)}
        <p class="cartao__preco">${fmtFaixa(a.preco)}<span>${a.ml} ml</span></p>
      </div>
    </div>
    <div class="cartao__base">
      <span class="selo-economia">${par.economia}% mais barato por ml</span>
      <span class="cartao__cta" aria-hidden="true">Comparar <span>→</span></span>
    </div>
  </a>
</article>`;
}

// ---------------------------------------------------------------------------
// Cabeçalho e rodapé
// ---------------------------------------------------------------------------

const SINAL = `<svg class="marca__sinal" viewBox="0 0 40 40" aria-hidden="true" focusable="false"><path d="M14 6c5 7 8 12 8 17a8 8 0 0 1-16 0c0-5 3-10 8-17z" fill="currentColor"/><path d="M27 10c4.4 6 7 10.4 7 14.6a7 7 0 0 1-14 0C20 20.4 22.6 16 27 10z" fill="none" stroke="currentColor" stroke-width="2"/></svg>`;

export function cabecalho(ctx, ativo = "") {
  const item = (id, href, texto) =>
    `<a href="${href}" data-nav="${id}"${ativo === id ? ' aria-current="page"' : ""}>${texto}</a>`;
  return `<header class="topo">
  <div class="topo__in envoltorio">
    <a class="marca" href="${ctx.inicio()}" data-nav="inicio">${SINAL}<span class="marca__nome">Essência <em>Gêmea</em></span></a>
    <nav class="nav" aria-label="Principal">
      ${item("feminino", ctx.genero("feminino"), "Feminino")}
      ${item("masculino", ctx.genero("masculino"), "Masculino")}
      ${item("metodo", ctx.metodo(), "Como avaliamos")}
    </nav>
  </div>
</header>`;
}

export function rodape(ctx) {
  return `<footer class="rodape">
  <div class="envoltorio rodape__in">
    <div class="rodape__marca">
      <p class="marca marca--rodape">${SINAL}<span class="marca__nome">Essência <em>Gêmea</em></span></p>
      <p>${esc(site.slogan)}</p>
    </div>
    <nav class="rodape__nav" aria-label="Rodapé">
      <a href="${ctx.genero("feminino")}">Top ${TOTAIS.feminino} feminino</a>
      <a href="${ctx.genero("masculino")}">Top ${TOTAIS.masculino} masculino</a>
      <a href="${ctx.metodo()}">Como avaliamos</a>
    </nav>
    <div class="rodape__aviso">
      <p>Guia independente. As marcas citadas pertencem aos seus donos e não têm vínculo com este site. As versões em conta são perfumes de marcas próprias, vendidos legalmente; não são falsificações.</p>
      <p>Semelhança, notas e fixação são avaliações da curadoria e variam de pele para pele. Preços são faixas estimadas e mudam com frequência: confira o valor na loja. Podemos receber comissão por compras feitas pelos links, sem custo extra para você.</p>
      <p class="rodape__ano">© ${site.ano} ${esc(site.nome)}</p>
    </div>
  </div>
</footer>`;
}

// ---------------------------------------------------------------------------
// Página inicial
// ---------------------------------------------------------------------------

function media(lista, campo) {
  return Math.round(lista.reduce((s, p) => s + p[campo], 0) / lista.length);
}

function porta(genero, pares, ctx) {
  const lista = pares.filter((p) => p.genero === genero);
  const top = lista[0];
  const maxEco = Math.max(...lista.map((p) => p.economia));
  return `<a class="porta" data-genero="${genero}" href="${ctx.genero(genero)}">
    <div class="porta__frascos">${frasco(top.original, "frasco--porta", ctx)}<span class="porta__x" aria-hidden="true">×</span>${frasco(top.alt, "frasco--porta", ctx)}</div>
    <div class="porta__texto">
      <p class="olho">Top ${lista.length}</p>
      <h2 class="porta__titulo">${GENEROS[genero].nome}</h2>
      <p class="porta__exemplo">${esc(top.original.nome)} <span>×</span> ${esc(top.alt.nome)}</p>
      <p class="porta__eco">Economia de até ${maxEco}% por ml</p>
      <p class="porta__cta">Ver ranking ${GENEROS[genero].nome.toLowerCase()} <span aria-hidden="true">→</span></p>
    </div>
  </a>`;
}

export function paginaInicio(pares, ctx) {
  const fem = pares.filter((p) => p.genero === "feminino").slice(0, 3);
  const mas = pares.filter((p) => p.genero === "masculino").slice(0, 3);
  const corpo = `
<section class="abertura">
  <div class="envoltorio abertura__in">
    <p class="olho">Guia de perfumes importados · edição ${site.ano}</p>
    <h1 class="abertura__titulo">O perfume que você deseja tem uma versão que <em>cabe no bolso.</em></h1>
    <p class="abertura__texto">Comparamos ${pares.length} perfumes importados famosos com alternativas da mesma família olfativa. Para cada par, você vê as notas, a fixação, a projeção, a nota da curadoria e quanto economiza por ml.</p>
    <dl class="numeros">
      <div><dt>Comparações</dt><dd>${pares.length}</dd></div>
      <div><dt>Economia média por ml</dt><dd>${media(pares, "economia")}<span class="pct">%</span></dd></div>
      <div><dt>Semelhança média</dt><dd>${media(pares, "semelhanca")}<span class="pct">%</span></dd></div>
    </dl>
  </div>
</section>
<section class="portas envoltorio" aria-label="Escolha o ranking">
  ${porta("feminino", pares, ctx)}
  ${porta("masculino", pares, ctx)}
</section>
<section class="secao envoltorio">
  <div class="secao__cabeca">
    <h2 class="secao__titulo">Os mais procurados</h2>
    <p class="secao__texto">Os três primeiros de cada ranking. Toque em um par para ver a comparação completa.</p>
  </div>
  <div class="destaques">
    <div class="destaques__col" data-genero="feminino">
      <h3 class="destaques__titulo">Feminino</h3>
      <div class="grade-cartoes grade-cartoes--coluna">${fem.map((p) => cartao(p, ctx, 4)).join("")}</div>
      <a class="link-seta" href="${ctx.genero("feminino")}">Ver os ${TOTAIS.feminino} femininos <span aria-hidden="true">→</span></a>
    </div>
    <div class="destaques__col" data-genero="masculino">
      <h3 class="destaques__titulo">Masculino</h3>
      <div class="grade-cartoes grade-cartoes--coluna">${mas.map((p) => cartao(p, ctx, 4)).join("")}</div>
      <a class="link-seta" href="${ctx.genero("masculino")}">Ver os ${TOTAIS.masculino} masculinos <span aria-hidden="true">→</span></a>
    </div>
  </div>
</section>
<section class="secao envoltorio">
  <div class="secao__cabeca">
    <h2 class="secao__titulo">Como ler cada comparação</h2>
    <p class="secao__texto">Três números resumem cada par. A metodologia completa está em <a href="${ctx.metodo()}">Como avaliamos</a>.</p>
  </div>
  <div class="leitura">
    <div class="leitura__item">
      <div class="leitura__visual">${anel(85, "anel--demo")}</div>
      <h3>Semelhança</h3>
      <p>Quanto do cheiro do original a alternativa reproduz, de 0 a 100%. Acima de 85% a diferença costuma aparecer só lado a lado.</p>
    </div>
    <div class="leitura__item">
      <div class="leitura__visual"><p class="leitura__nota">8,8<small>/10</small></p></div>
      <h3>Nota da curadoria</h3>
      <p>Qualidade geral do perfume: equilíbrio, matérias-primas, fixação e versatilidade. Cada perfume do par recebe a sua.</p>
    </div>
    <div class="leitura__item">
      <div class="leitura__visual"><p class="leitura__eco">91<span class="pct">%</span></p></div>
      <h3>Economia por ml</h3>
      <p>Comparamos o preço por ml, porque os frascos têm tamanhos diferentes. Um original de 50 ml não se compara direto com uma alternativa de 100 ml.</p>
    </div>
  </div>
</section>
<section class="secao envoltorio">
  <div class="secao__cabeca">
    <h2 class="secao__titulo">Antes de comprar</h2>
    <p class="secao__texto">As alternativas desta lista são perfumes legítimos de marcas como Lattafa, Armaf e Maison Alhambra. O risco está nas falsificações, que existem até dessas marcas.</p>
  </div>
  <ul class="dicas">
    <li><h3>Prefira lojas oficiais</h3><p>Compre da loja oficial da marca ou de vendedores com muitas avaliações e nota alta no marketplace.</p></li>
    <li><h3>Desconfie de preço baixo demais</h3><p>Se um perfume custa muito menos que a faixa média indicada aqui, é provável que seja falsificado.</p></li>
    <li><h3>Confira a embalagem</h3><p>Caixa com celofane bem selado, código de barras e número de lote impressos na caixa e no frasco.</p></li>
    <li><h3>Teste uma amostra</h3><p>Se puder, compre antes um decant (amostra de 5 a 10 ml). Cada pele reage de um jeito.</p></li>
  </ul>
</section>`;
  return {
    rota: "inicio",
    genero: "",
    ativo: "inicio",
    titulo: `${site.nome} | Perfumes importados e suas versões em conta`,
    descricao: site.descricao,
    caminho: "",
    corpo,
  };
}

// ---------------------------------------------------------------------------
// Página de gênero (ranking com filtros)
// ---------------------------------------------------------------------------

export function paginaGenero(genero, pares, ctx) {
  const lista = pares.filter((p) => p.genero === genero);
  const info = GENEROS[genero];
  const grupos = [...new Set(lista.map((p) => p.grupo))].sort((a, b) => a.localeCompare(b, "pt-BR"));
  const idBusca = `busca-${genero}`;
  const idOrdem = `ordem-${genero}`;
  const itens = lista
    .map((p) => `<li class="lista__item" data-grupo="${esc(p.grupo)}" data-rank="${p.rank}" data-economia="${p.economia}" data-semelhanca="${p.semelhanca}" data-nota="${p.alt.nota}" data-busca="${esc(textoBusca(p))}">${cartao(p, ctx, 2)}</li>`)
    .join("\n");
  const corpo = `
<section class="cabeca envoltorio">
  <nav class="trilha" aria-label="Você está em"><a href="${ctx.inicio()}">Início</a><span aria-hidden="true">/</span><span>${info.nome}</span></nav>
  <p class="olho">Top ${lista.length} · edição ${site.ano}</p>
  <h1 class="cabeca__titulo">Perfumes ${info.plural} importados e suas versões em conta</h1>
  <p class="cabeca__texto">Os ${lista.length} ${info.plural} mais desejados, cada um ao lado da alternativa que mais se aproxima dele. A ordem é o ranking da curadoria: fama do original, procura no Brasil e qualidade da alternativa.</p>
</section>
<section class="catalogo envoltorio" data-catalogo>
  <div class="filtros">
    <label class="filtros__busca" for="${idBusca}">
      <span class="sr">Buscar</span>
      <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false"><circle cx="10.5" cy="10.5" r="6.5" fill="none" stroke="currentColor" stroke-width="2"/><path d="m15.5 15.5 5 5" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
      <input id="${idBusca}" type="search" placeholder="Perfume, marca ou nota (ex.: baunilha)" autocomplete="off">
    </label>
    <div class="filtros__grupos" role="group" aria-label="Família olfativa">
      <button type="button" class="chip" data-filtro="todos" aria-pressed="true">Todos</button>
      ${grupos.map((g) => `<button type="button" class="chip" data-filtro="${esc(g)}" aria-pressed="false">${esc(g)}</button>`).join("")}
    </div>
    <label class="filtros__ordem" for="${idOrdem}">
      <span>Ordenar por</span>
      <select id="${idOrdem}">
        <option value="rank">Ranking</option>
        <option value="economia">Maior economia</option>
        <option value="semelhanca">Mais parecidos</option>
        <option value="nota">Melhor nota da versão em conta</option>
      </select>
    </label>
  </div>
  <p class="catalogo__contagem" data-contagem aria-live="polite">${lista.length} comparações</p>
  <ol class="lista" data-lista>
${itens}
  </ol>
  <p class="catalogo__vazio" data-vazio hidden>Nenhum perfume encontrado. Tente outra nota ou volte para "Todos".</p>
</section>`;
  return {
    rota: genero,
    genero,
    ativo: genero,
    titulo: `Top ${lista.length} perfumes ${info.plural} importados e suas versões mais baratas | ${site.nome}`,
    descricao: `Os ${lista.length} perfumes ${info.plural} importados mais desejados ao lado das alternativas mais parecidas: semelhança, notas olfativas, fixação, preço e onde comprar.`,
    caminho: `${genero}/`,
    corpo,
    jsonld: {
      "@context": "https://schema.org",
      "@type": "ItemList",
      name: `Top ${lista.length} perfumes ${info.plural} e suas versões em conta`,
      itemListElement: lista.map((p) => ({
        "@type": "ListItem",
        position: p.rank,
        name: `${p.original.titulo} × ${p.alt.titulo}`,
        url: `${site.url}${site.basePath}${p.genero}/${p.slug}/`,
      })),
    },
  };
}

// ---------------------------------------------------------------------------
// Página de comparação
// ---------------------------------------------------------------------------

function ficha(p, papel, ctx) {
  const ehOriginal = papel === "original";
  return `<article class="ficha ficha--${papel}">
    <div class="ficha__frasco">${frasco(p, "frasco--ficha", ctx)}</div>
    <p class="papel papel--${papel}">${ehOriginal ? "O original" : "Versão em conta"}</p>
    ${nomePerfume(p, "h2", "nome")}
    <p class="ficha__meta">${esc(CONCENTRACOES[p.conc] || p.conc)}${p.ano ? ` · ${p.ano}` : ""}</p>
    <dl class="ficha__dados">
      <div class="ficha__nota"><dt>Nota da curadoria</dt><dd>${fmtNota(p.nota)}<small>/10</small></dd></div>
      <div><dt>Preço estimado</dt><dd>${fmtFaixa(p.preco)}<small>${p.ml} ml</small></dd></div>
      <div><dt>Preço por ml</dt><dd>≈ ${fmtPorMl(p.precoMl)}</dd></div>
      <div><dt>Fixação</dt><dd>${fmtHoras(p.fixacao)}</dd></div>
      <div><dt>Projeção</dt><dd>${gotas(p.projecao)}<small>${PROJECAO[p.projecao]}</small></dd></div>
      <div><dt>Família</dt><dd class="ficha__familia">${esc(p.familia)}</dd></div>
    </dl>
    <p class="compra__titulo">Ver preço em</p>
    ${botoesCompra(p)}
  </article>`;
}

const ETAPAS = [
  ["saida", "Saída", "Primeiros 15 minutos"],
  ["coracao", "Coração", "De 30 minutos a 3 horas"],
  ["fundo", "Fundo", "O que fica na pele"],
];

function iconeEtapa(i) {
  // Triângulo em três faixas; a faixa da etapa atual fica preenchida.
  const faixas = [
    "M12 3 L15.6 9 H8.4 Z",
    "M8 10 H16 L19.6 16 H4.4 Z",
    "M4 17 H20 L22 21 H2 Z",
  ];
  return `<svg class="etapa__icone" viewBox="0 0 24 24" aria-hidden="true" focusable="false">${faixas
    .map((d, k) => `<path d="${d}" fill="currentColor" fill-opacity="${k === i ? 1 : 0.22}"/>`)
    .join("")}</svg>`;
}

function chipsNotas(lista, outro) {
  return `<ul class="notas">${lista
    .map((n) => {
      const comum = notaPresente(n, outro);
      return `<li class="nota-chip${comum ? " nota-chip--comum" : ""}">${esc(n)}${comum ? '<span class="sr"> (nos dois)</span>' : ""}</li>`;
    })
    .join("")}</ul>`;
}

function piramide(par) {
  const { original: o, alt: a } = par;
  return ETAPAS.map(([chave, nome, tempo], i) => `<div class="etapa">
      <div class="etapa__cabeca">${iconeEtapa(i)}<h3>${nome}</h3><p>${tempo}</p></div>
      <div class="etapa__lado"><p class="etapa__quem">${esc(o.nome)}</p>${chipsNotas(o.notas[chave], a)}</div>
      <div class="etapa__lado"><p class="etapa__quem">${esc(a.nome)}</p>${chipsNotas(a.notas[chave], o)}</div>
    </div>`).join("");
}

function quandoUsar(par) {
  const climas = ["Calor", "Meia-estação", "Frio"];
  const periodos = ["Dia", "Noite"];
  const usaPeriodo = (p) => par.periodo === "Dia e noite" || par.periodo === p;
  const marca = (ativo, texto) => `<li class="uso${ativo ? " uso--sim" : ""}">${texto}${ativo ? "" : '<span class="sr"> (menos indicado)</span>'}</li>`;
  return `<div class="usos">
      <div><h3>Clima</h3><ul class="usos__lista">${climas.map((c) => marca(par.clima.includes(c), c)).join("")}</ul></div>
      <div><h3>Período</h3><ul class="usos__lista">${periodos.map((p) => marca(usaPeriodo(p), p)).join("")}</ul></div>
      <div><h3>Ocasiões</h3><ul class="usos__lista">${par.ocasioes.map((o) => marca(true, esc(o))).join("")}</ul></div>
    </div>`;
}

const juntar = (lista) => (lista.length > 1 ? `${lista.slice(0, -1).join(", ")} e ${lista.at(-1)}` : lista[0] || "");

function resumoUso(par) {
  const periodo = { Dia: "de dia", Noite: "à noite", "Dia e noite": "de dia e à noite" }[par.periodo] || par.periodo;
  const climas = { Calor: "no calor", "Meia-estação": "na meia-estação", Frio: "no frio" };
  const ordem = Object.keys(climas).filter((c) => par.clima.includes(c));
  const onde = ordem.length === 3 ? "o ano todo" : juntar(ordem.map((c) => climas[c]));
  const texto = `Funciona melhor ${periodo}, ${onde}.`;
  return esc(texto.charAt(0).toUpperCase() + texto.slice(1));
}

function tabelaAvaliacao(par) {
  const { original: o, alt: a } = par;
  const linha = (criterio, vo, va, destaque = "") =>
    `<tr${destaque ? ` class="${destaque}"` : ""}><th scope="row">${criterio}</th><td>${vo}</td><td>${va}</td></tr>`;
  return `<div class="tabela-rolagem"><table class="avaliacao">
      <thead><tr><th scope="col">Critério</th><th scope="col">${esc(o.nome)}</th><th scope="col">${esc(a.nome)}</th></tr></thead>
      <tbody>
        ${linha("Nota da curadoria", `${fmtNota(o.nota)}/10`, `${fmtNota(a.nota)}/10`)}
        ${linha("Fixação", fmtHoras(o.fixacao), fmtHoras(a.fixacao))}
        ${linha("Projeção", PROJECAO[o.projecao], PROJECAO[a.projecao])}
        ${linha("Concentração", esc(CONCENTRACOES[o.conc] || o.conc), esc(CONCENTRACOES[a.conc] || a.conc))}
        ${linha("Frasco de referência", `${o.ml} ml`, `${a.ml} ml`)}
        ${linha("Preço estimado", fmtFaixa(o.preco), fmtFaixa(a.preco))}
        ${linha("Preço por ml", `≈ ${fmtPorMl(o.precoMl)}`, `≈ ${fmtPorMl(a.precoMl)}`, "avaliacao__economia")}
      </tbody>
    </table></div>`;
}

export function paginaPar(par, pares, ctx) {
  const { original: o, alt: a } = par;
  const info = GENEROS[par.genero];
  const mesmos = pares.filter((p) => p.genero === par.genero);
  const relacionados = [1, 2, 3].map((k) => mesmos[(par.rank - 1 + k) % mesmos.length]);
  const outras = (par.outras || []).length
    ? `<div class="outras">
        <h3>Outras alternativas para o ${esc(o.nome)}</h3>
        <ul>${par.outras.map((n) => `<li><a href="${esc(linkDeBusca(n))}" target="_blank" rel="sponsored nofollow noopener">${esc(n)} <span aria-hidden="true">↗</span></a></li>`).join("")}</ul>
      </div>`
    : "";
  const corpo = `
<section class="duelo envoltorio">
  <nav class="trilha" aria-label="Você está em"><a href="${ctx.inicio()}">Início</a><span aria-hidden="true">/</span><a href="${ctx.genero(par.genero)}">${info.nome}</a><span aria-hidden="true">/</span><span>${esc(o.nome)}</span></nav>
  <p class="olho">Nº ${pad2(par.rank)} do top ${TOTAIS[par.genero]} ${info.nome.toLowerCase()}</p>
  <h1 class="duelo__titulo"><span>${esc(o.titulo)}</span> <span class="duelo__x" aria-label="comparado com">×</span> <span>${esc(a.titulo)}</span></h1>
  <p class="duelo__veredito">${esc(par.veredito)}</p>
  <div class="duelo__grade">
    ${ficha(o, "original", ctx)}
    <div class="duelo__meio">
      ${anel(par.semelhanca, "anel--grande")}
      <p class="duelo__eco"><strong>${par.economia}<span class="pct">%</span></strong> mais barato por ml</p>
      <p class="duelo__comuns">${par.notasEmComum} de ${par.notasTotal} notas do original aparecem na versão em conta</p>
    </div>
    ${ficha(a, "alt", ctx)}
  </div>
</section>
<section class="secao envoltorio">
  <div class="secao__cabeca">
    <h2 class="secao__titulo">Pirâmide olfativa</h2>
    <p class="secao__texto"><span class="legenda-comum" aria-hidden="true"></span>Notas destacadas aparecem nos dois perfumes.</p>
  </div>
  <div class="piramide">${piramide(par)}</div>
</section>
<section class="secao envoltorio secao--duas">
  <div>
    <h2 class="secao__titulo">Acordes principais</h2>
    <p class="secao__texto">O DNA que os dois compartilham, do mais forte ao mais sutil.</p>
    <ul class="fitas">${par.acordes.map(([n, v]) => fita(n, v)).join("")}</ul>
  </div>
  <div>
    <h2 class="secao__titulo">Quando usar</h2>
    <p class="secao__texto">${resumoUso(par)}</p>
    ${quandoUsar(par)}
  </div>
</section>
<section class="secao envoltorio">
  <div class="secao__cabeca">
    <h2 class="secao__titulo">Avaliação lado a lado</h2>
    <p class="secao__texto">Valores da curadoria. Fixação e projeção mudam conforme a pele, o clima e a quantidade aplicada.</p>
  </div>
  ${tabelaAvaliacao(par)}
</section>
<section class="secao envoltorio">
  <div class="secao__cabeca"><h2 class="secao__titulo">Recomendações</h2></div>
  <div class="recomendacoes">
    <div class="reco"><h3>Para quem é</h3><p>${esc(par.paraQuem)}</p></div>
    <div class="reco"><h3>Diferenças que você vai notar</h3><p>${esc(par.diferencas)}</p></div>
    <div class="reco"><h3>Dica de uso</h3><p>${esc(par.dica)}</p></div>
  </div>
  ${outras}
</section>
<section class="secao envoltorio">
  <div class="secao__cabeca"><h2 class="secao__titulo">Veja também</h2></div>
  <div class="grade-cartoes">${relacionados.map((p) => cartao(p, ctx, 3)).join("")}</div>
</section>`;
  return {
    rota: par.slug,
    genero: par.genero,
    ativo: par.genero,
    titulo: `Perfume parecido com ${o.titulo}: ${a.titulo} | ${site.nome}`,
    descricao: `${a.titulo} tem ${par.semelhanca}% de semelhança com o ${o.titulo} e custa cerca de ${par.economia}% menos por ml. Compare notas, fixação, projeção e onde comprar.`,
    caminho: `${par.genero}/${par.slug}/`,
    imagem: ctx.foto(o),
    corpo,
    jsonld: {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      itemListElement: [
        { "@type": "ListItem", position: 1, name: "Início", item: `${site.url}${site.basePath}` },
        { "@type": "ListItem", position: 2, name: info.nome, item: `${site.url}${site.basePath}${par.genero}/` },
        { "@type": "ListItem", position: 3, name: `${o.titulo} × ${a.titulo}` },
      ],
    },
  };
}

// ---------------------------------------------------------------------------
// Como avaliamos
// ---------------------------------------------------------------------------

export function paginaMetodo(pares, ctx) {
  const corpo = `
<section class="cabeca envoltorio">
  <nav class="trilha" aria-label="Você está em"><a href="${ctx.inicio()}">Início</a><span aria-hidden="true">/</span><span>Como avaliamos</span></nav>
  <p class="olho">Metodologia</p>
  <h1 class="cabeca__titulo">Como avaliamos cada comparação</h1>
  <p class="cabeca__texto">Cada par junta um perfume importado de referência e a alternativa mais barata que mais se aproxima dele. Estes são os critérios por trás dos números.</p>
</section>
<section class="envoltorio texto-longo">
  <h2>Escolha dos pares</h2>
  <p>Partimos dos importados mais desejados no Brasil e buscamos, para cada um, a alternativa que a comunidade de perfumaria mais reconhece como parecida: avaliações de usuários, fóruns e comparações lado a lado. Quando há mais de uma boa opção, ela aparece em "Outras alternativas".</p>
  <h2>Ranking</h2>
  <p>A ordem dos rankings é editorial. Ela pesa a fama do perfume original, a procura no Brasil e a qualidade da versão em conta.</p>
  <h2>Semelhança</h2>
  <p>Percentual de 0 a 100 que indica quanto do cheiro do original a alternativa reproduz depois de assentar na pele, considerando saída, evolução e fundo. Abaixo de 75%, tratamos a alternativa como inspiração: tem o mesmo estilo, mas personalidade própria.</p>
  <h2>Nota da curadoria</h2>
  <p>Nota de 0 a 10 para cada perfume, avaliado por si só: qualidade e equilíbrio da composição, desempenho e versatilidade. Uma alternativa pode ter nota maior que o original quando entrega mais fixação ou um resultado mais agradável para o clima brasileiro.</p>
  <h2>Fixação e projeção</h2>
  <p>Fixação é a faixa de horas em que o perfume ainda é percebido na pele. Projeção vai de 1 (íntima, só quem chega perto sente) a 5 (muito forte, deixa rastro no ambiente). São referências médias; pele, clima e quantidade aplicada mudam bastante o resultado.</p>
  <h2>Preços e economia</h2>
  <p>Os preços são faixas estimadas para o frasco indicado, com base em lojas brasileiras, e mudam com frequência. A economia é calculada pelo preço médio por ml, já que originais e alternativas costumam ter tamanhos diferentes. Confira sempre o valor atual na loja.</p>
  <h2>Notas olfativas</h2>
  <p>As pirâmides seguem as notas divulgadas pelas marcas e pelas principais bases de perfumaria. As notas destacadas aparecem nos dois perfumes do par.</p>
  <h2>Links de compra</h2>
  <p>Os botões levam a buscas ou a produtos em lojas como Amazon, Mercado Livre e Shopee. Alguns links podem ser de afiliado: se você comprar por eles, podemos receber uma comissão, sem custo extra para você. Isso não muda as avaliações.</p>
  <h2>Marcas e originalidade</h2>
  <p>Não temos vínculo com nenhuma das marcas citadas. As versões em conta são perfumes de marcas próprias, como Lattafa, Armaf, Maison Alhambra, Afnan, Al Haramain, Rasasi e French Avenue, e não são falsificações nem réplicas dos frascos originais.</p>
  <p><a class="link-seta" href="${ctx.genero("feminino")}">Ver o top ${TOTAIS.feminino} feminino <span aria-hidden="true">→</span></a> <a class="link-seta" href="${ctx.genero("masculino")}">Ver o top ${TOTAIS.masculino} masculino <span aria-hidden="true">→</span></a></p>
</section>`;
  return {
    rota: "como-avaliamos",
    genero: "",
    ativo: "metodo",
    titulo: `Como avaliamos | ${site.nome}`,
    descricao: "Entenda como escolhemos os pares e calculamos semelhança, nota da curadoria, fixação, projeção e economia por ml.",
    caminho: "como-avaliamos/",
    corpo,
  };
}

export function pagina404(ctx) {
  return {
    rota: "404",
    genero: "",
    ativo: "",
    titulo: `Página não encontrada | ${site.nome}`,
    descricao: "Página não encontrada.",
    caminho: "404.html",
    corpo: `
<section class="cabeca envoltorio cabeca--404">
  <p class="olho">Erro 404</p>
  <h1 class="cabeca__titulo">Este frasco está vazio</h1>
  <p class="cabeca__texto">A página que você procura não existe ou mudou de endereço.</p>
  <p><a class="link-seta" href="${ctx.genero("feminino")}">Top ${TOTAIS.feminino} feminino <span aria-hidden="true">→</span></a> <a class="link-seta" href="${ctx.genero("masculino")}">Top ${TOTAIS.masculino} masculino <span aria-hidden="true">→</span></a></p>
</section>`,
  };
}
