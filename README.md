# Hand-On Training: SQL Migration to Azure SQL DB and Azure SQL Managed Instance (Online and Offline)

## Overview 

**This hands-on training enables attendees to** learn how to use Microsoft tooling for online and offline SQL Server Migrations to PaaS Azure SQL (SQL DB and SQL Managed Instance).

**This hand-on training simulates a real-world scenario** where Database Administrators need to migrate SQL Servers (on-premises or Azure SQL VMs) to PaaS Azure SQL (SQL DB and SQL Managed Instance), while taking advantage of Microsoft migration tools and services. 

**During the "hands-on" attendees will focus on:**
1. Performing SQL Server migration assessments on existing SQL Server (2012, 2016, and 2019) prior to migration. 
2. Addressing any SQL Server assessment compatibility or feature parity issues prior to migration. 
3. Migrating SQL Server to PaaS Azure SQL (SQL DB and SQL MI) in offline and online mode with Microsoft migration tools (URL backup/restore, Azure Data Migration Assistant (DMA), Azure Data Migration Service (DMS), Azure Data Studio). 

**By the end of the hands-on, attendees** will have learned the fundamentals of migrating SQL Server to PaaS Azure SQL in offline and online mode with their respective Microsoft migration tool. 

## Technologies

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

## Prerequisites
1. Deploy training resources in Azure Subscription:
    - Open Cloud Shell
    - Git clone Bicep files: `git clone https://github.com/cbattlegear/SqlServerMigrationTraining.git`
    - Go into directory: `cd SQLMigrationTraining/`
    - Execute main.bicep: `az deployment sub create --location eastus2 --template-file main.bicep`
    - Walk through on-screen instructions. ***Note:*** For resource names, use all lowercase and avoid underscored and dashes. For password, 16 chars, upper, lower, number.

      ***Deployment will take ~3 hours due to Azure SQL MI provisioning.***
 2. Verify environment deployment.
    
    - Deployed resource group should contain the following: 
        - Azure Bastion 
        - Azure Disk (attached to VM)
        - Azure Network Interface
        - Azure Network Security Group (3 of them)
        - Azure Public IP Address (For Bastion)
        - Azure Route Table (For SQL MI)
        - Azure Storage Account
        - Azure SQL Database (attached to Azure SQL Server)
        - Azure SQL Managed Instance
        - Azure SQL Server (Has 1 DB attached)
        - Azure SQL Virtual Machine (same as Azure VM name)
        - Azure Virtual Cluster (For SQL MI)
        - Azure Virtual Machine (same as Azure SQL VM)
        - Azure VNET
 
    - Bastion into VM in the deployed resource group.
      - Verify the following is installed: 
          - SQL Server 2012 - AdventureWorks2012
          - SQL Server 2016 - AdventureWorks2016
          - SQL Server 2019 - AdventureWorks2019
          - SQL Server Management Studio
          - Azure Data Studio 
          - Data Migration Assistant - ***Note:*** Download and install. 
          
 3. Supporting documents: 
    - [TSQL - SQL backup and restore to Azure Blob Storage](https://learn.microsoft.com/en-us/sql/relational-databases/tutorial-sql-server-backup-and-restore-to-azure-blob-storage-service?view=sql-server-ver16&tabs=SSMS)
    - [TSQL - Create SQL Server credentials for authentication to Azure Blob Storage](https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/sql-server-backup-to-url?view=sql-server-ver16#credential)
    - [Migrate SQL Server to Azure SQL MI online using Azure Data Studio with DMS](https://learn.microsoft.com/en-us/azure/dms/tutorial-sql-server-managed-instance-online-ads)
    - [Migrate SQL Server to Azure SQL DB using Data Migration Assistant (DMA)](https://learn.microsoft.com/en-us/sql/dma/dma-migrateonpremsqltosqldb?view=sql-server-ver16)
   

## Training 
      
**Objectives**:
1. SQL Server 2016 => Offline migration - Backup to URL (TSQL) and restore with URL to Azure SQL MI (TSQL).
2. SQL Server 2019 => Online migration - Azure Data Studio migration to Azure SQL MI.
3. SQL Server 2012 => Offline migration - Microsoft Data Migration Assistant (DMA) migration to Azure SQL DB.


PENDING STEPS ... Will be provided day of training 
