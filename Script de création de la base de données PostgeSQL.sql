
-- ########################################################
-- ## SCRIPT DE CRÉATION DE LA BASE DE DONNÉES POSTGESQL ##
-- ########################################################


--DROP DATABASE DATAImmo;
--CREATE DATABASE DATAImmo;

DROP TABLE IF EXISTS _recensements_population;
DROP TABLE IF EXISTS _transactions;
DROP TABLE IF EXISTS _ref_geographique;
DROP TABLE IF EXISTS population;
DROP TABLE IF EXISTS vente;
DROP TABLE IF EXISTS bien;
DROP TABLE IF EXISTS commune;
DROP TABLE IF EXISTS departement;

--######################### "REGION", "DEPARTEMENT" ET "COMMUNE" #########################

-- Création d'une table qui va reçevoir les données des régions, populations et communes

-- -> Les différents niveaux d'agrégats géographiques associés aux communes françaises identifiées par leurs n° INSEE


--DROP TABLE _ref_geographique;

CREATE TABLE _ref_geographique(
regrgp_nom VARCHAR(30) NOT NULL,
reg_nom VARCHAR(50) NOT NULL,
reg_nom_old VARCHAR(50) NOT NULL,
aca_nom VARCHAR(50) NOT NULL,
dep_nom VARCHAR(50) NOT NULL,
com_code VARCHAR(5) NOT NULL,
com_code1 VARCHAR(5) NOT NULL,
com_code2 VARCHAR(5) NOT NULL,
com_id VARCHAR(6) NOT NULL,
com_nom_maj_court VARCHAR(50) NOT NULL,
com_nom_maj VARCHAR(50) NOT NULL,
com_nom VARCHAR(100) NOT NULL,
uu_code VARCHAR(10) NULL,
uu_id VARCHAR(10) NULL,
uucr_id VARCHAR(10) NOT NULL,
uucr_nom VARCHAR(50) NOT NULL,
ze_id VARCHAR(10) NOT NULL,
dep_code VARCHAR(10) NOT NULL,
dep_id VARCHAR(10) NOT NULL,
dep_nom_num VARCHAR(50) NOT NULL,
dep_num_nom VARCHAR(50) NOT NULL,
aca_code INTEGER NOT NULL,
aca_id VARCHAR(10) NOT NULL,
reg_code INTEGER NOT NULL,
reg_id VARCHAR(10) NOT NULL,
reg_code_old INTEGER NOT NULL,
reg_id_old VARCHAR(10) NOT NULL,
fd_id VARCHAR(10) NOT NULL,
fr_id VARCHAR(10) NOT NULL,
fe_id VARCHAR(10) NOT NULL,
uu_id_99 VARCHAR(10) NOT NULL,
au_code VARCHAR(10) NULL,
au_id VARCHAR(10) NOT NULL,
auc_id VARCHAR(10) NOT NULL,
auc_nom VARCHAR(100) NOT NULL,
uu_id_10 VARCHAR(10) NOT NULL,
geolocalisation POINT NULL
);



-- Importation du fichier csv
-- source : https://www.data.gouv.fr/fr/datasets/referentiel-geographique-francais-communes-unites-urbaines-aires-urbaines-departements-academies-regions-1/#resources

COPY _ref_geographique FROM 'D:\...\fr-esr-referentiel-geographique.csv' DELIMITER ';' CSV HEADER;



-- Création de la table "departement"

--DROP TABLE departement;

CREATE TABLE departement(
code_departement VARCHAR(3) PRIMARY KEY NOT NULL,
nom_departement VARCHAR(50) NOT NULL,
code_region INTEGER NOT NULL,
nom_region VARCHAR(50) NOT NULL
);



-- Remplissage de "departement" par les données de "_ref_geographique"

INSERT INTO departement 
SELECT DISTINCT dep_code, dep_nom, reg_code, reg_nom FROM _ref_geographique;



-- Création de la table "commune"

--DROP TABLE commune;

CREATE TABLE commune(
id_commune VARCHAR(5) PRIMARY KEY NOT NULL,
nom_commune VARCHAR(100) NOT NULL,
code_departement VARCHAR(3) NOT NULL,
CONSTRAINT fk_departement
FOREIGN KEY(code_departement) 
REFERENCES departement(code_departement)
);



