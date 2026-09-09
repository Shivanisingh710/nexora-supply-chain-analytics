create database Capstone;
use capstone;

# Total Number of Rows present in the tables
								  # Origanally     # After Handling Inconsistency
select count(*) from inventory;   # 45585 Rows       40820 Rows
select count(*) from order_items; # 52835 Rows       47537 Rows
select count(*) from orders;      # 52908 Rows       51375 Rows
select count(*) from product;     # 12265 Rows       11508 Rows
select count(*) from supplier;    # 10380 Rows       9996  Rows
select count(*) from warehouse;   # 10098 Rows       9952  Rows

# Establishing relationship between the tables

alter table inventory add primary key (inventory_id);
alter table order_items add primary key (order_item_id);
alter table orders add primary key (order_id);
alter table product add primary key (product_id);
alter table supplier add primary key (supplier_id);
alter table warehouse add primary key (warehouse_id);

select warehouse_id
from inventory
where warehouse_id not in
(select warehouse_id from warehouse); #928

delete i
from inventory i
left join warehouse w
on i.warehouse_id = w.warehouse_id
where w.warehouse_id is null;

alter table inventory add foreign key (warehouse_id)
references warehouse(warehouse_id);

select product_id 
from inventory 
where product_id not in 
(select product_id from product); #1000

delete i
from inventory i
left join product p
on i.product_id = p.product_id
where p.product_id is null;

alter table inventory add foreign key (product_id)
references product(product_id);

select product_id 
from order_items 
where product_id not in 
(select product_id from product); #1000

delete o
from order_items o
left join product p
on o.product_id = p.product_id
where p.product_id is null;

alter table order_items add foreign key (product_id)
references product(product_id);

select order_id 
from order_items 
where order_id not in 
(select order_id from orders); #778

delete oi
from order_items oi
left join orders o
on o.order_id = oi.order_id
where o.order_id is null;

alter table order_items add foreign key (order_id)
references orders(order_id);

select warehouse_id
from orders
where warehouse_id not in
(select warehouse_id from warehouse); #1000

# First needed to delete the dependent order items.
delete oi
from order_items oi
join orders o
on oi.order_id = o.order_id
left join warehouse w
on o.warehouse_id = w.warehouse_id
where w.warehouse_id is null;

# Then delete the incinsistent warehouse id
delete o
from orders o
left join warehouse w
on o.warehouse_id = w.warehouse_id
where w.warehouse_id is null;

alter table orders add foreign key (warehouse_id)
references warehouse(warehouse_id);
desc orders;

select supplier_id
from product 
where supplier_id not in
(select supplier_id from supplier); #513

delete oi
from order_items oi
join product p
on oi.product_id = p.product_id
left join supplier s
on p.supplier_id = s.supplier_id
where s.supplier_id is null;

delete i
from inventory i
join product p
on i.product_id = p.product_id
left join supplier s
on p.supplier_id = s.supplier_id
where s.supplier_id is null;

delete p
from product p
left join supplier s
on p.supplier_id = s.supplier_id
where s.supplier_id is null;

alter table product add foreign key (supplier_id)
references supplier(supplier_id);

select * from inventory;
select * from supplier;
select * from warehouse;
select * from product;
select * from orders;
select * from order_items;


# Columns:
# Inventory.csv - inventory_id, product_id, warehouse_id, stock_quantity, 
#                 reserved_stock, damaged_stock, last_updated

# Supplier.csv - supplier_id, supplier_name, city, country, supplier_type, lead_time, rating

# Warehouse.csv - warehouse_id, warehouse_name, city, state, warehouse_type, capacity

# Product.csv - product_id, product_name, brand, category, supplier_id, unit_cost, 
#               selling_price, reorder_level, weight_kg, launch_date, is_discontinued

# Orders.csv - order_id, customer_id, order_date, warehouse_id, order_status, 
#              shipment_status, payment_method, shipping_mode

# Order_items.csv - order_item_id, order_id, product_id, quantity, 
#                   unit_price, discount, returned_flag

