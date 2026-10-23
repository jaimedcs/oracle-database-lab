# Laboratorio 5 · Respuestas y retrospectiva de recuperación

**Repositorio:** `oracle-database-lab` · **Issue:** #9 · **Rama:** `chore/9-oracle-dba-workflow-ii`

> Cifras de los registros de evidencia del propio laboratorio. Las referencias `archivo:línea` se extraen de los logs existentes. Los valores del documento del profesor se utilizan solo como teoría, nunca como mediciones personales.

## 1. Preguntas de comprobación (1–22)

### 1. ¿Qué demuestra comparar el paso 6 de las copias lab4-final y lab3-final?

En el backup del Lab 3 había cinco datafiles de negocio fuera de la ruta estándar del volumen; en el del Lab 4 el paso 6 informa **'ninguno: el volumen contiene toda la base de datos'**. La reubicación de datafiles del Lab 4 dejó la copia fría autocontenida, sin dependencias externas al volumen.

**Evidencia propia:** `20261023T094801Z_00-backup-lab4.script.log:64` — `== 6. Archivos fuera del volumen ==`  
`20261023T094801Z_00-backup-lab4.script.log:65` — `ninguno: el volumen contiene toda la base de datos`

### 2. Calcula el bfr de CLIENTE y PEDIDO y explica la diferencia.

En mi banco, CLIENTE tiene 100,000 filas en 1,517 bloques, longitud media 102 bytes y `bfr ≈ 100000/1517 ≈ 66`. PEDIDO tiene 1,000,000 filas en 5,320 bloques, longitud media 32 bytes y `bfr ≈ 188`. PEDIDO almacena 2.85 veces más filas por bloque porque sus filas son mucho más cortas. El `bfr` es el cociente real entre filas y bloques, no una capacidad teórica fija.

**Evidencia propia:** `20261023T095350Z_01-perfil-tiendasur.script.log:6` — `CLIENTE      100000       1517        102         66       11.9 23-OCT-26`  
`20261023T095350Z_01-perfil-tiendasur.script.log:7` — `PEDIDO      1000000       5320         32        188       41.6 23-OCT-26`

### 3. ¿Por qué la herramienta de medida ejecuta dos veces?

La primera ejecución incluye análisis SQL y calienta la caché; medirla mezclaría trabajo de inicialización con ejecución normal. La segunda ronda mide lecturas lógicas y físicas con un entorno más estable. Lo comprobé en `LAB_TOOLS.MEDIR`, donde la consulta por PK devolvió una fila con 4 lecturas lógicas y 0 físicas en la prueba inicial.

**Evidencia propia:** `20261023T095351Z_01-herramienta-medir.script.log:33` — `prueba_pk		       filas=	   1  lecturas l??gicas=      4  f??sicas=    0       .2 ms`  
`20261023T095351Z_01-herramienta-medir.script.log:34` — `plan: TABLE ACCESS BY INDEX ROWID PEDIDO > INDEX UNIQUE SCAN PK_PEDIDO`

### 4. Altura, hojas y fan-out de IX_PED_CLIENTE; proyección a 1.000 millones.

La altura es `BLEVEL+1`; el factor de ramificación es (hojas + ramas − 1) / ramas. En mi índice **IX_PED_CLIENTE**, la altura medida es **3** y el fan-out real es **consultar evidencia 02**; el script proyecta **altura 4** con 1.000 millones de filas. El aumento es logarítmico porque cada bloque de rama apunta a muchos hijos, no lineal con el número de filas.

**Evidencia propia:** `20261023T095612Z_02-anatomia-indice.script.log:9` — `PEDIDO   IX_PED_CLIENTE     NONUNIQUE          3       2216     100816    1000000     999041          5320`  
`20261023T095612Z_02-anatomia-indice.script.log:19` — `IX_PED_CLIENTE              3       1000000       2216          2215          6              15.9              7996         90          0`  
`20261023T095612Z_02-anatomia-indice.script.log:23` — `Altura comprobada: 1 + ceil(log_fo(hojas)) = 1 + ceil(log_543(2216)) = 3   (INDEX_STATS dice 3)`  
`20261023T095612Z_02-anatomia-indice.script.log:26` — `Con   1,000,000,000 filas ->   2208969 hojas -> altura 4 -> 5 lecturas para encontrar UNA fila (altura + tabla)`

### 5. Descomposición de una entrada de ROWID en PK_CLIENTE y bigfile.

Una entrada de hoja guarda clave y ROWID. En un índice `BIGFILE` el ROWID del bloque se representa con cuatro bytes y la ranura con dos; el número de archivo no aparece en cada entrada porque el tablespace bigfile solo tiene un datafile. En el volcado de `PK_CLIENTE` la clave del cliente 1 se liga al bloque/ranura mostrados por `DBMS_ROWID.ROWID_BLOCK_NUMBER` y `ROWID_ROW_NUMBER`.

