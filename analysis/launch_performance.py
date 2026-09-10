"""Performance profile for the newly launched gel flavours.

Trading view rather than the incrementality study: volume, AOV, order-type mix,
customer mix, discounting and returns. Reported two ways - life-to-date, which
answers "how is it doing now", and a like-for-like first-60-days cut, which is
the only fair way to rank launches of different ages against each other.
"""

from common import COHORT, LAUNCHES, client, scope_filter

LFL_DAYS = 60


def _window(launch_date, days=None):
    if days is None:
        return f"AND date >= DATE '{launch_date}'"
    return (f"AND date >= DATE '{launch_date}' "
            f"AND date < DATE_ADD(DATE '{launch_date}', INTERVAL {days} DAY)")


def headline(category, flavour, launch_date, days=None):
    return f"""
    SELECT
      COUNT(DISTINCT order_id) AS orders,
      COUNT(DISTINCT customer_id) AS customers,
      ROUND(SUM(total_sales), 0) AS gross,
      ROUND(SUM(net_sales), 0) AS net,
      ROUND(SAFE_DIVIDE(SUM(total_sales), COUNT(DISTINCT order_id)), 2) AS aov,
      ROUND(SUM(total_purchased_units), 0) AS units,
      ROUND(SAFE_DIVIDE(SUM(total_purchased_units), COUNT(DISTINCT order_id)), 2) AS units_per_order,
      ROUND(SAFE_DIVIDE(SUM(item_discount), SUM(gross_sales)) * 100, 1) AS discount_rate,
      ROUND(SAFE_DIVIDE(SUM(refunded_amount_by_return_date), SUM(total_sales)) * 100, 1) AS return_rate
    FROM {COHORT}
    WHERE {scope_filter()}
      AND master_product_category = '{category}'
      AND component_sku_flavour_name = '{flavour}'
      {_window(launch_date, days)}
    """


def order_type(category, flavour, launch_date, days=None):
    return f"""
    SELECT
      COALESCE(order_type_by_subscription, 'Unclassified') AS otype,
      COUNT(DISTINCT order_id) AS orders,
      COUNT(DISTINCT customer_id) AS customers,
      ROUND(SUM(total_sales), 0) AS gross,
      ROUND(SAFE_DIVIDE(SUM(total_sales), COUNT(DISTINCT order_id)), 2) AS aov
    FROM {COHORT}
    WHERE {scope_filter()}
      AND master_product_category = '{category}'
      AND component_sku_flavour_name = '{flavour}'
      {_window(launch_date, days)}
    GROUP BY 1 ORDER BY gross DESC
    """


def monthly(category, flavour, launch_date):
    return f"""
    SELECT
      FORMAT_DATE('%Y-%m', date) AS mth,
      COUNT(DISTINCT order_id) AS orders,
      ROUND(SUM(total_sales), 0) AS gross,
      ROUND(SAFE_DIVIDE(SUM(total_sales), COUNT(DISTINCT order_id)), 2) AS aov,
      ROUND(100 * SAFE_DIVIDE(
        COUNT(DISTINCT IF(order_type_by_subscription = 'Subscription Order', order_id, NULL)),
        COUNT(DISTINCT order_id)), 1) AS sub_order_pct
    FROM {COHORT}
    WHERE {scope_filter()}
      AND master_product_category = '{category}'
      AND component_sku_flavour_name = '{flavour}'
      {_window(launch_date)}
    GROUP BY 1 ORDER BY 1
    """


def customer_mix(category, flavour, launch_date, days=None):
    return f"""
    WITH first_order AS (
      SELECT customer_id, MIN(date) AS first_date
      FROM {COHORT}
      WHERE {scope_filter()} AND customer_id IS NOT NULL AND customer_id <> ''
      GROUP BY 1
    )
    SELECT
      IF(f.first_date < DATE '{launch_date}', 'Pre-existing customer', 'Acquired at/after launch') AS seg,
      COUNT(DISTINCT b.customer_id) AS customers,
      COUNT(DISTINCT b.order_id) AS orders,
      ROUND(SUM(b.total_sales), 0) AS gross,
      ROUND(SAFE_DIVIDE(SUM(b.total_sales), COUNT(DISTINCT b.order_id)), 2) AS aov
    FROM {COHORT} b
    LEFT JOIN first_order f ON f.customer_id = b.customer_id
    WHERE {scope_filter('b')}
      AND b.master_product_category = '{category}'
      AND b.component_sku_flavour_name = '{flavour}'
      AND b.date >= DATE '{launch_date}'
      {'' if days is None else f"AND b.date < DATE_ADD(DATE '{launch_date}', INTERVAL {days} DAY)"}
    GROUP BY 1 ORDER BY gross DESC
    """


