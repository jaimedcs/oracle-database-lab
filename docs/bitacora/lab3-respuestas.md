# Respuestas de comprobación — Lab 3 Instalación del Entorno Oracle

Alumno: Jaime De Castro

## Docker
### 1. ¿Qué diferencia hay entre una imagen y un contenedor?

Una imagen es una plantilla inmutable que contiene el sistema de archivos, dependencias y configuración necesaria para crear un entorno. Un contenedor es una instancia en ejecución de esa imagen, con su propio estado y procesos.

### 2. ¿Qué ocurre cuando ejecutamos un contenedor con un volumen asociado?

El volumen permite guardar datos fuera del ciclo de vida del contenedor. Si el contenedor se elimina o se vuelve a crear, la información almacenada en el volumen permanece.

### 3. ¿Por qué publicamos puertos al crear el contenedor Oracle?

Porque el servicio Oracle dentro del contenedor está aislado. Al publicar el puerto podemos acceder desde fuera del contenedor, por ejemplo con SQL Developer, SQLcl u ORDS.

### 4. ¿Qué diferencia hay entre parar un contenedor y eliminarlo?

Parar un contenedor detiene sus procesos pero mantiene su configuración y datos asociados. Eliminarlo borra el contenedor, aunque los datos permanecen si están en un volumen persistente.

## Git, organización y evidencia
### 5. ¿Por qué trabajamos con una rama propia en lugar de hacerlo directamente sobre main?

Porque permite aislar los cambios del laboratorio, revisarlos antes de integrarlos y mantener la rama principal protegida.

### 6. ¿Qué información aporta un commit bien escrito?

Describe de forma clara qué cambio se ha realizado y permite seguir la evolución del proyecto. También facilita la revisión por otros miembros del equipo.

### 7. ¿Para qué sirven las evidencias generadas durante la práctica?

Sirven para demostrar que cada paso se ha ejecutado correctamente y permiten revisar el proceso sin tener que repetirlo.

### 8. ¿Por qué usamos nombres con fecha y hora en los archivos de evidencia?

Porque permiten identificar cuándo se generó cada evidencia, evitar duplicados y mantener un orden cronológico.
## Seguridad
### 9. ¿Por qué no se debe guardar una contraseña real dentro de Git?

Porque Git guarda el historial de cambios y una contraseña podría recuperarse aunque después se elimine del archivo actual. Los secretos deben mantenerse fuera del repositorio.

### 10. ¿Qué archivo utilizamos para guardar las contraseñas y por qué no se versiona?

Utilizamos `config/.env` para almacenar los secretos y está incluido en `.gitignore` para impedir que Git lo añada al repositorio.

### 11. ¿Qué comprobación realizamos para verificar que el secreto está protegido?

Ejecutamos `git check-ignore -v config/.env` para comprobar que Git está ignorando correctamente el archivo.

### 12. ¿Qué información sensible no debe aparecer nunca en el repositorio?

No deben aparecer contraseñas reales de SYS/SYSTEM, ALUMNO o ORDS_PUBLIC_USER, ni ningún archivo que contenga secretos.
## Oracle y herramientas
### 13. ¿Qué es un PDB en Oracle?

Un PDB (Pluggable Database) es una base de datos conectable dentro de una CDB (Container Database). En esta práctica trabajamos con el PDB `FREEPDB1`.

### 14. ¿Qué usuario utilizamos para administrar Oracle durante la instalación?

Utilizamos el usuario SYS con privilegios de SYSDBA para realizar tareas administrativas como crear usuarios, tablespaces y configurar la base de datos.

### 15. ¿Para qué sirven las migraciones V000 y V001?

La migración V000 crea los tablespaces y usuarios aislados de los cinco entornos de negocio. La migración V001 crea las tablas, índices y estructuras necesarias dentro de esos esquemas.

### 16. ¿Qué función tiene SQLcl?

SQLcl es una herramienta de línea de comandos de Oracle que permite conectarse a la base de datos y ejecutar consultas y scripts SQL.

### 17. ¿Qué función tiene ORDS?

ORDS (Oracle REST Data Services) permite exponer servicios web sobre Oracle y proporciona la interfaz Database Actions accesible desde el navegador.

### 18. ¿Qué comprobamos con Database Actions?

Comprobamos que ORDS funciona correctamente, que el usuario ALUMNO está habilitado y que la conexión se realiza sobre el PDB correcto (`FREEPDB1`).
## Entorno de trabajo
### 19. ¿Por qué usamos WSL 2 con Ubuntu en esta práctica?

Porque proporciona un entorno Linux real dentro de Windows, similar al utilizado en servidores profesionales, permitiendo trabajar con herramientas como Docker, Git y ShellCheck.

### 20. ¿Por qué es importante definir las variables del entorno en un único archivo?

Porque evita repetir valores manualmente, reduce errores y permite reutilizar la misma configuración en todos los scripts.

### 21. ¿Qué ventaja aporta automatizar la instalación mediante scripts?

Permite repetir el despliegue de forma consistente, documentada y reproducible, evitando depender de pasos manuales.

### 22. ¿Qué comprobaciones finales realizamos antes de entregar?

Comprobamos que Docker, Oracle, ORDS, Java, SQLcl y las evidencias funcionan correctamente, además de verificar que los secretos están protegidos y que el repositorio está preparado para la entrega.
