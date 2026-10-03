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


-- 7 --------
-- Crie a tabela staging.cardapio com as colunas item (VARCHAR(20), chave primária), price
-- (NUMERIC(6,2) NOT NULL) e category (VARCHAR(10) NOT NULL) e insira nela as oito linhas
-- da Tabela 3.

DROP TABLE IF EXISTS staging.cardapio CASCADE;

CREATE TABLE staging.cardapio(
    item VARCHAR(20) PRIMARY KEY,
    price NUMERIC(6,2) NOT NULL,
    category VARCHAR(10) NOT NULL
)

INSERT INTO staging.cardapio
    (item, price, category)
    VALUES
    ('COOKIE', 1.00, 'Comida'), ('TEA', 1.50, 'Bebida'), ('COFFEE', 2.00, 'Bebida'), 
    ('CAKE', 3.00, 'Comida'), ('JUICE', 3.00, 'Bebida'), ('SANDWICH', 4.00, 'Comida'), 
    ('SMOOTHIE', 4.00, 'Bebida'), ('SALAD', 5.00, 'Comida');

    -- 8 --
-- Aplique à tabela staging.cafe_tipada as regras da Tabela 7, na ordem indicada, com
-- um UPDATE por regra (a R6 pode usar dois). Use subconsultas sobre staging.cardapio
-- nas regras R1 e R5. Abaixo de cada UPDATE, registre em comentário a quantidade de linhas
-- afetadas informada pelo pgAdmin.

--R1--
UPDATE staging.cafe_tipada as cafe
SET price_per_unit = cardapio.price
FROM staging.cardapio
WHERE cafe.item = cardapio.item AND cafe.price_per_unit IS NULL AND cafe.item IS NOT NULL;
-- 479 LINHAS ALTERADAS.

--R2
UPDATE staging.cafe_tipada
SET price_per_unit = total_spent / quantity
WHERE price_per_unit IS NULL AND total_spent IS NOT NULL AND quantity IS NOT NULL AND quantity <> 0;
-- 48 LINHAS ALTERADAS.

--R3
UPDATE staging.cafe_tipada
SET quantity = ROUND(total_spent / price_per_unit)
WHERE quantity IS NULL AND price_per_unit IS NOT NULL AND total_spent IS NOT NULL;
-- 456 LINHAS ALTERADAS.

--R4
UPDATE staging.cafe_tipada
SET total_spent = quantity * price_per_unit
WHERE total_spent IS NULL AND quantity IS NOT NULL AND price_per_unit IS NOT NULL;
-- 479 LINHAS ALTERADAS.

--R5
UPDATE staging.cafe_tipada AS cafe
SET item = cardapio_temp.item
FROM (
    SELECT price, MIN(item) AS item
    FROM staging.cardapio
    GROUP BY price
    HAVING COUNT(*) = 1
) AS cardapio_temp
WHERE cafe.price_per_unit = cardapio_temp.price
  AND cafe.item IS NULL;
-- 489 LINHAS ALTERADAS.

--R6
UPDATE staging.cafe_tipada
SET payment_method = 'UNKNOWN'
WHERE payment_method IS NULL;
UPDATE staging.cafe_tipada
SET location = 'UNKNOWN'
WHERE location IS NULL;

-- 3178 LINHAS ALTERADAS.
-- 3961 LINHAS ALTERADAS.
-- -- TOTAL DE LINHAS ALTERADAS PELA R6: 7139


-- ENUNCIADO 9 -----------------
-- Crie staging.cafe_sales com as mesmas colunas e tipos da Tabela 6, agora com NOT NULL
-- em todas elas e com as restrições CHECK (quantity > 0) e CHECK (price_per_unit > 0).
-- Carregue-a, precedida de TRUNCATE, apenas com as linhas de staging.cafe_tipada que
-- não têm nenhum valor nulo. Escreva então uma consulta que devolva, em uma única linha,
-- três colunas: linhas_tipada, linhas_limpas e descartadas. Registre os três números em
-- comentário.

DROP TABLE if EXISTS staging.cafe_sales;
CREATE TABLE staging.cafe_sales (
    transaction_id   VARCHAR(20) NOT NULL,
    item             TEXT NOT NULL,
    quantity         INTEGER NOT NULL CHECK (quantity > 0),
    price_per_unit   NUMERIC NOT NULL CHECK (price_per_unit > 0),
    total_spent      NUMERIC NOT NULL,
    payment_method   TEXT NOT NULL,
    location         TEXT NOT NULL,
    transaction_date DATE NOT NULL
);