def pack_mix(category, flavour, launch_date):
    return f"""
    SELECT
      COALESCE(package_type, 'Unspecified') AS pack,
      COUNT(DISTINCT order_id) AS orders,
      ROUND(SUM(total_sales), 0) AS gross
    FROM {COHORT}
    WHERE {scope_filter()}
      AND master_product_category = '{category}'
      AND component_sku_flavour_name = '{flavour}'
      {_window(launch_date)}
    GROUP BY 1 ORDER BY gross DESC LIMIT 6
    """


def main():
    bq = client()
    print("=" * 100)
    print("LAUNCH PERFORMANCE PROFILE  (Shopify / United States)")
    print("=" * 100)

    for scope_label, days in (("LIFE TO DATE", None), (f"FIRST {LFL_DAYS} DAYS (like-for-like)", LFL_DAYS)):
        print(f"\n\n##### {scope_label}")
        print(f"{'launch':<24}{'orders':>9}{'customers':>11}{'gross $':>13}{'AOV':>9}"
              f"{'units/ord':>11}{'disc %':>9}{'return %':>10}")
        for label, cat, flav, d in LAUNCHES:
            r = list(bq.query(headline(cat, flav, d, days)).result())[0]
            print(f"{label:<24}{r.orders:>9,}{r.customers:>11,}{r.gross:>13,.0f}{r.aov:>9.2f}"
                  f"{r.units_per_order:>11.2f}{r.discount_rate:>9}{r.return_rate:>10}")

    print("\n\n##### ORDER TYPE MIX  (life to date)")
    for label, cat, flav, d in LAUNCHES:
        print(f"\n  {label}")
        print(f"    {'type':<24}{'orders':>9}{'customers':>11}{'gross $':>13}{'AOV':>9}{'% of gross':>12}")
        rows = list(bq.query(order_type(cat, flav, d)).result())
        tot = sum(float(x.gross) for x in rows) or 1
        for r in rows:
            print(f"    {r.otype:<24}{r.orders:>9,}{r.customers:>11,}{r.gross:>13,.0f}"
                  f"{r.aov:>9.2f}{100*float(r.gross)/tot:>11.1f}%")

    print("\n\n##### CUSTOMER MIX  (life to date)")
    for label, cat, flav, d in LAUNCHES:
        print(f"\n  {label}")
        print(f"    {'segment':<28}{'customers':>11}{'orders':>9}{'gross $':>13}{'AOV':>9}")
        for r in bq.query(customer_mix(cat, flav, d)).result():
            print(f"    {r.seg:<28}{r.customers:>11,}{r.orders:>9,}{r.gross:>13,.0f}{r.aov:>9.2f}")

    print("\n\n##### MONTHLY TRAJECTORY")
    for label, cat, flav, d in LAUNCHES:
        print(f"\n  {label}  (launched {d})")
        print(f"    {'month':<10}{'orders':>9}{'gross $':>13}{'AOV':>9}{'sub order %':>13}")
        for r in bq.query(monthly(cat, flav, d)).result():
            print(f"    {r.mth:<10}{r.orders:>9,}{r.gross:>13,.0f}{r.aov:>9.2f}{r.sub_order_pct:>12}%")

    print("\n\n##### PACK / FORMAT MIX  (life to date)")
    for label, cat, flav, d in LAUNCHES:
        print(f"\n  {label}")
        for r in bq.query(pack_mix(cat, flav, d)).result():
            print(f"    {str(r.pack)[:34]:<36}{r.orders:>9,} orders{r.gross:>13,.0f}")


if __name__ == "__main__":
    main()
