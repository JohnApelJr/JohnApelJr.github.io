-- 1.	Database Creation
create database HAM_Radio_LARC;
GO
use HAM_Radio_LARC;
GO
/*
    If import wizard doesn't allow options outside of the 'master dataset' import to master move into HAM_Radio_LARC
*/
SELECT * INTO [dbo].[Membership Roster] FROM [master].[dbo].[Membership Roster];
/*
    Import csv using import wizard naming the table "Membership Roster"
    Manual additions to table for removing duplicates and adding Club Officer Roles
*/

-- Removing Duplicates from Dataset
DELETE FROM [dbo].[Membership Roster]
    WHERE Middle_Initial = 'DUPLICATE';
GO

-- Creating Club Officers Column 
ALTER TABLE [dbo].[Membership Roster]
    ADD Club_Officer VARCHAR(50) NULL;

--Club Officers
UPDATE [dbo].[Membership Roster]
SET Club_Officer = 'President'
WHERE First_Name = 'David' AND Last_Name = 'Sepulveda';

UPDATE [dbo].[Membership Roster]
SET Club_Officer = 'Vice President'
WHERE First_Name = 'Salvatore' AND Last_Name = 'Zarbo';

UPDATE [dbo].[Membership Roster]
SET Club_Officer = 'Treasurer'
WHERE First_Name = 'Thomas' AND Last_Name = 'Webb Jr.';

UPDATE [dbo].[Membership Roster]
SET Club_Officer = 'Secretary'
WHERE First_Name = 'Genevieve' AND Last_Name = 'Griesbaum';

--Board of Directors
UPDATE [dbo].[Membership Roster]
SET Club_Officer = 'Director'
WHERE First_Name = 'Charles' AND Last_Name = 'Lawson';

UPDATE [dbo].[Membership Roster]
SET Club_Officer = 'Director'
WHERE First_Name = 'Ryan' AND Last_Name = 'Buono';

UPDATE [dbo].[Membership Roster]
SET Club_Officer = 'Director'
WHERE First_Name = 'Robert' AND Last_Name = 'Delamater';

UPDATE [dbo].[Membership Roster]
SET Club_Officer = 'Director'
WHERE First_Name = 'Joseph' AND Last_Name = 'Fox Jr.';

--Chairman
UPDATE [dbo].[Membership Roster]
SET Club_Officer = 'Hamfest Chairman'
WHERE First_Name = 'Luke' AND Last_Name = 'Calianno' AND Call_Sign = 'N2GDU';

UPDATE [dbo].[Membership Roster]
SET Club_Officer = 'Membership Chairman'
WHERE First_Name = 'David' AND Last_Name = 'Ladd';

UPDATE [dbo].[Membership Roster]
SET Club_Officer = 'Club Property Chairman'
WHERE First_Name = 'Timothy' AND Last_Name = 'Poliniak';

/*
    Upscript portion for tables creation
*/
-- Create Licenses Table
CREATE TABLE Licenses (
    license_id INT IDENTITY(1,1) PRIMARY KEY,
    license_type_name VARCHAR(20) NOT NULL UNIQUE
);
INSERT INTO Licenses (license_type_name)
SELECT DISTINCT [License_Class] FROM [HAM_Radio_LARC].[dbo].[Membership Roster];
GO