# ABC Analysis Table (using CTE and views) 
create view abc_analysis as
with product_sales as            
(Select p.product_id,            
		p.product_name,
	    round(sum(oi.quantity*
        oi.unit_price*
        (1-oi.discount/100)),2) as total_revenue
from product p
join order_items oi 
		  on p.product_id = oi.product_id
where oi.returned_flag = 0
group by p.product_id,
         p.product_name),
         
total_sales as
(select sum(total_revenue) as company_revenue
 from product_sales),

product_percentage as
(select ps.product_id,
        ps.product_name,
        ps.total_revenue,
        round(((ps.total_revenue / ts.company_revenue) * 100),2)
        as revenue_percentage
from product_sales ps
cross join total_sales ts),

cumulative_sales as
(select product_id,
        product_name,
        total_revenue,
        revenue_percentage,
        round(sum(revenue_percentage) over
        (order by total_revenue desc),2) 
        as cumulative_percentage
from product_percentage)
select product_id,
       product_name,
	   total_revenue,
       revenue_percentage,
	   cumulative_percentage,
case
	when cumulative_percentage <= 80 then 'A'
	when cumulative_percentage <= 95 then 'B'
	else 'C'
    end as abc_category
from cumulative_sales;

select * from abc_analysis;

#XYZ Analysis Table (using CTE and views)
create view xyz_analysis as
with monthly_demand as
(Select oi.product_id,
         year(o.order_date) order_year,
         month(o.order_date) order_month,
         sum(oi.quantity) Monthly_quantity
from order_items oi
join orders o
		on oi.order_id=o.order_id
group by oi.product_id,
         order_year,
		 order_month),
         
demand_variablity as
(select product_id,
		Avg(Monthly_quantity) avg_demand,
        stddev_pop(Monthly_quantity) demand_stddev
from monthly_demand
group by product_id),

cv_calculation as
(select product_id,
		avg_demand,
        demand_stddev,
        demand_stddev/nullif(avg_demand,0)
        coefficient_of_variance
from demand_variablity)
select
    product_id,
    avg_demand,
    demand_stddev,
    coefficient_of_variance,
    case
        when coefficient_of_variance <= 0.25
            then 'X'
        when coefficient_of_variance <= 0.50
            then 'Y'
        else 'Z'
    end as xyz_category
from cv_calculation;

select * from xyz_analysis;

create view abc_xyz_matrix as
select
    a.product_id,
    a.product_name,
    a.abc_category,
    x.xyz_category,
    a.total_revenue,
    a.revenue_percentage,
    x.avg_demand,
    x.demand_stddev,
    x.coefficient_of_variance,
    concat(a.abc_category, x.xyz_category) as abc_xyz_category
from abc_analysis a
join xyz_analysis x
    on a.product_id = x.product_id;
    
select * from abc_xyz_matrix;

   
# SQL-Based ABC-XYZ Inventory Optimization Decision Support System

# 1.ich products contribute the most to company revenue and should be classified as
# Category A for inventory prioritization?

select distinct 
       product_name
from abc_analysis
where abc_category='A';

-- Explanation:
-- Used ABC analysis view to identify high-value products that contribute the most 
-- to the company's total revenue. where Category A products together contribute 
-- approximately 80% of the total revenue, whereas Category B contributes the next 
-- 15% and Category C contributes the remaining 5%.

-- Why it matters:
-- The company wants to know which products deserve the highest inventory investment.

# 2.Does the company's product portfolio follow the Pareto 80/20 Principle, allowing the 
# company to focus inventory investment on high-value products and reduce inventory costs?

select count(distinct product_id)  prod_A,
	   count(distinct product_id) * 100 /
       (select count(distinct product_id) 
       from abc_analysis) prod_A_per
from abc_analysis
where abc_category = 'A';

-- Answer:
-- The analysis shows that 54.67% of the products contribute approximately 80% of 
-- total revenue. This does not strongly follow the Pareto 80/20 Principle, where around 
-- 20% of products would be expected to generate 80% of revenue. Therefore, the company 
-- should not focus inventory investment only on a small group of high-value products. 
-- Instead, inventory should be managed across a broader range of products, with higher 
-- priority given to Category A products while maintaining adequate stock levels 
-- for B and C products.

# 3.Which Category A products require inventory action across warehouses based on their 
# revenue contribution, current stock, reorder level, supplier lead time, and 
# inventory value?

