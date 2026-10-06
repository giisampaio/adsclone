// Lista os ids de todos os perfumes, para usar em data/links.js.
import { carregarPares } from "../src/lib.js";

for (const par of carregarPares()) {
  const ids = [par.original.id.padEnd(48), par.alt.id.padEnd(44), par.nacional?.id || ""];
  console.log(`${par.genero.padEnd(9)} Nº ${String(par.rank).padStart(2, "0")}  ${ids.join(" ").trimEnd()}`);
}
