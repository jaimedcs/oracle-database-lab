# Laboratorio 4 — Respuestas y preguntas tipo examen

**Práctica 1 · Oracle DBA Workflow I (v3)**

**Entorno utilizado:** Oracle FREE 23.26.3.0.0 en Docker, CDB `FREE`, PDB `FREEPDB1`, volumen `oralab-26ai-data`. Las cifras citadas son las de nuestras evidencias; no las salidas de ejemplo del enunciado.

## 1. Preguntas de comprobación (1–38)

### Respaldo y diagnóstico

**1.** Porque se ejecutó `SHUTDOWN IMMEDIATE` antes de copiar: Oracle hizo el checkpoint y cerró limpiamente datafiles y redo. Si copiamos con la base abierta, la copia de archivos por sí sola no garantiza consistencia y requeriría una estrategia de backup en caliente y recuperación. Evidencia: `00-backup-lab3.script.log`.

**2.** `manifiesto.txt` identifica fecha, volumen, imagen y commit de la copia; `SHA256SUMS` permite detectar alteraciones en cada archivo. `restaurar-estado.sh` verifica primero los SHA-256 y solo después puede tocar el volumen. Mi comprobación devolvió OK para los cuatro archivos de la copia.

**3.** RPO es cuánto trabajo se perdería: aquí, todo cambio posterior al backup `20261023T083354Z_lab3-final` si hubiera que restaurarlo. RTO es cuánto tardaríamos en volver a dar servicio; el laboratorio 4 comprueba integridad y disponibilidad, pero no mide un tiempo real de restauración completo (eso queda para la prueba de restauración).


### Correcciones del Lab 3

**4.** V000 usó rutas relativas. Oracle las resolvió en `$ORACLE_HOME/dbs`, que en mi contenedor apuntaba mediante un enlace a `/opt/oracle/oradata/dbconfig/FREE/dbs`. Por eso no estaban fuera del volumen, pero sí en un lugar poco apropiado. `DB_CREATE_FILE_DEST` configurado habría permitido usar OMF en una ruta prevista. Evidencia 01.

**5.** `ALTER TABLESPACE ... RENAME DATAFILE` modifica la referencia del control file, pero no mueve físicamente los bytes. Por eso el script pasa el tablespace a OFFLINE, copia el datafile conservando propietario/permisos, cambia la referencia, lo pone ONLINE y solo entonces elimina el original. Evidencia 03.

**6.** Una migración aplicada es parte de la historia reproducible: editar V000 alteraría lo que se ejecutó en otros entornos. V003 añade la corrección sin reescribir esa historia. Quitar una contraseña del código no invalida la ya establecida en Oracle; con `NO AUTHENTICATION` las cuentas ya no aceptan esa credencial. Evidencia 04.

**7.** Se borró y recreó el contenedor manteniendo `oralab-26ai-data`: sobrevivieron los cinco datafiles, los tablespaces ONLINE y las 14 tablas de negocio. Así se demuestra que los datos dependen del volumen, no de la capa temporal del contenedor. Evidencia `03-prueba-persistencia`.


### Instancia, arranque y parámetros

**8.** Instancia: `STARTUP_TIME`, `STATUS=OPEN` y procesos/PID (evidencias 05, 09). Base: `DBID=1509902213`, `ARCHIVELOG`, y 16 datafiles (evidencias 05 y 11). La instancia cambia al reiniciar; los archivos y la identidad de la base persisten.

**9.** NOMOUNT lee el SPFILE y crea SGA y procesos, pero no abre control files (`ORA-01507` al preguntar a V$DATABASE). MOUNT abre control files y conoce estructura/datafiles, pero no el diccionario de datos (`ORA-01219` en DBA_TABLES). OPEN abre datafiles y redo y ya permite consultas normales. Evidencia 06.

