# Essência Gêmea

Guia de perfumes importados e suas versões em conta, lado a lado. Traz o
top 40 feminino e o top 40 masculino: cada página mostra o original e a
alternativa com notas olfativas, fixação, projeção, nota da curadoria, economia
por ml e botões de compra.

O site é estático (HTML + CSS + um pouco de JavaScript), gerado por um script
Node sem dependências. Cada comparação vira uma página própria, o que ajuda no
Google ("perfume parecido com Creed Aventus").

## Estrutura

```
data/
  site.js        nome do site, domínio, tag de afiliado da Amazon e lojas
  links.js       seus links de afiliado por perfume (substituem os links de busca)
  imagens.js     de onde vem a foto de cada perfume
  feminino.js    top 40 feminino
  masculino.js   top 40 masculino (os campos estão explicados no topo do arquivo)
src/
  lib.js         cálculos: economia por ml, notas em comum, links de compra
  render.js      templates HTML de todas as páginas
  styles.css     visual do site (paleta feminina, masculina e neutra)
  app.js         busca, filtros e ordenação do ranking
imagens/perfumes/  fotos baixadas com `npm run imagens`
build.mjs        gera o site em dist/ (ou a prévia de arquivo único com --previa)
```

## Como rodar

Precisa de Node 18 ou mais recente.

```bash
npm run build   # gera dist/
npm run dev     # gera e abre em http://localhost:4173
npm run previa  # gera previa/essencia-gemea.html, um arquivo único navegável
```

## Links de afiliado

Hoje os botões levam para a busca de cada perfume na Amazon, no Mercado Livre e
na Shopee. Para trocar pelos seus links:

1. **Amazon Associados:** coloque seu ID em `data/site.js` → `afiliados.amazon.tag`
   (ex.: `"seusite-20"`). Todos os links de busca da Amazon passam a levar sua tag.
2. **Links por produto (Amazon, Mercado Livre, Shopee):** rode `npm run ids` para
   ver o id de cada perfume e cole os links em `data/links.js`:

   ```js
   export const links = {
     "lattafa-asad": {
       amazon: "https://amzn.to/xxxxxxx",
       mercadolivre: "https://mercadolivre.com/sec/xxxxxxx",
       shopee: "https://s.shopee.com.br/xxxxxxx",
     },
   };
   ```

   O que não estiver preenchido continua usando o link de busca.

Todos os links de compra saem com `rel="sponsored nofollow"`, como o Google pede
para links de afiliado.

## Adicionar ou editar perfumes

Cada par fica em `data/feminino.js` ou `data/masculino.js`. A posição no array é
a posição no ranking. Para adicionar o 41º, copie um bloco existente, ajuste os
campos e rode `npm run build`: a página nova, o card no ranking e o sitemap são
gerados automaticamente.

Campos que mais importam:

- `semelhanca`: 0 a 100 (%).
- `nota`: 0 a 10, para cada perfume.
- `preco: [mín, máx]` e `ml`: faixa estimada em reais para o frasco de referência.
  A economia é calculada pelo preço médio por ml.
- `notas: { saida, coracao, fundo }`: as notas iguais nos dois perfumes ficam
  destacadas sozinhas.

## Fotos dos perfumes

Cada perfume tem uma foto real do frasco. Para cada um, o site usa a primeira
opção disponível:

1. **Arquivo próprio** em `imagens/perfumes/<id>.jpg` (ou `.png`/`.webp`).
2. **URL própria** em `data/imagens.js` → `fotos` (por exemplo, a imagem do
   produto fornecida pelo programa de afiliados da Amazon, Mercado Livre ou Shopee).
3. **Foto do Fragrantica**, pelo número da página do perfume, já mapeado para os
   160 perfumes em `data/imagens.js` → `fragrantica`.
4. **Ilustração do frasco**, se a foto não carregar.

Para baixar as 160 fotos para dentro do projeto (recomendado: o site fica mais
rápido e não depende de outro servidor):

```bash
npm run imagens   # salva em imagens/perfumes/
npm run build
```

Depois, faça commit da pasta `imagens/`. As fotos pertencem às marcas. Para uso
comercial, o caminho mais seguro é trocar, aos poucos, pela imagem que o programa
de afiliados fornece para cada produto (opção 2).

## Publicar

**Com Docker** (Easypanel, Coolify, Railway, Render etc.): aponte para a pasta
`site-perfumes/`. O `Dockerfile` gera o site e serve com nginx na porta 80.

**Hospedagem estática** (Netlify, Vercel, Cloudflare Pages, Hostinger):
comando de build `node build.mjs`, pasta de publicação `dist`.

Antes de publicar, troque `url` em `data/site.js` pelo domínio real. Ele é usado
no sitemap, no link canônico e nas prévias de compartilhamento.

## Avisos que já estão no site

- Preços são faixas estimadas e mudam com frequência.
- Semelhança, notas e fixação são avaliações da curadoria.
- As alternativas são perfumes de marcas próprias, não falsificações.
- O site pode receber comissão pelos links (divulgação exigida pelos programas de afiliados).
