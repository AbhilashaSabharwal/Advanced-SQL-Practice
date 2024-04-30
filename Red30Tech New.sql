--- SET PK FOR ONLINE RETAIL SALES
  -- First, Make cols Non-Nullable
  ALTER TABLE dbo.OnlineRetailSales
  ALTER COLUMN OrderNum float NOT NULL
  GO
  
  -- Identify OrderNum as the Primary Key of this table
  ALTER TABLE dbo.OnlineRetailSales add primary key (OrderNum) 
  GO
  
  --- SET PK FOR SESSION INFO 
  -- First, Make cols Non-Nullable
  ALTER TABLE dbo.SessionInfo
  ALTER COLUMN [Start Date] datetime NOT NULL
  GO 

  ALTER TABLE dbo.SessionInfo
  ALTER COLUMN [End Date] datetime NOT NULL
  GO

  ALTER TABLE dbo.SessionInfo
  ALTER COLUMN [Session Name] nvarchar(255) NOT NULL
  GO 
  
  -- Identify Start Date, End Date, and Session name as the Primary Key of this table
  ALTER TABLE dbo.SessionInfo add primary key ([Start Date],[End Date],[Session Name]) 
  GO

  --- SET PK FOR SPEAKER INFO
  -- First, Make cols Non-Nullable
  ALTER TABLE dbo.SpeakerInfo
  ALTER COLUMN [Name] nvarchar(255) NOT NULL
  GO 

  ALTER TABLE dbo.SpeakerInfo
  ALTER COLUMN [Session Name] nvarchar(255) NOT NULL
  GO

  -- Identify Name and Session Name as the Primary Key of this table
  -- Some session topics are duplicates of each other but they are delivered by different speakers
  ALTER TABLE dbo.SpeakerInfo add primary key ([Name],[Session Name]) 
  GO
  
  --- SET PK FOR CONFERENCE ATTENDEES
  -- First, Make cols Non-Nullable
  ALTER TABLE dbo.ConventionAttendees
  ALTER COLUMN [Email] nvarchar(255)  NOT NULL
  GO
  
  -- Identify Email as the Primary Key of this table
  ALTER TABLE dbo.ConventionAttendees add primary key (Email) 
  GO
  
  --- SET PK FOR INVENTORY
  -- First, Make cols Non-Nullable
  ALTER TABLE dbo.Inventory
  ALTER COLUMN ProdNumber nvarchar(255) NOT NULL
  GO

  ALTER TABLE dbo.Inventory
  ALTER COLUMN ProdName nvarchar(255) NOT NULL
  GO
  
  -- Identify ProdNumber and ProdName as the composite Primary Key of this table
  ALTER TABLE dbo.Inventory add primary key ([ProdNumber],[ProdName])
  GO
  
  --- SET PK FOR EMPLOYEE DIRECTORY
  -- First, Make cols Non-Nullable
  ALTER TABLE dbo.EmployeeDirectory
  ALTER COLUMN EmployeeID nvarchar(255) NOT NULL
  GO
  
  -- Identify EmployeeID as the composite Primary Key of this table
  ALTER TABLE dbo.EmployeeDirectory add primary key ([EmployeeID])
  GO

  -- SCALAR SUBQUERIES
  SELECT *
  FROM OnlineRetailSales
  WHERE [Order Total] >= 
						(SELECT AVG([Order Total]) FROM OnlineRetailSales) ; 

SELECT *, (SELECT AVG([Order Total]) FROM OnlineRetailSales) AS AvgOrderTotal
  FROM OnlineRetailSales
  WHERE [Order Total] >= 
						(SELECT AVG([Order Total]) FROM OnlineRetailSales)
ORDER BY [Order Total] DESC; 

-- MULTI ROW SUBQUERIES AND UNCORRELATED SUBQUERIES
SELECT [Speaker Name], [Session Name], [Start Date], [End Date], [Room Name]
FROM SessionInfo
WHERE [Speaker Name] IN 
						(SELECT Name
						 FROM SpeakerInfo
						 WHERE Organization = 'Two Trees Olive Oil') ; 

SELECT [Speaker Name], [Session Name], [Start Date], [End Date], [Room Name]
FROM SessionInfo AS A 
INNER JOIN  (SELECT Name
			FROM SpeakerInfo AS B 
			WHERE Organization = 'Two Trees Olive Oil') AS Speak
ON A.[Speaker Name] = Speak.Name ; 

-- CORRELATED SUBQUERIES
SELECT [First name], [Last name], Email, [Phone Number], State
FROM ConventionAttendees AS C
WHERE NOT EXISTS
				(SELECT CustName 
				FROM OnlineRetailSales AS O
				WHERE C.State = O.CustState) ; 

-- CHALLENGE
SELECT ProdCategory, ProdNumber, ProdName, [In Stock]
FROM Inventory
WHERE [In Stock] <=
					(SELECT AVG([In Stock]) 
					FROM Inventory) ; 

-- NON RECURSIVE CTE
WITH AvgTotal ([Avg_Total]) AS
	(SELECT AVG([Order Total]) AS Avg_Total
	FROM OnlineRetailSales) 
