// Fotos dos perfumes.
//
// Para cada perfume, o site usa a primeira opção disponível:
//   1. Um arquivo seu em imagens/perfumes/<id>.jpg (ou .png / .webp).
//      Rode `npm run imagens` para baixar todas as fotos para essa pasta.
//   2. Uma URL sua em `fotos` abaixo (ex.: a foto do produto que o programa de
//      afiliados da Amazon, do Mercado Livre ou da Shopee fornece).
//   3. A foto do frasco no Fragrantica, pelo número da página do perfume
//      (fragrantica.com/perfume/Marca/Nome-NUMERO.html).
//   4. A ilustração do frasco, se nenhuma foto carregar.
//
// Rode `npm run ids` para ver o id de cada perfume.

export const fotos = {
  // "lattafa-asad": "https://m.media-amazon.com/images/I/xxxxxxxx.jpg",
};

export const fragrantica = {
  // Masculino
  "creed-aventus": 9828,
  "armaf-club-de-nuit-intense-man": 34696,
  "dior-sauvage-elixir": 68415,
  "lattafa-asad": 72821,
  "dior-sauvage": 48100,
  "maison-alhambra-salvo": 93538,
  "chanel-bleu-de-chanel": 25967,
  "armaf-club-de-nuit-iconic": 78475,
  "jean-paul-gaultier-ultra-male": 30947,
  "afnan-9pm": 65414,
  "kilian-angels-share": 62615,
  "lattafa-khamrah": 75805,
  "initio-oud-for-greatness": 53641,
  "lattafa-badee-al-oud-oud-for-glory": 64948,
  "yves-saint-laurent-y": 50757,
  "lattafa-fakhar-black": 70465,
  "jean-paul-gaultier-le-male-elixir": 81642,
  "lattafa-the-kingdom": 97995,
  "paco-rabanne-invictus": 18471,
  "rasasi-hawas-for-him": 46890,
  "paco-rabanne-1-million-parfum": 60035,
  "lattafa-fakhar-gold-extrait": 85092,
  "parfums-de-marly-layton": 39314,
  "al-haramain-detour-noir": 70748,
  "parfums-de-marly-althair": 84109,
  "french-avenue-liquid-brun": 94713,
  "tom-ford-tobacco-vanille": 1825,
  "maison-alhambra-tobacco-touch": 79943,
  "dior-homme-intense": 13016,
  "maison-alhambra-dark-door-intense": 94172,
  "creed-green-irish-tweed": 474,
  "armaf-tres-nuit": 27711,
  "creed-silver-mountain-water": 472,
  "armaf-club-de-nuit-sillage": 64105,
  "tom-ford-tuscan-leather": 1849,
  "maison-alhambra-toscano-leather": 79942,
  "tom-ford-oud-wood": 1826,
  "maison-alhambra-woody-oud": 79940,
  "louis-vuitton-ombre-nomade": 49755,
  "maison-alhambra-jean-lowe-noir": 95137,

  // Feminino
  "maison-francis-kurkdjian-baccarat-rouge-540": 33519,
  "armaf-club-de-nuit-untold": 78476,
  "carolina-herrera-good-girl": 39681,
  "lattafa-qimmah-for-women": 82793,
  "lancome-la-vie-est-belle": 14982,
  "maison-alhambra-la-vita-bella": 122718,
  "yves-saint-laurent-libre": 56077,
  "maison-alhambra-leonie": 95881,
  "chanel-coco-mademoiselle": 611,
  "armaf-club-de-nuit-woman": 27655,
  "parfums-de-marly-delina": 43871,
  "maison-alhambra-delilah": 90273,
  "yves-saint-laurent-black-opium": 25324,
  "maison-alhambra-opera-noir": 92625,
  "valentino-donna-born-in-roma-intense": 78739,
  "lattafa-yara": 76880,
  "burberry-goddess": 83483,
  "lattafa-angham": 96768,
  "mugler-angel-nova": 61519,
  "lattafa-mayar": 84309,
  "xerjoff-erba-pura": 55157,
  "al-haramain-amber-oud-gold-edition": 51816,
  "paco-rabanne-olympea": 31666,
  "maison-alhambra-olivia": 85050,
  "viktor-e-rolf-flowerbomb": 1460,
  "maison-alhambra-victoria-flower": 92618,
  "tom-ford-lost-cherry": 51411,
  "maison-alhambra-lovely-cherie": 79944,
  "kilian-good-girl-gone-bad": 15924,
  "maison-alhambra-kismet-for-women": 75475,
  "kilian-love-dont-be-shy": 4322,
  "lattafa-ansaam-gold": 82731,
  "chanel-chance-eau-tendre": 8069,
  "maison-alhambra-chants-tenderina": 89034,
  "burberry-her": 51694,
  "lattafa-rave-now-women": 85088,
  "parfums-de-marly-oriana": 69117,
  "french-avenue-olena": 101175,
  "tom-ford-bitter-peach": 62707,
  "maison-alhambra-bright-peach": 79937,
};

export const urlFragrantica = (numero) => `https://fimgs.net/mdimg/perfume/375x500.${numero}.jpg`;
