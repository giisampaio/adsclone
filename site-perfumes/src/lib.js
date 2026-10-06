// Funções de dados: monta os pares, calcula economia, notas em comum e links de compra.

import { afiliados, lojas } from "../data/site.js";
import { links } from "../data/links.js";
import { fotos, fragrantica, urlFragrantica } from "../data/imagens.js";
import { feminino } from "../data/feminino.js";
import { masculino } from "../data/masculino.js";

export const GENEROS = {
  feminino: { id: "feminino", nome: "Feminino", plural: "femininos" },
  masculino: { id: "masculino", nome: "Masculino", plural: "masculinos" },
};

export const CONCENTRACOES = {
  EDT: "Eau de Toilette",
  "EDT Intense": "Eau de Toilette Intense",
  EDP: "Eau de Parfum",
  Parfum: "Parfum",
  Elixir: "Elixir",
  Extrait: "Extrait de Parfum",
};

export const PROJECAO = ["", "Íntima", "Discreta", "Moderada", "Forte", "Muito forte"];

export const slugify = (s) =>
  String(s)
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/&/g, " e ")
    .replace(/['’]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");

export const normalizar = (s) =>
  String(s)
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase();

const medio = ([min, max]) => (min + max) / 2;

function prepararPerfume(p) {
  return {
    ...p,
    id: slugify(`${p.marca} ${p.nome}`),
    titulo: `${p.marca} ${p.nome}`,
    precoMl: medio(p.preco) / p.ml,
  };
}

// Duas notas "batem" quando são iguais ou começam pela mesma matéria-prima
// (ex.: "Baunilha" e "Baunilha bourbon"). Algumas palavras iniciais são genéricas
// demais e exigem o nome completo (ex.: "Pimenta-rosa" ≠ "Pimenta-preta").
const RAIZES_GENERICAS = new Set(["ambar", "notas", "nota", "folha", "folhas", "flor", "acorde", "pimenta", "madeiras", "madeira", "oleo"]);

function chavesDaNota(nota) {
  const completa = slugify(nota);
  const raiz = completa.split("-")[0];
  return { completa, raiz: RAIZES_GENERICAS.has(raiz) ? completa : raiz };
}

export function notaPresente(nota, outroPerfume) {
  const a = chavesDaNota(nota);
  return todasNotas(outroPerfume).some((n) => {
    const b = chavesDaNota(n);
    return a.completa === b.completa || a.raiz === b.raiz;
  });
}

export const todasNotas = (p) => [...p.notas.saida, ...p.notas.coracao, ...p.notas.fundo];

function montarLista(genero, lista) {
  return lista.map((par, i) => {
    const original = prepararPerfume(par.original);
    const alt = prepararPerfume(par.alt);
    const notasOriginal = todasNotas(original);
    const emComum = notasOriginal.filter((n) => notaPresente(n, alt)).length;
    return {
      ...par,
      genero,
      rank: i + 1,
      original,
      alt,
      slug: slugify(`${original.marca} ${original.nome} vs ${alt.nome}`),
      economia: Math.round((1 - alt.precoMl / original.precoMl) * 100),
      notasEmComum: emComum,
      notasTotal: notasOriginal.length,
    };
  });
}

export function carregarPares() {
  const pares = [...montarLista("feminino", feminino), ...montarLista("masculino", masculino)];
  const vistos = new Set();
  for (const p of pares) {
    if (vistos.has(p.slug)) throw new Error(`Slug repetido: ${p.slug}`);
    vistos.add(p.slug);
  }
  return pares;
}

export function linksDeCompra(perfume) {
  const proprios = links[perfume.id] || {};
  const consulta = perfume.busca || perfume.titulo;
  return lojas.map((loja) => {
    const proprio = proprios[loja.id];
    let url = proprio || loja.busca(consulta);
    if (!proprio && loja.id === "amazon" && afiliados.amazon.tag) {
      url += `&tag=${encodeURIComponent(afiliados.amazon.tag)}`;
    }
    return { id: loja.id, nome: loja.nome, url, afiliado: Boolean(proprio) };
  });
}

// URL externa da foto (sua URL em data/imagens.js ou a do Fragrantica). Vazio se não houver.
export function fonteDaFoto(perfume) {
  if (fotos[perfume.id]) return fotos[perfume.id];
  return fragrantica[perfume.id] ? urlFragrantica(fragrantica[perfume.id]) : "";
}

export function linkDeBusca(texto, lojaId = "amazon") {
  const loja = lojas.find((l) => l.id === lojaId) || lojas[0];
  let url = loja.busca(texto);
  if (loja.id === "amazon" && afiliados.amazon.tag) url += `&tag=${encodeURIComponent(afiliados.amazon.tag)}`;
  return url;
}

const brl0 = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL", maximumFractionDigits: 0 });
const brl2 = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL", minimumFractionDigits: 2, maximumFractionDigits: 2 });
const num0 = new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 0 });
const num1 = new Intl.NumberFormat("pt-BR", { minimumFractionDigits: 1, maximumFractionDigits: 1 });

export const fmtFaixa = ([min, max]) => `${brl0.format(min)}–${num0.format(max)}`;
export const fmtPorMl = (v) => (v >= 10 ? brl0.format(v) : brl2.format(v));
export const fmtNota = (v) => num1.format(v);
export const fmtHoras = ([min, max]) => `${min}–${max} h`;
