# Projet SQL : analyse d'une plateforme e-commerce

Auteur : Anis Laddada (projet réalisé seul)

Projet en SQL (PostgreSQL) pour le cours de bases de données à l'EFREI.

## Fichiers

- `create_schema.sql` : création des 4 tables
- `seed_ecommerce.sql` : données de la plateforme (fournies)
- `analysis.sql` : requêtes d'analyse (parties 3 à 7)

## Lancer le projet

```bash
createdb -U postgres ecommerce_db
psql -U postgres -d ecommerce_db -f create_schema.sql
psql -U postgres -d ecommerce_db -f seed_ecommerce.sql
psql -U postgres -d ecommerce_db -f analysis.sql
```

Si `createdb` n'est pas reconnu, ouvrir `psql` et taper `CREATE DATABASE ecommerce_db;`.

Le seed se lance toujours après `create_schema.sql`. Après le chargement, on doit trouver 100 clients, 65 produits, 500 commandes et 1547 lignes de commande.

## Modèle de données

- `client` : un client (email unique)
- `produit` : un produit du catalogue, avec son prix et son stock
- `commande` : une commande d'un client, avec sa date et son statut
- `ligne_commande` : un produit acheté dans une commande, avec la quantité et le prix payé

Un client a plusieurs commandes, une commande a plusieurs lignes, et un produit apparaît dans plusieurs lignes. `ligne_commande` relie `commande` et `produit`. Elle garde le prix réellement payé, qui peut être différent du prix du catalogue.

Contraintes : clés primaires et étrangères, `NOT NULL`, `UNIQUE` sur l'email, `CHECK` sur le statut, la quantité (`> 0`), les prix et le stock (`>= 0`). Le stock peut être à 0 car certains produits sont en rupture.

## Règles de calcul

- Montant d'une ligne = quantité x prix unitaire.
- Les commandes annulées sont exclues du chiffre d'affaires, des quantités et du panier moyen.
- Un client actif a au moins une commande non annulée.

## Conclusions

- Chiffre d'affaires : 617 494,76 € pour 484 commandes. Panier moyen : 1 275,82 €.
- 90 clients sur 100 ont commandé. Le taux d'annulation est de 3,2 %.
- La catégorie Sport rapporte le plus (162 149,83 €).
- Le mois le plus fort est mai, le plus faible est janvier.
- 5 produits n'ont jamais été vendus.
- 30 commandes sont datées avant l'inscription du client : c'est une anomalie dans les données.
- 3 produits populaires sont en rupture de stock (Lampe 2, Sweat 1, Souris 2).
