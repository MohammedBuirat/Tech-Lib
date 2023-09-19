select Borrower_Id from Loans
DECLARE @Borro INT;
SET @Borro = 1;

SELECT * FROM Loans b 
Where b.Borrower_Id = @Borro
AND b.Date_Returned IS NULL;



WITH BorrowerWithMoreThanBook (Borrower_Id) 
AS(
    SELECT a.Borrower_Id
    FROM Borrowers a
    INNER JOIN Loans b ON a.Borrower_Id = b.Borrower_Id  -- Corrected the join condition
    WHERE b.Date_Returned IS NULL
    GROUP BY a.Borrower_Id
    HAVING COUNT(*) > 1
)
select * from BorrowerWithMoreThanBook

GO

SELECT a.Borrower_id , RANK() OVER (ORDER BY COUNT(*)) AS RANK
FROM Borrowers a INNER JOIN
Loans b ON a.Borrower_Id = b.Borrower_Id
GROUP BY a.Borrower_Id

DECLARE @Month INT;
SET @Month = 5;

SELECT TOP 1 a.Genre,COUNT(*),RANK() OVER(ORDER BY COUNT(*) DESC)
FROM Books a INNER JOIN 
Loans b ON a.Book_Id = b.Book_Id
WHERE (SELECT MONTH(b.Date_Borrowed)) = @Month 
GROUP BY a.Genre

GO

CREATE PROCEDURE sp_AddNewBorrower
	@First_Name VARCHAR(30),
	@Last_Name VARCHAR(30),
	@Email VARCHAR(50),
	@Date_Of_Birth DATE,
	@Membership_Date DATE
AS
BEGIN
	insert into Borrowers (First_Name, Last_Name, Email, Date_Of_Birth, Membership_Date) values (@First_Name, 
	@Last_Name, @Email, @Date_Of_Birth, @Membership_Date);
	select MAX(Borrower_Id) as max
	from Borrowers;
END;

GO
CREATE FUNCTION fn_CalculateOverdueFees (@Loan_Id INT)
RETURNS INT
AS
BEGIN
    DECLARE @Total int;
	DECLARE @Return_Date DATE;
	DECLARE @Borrow_Date DATE;
	DECLARE @DUE_Date DATE;
	SELECT @Return_Date = Date_Returned, @Borrow_Date = Date_Borrowed, @Due_Date = Due_Date
    FROM Loans
    WHERE Loan_Id = @Loan_Id;

	SET @Total = 0;
	IF @Return_Date IS NULL
	BEGIN
		SET @Return_Date = GETDATE();
	END

	IF @Return_Date > @DUE_Date
	BEGIN
		DECLARE @Day_Diff INT;
		SET  @Day_Diff = DATEDIFF(day, @DUE_Date, @Return_Date);
		IF @Day_Diff > 30
		BEGIN
			SET @Total = (@Day_Diff - 30)*2;
			SET @Day_Diff = @Day_Diff - 30;
		END
		SET  @Total = @Total + @Day_Diff;
	END
	RETURN @Total;
END;

SELECT dbo.fn_CalculateOverdueFees(29) AS FEES;

GO;

CREATE FUNCTION fn_BookBorrowingFrequency(@Book_Id INT)
RETURNS INT
AS
BEGIN
	DECLARE @Res INT;
	SELECT @RES = COUNT(*)
	FROM Loans a WHERE a.Book_Id = @Book_Id;
	RETURN @RES;

END

Select dbo.fn_BookBorrowingFrequency(1) AS NUM;

GO

SELECT Book_Id
from Loans Where Date_Returned > (DATEADD(day,30, Due_Date));

Select a.Author,COUNT(*) AS [Number Of Borroweing]
FROM Books a INNER JOIN
Loans b ON a.Book_Id = b.Book_Id
GROUP BY a.Author
order by[Number Of Borroweing]

GO

WITH Age_Counts as (
SELECT (DATEDIFF(year, a.Date_Of_Birth, GETDATE()) / 10) * 10 AS Age, T1.Genre, COUNT(*) Count_Per_Age
FROM Borrowers a
INNER JOIN (
    SELECT c.Genre, b.Borrower_Id
    FROM Loans b
    INNER JOIN Books c ON b.Book_Id = c.Book_Id
) AS T1 ON T1.Borrower_Id = a.Borrower_Id
GROUP BY (DATEDIFF(year, a.Date_Of_Birth, GETDATE()) / 10) * 10, T1.Genre
)

SELECT CONVERT(NVARCHAR(5), A.Age)+'-'+CONVERT(NVARCHAR(5), A.Age+10), A.Genre, A.Count_Per_Age
FROM Age_Counts A
INNER JOIN (
    SELECT Age, MAX(Count_Per_Age) AS Max_Count_Per_Age
    FROM Age_Counts
    GROUP BY Age
) AS MaxCounts ON A.Age = MaxCounts.Age AND A.Count_Per_Age = MaxCounts.Max_Count_Per_Age
ORDER BY A.Age;

GO

CREATE PROCEDURE sp_BorrowedBooksReport
@StartDate DATE,
@EndDate DATE
AS
BEGIN
	SELECT  DISTINCT a.Book_Id From Loans a Where a.Date_Borrowed >= @StartDate
	AND a.Date_Borrowed <= @EndDate;
END

DECLARE @E DATE = GETDATE();; 
DECLARE @S DATE = '2020-12-12';

EXEC sp_BorrowedBooksReport @S, @E;


CREATE TABLE AuditLog (
	
	Book_Id int FOREIGN KEY REFERENCES Books(Book_Id),
	Status_Change varchar(30),
	Change_Date Date
);

GO
CREATE TRIGGER Change_Book_Status
ON Books
AFTER UPDATE
AS
BEGIN
	DECLARE @Stat VARCHAR(30);
	DECLARE @Id int;
	SELECT @Stat = Current_Status,@Id = Book_Id FROM inserted;
	INSERT INTO AuditLog(Book_Id,Status_Change,Change_Date) VALUES (@Id,@Stat,GETDATE());
END

GO

CREATE PROCEDURE sp_Stored_Procedure_With_Temp_Table
AS
BEGIN
	DROP TABLE IF EXISTS #Temp;
	CREATE TABLE #Temp (
	Borrower_Id int
	);
	INSERT INTO  #Temp(Borrower_Id) 
	SELECT DISTINCT a.Borrower_Id FROM Loans a
	WHERE a.Date_Returned > a.Due_Date OR
	(a.Date_Returned IS NULL AND a.Due_Date < GETDATE());

	Select t.Borrower_Id,a.Book_Id
	FROM  #Temp t INNER JOIN Loans a
	ON t.Borrower_Id = a.Borrower_Id
	WHERE a.Date_Returned > a.Due_Date OR
	(a.Date_Returned IS NULL AND a.Due_Date < GETDATE());
END

GO

DECLARE @Total INT;
SELECT @Total = count(*) from Loans;
SELECT  TOP 3 DATENAME(DW,a.Date_Borrowed) AS Day_Of_The_Week,
CONVERT(NVARCHAR(50), CAST((100.0 * COUNT(*)) / @Total AS DECIMAL(10, 2))) + '%' AS Percentage
from Loans a
GROUP BY DATENAME(DW,a.Date_Borrowed)
ORDER BY COUNT(*) DESC;