TRUNCATE TABLE staging.cafe_sales;

INSERT INTO staging.cafe_sales (
    transaction_id,
    item,
    quantity,
    price_per_unit,
    total_spent,
    payment_method,
    location,
    transaction_date
)
SELECT 
    transaction_id,
    item,
    quantity,
    price_per_unit,
    total_spent,
    payment_method,
    location,
    transaction_date
FROM staging.cafe_tipada
WHERE transaction_id IS NOT NULL
  AND item IS NOT NULL
  AND quantity IS NOT NULL
  AND price_per_unit IS NOT NULL
  AND total_spent IS NOT NULL
  AND payment_method IS NOT NULL
  AND location IS NOT NULL
  AND transaction_date IS NOT NULL;

SELECT 
(SELECT COUNT(*) FROM staging.cafe_tipada) AS linhas_tipada,
(SELECT COUNT(*) FROM staging.cafe_sales)  AS linhas_limpas,
(SELECT COUNT(*) AS descartadas
FROM staging.cafe_tipada
WHERE transaction_id NOT IN (
    SELECT transaction_id 
    FROM staging.cafe_sales)
);

-- -- 10 ----------------
-- Consulte a menor e a maior data de venda registradas em staging.cafe_sales. Em seguida,
-- crie dw.dim_date com as colunas da Figura 4 (date_sk inteiro no formato YYYYMMDD) e
-- carregue-a com generate_series, gerando todos os dias dos anos completos que cobrem
-- esse intervalo. Confira a quantidade de linhas geradas.

SELECT min(transaction_date) FROM cafe_sales

SELECT max(transaction_date) FROM cafe_sales

SELECT d
FROM generate_series(
        (SELECT min(transaction_date) FROM cafe_sales),
        (SELECT max(transaction_date) FROM cafe_sales),
        INTERVAL '1 day'
    ) g(d);

DROP TABLE IF EXISTS dw.dim_date CASCADE;
CREATE TABLE dw.dim_date(
    date_sk INTEGER PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    day SMALLINT NOT NULL,
    month SMALLINT NOT NULL,
    month_name VARCHAR(15) NOT NULL,
    quarter SMALLINT NOT NULL,
    year SMALLINT NOT NULL,
    day_of_week VARCHAR(15) NOT NULL,
    is_weekend BOOLEAN NOT NULL);


INSERT INTO dw.dim_date
SELECT 
    CAST(TO_CHAR(d, 'YYYYMMDD') AS INTEGER),
    d::DATE,
    EXTRACT(DAY FROM d)::SMALLINT,
    EXTRACT(MONTH FROM d)::SMALLINT,
    TO_CHAR(d, 'TMMONTH'),
    EXTRACT(QUARTER FROM d)::SMALLINT,
    EXTRACT(YEAR FROM d)::SMALLINT,
    TO_CHAR(d, 'TMDAY'),
    EXTRACT(DOW FROM d) IN(0, 6)
    FROM generate_series(
        (SELECT min(transaction_date) FROM cafe_sales),
        (SELECT max(transaction_date) FROM cafe_sales),
        INTERVAL '1 day'
    ) g(d);

-- CONFERENCIA
SELECT * FROM dw.dim_date

-- -- 11 --------------
-- Crie e carregue dw.dim_item, dw.dim_payment e dw.dim_location, com chaves SERIAL e
-- atributos descritivos UNIQUE. A carga usa DISTINCT sobre staging.cafe_sales; a category
-- de dim_item vem de staging.cardapio. Confira as três dimensões em uma única consulta
-- com UNION ALL: esperam-se 8 itens, 4 formas de pagamento e 3 locais, já incluído o valor
-- 'Unknown'.

DROP TABLE IF EXISTS dw.dim_item CASCADE;
CREATE TABLE dw.dim_item(
    item_sk SERIAL PRIMARY KEY,
    item VARCHAR (200) NOT NULL UNIQUE,
    category VARCHAR(40) NOT NULL);
INSERT INTO dw.dim_item(item,category)
SELECT DISTINCT item, category FROM staging.cardapio;