-- Remplissage de "commune" par les données de "_ref_geographique" en jointure avec "communes_france"

INSERT INTO commune 
SELECT com_code, com_nom, dep_code 
FROM _ref_geographique;




-- ######################### "BIEN" ET "VENTE" #########################


-- Création d'une table qui va reçevoir les données des transactions 


--DROP TABLE _transactions;

CREATE TABLE _transactions(
code_service_ch VARCHAR(50),
reference_document VARCHAR(50),
articles_cgi_1 VARCHAR(50),
articles_cgi_2 VARCHAR(50),
articles_cgi_3 VARCHAR(50),
articles_cgi_4 VARCHAR(50),
articles_cgi_5 VARCHAR(50),
no_disposition INTEGER NOT NULL,
date_mutation Date NOT NULL,
nature_mutation VARCHAR(40) NOT NULL,
valeur_fonciere FLOAT NULL,
no_voie INTEGER NULL,
btq VARCHAR(1) NULL,
code_type_voie INTEGER NOT NULL,
type_voie VARCHAR(4) NULL,
code_voie VARCHAR(4) NOT NULL,
voie VARCHAR(50) NOT NULL,
code_id_commune INTEGER NOT NULL,
code_postal FLOAT NULL,
commune VARCHAR(50) NULL,
code_departement VARCHAR(3) NOT NULL,
code_commune VARCHAR(3) NOT NULL,
prefixe_section INTEGER NULL,
section VARCHAR(2) NULL,
no_plan INTEGER NOT NULL,
no_volume INTEGER NULL,
no_lot_1 VARCHAR(7) NOT NULL,
surface_carrez_lot_1 FLOAT NOT NULL,
no_lot_2 VARCHAR(7) NULL,
surface_carrez_lot_2 FLOAT NULL,
no_lot_3 VARCHAR(7) NULL,
surface_carrez_lot_3 FLOAT NULL,
no_lot_4 VARCHAR(7) NULL,
surface_carrez_lot_4 FLOAT NULL,
no_lot_5 VARCHAR(7) NULL,
surface_carrez_lot_5 FLOAT NULL,
nombre_lots INTEGER NOT NULL,
code_type_local INTEGER NOT NULL,
type_local VARCHAR(50) NOT NULL,
identifiant_local VARCHAR(20) NULL,
surface_reelle_bati FLOAT NOT NULL,
nombre_pieces_principales INTEGER NOT NULL,
nature_culture VARCHAR(2) NULL,
nature_culture_speciale VARCHAR(5) NULL,
surface_terrain FLOAT NULL
);



-- source : Demandes de valeurs foncières : transactions immobilières intervenues au cours du 1er semestre 2020 sur le territoire métropolitain et les DOM-TOM
-- -> Fichier "DVF.csv" fournit

-- Importation du fichier csv
COPY _transactions FROM 'D:\...\DVF.csv' DELIMITER ';' CSV HEADER;



-- Ajout dans la table "_transactions" de la colonne qui va être la clé primaire de la future table "bien"

ALTER TABLE _transactions ADD COLUMN id_bien INTEGER;



-- Ajout dans la table "_transactions" d'une colonne "id_commune" qui va contenir le code INSEE (code_departement + code_commune)

ALTER TABLE _transactions ADD COLUMN id_commune VARCHAR(5);



-- Insérer le code INSEE issue de la concaténation du code département et du code commune

UPDATE _transactions SET id_commune = CONCAT(code_departement, LPAD(code_commune, 2, '0')) WHERE LENGTH(code_departement) = 3 AND LENGTH(code_commune) < 3;

UPDATE _transactions SET id_commune = CONCAT(code_departement, code_commune) WHERE LENGTH(code_departement) = 3 AND LENGTH(code_commune) = 3;

UPDATE _transactions SET id_commune = CONCAT(code_departement, LPAD(code_commune, 3, '0')) WHERE LENGTH(code_departement) < 3;



-- Création de la table "bien"

--DROP TABLE bien;

CREATE TABLE bien(
id_bien SERIAL PRIMARY KEY,
no_voie INTEGER NULL,
type_voie VARCHAR(4) NULL,
voie VARCHAR(50) NOT NULL,
total_piece INTEGER NOT NULL,
surface_carrez FLOAT NOT NULL,
surface_local FLOAT NOT NULL,
type_local VARCHAR(50) NOT NULL,
id_commune VARCHAR(5) NOT NULL,
CONSTRAINT fk_bien_commune
FOREIGN KEY(id_commune) 
REFERENCES commune(id_commune)
);