**Evidencia propia:** `20261023T095612Z_02-anatomia-indice.script.log:4` — `TABLE_NA INDEX_NAME         UNICO         ALTURA      HOJAS     CLAVES   ENTRADAS         CF BLOQUES_TABLA`  
`20261023T095612Z_02-anatomia-indice.script.log:7` — `CLIENTE  PK_CLIENTE         UNIQUE             2        187     100000     100000       1477          1517`  
`20261023T095612Z_02-anatomia-indice.script.log:35` — `(primera ejecución descartada: puede incluir trabajo único, como limpiar el bloque. Se mide la segunda, en caliente)`  
`20261023T095612Z_02-anatomia-indice.script.log:63` — `(Buffers = lecturas lógicas: altura del índice (3) + 1 bloque de tabla = 4. Es la cuenta de la Unidad 3, hecha por Oracle)`  
`20261023T095612Z_02-anatomia-indice.script.log:76` — `===== 4. Raíz, rama y hoja: volcado real de los bloques de PK_CLIENTE =====`

### 6. Tres comparaciones de tipos de índice con lecturas medidas.

Comparé tres pares medidos: **Q13** sin/con índice único en DNI; **Q7** con índice por cliente frente a índice compuesto/cubriente; y **Q14** sin/con cuatro bitmap en análisis histórico. El único evita recorrer toda CLIENTE; el cubriente ahorra el salto a la tabla y el ordenamiento; el bitmap combina filtros de baja cardinalidad, adecuado para almacenes con pocas escrituras.

**Evidencia propia:** `20261023T095614Z_03-tipos-indice.script.log:6` — `Q13 sin ??ndice                filas=      1  lecturas l??gicas=   1486  f??sicas=    0      3.9 ms`  
`20261023T095614Z_03-tipos-indice.script.log:8` — `Q13 con UNIQUE (dni)           filas=      1  lecturas l??gicas=      3  f??sicas=    0       .2 ms`  
`20261023T095614Z_03-tipos-indice.script.log:28` — `Q7 con ix_ped_cliente          filas=      4  lecturas l??gicas=     15  f??sicas=    0       .3 ms`  
`20261023T095614Z_03-tipos-indice.script.log:30` — `Q7 (id_cliente, fecha)         filas=      4  lecturas l??gicas=      7  f??sicas=    0       .1 ms`  
`20261023T095614Z_03-tipos-indice.script.log:32` — `Q7 cubriente                   filas=      4  lecturas l??gicas=      3  f??sicas=    0       .3 ms`  
`20261023T095614Z_03-tipos-indice.script.log:58` — `Q14 sin bitmaps                filas=      1  lecturas l??gicas=   4073  f??sicas=    0     23.2 ms`  
`20261023T095614Z_03-tipos-indice.script.log:60` — `Q14 con 4 bitmaps              filas=      1  lecturas l??gicas=    528  f??sicas=    0      2.4 ms`

### 7. ¿Por qué IX_PED_FECHA tiene buen CF e IX_PED_CLIENTE malo? ¿REBUILD?

`IX_PED_FECHA` tiene clustering factor (CF) cercano a los ~5.320 bloques porque fecha y ubicación física están correlacionadas. `IX_PED_CLIENTE` tiene CF cercano al millón de filas porque los clientes se distribuyeron al azar. **REBUILD no corrige el CF**: ordena el índice pero no mueve ni reordena las filas de la tabla.

**Evidencia propia:** `20261023T095711Z_04-agrupamiento.script.log:7` — `IX_PED_FECHA           5220          5320     1000000 BUENO: filas vecinas en el ??ndice, vecinas en disco`  
`20261023T095711Z_04-agrupamiento.script.log:9` — `IX_PED_CLIENTE       999041          5320     1000000 MALO: casi cada entrada salta a otro bloque`  
`20261023T095711Z_04-agrupamiento.script.log:15` — `IX_PED_FECHA             5220`  
`20261023T095711Z_04-agrupamiento.script.log:16` — `IX_PED_CLIENTE         999041`

### 8. Punto de equilibrio de cada índice y fórmula teórica.

En la curva medí los accesos por índice con CF bueno, CF malo y FULL TABLE SCAN para distintos porcentajes `k`. El **primer porcentaje probado** donde el índice con CF malo supera en lecturas al FULL es **1.0 %**; para el CF bueno es **100.0 %** (según las filas muestreadas). Para PEDIDO (`bfr≈188`), la fórmula aproximada del umbral en lecturas lógicas con CF malo es `1/188≈0,53 %`; suponiendo lectura aleatoria 5 veces más cara, `≈0,11 %`. El coste del optimizador puede elegir FULL antes de que las lecturas lógicas del índice superen las del recorrido completo. El índice de fecha tolera un porcentaje muy superior por su CF favorable.

