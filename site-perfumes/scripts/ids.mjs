// Lista os ids de todos os perfumes, para usar em data/links.js.
import { carregarPares } from "../src/lib.js";

for (const par of carregarPares()) {
  console.log(`${par.genero.padEnd(9)} Nº ${String(par.rank).padStart(2, "0")}  ${par.original.id.padEnd(48)} ${par.alt.id}`);
}
