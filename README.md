# Hand-On Training - SQL Migration (Online and Offline)

## Overview 

**This hands-on training enables attendees to** learn how to use

**This hand-on simulates a real-worl scenario**

**During the "hands-on" attendees will focus on:**

**By the end of the hands-on, attendees**

### Technologies

[SQL Server 2012](https://learn.microsoft.com/en-us/previous-versions/sql/sql-server-2012/ms130214(v=sql.110)),
[SQL Server 2016](https://learn.microsoft.com/en-us/sql/sql-server/?view=sql-server-2016), 
[SQL Server 2019](https://learn.microsoft.com/en-us/sql/sql-server/?view=sql-server-ver15), 
[Azure SQL DB](https://learn.microsoft.com/en-us/azure/azure-sql/database/?view=azuresql), 
[Azure SQL Managed Instance](https://learn.microsoft.com/en-us/azure/azure-sql/database/?view=azuresql), 
[Azure Bastion](https://learn.microsoft.com/en-us/azure/bastion/),
[Microsoft Data Migration Assistant (DMA)](https://learn.microsoft.com/en-us/sql/dma/dma-overview?view=sql-server-ver16),
[Azure Data Studio](https://learn.microsoft.com/en-us/sql/azure-data-studio/?view=sql-server-ver15),
[Azure Database Migration Services (DMS)](https://learn.microsoft.com/en-us/azure/dms/dms-overview),
[Azure Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/),
[Git](https://git-scm.com/docs),
[Azure Cloud Shell](https://learn.microsoft.com/en-us/azure/cloud-shell/overview),
[Azure Storage](https://learn.microsoft.com/en-us/azure/storage/), 
[SQL Server Management Studio (SSMS)](https://learn.microsoft.com/en-us/sql/ssms/sql-server-management-studio-ssms?view=sql-server-ver16) 

### Prerequisites: 
1. Deploy training resources in Azure Subscription.
    - Open Cloud Shell
    - Git clone Bicep files: `git clone https://github.com/cbattlegear/SqlServerMigrationTraining.git`
    - Go into directory: `cd SQLMigrationTraining/`
    - Execute main.bicep: `az deployment sub create --location eastus2 --template-file main.bicep`
    - Walk through on-screen instructions. ***Note:*** For resource names, use all lowercase and avoid underscored and dashes. For password, 16 chars, upper, lower, number.

      ***Deployment will take ~3 hours due to Azure SQL MI provisioning.***
 2. Verify environment deployment.
    - Bastion into VM in the deployed resource group.
      - Verify the following is installed: 
          - SQL Server 2012 - AdventureWorks2012
          - SQL Server 2016 - AdventureWorks2016
          - SQL Server 2019 - AdventureWorks2019
          - SQL Server Management Studio
          - Azure Data Studio 
          - Data Migration Assistant - ***Note:*** Download and install. 
      
