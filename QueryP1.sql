--Criando schemas se não existirem
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dw;

--Conferencia
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('raw', 'staging', 'dw');
---------------------------------------------
-- 2 --Crie a tabela raw.cafe_sales com as oito colunas da Tabela 1, todas do tipo TEXT, sem
--nenhuma restrição e na mesma ordem do arquivo CSV. Inicie o bloco com DROP TABLE IF
--EXISTS ... CASCADE.

DROP TABLE IF EXISTS raw.cafe_sales CASCADE;
CREATE TABLE raw.cafe_sales (
transaction_id TEXT,
item TEXT,
quantity TEXT,
price_per_unit TEXT,
total_spent TEXT,
payment_method TEXT,
location TEXT,
transaction_date TEXT
 );

-- 3 -----------
--Importe dirty_cafe_sales.csv para raw.cafe_sales com Import/Export Data… do
--pgAdmin (Format csv, Encoding UTF8, Header ligado, Delimiter vírgula). Registre em
--comentário as opções usadas e escreva duas consultas de validação: o total de linhas (10.000
--esperadas) e o total de valores distintos de transaction_id.

SELECT * FROM raw.cafe_sales;
SELECT COUNT(*) FROM raw.cafe_sales;
SELECT * FROM raw.cafe_sales LIMIT 3;

-- 4 ----------
-- Para cada uma das colunas item, payment_method e location da camada raw, escreva uma
-- consulta que liste cada valor distinto e a quantidade de linhas em que ele aparece, da maior
-- para a menor quantidade. Os valores NULL também devem aparecer.

SELECT DISTINCT item,  payment_method, location, COUNT(*) AS Qtd_linhas
FROM raw.cafe_sales
GROUP BY item, payment_method, location
ORDER BY Qtd_linhas DESC;

-- 5 ---------
-- Escreva uma única consulta, usando UNION ALL, que devolva uma linha para cada coluna
-- da camada raw, exceto transaction_id, com quatro colunas: coluna (o nome da coluna,
-- como texto), qtd_error, qtd_unknown e qtd_vazio (valor NULL ou texto vazio após TRIM).
-- O resultado terá sete linhas.

SELECT 'item' AS coluna,
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE item IS NULL) AS qtd_vazio,
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE UPPER(TRIM(item)) = 'UNKNOWN') AS qtd_unknown,
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE UPPER(TRIM(item)) = 'ERROR') AS qtd_error
 
UNION ALL
SELECT 'quantity',
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE quantity IS NULL),
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE UPPER(TRIM(quantity)) = 'UNKNOWN'),
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE UPPER(TRIM(quantity)) = 'ERROR')
 
UNION ALL
SELECT 'price_per_unit',
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE price_per_unit IS NULL),
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE UPPER(TRIM(price_per_unit)) = 'UNKNOWN'),
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE UPPER(TRIM(price_per_unit)) = 'ERROR')
 
UNION ALL
SELECT 'total_spent',
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE total_spent IS NULL),
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE UPPER(TRIM(total_spent)) = 'UNKNOWN'),
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE UPPER(TRIM(total_spent)) = 'ERROR')
 
UNION ALL
SELECT 'payment_method',
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE payment_method IS NULL),
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE UPPER(TRIM(payment_method)) = 'UNKNOWN'),
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE UPPER(TRIM(payment_method)) = 'ERROR')
 
UNION ALL
SELECT 'location',
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE location IS NULL),
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE UPPER(TRIM(location)) = 'UNKNOWN'),
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE UPPER(TRIM(location)) = 'ERROR')
 
UNION ALL
SELECT 'transaction_date',
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE transaction_date IS NULL),
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE UPPER(TRIM(transaction_date)) = 'UNKNOWN'),
  (SELECT COUNT(*) FROM raw.cafe_sales WHERE UPPER(TRIM(transaction_date)) = 'ERROR');
 

