/* 1. Tanım Sorusu: Northwind veritabanında kaç tablo olduğunu ve tabloların isimlerini listeleyiniz. */
-- Toplam tablo sayısı
SELECT COUNT(*) AS TableCount
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE';
GO

-- Tabloların isimleri
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE';
GO

/* 2. JOIN Sorusu: Her sipariş için müşteri, şirket adı, çalışan adı, sipariş tarihi ve gönderici (Shipper) adını listeleyiniz. */
SELECT o.OrderID,
       c.CompanyName,
       CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeFullName,
       o.OrderDate,
       s.CompanyName AS ShipperName
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN Employees e ON o.EmployeeID = e.EmployeeID
JOIN Shippers s ON o.ShipVia = s.ShipperID;
GO

/* 3. Aggregate Fonksiyon: Tüm siparişlerin toplam tutarını (Quantity * UnitPrice) hesaplayınız. */
SELECT SUM(Quantity * UnitPrice) AS TotalOrderAmount
FROM [Order Details];
GO

/* 4. Gruplama: Hangi ülkeden kaç müşteri olduğunu listeleyiniz. */
SELECT Country, COUNT(*) AS CustomerCount
FROM Customers
GROUP BY Country;
GO

/* 5. Subquery Kullanımı: En pahalı ürünün adını ve fiyatını listeleyiniz. */
SELECT ProductName, UnitPrice
FROM Products
WHERE UnitPrice = (SELECT MAX(UnitPrice) FROM Products);
GO

/* 6. JOIN ve Aggregate: Her çalışana düşen sipariş sayısını gösteren listeyi oluşturunuz. */
SELECT e.EmployeeID,
       CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeFullName,
       COUNT(o.OrderID) AS OrderCount
FROM Employees e
LEFT JOIN Orders o ON e.EmployeeID = o.EmployeeID
GROUP BY e.EmployeeID, e.FirstName, e.LastName;
GO

/* 7. Tarih Filtreleme: 1997 yılında verilen siparişleri listeleyiniz. */
SELECT *
FROM Orders
WHERE YEAR(OrderDate) = 1997;
GO

/* 8. CASE Kullanımı: Ürünleri fiyat aralıklarına göre “Ucuz”, “Orta” ve “Pahalı” kategorilere ayırınız. */
SELECT ProductName, UnitPrice,
       CASE 
         WHEN UnitPrice < 20 THEN 'Ucuz'
         WHEN UnitPrice >= 20 AND UnitPrice < 50 THEN 'Orta'
         ELSE 'Pahalı'
       END AS PriceCategory
FROM Products;
GO

/* 9. Nested Subquery: En çok sipariş verilen ürünün adını ve sipariş adedini (adet bazında) bulunuz. */
SELECT ProductName, TotalQuantity
FROM (
    SELECT p.ProductName, SUM(od.Quantity) AS TotalQuantity
    FROM [Order Details] od
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY p.ProductName
) AS Sub
WHERE TotalQuantity = (
    SELECT MAX(TotalQuantity)
    FROM (
        SELECT SUM(Quantity) AS TotalQuantity
        FROM [Order Details]
        GROUP BY ProductID
    ) AS Totals
);
GO

/* 10. View Oluşturma: Ürünler ve kategoriler bilgisini birleştiren bir görünüm (view) oluşturunuz. */
CREATE VIEW vw_ProductCategories AS
SELECT p.ProductID, p.ProductName, p.UnitPrice, c.CategoryName
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID;

/* DENEME */
SELECT * FROM vw_ProductCategories;
GO

/* 11. Trigger: Ürün silindiğinde log tablosuna kayıt yapan bir trigger yazınız. */
CREATE TRIGGER trg_ProductDeletion
ON Products
AFTER DELETE
AS
BEGIN
    INSERT INTO ProductDeletionLog (ProductID, DeletedAt)
    SELECT ProductID, GETDATE()
    FROM deleted;
END;

/* DENEME */
CREATE TABLE ProductDeletionLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT,
    DeletedAt DATETIME
);

DELETE FROM [Order Details] WHERE ProductID = 1;
DELETE FROM Products WHERE ProductID = 1;
SELECT * FROM ProductDeletionLog;
GO

/* 12. Stored Procedure: Belirli bir ülkeye ait müşterileri listeleyen bir stored procedure yazınız. */
CREATE PROCEDURE sp_GetCustomersByCountry
    @Country NVARCHAR(50)
