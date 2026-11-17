# Laboratorio 6 — Respuestas de comprobación · E019

## 1. Errores ORA- del alert log en las últimas 24 horas

En la lista de turno de la Parte B obtuve **5 registros de error ORA- en las últimas 24 horas**. Al revisar los mensajes del *alert log* aparecieron avisos relacionados con la prioridad de procesos internos (`ORA-00800`, en procesos como `VKTM` y `LGWR`) y fallos de una tarea automática (`ORA-12012` asociado a `ORA-00001`). Más adelante, durante las pruebas del laboratorio, se generaron también errores esperados como `ORA-65019`, al intentar abrir una PDB ya abierta, y `ORA-01536`, al superar una cuota. No atribuyo estos últimos al recuento inicial, porque sucedieron después.

El número de errores no constituye por sí mismo una alarma: hay que contrastar la hora, el origen, la recurrencia y el impacto. En aquella lista de turno había **0 sesiones bloqueadas y 0 alertas pendientes**, aunque el fallo de la tarea automática merecería seguimiento.

**Evidencia:** `docs/bitacora/lab6/evidencia/script/20261117T224547Z_01-turno.script.log` (`ERRORES_ORA_24H=5`, `SESIONES_BLOQUEADAS=0`, `ALERTAS_PENDIENTES=0`) y consulta posterior de `V$DIAG_ALERT_EXT`.

## 2. Ventana de mantenimiento del miércoles

La ventana `WEDNESDAY_WINDOW` comienza a las **22:00** y tiene una duración de **4 horas**; por tanto, termina a las **02:00 del jueves**. En la comprobación figuraban habilitados los tres clientes de mantenimiento automático: `auto optimizer stats collection`, que recoge estadísticas para el optimizador; `auto space advisor`, que examina el aprovechamiento del espacio; y `sql tuning advisor`, que propone mejoras de SQL. Que estén habilitados significa que pueden ejecutarse en la ventana; no asegura que los tres hayan realizado trabajo efectivo esa noche.

**Evidencia:** `docs/bitacora/lab6/evidencia/spool/20261117T224555Z_01-automatizacion.spool.log` (`WEDNESDAY_WINDOW`, `BYHOUR=22`, `HORAS=4`, tres clientes `ENABLED`).

## 3. Diferencia entre V$SPPARAMETER y V$PARAMETER tras SCOPE=SPFILE

El parámetro `db_files` tenía **200** en memoria y no aparecía fijado expresamente en el SPFILE (`ISSPECIFIED=FALSE`). El intento de cambiarlo con `SCOPE=MEMORY` dio `ORA-02095`, porque no se puede modificar dinámicamente. En cambio, `ALTER SYSTEM SET db_files=250 SCOPE=SPFILE` fue aceptado: `V$SPPARAMETER` mostró **250** con `ISSPECIFIED=TRUE`, mientras `V$PARAMETER` seguía indicando **200**. Esto demuestra que el cambio se había guardado para el siguiente arranque, pero todavía no estaba activo. Sin `RESET`, el reinicio habría intentado arrancar con `db_files=250`.

**Evidencia:** `docs/bitacora/lab6/evidencia/script/20261117T225025Z_02-parametros.script.log` (SPFILE: 250; memoria: 200; `ORA-02095`).

## 4. Por qué RESET era correcto para db_files y no para processes

Para `db_files`, `RESET` era la vuelta atrás adecuada porque el parámetro **no estaba fijado expresamente** en el SPFILE inicial. Al eliminar el valor 250 pendiente, volvió a quedar `ISSPECIFIED=FALSE`, por lo que Oracle conservaría su comportamiento predeterminado; el valor efectivo de esta instancia era **200**. Para `processes` sería distinto: el PFILE contiene la línea **`*.processes=200`**. En ese caso, restaurar la configuración implica volver a fijar el valor **200**, no borrar una entrada expresamente configurada. Además, el intento de modificar `processes` desde la PDB produjo `ORA-65040` porque es una operación que corresponde al ámbito de la CDB.

