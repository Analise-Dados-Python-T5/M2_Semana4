# Vitrine — pacote técnico para a gravação (DW/DL, ETL/ELT, Modelagem Dimensional)

Pacote de dados e scripts para rodar AO VIVO na gravação do vídeo de 2h30, seguindo
o roteiro de 6 blocos que você já desenhou (OLTP/OLAP → Data Lake/ETL/ELT →
Star Schema → Snowflake → Redshift/BigQuery → Desafio final). Uma única base
fictícia — a loja **Vitrine** — conecta todas as demonstrações.

Ambiente usado: **PostgreSQL local** (já testado neste pacote com PostgreSQL 16).
Tudo foi rodado de ponta a ponta para garantir que executa sem erro — os números
reais de cada consulta estão em `docs/resultados_esperados.md`.

## Estrutura

```
vitrine-dw/
├── raw/            # "entrada do Data Lake": arquivos brutos, com os 3 problemas propositais
│   ├── produtos.csv     (1 produto duplicado: id 101 e 118)
│   ├── clientes.csv
│   ├── lojas.csv
│   ├── vendas.csv       (datas em 2 formatos; 1 linha com valor ausente)
│   └── pagamentos.json  (semiestruturado, aninhado)
├── processed/      # saída do script Python de limpeza (demonstração ETL, Bloco 2)
│   ├── produtos_tratado.csv
│   ├── mapa_produtos_duplicados.csv
│   └── vendas_tratada.csv
├── scripts/        # Python
│   ├── 01_gerar_dados_brutos.py   # gera tudo que está em raw/ (seed fixa, reprodutível)
│   └── 02_tratar_dados.py         # ETL: lê raw/, corrige, grava em processed/
├── sql/            # SQL, um arquivo por bloco do roteiro
│   ├── 00_oltp_olap_demo.sql
│   ├── 01_staging_elt_load.sql
│   ├── 02_dw_star_schema.sql
│   ├── 03_consultas_negocio.sql
│   ├── 04_snowflake_schema.sql
│   └── 05_desafio_final.sql
├── diagrams/       # cole no dbdiagram.io para o Bloco 4 (comparação visual)
│   ├── star_schema.dbml
│   └── snowflake_schema.dbml
└── docs/
    └── resultados_esperados.md    # "gabarito": o que cada consulta deve devolver
```

## Como cada arquivo se encaixa no seu roteiro

| Bloco do roteiro | O que rodar | O que isso demonstra |
|---|---|---|
| 1 — OLTP x OLAP (20 min) | `sql/00_oltp_olap_demo.sql` | `UPDATE` pontual x `SELECT ... GROUP BY` agregado, lado a lado |
| 2 — Data Lake, ETL, ELT (30 min) | abrir `raw/*` na tela → rodar `scripts/02_tratar_dados.py` (ETL, Python) → rodar `sql/01_staging_elt_load.sql` (ELT, SQL) | os MESMOS 3 problemas resolvidos dos dois jeitos diferentes |
| 3 — Construindo o DW (35 min) | `sql/02_dw_star_schema.sql` → `sql/03_consultas_negocio.sql` | grão da fato, dimensões, 3 consultas de negócio |
| 4 — Star x Snowflake (25 min) | `sql/04_snowflake_schema.sql` + `diagrams/*.dbml` no dbdiagram.io | mesma pergunta, 1 join x 2 joins |
| 5 — Redshift/BigQuery (25 min) | fora deste pacote — ver observação abaixo | o mesmo modelo rodando em nuvem |
| 6 — Desafio final (15 min) | `sql/05_desafio_final.sql` | faturamento x lucro, por categoria |

> **Bloco 5 não tem script aqui de propósito**: é navegação pela interface
> real do Redshift/BigQuery, não algo para rodar localmente. Se quiser, o
> mesmo `sql/02_dw_star_schema.sql` roda quase sem alterações num desses
> ambientes (troque `serial` por `IDENTITY`/`GENERATE_UUID()` conforme a
> plataforma) — útil para mostrar "a mesma modelagem, plataforma diferente".

## Como rodar do zero (antes de gravar, uma vez)

```bash
# 1) Suba um Postgres local (ajuste usuário/senha conforme seu ambiente)
createdb vitrine

# 2) Gere os dados brutos (ou use os que já estão em raw/)
cd vitrine-dw
python3 scripts/01_gerar_dados_brutos.py

# 3) (opcional, Bloco 2 - ETL em Python) gere a versão tratada
python3 scripts/02_tratar_dados.py

# 4) Rode os blocos SQL em ordem -- SEMPRE a partir da raiz do projeto,
#    porque os \copy usam caminhos relativos (raw/arquivo.csv)
psql -h localhost -U postgres -d vitrine -f sql/00_oltp_olap_demo.sql
psql -h localhost -U postgres -d vitrine -f sql/01_staging_elt_load.sql
psql -h localhost -U postgres -d vitrine -f sql/02_dw_star_schema.sql
psql -h localhost -U postgres -d vitrine -f sql/03_consultas_negocio.sql
psql -h localhost -U postgres -d vitrine -f sql/04_snowflake_schema.sql
psql -h localhost -U postgres -d vitrine -f sql/05_desafio_final.sql
```

Para a gravação em si: rode tudo uma vez ANTES, confira contra
`docs/resultados_esperados.md`, e na hora de gravar pode tanto re-executar os
mesmos arquivos (`\i sql/02_dw_star_schema.sql` dentro do `psql`, por
exemplo) quanto colar os blocos de SQL um por um para controlar o ritmo —
cada arquivo já está comentado e dividido exatamente nos pontos onde o
roteiro sugere pausar.

## Os 3 problemas propositais nos dados (e onde cada um é resolvido)

1. **Produto duplicado** — `id_produto` 101 e 118 são o mesmo tênis, só que
   118 foi digitado errado ("tenis runner pro ", sem acento, minúsculo, com
   espaço sobrando). Resolvido em `scripts/02_tratar_dados.py` (Python/ETL)
   e, separadamente, em `sql/02_dw_star_schema.sql` (SQL/ELT) — mesma
   correção, dois caminhos, para o Bloco 2 comparar.
2. **Datas em dois formatos** — `vendas.csv` mistura `AAAA-MM-DD` (ISO) e
   `DD/MM/AAAA` (como um PDV mais antigo costuma exportar). Resolvido do
   mesmo jeito duplo acima.
3. **Valor ausente** — a venda `id_venda = 38` não tem `valor_unitario`. Em
   vez de inventar um número, o modelo preserva `NULL` e marca
   `status_qualidade = 'valor_ausente_revisar'` — bom gancho para falar de
   qualidade de dados sem transformar isso num bug escondido.

## Sobre o dinheiro: por que Eletrônicos puxa o Bloco 6

Os custos em `raw/produtos.csv` foram montados de propósito: a categoria
Eletrônicos vende muito (volume alto) mas tem margem apertada (~10%),
enquanto Calçados/Vestuário/Acessórios vendem menos mas com margem muito
melhor (53% a 65%). O resultado real (não forçado na consulta, só nos dados
de entrada) é que **Calçados lucra mais em reais do que Eletrônicos**, apesar
de faturar menos de um terço. Os números exatos estão em
`docs/resultados_esperados.md`.
