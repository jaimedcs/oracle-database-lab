# Laboratorio 6 - Guardia nocturna
**Estudiante:** E019
**Fecha:** 17 de noviembre de 2026

## INC-601 - Bloqueo de la ficha de un alumno

- **Detección:** 23:07 UTC. Secretaría comunica que la ficha del estudiante 101 se queda bloqueada al guardarla.
- **Impacto:** Ana García no podía terminar la operación. La base de datos y los servicios seguían disponibles. No se midió la duración exacta de la incidencia.
- **Diagnóstico:** La sesión 231 de ANA_GARCIA esperaba en `enq: TX - row lock contention`. La bloqueaba la sesión 63, serial 7010, de APP_ACADEMIA, identificada con el módulo `matriculas` y la acción `cierre-periodo`. La transacción pendiente tenía 1 bloque y 1 registro de UNDO.
- **Causa raíz:** El proceso de matrículas mantenía un cambio sin confirmar sobre una fila que necesitaba secretaría. La transacción abierta impidió continuar hasta liberar el bloqueo.
- **Intervención:** Se comprobó la identidad del bloqueador y se ejecutó `ALTER SYSTEM KILL SESSION '63,7010' IMMEDIATE;`. Se actuó solo sobre la sesión responsable, sin reiniciar Oracle.
- **Validación:** El diagnóstico posterior no mostró sesiones bloqueadas. La conexión de ANA_GARCIA permitió consultar al estudiante 101 con estado `ACTIVO`. ASH conservó el histórico del bloqueo.
- **Acción preventiva:** Revisar el control de transacciones en el cierre de periodo, evitar esperas prolongadas con cambios sin confirmar y alertar ante bloqueos TX sostenidos.

## INC-602 - La aplicación no conecta por ORA-12514

- **Detección:** 23:10 UTC. El equipo de matrículas comunica que la aplicación no puede establecer conexiones.
- **Impacto:** El acceso por el servicio `academia_app` quedó interrumpido. FREEPDB1 y el listener continuaban funcionando.
- **Diagnóstico:** `CDB_SERVICES` mostraba `academia_app` como servicio existente, pero `V$ACTIVE_SERVICES` indicaba `ARRANCADO = NO`. El servicio tampoco aparecía en el resumen del listener.
- **Causa raíz:** El servicio de aplicación estaba detenido pese a que la PDB seguía abierta. La evidencia demuestra el estado incorrecto del servicio, aunque no permite identificar por sí sola qué acción lo detuvo.
- **Intervención:** Se ejecutó `DBMS_SERVICE.START_SERVICE('academia_app')`, seguido de `ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE` y `ALTER SYSTEM REGISTER`.
- **Validación:** El listener volvió a anunciar `academia_app` con estado `READY`. APP_ACADEMIA conectó, utilizó `ROL_APP_ACADEMIA` y consultó 17.600 estudiantes activos.
- **Acción preventiva:** Comprobar que los servicios de aplicación siguen registrados después de los reinicios y añadir su disponibilidad a la lista de turno.

## INC-603 - Cuenta de aplicación bloqueada

- **Detección:** 23:12 UTC. Matrículas comunica el error ORA-28000 después del despliegue y de la ejecución de un procedimiento trimestral de bajas.
- **Impacto:** APP_ACADEMIA no podía iniciar sesión, aunque la base de datos y el servicio estaban disponibles.
- **Diagnóstico:** `CDB_USERS` mostraba `APP_ACADEMIA` con estado `LOCKED`, perfil `DEFAULT` y límite de 10 intentos fallidos. No figuraba como `LOCKED(TIMED)`.
- **Causa raíz:** Se observó un bloqueo administrativo de la cuenta. El ticket apunta a que el procedimiento de bajas pudo incluir una cuenta técnica, aunque haría falta revisar ese procedimiento y su auditoría para confirmarlo.
- **Intervención:** Se verificó el estado de la cuenta y se ejecutó `ALTER USER app_academia ACCOUNT UNLOCK`. No fue necesario cambiar la contraseña ni reiniciar Oracle.
- **Validación:** La cuenta volvió a `OPEN`. La aplicación conectó con `ROL_APP_ACADEMIA`, consultó 17.600 estudiantes y realizó una actualización de prueba seguida de ROLLBACK. El ORA-00942 al acceder al histórico fue el rechazo de permisos esperado.
- **Acción preventiva:** Excluir expresamente las cuentas técnicas de los procedimientos automáticos de bajas, validar la lista de cuentas afectadas antes de ejecutarlos y conservar auditoría de los cambios de estado.

### Evidencias del INC-601
- `docs/bitacora/lab6/evidencia/script/20261117T230739Z_08-inc601-ticket.script.log`
- `docs/bitacora/lab6/evidencia/script/20261117T230746Z_08-inc601-diagnostico.script.log`
- `docs/bitacora/lab6/evidencia/script/20261117T230854Z_08-inc601-intervencion.script.log`
- `docs/bitacora/lab6/evidencia/script/20261117T230858Z_08-inc601-validacion.script.log`
- `docs/bitacora/lab6/evidencia/script/20261117T231003Z_08-inc601-consumidor.script.log`

### Evidencias del INC-602
- `docs/bitacora/lab6/evidencia/script/20261117T231033Z_08-inc602-ticket.script.log`
- `docs/bitacora/lab6/evidencia/script/20261117T231034Z_08-inc602-diagnostico.script.log`
- `docs/bitacora/lab6/evidencia/script/20261117T231038Z_08-inc602-listener.script.log`
- `docs/bitacora/lab6/evidencia/script/20261117T231133Z_08-inc602-intervencion.script.log`
- `docs/bitacora/lab6/evidencia/script/20261117T231133Z_08-inc602-validacion.script.log`

### Evidencias del INC-603
- `docs/bitacora/lab6/evidencia/script/20261117T231240Z_08-inc603-diagnostico.script.log`
- `docs/bitacora/lab6/evidencia/script/20261117T231240Z_08-inc603-ticket.script.log`
- `docs/bitacora/lab6/evidencia/script/20261117T231326Z_08-inc603-intervencion.script.log`
- `docs/bitacora/lab6/evidencia/script/20261117T231326Z_08-inc603-validacion.script.log`