-- Remplissage de "bien" par les données de "_transactions"

INSERT INTO bien(no_voie, type_voie, voie, total_piece, surface_carrez, surface_local, type_local, id_commune)
SELECT DISTINCT no_voie, type_voie, voie, nombre_pieces_principales, COALESCE(surface_carrez_lot_1,0)+COALESCE(surface_carrez_lot_2,0)+COALESCE(surface_carrez_lot_3,0)+COALESCE(surface_carrez_lot_4,0)+COALESCE(surface_carrez_lot_5,0), surface_reelle_bati, type_local, id_commune
FROM _transactions;



-- Mettre à jour la colonne "id_bien" de la table "_transactions" par les id générés dans la table "bien"

UPDATE _transactions d
SET id_bien = (
SELECT id_bien FROM bien b
WHERE (b.no_voie = d.no_voie OR b.no_voie IS NULL AND d.no_voie IS NULL)
AND (b.type_voie = d.type_voie OR b.type_voie IS NULL AND d.type_voie IS NULL)
AND b.voie = d.voie
AND b.total_piece = d.nombre_pieces_principales
AND b.surface_carrez = COALESCE(d.surface_carrez_lot_1,0)+COALESCE(d.surface_carrez_lot_2,0)+COALESCE(d.surface_carrez_lot_3,0)+COALESCE(d.surface_carrez_lot_4,0)+COALESCE(d.surface_carrez_lot_5,0)
AND b.surface_local = d.surface_reelle_bati
AND b.type_local = d.type_local
AND (b.id_commune = d.id_commune)
);



-- Création de la table "vente"

--DROP TABLE vente;

CREATE TABLE vente(
id_vente SERIAL PRIMARY KEY,
date_mutation DATE NOT NULL,
valeur_fonciere FLOAT NULL,
id_bien INTEGER NOT NULL,
CONSTRAINT fk_bien
FOREIGN KEY(id_bien) 
REFERENCES bien(id_bien)
);



-- Remplissage de "vente" par les données de "_transactions"

INSERT INTO vente (date_mutation, valeur_fonciere, id_bien)
SELECT date_mutation, valeur_fonciere, id_bien
FROM _transactions;




-- ######################### "POPULATION" #########################



-- Évolution et structure de la population en 2019, 2013 et 2008

--DROP TABLE _recensements_population;