**Evidencia propia:** `20261023T095711Z_04-agrupamiento.script.log:20` — `b = 5320 bloques, r = 1000000 filas, bfr = 188`  
`20261023T095711Z_04-agrupamiento.script.log:27` — `1 %         10000                80             9920           5232   recorrido completo   <- el ??ndice malo ya lee m??s que la tabla`  
`20261023T095711Z_04-agrupamiento.script.log:29` — `5 %         50000               395            50041           5232   recorrido completo   <- el ??ndice malo ya lee m??s que la tabla`  
`20261023T095711Z_04-agrupamiento.script.log:30` — `10 %       100000               789           100167           5232   recorrido completo   <- el ??ndice malo ya lee m??s que la tabla`  
`20261023T095711Z_04-agrupamiento.script.log:32` — `50 %       500000              3938           500374           5232   recorrido completo   <- el ??ndice malo ya lee m??s que la tabla`  
`20261023T095711Z_04-agrupamiento.script.log:33` — `100 %     1000000              7875          1001259           5232   recorrido completo   <- hasta el ??ndice bueno pierde`  
`20261023T095711Z_04-agrupamiento.script.log:37` — `En disco, con c_sec/c_aleat = 1/5:      k/r < .11 %   (la lectura aleatoria es la cara)`

### 9. ¿Por qué Q4b (Gonz%) usa índice y lee más que un FULL SCAN?

`LIKE 'Gonz%'` sí es sargable porque busca un prefijo del índice, pero la consulta usa `SELECT *`: debe visitar muchos bloques de tabla por ROWID. Como los apellidos están físicamente dispersos y el porcentaje de clientes encontrados supera el punto de equilibrio, el total de lecturas puede ser peor que un FULL TABLE SCAN; usar un índice no garantiza ahorrar E/S.

**Evidencia propia:** `20261023T095729Z_05-sargabilidad.script.log:36` — `Q4a LIKE %ez                   filas=  18902  lecturas l??gicas=   1523  f??sicas=    0     24.6 ms`  
`20261023T095729Z_05-sargabilidad.script.log:38` — `Q4b LIKE Gonz%                 filas=   2056  lecturas l??gicas=   2024  f??sicas=    0        6 ms`

### 10. Coste de INSERT con 4, 9 y 5 índices; índices rechazados.

Medí 2.000 INSERT por escenario (**4 índices de partida**, **9 con la propuesta**, **5 tras V005**); costes obtenidos: **hoy: 10.2 bloques/fila; v005: 12.1 bloques/fila**. Cada índice nuevo suele sumar visitas a la hoja y modificaciones/undo. Rechacé índices sin selectividad ni uso suficiente (estado genérico, canal e importe), así como los cubiertos por prefijos de otros. Conservé índices con efecto medido en consultas concretas (`IX_PED_CP`, `IX_PED_CLI_FEC_CUB`, `IX_PED_PENDIENTES`) y los imprescindibles para integridad.

**Evidencia propia:** `20261023T095907Z_06-indices.script.log:2` — `===== Escenario: hoy =====`  
`20261023T095907Z_06-indices.script.log:4` — `INDICES_EN_PEDIDO INDICES`  
`20261023T095907Z_06-indices.script.log:7` — `hoy: 2000 INSERT               filas=  2000  lecturas l??gicas=  30608  bloques modificados= 20338  redo=  2589 KB    80.4 ms  | por fila: 10.2 bloques, 1325 bytes de redo`  
`20261023T095907Z_06-indices.script.log:13` — `===== Escenario: compañero =====`  
`20261023T095907Z_06-indices.script.log:15` — `INDICES_EN_PEDIDO INDICES`  
`20261023T095907Z_06-indices.script.log:20` — `compa??ero: 2000 INSERT        filas=  2000  lecturas l??gicas=  60706  bloques modificados= 40440  redo=  5073 KB   120.1 ms  | por fila: 20.2 bloques, 2598 bytes de redo`  
`20261023T095907Z_06-indices.script.log:135` — `===== Escenario: V005 =====`  
`20261023T095907Z_06-indices.script.log:137` — `INDICES_EN_PEDIDO INDICES`  
`20261023T095907Z_06-indices.script.log:140` — `V005: 2000 INSERT              filas=  2000  lecturas l??gicas=  34385  bloques modificados= 24213  redo=  3144 KB    86.3 ms  | por fila: 12.1 bloques, 1610 bytes de redo`

### 11. Divisiones 50/50, 90/10 y patrón cola en los gráficos.

En **AZAR**, las divisiones habituales 50/50 dejan hojas con ocupación intermedia; en **CRECIENTE**, el crecimiento por el extremo derecho produce más divisiones 90/10, con hojas antiguas muy llenas; `REVERSE` reparte la carga. El **patrón cola** es distinto: las hojas izquierdas quedan vacías por borrados y las derechas reciben nuevas entradas. Los gráficos y sus mediciones distinguen estas distribuciones.