AS
BEGIN
    SELECT *
    FROM Customers
    WHERE Country = @Country;
END;

/* DENEME */
EXEC sp_GetCustomersByCountry @Country = 'Germany';
GO

/* 13. Left Join Kullanımı: Tüm ürünlerin tedarikçi bilgilerini, varsa tedarikçi adıyla listeleyiniz. */
SELECT p.ProductName, s.CompanyName AS SupplierName
FROM Products p
LEFT JOIN Suppliers s ON p.SupplierID = s.SupplierID;
GO

/* 14. Fiyat Ortalamasının Üzerindeki Ürünler: Fiyatı ortalamanın üzerinde olan ürünleri listeleyiniz. */
SELECT ProductName, UnitPrice
FROM Products
WHERE UnitPrice > (SELECT AVG(UnitPrice) FROM Products);
GO

/* 15. En Çok Ürün Satan Çalışan: Sipariş detaylarına göre en çok ürün satan çalışanı bulunuz. */
SELECT TOP 1 e.EmployeeID,
       CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeFullName,
       SUM(od.Quantity) AS TotalProductsSold
FROM Employees e
JOIN Orders o ON e.EmployeeID = o.EmployeeID
JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY e.EmployeeID, e.FirstName, e.LastName
ORDER BY TotalProductsSold DESC;
GO

/* 16. Ürün Stoğu Kontrolü: Stok miktarı 10’un altında olan ürünleri listeleyiniz. */
SELECT ProductName, UnitsInStock
FROM Products
WHERE UnitsInStock < 10;
GO

/* 17. Şirketlere Göre Sipariş Sayısı: Her müşteri şirketinin yaptığı sipariş sayısını ve toplam harcamasını bulunuz. */
SELECT c.CompanyName, 
       COUNT(o.OrderID) AS OrderCount, 
       SUM(od.Quantity * od.UnitPrice) AS TotalSpent
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY c.CompanyName;
GO

/* 18. En Fazla Müşterisi Olan Ülke: Müşteri sayısı en yüksek olan ülkeyi bulunuz. */
SELECT TOP 1 Country, COUNT(*) AS CustomerCount
FROM Customers
GROUP BY Country
ORDER BY CustomerCount DESC;
GO

/* 19. Her Siparişteki Ürün Sayısı: Her siparişte kaç farklı ürün bulunduğunu listeleyiniz. */
SELECT OrderID, COUNT(DISTINCT ProductID) AS DifferentProductCount
FROM [Order Details]
GROUP BY OrderID;
GO

/* 20. Ürün Kategorilerine Göre Ortalama Fiyat: Her kategori için ortalama ürün fiyatını bulunuz. */
SELECT c.CategoryName, AVG(p.UnitPrice) AS AveragePrice
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryName;
GO

/* 21. Aylık Sipariş Sayısı: Siparişleri yıl ve aya göre gruplandırarak sipariş sayılarını listeleyiniz. */
SELECT DATEPART(YEAR, OrderDate) AS OrderYear,
       DATEPART(MONTH, OrderDate) AS OrderMonth,
       COUNT(*) AS OrderCount
FROM Orders
GROUP BY DATEPART(YEAR, OrderDate), DATEPART(MONTH, OrderDate)
ORDER BY OrderYear, OrderMonth;
GO

/* 22. Çalışanların Müşteri Sayısı: Her çalışanın ilgilendiği (sipariş aldığı) benzersiz müşteri sayısını hesaplayınız. */
SELECT e.EmployeeID,
       CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeFullName,
       COUNT(DISTINCT o.CustomerID) AS CustomerCount
FROM Employees e
JOIN Orders o ON e.EmployeeID = o.EmployeeID
GROUP BY e.EmployeeID, e.FirstName, e.LastName;
GO

/* 23. Hiç Siparişi Olmayan Müşteriler: Sipariş kaydı bulunmayan müşterileri listeleyiniz. */
SELECT c.CompanyName, c.CustomerID
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderID IS NULL;
GO

/* 24. Siparişlerin Nakliye Maliyeti Analizi: Nakliye (Freight) maliyetine göre en yüksek 5 siparişi listeleyiniz. */
SELECT TOP 5 OrderID, Freight
FROM Orders
ORDER BY Freight DESC;
GO