**10.** `V$PARAMETER` muestra el valor efectivo en memoria; `V$SPPARAMETER`, lo persistido en el SPFILE. Para `db_files` se vio 200 en memoria y 300 pendiente en SPFILE; después `ALTER SYSTEM RESET` eliminó ese valor pendiente. Evidencia 07.

**11.** `PROCESSES` es estático: la columna de modificación de `V$PARAMETER` no autoriza necesariamente `SCOPE=MEMORY`; el intento devolvió `ORA-02095` (acompañado de `ORA-02097`). Requiere cambiar SPFILE y reiniciar. Evidencia 07.


### Memoria y procesos

**12.** Usa ASMM: `SGA_TARGET=1536M`, `PGA_AGGREGATE_TARGET=512M` y `MEMORY_TARGET=0` (también `MEMORY_SIZE=0`). Oracle gestiona dinámicamente componentes de SGA, mientras PGA se controla aparte. Evidencia 08.

**13.** Ronda fría: 357 lecturas lógicas y 261 físicas para 17.600 alumnos activos; ronda caliente: 247 lógicas y 0 físicas. La tasa de acierto física de la segunda ronda fue 100 %; los bloques ya estaban en el Buffer Cache. Evidencia `08-cache`.

**14.** Con literales hubo 1.051 análisis y 1.008 hard parse (750 ms), mientras que con `:id` hubo 1 análisis y 1 hard parse (10 ms) para 1.000 ejecuciones. En `V$SQL` quedó 1 cursor reutilizado 1.000 veces con bind, frente a 698 cursores con literales aún presentes. Evidencia `08-parse-pga`.

**15.** LGWR tiene `SPID=903` en `V$PROCESS` y se identifica como `db_lgwr_FREE` con PID 903 desde el Linux del contenedor. `docker top` puede mostrar otro PID porque el host y el contenedor tienen distintos espacios de nombres de PID. Evidencia 09.


### Contenedores

**16.** SYS en `CDB$ROOT` ve 16 datafiles porque la vista incluye CDB$ROOT (4), PDB$SEED (3) y FREEPDB1 (9). Tras `SET CONTAINER=FREEPDB1`, solo aparecen los 9 de esa PDB. Evidencia 10.

**17.** `LAB4_ANALISTA` solo tenía `CREATE SESSION`; Oracle no le concede acceso a `DBA_TABLES`. Devuelve `ORA-00942` sin revelar la existencia de objetos fuera de su ámbito, en lugar de mostrar simplemente sus filas. Evidencia 10.

**18.** `C##LAB4_AUDITOR` no tenía el atributo `CONTAINER_DATA` para todas las PDB: desde la raíz veía solo CON_ID 1 (y 0 en determinadas V$). `C##OPS_RO` tiene `DEFAULT_ATTR=Y` y `ALL_CONTAINERS=Y`. Se iguala con `ALTER USER c##lab4_auditor SET CONTAINER_DATA = ALL CONTAINER = CURRENT;`, además de los permisos de lectura necesarios. Evidencia 10.

**19.** `GRANT READ ANY TABLE ON SCHEMA` evita conceder SELECT individual a cada tabla e incluye las nuevas de ese esquema. Es más mantenible, pero expone también tablas futuras que podrían ser sensibles; sigue sin autorizar escritura ni acceso a otros esquemas. Evidencia 10.

**20.** `COMMON_USER_PREFIX` es `C##` en mi instancia. Crear `LAB4_LOCAL` desde la raíz dio `ORA-65096`; en una PDB, intentar crear el común `C##LAB4_COMUN` dio `ORA-65094`. Evidencia 10.


### Archivos

**21.** Son base: datafiles, control files y online redo logs; tempfiles pertenecen a la estructura operativa, pero no se respaldan porque se pueden recrear. Relacionados: SPFILE, password file y ADR/alert log. El password file se ve en `$ORACLE_HOME/dbs/orapwFREE` y en mi imagen está enlazado al volumen; permite autenticación administrativa remota. Evidencia 11.

