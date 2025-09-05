/*Which book is the most expensive?
What are the most popular books in each city?
Which is the most bought book?
Which book is least preferred by the readers?
Íàñêîëüêî ïðîäàæè îäíîé è òîé æå êíèãè îòëè÷àþòñÿ â ðàçíûõ ãîðîäàõ? (Íàéòè êíèãó ñ íàèáîëüøèì ðàçáðîñîì â ïðîäàæàõ)
Åñòü ëè êîððåëÿöèÿ ìåæäó öåíîé êíèãè è êîëè÷åñòâîì ïðîäàæ â ðàçíûõ ãîðîäàõ? (Íàéòè êíèãè, ãäå â äîðîãèõ ãîðîäàõ ïðîäàþòñÿ ëó÷øå äåøåâûõ êíèã)
*/


--Which book is the most expensive?

SELECT TOP 1
	Book_ID, Book_Name, Price
FROM
	books
ORDER BY Price DESC;

--What are the most popular books in each city?

SELECT 
	City, Book_ID, Book_Name, Sales
FROM
	(
		SELECT 
			Book_ID, Book_Name, City, Sales, RANK() OVER (PARTITION BY City ORDER BY Sales DESC) as rank
		FROM
			books
	) as ranked
WHERE rank = 1

-- Which is the most bought book?
SELECT TOP 1
	Book_ID, Book_Name, SUM(Sales) as AllSales
FROM
	books
GROUP BY Book_ID, Book_Name
ORDER BY SUM(Sales) DESC

-- Íàñêîëüêî ïðîäàæè îäíîé è òîé æå êíèãè îòëè÷àþòñÿ â ðàçíûõ ãîðîäàõ? (Íàéòè êíèãó ñ íàèáîëüøèì ðàçáðîñîì â ïðîäàæàõ)
SELECT Book_Name, SalesDifference AS diff, RANK() OVER(ORDER BY SalesDifference DESC) AS TopSales
FROM (
SELECT Book_ID, Book_Name, MAX(Sales) AS MaxSales, MIN(Sales) AS MinSales, MAX(Sales) - MIN(Sales) as SalesDifference
FROM books
GROUP BY Book_ID, Book_Name
) AS extremums

-- Åñòü ëè êîððåëÿöèÿ ìåæäó öåíîé êíèãè è êîëè÷åñòâîì ïðîäàæ â ðàçíûõ ãîðîäàõ? (Íàéòè êíèãè, ãäå â äîðîãèõ ãîðîäàõ ïðîäàþòñÿ ëó÷øå äåøåâûõ êíèã)
WITH CityStats AS (
	SELECT
		City, AVG(Price) AS AvgCityPrice
	FROM
	books
	GROUP BY City
),
BookStats AS (
	SELECT b.Book_Name, b.City, c.AvgCityPrice, Price, b.Sales,
	CASE
		WHEN Price > C.AvgCityPrice THEN 'Expensive'
		ELSE 'Cheap'
	END AS Category
	FROM books b
	JOIN CityStats c ON b.City = c.City
),
CityCategoryStats AS (
	SELECT 
		City, Category, SUM(Sales) AS TotalSales, COUNT(*) AS BookCount
	FROM
		BookStats
	GROUP BY City, Category
),
Comparison AS (
	SELECT
		c1.City, c1.TotalSales as ExpensiveSales, c2.TotalSales as CheapSales, c1.TotalSales * 1.0 / NULLIF(c2.TotalSales, 0) AS Ratio
	FROM CityCategoryStats c1
	JOIN CityCategoryStats c2 ON c1.City = c2.City
	WHERE c1.Category = 'Expensive' AND c2.Category = 'Cheap'
)
SELECT City, ExpensiveSales, CheapSales, CAST(FLOOR(Ratio * 100) - 100  AS varchar) + '%' AS PercentDiff,
	CASE 
		WHEN Ratio > 1 THEN 'Expensive books sell better'
		WHEN Ratio < 1 THEN 'Cheap sell better'
	END AS Result

FROM Comparison
