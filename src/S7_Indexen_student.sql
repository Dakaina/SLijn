-- ------------------------------------------------------------------------
-- Data & Persistency
-- Opdracht S7: Indexen
--
-- (c) 2020 Hogeschool Utrecht
-- Tijmen Muller (tijmen.muller@hu.nl)
-- André Donk (andre.donk@hu.nl)
-- ------------------------------------------------------------------------
-- LET OP, zoals in de opdracht op Canvas ook gezegd kun je informatie over
-- het query plan vinden op: https://www.postgresql.org/docs/current/using-explain.html


-- S7.1.
--
-- Je maakt alle opdrachten in de 'sales' database die je hebt aangemaakt en gevuld met
-- de aangeleverde data (zie de opdracht op Canvas).
--
-- Voer het voorbeeld uit wat in de les behandeld is:
-- 1. Voer het volgende EXPLAIN statement uit:
--    EXPLAIN SELECT * FROM order_lines WHERE stock_item_id = 9;
--    Bekijk of je het resultaat begrijpt. Kopieer het explain plan onderaan de opdracht
"Gather  (cost=1000.00..11303.54 rows=2020 width=96)"
"  Workers Planned: 2"
"  ->  Parallel Seq Scan on order_lines  (cost=0.00..10101.54 rows=842 width=96)"
"        Filter: (stock_item_id = 9)"
-- 2. Voeg een index op stock_item_id toe:
--    CREATE INDEX ord_lines_si_id_idx ON order_lines (stock_item_id);
-- 3. Analyseer opnieuw met EXPLAIN hoe de query nu uitgevoerd wordt
--    Kopieer het explain plan onderaan de opdracht
"Bitmap Heap Scan on order_lines  (cost=24.08..4611.35 rows=2020 width=96)"
"  Recheck Cond: (stock_item_id = 9)"
"  ->  Bitmap Index Scan on ord_lines_si_id_idx  (cost=0.00..23.57 rows=2020 width=0)"
"        Index Cond: (stock_item_id = 9)"
-- 4. Verklaar de verschillen. Schrijf deze hieronder op.
Zonder index zoekt het in een parallel sequential scan (door hele tabel heen zoeken voor rows waar stock item id 9 is).
Totale cost is 11303.54

Index scan zoekt eerst de posities in een Index en daarna worden die posities opgehaald uit de tabel
Totale cost is 4611.35 en dat is best wat lager dan zonder index.
-- S7.2.
--
-- 1. Maak de volgende twee query’s:
-- 	  A. Toon uit de order tabel de order met order_id = 73590
    "Index Scan using pk_sales_orders on orders  (cost=0.29..8.31 rows=1 width=155)"
"  Index Cond: (order_id = 73590)"
-- 	  B. Toon uit de order tabel de order met customer_id = 1028
    "Seq Scan on orders  (cost=0.00..1819.94 rows=107 width=155)"
"  Filter: (customer_id = 1028)"
-- 2. Analyseer met EXPLAIN hoe de query’s uitgevoerd worden en kopieer het explain plan onderaan de opdracht
-- 3. Verklaar de verschillen en schrijf deze op
    orders is een primary key en dus krijgt het bij het maken van de tabel automatisch ook een index.
    customer_id heeft geen index en dus wordt het gezocht via een sequential scan
-- 4. Voeg een index toe, waarmee query B versneld kan worden
    CREATE INDEX inx_customer_id ON orders (customer_id);
-- 5. Analyseer met EXPLAIN en kopieer het explain plan onder de opdracht
    "Bitmap Heap Scan on orders  (cost=5.12..308.96 rows=107 width=155)"
"  Recheck Cond: (customer_id = 1028)"
"  ->  Bitmap Index Scan on inx_customer_id  (cost=0.00..5.10 rows=107 width=0)"
"        Index Cond: (customer_id = 1028)"
-- 6. Verklaar de verschillen en schrijf hieronder op
Zonder index is de totale cost 1819.94 en met index is het 308.96 dus het kost veel minder
om de passende resultaten te vinden. Het enige wat iets meer kost is het opstarten
bij een index (5.12 vergeleken met 0.00) maar in het algemeen wint het nogsteeds.