CREATE TABLE _recensements_population(
-- code INSEE
CODGEO VARCHAR(5) NOT NULL,
-- [ population 2019 totale ]
P19_POP FLOAT NULL,
-- population 2019 par tranche d'âge
P19_POP0014 FLOAT NULL,
P19_POP1529 FLOAT NULL,
P19_POP3044 FLOAT NULL,
P19_POP4559 FLOAT NULL,
P19_POP6074 FLOAT NULL,
P19_POP7589 FLOAT NULL,
P19_POP90P FLOAT NULL,
-- population 2019 hommes
P19_POPH FLOAT NULL,
P19_H0014 FLOAT NULL,
P19_H1529 FLOAT NULL,
P19_H3044 FLOAT NULL,
P19_H4559 FLOAT NULL,
P19_H6074 FLOAT NULL,
P19_H7589 FLOAT NULL,
P19_H90P FLOAT NULL,
P19_H0019 FLOAT NULL,
P19_H2064 FLOAT NULL,
P19_H65P FLOAT NULL,
-- population 2019 femmes
P19_POPF FLOAT NULL,
P19_F0014 FLOAT NULL,
P19_F1529 FLOAT NULL,
P19_F3044 FLOAT NULL,
P19_F4559 FLOAT NULL,
P19_F6074 FLOAT NULL,
P19_F7589 FLOAT NULL,
P19_F90P FLOAT NULL,
P19_F0019 FLOAT NULL,
P19_F2064 FLOAT NULL,
P19_F65P FLOAT NULL,
-- population 2019 par ancienneté
P19_POP01P FLOAT NULL,
P19_POP01P_IRAN1 FLOAT NULL,
P19_POP01P_IRAN2 FLOAT NULL,
P19_POP01P_IRAN3 FLOAT NULL,
P19_POP01P_IRAN4 FLOAT NULL,
P19_POP01P_IRAN5 FLOAT NULL,
P19_POP01P_IRAN6 FLOAT NULL,
P19_POP01P_IRAN7 FLOAT NULL,
P19_POP0114_IRAN2P FLOAT NULL,
P19_POP0114_IRAN2 FLOAT NULL,
P19_POP0114_IRAN3P FLOAT NULL,
P19_POP1524_IRAN2P FLOAT NULL,
P19_POP1524_IRAN2 FLOAT NULL,
P19_POP1524_IRAN3P FLOAT NULL,
P19_POP2554_IRAN2P FLOAT NULL,
P19_POP2554_IRAN2 FLOAT NULL,
P19_POP2554_IRAN3P FLOAT NULL,
P19_POP55P_IRAN2P FLOAT NULL,
P19_POP55P_IRAN2 FLOAT NULL,
P19_POP55P_IRAN3P FLOAT NULL,
-- population 2019 par profession
C19_POP15P FLOAT NULL,
C19_POP15P_CS1 FLOAT NULL,
C19_POP15P_CS2 FLOAT NULL,
C19_POP15P_CS3 FLOAT NULL,
C19_POP15P_CS4 FLOAT NULL,
C19_POP15P_CS5 FLOAT NULL,
C19_POP15P_CS6 FLOAT NULL,
C19_POP15P_CS7 FLOAT NULL,
C19_POP15P_CS8 FLOAT NULL,
-- population 2019 hommes par profession
C19_H15P FLOAT NULL,
C19_H15P_CS1 FLOAT NULL,
C19_H15P_CS2 FLOAT NULL,
C19_H15P_CS3 FLOAT NULL,
C19_H15P_CS4 FLOAT NULL,
C19_H15P_CS5 FLOAT NULL,
C19_H15P_CS6 FLOAT NULL,
C19_H15P_CS7 FLOAT NULL,
C19_H15P_CS8 FLOAT NULL,
-- population 2019 femmes par profession
C19_F15P FLOAT NULL,
C19_F15P_CS1 FLOAT NULL,
C19_F15P_CS2 FLOAT NULL,
C19_F15P_CS3 FLOAT NULL,
C19_F15P_CS4 FLOAT NULL,
C19_F15P_CS5 FLOAT NULL,
C19_F15P_CS6 FLOAT NULL,
C19_F15P_CS7 FLOAT NULL,
C19_F15P_CS8 FLOAT NULL,
-- population 2019 par tranche d'âge et par profession
C19_POP1524 FLOAT NULL,
C19_POP1524_CS1 FLOAT NULL,
C19_POP1524_CS2 FLOAT NULL,
C19_POP1524_CS3 FLOAT NULL,
C19_POP1524_CS4 FLOAT NULL,
C19_POP1524_CS5 FLOAT NULL,
C19_POP1524_CS6 FLOAT NULL,
C19_POP1524_CS7 FLOAT NULL,
C19_POP1524_CS8 FLOAT NULL,
C19_POP2554 FLOAT NULL,
C19_POP2554_CS1 FLOAT NULL,
C19_POP2554_CS2 FLOAT NULL,
C19_POP2554_CS3 FLOAT NULL,
C19_POP2554_CS4 FLOAT NULL,
C19_POP2554_CS5 FLOAT NULL,
C19_POP2554_CS6 FLOAT NULL,
C19_POP2554_CS7 FLOAT NULL,
C19_POP2554_CS8 FLOAT NULL,
C19_POP55P FLOAT NULL,
C19_POP55P_CS1 FLOAT NULL,
C19_POP55P_CS2 FLOAT NULL,
C19_POP55P_CS3 FLOAT NULL,
C19_POP55P_CS4 FLOAT NULL,
C19_POP55P_CS5 FLOAT NULL,
C19_POP55P_CS6 FLOAT NULL,
C19_POP55P_CS7 FLOAT NULL,
C19_POP55P_CS8 FLOAT NULL,
-- [ population 2013 totale ]
P13_POP FLOAT NULL,
-- population 2013 par tranche d'âge
P13_POP0014 FLOAT NULL,
P13_POP1529 FLOAT NULL,
P13_POP3044 FLOAT NULL,
P13_POP4559 FLOAT NULL,
P13_POP6074 FLOAT NULL,
P13_POP7589 FLOAT NULL,
P13_POP90P FLOAT NULL,
-- population 2013 hommes
P13_POPH FLOAT NULL,
P13_H0014 FLOAT NULL,
P13_H1529 FLOAT NULL,
P13_H3044 FLOAT NULL,
P13_H4559 FLOAT NULL,
P13_H6074 FLOAT NULL,
P13_H7589 FLOAT NULL,
P13_H90P FLOAT NULL,
P13_H0019 FLOAT NULL,
P13_H2064 FLOAT NULL,
P13_H65P FLOAT NULL,
-- population 2013 femmes
P13_POPF FLOAT NULL,
P13_F0014 FLOAT NULL,
P13_F1529 FLOAT NULL,
P13_F3044 FLOAT NULL,
P13_F4559 FLOAT NULL,
P13_F6074 FLOAT NULL,
P13_F7589 FLOAT NULL,
P13_F90P FLOAT NULL,
P13_F0019 FLOAT NULL,
P13_F2064 FLOAT NULL,
P13_F65P FLOAT NULL,
-- population 2013 par ancienneté
P13_POP01P FLOAT NULL,
P13_POP01P_IRAN1 FLOAT NULL,
P13_POP01P_IRAN2 FLOAT NULL,
P13_POP01P_IRAN3 FLOAT NULL,
P13_POP01P_IRAN4 FLOAT NULL,
P13_POP01P_IRAN5 FLOAT NULL,
P13_POP01P_IRAN6 FLOAT NULL,
P13_POP01P_IRAN7 FLOAT NULL,
P13_POP0114_IRAN2P FLOAT NULL,
P13_POP0114_IRAN2 FLOAT NULL,
P13_POP0114_IRAN3P FLOAT NULL,
P13_POP1524_IRAN2P FLOAT NULL,
P13_POP1524_IRAN2 FLOAT NULL,
P13_POP1524_IRAN3P FLOAT NULL,
P13_POP2554_IRAN2P FLOAT NULL,
P13_POP2554_IRAN2 FLOAT NULL,
P13_POP2554_IRAN3P FLOAT NULL,
P13_POP55P_IRAN2P FLOAT NULL,
P13_POP55P_IRAN2 FLOAT NULL,
P13_POP55P_IRAN3P FLOAT NULL,
-- population 2013 par profession
C13_POP15P FLOAT NULL,
C13_POP15P_CS1 FLOAT NULL,
C13_POP15P_CS2 FLOAT NULL,
C13_POP15P_CS3 FLOAT NULL,
C13_POP15P_CS4 FLOAT NULL,
C13_POP15P_CS5 FLOAT NULL,
C13_POP15P_CS6 FLOAT NULL,
C13_POP15P_CS7 FLOAT NULL,
C13_POP15P_CS8 FLOAT NULL,
-- population 2013 hommes par profession
C13_H15P FLOAT NULL,
C13_H15P_CS1 FLOAT NULL,
C13_H15P_CS2 FLOAT NULL,
C13_H15P_CS3 FLOAT NULL,
C13_H15P_CS4 FLOAT NULL,
C13_H15P_CS5 FLOAT NULL,
C13_H15P_CS6 FLOAT NULL,
C13_H15P_CS7 FLOAT NULL,
C13_H15P_CS8 FLOAT NULL,
-- population 2013 femmes par profession
C13_F15P FLOAT NULL,
C13_F15P_CS1 FLOAT NULL,
C13_F15P_CS2 FLOAT NULL,
C13_F15P_CS3 FLOAT NULL,
C13_F15P_CS4 FLOAT NULL,
C13_F15P_CS5 FLOAT NULL,
C13_F15P_CS6 FLOAT NULL,
C13_F15P_CS7 FLOAT NULL,
C13_F15P_CS8 FLOAT NULL,
-- population 2013 par tranche d'âge et par profession
C13_POP1524 FLOAT NULL,
C13_POP1524_CS1 FLOAT NULL,
C13_POP1524_CS2 FLOAT NULL,
C13_POP1524_CS3 FLOAT NULL,
C13_POP1524_CS4 FLOAT NULL,
C13_POP1524_CS5 FLOAT NULL,
C13_POP1524_CS6 FLOAT NULL,
C13_POP1524_CS7 FLOAT NULL,
C13_POP1524_CS8 FLOAT NULL,
C13_POP2554 FLOAT NULL,
C13_POP2554_CS1 FLOAT NULL,
C13_POP2554_CS2 FLOAT NULL,
C13_POP2554_CS3 FLOAT NULL,
C13_POP2554_CS4 FLOAT NULL,
C13_POP2554_CS5 FLOAT NULL,
C13_POP2554_CS6 FLOAT NULL,
C13_POP2554_CS7 FLOAT NULL,
C13_POP2554_CS8 FLOAT NULL,
C13_POP55P FLOAT NULL,
C13_POP55P_CS1 FLOAT NULL,
C13_POP55P_CS2 FLOAT NULL,
C13_POP55P_CS3 FLOAT NULL,
C13_POP55P_CS4 FLOAT NULL,
C13_POP55P_CS5 FLOAT NULL,
C13_POP55P_CS6 FLOAT NULL,
C13_POP55P_CS7 FLOAT NULL,
C13_POP55P_CS8 FLOAT NULL,
-- [ population 2008 totale ]
P08_POP FLOAT NULL,
-- population 2008 par tranche d'âge
P08_POP0014 FLOAT NULL,
P08_POP1529 FLOAT NULL,
P08_POP3044 FLOAT NULL,
P08_POP4559 FLOAT NULL,
P08_POP6074 FLOAT NULL,
P08_POP75P FLOAT NULL,
-- population 2008 hommes
P08_POPH FLOAT NULL,
P08_H0014 FLOAT NULL,
P08_H1529 FLOAT NULL,
P08_H3044 FLOAT NULL,
P08_H4559 FLOAT NULL,
P08_H6074 FLOAT NULL,
P08_H7589 FLOAT NULL,
P08_H90P FLOAT NULL,
P08_H0019 FLOAT NULL,
P08_H2064 FLOAT NULL,
P08_H65P FLOAT NULL,
-- population 2008 femmes
P08_POPF FLOAT NULL,
P08_F0014 FLOAT NULL,
P08_F1529 FLOAT NULL,
P08_F3044 FLOAT NULL,
P08_F4559 FLOAT NULL,
P08_F6074 FLOAT NULL,
P08_F7589 FLOAT NULL,
P08_F90P FLOAT NULL,
P08_F0019 FLOAT NULL,
P08_F2064 FLOAT NULL,
P08_F65P FLOAT NULL,
-- population 2008 par ancienneté
P08_POP05P FLOAT NULL,
P08_POP05P_IRAN1 FLOAT NULL,
P08_POP05P_IRAN2 FLOAT NULL,
P08_POP05P_IRAN3 FLOAT NULL,
P08_POP05P_IRAN4 FLOAT NULL,
P08_POP05P_IRAN5 FLOAT NULL,
P08_POP05P_IRAN6 FLOAT NULL,
P08_POP05P_IRAN7 FLOAT NULL,
P08_POP0514 FLOAT NULL,
P08_POP0514_IRAN2 FLOAT NULL,
P08_POP0514_IRAN3P FLOAT NULL,
P08_POP1524 FLOAT NULL,
P08_POP1524_IRAN2 FLOAT NULL,
P08_POP1524_IRAN3P FLOAT NULL,
P08_POP2554 FLOAT NULL,
P08_POP2554_IRAN2 FLOAT NULL,
P08_POP2554_IRAN3P FLOAT NULL,
P08_POP55P FLOAT NULL,
P08_POP55P_IRAN2 FLOAT NULL,
P08_POP55P_IRAN3P FLOAT NULL,
-- population 2008 par profession
C08_POP15P FLOAT NULL,
C08_POP15P_CS1 FLOAT NULL,
C08_POP15P_CS2 FLOAT NULL,
C08_POP15P_CS3 FLOAT NULL,
C08_POP15P_CS4 FLOAT NULL,
C08_POP15P_CS5 FLOAT NULL,
C08_POP15P_CS6 FLOAT NULL,
C08_POP15P_CS7 FLOAT NULL,
C08_POP15P_CS8 FLOAT NULL,
-- population 2008 hommes par profession
C08_H15P FLOAT NULL,
C08_H15P_CS1 FLOAT NULL,
C08_H15P_CS2 FLOAT NULL,
C08_H15P_CS3 FLOAT NULL,
C08_H15P_CS4 FLOAT NULL,
C08_H15P_CS5 FLOAT NULL,
C08_H15P_CS6 FLOAT NULL,
C08_H15P_CS7 FLOAT NULL,
C08_H15P_CS8 FLOAT NULL,
-- population 2008 femmes par profession
C08_F15P FLOAT NULL,
C08_F15P_CS1 FLOAT NULL,
C08_F15P_CS2 FLOAT NULL,
C08_F15P_CS3 FLOAT NULL,
C08_F15P_CS4 FLOAT NULL,
C08_F15P_CS5 FLOAT NULL,
C08_F15P_CS6 FLOAT NULL,
C08_F15P_CS7 FLOAT NULL,
C08_F15P_CS8 FLOAT NULL,
-- population 2008 par tranche d'âge et par profession
C08_POP1524 FLOAT NULL,
C08_POP1524_CS1 FLOAT NULL,
C08_POP1524_CS2 FLOAT NULL,
C08_POP1524_CS3 FLOAT NULL,
C08_POP1524_CS4 FLOAT NULL,
C08_POP1524_CS5 FLOAT NULL,
C08_POP1524_CS6 FLOAT NULL,
C08_POP1524_CS7 FLOAT NULL,
C08_POP1524_CS8 FLOAT NULL,
C08_POP2554 FLOAT NULL,
C08_POP2554_CS1 FLOAT NULL,
C08_POP2554_CS2 FLOAT NULL,
C08_POP2554_CS3 FLOAT NULL,
C08_POP2554_CS4 FLOAT NULL,
C08_POP2554_CS5 FLOAT NULL,
C08_POP2554_CS6 FLOAT NULL,
C08_POP2554_CS7 FLOAT NULL,
C08_POP2554_CS8 FLOAT NULL,
C08_POP55P FLOAT NULL,
C08_POP55P_CS1 FLOAT NULL,
C08_POP55P_CS2 FLOAT NULL,
C08_POP55P_CS3 FLOAT NULL,
C08_POP55P_CS4 FLOAT NULL,
C08_POP55P_CS5 FLOAT NULL,
C08_POP55P_CS6 FLOAT NULL,
C08_POP55P_CS7 FLOAT NULL,
C08_POP55P_CS8 FLOAT NULL
);



