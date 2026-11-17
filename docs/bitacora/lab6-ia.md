He leído la política de uso de IA de la asignatura.

# Declaración de uso de IA · Lab 6 · E019

<!--
CÓMO SE RELLENA (léelo y borra este comentario si quieres; el script de evaluación lo ignora)
- La PRIMERA línea es obligatoria y no se toca: «He leído la política de uso de IA de la asignatura.»
- Copia este archivo como docs/bitacora/lab6-ia.md (junto a lab6-respuestas.md) y pon tu código en el título.
  Cada laboratorio tiene el suyo: en el Lab 7 será docs/bitacora/lab7-ia.md.
- Si NO has usado IA: deja solo la línea «No he usado IA.» y borra la entrada de ejemplo.
- Si la has usado: borra la línea «No he usado IA.» y escribe UNA entrada por cada uso, con los 7 campos.
  Un campo vacío es una entrada incompleta (D3: −0,5 por entrada).
- Preguntar a la IA como tutor o corregir la ortografía de un texto propio está permitido: decláralo también.
  Si no copiaste código, escribe «no aplica» en «Código recibido» y en «Evidencia de ejecución» (no cuentan como vacíos).
  Los demás campos son siempre obligatorios.
- Una entrada con TODOS los campos vacíos (la de ejemplo sin tocar) no cuenta: se ignora.
- El código copiado de una IA puntúa si lo EJECUTAS en tu contenedor, lo EXPLICAS con tus palabras,
  dices para qué lo usaste y adjuntas aquí el código y el prompt LITERAL.
-->


## Entrada 1 - Preparacion y ejecucion del laboratorio

- **Herramienta:** ChatGPT (OpenAI).
- **Prompt:** Ayudame a organizar la ejecucion del Laboratorio 6 de Oracle utilizando los scripts facilitados por el profesor.
- **Codigo recibido:** Comandos de terminal para ejecutar los scripts existentes, entre ellos `bash scripts/ops/esperar-healthy.sh 600` y `bash scripts/lab6/05-resumable.sh`.
- **Donde lo use:** Preparacion del laboratorio y ejecucion de las partes A a H.
- **Proposito:** Seguir un orden de trabajo, verificar los resultados y registrar evidencias.
- **Que hace:** Los comandos ejecutan los scripts del material de clase. ChatGPT ayudo a organizarlos y a interpretar las salidas. Los scripts originales proceden del profesor.
- **Evidencia de ejecucion:** `docs/bitacora/lab6/evidencia/script/20261117T230125Z_05-resumable.script.log`.

## Entrada 2 - Incidente INC-601

- **Herramienta:** ChatGPT (OpenAI).
- **Prompt:** Analiza el bloqueo entre dos sesiones de Oracle y explica cómo liberar la operación afectada sin reiniciar la base.
- **Código recibido:** `ALTER SYSTEM KILL SESSION '63,7010' IMMEDIATE;`
- **Dónde lo usé:** Parte I, incidente INC-601.
- **Propósito:** Resolver el bloqueo que impedía modificar la ficha del alumno 101.
- **Qué hace:** Termina la sesión bloqueadora tras comprobar su SID y SERIAL#. Después se verificó que desapareció el bloqueo y que el alumno 101 estaba ACTIVO.
- **Evidencia de ejecución:** docs/bitacora/lab6/evidencia/script/20261117T230854Z_08-inc601-intervencion.script.log

## Entrada 3 - Incidente INC-602

- **Herramienta:** ChatGPT (OpenAI).
- **Prompt:** Explica cómo diagnosticar ORA-12514 y recuperar un servicio Oracle que no aparece en el listener.
- **Código recibido:** `DBMS_SERVICE.START_SERVICE('academia_app');`, `ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE;` y `ALTER SYSTEM REGISTER;`
- **Dónde lo usé:** Parte I, incidente INC-602.
- **Propósito:** Recuperar la conexión de la aplicación de matrículas.
- **Qué hace:** Arranca el servicio, guarda su estado y actualiza el registro del listener. Se comprobó que aparecía READY y que la aplicación conectaba.
- **Evidencia de ejecución:** docs/bitacora/lab6/evidencia/script/20261117T231133Z_08-inc602-intervencion.script.log

## Entrada 4 - Incidente INC-603

- **Herramienta:** ChatGPT (OpenAI).
- **Prompt:** Analiza el error ORA-28000 y explica cómo recuperar una cuenta de aplicación bloqueada.
- **Código recibido:** `ALTER USER app_academia ACCOUNT UNLOCK;`
- **Dónde lo usé:** Parte I, incidente INC-603.
- **Propósito:** Restablecer el acceso de APP_ACADEMIA.
- **Qué hace:** Desbloquea únicamente la cuenta afectada después de verificar su estado. Se comprobó que volvió a OPEN y que podía consultar los estudiantes.
- **Evidencia de ejecución:** docs/bitacora/lab6/evidencia/script/20261117T231326Z_08-inc603-intervencion.script.log


## Entrada 5 - Documentacion de la guardia

- **Herramienta:** ChatGPT (OpenAI).
- **Prompt:** Ayudame a organizar los informes de tres incidentes Oracle, indicando diagnostico, solucion, validacion y medidas preventivas.
- **Codigo recibido:** No aplica. Se recibio un borrador Markdown.
- **Donde lo use:** Parte I, docs/bitacora/lab6-guardia.md.
- **Proposito:** Preparar los informes de los incidentes INC-601, INC-602 e INC-603.
- **Que hace:** Organiza los resultados de las pruebas y relaciona cada problema con su solucion. El borrador fue preparado con asistencia de ChatGPT y debe revisarse antes de entregarlo.
- **Evidencia de ejecucion:** docs/bitacora/lab6-guardia.md y los archivos de evidencia 08 de los tres incidentes.