-- Create Membership_Types Table
CREATE TABLE Membership_Types (
    membership_type_id INT IDENTITY(1,1) PRIMARY KEY,
    membership_type_name VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO Membership_Types (membership_type_name)
SELECT DISTINCT [LARC_Membership_Type] FROM [HAM_Radio_LARC].[dbo].[Membership Roster];
GO

-- Create Membership_Dates Table
CREATE TABLE Membership_Dates (
    begin_date DATE NOT NULL,
    date_id INT IDENTITY(1,1) PRIMARY KEY,
    prior_date DATE, 
    expiration_date DATE
);
INSERT INTO Membership_Dates (begin_date, prior_date, expiration_date)
SELECT DISTINCT GETDATE() AS begin_date, [Prior_Membership_Expiration] as prior_date, [Next_Membership_Expiration] as expiration_date FROM [HAM_Radio_LARC].[dbo].[Membership Roster];
GO

-- Create Contact_Infos Table
CREATE TABLE Contact_Infos (
    contact_info_id INT IDENTITY(1,1) PRIMARY KEY,
    address VARCHAR(255),
    city VARCHAR(100),
    state CHAR(2),
    zipcode VARCHAR(10),
    email VARCHAR(100),
    phone VARCHAR(15)
);
INSERT INTO Contact_Infos (address, city, state, zipcode, email, phone)
SELECT DISTINCT [Address], [City], [State], [Zipcode], [Email_Address], [Phone]
FROM [HAM_Radio_LARC].[dbo].[Membership Roster];
GO

-- Create Members Table
CREATE TABLE Members (
    member_id INT IDENTITY(1,1) PRIMARY KEY,
    last_name VARCHAR(50),
    first_name VARCHAR(50),
    middle_initial VARCHAR(20),
    call_sign VARCHAR(15),
    license_id INT,
    membership_type_id INT,
    contact_info_id INT,
    membership_date_id INT,
    FOREIGN KEY (license_id) REFERENCES Licenses(license_id),
    FOREIGN KEY (membership_type_id) REFERENCES Membership_Types(membership_type_id),
    FOREIGN KEY (contact_info_id) REFERENCES Contact_Infos(contact_info_id),
    FOREIGN KEY (membership_date_id) REFERENCES Membership_Dates(date_id)
);
INSERT INTO Members (last_name, first_name, middle_initial, call_sign, license_id, membership_type_id, contact_info_id, membership_date_id)
SELECT 
    [Last_Name], 
    [First_Name], 
    [Middle_Initial], 
    [Call_Sign],
    (SELECT TOP 1 license_id FROM Licenses WHERE license_type_name = mr.[License_Class]),
    (SELECT TOP 1 membership_type_id FROM Membership_Types WHERE membership_type_name = mr.[LARC_Membership_Type]),
    (SELECT TOP 1 contact_info_id FROM Contact_Infos WHERE Address = mr.[Address] AND City = mr.[City] AND State = mr.[State] AND Zipcode = mr.[Zipcode]),
    (SELECT TOP 1 date_id FROM Membership_Dates WHERE expiration_date = mr.[Next_Membership_Expiration])
FROM [HAM_Radio_LARC].[dbo].[Membership Roster] mr;
GO

-- Add volunteer status
ALTER TABLE Members 
ADD member_vol_status VARCHAR(3) CHECK (member_vol_status IN ('Yes', 'No')) NOT NULL DEFAULT 'No';
GO

-- Add membership badge
ALTER TABLE Members 
ADD member_badge VARCHAR(10) NULL;
GO

-- Update membership badges based on tenure
UPDATE Members 
SET member_badge =
    CASE 
        WHEN DATEDIFF(YEAR, Membership_Dates.begin_date, GETDATE()) >= 10 THEN 'Gold'
        WHEN DATEDIFF(YEAR, Membership_Dates.begin_date, GETDATE()) >= 5 THEN 'Silver'
        WHEN DATEDIFF(YEAR, Membership_Dates.begin_date, GETDATE()) >= 1 THEN 'Bronze'
        ELSE 'New'
    END
FROM Members
JOIN Membership_Dates ON Members.membership_date_id = Membership_Dates.date_id;

-- Create Keys Table
CREATE TABLE Keys (
    key_id INT PRIMARY KEY IDENTITY(1,1),
    key_number VARCHAR(10) NOT NULL UNIQUE,
    key_issue_date DATE NOT NULL,
    key_access_type VARCHAR(20) CHECK (key_access_type IN ('Front Door', 'Repeater Room', 'None')) NULL
);
GO

-- Insert data into Keys Table (Sample Data)
INSERT INTO Keys (key_number, key_issue_date, key_access_type)
VALUES 
    ('K1001', GETDATE(), 'Front Door'),
    ('K1002', GETDATE(), 'Repeater Room'),
    ('K1003', GETDATE(), 'None');
GO

-- Create Key_Holders Table
CREATE TABLE Key_Holders (
    member_id INT NOT NULL,
    key_id INT NOT NULL,
    PRIMARY KEY (member_id, key_id),
    FOREIGN KEY (member_id) REFERENCES Members(member_id) ON DELETE CASCADE,
    FOREIGN KEY (key_id) REFERENCES Keys(key_id) ON DELETE CASCADE
);
GO

-- Insert data into Key_Holders Table (Sample Data)
INSERT INTO Key_Holders (member_id, key_id)
SELECT TOP 3 m.member_id, k.key_id
FROM Members m
CROSS JOIN Keys k
WHERE k.key_access_type <> 'None';
GO

-- Create Club_Officers Table
CREATE TABLE Club_Officers (
    club_officer_id INT PRIMARY KEY IDENTITY(1,1),
    member_id INT NOT NULL,
    officer_role VARCHAR(25) CHECK (officer_role IN ('President', 'Vice President', 'Treasurer', 'Secretary',
        'Director', 'Hamfest Chairman', 'Membership Chairman', 'Donations Chairman', 'Club Property Chairman')) NULL,
    FOREIGN KEY (member_id) REFERENCES Members(member_id) ON DELETE CASCADE
);
GO

-- Insert data into Club_Officers Table
INSERT INTO Club_Officers (member_id, officer_role)
SELECT 
    m.member_id, 
    mr.Club_Officer
FROM [HAM_Radio_LARC].[dbo].[Membership Roster] mr 
JOIN Members m 
    ON m.first_name = mr.First_Name
    AND m.last_name = mr.Last_Name
WHERE mr.Club_Officer IS NOT NULL;
GO 


-- Create Membership_Dues Table
CREATE TABLE Membership_Dues (
    payment_id INT PRIMARY KEY IDENTITY(1,1),
    member_id INT NOT NULL,
    payment_date DATE NOT NULL DEFAULT GETDATE(),
    amount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (member_id) REFERENCES Members(member_id) ON DELETE CASCADE
);
GO

-- Insert Membership Dues Data (Sample Data)
INSERT INTO Membership_Dues (member_id, payment_date, amount)
SELECT 
    m.member_id, 
    GETDATE(), 
    50.00  -- Assume a default membership fee of $50
FROM Members m;
GO

-- Create Trigger for Membership Expiration Update
CREATE TRIGGER trg_UpdateMembershipExpiration
ON Membership_Dues
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Update expiration date to the last day of the current calendar year (12/31/YYYY)
    UPDATE Membership_Dates
    SET expiration_date = DATEFROMPARTS(YEAR(GETDATE()), 12, 31)
    FROM Membership_Dates md
    INNER JOIN Members m ON md.date_id = m.membership_date_id
    INNER JOIN inserted i ON m.member_id = i.member_id;
END;
GO

CREATE NONCLUSTERED INDEX IX_Members_MembershipStatus
ON Members (membership_type_id);
GO

--Verify Members table with data
SELECT * FROM Members
GO

--Nonclustered Index for license_type_name (Licenses Table)
CREATE NONCLUSTERED INDEX IX_Licenses_LicenseType
ON Licenses (license_type_name);
GO

--example query 
SELECT m.* 
FROM Members m
JOIN Licenses l ON m.license_id = l.license_id
WHERE l.license_type_name = 'General';
GO

--query for existing call signs 
SELECT 
    member_id, 
    last_name, 
    first_name, 
    middle_initial, 
    call_sign, 
    license_id, 
    membership_type_id, 
    contact_info_id, 
    membership_date_id
FROM Members
WHERE call_sign IS NOT NULL 
    AND call_sign <> '' 
    AND call_sign <> 'pending' 
    AND call_sign NOT LIKE '%no call%'
    AND call_sign NOT LIKE '%no-call%';
GO

--query for members without call sign
SELECT 
    member_id, 
    last_name, 
    first_name, 
    middle_initial, 
    call_sign, 
    license_id, 
    membership_type_id, 
    contact_info_id, 
    membership_date_id
FROM Members
WHERE call_sign LIKE '%no call%' 
    OR call_sign LIKE '%no-call%';
GO

--query for members pending call sign 
SELECT 
    member_id, 
    last_name, 
    first_name, 
    middle_initial, 
    call_sign, 
    license_id, 
    membership_type_id, 
    contact_info_id, 
    membership_date_id
FROM Members
WHERE call_sign LIKE 'pending';
GO

--view for club officers
CREATE VIEW Club_Officer_View AS
SELECT 
    m.member_id, 
    m.last_name, 
    m.first_name, 
    m.middle_initial, 
    m.call_sign, 
    m.license_id, 
    m.membership_type_id, 
    m.contact_info_id, 
    m.membership_date_id, 
    co.officer_role
FROM Members m
JOIN Club_Officers co ON m.member_id = co.member_id;
GO

--query for Keys issued from Membership Roster
SELECT  
    Last_Name, 
    First_Name, 
    Middle_Initial, 
    Call_Sign, 
    License_Class,
    Key_Number,
    Key_Issue_Date
FROM [dbo].[Membership Roster]
WHERE Key_Number IS NOT NULL;
GO

--Check if the view exists
SELECT * FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'Club_Officer_View';

--Viewing the data
SELECT * FROM Club_Officer_View;

--Nonclustered Index for key_id and member_id (Key_Holders Table)
CREATE NONCLUSTERED INDEX IX_KeyHolders_KeyID
ON Key_Holders (key_id);
GO

-- Verify data population
SELECT * FROM Members;
SELECT * FROM Membership_Types;
SELECT * FROM Membership_Dates;
SELECT * FROM Contact_Infos;
SELECT * FROM Licenses;
SELECT * FROM Club_Officers;
SELECT * FROM Membership_Dues;
SELECT * FROM Keys;
SELECT * FROM Key_Holders;
GO

-- DOWN: Drop Database and Tables

USE HAM_Radio_LARC;
GO

-- Drop Views First
DROP VIEW IF EXISTS Club_Officer_View;
GO

-- Drop Foreign Key Dependent Tables First
DROP TABLE IF EXISTS Club_Officers;
GO 
DROP TABLE IF EXISTS Membership_Dues;
GO
DROP TRIGGER IF EXISTS trg_UpdateMembershipExpiration;
GO 
DROP TABLE IF EXISTS Key_Holders
Go 
DROP TABLE IF EXISTS Keys
GO 
DROP TABLE IF EXISTS Members;
GO 

-- Drop Parent Tables
DROP TABLE IF EXISTS Licenses;
GO 
DROP TABLE IF EXISTS Membership_Types;
GO 
DROP TABLE IF EXISTS Membership_Dates;
GO 
DROP TABLE IF EXISTS Contact_Infos;
GO 
DROP TABLE IF EXISTS [dbo].[Membership Roster];
GO

-- Set Database to Single-User Mode to Avoid Errors 
ALTER DATABASE HAM_Radio_LARC SET MULTI_USER;
GO 

-- Drop Database
DROP DATABASE HAM_Radio_LARC;
GO 

SELECT * FROM [dbo].[Membership Roster];