**Evidencia propia:** `20261023T095924Z_07a-crecimiento.script.log:3` — `AZAR (claves aleatorias)           divisiones de hoja =   595   de ellas 90/10 =     0`  
`20261023T095924Z_07a-crecimiento.script.log:4` — `CRECIENTE (secuencia, fecha...)    divisiones de hoja =   398   de ellas 90/10 =   398`  
`20261023T095924Z_07a-crecimiento.script.log:5` — `CRECIENTE con ??ndice REVERSE      divisiones de hoja =   511   de ellas 90/10 =     0`

**Evidencia propia:** `20261023T095924Z_07b-patron-cola.script.log:4` — `MENSAJES_VIVOS    PRIMERO     ULTIMO`  
`20261023T095924Z_07b-patron-cola.script.log:6` — `100000     150001     250000`  
`20261023T095924Z_07b-patron-cola.script.log:10` — `plan: COUNT STOPKEY > VIEW > INDEX FULL SCAN IX_COLA`  
`20261023T095924Z_07b-patron-cola.script.log:19` — `IX_COLA             2        418     167867      67867           40         81        3.2`

### 12. ¿Qué remedio elegir en producción para el patrón cola?

En producción empezaría por `ALTER INDEX ... COALESCE`, con medición antes y después, porque compacta hojas aprovechables en línea sin reconstruir todo el índice. Si interesa devolver espacio al tablespace, `SHRINK SPACE`; `REBUILD ONLINE` solo con causa demostrada, pues cuesta más espacio y redo. La solución estructural para una cola es particionar por fecha y retirar particiones enteras.

**Evidencia propia:** `20261023T095924Z_07c-remedios.script.log:6` — `0. cola degradada                         418      67867           4                        219`  
`20261023T095924Z_07c-remedios.script.log:7` — `1. tras COALESCE                          201          0           4                          2`  
`20261023T095924Z_07c-remedios.script.log:8` — `2. tras SHRINK SPACE                      201          0        1.69                          2`  
`20261023T095924Z_07c-remedios.script.log:9` — `3. tras REBUILD ONLINE                    223          0           2                          2`  
`20261023T095924Z_07c-remedios.script.log:12` — `COALESCE        fusiona hojas vecinas medio vacías dentro del índice. En línea, sin bloqueo. NO devuelve espacio al tablespace.`  
`20261023T095924Z_07c-remedios.script.log:13` — `SHRINK SPACE    COALESCE + devuelve los bloques sobrantes al tablespace (baja la marca de agua). En línea.`

### 13. SCN comparados por Oracle al abrir un datafile.

Oracle compara el SCN de checkpoint registrado en el **control file** para el datafile con el SCN de la **cabecera** del propio datafile. Si difieren, puede necesitar recuperación para ponerlo al día antes de abrir. Un `ALTER SYSTEM CHECKPOINT` sincroniza las referencias.

**Evidencia propia:** `20261023T100253Z_08-scn-checkpoint.script.log:14` — `CKPT_EN_CONTROL_FILE`  
`20261023T100253Z_08-scn-checkpoint.script.log:18` — `FILE#     CON_ID ARCHIVO	       CKPT_CONTROL_FILE CKPT_CABECERA ESTADO`  
`20261023T100253Z_08-scn-checkpoint.script.log:20` — `1	    1 system01.dbf		 4248884       4248884 sincronizado`  
`20261023T100253Z_08-scn-checkpoint.script.log:21` — `2	    2 system01.dbf		 2098101       2098101 sincronizado`  
`20261023T100253Z_08-scn-checkpoint.script.log:22` — `3	    1 sysaux01.dbf		 4248884       4248884 sincronizado`  
`20261023T100253Z_08-scn-checkpoint.script.log:23` — `4	    2 sysaux01.dbf		 2098101       2098101 sincronizado`  
`20261023T100253Z_08-scn-checkpoint.script.log:24` — `16	    3 academia01.dbf		 4248884       4248884 sincronizado`

### 14. ¿Qué protege y qué no la multiplexación en el mismo volumen?

Tres `controlXX.ctl` protegen frente a la pérdida/corrupción **aislada** de un archivo: el simulacro B restauró la tercera copia desde otra sana. Pero las tres en el **mismo volumen** no protegen del fallo del volumen entero. En producción se multiplexan en discos o grupos de almacenamiento independientes y se conserva backup RMAN del control file.