select p.product_name,
       a.total_revenue,
       a.revenue_percentage,
       s.supplier_name,
       i.stock_quantity,
       w.warehouse_name,
       w.city,
       p.reorder_level,
       s.lead_time,
       (i.stock_quantity * p.unit_cost) as inventory_value,
       case 
            when i.stock_quantity < p.reorder_level
			 and s.lead_time >= 15 then 'Urgent Rplenishment'
		    when i.stock_quantity < p.reorder_level
            then 'Reorder'
            when i.stock_quantity > p.reorder_level * 3
            then 'Review Overstock'
            else 'Maintain Inventory'
	 end as inventory_action
from abc_analysis a 
join product p
    on a.product_id = p.product_id
join inventory i
    on a.product_id = i.product_id
join supplier s
    on p.supplier_id = s.supplier_id
join warehouse w
    on i.warehouse_id = w.warehouse_id
where a.abc_category = 'A'
order by a.total_revenue desc; 
  
-- Insight
-- Category A products are the high-revenue products, so the company should give 
-- them more attention. Some A products have stock below the reorder level, especially 
-- where the supplier lead time is high, so they need to be reordered quickly. At the 
-- same time, some warehouses have excess stock of A products, which means the company 
-- can review and reduce unnecessary inventory investment.

# 4.Which products have the most predictable demand, and how should the company manage 
# their inventory based on demand variability, current stock, reorder levels, and 
# warehouse availability?

select 
	p.product_name,
	x.xyz_category,
    round(x.avg_demand,2) avg_monthly_demand,
    round(x.demand_stddev,2) demand_stddev,
    round(x.coefficient_of_variance,2) cv,
    i.stock_quantity,
    p.reorder_level,
    w.warehouse_name,
    w.capacity,
    w.city,
	case
	    when i.stock_quantity < p.reorder_level
        and x.xyz_category = 'X'
        then 'Reorder - Stable Demand'
        
        when i.stock_quantity < p.reorder_level
        and x.xyz_category = 'Y'
        then 'Reorder - Monitor Demand'
        
        when i.stock_quantity < p.reorder_level
        and x.xyz_category = 'Z'
        then 'Reorder Carefully - Unpredictable Demand'
        
        when i.stock_quantity > p.reorder_level * 3
        then 'Review Quantity'
        
        else 'Maintain Inventory'
	end as inventory_action
from xyz_analysis x
join product p
    on x.product_id = p.product_id
join inventory i
    on x.product_id = i.product_id
join warehouse w
    on i.warehouse_id = w.warehouse_id
order by x.coefficient_of_variance;
	
-- Stable-demand products can be confidently reordered when stock falls below the 
-- reorder level, while unpredictable-demand products need careful replenishment. 
-- Products with excess stock should be reviewed to reduce unnecessary inventory 
-- and costs.
    
# 5.Which products generate high revenue but have disproportionately high inventory value,
# indicating potential capital inefficiency?

select
    p.product_id,
    p.product_name,
    a.total_revenue,
    round(sum(i.stock_quantity * p.unit_cost),2) inventory_value,
    round(sum(i.stock_quantity * p.unit_cost) / a.total_revenue,2) 
    inventory_to_revenue_ratio
from abc_analysis a
join product p
    on a.product_id = p.product_id
join inventory i
    on p.product_id = i.product_id
group by
    p.product_id,
    p.product_name,
    a.total_revenue
order by inventory_to_revenue_ratio desc;

-- Insight
-- The analysis shows that some products have a very high inventory value compared to 
-- the revenue they generate. This means too much money is getting stuck in inventory, 
-- so the company should review these products and reduce excess stock where possible 
-- to improve inventory efficiency.


# 6.Which products generate significant revenue despite maintaining relatively low inventory levels,
# and what does this suggest about their inventory efficiency?

select
	p.product_id,
    p.product_name,
    a.total_revenue,
    round(sum(i.stock_quantity * p.unit_cost),2) inventory_value,
    round(sum(i.stock_quantity * p.unit_cost) / a.total_revenue,2) 
    inventory_to_revenue_ratio
from abc_analysis a
join product p
    on a.product_id = p.product_id
join inventory i
    on p.product_id = i.product_id
