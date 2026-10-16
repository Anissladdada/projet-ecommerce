-- Projet e-commerce : analyse SQL
-- Auteur : Anis Laddada
-- Lancer : psql -U postgres -d ecommerce_db -f analysis.sql
--
-- Montant d'une ligne = quantite * prix_unitaire.
-- Les commandes annulées sont exclues du chiffre d'affaires,
-- des quantités vendues et du panier moyen.


-- ===== PARTIE 3 : ANALYSE SQL =====

-- Exercice 1 : tous les produits, puis ceux à plus de 100 euros
SELECT nom, categorie, prix, stock
FROM produit
ORDER BY categorie, nom;

SELECT nom, categorie, prix, stock
FROM produit
WHERE prix > 100
ORDER BY prix DESC;


-- Exercice 2 : clients d'une ville, puis nombre de clients par ville
SELECT *
FROM client
WHERE ville = 'Lyon';

SELECT ville, COUNT(*) AS nb_clients
FROM client
GROUP BY ville
ORDER BY nb_clients DESC;


-- Exercice 3 : commandes avec les informations du client
SELECT c.id, c.date_commande, c.statut,
       cl.nom, cl.prenom, cl.email, cl.ville
FROM commande c
JOIN client cl ON cl.id = c.client_id
ORDER BY c.date_commande;


-- Exercice 4 : montant de chaque ligne de commande
SELECT id, commande_id, produit_id, quantite, prix_unitaire,
       quantite * prix_unitaire AS montant_ligne
FROM ligne_commande;


-- Exercice 5 : montant total de chaque commande
SELECT c.id, c.date_commande, c.statut,
       SUM(lc.quantite * lc.prix_unitaire) AS montant_total
FROM commande c
JOIN ligne_commande lc ON lc.commande_id = c.id
GROUP BY c.id, c.date_commande, c.statut
ORDER BY c.id;


-- Exercice 6 : chiffre d'affaires et quantités par catégorie
SELECT p.categorie,
       SUM(lc.quantite * lc.prix_unitaire) AS chiffre_affaires,
       SUM(lc.quantite) AS quantite_vendue
FROM ligne_commande lc
JOIN commande c ON c.id = lc.commande_id
JOIN produit p ON p.id = lc.produit_id
WHERE c.statut <> 'annulée'
GROUP BY p.categorie
ORDER BY chiffre_affaires DESC;


-- Exercice 7 : 10 produits les plus vendus en quantité
SELECT p.nom, p.categorie, SUM(lc.quantite) AS quantite_vendue
FROM ligne_commande lc
JOIN commande c ON c.id = lc.commande_id
JOIN produit p ON p.id = lc.produit_id
WHERE c.statut <> 'annulée'
GROUP BY p.id, p.nom, p.categorie
ORDER BY quantite_vendue DESC, p.nom
LIMIT 10;


-- Exercice 8 : 10 produits qui rapportent le plus
SELECT p.nom, p.categorie,
       SUM(lc.quantite * lc.prix_unitaire) AS chiffre_affaires
FROM ligne_commande lc
JOIN commande c ON c.id = lc.commande_id
JOIN produit p ON p.id = lc.produit_id
WHERE c.statut <> 'annulée'
GROUP BY p.id, p.nom, p.categorie
ORDER BY chiffre_affaires DESC
LIMIT 10;


-- Exercice 9 : commandes et montant par client
-- Le filtre sur le statut est dans le ON, pour garder les clients sans commande.
SELECT cl.id, cl.nom, cl.prenom,
       COUNT(DISTINCT c.id) AS nb_commandes,
       COALESCE(SUM(lc.quantite * lc.prix_unitaire), 0) AS montant_total
FROM client cl
LEFT JOIN commande c ON c.client_id = cl.id AND c.statut <> 'annulée'
LEFT JOIN ligne_commande lc ON lc.commande_id = c.id
GROUP BY cl.id, cl.nom, cl.prenom
ORDER BY montant_total DESC;

-- Clients qui n'ont jamais commandé
SELECT cl.*
FROM client cl
LEFT JOIN commande c ON c.client_id = cl.id
WHERE c.id IS NULL;


-- Exercice 10 : panier moyen
-- Panier moyen = chiffre d'affaires / nombre de commandes.
SELECT ROUND(SUM(lc.quantite * lc.prix_unitaire) / COUNT(DISTINCT c.id), 2)
       AS panier_moyen
