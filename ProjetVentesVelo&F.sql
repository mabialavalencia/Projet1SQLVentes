 ----  


 Use AdventureWorks2022
 Go

 -- OBJECTIF 1 : CALCUL DU CHIFFRES D'AFFAIRES


 --  Chiffres d'affaires  de chaque mois  par année 

 Select OrderDate from Sales.SalesOrderHeader ; -- Affiche l'année et le mois pour avoir une idée de ma donnée

 --
 SELECT
  YEAR(OrderDate) AS OrderYear,
  MONTH(OrderDate) AS OrderMonth,
  ROUND(SUM(TotalDue), 2) AS TotalRevenue
FROM Sales.SalesOrderHeader
GROUP BY
  YEAR(OrderDate),
  MONTH(OrderDate)
ORDER BY
  OrderYear DESC,
  OrderMonth DESC;

  ----- Chiffres d'affaires par année ----

  SELECT
  YEAR(OrderDate) AS OrderYear,
  ROUND(SUM(TotalDue), 2) AS TotalRevenue
FROM Sales.SalesOrderHeader
GROUP BY
  YEAR(OrderDate)
ORDER BY
  OrderYear DESC;
  
  -- On voit bien que 2013 est l'année la fructueuse avec un chiffre d'affaire : 48965887.82 par rapport à 2014 , 2012, 2011

  -- Recettes Mensuelles par Pays 

SELECT
  cr.Name AS Country,
  YEAR(soh.OrderDate) AS OrderYear,
  MONTH(soh.OrderDate) AS OrderMonth,
  ROUND(SUM(soh.TotalDue), 2) AS TotalRevenue
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.SalesTerritory AS st
  ON soh.TerritoryId = st.TerritoryId
JOIN Person.CountryRegion AS cr
  ON cr.CountryRegionCode = st.CountryRegionCode
GROUP BY
  cr.Name,
  YEAR(soh.OrderDate),
  MONTH(soh.OrderDate)
ORDER BY
  OrderYear DESC,
  OrderMonth DESC,
  Country;


  -----  Produits les plus vendus -----

  SELECT TOP 10
  p.ProductID,
  p.Name AS ProductName,
  SUM(od.OrderQty) AS TotalUnitsSold
FROM Sales.SalesOrderDetail od
JOIN Production.Product p
  ON od.ProductID = p.ProductID
GROUP BY
  p.ProductID, 
  p.Name
ORDER BY
  TotalUnitsSold DESC;

  --- On peut aller plus loin en évaluons nos produits 

  SELECT
  ProductId,
  ROUND(AVG(Rating), 1) AS ProductRating
FROM Production.ProductReview
GROUP BY ProductId;


  --- MAGASINS LES PLUS PERFORMANTS ----

 SELECT
  p.ProductId,
  p.Name AS ProductName,
  SUM(od.OrderQty) AS TotalUnitsSold
FROM Sales.SalesOrderDetail od
JOIN Sales.SalesOrderHeader oh  -- Alias oh pour SalesOrderHeader
  ON od.SalesOrderId = oh.SalesOrderId
JOIN Production.Product p
  ON od.ProductID = p.ProductID
WHERE oh.OrderDate > DATEADD(MONTH, -2, GETDATE())  -- Utilise l'alias oh
GROUP BY
  p.Name,
  p.ProductId
ORDER BY
  TotalUnitsSold DESC;

  -----
  SELECT TOP 5
  COALESCE(s.Name, 'Online') AS StoreName,
  ROUND(SUM(so.TotalDue), 2) AS TotalSalesAmount
FROM Sales.SalesOrderHeader so
LEFT JOIN Sales.Store s
  ON so.SalesPersonId = s.SalesPersonId
GROUP BY s.Name
ORDER BY TotalSalesAmount DESC;-- Cette requete retourne les 10 magasins ou les 10 commandes en lignes avec le montant total des ventes pour les deux derniers mois.