**22.** 100 MiB son 104.857.600 bytes; el archivo físico mide 104.865.792: hay exactamente 8.192 bytes adicionales, un bloque. `V$DATAFILE.BYTES` refleja el espacio de datos lógico, mientras el fichero incluye la cabecera del datafile. Evidencia 11.

**23.** Los dos control files están en la misma carpeta/volumen, y cada grupo de redo tiene un solo miembro. Si falla el almacenamiento subyacente, la multiplicación de nombres no protege frente al mismo fallo; conviene multiplexar en destinos realmente independientes. Evidencia 11.

**24.** `diagnostic_dest=/opt/oracle` está fuera del volumen. Al recrear el contenedor se pierde el alert log y las trazas previas: la base puede seguir intacta, pero se pierde historial para investigar incidentes. Conviene persistir ADR o centralizar logs. Evidencia 11.


### Bloque y fila

**25.** ROWID `AAAR2vAAAAAAAMLAAF`: `DATA_OBJECT_ID=73135` corresponde a `ADMIN_ACADEMIA.ACA_ESTUDIANTES`; archivo absoluto 16 (`academia01.dbf`), bloque 779 y ranura 5. Se verificó con `DBMS_ROWID` especificando `BIGFILE` y `ROWID_TO_ABSOLUTE_FNO`. Evidencia 12.

**26.** `nrow=90` filas en el bloque, `fsbo=0xC6=198` comienza el espacio libre, `fseo=0x427=1063` termina ese espacio y `avsp=0x361=865` bytes disponibles. En efecto, 1063−198=865. Evidencia 12.

**27.** La ITL con `Flag=--U-` representa una transacción confirmada; `Lck=90` señala que las 90 filas conservan marca de aquella transacción. Oracle no limpia todas las cabeceras al hacer COMMIT; lo comprueba y limpia más tarde al acceder/modificar el bloque (delayed block cleanout). Evidencia 12.

**28.** Fila 101: 3 bytes de cabecera (`fb`, `lb`, `cc`) + 7 bytes de longitud (una por columna) + 68 bytes de datos = **78 bytes**. En el directorio del bloque añade 2 bytes de puntero, es decir 80 por fila físicamente. Evidencia 12.


### Capacidad y coste

**29.** Con B=8192, H=96, PCTFREE=10 % y R=76: bfr=floor((8192−96)×0,9/76)=95 filas/bloque, b=ceil(20000/95)=211 bloques. Afinando Oracle (H=122 y 2 bytes/directorio), bfr=93 y b=216. El valor real de DBA_TABLES es 244 bloques por variación de tamaños, huecos y reservas; 256 bloques asignados al segmento. Evidencias 12 y 13.

**30.** Mis mediciones del apartado 13 fueron: `5a. L??GICA    : 400000 lecturas l??gicas (4 por b??squeda) en 980 ms de CPU -> 2.45 ??s por lectura l??gica` / `5b. ALEATORIA : 5464 lecturas f??sicas de 1 bloque (??ndice + tabla) en 51.8 ms -> lat = 9.5 ??s por lectura f??sica` / `5c. SECUENCIAL: 4595 bloques en 53 peticiones (36 multibloque, ~87 bloques/petici??n) en 25 ms -> Bw = 1421 MB/s`. La lógica se obtiene de memoria, la física aleatoria añade la localización del bloque, y la secuencial amortiza el coste al traer muchos bloques por petición.

**31.** Con HDD (150 MiB/s, latencia 5 ms), leer 8192 bytes secuencialmente cuesta 52,1 µs/bloque, frente a 5000 µs/bloque aleatorio: cociente ≈ 0,0104. Con el bfr=86 registrado en 13, umbral k/r < 0,0104/86 ≈ 0.0121 %.