FROM commande c
JOIN ligne_commande lc ON lc.commande_id = c.id
WHERE c.statut <> 'annulée';

-- Panier moyen par mois
SELECT TO_CHAR(c.date_commande, 'YYYY-MM') AS mois,
       COUNT(DISTINCT c.id) AS nb_commandes,
       ROUND(SUM(lc.quantite * lc.prix_unitaire), 2) AS chiffre_affaires,
       ROUND(SUM(lc.quantite * lc.prix_unitaire) / COUNT(DISTINCT c.id), 2)
           AS panier_moyen
FROM commande c
JOIN ligne_commande lc ON lc.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY mois
ORDER BY mois;


-- ===== PARTIE 4 : TRANSFORMATION DES DONNÉES =====

-- Exercice 11 : catégorie de panier selon le montant de la commande
SELECT c.id AS commande_id,
       SUM(lc.quantite * lc.prix_unitaire) AS montant,
       CASE
           WHEN SUM(lc.quantite * lc.prix_unitaire) < 500 THEN 'Petit panier'
           WHEN SUM(lc.quantite * lc.prix_unitaire) < 1500 THEN 'Panier moyen'
           ELSE 'Gros panier'
       END AS categorie_panier
FROM commande c
JOIN ligne_commande lc ON lc.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY c.id
ORDER BY c.id;


-- Exercice 12 : évolution du chiffre d'affaires par mois
-- Observation : le mois le plus fort est mai, le plus faible est janvier.
-- L'activité est plus faible en début d'année, puis plus haute ensuite.
SELECT TO_CHAR(c.date_commande, 'YYYY-MM') AS mois,
       ROUND(SUM(lc.quantite * lc.prix_unitaire), 2) AS chiffre_affaires
FROM commande c
JOIN ligne_commande lc ON lc.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY mois
ORDER BY mois;


-- ===== PARTIE 5 : QUALITÉ DES DONNÉES =====

-- Exercice 13 : commandes passées avant l'inscription du client
SELECT c.id AS commande_id, c.client_id,
       c.date_commande, cl.date_inscription
FROM commande c
JOIN client cl ON cl.id = c.client_id
WHERE c.date_commande < cl.date_inscription
ORDER BY c.id;

SELECT COUNT(*) AS nb_anomalies
FROM commande c
JOIN client cl ON cl.id = c.client_id
WHERE c.date_commande < cl.date_inscription;


-- Exercice 14 : produits jamais vendus
-- Ils immobilisent du stock sans rapporter : l'entreprise peut les
-- promouvoir, baisser leur prix ou les retirer du catalogue.
SELECT p.nom, p.categorie, p.prix, p.stock
FROM produit p
LEFT JOIN ligne_commande lc ON lc.produit_id = p.id
WHERE lc.id IS NULL
ORDER BY p.id;


-- ===== PARTIE 6 : TABLEAU DE BORD =====

-- Exercice 15 A : exploration
SELECT 'client' AS table_name, COUNT(*) AS nb_lignes FROM client
UNION ALL
SELECT 'produit', COUNT(*) FROM produit
UNION ALL
SELECT 'commande', COUNT(*) FROM commande
UNION ALL
SELECT 'ligne_commande', COUNT(*) FROM ligne_commande;

SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('client', 'produit', 'commande', 'ligne_commande')
ORDER BY table_name, ordinal_position;

-- Valeurs manquantes : COUNT(colonne) ignore les NULL.
-- Résultat attendu : 0 partout, car les colonnes sont NOT NULL.
SELECT COUNT(*) - COUNT(nom) AS nom_manquant,
       COUNT(*) - COUNT(prenom) AS prenom_manquant,
       COUNT(*) - COUNT(email) AS email_manquant,
       COUNT(*) - COUNT(ville) AS ville_manquante,
       COUNT(*) - COUNT(date_inscription) AS date_inscription_manquante
FROM client;

SELECT COUNT(*) - COUNT(nom) AS nom_manquant,
       COUNT(*) - COUNT(categorie) AS categorie_manquante,
       COUNT(*) - COUNT(prix) AS prix_manquant,
       COUNT(*) - COUNT(stock) AS stock_manquant
FROM produit;

SELECT COUNT(*) - COUNT(client_id) AS client_manquant,
       COUNT(*) - COUNT(date_commande) AS date_manquante,
       COUNT(*) - COUNT(statut) AS statut_manquant
FROM commande;

