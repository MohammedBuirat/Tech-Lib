Create DATABASE [Tech lib]
use [Tech lib]

CREATE TABLE Books (
    Book_Id INT IDENTITY(1,1) PRIMARY KEY,
    Title VARCHAR(200),
    Author VARCHAR(100),
    ISBN VARCHAR(20),
    Published_Date DATE,
    Genre VARCHAR(30),
    Shelf_Location VARCHAR(50),
    Current_Status VARCHAR(12) CHECK (Current_Status IN('Borrowed', 'Available')) NOT NULL
);


CREATE TABLE Borrowers(
	Borrower_Id INT IDENTITY(1,1) PRIMARY KEY,
	First_Name VARCHAR(30),
	Last_Name VARCHAR(30),
	Email VARCHAR(50) CHECK (Email like '%@%.%') NOT NULL UNIQUE,
	Date_Of_Birth DATE,
	Membership_Date DATE
);

CREATE TABLE Loans(
	Loan_Id int IDENTITY(1,1) PRIMARY KEY,
	Book_Id int FOREIGN KEY REFERENCES Books(Book_Id),
	Borrower_Id INT FOREIGN KEY REFERENCES Borrowers(Borrower_Id),
	Date_Borrowed DATE,
	Due_Date DATE NOT NULL,
	Date_Returned DATE
);


UPDATE books SET Current_Status = 'Available'

UPDATE books SET Current_Status = 'Borrowed' WHERE Book_Id in(
SELECT Book_Id FROM Loans WHERE Date_Returned IS NULL
);


