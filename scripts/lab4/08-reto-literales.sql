WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 160 PAGESIZE 60
COLUMN ejemplo FORMAT A65
SELECT force_matching_signature,
       COUNT(DISTINCT sql_id) AS cursores,
       SUM(executions) AS ejecuciones,
       MIN(SUBSTR(sql_text,1,65)) AS ejemplo
FROM v$sql
WHERE force_matching_signature <> 0
GROUP BY force_matching_signature
HAVING COUNT(DISTINCT sql_id) > 50
ORDER BY cursores DESC
FETCH FIRST 10 ROWS ONLY;
EXIT
