/*

Dataset Cleaning Project Using SQL Queries


Functions used in the project:
(
	UPDATE SET, 
	ALTER TABLE,
	LEFT, RIGHT, CHARINDEX, CONCAT
	ISNULL, [UPDATE SET FROM], JOIN, LEFT JOIN
	PIVOT, WITH AS (CTE), MAX, CROSS APPLY
	ROW_NUMBER, OVER, PARTITION BY, MAX
	SUBSTRING, LEN, PARSENAME,
	DELETE,  ALTER TABLE DROP COLUMN

)
*/




-- First, let's have a look of the dataset.


SELECT *
FROM PortfolioProject.dbo.NashvilleHousing



--------------------------------------------------------------------------------------------------------------------------


-- Standardize Date Format


SELECT
	SaleDate,
	CONVERT(date, SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing


UPDATE PortfolioProject.dbo.NashvilleHousing
SET SaleDate = CONVERT(date, SaleDate)
-- Sometimes this method doesn't work


ALTER Table PortfolioProject.dbo.NashvilleHousing
Add SaleDate_v1 Date;
-- Add a new column called SaleDate_v1


UPDATE PortfolioProject.dbo.NashvilleHousing
SET SaleDate_v1 = CONVERT(date, SaleDate)
-- Update SaleDate_v1 column values



 --------------------------------------------------------------------------------------------------------------------------


-- Populate Property Address data


-- If the ParcelID the same, the PropertyAddress is the same.
SELECT 
	P1.[ParcelID],
	P1.PropertyAddress,	
	P2.[ParcelID],
	P2.PropertyAddress
From PortfolioProject.dbo.NashvilleHousing P1
LEFT JOIN PortfolioProject.dbo.NashvilleHousing P2 
	ON P1.[ParcelID] = P2.[ParcelID] AND P1.[UniqueID ] <> P2.[UniqueID ]
WHERE P1.PropertyAddress IS NULL 
-- Preview the values that going to fill the PropertyAddress


UPDATE P1
SET PropertyAddress = ISNULL(P1.PropertyAddress, P2.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing P1
LEFT JOIN PortfolioProject.dbo.NashvilleHousing P2 
	ON P1.[ParcelID] = P2.[ParcelID] AND P1.[UniqueID ] <> P2.[UniqueID ]
WHERE P1.PropertyAddress IS NULL 


--SELECT PropertyAddress, OwnerAddress, LEFT(OwnerAddress,CHARINDEX(', TN', OwnerAddress)-1)
--FROM PortfolioProject.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL 


--SELECT PropertyAddress, OwnerAddress, NULLIF(CONCAT(PropertyAddress, ', TN'), ', TN')
--FROM PortfolioProject.dbo.NashvilleHousing
--WHERE OwnerAddress IS NULL



--------------------------------------------------------------------------------------------------------------------------


-- Breaking out Address into Individual Columns (Address, City, State)


-- PARSENAME ONLY WORKS ON '.' INSTEAD OF ','
SELECT 
	[UniqueID ],
	[OwnerAddress],
	PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing


SELECT
	[OwnerAddress],
	PARSENAME(REPLACE([OwnerAddress], ',', '.'), 3),
	PARSENAME(REPLACE([OwnerAddress], ',', '.'), 2),
	PARSENAME(REPLACE([OwnerAddress], ',', '.'), 1)
FROM PortfolioProject.dbo.NashvilleHousing


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD [OwnerSplitAddress] nvarchar(255);

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE([OwnerAddress], ',', '.'), 3)


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD [OwnerSplitCity] nvarchar(255);

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE([OwnerAddress], ',', '.'), 2)


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD [OwnerSplitState] nvarchar(255);

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE([OwnerAddress], ',', '.'), 1)


--Check the table
SELECT * FROM PortfolioProject.dbo.NashvilleHousing





--Using Substring to separate string value.


SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS ADDRESS,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM PortfolioProject.dbo.NashvilleHousing


-- Alternative method using Pivot and CROSS APPLY functions


WITH ADDRESS_COLUMNS AS 
(
	SELECT 
		[UniqueID ],
		[1] AS [ADDRESS],
		[2] AS [CITY],
		[3] AS [STATE]
	FROM
	(	
		SELECT 
			[UniqueID ], 
			VALUE,
			ROW_NUMBER() OVER(PARTITION BY [UniqueID ] ORDER BY [UniqueID ]) AS ROWNUM
		FROM PortfolioProject.dbo.NashvilleHousing
		CROSS APPLY string_split([OwnerAddress], ',')
	) SOURCE_TABLE
	PIVOT
	(
		MAX(VALUE)
		FOR [ROWNUM] IN ([1], [2], [3])
	) PVT
)

SELECT 
	P1.[UniqueID ],
	P1.OwnerAddress,
	AC.ADDRESS,
	AC.CITY,
	AC.STATE
FROM PortfolioProject.dbo.NashvilleHousing P1
LEFT JOIN ADDRESS_COLUMNS AC ON P1.[UniqueID ] = AC.[UniqueID ]




--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT
	DISTINCT [SoldAsVacant]
FROM PortfolioProject.dbo.NashvilleHousing

SELECT
	[SoldAsVacant],
	CASE [SoldAsVacant]
		WHEN 'N' THEN 'No'
		WHEN 'Y' THEN 'Yes'
		ELSE [SoldAsVacant]
	END
FROM PortfolioProject.dbo.NashvilleHousing
order by LEN([SoldAsVacant])


UPDATE PortfolioProject.dbo.NashvilleHousing
SET [SoldAsVacant] 
	= CASE [SoldAsVacant]
		WHEN 'N' THEN 'No'
		WHEN 'Y' THEN 'Yes'
		ELSE [SoldAsVacant]
	  END


SELECT [SoldAsVacant], COUNT([SoldAsVacant])
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY [SoldAsVacant]



-----------------------------------------------------------------------------------------------------------------------------------------------------------


-- Remove Duplicates


WITH TEM AS 
(
	SELECT 
		*,
		ROW_NUMBER() OVER(PARTITION BY [ParcelID],[SaleDate],[SalePrice],
			[OwnerName],[LegalReference] ORDER BY [SaleDate]) AS ROWNUM
	FROM PortfolioProject.dbo.NashvilleHousing
)


DELETE
FROM TEM
WHERE ROWNUM>1  -- DELETE duplicated values that filltered by rownum



---------------------------------------------------------------------------------------------------------


-- Delete Unused Columns


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN [OwnerAddress], [TaxDistrict], [PropertyAddress], [SaleDate]


SELECT * FROM PortfolioProject.dbo.NashvilleHousing