-- Importation du fichier csv

-- source : https://www.insee.fr/fr/statistiques/6456153?sommaire=6456166

COPY _recensements_population FROM 'D:\...\base-cc-evol-struct-pop-2019.csv' DELIMITER ';' CSV HEADER;



-- Enlèvement des "zéros" à gauche du "CODGEO"

UPDATE _recensements_population SET CODGEO = SUBSTR(CODGEO,2) WHERE CODGEO LIKE '0%';



-- Remplacer les valeurs NULL par des "zéros" dans les colonnes "P19_POP", "P13_POP" et "P08_POP"

UPDATE _recensements_population SET P19_POP = 0 WHERE P19_POP IS NULL;

UPDATE _recensements_population SET P13_POP = 0 WHERE P13_POP IS NULL;

UPDATE _recensements_population SET P08_POP = 0 WHERE P08_POP IS NULL;



-- Création de la table "population"

--DROP TABLE population;

CREATE TABLE population(
code_population SERIAL PRIMARY KEY,
total_population INTEGER NOT NULL,
annee INTEGER NOT NULL,
id_commune VARCHAR(5) NOT NULL,
CONSTRAINT fk_pop_commune
FOREIGN KEY(id_commune) 
REFERENCES commune(id_commune)
);



-- Remplissage de "population" par les données de "_recensements_population" de 2019

INSERT INTO population(total_population, annee, id_commune)
SELECT P19_POP, 2019, CODGEO
FROM _recensements_population;



-- Remplissage de "population" par les données de "_recensements_population" de 2013

INSERT INTO population(total_population, annee, id_commune)
SELECT P13_POP, 2013, CODGEO
FROM _recensements_population;



-- Remplissage de "population" par les données de "_recensements_population" de 2008

INSERT INTO population(total_population, annee, id_commune)
SELECT P08_POP, 2008, CODGEO
FROM _recensements_population;


