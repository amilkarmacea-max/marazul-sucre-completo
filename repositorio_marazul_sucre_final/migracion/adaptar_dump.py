import sys
import re
from pathlib import Path

origen, destino = sys.argv[1], sys.argv[2]
s = Path(origen).read_text(encoding="utf-8-sig")

indice = ("  UNIQUE KEY `uq_trip_crew_one_responsible` "
          "(((case when (`crew_role` = _utf8mb4'RESPONSABLE') then `trip_id` end))),\n")
if indice not in s:
    sys.exit("No se encontró el índice funcional de trip_crew")
s = s.replace(indice, "  UNIQUE KEY `uq_trip_crew_one_responsible` (`responsible_trip_id`),\n")

columna = "  `crew_role` varchar(25) NOT NULL DEFAULT 'TRIPULANTE',\n"
i = s.index("CREATE TABLE `trip_crew`")
j = s.index(columna, i) + len(columna)
virtual = ("  `responsible_trip_id` int GENERATED ALWAYS AS "
           "(CASE WHEN `crew_role` = 'RESPONSABLE' THEN `trip_id` END) VIRTUAL,\n")
s = s[:j] + virtual + s[j:]
s = re.sub(r'/\*!(\d{5,6})\s*(.*?)\*/', lambda m: m.group(2).strip() if int(m.group(1)) < 50700 else '', s, flags=re.S)
s = re.sub(r'DEFINER\s*=\s*`[^`]+`@`[^`]+`\s*', '', s)
Path(destino).write_text(s, encoding="utf8")
print("Listo:", destino)
