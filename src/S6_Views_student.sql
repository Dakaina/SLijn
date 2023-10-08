-- ------------------------------------------------------------------------
-- Data & Persistency
-- Opdracht S6: Views
--
-- (c) 2020 Hogeschool Utrecht
-- Tijmen Muller (tijmen.muller@hu.nl)
-- André Donk (andre.donk@hu.nl)
-- ------------------------------------------------------------------------


-- S6.1.
--
-- 1. Maak een view met de naam "deelnemers" waarmee je de volgende gegevens uit de tabellen inschrijvingen en uitvoering combineert:
--    inschrijvingen.cursist, inschrijvingen.cursus, inschrijvingen.begindatum, uitvoeringen.docent, uitvoeringen.locatie
CREATE OR REPLACE VIEW deelnemers AS
SELECT i.cursist, i.cursus, i.begindatum, u.docent, u.locatie
FROM inschrijvingen i, uitvoeringen u;
-- 2. Gebruik de view in een query waarbij je de "deelnemers" view combineert met de "personeels" view (behandeld in de les):
--     CREATE OR REPLACE VIEW personeel AS
-- 	     SELECT mnr, voorl, naam as medewerker, afd, functie
--       FROM medewerkers;
--Weet niet precies waar je het mee gecombineerd wou hebben. cursist of docent dus voor cursist gekozen.
SELECT *
FROM deelnemers d
JOIN personeel l ON d.cursist = l.mnr;
-- 3. Is de view "deelnemers" updatable ? Waarom ?
Deelnemers is niet updatable want het bestaat uit 2 tables.
Om een view te kunnen updaten moet het uit 1 table bestaan.

-- S6.2.
--
-- 1. Maak een view met de naam "dagcursussen". Deze view dient de gegevens op te halen: 
--      code, omschrijving en type uit de tabel curssussen met als voorwaarde dat de lengte = 1. Toon aan dat de view werkt.
CREATE OR REPLACE VIEW dagcursussen AS
SELECT code, omschrijving, type
FROM cursussen
WHERE lengte = 1;
-- 2. Maak een tweede view met de naam "daguitvoeringen". 
--    Deze view dient de uitvoeringsgegevens op te halen voor de "dagcurssussen" (gebruik ook de view "dagcursussen"). Toon aan dat de view werkt
CREATE OR REPLACE VIEW daguitvoeringen AS
SELECT * from uitvoeringen
WHERE cursus IN (SELECT code FROM dagcursussen);
-- 3. Verwijder de views en laat zien wat de verschillen zijn bij DROP view <viewnaam> CASCADE en bij DROP view <viewnaam> RESTRICT
Resultaten:
-Bij het gebruiken van 'DROP VIEW dagcursussen CASCADE;' wordt niet alleen dagcursussen verwijdert
maar ook daguitvoeringen omdat die depend op het bestaan van dagcursussen.
-Bij het gebruiken van 'DROP VIEW dagcursussen RESTRICT;' wordt niks verwijderd omdat dagcursussen wordt gebruikt
in daguitvoeringen.
-Bij het gebruiken van 'DROP VIEW daguitvoeringen CASCADE;' wordt alleen daguitvoeringen verwijdert en niet dagcursussen
want dagcursussen depend niet op het bestaan van daguitvoeringen.
-Bij het gebruiken van 'DROP VIEW daguitvoeringen RESTRICT;' wordt alleen daguitvoeringen verwijderd want het wordt
nergens anders gebruikt. er is geen andere view dat depend op het bestaan van daguitvoeringen.

Conclusie:
-CASCADE zorgt ervoor dat de view wordt verwijderd en daarbij alle views die gebruik maken van het
origineel verwijderde view.
-RESTRICT zorgt ervoor dat de view alleen wordt verwijderd als er geen andere view is dat gebruik
maakt van de originele view.
