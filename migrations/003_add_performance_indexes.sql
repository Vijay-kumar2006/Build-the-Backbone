-- 003_add_performance_indexes.sql

-- 1. Orders by user - fixes order history N+1 scan
-- Justification: GET /api/orders/history filters by user_id on a table that grows without bound - sequential scan becomes unusable above 10K rows.
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);

-- 2. Composite: orders by user + date - eliminates sort step
-- Justification: Order history is always sorted newest-first; this index covers both the WHERE user_id filter and the ORDER BY order_date DESC.
CREATE INDEX IF NOT EXISTS idx_orders_user_created ON orders(user_id, order_date DESC);

-- 3. Order items by order - fixes menu N+1
-- Justification: Every GET /restaurants/:id/menu fetches order_items by order_id in a loop - this index converts each inner query from a full table scan to a single index lookup.
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);

-- 4. Menu items by restaurant - fixes restaurant menu scan
-- Justification: GET /restaurants/:id/menu always filters by restaurant_id; without this index, every menu request scans the entire menu_items table.
CREATE INDEX IF NOT EXISTS idx_menu_items_restaurant ON menu_items(restaurant_id);

-- 5. Restaurants by city+active - covers browsing filter
-- Justification: The browse endpoint always filters WHERE city=$1 AND active=true; partial composite index covers this exact pattern.
CREATE INDEX IF NOT EXISTS idx_restaurants_city_active ON restaurants(city, is_active) WHERE is_active = true;