SELECT *
FROM OnlineRetailSales, AvgTotal
WHERE [Order Total] >= Avg_Total;

WITH AvgTotal AS
	(SELECT AVG([Order Total]) AS Avg_Total
	FROM OnlineRetailSales) 
SELECT *
FROM OnlineRetailSales, AvgTotal
WHERE [Order Total] >= Avg_Total;

--RECURSIVE CTE
WITH DirectReports AS
	(SELECT EmployeeID, [First Name], [Last Name], Manager
	FROM EmployeeDirectory
	WHERE EmployeeID= 42
	UNION ALL
	SELECT E.EmployeeID, E.[First Name], E.[Last Name], E.Manager
	FROM EmployeeDirectory AS E
	INNER JOIN DirectReports AS D
	ON E.Manager = D.EmployeeID)

	with DirectReports AS (
	SELECT E.EmployeeID, E.[First Name], E.[Last Name], E.Manager
	FROM EmployeeDirectory AS E
	WHERE E.Manager = 42
	)
SELECT COUNT (*) AS DirectReports
FROM DirectReports
WHERE EmployeeID != 42 ;

--CHALLENGE
WITH AvgInStock (Avg_InStock) AS (
		SELECT AVG([In Stock]) AS Avg_InStock
		FROM Inventory)
SELECT ProdCategory, ProdNumber, ProdName, [In Stock], Avg_InStock
FROM Inventory, AvgInStock
WHERE [In Stock] < Avg_InStock ; 

-- WINDOWS FUNCTION ROW_NUMBER
SELECT OrderNum, OrderDate, CustName, ProdName, Quantity,
ROW_NUMBER() OVER(PARTITION BY [CustName] ORDER BY [OrderDate] DESC) AS RowNo
FROM OnlineRetailSales ; 

WITH ROWNUMBERS AS (
	SELECT OrderNum, OrderDate, CustName, ProdName, Quantity,
	ROW_NUMBER() OVER(PARTITION BY [CustName] ORDER BY [OrderDate] DESC) AS RowNo
	FROM OnlineRetailSales)
SELECT *
FROM ROWNUMBERS
WHERE RowNo = 1 ;

--CHALLENGE
WITH RowNumbers AS(
	SELECT OrderNum, OrderDate, CustName, ProdCategory, ProdName, [Order Total],
	ROW_NUMBER() OVER(PARTITION BY ProdCategory ORDER BY [Order Total] DESC) AS HighestOrders
	FROM OnlineRetailSales
	WHERE CustName= 'Boehm Inc.')
SELECT *
FROM RowNumbers
WHERE HighestOrders IN (1,2,3)
ORDER BY ProdCategory, [Order Total] DESC ;

-- LAG AND LEAD() FUNCTIONS
SELECT [Start Date], [End Date], [Session Name],
	LAG([Session Name],1) OVER (ORDER BY [Start Date] ASC) AS PreviousSession,
	LAG([Start Date],1) OVER (ORDER BY [Start Date] ASC) AS PreviousSessionStartTime,
	LEAD([Session Name],1) OVER (ORDER BY [Start Date] ASC) AS NextSession,
	LEAD([Start Date],1) OVER (ORDER BY [Start Date] ASC) AS NextSessionStartTime
FROM SessionInfo
WHERE [Room Name] = 'Room 102' ; 

--CHALLENGE
WITH Orders_By_Day AS (
						SELECT OrderDate, SUM(Quantity) AS Quantity_By_Day
						FROM OnlineRetailSales
						WHERE ProdCategory= 'Drones'
						GROUP BY OrderDate
						)
SELECT OrderDate, Quantity_By_Day,
LAG(Quantity_By_Day,1) OVER(ORDER BY OrderDate ASC) AS LastOrderQuantity1,
LAG(Quantity_By_Day,2) OVER(ORDER BY OrderDate ASC) AS LastOrderQuantity2,
LAG(Quantity_By_Day,3) OVER(ORDER BY OrderDate ASC) AS LastOrderQuantity3,
LAG(Quantity_By_Day,4) OVER(ORDER BY OrderDate ASC) AS LastOrderQuantity4,
LAG(Quantity_By_Day,5) OVER(ORDER BY OrderDate ASC) AS LastOrderQuantity5
FROM Orders_By_Day ; 

--RANKING FUNCTIONS RANK & DENSE RANK()
SELECT *,
RANK() OVER(ORDER BY [Last Name]) AS Rank_,
DENSE_RANK() OVER(ORDER BY [Last Name]) AS DenseRank_
FROM EmployeeDirectory ; 

--CHALLENGE
WITH Ranks AS(
				SELECT *, 
				RANK() OVER(PARTITION BY [State] ORDER BY [Registration Date] ASC) AS Rank_,
				DENSE_RANK() OVER(PARTITION BY [State] ORDER BY [Registration Date] ASC) AS DenseRank_
				FROM ConventionAttendees
				)
SELECT *
FROM Ranks
WHERE DenseRank_ IN (1,2,3); 