group by
    p.product_id,
    p.product_name,
    a.total_revenue
having a.total_revenue >= 
(select min(total_revenue)
		from(select total_revenue,
                    ntile(4) over (order by total_revenue) q
			from abc_analysis) r
           where q = 4)
and inventory_to_revenue_ratio <=
(select max(ratio)
        from(select a2.product_id,
                sum((i2.stock_quantity * p2.unit_cost) /a2.total_revenue) ratio,
                ntile(4) over(order by sum(i2.stock_quantity * p2.unit_cost) /
                a2.total_revenue) q
            from abc_analysis a2
            join product p2
                on a2.product_id = p2.product_id
            join inventory i2
                on a2.product_id = i2.product_id
            group by
                a2.product_id,
                a2.total_revenue) x
        where q = 1)
order by inventory_to_revenue_ratio;

# 7.Which products have high inventory value but contribute relatively little revenue,
# indicating potential overstock and tied-up capital?

select
    m.product_name,
    m.abc_xyz_category,
    m.total_revenue,
    round(sum(i.stock_quantity * p.unit_cost),2) inventory_value
from abc_xyz_matrix m
join product p
    on m.product_id = p.product_id
join inventory i
    on m.product_id = i.product_id
where m.abc_xyz_category IN ('AY', 'AZ')
group by
    m.product_id,
    m.product_name,
    m.abc_xyz_category,
    m.total_revenue
order by inventory_value desc;

# 8.Which high-value products have low stock levels and long supplier lead times, creating 
# the highest risk of stockouts?

select 
	p.product_name,
    m.abc_xyz_category,
    i.stock_quantity,
    m.total_revenue,
    s.lead_time,
    p.reorder_level,
    case
		when i.stock_quantity < p.reorder_level and s.lead_time >= 15
		then 'Critical Stockout Risk'
        when i.stock_quantity < p.reorder_level
		 then 'High Stockout Risk'
        else 'Low Stockout Risk'
	end as stockout_risk
from abc_xyz_matrix m
join product p 
	on p.product_id = m.product_id
join supplier s 
	on s.supplier_id = p.supplier_id
join inventory i 
	on p.product_id = i.product_id
where m.abc_xyz_category = 'AZ'
  and i.stock_quantity < p.reorder_level
  and s.lead_time >= 15
order by m.total_revenue desc;
    
# 9.Which products are overstocked across warehouses despite having low revenue contribution, 
# and how much inventory value could potentially be reduced?

select
    p.product_name,
    m.abc_xyz_category,
    w.warehouse_name,
    w.city,
    m.total_revenue,
    i.stock_quantity,
    p.reorder_level,
	ROUND(i.stock_quantity * p.unit_cost, 2) inventory_value,
	ROUND(i.stock_quantity / p.reorder_level, 2) stock_to_reorder_ratio
from abc_xyz_matrix m
join product p
    on m.product_id = p.product_id
join inventory i
    on p.product_id = i.product_id
join warehouse w
    on i.warehouse_id = w.warehouse_id
where m.abc_category = 'C'
  and i.stock_quantity > p.reorder_level * 3
order by inventory_value desc;

# 10.Which products are overstocked in one warehouse while being below the reorder level 
# in another warehouse, indicating an opportunity to redistribute inventory instead of 
# placing new supplier orders?

select
    p.product_name,
    m.abc_xyz_category,
    w1.warehouse_name as excess_warehouse,
    i1.stock_quantity as excess_stock,
	w2.warehouse_name as shortage_warehouse,
    i2.stock_quantity as shortage_stock,
	p.reorder_level
from inventory i1
join inventory i2
    on i1.product_id = i2.product_id
    and i1.warehouse_id <> i2.warehouse_id
join product p
    on i1.product_id = p.product_id
join abc_xyz_matrix m
    on i1.product_id = m.product_id
join warehouse w1
    on i1.warehouse_id = w1.warehouse_id
join warehouse w2
    on i2.warehouse_id = w2.warehouse_id
where i1.stock_quantity > p.reorder_level * 3
  and i2.stock_quantity < p.reorder_level
order by p.product_name;

-- Business Insight:
-- Some products have excess stock in one warehouse while facing shortages in another. 
-- Redistributing this inventory can help avoid unnecessary purchases and reduce excess
-- inventory costs.