**Evidencia propia:** `20261023T100307Z_09-multiplexar.script.log:1` — `control_files actual: /opt/oracle/oradata/FREE/control01.ctl, /opt/oracle/oradata/FREE/control02.ctl`  
`20261023T100307Z_09-multiplexar.script.log:11` — `-rw-r----- 1 oracle oinstall   18792448 Oct 23 10:03 control01.ctl`  
`20261023T100307Z_09-multiplexar.script.log:12` — `-rw-r----- 1 oracle oinstall   18792448 Oct 23 10:03 control02.ctl`  
`20261023T100307Z_09-multiplexar.script.log:13` — `-rw-r----- 1 oracle oinstall   18792448 Oct 23 10:03 control03.ctl`

### 15. Estados CURRENT/ACTIVE/INACTIVE y rechazos de borrado.

**CURRENT** es el grupo al que LGWR escribe; **ACTIVE** ya no recibe escritura nueva, pero aún puede ser necesario para recuperación; **INACTIVE** ya no es necesario para recuperación de instancia. El script demuestra que Oracle rechaza borrar el CURRENT, un grupo ACTIVE/no archivado y el grupo cuya eliminación dejaría una cantidad insuficiente de grupos; protege los datos y la continuidad del redo.

**Evidencia propia:** `20261023T100318Z_10-redo.script.log:6` — `1	    1	      13	200	     1 YES	ACTIVE		 4254130`  
`20261023T100318Z_10-redo.script.log:7` — `2	    1	      14	200	     1 YES	ACTIVE		 4259397`  
`20261023T100318Z_10-redo.script.log:8` — `3	    1	      15	200	     1 NO	CURRENT 	 4260026`  
`20261023T100318Z_10-redo.script.log:31` — `===== 3. Cambio de log (log switch): el grupo CURRENT pasa al siguiente, en círculo =====`  
`20261023T100318Z_10-redo.script.log:35` — `1	   16 CURRENT`  
`20261023T100318Z_10-redo.script.log:36` — `2	   14 ACTIVE`  
`20261023T100318Z_10-redo.script.log:37` — `3	   15 ACTIVE`  
`20261023T100318Z_10-redo.script.log:41` — `1	   16 ACTIVE`  
`20261023T100318Z_10-redo.script.log:42` — `2	   17 CURRENT`  
`20261023T100318Z_10-redo.script.log:43` — `3	   15 ACTIVE`

### 16. Cadena causal de la FRA llena.

Al reducir la FRA a 2 MB el espacio se agota; `ORA-19815` avisa, `ORA-19809` indica límite excedido y ARCn no puede archivar (`ORA-16038`). LGWR no puede reutilizar un grupo sin archivar, aparecen esperas `log file switch (archiving needed)` y pueden rechazarse conexiones (`ORA-00257`). En la prueba restauré el límite a 4 GB; no borré archivos mediante `rm`.

**Evidencia propia:** `20261023T100517Z_11-fra-llena.script.log:6` — `/opt/oracle/oradata/fra 	     4096	14.4`  
`20261023T100517Z_11-fra-llena.script.log:14` — `ORA-16038: log 2 sequence# 17 cannot be archived`  
`20261023T100517Z_11-fra-llena.script.log:15` — `ORA-19809: limit exceeded for recovery files`  
`20261023T100517Z_11-fra-llena.script.log:18` — `Help: https://docs.oracle.com/error-help/db/ora-16038/`  
`20261023T100517Z_11-fra-llena.script.log:32` — `10:05:17 ORA-19815: WARNING: db_recovery_file_dest_size of 2097152 bytes is 100.00% used, and has 0 remaining`  
`20261023T100517Z_11-fra-llena.script.log:33` — `10:05:18 ORA-19809: limit exceeded for recovery files`  
`20261023T100517Z_11-fra-llena.script.log:45` — `/opt/oracle/oradata/fra 	     4096	16.3`

### 17. Lectores/escritores: experimento de dos sesiones.

La sesión A cambió la fila 101 sin confirmar. B leyó el valor **ACTIVO** anterior reconstruido con UNDO, aunque A tenía el bloque modificado. B pudo leer sin esperar, pero un `FOR UPDATE WAIT 3` sobre la misma fila falló por bloqueo (`ORA-00054`): dos escritores sí compiten. Tras el COMMIT de A, B vio `EGRESADO`; después restauramos `ACTIVO` mediante flashback.

**Evidencia propia:** `20261023T100518Z_12-lectura-consistente.script.log:3` — `[B] 1. ¿Qué ve B? El valor CONFIRMADO, reconstruido con el undo (lectura consistente)`  
`20261023T100518Z_12-lectura-consistente.script.log:7` — `101 ACTIVO`  
`20261023T100518Z_12-lectura-consistente.script.log:22` — `[B] 4. B intenta bloquear la misma fila: esperar como mucho 3 s (error esperado: ORA-00054, fila bloqueada por A)`  
`20261023T100518Z_12-lectura-consistente.script.log:26` — `ORA-00054: Failed to acquire a lock (Type: "TX", Name: "Transaction", Description: "Lock held by a transaction to allow other transactions to wait for it")`  
`20261023T100518Z_12-lectura-consistente.script.log:29` — `Help: https://docs.oracle.com/error-help/db/ora-00054/`  
`20261023T100518Z_12-lectura-consistente.script.log:37` — `101 EGRESADO`  
`20261023T100518Z_12-lectura-consistente.script.log:43` — `101 ACTIVO`  
`20261023T100518Z_12-lectura-consistente.script.log:49` — `101 ACTIVO`

