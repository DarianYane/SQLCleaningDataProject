-- Cleaning Data SQL Project

--------------------------------------------------------------------------

-- Calling the database to know that I am working properly
--SELECT *
--FROM SQLCleaningDataProject.dbo.CityHouses

-- Delete the ID column
	-- 1) Verify what I am going to delete
	--SELECT UniqueID
	--FROM SQLCleaningDataProject.dbo.CityHouses

	-- 2) Remove UniqueID column
	ALTER TABLE SQLCleaningDataProject.dbo.CityHouses DROP COLUMN UniqueID;

------------------------------------------------------------------------------

-- Populate PropertyAddress data
	-- 1) Find the lines that have the same ParcelID but different SaleDate. To do this, I join the same table twice, but in the first one I call the NULLs
	--SELECT one.ParcelID, one.PropertyAddress, one.SaleDateFormated, two.ParcelID, two.PropertyAddress, two.SaleDateFormated
	--FROM SQLCleaningDataProject.dbo.CityHouses AS one
	--JOIN SQLCleaningDataProject.dbo.CityHouses AS two
	--	ON one.ParcelID = two.ParcelID
	--	AND one.SaleDateFormated <> two.SaleDateFormated
	--WHERE one.PropertyAddress is NULL

	-- 2) Generate NULL replacement
	--SELECT one.ParcelID, one.PropertyAddress, one.SaleDateFormated, two.ParcelID, two.PropertyAddress, two.SaleDateFormated, ISNULL(one.PropertyAddress, two.PropertyAddress)
	--FROM SQLCleaningDataProject.dbo.CityHouses AS one
	--JOIN SQLCleaningDataProject.dbo.CityHouses AS two
	--	ON one.ParcelID = two.ParcelID
	--	AND one.SaleDateFormated <> two.SaleDateFormated
	--WHERE one.PropertyAddress is NULL

	-- 3) Replace NULL using the above structures
	UPDATE one
	SET PropertyAddress = ISNULL(one.PropertyAddress, two.PropertyAddress)
	FROM SQLCleaningDataProject.dbo.CityHouses AS one
	JOIN SQLCleaningDataProject.dbo.CityHouses AS two
		ON one.ParcelID = two.ParcelID
		AND one.SaleDateFormated <> two.SaleDateFormated
	WHERE one.PropertyAddress is NULL

	-- 4) Verification: If we run step 1) again, we should not have NULL entries.

--------------------------------------------------------------------------

-- Split PropertyAddress data into Address (Street + Number), and City
	-- 1) Create new columns (Address and City)
	ALTER TABLE SQLCleaningDataProject.dbo.CityHouses
	ADD Address varchar(255);

	ALTER TABLE SQLCleaningDataProject.dbo.CityHouses
	ADD City varchar(255);

	-- 2) Split PropertyAddress into Address and City
	--SELECT
	--SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
	--SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress)) AS City
	--FROM SQLCleaningDataProject.dbo.CityHouses

	-- 3) Use the above structures to update the values of Address and City
	UPDATE SQLCleaningDataProject.dbo.CityHouses
	SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1);

	UPDATE SQLCleaningDataProject.dbo.CityHouses
	SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress));

	-- 4) Delete the original PropertyAddress column
	ALTER TABLE SQLCleaningDataProject.dbo.CityHouses DROP COLUMN PropertyAddress;


--------------------------------------------------------------------------

--Fix SaleDate Format
	-- 1) Visualize what is to be changed
	--SELECT SaleDate, CONVERT(Date, SaleDate)
	--FROM SQLCleaningDataProject.dbo.CityHouses

	-- 2) Create a new column
	ALTER TABLE SQLCleaningDataProject.dbo.CityHouses
	ADD SaleDateFormated Date;

	-- 3) Fill in the new column
	UPDATE SQLCleaningDataProject.dbo.CityHouses
	SET SaleDateFormated = CONVERT(Date, SaleDate)

	-- 4) Remove the old column
		-- 1) Verify what I am going to delete
		--SELECT SaleDate
		--FROM SQLCleaningDataProject.dbo.CityHouses

	-- 5) Remove SaleDate column
		ALTER TABLE SQLCleaningDataProject.dbo.CityHouses DROP COLUMN SaleDate;

----------------------------------------------------------------------------------

-- Split the property owner's address data into Address (Street + Number), City and State
	-- 1) Create new columns (OwnerAddress, OwnerCity and OwnerState)
	ALTER TABLE SQLCleaningDataProject.dbo.CityHouses
	ADD OwnerAddressOnly varchar(255);

	ALTER TABLE SQLCleaningDataProject.dbo.CityHouses
	ADD OwnerCityOnly varchar(255);

	ALTER TABLE SQLCleaningDataProject.dbo.CityHouses
	ADD OwnerStateOnly varchar(255);

	-- 2) Split OwnerAddress to Address, City and State
	--SELECT
	--PARSENAME(REPLACE(OwnerAddress,',','.'),3),
	--PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	--PARSENAME(REPLACE(OwnerAddress,',','.'),1)
	--FROM SQLCleaningDataProject.dbo.CityHouses

	-- 3) Use the above structures to update the values of OwnerAddress, OwnerCity and OwnerState
	UPDATE SQLCleaningDataProject.dbo.CityHouses
	SET OwnerAddressOnly = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

	UPDATE SQLCleaningDataProject.dbo.CityHouses
	SET OwnerCityOnly = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

	UPDATE SQLCleaningDataProject.dbo.CityHouses
	SET OwnerStateOnly = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

	-- 4) Delete the original OwnerAddress column
	ALTER TABLE SQLCleaningDataProject.dbo.CityHouses DROP COLUMN OwnerAddress;

--------------------------------------------------------------------------

-- Replace "Y" with "Yes" and "N" with "No" (in SoldAsVacant)
	-- 1) View cases
	--SELECT SoldAsVacant
	--FROM SQLCleaningDataProject.dbo.CityHouses
	--GROUP BY SoldAsVacant;

	-- 2) Make replacements
	UPDATE SQLCleaningDataProject.dbo.CityHouses
	SET SoldAsVacant = 
	CASE
		WHEN SoldAsVacant = 'Y'THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END
	FROM SQLCleaningDataProject.dbo.CityHouses

---------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove duplicates (If they have the same ParcelID, SalePrice, LegalReference and SaleDateFormated I can consider them to be the same operation)
	-- 1) Number the repeated lines (If the data are the same, I number the lines with the same information to keep only the first line of each case)
	--SELECT *, 
	--	ROW_NUMBER() OVER (PARTITION BY ParcelID, SalePrice, LegalReference, SaleDateFormated ORDER BY LegalReference) AS MasterCode
	--FROM SQLCleaningDataProject.dbo.CityHouses
	--ORDER BY MasterCode DESC;
					
	-- Convert the above expression to CTE in order to filter out those greater than 1
	WITH NumbRows AS (
		SELECT *, 
			ROW_NUMBER() OVER (PARTITION BY ParcelID, SalePrice, LegalReference, SaleDateFormated ORDER BY LegalReference) AS MasterCode
		FROM SQLCleaningDataProject.dbo.CityHouses)
	DELETE
	FROM NumbRows
	WHERE MasterCode>1;

----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Finally, call up all data clean and ready for analysis

SELECT *
FROM SQLCleaningDataProject.dbo.CityHouses