# 11.Which suppliers create the highest inventory risk because they have long lead
# times and supply products that are already low in stock?

select 
    s.supplier_id,
    s.supplier_name,
    p.product_name,
    w.warehouse_name,
    s.lead_time,
    i.stock_quantity,
	p.reorder_level,
    m.abc_xyz_category
from product p
join abc_xyz_matrix m
	on m.product_id = p.product_id
join supplier s 
	on p.supplier_id = s.supplier_id
join inventory i
	on i.product_id = p.product_id
join warehouse w
	on w.warehouse_id = i.warehouse_id
where m.abc_xyz_category = 'AX' 
and s.lead_time >= 15
and i.stock_quantity < p.reorder_level
order by s.lead_time desc;
        
# 12.Which low-value, unpredictable products are exposed to high supplier risk due to 
# long lead times and low supplier ratings?

select
	s.supplier_id,
    s.supplier_name,
    p.product_name,
    w.warehouse_name,
    s.rating,
    s.lead_time,
    (i.stock_quantity*p.unit_cost) inventory_value,
    m.abc_xyz_category
from product p
join abc_xyz_matrix m
	on m.product_id = p.product_id
join supplier s 
	on p.supplier_id = s.supplier_id
join inventory i
	on i.product_id = p.product_id
join warehouse w
	on w.warehouse_id = i.warehouse_id
where m.abc_xyz_category = 'CZ' 
and s.lead_time >= 15
and s.rating < 3
order by s.rating desc;

-- Business Insight:
-- Some low-value and unpredictable products are supplied by suppliers with long lead 
-- times and low ratings. The company should avoid keeping unnecessary inventory for 
-- these products and review these suppliers to reduce supply and inventory risk.

# 13.Which products have the highest damaged and reserved stock, and how much usable 
# inventory is actually available across warehouses?

select
    p.product_id,
    p.product_name,
    m.abc_xyz_category,
    w.warehouse_name,
    i.stock_quantity,
    i.reserved_stock,
    i.damaged_stock,
	(i.stock_quantity - i.reserved_stock - i.damaged_stock) usable_stock,
	ROUND((i.stock_quantity - i.reserved_stock - i.damaged_stock) * p.unit_cost,2) 
    usable_inventory_value

from inventory i
join product p
    on i.product_id = p.product_id
join abc_xyz_matrix m
    on i.product_id = m.product_id
join warehouse w
    on i.warehouse_id = w.warehouse_id
order by usable_stock;

-- Business Insight:
-- Some products may appear to have sufficient stock, but a portion of that stock is
-- reserved or damaged. The company should focus on products with low usable inventory 
-- to get a more accurate picture of actual stock availability.

# 14.Which products have a high percentage of reserved or damaged stock, and
# could this reduce their actual availability for customers?

select
    p.product_id,
    p.product_name,
    i.stock_quantity,
    i.reserved_stock,
    i.damaged_stock,
	ROUND(((i.reserved_stock + i.damaged_stock)
        /i.stock_quantity) * 100, 2) unavailable_stock_percentage,
	(i.stock_quantity - i.reserved_stock - i.damaged_stock)
	actual_availability,
	m.abc_xyz_category
from abc_xyz_matrix m
join product p
    on p.product_id = m.product_id
join inventory i
    on p.product_id = i.product_id
order by unavailable_stock_percentage desc;
    
-- Business Insight:
-- These products have at least 20% of their stock either reserved or damaged,
-- meaning their actual available stock is lower than the reported stock. 
-- The company should monitor these products closely because low usable inventory 
-- can affect customer availability and lead to stock shortages.


# 15.Which warehouses are holding the highest inventory value, and are they mainly storing
# high-value or low-demand products?

select
    w.warehouse_id,
    w.warehouse_name,
    w.city,
    m.abc_xyz_category,
    round(sum(i.stock_quantity * p.unit_cost), 2) AS inventory_value
from warehouse w
join inventory i
    on i.warehouse_id = w.warehouse_id
join product p
    on p.product_id = i.product_id
join abc_xyz_matrix m
    on p.product_id = m.product_id
group by
    w.warehouse_id,
    w.warehouse_name,
    w.city,
    m.abc_xyz_category