**32.** Porque `FLUSH BUFFER_CACHE` vacía los buffers de Oracle, no la page cache de Linux: una lectura física de Oracle puede satisfacerse con RAM del sistema anfitrión. Los microsegundos no invalidan el método; los resultados no deben extrapolarse a un HDD real. Evidencia 13.


### Filas migradas y encadenadas

**33.** Migración: un UPDATE aumenta una fila que originalmente cabía, Oracle la mueve y deja un puntero en el bloque original; se detecta con CHAIN_CNT/LIST CHAINED ROWS y se corrige con MOVE y PCTFREE adecuado. Encadenamiento: una fila no cabe entera en un bloque (p. ej., 12.000 bytes en bloques de 8 KB); se divide en piezas y MOVE no elimina esa necesidad. Evidencia 14.

**34.** De cada 1.000 accesos, 800 normales necesitan 3 lecturas lógicas y 200 migrados 4: (800×3 + 200×4)/1000 = **3,2**; es alrededor de un 6,7 % más que 3. Evidencia 14.

**35.** `ALTER TABLE ... MOVE` reconstruye las filas con nuevos ROWID físicos; los índices que guardan los antiguos punteros quedan `UNUSABLE`. Hay que `ALTER INDEX ... REBUILD` y verificar su estado, o planificar `MOVE ONLINE` si se admite y conviene. Evidencia 14.


### Autopsia y operación

**36.** Tres hallazgos: (1) FRA no configurada pese a ARCHIVELOG: supervisar destino de archivados y configurar FRA (alta); (2) ambos control files están en el mismo volumen y redo sin multiplexar: separación de almacenamiento (alta); (3) ADR fuera del volumen: historial de errores se pierde al recrear contenedor, persistirlo/centralizarlo (media). Evidencias 11 y 15.

**37.** `C##OPS_RO` sigue el principio de mínimo privilegio: consulta vistas del catálogo y el alert log con un GRANT concreto. `SYSTEM` posee capacidad administrativa excesiva. La cuenta de observación no debe hacer UPDATE, DROP, ALTER SYSTEM ni administrar usuarios. Evidencias 02, 10 y 11.

**38.** Se corrigieron dos vías: contraseñas de los propietarios de esquema escritas en V000 (invalidación por V003 `NO AUTHENTICATION`) y contraseña SYS en la línea de comandos `sys/clave` del anterior runner (sustituido por autenticación del sistema operativo como SYSDBA). Evidencias 04 y `08-aplicar-migraciones.sh`.

## 2. Preguntas tipo examen (P1–P46)

Una letra (o varias, según indique la pregunta), con justificación breve y sección de evidencia.