-- S7.3.A
--
-- Het blijkt dat customers regelmatig klagen over trage bezorging van hun bestelling.
-- Het idee is dat verkopers misschien te lang wachten met het invoeren van de bestelling in het systeem.
-- Daar willen we meer inzicht in krijgen.
-- We willen alle orders (order_id, order_date, salesperson_person_id (als verkoper),
--    het verschil tussen expected_delivery_date en order_date (als levertijd),  
--    en de bestelde hoeveelheid van een product zien (quantity uit order_lines).
-- Dit willen we alleen zien voor een bestelde hoeveelheid van een product > 250
--   (we zijn nl. als eerste geïnteresseerd in grote aantallen want daar lijkt het vaker mis te gaan)
-- En verder willen we ons focussen op verkopers wiens bestellingen er gemiddeld langer over doen.
-- De meeste bestellingen kunnen binnen een dag bezorgd worden, sommige binnen 2-3 dagen.
-- Het hele bestelproces is er op gericht dat de gemiddelde bestelling binnen 1.45 dagen kan worden bezorgd.
-- We willen in onze query dan ook alleen de verkopers zien wiens gemiddelde levertijd 
--  (expected_delivery_date - order_date) over al zijn/haar bestellingen groter is dan 1.45 dagen.
-- Maak om dit te bereiken een subquery in je WHERE clause.
-- Sorteer het resultaat van de hele geheel op levertijd (desc) en verkoper.
-- 1. Maak hieronder deze query (als je het goed doet zouden er 377 rijen uit moeten komen, en het kan best even duren...)

SELECT
    o.order_id,
    o.order_date,
    o.salesperson_person_id as verkoper,
    o.expected_delivery_date - o.order_date as levertijd,
    ol.quantity
FROM
    orders o
JOIN
    order_lines ol ON o.order_id = ol.order_id
WHERE
    quantity > 250 AND o.salesperson_person_id IN
                       (SELECT salesperson_person_id
                        FROM orders
                        GROUP BY salesperson_person_id
                        HAVING avg(expected_delivery_date - order_date) > 1.45)
ORDER BY levertijd desc, verkoper;


-- S7.3.B
--
-- 1. Vraag het EXPLAIN plan op van je query (kopieer hier, onder de opdracht)
    "Gather Merge  (cost=9723.72..9750.79 rows=232 width=20)"
"  Workers Planned: 2"
"  ->  Sort  (cost=8723.70..8723.99 rows=116 width=20)"
"        Sort Key: ((o.expected_delivery_date - o.order_date)) DESC, o.salesperson_person_id"
"        ->  Hash Join  (cost=2188.42..8719.72 rows=116 width=20)"
"              Hash Cond: (o.salesperson_person_id = orders.salesperson_person_id)"
"              ->  Nested Loop  (cost=0.29..6529.85 rows=386 width=20)"
"                    ->  Parallel Seq Scan on order_lines ol  (cost=0.00..5051.27 rows=386 width=8)"
"                          Filter: (quantity > 250)"
"                    ->  Index Scan using pk_sales_orders on orders o  (cost=0.29..3.83 rows=1 width=16)"
"                          Index Cond: (order_id = ol.order_id)"
"              ->  Hash  (cost=2188.09..2188.09 rows=3 width=4)"
"                    ->  HashAggregate  (cost=2187.91..2188.06 rows=3 width=4)"
"                          Group Key: orders.salesperson_person_id"
"                          Filter: (avg((orders.expected_delivery_date - orders.order_date)) > 1.45)"
"                          ->  Seq Scan on orders  (cost=0.00..1635.95 rows=73595 width=12)"
-- 2. Kijk of je met 1 of meer indexen de query zou kunnen versnellen
CREATE INDEX idx_quantity ON order_lines (quantity)
-- 3. Maak de index(en) aan en run nogmaals het EXPLAIN plan (kopieer weer onder de opdracht)
"Sort  (cost=6471.64..6472.34 rows=278 width=20)"
"  Sort Key: ((o.expected_delivery_date - o.order_date)) DESC, o.salesperson_person_id"
"  ->  Hash Join  (cost=4380.28..6460.36 rows=278 width=20)"
"        Hash Cond: (o.order_id = ol.order_id)"
"        ->  Hash Join  (cost=2188.13..4099.15 rows=22078 width=16)"
"              Hash Cond: (o.salesperson_person_id = orders.salesperson_person_id)"
"              ->  Seq Scan on orders o  (cost=0.00..1635.95 rows=73595 width=16)"
"              ->  Hash  (cost=2188.09..2188.09 rows=3 width=4)"
"                    ->  HashAggregate  (cost=2187.91..2188.06 rows=3 width=4)"
"                          Group Key: orders.salesperson_person_id"
"                          Filter: (avg((orders.expected_delivery_date - orders.order_date)) > 1.45)"
"                          ->  Seq Scan on orders  (cost=0.00..1635.95 rows=73595 width=12)"
"        ->  Hash  (cost=2180.58..2180.58 rows=926 width=8)"
"              ->  Bitmap Heap Scan on order_lines ol  (cost=11.47..2180.58 rows=926 width=8)"
"                    Recheck Cond: (quantity > 250)"
"                    ->  Bitmap Index Scan on idx_quantity  (cost=0.00..11.24 rows=926 width=0)"
"                          Index Cond: (quantity > 250)"
-- 4. Wat voor verschillen zie je? Verklaar hieronder.
Totale cost is omlaag gegaan van 9750.79 naar 6472.34
Er is nu een index scan bij de quantity check door het aanmaken van idx_quantity
Index scan van orders o is nu sequential geworden. Hoewel de index scan origineel wel minder kostte
is met onze nieuwe index het toch slomer. De total cost van de parent is van 6529.85 naar 2188.06 gegaan

-- S7.3.C
--
-- Zou je de query ook heel anders kunnen schrijven om hem te versnellen?
Ik zou zeggen misschien een materialized view aanmaken van de subquery maar
dat zou je wel constant moeten updaten elke keer dat er een nieuwe row in tabel order komt.
Dit bespaart zo een 1000 aan totale kosten.
View:
CREATE MATERIALIZED VIEW gmd_salesperson AS SELECT salesperson_person_id
                                            FROM orders
                                            GROUP BY salesperson_person_id
                                            HAVING avg(expected_delivery_date - order_date) > 1.45;
Query:
SELECT
    o.order_id,
    o.order_date,
    o.salesperson_person_id as verkoper,
    o.expected_delivery_date - o.order_date as levertijd,
    ol.quantity
FROM
    gmd_salesperson gmd
    orders o
JOIN
    order_lines ol ON o.order_id = ol.order_id
WHERE
    quantity > 250 AND o.salesperson_person_id = gmd.salesperson_person_id
ORDER BY levertijd desc, verkoper;

