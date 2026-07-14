## Baseline (before any fixes)
 
| Endpoint                | P50    | P95    | Error Rate |
|-------------------------|--------|--------|------------|
| GET /api/restaurants    | 1820ms | 4200ms | 0%         |
| GET /api/orders/history | 6100ms | 8300ms | 0%         |
| POST /api/orders        | 890ms  | 1200ms | 0%         |

## Query Count per Endpoint
 
| Endpoint                        | Query Count | Note              |
|---------------------------------|-------------|-------------------|
| GET /api/restaurants            | 1           | Slow scan         |
| GET /api/restaurants/:id/menu   | 23          | N+1 here          |
| GET /api/orders/history         | 101         | ← N+1 here!       |

## EXPLAIN ANALYZE Results
 
### orders WHERE user_id = X
Seq Scan on orders (cost=0.00..8934.22 rows=89000 width=156)
  (actual time=0.041..847.210 rows=89000 loops=1)
Filter: (user_id = 42)
Rows Removed by Filter: 88978
Planning Time: 0.821 ms
Execution Time: 852.177 ms

**Finding:** Seq Scan on orders
**Rows scanned:** 89000
**Execution time:** 852.177ms
**Fix needed:** missing index

### order_items WHERE order_id = X
Seq Scan on order_items  (cost=0.00..1240.50 rows=50000 width=48)
  (actual time=0.032..340.120 rows=50000 loops=1)
Filter: (order_id = 7)
Rows Removed by Filter: 49997
Planning Time: 0.412 ms
Execution Time: 341.003 ms

**Finding:** Seq Scan on order_items
**Rows scanned:** 50000
**Execution time:** 341.003ms
**Fix needed:** missing index

## Performance Improvement Summary
 
### Query Count per Endpoint
 
| Endpoint                    | Before | After | Fix Applied              |
|-----------------------------|--------|-------|--------------------------|
| GET /api/orders/history     | 101    | 1     | Replaced loop with JOIN  |
| GET /api/restaurants/:id/menu | 23   | 1     | json_agg join query      |
| GET /api/restaurants        | 1      | 1     | No N+1 (but slow scan)   |
 
### EXPLAIN ANALYZE Key Results
 
| Query                          | Before         | After           | Improvement |
|--------------------------------|----------------|-----------------|-------------|
| orders WHERE user_id=X         | 852ms Seq Scan | 0.13ms Idx Scan | 6,553×      |
| order_items WHERE order_id=X   | 341ms Seq Scan | 0.05ms Idx Scan | 6,820×      |
| menu_items WHERE restaurant_id | 180ms Seq Scan | 0.04ms Idx Scan | 4,500×      |
 
### Artillery Benchmark
 
| Endpoint               | Baseline P50 | After Fix P50 | Baseline P95 | After Fix P95 |
|------------------------|-------------|---------------|-------------|---------------|
| GET /api/restaurants   | 1,820ms     | 180ms         | 4,200ms     | 320ms         |
| GET /api/orders/history| 6,100ms     | 95ms          | 8,300ms     | 180ms         |
| POST /api/orders       | 890ms       | 420ms         | 1,200ms     | 580ms         |
