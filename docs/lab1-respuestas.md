# Laboratorio 1 — Respuestas

## 1. ¿Cuál es la diferencia entre Working Directory, Staging Area y Local Repository?

El Working Directory es la carpeta del proyecto donde creo y modifico los archivos.

La Staging Area es una zona intermedia en la que preparo los archivos que quiero incluir en el siguiente commit mediante git add.

El Local Repository es el historial de commits almacenado por Git dentro de la carpeta .git.

Por ejemplo, cuando modifiqué README.md primero estaba en el Working Directory. Después ejecuté git add README.md y pasó a la Staging Area. Finalmente, al ejecutar git commit, el cambio quedó guardado en el Local Repository.

## 2. Si modificas un archivo pero no haces git add, ¿aparece ese cambio en tu próximo commit?

No. Git commit solamente guarda los cambios que previamente se han añadido a la Staging Area.

Lo comprobé cuando creé docs/customer-schema.md e intenté hacer directamente el commit. Git indicó que el archivo estaba untracked y el commit no se realizó hasta que ejecuté git add.

## 3. ¿Por qué git status no mostraba las carpetas vacías que creaste en la Parte C? ¿Qué truco usamos para solucionarlo?

Porque Git versiona archivos, no carpetas vacías.

Para conseguir que las carpetas vacías formen parte del repositorio añadimos dentro archivos llamados .gitkeep.

## 4. Explica con tus palabras qué es HEAD.

HEAD es el puntero que indica en qué commit o branch estoy trabajando en ese momento.

Por ejemplo, cuando aparecía:

HEAD -> main

significaba que estaba situado en la rama main.

## 5. ¿Qué diferencia hay entre crear una branch con git switch -c y crear una carpeta nueva con mkdir? ¿Cómo lo comprobamos en la Parte G?

git switch -c crea una nueva rama de Git, es decir, otra línea de evolución del historial.

mkdir crea físicamente una nueva carpeta en el disco.

Lo comprobamos creando feature/customer-search. Al ejecutar ls no apareció ninguna carpeta feature. Además, customer-search.md desaparecía al cambiar a main y volvía a aparecer al regresar a feature/customer-search.

## 6. Durante el conflicto de la Parte H, ¿qué representaba el contenido entre <<<<<<< HEAD y =======? ¿Y entre ======= y >>>>>>>?

Entre <<<<<<< HEAD y ======= aparecía la versión que ya tenía la rama actual, que en nuestro caso era main.

Entre ======= y >>>>>>> aparecía la versión que procedía de la rama que estábamos intentando fusionar.

Para resolver el conflicto eliminamos los marcadores y dejamos una versión final del contenido.

## 7. ¿Por qué NO se debe hacer git commit --amend sobre un commit que ya se subió con git push?

Porque git commit --amend reescribe el commit y genera un hash nuevo.

Si el commit ya ha sido compartido en GitHub, otras personas pueden tener el commit anterior y se producirían historiales distintos y problemas de sincronización.

## 8. Si borras por accidente la carpeta .git de tu proyecto, ¿qué se pierde exactamente? ¿Se pierde también el código fuente que está en el disco?

Se pierde la información interna del repositorio Git: commits, branches, configuración e historial local.

Los archivos normales del proyecto que están en el Working Directory no se borran por eliminar .git, pero la carpeta dejaría de comportarse como ese repositorio Git.

## 9. Explica con tus propias palabras la diferencia entre Git y GitHub, sin usar la palabra "nube".

Git es un programa de control de versiones que funciona en mi ordenador y permite crear commits, branches, merges y consultar el historial.

GitHub es una plataforma que permite alojar repositorios Git en un servidor y facilita compartirlos y trabajar con otras personas.

Git puede utilizarse localmente sin GitHub.

## 10. ¿Por qué no se debe subir un archivo .env con contraseñas reales a un repositorio, aunque el repositorio sea privado?

Porque una contraseña o clave incluida en un repositorio puede quedar almacenada en el historial y ser accesible posteriormente.

Las credenciales reales no deben versionarse. Se debe utilizar .gitignore y, si es necesario, un archivo de ejemplo sin secretos reales.

## 11. Un compañero te dice: "hice push y ahora GitHub me rechaza el segundo push con non-fast-forward". ¿Qué ha ocurrido probablemente y qué comando ejecutarías primero?

Probablemente el repositorio remoto contiene commits que todavía no existen en su repositorio local.

Primero ejecutaría:

git pull

para traer y combinar los cambios remotos. Después resolvería cualquier conflicto si fuera necesario y finalmente volvería a ejecutar git push.

## 12. ¿Qué tipo de Conventional Commit usarías para añadir un índice de rendimiento a una tabla, corregir una restricción mal definida y actualizar el README?

Para añadir un índice de rendimiento utilizaría:

perf:

porque se trata de una mejora relacionada con el rendimiento.

Para corregir una restricción mal definida utilizaría:

fix:

porque se está corrigiendo un error.

Para actualizar README.md utilizaría:

docs:

porque se trata de un cambio de documentación.