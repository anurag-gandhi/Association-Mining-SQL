
SELECT DISTINCT
  NatureKey,
  CONCAT(RecipientKey, ManufacturerKey, DateKey) AS TransactionID INTO [master].[dbo].IDs
FROM [master].[dbo].FactPaymentTransaction

SELECT
  intersection.*,
  b.TransactionsA,
  c.TransactionsB INTO [master].[dbo].[Combinations]
FROM (SELECT
  NatureA,
  NatureB,
  COUNT(DISTINCT TransactionID) AS Transactions
FROM (SELECT
  a.NatureKey AS NatureA,
  a.TransactionID,
  b.NatureKey AS NatureB
FROM [master].[dbo].IDs AS a
INNER JOIN [master].[dbo].IDs AS b
  ON a.TransactionID = b.TransactionID
WHERE b.NatureKey != a.NatureKey) AS a
GROUP BY NatureA,
         NatureB) AS intersection
LEFT JOIN (SELECT
  NatureKey,
  COUNT(*) AS TransactionsA
FROM [master].[dbo].IDs
GROUP BY NatureKey) AS b
  ON intersection.NatureA = b.NatureKey
LEFT JOIN (SELECT
  NatureKey,
  COUNT(*) AS TransactionsB
FROM [master].[dbo].IDs
GROUP BY NatureKey) AS c
  ON intersection.NatureB = c.NatureKey

ALTER TABLE [master].[dbo].[Combinations]
ADD Total_Transactions real,
Support_A real,
Support_B real,
Support_AB real,
Lift real





UPDATE [master].[dbo].[Combinations]
SET Total_Transactions = (SELECT
  COUNT(DISTINCT CONCAT(RecipientKey, ManufacturerKey, DateKey)) AS Total_Transactions
FROM [master].[dbo].FactPaymentTransaction)

UPDATE [master].[dbo].[Combinations]
SET Support_A = TransactionsA / Total_Transactions,
    Support_B = TransactionsB / Total_Transactions,
    Support_AB = Transactions / Total_Transactions

UPDATE [master].[dbo].[Combinations]
SET Lift = (Support_AB) / (Support_A * Support_B)


SELECT
  *
FROM (SELECT
  b.Nature_of_Payment AS NatureA_Name,
  c.Nature_of_Payment AS NatureB_Name,
  RANK() OVER (PARTITION BY a.NatureA ORDER BY a.Lift DESC) AS Association_Rank
FROM [master].[dbo].[Combinations] AS a
LEFT JOIN [master].[dbo].DimNatureOfPayment AS b
  ON a.NatureA = b.NatureKey
LEFT JOIN [master].[dbo].DimNatureOfPayment AS c
  ON a.NatureB = c.NatureKey
  WHERE TransactionsA > 5 AND TransactionsB > 5 AND Transactions > 5
  AND b.Active_indicator = 1) AS a
WHERE Association_Rank <= 5


DROP TABLE [master].[dbo].IDs
DROP TABLE [master].[dbo].[Combinations]