# Agentforce Analytics Warehouse Project

This project demonstrates using Salesforce Agentforce to proactively manage warehouse inventory based on insights derived from Data Cloud and visualized in Tableau Next. It checks stock levels via an external system (simulated by a Heroku app) and initiates warehouse transfers to prevent regional stockouts.

This repository contains the Salesforce metadata components (Apex, Flows, GenAI artifacts, etc.) required for this functionality.

## Features

* Leverages **Agentforce** for automated insights processing and action initiation.
* Integrates with **Salesforce Data Cloud** as the source of analytical insights.
* Assumes **Tableau Next** is used for visualizing Data Cloud insights that trigger the process.
* Connects to an external **Warehouse Management System (WMS) / ERP** (simulated via Heroku App) for real-time stock checks.
* Automates **warehouse-to-warehouse transfer initiation** using Salesforce Flows and Apex.
* Utilizes **Generative AI Prompt Templates** (`GenAiPromptTemplate`) and **Plugins** (`GenAiPlugin`) for interaction or data processing.
* Provides **Custom Notifications** for transfer initiation status.

## Technology Stack

* **Salesforce Platform**
    * Agentforce
    * Data Cloud
    * Flows (`Flow`)
    * Apex (`ApexClass`)
    * Custom Notifications (`CustomNotificationType`)
    * Generative AI Plugins (`GenAiPlugin`)
    * Generative AI Prompt Templates (`GenAiPromptTemplate`)
* **Tableau Next** (Assumed for insight visualization)
* **External WMS/ERP** (Simulated via [Heroku App](https://github.com/antoineissaly/PLACEHOLDER))

## High-Level Workflow

1.  Insights are generated in **Data Cloud** (potentially visualized via **Tableau Next**).
2.  **Agentforce** picks up relevant insights or events.
3.  Agentforce triggers **Apex** or **Flows** to process the insight.
4.  Apex (`AI_ApiCallUtility`, etc.) calls the external **WMS API** (Heroku app) to check stock levels (`Warehouse_Quantity` plugin might be involved here).
5.  Based on stock levels and insights, the `AI_WarehouseTransferFlow` **Flow** (potentially invoked by Apex or the `Warehouse_Transfer` plugin) initiates the transfer process.
6.  A **Custom Notification** (`Transfer_Initiated_Notif`) is sent upon initiation.
7.  The `AI_TransferJsonParser` **Prompt Template** might be used by Agentforce or Apex to structure data for API calls or logging.

## Salesforce Components Included

This repository contains the source code for the following Salesforce metadata components:

* **Apex Classes:**
    * `AI_ApiCallUtility`
    * `AI_WarehouseQuantity`
    * `AI_WarehouseTransfer`
* **Flow:**
    * `AI_WarehouseTransferFlow`
* **Custom Notification Type:**
    * `Transfer_Initiated_Notif`
* **GenAI Prompt Template:**
    * `AI_TransferJsonParser`
* **GenAI Plugins:**
    * `Warehouse_Quantity`
    * `Warehouse_Transfer`

## Prerequisites

* Salesforce Org with necessary features enabled (Data Cloud, Agentforce, Apex, Flow, GenAI Features).
* Salesforce CLI (`sf` or `sfdx`) installed and authenticated to your target org.
* Git installed.
* Access to deploy and manage the external WMS Heroku application (see External Dependencies).
* Configuration within Salesforce (e.g., Named Credentials) to allow secure API callouts to the deployed Heroku WMS application URL.

## Deployment

1.  **Clone the Repository:**
    ```bash
    git clone <your-github-repo-url>
    cd agentfoceAnalyticsWarehouse
    ```
2.  **Authenticate (if not already done):**
    ```bash
    # Log in to your target Salesforce org
    sf org login web -s -a MyTargetOrgAlias
    ```
    *(Replace `MyTargetOrgAlias` with a suitable alias)*
3.  **Deploy Metadata:**
    ```bash
    # Deploy the components from the force-app directory
    sf project deploy start -d force-app/main/default/ -o MyTargetOrgAlias
    ```
    *(Use the alias you set in the previous step)*
4.  **Assign Permissions:** Create and assign necessary Permission Sets to users who will interact with the features (e.g., grant access to Apex Classes, Flow, Custom Notification Type).
5.  **Post-Deployment Configuration:**
    * Activate the `AI_WarehouseTransferFlow` Flow if it's not active by default.
    * Configure **Named Credentials** or another secure mechanism in Salesforce Setup to store the URL and authentication details for your deployed Heroku WMS application. Update `AI_ApiCallUtility` or relevant classes/flows if necessary to use this configuration.
    * Configure Agentforce, Data Cloud triggers, and any necessary Tableau connections as required by your specific implementation.

## External Dependencies

* **Warehouse Management System (Heroku App):** This project requires a running instance of the simulated WMS application.
    * **Source Code:** [https://github.com/antoineissaly/PLACEHOLDER](https://github.com/antoineissaly/PLACEHOLDER)
    * **Action Required:** You must deploy this Heroku application (or your actual WMS/ERP endpoint) and ensure it's accessible. Update the Salesforce configuration (e.g., Named Credential) with the correct URL of **your deployed instance**. *(The provided link seems to be a placeholder; please update it if you have the correct repository link)*.