### 18. UNDO de DELETE, INSERT y redo del ROLLBACK.

Un `INSERT` requiere undo para deshacer la incorporación de la fila; un `DELETE` debe guardar suficiente información de la fila e índices para reconstruir lo eliminado, por eso genera más undo. El undo vive en bloques que también podrían perderse en una caída; sus cambios generan redo para poder rehacer el undo antes de deshacer. `ROLLBACK` también modifica bloques y vuelve a generar redo.

**Evidencia propia:** `20261023T100549Z_12-undo-y-redo.script.log:3` — `INSERT 10 000 filas    bloques de undo =   141 (  1128 KB) | redo total =   4803 KB, del cual describe el undo =   2023 KB`  
`20261023T100549Z_12-undo-y-redo.script.log:4` — `y su ROLLBACK       redo generado al deshacer = 356 KB`  
`20261023T100549Z_12-undo-y-redo.script.log:5` — `UPDATE 10 000 filas    bloques de undo =    72 (   576 KB) | redo total =   1258 KB, del cual describe el undo =    540 KB`  
`20261023T100549Z_12-undo-y-redo.script.log:6` — `y su ROLLBACK       redo generado al deshacer = 751 KB`  
`20261023T100549Z_12-undo-y-redo.script.log:7` — `DELETE 10 000 filas    bloques de undo =   427 (  3416 KB) | redo total =   6627 KB, del cual describe el undo =   3267 KB`  
`20261023T100549Z_12-undo-y-redo.script.log:8` — `y su ROLLBACK       redo generado al deshacer = 4701 KB`

### 19. LGWR y DBWn: durabilidad después del COMMIT y checkpoint.

En mi ejecución, tras el `UPDATE` + COMMIT se generaron **1.779 KB de redo**, **2 escrituras de LGWR** y quedaron **231 bloques sucios** de la tabla: la durabilidad se garantiza mediante redo confirmado en disco, NO por escribir ya los datafiles. Tras `ALTER SYSTEM CHECKPOINT`, DBWn escribió **346 bloques** de la instancia y quedaron **0 bloques sucios** de esta tabla.

**Evidencia propia:** `20261023T100550Z_13-lgwr-dbwn.script.log:22` — `1. UPDATE 20 000 filas + COMMIT 	 1779		    2	       1	    0		       231`  
`20261023T100550Z_13-lgwr-dbwn.script.log:23` — `2. ALTER SYSTEM CHECKPOINT		    8		    1	       0	  346			 0`

### 20. Simulacro A: roll forward y rollback, filas 102 y 103.

En el simulacro A se confirmó el cambio de la fila 102 a **EGRESADO**, pero se dejó sin confirmar el de la fila 103 a **INACTIVO** antes del `SHUTDOWN ABORT`. Al arrancar, Oracle hizo **roll forward** con el redo confirmado y **roll back** con undo: 102 quedó EGRESADO y 103 ACTIVO. Posteriormente la 102 volvió a ACTIVO para repetir el lab.

**Evidencia propia:** `20261023T101103Z_14a-caida-instancia.script.log:2` — `102 -> EGRESADO (confirmado) · 103 -> INACTIVO (sin confirmar) · y ahora... SHUTDOWN ABORT`  
`20261023T101103Z_14a-caida-instancia.script.log:19` — `102 EGRESADO`  
`20261023T101103Z_14a-caida-instancia.script.log:20` — `103 ACTIVO`  
`20261023T101103Z_14a-caida-instancia.script.log:26` — `[kcv.c:24899] kcvcrv: Beginning crash recovery of 1 threads`  
`20261023T101103Z_14a-caida-instancia.script.log:33` — `Completed crash recovery at`

### 21. Comparación de RTO/RPO entre simulacros C y D.

En el simulacro C se borró la tabla `ACA_MATRICULAS` y se restauró **toda la base** desde un backup frío: el RTO corresponde a descargar y arrancar la copia, y el RPO potencial es la ventana de cambios desde esa copia (el script la imprime). En el simulacro D solo se restauró un datafile con RMAN y se aplicó redo: **RTO 15 s** desde el comienzo de la reparación (**16 s desde el fallo**) y **RPO 0**. D es más rápido porque restaura un archivo, no todo el volumen, y conserva el cambio posterior a la copia.

