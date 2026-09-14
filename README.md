# Nexora Supply Chain Analytics

Nexora Supply Chain Analytics is an end-to-end **data analytics and business intelligence project** focused on analyzing products, demand, inventory, warehouses, suppliers, sales, and order fulfillment.

The project uses **Python, Pandas, SQL/MySQL, and Power BI** to convert raw transactional data into actionable supply-chain insights.

---

## 🛠️ Tools & Technologies

- **Python & Pandas** – Data cleaning and preprocessing
- **SQL / MySQL** – Data validation, analysis and business logic
- **Power BI & DAX** – Interactive dashboards and KPIs
- **GitHub** – Project management and version control

---

## 🔄 End-to-End Workflow

**Raw Dataset → Python/Pandas → Clean Dataset → SQL Analysis → ABC/XYZ Analysis → ABC-XYZ Matrix → Power BI → Business Insights**

### 🐍 Python & Pandas
Raw datasets were cleaned, transformed and prepared using Pandas before being loaded into SQL.

### 🗄️ SQL / MySQL
The cleaned data was structured into relational tables and analyzed using:

**Joins, CTEs, Subqueries, CASE statements, Aggregate Functions, Window Functions, Views, Triggers, Stored Procedures, Primary & Foreign Keys.**

### 📊 ABC Analysis
Classifies products based on **revenue contribution** into A, B and C categories.

### 📈 XYZ Analysis
Classifies products based on **demand variability** using the coefficient of variation into X, Y and Z categories.

### 🔀 ABC-XYZ Matrix
Combines **revenue importance and demand variability** to create segments such as AX, AY, AZ, BX, BY, BZ, CX, CY and CZ for better inventory prioritization and replenishment decisions.

### ⚙️ SQL Automation
A **trigger** generates reorder alerts when stock falls below the reorder level, while a **stored procedure** provides warehouse-wise inventory summaries.

---

## 📊 Power BI Dashboard

The analysis is presented through four interactive dashboard pages:

- **Inventory Overview** – Revenue, orders, products, suppliers and warehouse performance
- **Product & Demand Analytics** – ABC, XYZ, ABC-XYZ, product and brand analysis
- **Inventory & Warehouse Management** – Stock levels, low stock, damaged stock and warehouse utilization
- **Suppliers & Fulfillment** – Supplier performance, lead time, ratings and order fulfillment

Interactive slicers allow analysis by **year, category, brand, supplier, city, warehouse, order status, shipping mode, ABC/XYZ categories**, and more.

---

## 📁 Repository Structure

```text
Nexora-Supply-Chain-Analytics/
│
├── Clean Dataset/
├── Raw Dataset/
├── Nexora Supply Chain Project.pbix
├── abc-xyz-Analysis.sql
├── README.md
└── LICENSE

## 🎯 Conclusion

Nexora combines **data cleaning, SQL analytics, inventory classification, and Power BI** to transform raw supply-chain data into meaningful business insights.

The **ABC + XYZ approach** improves inventory decision-making by considering both **revenue contribution and demand variability**, while Power BI makes the insights easy to explore and act upon.

**Python cleans → SQL analyzes → ABC/XYZ prioritizes → Power BI visualizes.**

---

## 👩‍💻 Author

**Shivani Singh**

**Data Analytics | Python | Pandas | SQL | MySQL | Power BI | DAX**