**Evidencia:** `docs/bitacora/lab6/evidencia/config/20261117T225026Z_02-init_desde_spfile.ora` (`*.processes=200`, sin entrada `db_files`) y `docs/bitacora/lab6/evidencia/script/20261117T225025Z_02-parametros.script.log`.

## 5. Error al conectarse tras reiniciar sin SAVE STATE

`C##OPS_RO` recibió **`ORA-01109: database not open`**. El reinicio había abierto correctamente la base contenedora `FREE`, de ahí el mensaje `Database opened`, pero `FREEPDB1` permanecía en estado **MOUNTED** porque todavía no tenía guardado su estado de apertura. Una CDB abierta no implica que todas sus PDB estén abiertas. El `ORA-01035` observado en otro paso correspondió al acceso a una PDB en modo restringido, no a este reinicio.

**Evidencia:** `docs/bitacora/lab6/evidencia/script/20261117T225051Z_02-estados-pdb.script.log` (`FREEPDB1 MOUNTED`, `ORA-01109`, posterior `FREEPDB1 READ WRITE`).

## 6. SID, SPID y evento de la sesión de la aplicación

La sesión de `APP_ACADEMIA` tenía **SID 229**, **SERIAL# 39639**, **SPID 2473** y el evento de espera **`PL/SQL lock timer`**. Entraba por el servicio `academia_app`. Sus campos de instrumentación indicaban `MODULE=matriculas`, `ACTION=cierre-periodo` y `CLIENT_IDENTIFIER=ana.garcia@ucam`. El `USERNAME` solo identifica la cuenta técnica de Oracle, que pueden compartir distintos usuarios de la aplicación; los otros campos permiten identificar el módulo, la acción concreta y el usuario final relacionado con esa sesión.