**Evidencia propia:** `20261023T101310Z_14c-simulacro-restauracion.script.log:53` — `RPO (datos perdidos): todo lo hecho en los 1 s entre la copia y el fallo`  
`20261023T101310Z_14c-simulacro-restauracion.script.log:54` — `RTO (tiempo de restauración): 139 s`

**Evidencia propia:** `20261023T101905Z_14d-perdida-datafile.script.log:66` — `RPO (datos perdidos): 0 (copia + redo archivado + redo en línea)`  
`20261023T101905Z_14d-perdida-datafile.script.log:67` — `RTO (archivo fuera de línea -> en línea): 15 s; desde el fallo: 16 s`

### 22. Clasificación de ORA- del healthcheck diario.

Los errores del bloque 5 del healthcheck deben juzgarse por fecha y origen. `ORA-19809/16038/19815` corresponden al experimento de FRA (L); `ORA-00205/00202/27037`, a la copia del control file (O-B); `ORA-01116/01110/27041/63999/01113`, a la pérdida del datafile (O-D). `ORA-20013` y `ORA-00800`, si aparecen, son diagnósticos conocidos del entorno de laboratorio (Lab 4), no prueba de que siga roto. La verificación 16 y la PDB abierta permiten distinguir huellas del simulacro de incidentes actuales.

**Evidencia propia:** `20261023T102057Z_15-healthcheck.script.log:34` — `10-23 10:19 ORA-01113: file 25 needs media recovery`  
`20261023T102057Z_15-healthcheck.script.log:35` — `10-23 10:19 ORA-01113: file 25 needs media recovery`  
`20261023T102057Z_15-healthcheck.script.log:36` — `10-23 10:19 ORA-01110: data file 16: '/opt/oracle/oradata/FREE/FREEPDB1/academia01.dbf'`  
`20261023T102057Z_15-healthcheck.script.log:37` — `10-23 10:19 ORA-63999: data file suffered media failure`  
`20261023T102057Z_15-healthcheck.script.log:38` — `10-23 10:18 ORA-00800: soft external error, arguments: [Set Priority Failed], [LGWR], [Check traces an`  
`20261023T102057Z_15-healthcheck.script.log:39` — `10-23 10:18 ORA-00800: soft external error, arguments: [Set Priority Failed], [VKTM], [Check traces an`  
`20261023T102057Z_15-healthcheck.script.log:40` — `10-23 10:16 ORA-00800: soft external error, arguments: [Set Priority Failed], [LGWR], [Check traces an`  
`20261023T102057Z_15-healthcheck.script.log:41` — `10-23 10:16 ORA-00800: soft external error, arguments: [Set Priority Failed], [VKTM], [Check traces an`  
`20261023T102057Z_15-healthcheck.script.log:42` — `10-23 10:11 ORA-00202: control file: '/opt/oracle/oradata/FREE/control03.ctl'`  
`20261023T102057Z_15-healthcheck.script.log:69` — `== 9. Undo: errores de "snapshot too old" (ORA-01555) o falta de espacio en las últimas 24 h (0 y 0 = bien) ==`

## 2. Simulacro de examen 1Z0-182 (S1–S26)

En las preguntas con dos opciones se indican ambas letras, como exige el enunciado.

| Pregunta | Respuesta | Justificación breve | Parte |
|---|---|---|---|
| S1 | **B** | El CF próximo al número de filas obliga a visitar casi un bloque por fila. | E |
| S2 | **A y C** | Índice funcional para UPPER(email), o aplicar LOWER al dato para dejar la columna intacta. | D/F |
| S3 | **B** | La conversión implícita TO_NUMBER se aplica a la columna indexada. | F |
| S4 | **B** | Bitmap encaja con baja cardinalidad y cargas por lotes de almacén, no OLTP concurrente. | D |
| S5 | **B** | SKIP SCAN puede recorrer por grupos de la primera columna ausente. | D |
| S6 | **B** | INVISIBLE permite medir sin ese acceso y volver a VISIBLE sin reconstrucción. | G |
| S7 | **A y C** | COALESCE fusiona hojas y SHRINK devuelve espacio; evitan un REBUILD sin ONLINE. | H |
| S8 | **B** | REVERSE reparte claves crecientes pero rompe rangos naturales de la clave. | H |
| S9 | **C** | Cambiar una columna no indexada no obliga a actualizar entradas de esos índices. | G |
| S10 | **B** | Ramificación depende de cuántas claves/referencias caben por bloque de rama. | C |
| S11 | **A y C** | La IOT contiene las filas en su PK; evita otra visita a tabla al buscar por PK. | D |
| S12 | **B** | Se comparan los SCN de checkpoint del control file y de la cabecera física. | I |
| S13 | **C** | CKPT actualiza la información del checkpoint; DBWn escribe los bloques sucios. | I/N |
| S14 | **B y E** | En NOMOUNT existen SGA/procesos y parámetros; los control files aún no están montados. | Lab 4/E |
| S15 | **B** | ARCHIVELOG se activa con base montada tras parada limpia, y luego se abre. | L |
| S16 | **B** | Puede reconstruirse el grupo INACTIVE archivado con CLEAR LOGFILE; no recuperar toda la base. | K |
| S17 | **A y C** | UNDO sirve para lectura consistente y Flashback Query además de ROLLBACK. | M |
| S18 | **B** | Hay que rehacer los bloques de undo tras fallo antes de poder deshacer cambios. | M |
| S19 | **A** | COMMIT garantiza persistencia del redo en el online redo log, no del datafile. | N |
| S20 | **A** | MTTR menor aumenta la frecuencia/trabajo incremental de checkpoints. | I/N |
| S21 | **B** | El archivador no logra archivar (p. ej. FRA al 100%), bloqueando el log switch. | L |
| S22 | **B** | Primero poner fuera de línea el datafile de aplicación para preservar el servicio restante. | O-D |
| S23 | **B** | SYSTEM exige recuperación con la base montada, RESTORE/RECOVER y OPEN. | O-D |
| S24 | **B** | En NOARCHIVELOG no hay redo archivado para recuperar posteriores cambios. | L/O-D |
| S25 | **B y D** | Aumentar retención/capacidad de undo; garantizarla solo si la operación es prioritaria. | M |
| S26 | **A** | V$RECOVERY_AREA_USAGE desglosa el consumo de FRA por tipo de archivo. | L/P |