SELECT COUNT(*) - COUNT(commande_id) AS commande_manquante,
       COUNT(*) - COUNT(produit_id) AS produit_manquant,
       COUNT(*) - COUNT(quantite) AS quantite_manquante,
       COUNT(*) - COUNT(prix_unitaire) AS prix_manquant
FROM ligne_commande;


-- Exercice 15 B : indicateurs commerciaux
-- Client actif = client avec au moins une commande non annulée.
SELECT SUM(lc.quantite * lc.prix_unitaire) AS chiffre_affaires_total,
       COUNT(DISTINCT c.id) AS nb_commandes,
       ROUND(SUM(lc.quantite * lc.prix_unitaire) / COUNT(DISTINCT c.id), 2)
           AS panier_moyen,
       COUNT(DISTINCT c.client_id) AS clients_actifs
FROM commande c
JOIN ligne_commande lc ON lc.commande_id = c.id
WHERE c.statut <> 'annulée';

-- Taux d'annulation, calculé sur toutes les commandes
SELECT ROUND(100.0 * SUM(CASE WHEN statut = 'annulée' THEN 1 ELSE 0 END)
             / COUNT(*), 2) AS taux_annulation_pct
FROM commande;


-- Exercice 15 C : 10 meilleurs clients
SELECT cl.id, cl.nom, cl.prenom,
       ROUND(SUM(lc.quantite * lc.prix_unitaire), 2) AS chiffre_affaires
FROM client cl
JOIN commande c ON c.client_id = cl.id
JOIN ligne_commande lc ON lc.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY cl.id, cl.nom, cl.prenom
ORDER BY chiffre_affaires DESC
LIMIT 10;


-- Exercice 15 D : table de synthèse mensuelle
-- Elle permet de suivre l'activité mois par mois et de repérer les pics.
DROP TABLE IF EXISTS synthese_mensuelle;

CREATE TABLE synthese_mensuelle AS
SELECT TO_CHAR(c.date_commande, 'YYYY-MM') AS mois,
       COUNT(DISTINCT c.id) AS nb_commandes,
       ROUND(SUM(lc.quantite * lc.prix_unitaire), 2) AS chiffre_affaires,
       ROUND(SUM(lc.quantite * lc.prix_unitaire) / COUNT(DISTINCT c.id), 2)
           AS panier_moyen
FROM commande c
JOIN ligne_commande lc ON lc.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY mois
ORDER BY mois;

SELECT * FROM synthese_mensuelle ORDER BY mois;


-- ===== PARTIE 7 : ANALYSE LIBRE =====

-- Analyse 1
-- Question : les clients paient-ils moins cher que le prix du catalogue ?
-- Observation : oui, de 5 % (Audio) à 7 % (Sport) en moyenne.
-- Intérêt : voir où les promotions coûtent le plus à l'entreprise.
SELECT p.categorie,
       ROUND(AVG((lc.prix_unitaire - p.prix) / p.prix * 100), 1)
           AS ecart_moyen_pct
FROM ligne_commande lc
JOIN produit p ON p.id = lc.produit_id
GROUP BY p.categorie
ORDER BY ecart_moyen_pct;


-- Analyse 2
-- Question : des produits en rupture de stock se vendent-ils bien ?
-- Observation : 3 produits sont à stock 0 et se vendent bien
-- (Lampe 2, Sweat 1, Souris 2).
-- Intérêt : ce sont les produits à réapprovisionner en priorité.
SELECT p.nom, p.categorie, p.stock, SUM(lc.quantite) AS quantite_vendue
FROM produit p
JOIN ligne_commande lc ON lc.produit_id = p.id
JOIN commande c ON c.id = lc.commande_id
WHERE p.stock = 0 AND c.statut <> 'annulée'
GROUP BY p.id, p.nom, p.categorie, p.stock
ORDER BY quantite_vendue DESC;


-- Analyse 3
-- Question : quelles villes rapportent le plus ?
-- Observation : Montpellier est première et Strasbourg dernière.
-- Chaque ville a 10 clients, la différence vient donc de ce qu'ils achètent.
-- Intérêt : cibler les actions marketing sur les villes qui achètent le moins.
SELECT cl.ville,
       COUNT(DISTINCT c.id) AS nb_commandes,
       ROUND(SUM(lc.quantite * lc.prix_unitaire), 2) AS chiffre_affaires
FROM client cl
JOIN commande c ON c.client_id = cl.id
JOIN ligne_commande lc ON lc.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY cl.ville
ORDER BY chiffre_affaires DESC;