-------- Sources de Revenus------
---- Je veux voir Comment les revenus en ligne se comparent-ils aux revenus hors ligne ?
SELECT
  CASE 
    WHEN OnlineOrderFlag = 1 THEN 'Online'
    ELSE 'Store'
  END AS OrderOrigin,
  COUNT(SalesOrderId) AS TotalSales,
  SUM(TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader
GROUP BY OnlineOrderFlag
ORDER BY TotalRevenue DESC;

-- Nous pouvons clairement voir une conclusion : 
---Les magasins physiques réalisent presque 10 fois moins de ventes mais produisent 3 fois plus de revenus que les magasins en ligne

-- Essayons de voir le mois le plus fructueux par année que ça soit en ligne ou en magasin.

SELECT
  CASE 
    WHEN OnlineOrderFlag = 1 THEN 'Online'
    ELSE 'Store'
  END AS OrderOrigin,
  YEAR(OrderDate) AS OrderYear,                -- Extraction de l'année
  MONTH(OrderDate) AS OrderMonth,             -- Extraction du mois
  COUNT(SalesOrderId) AS TotalSales,
  SUM(TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader
GROUP BY
  YEAR(OrderDate),                             -- Groupement par année
  MONTH(OrderDate),                            -- Groupement par mois
  OnlineOrderFlag                              -- Groupement par origine (en ligne ou en magasin)
ORDER BY
  OrderOrigin,                                 -- Tri par origine
  OrderYear DESC,                              -- Tri par année décroissante
  OrderMonth DESC;                             -- Tri par mois décroissant

  ---- Taille moyenne des commandes par pays ---

  -- Je commence par regarder le montant moyen des commandes ---
  WITH OrderSizes AS (
  SELECT
    sod.SalesOrderId,
    SUM(sod.OrderQty) AS ProductCount,  -- Total des quantités de produits par commande
    cr.Name AS Country                  
  FROM Sales.SalesOrderHeader soh
  JOIN Sales.SalesOrderDetail sod
    ON sod.SalesOrderId = soh.SalesOrderId  
  JOIN Sales.SalesTerritory st
    ON soh.TerritoryId = st.TerritoryId     
  JOIN Person.CountryRegion cr
    ON cr.CountryRegionCode = st.CountryRegionCode  
  GROUP BY
    sod.SalesOrderId,                       
    cr.Name                                 
)
SELECT *
FROM OrderSizes;

  --- Je regroupe les résultats par pays -----

  WITH OrderSizes AS (
  SELECT
    sod.SalesOrderId,
    SUM(sod.OrderQty) AS ProductCount,  -- Total des quantités de produits par commande
    cr.Name AS Country                  -- 
  FROM Sales.SalesOrderHeader soh
  JOIN Sales.SalesOrderDetail sod
    ON sod.SalesOrderId = soh.SalesOrderId  -- Jointure entre commandes et détails
  JOIN Sales.SalesTerritory st
    ON soh.TerritoryId = st.TerritoryId     -- Jointure pour obtenir le territoire
  JOIN Person.CountryRegion cr
    ON cr.CountryRegionCode = st.CountryRegionCode  -- Jointure pour obtenir le pays
  GROUP BY
    sod.SalesOrderId,                       -- Groupement par ID de commande
    cr.Name                                 
)
SELECT
  Country,                                  -- Nom du pays
  CAST(AVG(ProductCount) AS DECIMAL(10, 2)) AS AverageOrderSize  -- Taille moyenne des commandes
FROM OrderSizes
GROUP BY Country                            -- Groupement par pays
ORDER BY AverageOrderSize DESC;            


----Valeur moyenne des clients à vie par région-----

---Quelle est la valeur moyenne de la durée de vie des clients dans chaque région ?

SELECT
  cs.CustomerId,                              -- Identifiant du client
  cs.TerritoryId,                             -- Identifiant du territoire
  SUM(ord.TotalDue) AS LifetimeRevenues       -- Revenus totaux accumulés par client
FROM Sales.Customer cs
JOIN Sales.SalesOrderHeader ord
  ON cs.CustomerId = ord.CustomerId           -- Jointure sur l'identifiant du client
GROUP BY
  cs.CustomerId,                              -- Groupement par client
  cs.TerritoryId;                             -- Groupement par territoire
   
   -- La moitié du problème étant réolue , on regroupe les données pour chaque pays

WITH CustomerLifetimeRevenue AS (
  SELECT
    cstm.CustomerId,                          -- Identifiant du client
    ord.TerritoryId,                          -- Identifiant du territoire
    SUM(ord.TotalDue) AS LifetimeRevenue      -- Revenus totaux du client
  FROM Sales.Customer cstm
  JOIN Sales.SalesOrderHeader ord
    ON cstm.CustomerId = ord.CustomerId       -- Jointure entre clients et commandes
  GROUP BY
    cstm.CustomerId,
    ord.TerritoryId                           -- Groupement par client et territoire
)
SELECT
  cr.Name AS Country,                         -- Nom du pays
  ROUND(AVG(clr.LifetimeRevenue), 2) AS AvgLifetimeCustomerValue  -- Moyenne des revenus clients
FROM CustomerLifetimeRevenue clr
JOIN Sales.SalesTerritory tr
  ON clr.TerritoryId = tr.TerritoryId         -- Jointure avec les territoires
JOIN Person.CountryRegion cr
  ON cr.CountryRegionCode = tr.CountryRegionCode  -- Jointure avec les régions par pays
GROUP BY cr.Name                              -- Groupement par pays
ORDER BY
  AvgLifetimeCustomerValue DESC,             -- Tri par valeur moyenne décroissante
  cr.Name;                                   -- Tri secondaire par nom du pays



  