**Evidencia:** `docs/bitacora/lab6/evidencia/script/20261117T225625Z_03-sesiones.script.log` (SID 229, SERIAL# 39639, SPID 2473).

## 7. Transacciones después de CANCEL SQL y KILL SESSION

Después de `ALTER SYSTEM CANCEL SQL` permanecía **1 transacción abierta**: se interrumpió la llamada `DBMS_SESSION.SLEEP(40)`, pero no se confirmó ni deshizo automáticamente el `UPDATE` pendiente. Después de `ALTER SYSTEM KILL SESSION '229,39639' IMMEDIATE` la comprobación mostró **0 sesiones vivas de la aplicación**. Oracle devolvió `ORA-00031` porque la sesión había quedado marcada para terminar, y posteriormente se comprobó su finalización. Al deshacerse la operación no confirmada, la fila **101** conservó el estado **ACTIVO**. La salida aporta el recuento de cero sesiones, no un contador independiente de transacciones tras el `KILL`.

**Evidencia:** `docs/bitacora/lab6/evidencia/script/20261117T225625Z_03-sesiones.script.log` (`TRANSACCIONES_ABIERTAS_DE_LA_APP=1`, `SESIONES_APP_VIVAS=0`, alumno 101 `ACTIVO`).

## 8. Valor de common_user_prefix

El valor obtenido con `SHOW PARAMETER common_user_prefix` fue **`C##`**. Por ello, una cuenta común creada en la CDB debe seguir ese prefijo, como `C##OPS_RO`. En cambio, `APP_ACADEMIA` es una cuenta local de `FREEPDB1` y no necesita ese prefijo.

**Evidencia:** consulta `SHOW PARAMETER common_user_prefix` ejecutada el **17/11/2026 a las 23:43:34 UTC**, con `VALUE=C##`.

## 9. Tres perspectivas del diccionario

| Vista o dato | C##OPS_RO en CDB$ROOT | C##OPS_RO en FREEPDB1 | APP_ACADEMIA en FREEPDB1 |
|---|---:|---:|---:|
| `ALL_TABLES` de `ADMIN_ACADEMIA` | 0 | 0 | 1 |
| `DBA_USERS` | 37 | 47 | `ORA-00942` |
| `CDB_USERS` | 37 en `CON_ID=1` y 47 en `CON_ID=3` | 47 en `CON_ID=3` | `ORA-00942` |
| `V$DATAFILE` | 17 | 10 | `ORA-00942` |

La diferencia depende del contenedor y de los privilegios efectivos. Desde la raíz, `C##OPS_RO` podía ver datos de varios contenedores; dentro de `FREEPDB1` el alcance era local. `APP_ACADEMIA` podía consultar una tabla de negocio que necesitaba para trabajar, pero no las vistas administrativas. **`ORA-00942` no significa que la vista tenga cero filas**, sino que no estaba accesible para esa cuenta.

**Evidencia:** `docs/bitacora/lab6/evidencia/script/20261117T225814Z_04-tres-miradas.script.log`.

## 10. Lecturas lógicas y DB time de la carga

Los diez recorridos completos de `PEDIDO`, con un millón de filas cada uno, produjeron un delta de **53.403 lecturas lógicas**, equivalente a **5.340 por recorrido** según el redondeo del script. El **DB time fue 0,40 segundos**, el **DB CPU fue 0,37 segundos** y el tiempo de reloj fue **0,40 segundos**. Como DB time y DB CPU son muy próximos, durante esta prueba predominó el tiempo consumido en CPU y las esperas no ociosas tuvieron poca importancia relativa. Estas cifras corresponden a esta carga y no deben extrapolarse a cualquier actividad de la PDB.

**Evidencia:** `docs/bitacora/lab6/evidencia/script/20261117T225829Z_04-deltas.script.log`.

## 11. Espacio de TBS_ACADEMIA_HIST y criterio de alerta

Antes de la carga, `TBS_ACADEMIA_HIST` tenía **10 MB asignados**, **3,9 MB libres dentro de esos 10 MB** y un **máximo de 40 MB** por su configuración de autoextensión. La métrica de ocupación mostraba **15,16 %** respecto al tamaño máximo. Para las alertas vigilaría principalmente la ocupación en relación con el **máximo alcanzable** y el espacio que todavía puede crecer, no solo los 3,9 MB libres actuales: el datafile podía ampliarse hasta el techo de 40 MB. En la práctica también se configuraron umbrales preventivos del **80 % (aviso)** y **95 % (crítico)**.

**Evidencia:** `docs/bitacora/lab6/evidencia/script/*_05-almacenamiento.script.log` (10 MB, 3,9 MB, 40 MB, 15,16 %; umbrales 80/95).

## 12. Quién insertó y quién consumió la cuota

Las sentencias `INSERT INTO carga_hist.registro` se ejecutaron **desde la sesión administrativa SYSDBA**, pero el segmento pertenecía a **`CARGA_HIST`**, que es quien debe tener cuota en `TBS_ACADEMIA_HIST`. El primer `INSERT` produjo **`ORA-01950`** porque el propietario no tenía cuota. Después se le concedieron **2 MB**, pero una inserción mayor dio **`ORA-01536`** al superar ese límite. El hecho de que el tablespace pudiera crecer no solucionaba el problema, porque el límite que se estaba agotando era la **cuota del dueño del segmento**, no el espacio global del tablespace.

**Evidencia:** `docs/bitacora/lab6/evidencia/script/*_05-almacenamiento.script.log` (`CARGA_HIST`, `MAX_BYTES=2097152`, `ORA-01950`, `ORA-01536`).

## 13. Suspensión de una carga RESUMABLE

La operación se suspendió por **`ORA-01536`** al superar la cuota de `CARGA_HIST`. `DBA_RESUMABLE` mostraba el estado **`SUSPENDED`** y un `TIMEOUT` de **180 segundos**. En la consulta de seguimiento, la sesión llevaba **2 segundos** en el evento `statement suspended, wait error to be cleared`. La aplicación anotó inicio a las **23:01:26** y fin a las **23:01:40**, es decir, **14 segundos de ejecución total**, incluida la pausa; el registro no permite establecer con exactitud cuántos de esos segundos estuvo suspendida. Tras ampliar la cuota a **30 MB**, continuó y confirmó **20.000 filas**, con **23 MB de cuota consumida**. El *alert log* dejó constancia tanto de `suspended due to` como de `resumed`.

**Evidencia:** `docs/bitacora/lab6/evidencia/script/20261117T230125Z_05-resumable.script.log`.

## 14. DELETE, SHRINK SPACE, bloques y cuota

Antes de borrar había **20.000 filas**, **2.944 bloques** y **23 MB** asignados al segmento. Se borraron **18.000 filas**: quedaron **2.000**, pero el segmento seguía usando **2.944 bloques** y **23 MB**. Después de habilitar el movimiento de filas y ejecutar `SHRINK SPACE`, seguían quedando **2.000 filas**, pero el segmento se redujo a **304 bloques** y **2,4 MB** de cuota consumida. `DELETE` libera el contenido de las filas para reutilización, pero no reduce por sí mismo la marca de agua alta (*HWM*); `SHRINK` compacta el segmento y puede devolver espacio.

**Evidencia:** `docs/bitacora/lab6/evidencia/script/20261117T230141Z_05-hwm-shrink.script.log`.

## 15. Perfil DEFAULT y límites de PRF_PERSONAS

Mi perfil `DEFAULT` tenía **10 intentos fallidos** antes del bloqueo, **180 días** de vida de la contraseña, **7 días** de gracia, **1 día** de bloqueo e **INACTIVE_ACCOUNT_TIME=365 días**; además, `PASSWORD_VERIFY_FUNCTION` aparecía como `NULL`. El perfil `PRF_PERSONAS`, aplicado a `ANA_GARCIA`, incluía una política más específica. Destaco dos límites: **3 intentos fallidos** antes de bloquear temporalmente la cuenta, que dificulta los intentos repetidos de acceso, y la **verificación de complejidad**, que rechazó una contraseña de menos de **8 caracteres** con `ORA-28003`. El bloqueo de **1 minuto** se usó para la práctica: en producción habría que ajustar duración y recuperación al riesgo real y a la actividad de secretaría.

**Evidencia:** `docs/bitacora/lab6/evidencia/script/*_06-gobierno-acceso.script.log` (`FAILED_LOGIN_ATTEMPTS=10` en DEFAULT; `ORA-28003` para `corta`; perfil `PRF_PERSONAS`).

## 16. Lectura de ACA_MATRICULAS y error al modificar NOMBRES

`ANA_GARCIA` tenía activos `ROL_SECRETARIA_ACADEMIA` y su rol heredado `ROL_LECTURA_ACADEMIA`. Este último aportaba el privilegio de lectura sobre el esquema `ADMIN_ACADEMIA` (`SELECT ANY TABLE` de ámbito de esquema); por eso podía leer `ACA_MATRICULAS` aunque no se le hubiera concedido `SELECT` nominalmente sobre esa tabla. Para escribir, el rol de secretaría solo permitía actualizar la columna **`ESTADO`** de `ACA_ESTUDIANTES`. Al intentar modificar **`NOMBRES`**, columna no autorizada, recibió **`ORA-41900: missing UPDATE privilege`**. El resultado refleja un control de privilegios mínimos.

**Evidencia:** `docs/bitacora/lab6/evidencia/script/*_06-gobierno-acceso.script.log` y `docs/bitacora/lab6/evidencia/script/*_06-sesion-ana.script.log` (roles activos y `ORA-41900`).

## 17. Invalidación de objetos tras tres cambios de columnas

En la tabla de prueba `ACA_EST_LAB6` se realizaron tres cambios. Primero se añadió **`TELEFONO`**, columna que ningún objeto dependiente utilizaba: quedaron **0 objetos invalidados**. Después se amplió **`EMAIL_INSTITUCIONAL`** a `VARCHAR2(200)`, lo que invalidó **`V_CONTACTO_LAB6`**, la vista que referenciaba esa columna; los demás objetos continuaron válidos. Por último se amplió **`NOMBRES`** a `VARCHAR2(120)`: quedaron inválidos **`V_ACTIVOS_LAB6`**, **`V_CONTACTO_LAB6`** y **`F_TOTAL_ACTIVOS_LAB6`**. La función depende de `V_ACTIVOS_LAB6`, de manera que el cambio también repercute en esa dependencia. La diferencia con añadir `TELEFONO` ilustra las dependencias de grano fino de Oracle.

**Evidencia:** `docs/bitacora/lab6/evidencia/script/*_07-objetos.script.log` (estados `VALID`/`INVALID` y dependencias).

## 18. Asesores de memoria SGA y PGA

La SGA de partida era **1.536 MB**. El asesor mostraba `ESTD_DB_TIME_FACTOR=1` tanto en ese tamaño (factor 1) como al duplicarla a **3.072 MB** (factor 2); por tanto, **no estimaba ninguna mejora en DB time por duplicar la SGA** en la carga observada. Para la PGA, el valor actual era **512 MB**, con `HIT_PCT=100` y **0 sobreasignaciones**. Con **384 MB** también aparecían **0 sobreasignaciones**, pero con **256 MB** y **128 MB** había **4**. Entre los tamaños ensayados, las sobreasignaciones aparecían **por debajo de 384 MB**.

**Evidencia:** `docs/bitacora/lab6/evidencia/script/*_07-*` (salida de `SGA_TARGET_ADVICE` y `PGA_TARGET_ADVICE`: SGA 1.536/3.072 MB; PGA 128/256/384/512 MB).

## 19. Lecturas lógicas de la consulta trazada

En la traza de la sesión de la aplicación, la línea **`FETCH ... cr=247`** indicaba **247 lecturas lógicas** en esa operación de recuperación. El resumen de `tkprof` mostraba **249 lecturas lógicas para la consulta en total** al agregar todas sus fases. Son cifras compatibles: 247 corresponden al `FETCH` de la traza y 249 al total del informe. La línea `FETCH ... cr=247` es la referencia directa solicitada.

**Evidencia:** `docs/bitacora/lab6/evidencia/script/20261117T230603Z_07-adr-trazas.script.log` (`FETCH ... cr=247`; `tkprof` total 249).

## 20. Evidencia, intervención y validación de los tres incidentes

- **INC-601 — Bloqueo de matrícula.** Evidencia: espera `enq: TX - row lock contention` y sesión bloqueadora `APP_ACADEMIA`, **SID 63 / SERIAL# 7010**. Intervención: `ALTER SYSTEM KILL SESSION '63,7010' IMMEDIATE`, después de identificar la sesión responsable. Validación: desapareció el bloqueo y, desde el usuario afectado `ANA_GARCIA`, el estudiante **101 figuraba ACTIVO**.
- **INC-602 — ORA-12514.** Evidencia: `academia_app` estaba definido pero no activo y no figuraba disponible en el listener. Intervención: `DBMS_SERVICE.START_SERVICE('academia_app')` dentro de `FREEPDB1`, guardado del estado de la PDB y `ALTER SYSTEM REGISTER`. Validación: listener en **READY** y conexión y consulta correctas con `APP_ACADEMIA` (17.600 estudiantes observados en esa validación).
- **INC-603 — ORA-28000.** Evidencia: `APP_ACADEMIA` aparecía en estado **LOCKED**. Intervención: `ALTER USER app_academia ACCOUNT UNLOCK`. Validación: pasó a **OPEN** y la aplicación volvió a conectar con su rol habitual y a realizar su consulta.

**Evidencia:** `docs/bitacora/lab6-guardia.md` y `docs/bitacora/lab6/evidencia/script/*_08-inc601-*.script.log`, `*_08-inc602-*.script.log`, `*_08-inc603-*.script.log`.
