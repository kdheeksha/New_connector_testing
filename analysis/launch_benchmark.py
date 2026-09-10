"""Analysis 2 - launch benchmark curves.

Indexes each gel launch to day 0 and reports cumulative performance at
T+30 / T+60 / T+90 so launches at different calendar dates can be compared
on equal footing.
"""

from common import COHORT, LAUNCHES, client, scope_filter

MILESTONES = (30, 60, 90)


def curve_query(category, flavour, launch_date):
    return f"""
    WITH flavour_lines AS (
      SELECT
        DATE_DIFF(date, DATE '{launch_date}', DAY) AS day_index,
        order_id, customer_id, acquisition_date, date,
        total_sales, net_sales
      FROM {COHORT}
      WHERE {scope_filter()}
        AND master_product_category = '{category}'
        AND component_sku_flavour_name = '{flavour}'
        AND date >= DATE '{launch_date}'
    )
    SELECT
      m AS milestone,
      COUNT(DISTINCT order_id) AS orders,
      COUNT(DISTINCT customer_id) AS customers,
      COUNT(DISTINCT IF(date = acquisition_date, customer_id, NULL)) AS new_customers,
      ROUND(SUM(total_sales), 0) AS gross_sales,
      ROUND(SUM(net_sales), 0) AS net_sales,
      ROUND(SUM(IF(date = acquisition_date, total_sales, 0)), 0) AS ntb_sales,
      ROUND(SAFE_DIVIDE(SUM(total_sales), COUNT(DISTINCT order_id)), 2) AS aov
    FROM flavour_lines
    CROSS JOIN UNNEST({list(MILESTONES)}) AS m
    WHERE day_index BETWEEN 0 AND m - 1
    GROUP BY m
    ORDER BY m
    """


def repeat_rate_query(category, flavour, launch_date):
    """Share of launch-window adopters who bought anything again within 60d."""
    return f"""
    WITH adopters AS (
      SELECT DISTINCT customer_id, MIN(date) OVER (PARTITION BY customer_id) AS first_buy
      FROM {COHORT}
      WHERE {scope_filter()}
        AND master_product_category = '{category}'
        AND component_sku_flavour_name = '{flavour}'
        AND date BETWEEN DATE '{launch_date}' AND DATE_ADD(DATE '{launch_date}', INTERVAL 29 DAY)
        AND customer_id IS NOT NULL
    ),
    repeats AS (
      SELECT a.customer_id
      FROM adopters a
      JOIN {COHORT} b
        ON b.customer_id = a.customer_id
       AND b.date > a.first_buy
       AND b.date <= DATE_ADD(a.first_buy, INTERVAL 60 DAY)
      WHERE {scope_filter('b')}
      GROUP BY 1
    )
    SELECT
      (SELECT COUNT(*) FROM adopters) AS adopters,
      (SELECT COUNT(*) FROM repeats) AS repeated,
      ROUND(100 * SAFE_DIVIDE((SELECT COUNT(*) FROM repeats),
                              (SELECT COUNT(*) FROM adopters)), 1) AS repeat_rate_pct
    """


def main():
    bq = client()
    print("=" * 96)
    print("ANALYSIS 2 - LAUNCH BENCHMARK CURVES  (Shopify / United States)")
    print("=" * 96)

    for label, category, flavour, launch_date in LAUNCHES:
        print(f"\n{label}  -  launched {launch_date}")
        print("-" * 96)
        print(f"{'window':<9}{'orders':>9}{'customers':>11}{'new cust':>10}"
              f"{'gross $':>13}{'net $':>13}{'NTB %':>8}{'AOV':>8}")
        for r in bq.query(curve_query(category, flavour, launch_date)).result():
            ntb_pct = 100 * r.ntb_sales / r.gross_sales if r.gross_sales else 0
            print(f"T+{r.milestone:<7}{r.orders:>9,}{r.customers:>11,}{r.new_customers:>10,}"
                  f"{r.gross_sales:>13,.0f}{r.net_sales:>13,.0f}{ntb_pct:>7.1f}%{r.aov:>8.2f}")

        rr = list(bq.query(repeat_rate_query(category, flavour, launch_date)).result())[0]
        print(f"  first-30d adopters: {rr.adopters:,}  |  "
              f"bought again within 60d: {rr.repeated:,} ({rr.repeat_rate_pct}%)")


if __name__ == "__main__":
    main()
