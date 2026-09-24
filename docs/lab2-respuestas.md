# Lab 2 - Preguntas de comprobación

## 1. ¿Por qué un Issue sin criterios de aceptación es un problema, aunque la descripción general parezca clara?

Porque una descripción general puede explicar lo que se quiere hacer, pero no deja claro cuándo se puede considerar terminado el trabajo. Los criterios de aceptación convierten el Issue en algo verificable, ya que permiten comprobar objetivamente si se han cumplido todos los requisitos.

## 2. Explica la diferencia entre "Refs #N" y "Closes #N" en un mensaje de commit o en la descripción de un Pull Request.

`Refs #N` relaciona el commit o el cambio con el Issue número N, pero no provoca su cierre automático. En cambio, `Closes #N` indica a GitHub que ese Pull Request resuelve el Issue y, cuando el cambio se integra en `main`, GitHub cierra automáticamente el Issue.

## 3. ¿Qué ocurre exactamente si intentas hacer git push directamente sobre una branch main protegida? ¿Es un error tuyo o un fallo del sistema?

Si la protección de `main` está configurada para impedir el push directo y no se permite el bypass, GitHub rechaza el `push` y obliga a realizar el cambio mediante una branch y un Pull Request. No es un fallo del sistema, sino precisamente la protección funcionando como se espera.

## 4. Un compañero te dice: "he aprobado el PR sin mirar los archivos, total ya me fío". ¿Qué riesgo tiene esa forma de revisar?

El riesgo es que la aprobación deje de ser un control de calidad real. El reviewer debe revisar los archivos modificados y el diff para comprobar que el cambio cumple los criterios del Issue, que es legible, mantenible, seguro, está probado y correctamente documentado. Aprobar solo por confianza puede permitir que entren errores o problemas que nadie ha comprobado.

## 5. Si el reviewer pide un cambio y tú ya habías hecho push de tu branch, ¿tienes que abrir un Pull Request nuevo? Explica qué ocurre técnicamente con el PR existente cuando haces un nuevo commit.

No hay que abrir un Pull Request nuevo. Se modifica la misma branch, se crea un nuevo commit y se hace `push`. Como el Pull Request está asociado a esa branch, GitHub incorpora automáticamente el nuevo commit y actualiza el diff del mismo PR. Así se conserva toda la conversación y el historial de la revisión.

## 6. Describe con tus palabras la diferencia entre Merge commit, Squash and merge y Rebase and merge. ¿Cuál usarías para una branch con commits "wip", "fix", "fix2", "ok ya"?

`Merge commit` conserva todos los commits originales de la branch y añade un commit adicional de fusión.

`Squash and merge` combina todos los commits de la branch en un único commit antes de incorporarlo a `main`.

`Rebase and merge` reaplica los commits de la branch uno a uno sobre `main`, manteniendo un historial lineal y sin crear un commit de merge.

Para una branch con commits como `wip`, `fix`, `fix2` y `ok ya` utilizaría `Squash and merge`, porque esos commits son pasos de trabajo y no aportan valor individual al historial final de `main`.

## 7. ¿Por qué borrar una branch después del merge no elimina el trabajo realizado en ella?

Porque después del merge los cambios ya han sido incorporados a `main`. La branch es solamente un puntero que identificaba una línea de trabajo. Al borrarla se elimina ese puntero, pero el trabajo integrado continúa formando parte del historial de `main`.

## 8. ¿Qué información debería contener siempre la descripción de un Pull Request, como mínimo?

Como mínimo debería explicar qué se está haciendo, qué cambios concretos incluye, cómo se ha probado y con qué Issue está relacionado. En este laboratorio se organiza mediante las secciones `Summary`, `Changes`, `Testing` y `Related Issue`.

## 9. Un reviewer escribe solo "esto está mal" como comentario. ¿Qué le falta a ese comentario para ser útil? Reescríbelo tú con un ejemplo inventado.

Le falta explicar qué problema ha observado, por qué es importante y, cuando sea posible, qué cambio propone. También debería indicar claramente la severidad mediante Conventional Comments.

Por ejemplo:

`issue (blocking): Esta parte no cumple uno de los criterios de aceptación del Issue. Propongo corregirla antes de aprobar el Pull Request.`

Así el autor sabe qué problema existe, que bloquea la aprobación y qué debe hacer para resolverlo.

## 10. ¿Qué diferencia hay entre que main esté protegida y que simplemente el equipo "se ponga de acuerdo" en no hacer push directo?

Si solamente existe un acuerdo, cumplirlo depende de que todos los miembros del equipo recuerden y respeten la norma. Si `main` está protegida, esa política se convierte en una regla técnica aplicada por GitHub, que puede impedir directamente acciones que incumplan el flujo establecido.

## 11. Explica con un ejemplo propio la diferencia entre un comentario issue: (blocking) y uno nitpick: (if-minor) en formato Conventional Comments.

Un comentario `issue: (blocking)` señala un problema que debe resolverse antes de poder considerar listo el cambio.

Por ejemplo:

`issue (blocking): Falta uno de los criterios de aceptación indicados en el Issue. Debe añadirse antes del merge.`

Un comentario `nitpick: (if-minor)` señala un detalle menor que no debería impedir por sí solo la aprobación.

Por ejemplo:

`nitpick (if-minor): Podríamos cambiar este título para mantener el mismo estilo que el resto del documento.`

La diferencia principal es que el primero bloquea la aprobación hasta ser resuelto, mientras que el segundo queda a criterio del autor o del equipo.

## 12. Si tu próximo commit es feat!: cambia la firma de la función principal de la API, ¿qué tipo de versión SemVer se dispara y por qué?

Se produciría un cambio de versión `MAJOR`. El signo `!` en un Conventional Commit indica un `BREAKING CHANGE`, es decir, un cambio que rompe la compatibilidad con versiones anteriores. Por ejemplo, una versión `2.1.0` pasaría a `3.0.0`.

## 13. ¿Por qué abrir un Draft PR desde el primer commit estructural puede ahorrar tiempo al equipo, aunque parezca más lento para el autor individual?

Porque permite que otros miembros del equipo revisen y validen el enfoque general cuando todavía se ha invertido poco tiempo en el desarrollo. Si existe un problema de diseño, puede detectarse antes de haber escrito toda la lógica y los tests. De esta forma se aplica el principio de `Fail Fast` y se evita invertir muchas horas en una solución que después tendría que rehacerse.
