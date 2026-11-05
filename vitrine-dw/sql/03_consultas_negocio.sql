-- =============================================================================
-- BLOCO 3 (continuação) — Consultas de negócio sobre o Star Schema
-- =============================================================================
-- Três consultas, não dez conceitos abstratos. O mesmo modelo responde a
-- perguntas diferentes só mudando o agrupamento -- é a ideia a reforçar em
-- tela depois de rodar as três.
--
-- Rode com:  psql -h localhost -U postgres -d vitrine -f sql/03_consultas_negocio.sql
-- (depois de 02_dw_star_schema.sql)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) Faturamento por mês
-- -----------------------------------------------------------------------------
SELECT
    t.ano,
    t.mes,
    t.nome_mes,
    SUM(f.quantidade * COALESCE(f.valor_unitario, 0) - f.desconto) AS faturamento
FROM dw.fato_vendas f
JOIN dw.dim_tempo t ON f.sk_tempo = t.sk_tempo
GROUP BY t.ano, t.mes, t.nome_mes
ORDER BY t.ano, t.mes;

-- -----------------------------------------------------------------------------
-- 2) Os 5 produtos mais vendidos (por faturamento)
-- -----------------------------------------------------------------------------
SELECT
    p.nome_produto,
    p.categoria,
    SUM(f.quantidade) AS unidades_vendidas,
    SUM(f.quantidade * COALESCE(f.valor_unitario, 0) - f.desconto) AS faturamento
FROM dw.fato_vendas f
JOIN dw.dim_produto p ON f.sk_produto = p.sk_produto
GROUP BY p.nome_produto, p.categoria
ORDER BY faturamento DESC
LIMIT 5;

-- -----------------------------------------------------------------------------
-- 3) Clientes com maior valor total de compras
-- -----------------------------------------------------------------------------
SELECT
    c.nome_cliente,
    c.segmento,
    COUNT(*) AS numero_pedidos,
    SUM(f.quantidade * COALESCE(f.valor_unitario, 0) - f.desconto) AS valor_total
FROM dw.fato_vendas f
JOIN dw.dim_cliente c ON f.sk_cliente = c.sk_cliente
GROUP BY c.nome_cliente, c.segmento
ORDER BY valor_total DESC
LIMIT 10;

-- Fale em tela: "novo" compra pouco mas aparece bastante? "recorrente" domina
-- o topo? Deixe o resultado aparecer na tela antes de comentar.
