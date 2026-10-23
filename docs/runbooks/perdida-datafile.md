# Runbook: pérdida de un datafile en Oracle

## Síntomas y alcance
ORA-01116 indica un error de acceso al archivo, ORA-01110 identifica el datafile y ORA-27041 señala el fallo del sistema operativo. ORA-63999 puede indicar que Oracle ha cerrado la PDB afectada.

## Diagnóstico
1. Confirmar el archivo afectado mediante V$DATAFILE, el alert log y los mensajes ORA.
2. Comprobar que la base está en ARCHIVELOG y que existe una copia RMAN del archivo.
3. Ejecutar en RMAN: LIST BACKUP OF DATAFILE n;
4. Comprobar el estado de FREEPDB1 en V$PDBS y avisar al DBA responsable.
5. No borrar otros archivos ni reiniciar la instancia sin diagnosticar el alcance.

## Recuperación
Si FREEPDB1 sigue abierta, aislar el archivo:
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER DATABASE DATAFILE n OFFLINE;

Si Oracle ha cerrado la PDB, esperar a que quede completamente MOUNTED.

Desde RMAN conectado como SYSDBA:
RESTORE DATAFILE n;
RECOVER DATAFILE n;

Después, desde SQL*Plus:
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER DATABASE DATAFILE n ONLINE;

Si FREEPDB1 sigue MOUNTED, abrirla desde CDB$ROOT:
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;

## Verificación
- Confirmar FREEPDB1 en READ WRITE y el datafile ONLINE.
- Comprobar los datos de negocio afectados.
- Revisar el alert log y registrar RTO y RPO.
- Comunicar la restauración y documentar la causa.

## Resultado observado en el Laboratorio 5
En el simulacro 14D: RPO = 0; recuperación del archivo = 15 s; recuperación desde el fallo = 16 s.
El archivo se restauró mediante RMAN y se conservaron los 20.000 estudiantes.
