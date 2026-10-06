// Configurações gerais do site.
// Altere aqui o nome, o domínio e os códigos de afiliado.

export const site = {
  nome: "Essência Gêmea",
  slogan: "Perfumes importados e suas versões em conta, lado a lado.",
  descricao:
    "Compare 40 perfumes importados famosos com alternativas mais baratas: notas olfativas, fixação, projeção, nota da curadoria e quanto você economiza.",
  // Domínio final do site (sem barra no fim). Usado no sitemap, canonical e Open Graph.
  url: "https://www.essenciagemea.com.br",
  // Use "/" se o site ficar na raiz do domínio. Ex.: "/perfumes/" se ficar numa subpasta.
  basePath: "/",
  ano: 2026,
};

// Afiliados
// - amazon.tag: seu ID de Associado Amazon (ex.: "seusite-20"). Quando preenchido,
//   todos os links de busca da Amazon recebem "&tag=..." automaticamente.
// - Para Mercado Livre e Shopee, os programas geram links próprios por produto:
//   cole esses links em data/links.js (eles substituem os links de busca).
export const afiliados = {
  amazon: { tag: "" },
  mercadolivre: {},
  shopee: {},
};

// Lojas exibidas nos botões de compra, na ordem em que aparecem.
export const lojas = [
  {
    id: "amazon",
    nome: "Amazon",
    busca: (q) => `https://www.amazon.com.br/s?k=${encodeURIComponent(q)}`,
  },
  {
    id: "mercadolivre",
    nome: "Mercado Livre",
    busca: (q) =>
      `https://lista.mercadolivre.com.br/${q
        .normalize("NFD")
        .replace(/[̀-ͯ]/g, "")
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-|-$/g, "")}`,
  },
  {
    id: "shopee",
    nome: "Shopee",
    busca: (q) => `https://shopee.com.br/search?keyword=${encodeURIComponent(q)}`,
  },
];
