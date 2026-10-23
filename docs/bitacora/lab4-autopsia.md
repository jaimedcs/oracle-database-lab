# Laboratorio 4 — Autopsia de la instancia Oracle FREE

**Fecha de trabajo:** 23 de octubre de 2026  
**Ámbito:** Oracle FREE 23.26.3.0.0, `FREEPDB1`, imagen Oracle Free bajo Docker  
**Fuente principal:** `docs/bitacora/lab4/evidencia/spool/` (registro `15-autopsia-instancia`) y evidencias 01, 03, 07, 08, 09 y 11. 

## Estado general

La CDB `FREE` y la PDB `FREEPDB1` quedaron abiertas en `READ WRITE`. Los cinco datafiles de negocio están dentro de `/opt/oracle/oradata/FREE/FREEPDB1/` y los tablespaces siguen ONLINE después de recrear el contenedor. El conjunto de datos de demostración contiene 20.000 estudiantes, 40 asignaturas y 60.000 matrículas. La validación automatizada del paso 16 se confirmó como `TODO OK`.

## Hallazgos, riesgo, acción y prioridad

| Sección / evidencia | Hallazgo observado | Riesgo | Acción propuesta | Prioridad |
|---|---|---|---|---|
| 4 — Archivos · evidencia 11 | Dos control files (`control01.ctl`, `control02.ctl`) en la **misma ruta `/opt/oracle/oradata/FREE/`** | Una avería del almacenamiento compartido puede inutilizar ambas copias | Colocar copias multiplexadas en destinos físicos independientes y probar recuperación | **Alta** |
| 4 — Archivos · evidencia 11 | Tres grupos de online redo con **un único miembro por grupo** | Pérdida de disponibilidad ante daño de ese miembro | Multiplexar cada grupo de redo entre discos independientes | **Alta** |
| 4 y 9 — Configuración · evidencias 01 y 11 | `LOG_MODE=ARCHIVELOG` y `db_recovery_file_dest` vacío; `db_recovery_file_dest_size=0` | Los archivados no tienen una FRA gestionada y su destino/capacidad deben vigilarse; riesgo de saturación si no se gestionan | Definir estrategia de destino/FRA, política de limpieza y monitorización en Lab 5 | **Alta** |
| 11 — Diagnóstico de Linux · evidencia 11 | El ADR y `alert_FREE.log` se encuentran fuera del volumen persistente, en `/opt/oracle/diag/...` | Al recrear el contenedor se pierde historial de diagnóstico | Montar ADR en almacenamiento persistente o centralizar los logs | **Media** |
| 7 — Seguridad · evidencias 02, 04, 10 y 11 | `C##OPS_RO` es común y de solo lectura; cinco usuarios `ADMIN_*` con `AUTHENTICATION_TYPE=NONE` | Riesgo bajo si se mantienen esos permisos, pero habría riesgo de escalada si se reutilizara SYS/SYSTEM para observación | Mantener la observabilidad con menor privilegio y revisar periódicamente los GRANT | **Baja / seguimiento** |

## Hallazgos positivos comprobados

- **Persistencia:** borrar y recrear el contenedor conservó los cinco tablespaces de negocio y sus 14 tablas (evidencia 03).
- **Seguridad:** V003 invalidó las cinco contraseñas heredadas; el ejecutor administrativo ya usa autenticación de sistema operativo en vez de `sys/contraseña` en CLI (evidencia 04).
- **Memoria:** `SGA_TARGET=1536M`, `PGA_AGGREGATE_TARGET=512M`, `MEMORY_TARGET=0` (ASMM). La ronda caliente de Buffer Cache realizó **0 lecturas físicas** (evidencias 07–08).
- **Operación:** la cuenta `C##OPS_RO` puede consultar el alert log por `V_$DIAG_ALERT_EXT`; la PDB de prueba y el tablespace temporal del Lab 4 se borraron (evidencias 10–16).

## Interpretación del alert log

Los avisos de prioridad de Linux (`ORA-00800`) observados en el apartado 06 no bloquearon el arranque. El `ORA-65025` se provocó al intentar borrar una PDB todavía abierta (prueba del apartado 10); `ORA-06512` es parte del stack PL/SQL, no un incidente autónomo. El contador del apartado 15 registra 6 mensajes ORA- en 24 h.

## Resumen para una persona no técnica

La base de datos funciona y los datos persisten incluso al reconstruir el contenedor.  
La principal mejora pendiente es distribuir mejor los archivos críticos y controlar el almacenamiento de recuperación.  
También conviene conservar los registros de errores fuera del contenedor para poder investigar incidencias futuras.