- **P1: A, D.** El cierre IMMEDIATE produce copia consistente restaurable directamente; no exige RMAN ni ARCHIVELOG (A).
- **P2: B.** OFFLINE, copia de archivo, RENAME y ONLINE permite el traslado controlado (C).
- **P3: A, C.** El STARTUP_TIME corresponde a la instancia; CREATED es fecha de la base (E).
- **P4: A, C.** En NOMOUNT ya hay parámetros y procesos, pero el control file todavía no está montado (F).
- **P5: B.** La transición ARCHIVELOG se hace con la base montada y no abierta (F).
- **P6: B.** Con SPFILE y un parámetro dinámico el alcance por defecto es BOTH (F).
- **P7: C.** PROCESSES no es configurable desde la PDB; ORA-65040 (F).
- **P8: A, C.** Se puede arrancar con PFILE bueno y regenerar luego el SPFILE (F).
- **P9: B.** ASMM reparte SGA sin bajar del DB_CACHE_SIZE mínimo fijado (G).
- **P10: A, D.** Sort area y estado de sesión dedicado usan PGA, no SGA (G).
- **P11: C.** LGWR confirma persistencia del redo antes de completar COMMIT (H).
- **P12: B, D.** PMON y SMON son procesos básicos de la instancia (H).
- **P13: B.** Desde una PDB V$DATAFILE filtra al CON_ID local (I).
- **P14: B.** CONTAINER_DATA=ALL habilita visibilidad transversal desde la raíz (I).
- **P15: A, D.** El privilegio a nivel de esquema abarca tablas futuras de ese esquema, no otras (I).
- **P16: B, D.** Control files y online redo son archivos propios de la base de datos (J).
- **P17: C.** En el escenario sin archivado y sin otras copias independientes se pierde trabajo desde el último backup (J).
- **P18: B.** DBMS_ROWID usa distribución de bits BIGFILE si se especifica (K).
- **P19: A, B.** PCTFREE reserva espacio para updates y limita nuevas inserciones (K).
- **P20: B.** bfr=floor((8192−96)×0,9/180)=40; 2.000.000/40=50.000 bloques (L).
- **P21: B.** db file scattered read indica lectura multibloque hacia el buffer cache (L).
- **P22: A, C.** Identificar con LIST CHAINED ROWS y reorganizar con espacio libre suficiente (M).
- **P23: B.** 12.000 bytes exceden el tamaño de un bloque de 8 KB: chaining inevitable (M).
- **P24: B.** Cuenta común de lectura y GRANT puntual para leer el alert log (N).
- **P25: B.** PDB$SEED sirve como plantilla de solo lectura (I).
- **P26: C.** C## está reservado a usuarios comunes creados desde raíz; en PDB ORA-65094 (I).
- **P27: B.** Primero cerrar la PDB y luego DROP ... INCLUDING DATAFILES (I).
- **P28: A, C.** V$DATAFILE y V$LOG consultan información de control files ya montados (E/I).
- **P29: A.** Las tablas X$KCC reflejan estructura del control file (I).
- **P30: B.** En una PDB las vistas CDB_ devuelven solo su contenedor (I).
- **P31: B.** Los tempfiles se recrean, no se respaldan como datafiles (J).
- **P32: B.** La instancia opera con parámetros ya cargados; SPFILE puede recrearse desde memoria (F/J).
- **P33: B.** V$PWFILE_USERS informa privilegios administrativos del password file (J).
- **P34: A, B.** ITL y directorio de filas aparecen en el bloque real (K).
- **P35: B.** AUTOALLOCATE comienza con extensiones de 64 KB, pasando después a 1 MB (K).
- **P36: B.** ASSM usa mapas de bits para el espacio libre de bloques (K).
- **P37: B.** En este entorno Oracle 23ai/26ai crea BIGFILE local por defecto (K).
- **P38: A.** Con 0 lecturas físicas los bloques consultados se sirvieron desde caché (L).
- **P39: A, B.** PCTFREE mayor o filas más grandes reducen las filas útiles por bloque (L).
- **P40: B.** FLUSH BUFFER_CACHE afecta a todas las sesiones y causa lecturas físicas iniciales (G/L).
- **P41: B.** La migrada creció tras INSERT; la encadenada necesita varios bloques (M).
- **P42: A.** Tras MOVE hay que reconstruir índices no utilizables (M).
- **P43: A.** V$DIAG_ALERT_EXT permite consultar el alert log desde SQL (J/N).
- **P44: A, B.** Hay que ampliar capacidad o investigar segmentos crecientes (N).
- **P45: A, B.** PDB comparten SGA, procesos de instancia y online redo (E/I).
- **P46: B.** Un usuario local CREATE SESSION no puede cambiar a CDB$ROOT (I).

## Archivos de evidencia consultados

- `docs/bitacora/lab4/evidencia/script/` — respaldos, diagnósticos y ejercicios 00–16.
- `docs/bitacora/lab4/evidencia/spool/` — consultas SQL y V002/V003.
- `docs/bitacora/lab4/evidencia/config/` — PFILE y volcado del bloque 779.

*Este texto se ha generado a partir de los resultados aportados y de los registros disponibles en este repositorio. Revisar siempre los apartados de valores experimentales antes de la entrega.*