DROP TABLE IF EXISTS dw.dim_payment CASCADE;
CREATE TABLE dw.dim_payment(
payment_sk SERIAL PRIMARY KEY,
payment VARCHAR (100) NOT NULL UNIQUE);
INSERT INTO dw.dim_payment(payment)
SELECT DISTINCT payment_method FROM staging.cafe_sales;


DROP TABLE IF EXISTS dw.dim_location CASCADE;
CREATE TABLE dw.dim_location(
location_sk SERIAL PRIMARY KEY,
location VARCHAR (200) NOT NULL UNIQUE);
INSERT INTO dw.dim_location(location)
SELECT DISTINCT location FROM staging.cafe_sales;

--// CONFERENCIA
SELECT 'dim_item' AS dimensao, 
COUNT(*) AS total_registros
FROM dw.dim_item 
UNION ALL
SELECT 'dim_payment' AS dimensao, 
COUNT(*) AS total_registros
FROM dw.dim_payment
UNION ALL
SELECT 'dim_location' AS dimensao, 
COUNT(*) AS total_registros
FROM dw.dim_location;

-- --------------- 12 ------------------------
-- Crie dw.fact_sales conforme a Figura 4: transaction_nk como chave primária (dimensão
-- degenerada), chaves estrangeiras NOT NULL para as quatro dimensões, métricas NOT NULL e
-- um índice por chave estrangeira. Carregue-a a partir de staging.cafe_sales, precedida de
-- TRUNCATE: date_sk por formatação da data, sem JOIN; as outras três surrogate keys por JOIN
-- com as dimensões. Por fim, escreva uma consulta que compare, lado a lado, a quantidade de
-- linhas e a soma de total_spent da staging e da fato. Os dois pares devem ser iguais.

DROP TABLE IF EXISTS dw.fact_sales CASCADE;
 
CREATE TABLE dw.fact_sales (
    transaction_nk VARCHAR(20) PRIMARY KEY,
    date_sk INTEGER NOT NULL REFERENCES dw.dim_date(date_sk),
    item_sk INTEGER NOT NULL REFERENCES dw.dim_item(item_sk),
    payment_sk INTEGER NOT NULL REFERENCES dw.dim_payment(payment_sk),
    location_sk INTEGER NOT NULL REFERENCES dw.dim_location(location_sk),
    quantity INTEGER NOT NULL,
    price_per_unit NUMERIC(6,2) NOT NULL,
    total_spent NUMERIC(8,2) NOT NULL
);
 
-- 2. Índices das Chaves Estrangeiras
CREATE INDEX idx_fact_sales_date ON dw.fact_sales(date_sk);
CREATE INDEX idx_fact_sales_item ON dw.fact_sales(item_sk);
CREATE INDEX idx_fact_sales_payment ON dw.fact_sales(payment_sk);
CREATE INDEX idx_fact_sales_location ON dw.fact_sales(location_sk);
 
-- 3. Limpeza
TRUNCATE TABLE dw.fact_sales;
 
-- 4. Carga da Fato
INSERT INTO dw.fact_sales (
    transaction_nk,
    date_sk,
    item_sk,
    payment_sk,
    location_sk,
    quantity,
    price_per_unit,
    total_spent
)
SELECT
    s.transaction_id AS transaction_nk,
    CAST(TO_CHAR(s.transaction_date, 'YYYYMMDD') AS INTEGER) AS date_sk,
    i.item_sk,
    p.payment_sk,
    l.location_sk,
    s.quantity,
    s.price_per_unit,
    s.total_spent
FROM staging.cafe_sales s
JOIN dw.dim_item i     ON i.item = s.item
JOIN dw.dim_payment p  ON p.payment = s.payment_method
JOIN dw.dim_location l ON l.location = s.location;
 
-- 5. Validação Staging vs Fato
SELECT
    staging.qtd_staging,
    fato.qtd_fato,
    staging.total_spent_s,
    fato.total_fato_f
FROM
    (SELECT COUNT(*) AS qtd_staging, SUM(total_spent) AS total_spent_s FROM staging.cafe_sales) staging,
    (SELECT COUNT(*) AS qtd_fato, SUM(total_spent) AS total_fato_f FROM dw.fact_sales) fato;


-- 13 ---------------