order by inventory_value desc;
    
-- Business Insight:
-- Some warehouses hold high inventory value in unpredictable-demand products. These stocks
-- should be reviewed to reduce excess inventory and tied-up capital.

# Q16.Which products are at the highest risk of stockout, considering their demand
# variability, current stock, reorder level, and supplier lead time?

select
    p.product_id,
    p.product_name,
    m.xyz_category,
    m.coefficient_of_variance,
    i.stock_quantity,
    p.reorder_level,
    s.lead_time,
	case
        when i.stock_quantity < p.reorder_level
             and m.xyz_category = 'Z'
             and s.lead_time >= 15
             then 'Critical'
		when i.stock_quantity < p.reorder_level
			 and (m.xyz_category in ('Y','Z')
			 or s.lead_time >= 15)
			 then 'High'
		when i.stock_quantity < p.reorder_level
             then 'Medium'
		else 'Low'
    end as stockout_risk
from abc_xyz_matrix m
join product p
    on m.product_id = p.product_id
join inventory i
    on p.product_id = i.product_id
join supplier s
    on p.supplier_id = s.supplier_id
order by
	case
        when i.stock_quantity < p.reorder_level
             and m.xyz_category = 'Z'
             and s.lead_time >= 15 then 1
        when i.stock_quantity < p.reorder_level then 2
        else 3
    end,
    m.coefficient_of_variance desc;
	
-- Business Insight:
-- Products with unpredictable demand, low stock, and long supplier lead times have the
-- highest stockout risk and should be prioritized for replenishment.

# Q17.Which high-revenue products are exposed to demand uncertainty, and does the company
# have enough stock to protect against potential stockouts?

select
    p.product_name,
    m.abc_xyz_category,
    m.avg_demand,
    i.stock_quantity,
    p.reorder_level
from abc_xyz_matrix m
join product p
    on p.product_id = m.product_id
join inventory i
    on i.product_id = p.product_id
where m.abc_xyz_category in ('AY', 'AZ')
order by i.stock_quantity;

-- Business Insight:
-- AY and AZ products are high-value but have uncertain demand. The company should closely
-- monitor their stock levels and reorder on time to avoid stockouts without keeping too
-- much extra inventory.

# Q18.Which products have high demand but are not generating enough revenue, and should the
# company reconsider their pricing or sales strategy?

select
    p.product_name,
    m.xyz_category,
    m.avg_demand,
    m.total_revenue,
    p.selling_price,
    p.unit_cost
from abc_xyz_matrix m
join product p
    on p.product_id = m.product_id
where m.xyz_category = 'X'
order by m.avg_demand desc;

-- Business Insight:
-- Some products have high and stable demand but generate relatively low revenue.
-- The company can review their pricing and sales strategy to improve revenue from
-- these products.

# Q19.Can the company automatically flag products for replenishment when their stock
# falls below the reorder level?

delimiter //
create trigger check_reorder_level
after update on inventory
for each row
begin
    if new.stock_quantity < (
        select reorder_level
        from product
        where product_id = new.product_id)
    then
        Insert into inventory_alert (product_id, alert_message) values
        (new.product_id, 'Stock below reorder level');
    end if;
end // delimiter ;

-- Business Insights:
-- The trigger automatically creates an alert when stock goes below the reorder level, 
-- helping the company identify products that need replenishment.

# 20.Can the company generate a warehouse-wise inventory summary showing total stock,
# inventory value, and the number of products stored in each warehouse?

delimiter //
create procedure warehouse_inventory_summary()
begin
    select
        w.warehouse_id,
        w.warehouse_name,
        count(distinct i.product_id) total_products,
        sum(i.stock_quantity) total_stock,
        round(sum(i.stock_quantity * p.unit_cost), 2) inventory_value
    from warehouse w
    join inventory i
        on w.warehouse_id = i.warehouse_id
    join product p
        on i.product_id = p.product_id
    group by
        w.warehouse_id,
        w.warehouse_name
    order by inventory_value desc;
end // delimiter ;

call warehouse_inventory_summary();

-- Business Insight:
-- This report shows which warehouses hold more products, stock, and inventory value,
-- helping the company compare inventory distribution across warehouses.