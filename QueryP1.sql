--Criando schemas se não existirem
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dw;

--Conferencia
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('raw', 'staging', 'dw');
