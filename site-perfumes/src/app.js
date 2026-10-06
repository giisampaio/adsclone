// Interações do site: busca, filtro por família e ordenação no top 20.
// Na prévia de arquivo único, também faz a navegação entre páginas por #âncora.

(() => {
  "use strict";

  const normalizar = (s) => s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();

  function iniciarCatalogo(raiz) {
    const busca = raiz.querySelector('input[type="search"]');
    const chips = [...raiz.querySelectorAll("[data-filtro]")];
    const ordem = raiz.querySelector("select");
    const lista = raiz.querySelector("[data-lista]");
    const itens = [...lista.children];
    const contagem = raiz.querySelector("[data-contagem]");
    const vazio = raiz.querySelector("[data-vazio]");
    let grupo = "todos";

    function aplicar() {
      const termos = normalizar(busca.value).split(/\s+/).filter(Boolean);
      let visiveis = 0;
      for (const item of itens) {
        const okGrupo = grupo === "todos" || item.dataset.grupo === grupo;
        const okBusca = termos.every((t) => item.dataset.busca.includes(t));
        item.hidden = !(okGrupo && okBusca);
        if (!item.hidden) visiveis++;
      }
      const chave = ordem.value;
      const ordenados = [...itens].sort((a, b) =>
        chave === "rank"
          ? a.dataset.rank - b.dataset.rank
          : b.dataset[chave] - a.dataset[chave] || a.dataset.rank - b.dataset.rank
      );
      for (const item of ordenados) lista.appendChild(item);
      contagem.textContent = visiveis === 1 ? "1 comparação" : `${visiveis} comparações`;
      vazio.hidden = visiveis > 0;
    }

    busca.addEventListener("input", aplicar);
    ordem.addEventListener("change", aplicar);
    for (const chip of chips) {
      chip.addEventListener("click", () => {
        grupo = chip.dataset.filtro;
        for (const c of chips) c.setAttribute("aria-pressed", String(c === chip));
        aplicar();
      });
    }
  }

  document.querySelectorAll("[data-catalogo]").forEach(iniciarCatalogo);

  // ------------------------------------------------------------ prévia de arquivo único
  const rotas = [...document.querySelectorAll("[data-rota]")];
  if (!rotas.length) return;

  const links = [...document.querySelectorAll("[data-nav]")];

  function mostrar(rota, rolar) {
    for (const r of rotas) r.hidden = r !== rota;
    const genero = rota.dataset.tema;
    if (genero) document.documentElement.dataset.genero = genero;
    else delete document.documentElement.dataset.genero;
    for (const l of links) {
      if (l.dataset.nav === rota.dataset.ativo && l.dataset.nav !== "inicio") l.setAttribute("aria-current", "page");
      else l.removeAttribute("aria-current");
    }
    document.title = rota.dataset.titulo;
    if (rolar) window.scrollTo(0, 0);
  }

  function navegar(rolar) {
    const id = decodeURIComponent(location.hash.slice(1));
    const rota = rotas.find((r) => r.dataset.rota === id);
    if (rota) mostrar(rota, rolar);
    else if (!id) mostrar(rotas[0], rolar);
  }

  window.addEventListener("hashchange", () => navegar(true));
  navegar(false);
})();