**Puntuación del cuestionario:** 26 respuestas propuestas; comprobar con el simulacro del PDF antes de entregar.

## 3. Simulacros de fallo: RTO, RPO y retrospectiva

| Simulacro | Incidente | RTO | RPO | Resultado |
|---|---|---|---|---|
| A | `SHUTDOWN ABORT` | Arranque automático; duración exacta no cronometrada en 14A | **0** para cambios confirmados | 102 confirmada sobrevive; 103 no confirmada se revierte |
| B | Control file `control03.ctl` perdido | Reparación con copia sana; duración exacta no cronometrada en 14B | **0** | 3 control files y READ WRITE tras abrir |
| C | `DROP TABLE ... PURGE` | **139 s** | **1 s de ventana potencial**; no hay pérdida observada si no hubo otras escrituras | Se restauran 60.000 matrículas |
| D | Pérdida de `academia01.dbf` | **15 s (archivo); 16 s desde el fallo** | **0** | RMAN restaura el datafile, aplica redo y conserva 20.000 estudiantes |

### Retrospectiva sin culpables (game day)

- **A — caída de instancia.** Sorprendió que la base recuperara automáticamente lo confirmado. Mejoraría la medición automática del RTO y conservaría líneas del alert log con timestamps.
- **B — control file perdido.** El fallo `ORA-00205` se corrigió copiando una réplica sana con la instancia sin montar. Mejoraría la protección colocando los tres archivos en almacenamientos realmente independientes.
- **C — tabla eliminada.** `FLASHBACK TABLE TO BEFORE DROP` es mucho más barato que recuperar la base completa; `PURGE` obliga a otro procedimiento. Mejoraría el runbook incorporando `RMAN RECOVER TABLE` para no revertir tablas ajenas. El RPO indicado por la restauración completa es una ventana potencial, no una pérdida de filas necesariamente observada.
- **D — datafile perdido.** Se restauró únicamente el archivo y se aplicó redo; el valor cambiado *después* del backup sobrevivió (RPO 0). Mejoraría la alerta ante `ORA-63999`, verificando si la PDB permanece abierta o queda MOUNTED antes de restaurar.

### Evidencias de los simulacros

- A: 20261023T101103Z_14a-caida-instancia.script.log
- B: 20261023T101109Z_14b-perdida-controlfile.script.log
- C: 20261023T101310Z_14c-simulacro-restauracion.script.log
- D: 20261023T101905Z_14d-perdida-datafile.script.log

## 4. Comprobación del estado final y seguridad

El apartado 16 registró `RESULTADO: TODO OK. Lab 5 listo para entregar.` Las comprobaciones abarcan banco de pruebas, migración V005, 3 control files, grupos redo con miembros duplicados, ARCHIVELOG, FRA de 4 GiB, recuperación de filas, copia RMAN y evidencias 00–15.

No deben versionarse `backups/`, `config/.env`, ni `.arc`, `.bkp`, `.ctl`, `.dbf`, `.trc` ni contraseñas reales. Este fichero no lee contraseñas. Ejecutar el control de seguridad del PDF antes de hacer `git push`.

**Notas:** Las cifras de los apartados que no puedan extraerse mediante patrones se remiten expresamente al log indicado. El archivo se ha preparado sin reejecutar pruebas destructivas de Oracle.