-- 6 --------
-- com um único INSERT ... SELECT, precedido de TRUNCATE. Em todas as colunas, aplique
-- TRIM e transforme '', 'ERROR' e 'UNKNOWN' em NULL antes de qualquer conversão; converta
-- as colunas numéricas com CAST e a data com TO_DATE no formato 'YYYY-MM-DD'. Em seguida,
-- escreva uma consulta que conte os NULL de cada coluna da tabela tipada. Para cada coluna,
-- o total deve ser igual à soma qtd_error + qtd_unknown + qtd_vazio obtida no Enunciado
-- 5.



DROP TABLE IF EXISTS staging.cafe_tipada CASCADE;
CREATE TABLE staging.cafe_tipada (
transaction_id VARCHAR(20) PRIMARY KEY,
item VARCHAR(20),
quantity INTEGER,
price_per_unit NUMERIC(6,2),
total_spent NUMERIC(8,2),
payment_method VARCHAR(20),
location VARCHAR(20),
transaction_date DATE
 );
 

TRUNCATE TABLE staging.cafe_tipada;
INSERT INTO staging.cafe_tipada(
transaction_id,
item,
quantity,
price_per_unit,
total_spent,
payment_method,
location,
transaction_date)
SELECT
    UPPER(TRIM(transaction_id)),
    CASE
        WHEN UPPER(TRIM(item)) IN ('', 'ERROR', 'UNKNOWN')
        THEN NULL ELSE UPPER(TRIM(item))
    END,
    CASE
        WHEN UPPER(TRIM(quantity)) IN ('', 'ERROR', 'UNKNOWN')
        THEN NULL 
        ELSE CAST(TRIM(quantity) AS INTEGER)
    END,
    CASE
        WHEN UPPER(TRIM(price_per_unit)) IN ('', 'ERROR', 'UNKNOWN')
        THEN NULL 
        ELSE CAST(TRIM(price_per_unit) AS NUMERIC(6,2))
    END,
    CASE
        WHEN UPPER(TRIM(total_spent)) IN ('', 'ERROR', 'UNKNOWN')
        THEN NULL 
        ELSE CAST(TRIM(total_spent) AS NUMERIC(8,2))
    END,
    CASE
        WHEN UPPER(TRIM(payment_method)) IN ('', 'ERROR', 'UNKNOWN')
        THEN NULL 
        ELSE UPPER(TRIM(payment_method))
    END,
    CASE
        WHEN UPPER(TRIM(location)) IN ('', 'ERROR', 'UNKNOWN')
        THEN NULL 
        ELSE UPPER(TRIM(location))
    END,
    CASE
        WHEN UPPER(TRIM(transaction_date)) IN ('', 'ERROR', 'UNKNOWN')
        THEN NULL 
        ELSE TO_DATE(TRIM(transaction_date), 'YYYY-MM-DD')
    END
FROM raw.cafe_sales
WHERE TRIM(transaction_id) NOT IN ('', 'ERROR', 'UNKNOWN')
  AND transaction_id IS NOT NULL;
 
 
-- CONTANDO VALORES NULOS
SELECT 
    COUNT(CASE WHEN transaction_id IS NULL THEN 1 END) 
    AS transaction_id_null,
    COUNT(CASE WHEN item IS NULL THEN 1 END)
    AS item_null,
    COUNT(CASE WHEN quantity IS NULL THEN 1 END) 
    AS quantity_null,
    COUNT(CASE WHEN price_per_unit IS NULL THEN 1 END) 
    AS price_per_unit_null,
    COUNT(CASE WHEN total_spent IS NULL THEN 1 END) 
    AS total_spent_null,
    COUNT(CASE WHEN payment_method IS NULL THEN 1 END)
    AS payment_method_null,
    COUNT(CASE WHEN location IS NULL THEN 1 END)
    AS location_null,
    COUNT(CASE WHEN transaction_date IS NULL THEN 1 END)
    AS transaction_date_null
FROM staging.cafe_tipada;

