
-- lists employees with the number of customers they manage, sorted from most to least customers.
SELECT e.EmployeeID, e.FullName, COUNT(ec.CustomerID) AS TotalCustomers 
FROM Employees e 
INNER JOIN Employees_Customers ec ON e.EmployeeID = ec.EmployeeID 
GROUP BY e.EmployeeID
ORDER BY TotalCustomers DESC ;

-- retrieves cards expiring between January 13, 2027, and March 13, 2027, along with their type and the cardholder’s name.
SELECT c.CardID, c.CardType, c.ExpiryDate, cu.FullName 
FROM Cards c 
INNER JOIN Accounts a ON c.AccountID = a.AccountID 
INNER JOIN Customers cu ON a.CustomerID = cu.CustomerID 
WHERE c.ExpiryDate BETWEEN  '2027-01-13' AND '2027-03-13';


-- lists customers whose loan amount is greater than the average loan amount, ordered by customer ID.
SELECT  c.CustomerID, c.FullName, l.Amount FROM Loans l
INNER JOIN Customers c ON c.CustomerID = l.CustomerID
WHERE l.Amount > ( SELECT AVG(Amount) FROM Loans)
order by c.customerID ;


-- creates a stored procedure that retrieves a specific loan’s amount and total paid, then calls it for loan ID 114.
DELIMITER $$
CREATE PROCEDURE GetLoanDetails(IN loan_id INT)
BEGIN
    SELECT l.LoanID, l.Amount, SUM(lp.AmountPaid) AS TotalPaid
    FROM loans l
    LEFT JOIN loanpayments lp ON l.LoanID = lp.LoanID
    WHERE l.LoanID = loan_id
    GROUP BY l.LoanID, l.Amount;
END $$
DELIMITER ;
CALL GetLoanDetails(114);


-- creates a table showing each loan’s original amount, total paid, and remaining balance, then displays it.
CREATE TABLE loan_remaining_balance AS
SELECT l.LoanID, l.Amount AS original_amount,
    SUM(lp.AmountPaid) AS total_paid,(l.Amount - SUM(lp.AmountPaid)) AS remaining_balance
FROM Loans l
LEFT JOIN LoanPayments lp ON l.LoanID = lp.LoanID
GROUP BY l.LoanID, l.Amount;

SELECT * FROM loan_remaining_balance ;


-- creates a table of loans that are overdue and less than 50% repaid, then displays its contents.
CREATE TABLE overdue_loans AS
SELECT l.LoanID, l.CustomerID, l.Amount AS loan_amount,
    SUM(lp.AmountPaid) AS total_paid, l.EndDate,
    SUM(lp.AmountPaid) / l.Amount AS repayment_ratio FROM Loans l
LEFT JOIN LoanPayments lp ON lp.LoanID = l.LoanID
GROUP BY l.LoanID, l.CustomerID, l.Amount, l.EndDate
HAVING l.EndDate < CURRENT_DATE()       
AND SUM(lp.AmountPaid) < 0.5 * l.Amount;  

SELECT * FROM overdue_loans;


-- retrieves customers whose total loan amount is greater than the average loan amount, sorted by customer ID.
SELECT c.CustomerID, c.FullName, SUM(l.Amount) AS TotalLoanAmount FROM Loans l
INNER JOIN Customers c ON c.CustomerID = l.CustomerID
GROUP BY c.CustomerID
HAVING SUM(l.Amount) > (SELECT AVG(Amount) FROM Loans)
ORDER BY c.CustomerID;

-- lists all customers who do not have any loans.
SELECT c.CustomerID, c.FullName
FROM Customers c
LEFT JOIN Loans l ON c.CustomerID = l.CustomerID
WHERE l.LoanID IS NULL;

-- retrieves the top 5 customers with the highest number of transactions, sorted in descending order.
SELECT c.CustomerID, c.FullName, COUNT(t.TransactionID) AS NumOfTransactions
FROM Customers c
JOIN accounts a ON c.CustomerID = a.CustomerID
JOIN transactions t ON a.AccountID = t.AccountID
GROUP BY c.CustomerID, c.FullName
ORDER BY NumOfTransactions DESC
LIMIT 5;

-- Loans that expire within 3 months from now
SELECT l.LoanID, c.FullName, l.Amount, l.EndDate,
 DATEDIFF(l.EndDate, '2025-08-11') AS DaysLeft
FROM Loans l
JOIN Customers c ON l.CustomerID = c.CustomerID
WHERE l.EndDate > '2025-08-11' AND DATEDIFF(l.EndDate, '2025-08-11') <= 90
ORDER BY l.EndDate ASC;

-- Calculate loan status based on amount: small, medium, large
SELECT l.LoanID, c.FullName, l.Amount,
  CASE 
    WHEN l.Amount < 50000 THEN 'Small'
    WHEN l.Amount BETWEEN 50000 AND 200000 THEN 'Medium'
    ELSE 'Large'
  END AS LoanSizeCategory
FROM Loans l
JOIN Customers c ON l.CustomerID = c.CustomerID;

-------------------------------------------------------------------------------------------------
-- Find customers who are missing an email address
-- or phone number. This is important for
-- improving customer communication.
SELECT CustomerID, FullName, Email, Phone
FROM Customers
WHERE Email IS NULL OR Email = ''
   OR Phone IS NULL OR Phone = '';

-- List loans where the end date has passed but 
-- the loan is still active, indicating overdue repayments.
SELECT LoanID, CustomerID, LoanType, Amount, EndDate, Status
FROM Loans
WHERE EndDate < CURDATE() AND Status = 'Active';

-- Rank customers by the total amount of
-- loans they have taken, from highest to lowest.
SELECT c.CustomerID, c.FullName, COUNT(l.LoanID) AS NumberOfLoans,
 SUM(l.Amount) AS TotalLoanAmount
FROM Customers c
LEFT JOIN Loans l ON c.CustomerID = l.CustomerID
GROUP BY c.CustomerID, c.FullName
ORDER BY TotalLoanAmount DESC;

-- Find customers who do not have any linked
-- bank accounts, which is important for follow-up.
SELECT c.CustomerID, c.FullName
FROM Customers c
LEFT JOIN Accounts a ON c.CustomerID = a.CustomerID
WHERE a.AccountID IS NULL;

-- Detect accounts with a balance less than 10000 currency 
-- units, useful for monitoring low-balance or near-closed accounts.
SELECT AccountID, CustomerID, Balance
FROM Accounts
WHERE Balance < 10000;

-- Show each customer, their assigned employee, and the date of their 
-- last transaction, sorted by oldest transaction first to prioritize follow-up.
SELECT c.CustomerID, c.FullName, e.EmployeeID, e.FullName AS EmployeeName,
  MAX(t.TransactionDate) AS LastTransactionDate
FROM Customers c
JOIN Employees_Customers ec ON c.CustomerID = ec.CustomerID
JOIN Employees e ON ec.EmployeeID = e.EmployeeID
JOIN Accounts a ON c.CustomerID = a.CustomerID
JOIN Transactions t ON a.AccountID = t.AccountID
GROUP BY c.CustomerID, c.FullName, e.EmployeeID, e.FullName
ORDER BY LastTransactionDate ASC;
