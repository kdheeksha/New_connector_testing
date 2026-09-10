"""Head-to-head: newest gel flavours against the leading electrolyte flavours.

Two views, because "which is performing better" has two legitimate answers:

  * At equal age - each flavour measured over its own first N days, so a launch
    from 2025 can be compared with one from 2026 without the older flavour
    winning purely on having existed longer.
  * Trading now - the most recent complete month, side by side, which is what
    the ranking looks like in the current P&L.

Order-type split (one-time versus subscription) is reported on both views.
"""

from common import COHORT, client, scope_filter

# (label, category, flavour, launch_date)
FLAVOURS = [
    ("Gel · Raspberry/Watermelon", "Gel", "Raspberry, Watermelon", "2026-06-15"),
    ("Gel · Peach/Pear", "Gel", "Peach, Pear", "2026-03-20"),
    ("Elec · Mango/Pineapple", "Electrolytes", "Mango, Pineapple", "2025-07-04"),
    ("Elec · Melon/Watermelon", "Electrolytes", "Melon, Watermelon", "2025-07-04"),
    ("Elec · Banana/Strawberry", "Electrolytes", "Banana, Strawberry", "2025-07-04"),
    ("Elec · Lemon/Lime", "Electrolytes", "Lemon, Lime", "2025-07-04"),
]

EQUAL_AGE_DAYS = 87       # age of the newest gel launch
CURRENT_MONTH = "2026-08"  # most recent complete month


def where(category, flavour):
    return (f"{scope_filter()} AND master_product_category = '{category}' "
            f"AND component_sku_flavour_name = '{flavour}'")


def equal_age(category, flavour, launch_date):
    return f"""
    SELECT
      COUNT(DISTINCT order_id) AS orders,
      COUNT(DISTINCT customer_id) AS customers,
      ROUND(SUM(total_sales), 0) AS gross,
      ROUND(SAFE_DIVIDE(SUM(total_sales), COUNT(DISTINCT order_id)), 2) AS aov,
      COUNT(DISTINCT IF(order_type_by_subscription = 'Subscription Order', customer_id, NULL)) AS sub_custs,
      COUNT(DISTINCT IF(order_type_by_subscription = 'One Time Purchase', customer_id, NULL)) AS otp_custs,
      COUNT(DISTINCT IF(order_type_by_subscription = 'Subscription Order', order_id, NULL)) AS sub_orders,
      COUNT(DISTINCT IF(order_type_by_subscription = 'One Time Purchase', order_id, NULL)) AS otp_orders,
      ROUND(SUM(IF(order_type_by_subscription = 'Subscription Order', total_sales, 0)), 0) AS sub_gross,
      ROUND(SUM(IF(order_type_by_subscription = 'One Time Purchase', total_sales, 0)), 0) AS otp_gross
    FROM {COHORT}
    WHERE {where(category, flavour)}
      AND date >= DATE '{launch_date}'
      AND date < DATE_ADD(DATE '{launch_date}', INTERVAL {EQUAL_AGE_DAYS} DAY)
    """


def current(category, flavour):
    return f"""
    SELECT
      COUNT(DISTINCT order_id) AS orders,
      COUNT(DISTINCT customer_id) AS customers,
      ROUND(SUM(total_sales), 0) AS gross,
      ROUND(SAFE_DIVIDE(SUM(total_sales), COUNT(DISTINCT order_id)), 2) AS aov,
      COUNT(DISTINCT IF(order_type_by_subscription = 'Subscription Order', customer_id, NULL)) AS sub_custs,
      COUNT(DISTINCT IF(order_type_by_subscription = 'One Time Purchase', customer_id, NULL)) AS otp_custs,
      ROUND(SUM(IF(order_type_by_subscription = 'Subscription Order', total_sales, 0)), 0) AS sub_gross,
      ROUND(SUM(IF(order_type_by_subscription = 'One Time Purchase', total_sales, 0)), 0) AS otp_gross,
      ROUND(SAFE_DIVIDE(SUM(item_discount), SUM(gross_sales)) * 100, 1) AS discount_rate,
      ROUND(SAFE_DIVIDE(SUM(refunded_amount_by_return_date), SUM(total_sales)) * 100, 1) AS return_rate
    FROM {COHORT}
    WHERE {where(category, flavour)}
      AND FORMAT_DATE('%Y-%m', date) = '{CURRENT_MONTH}'
    """


def main():
    bq = client()
    print("=" * 104)
    print("GEL vs ELECTROLYTE - FLAVOUR HEAD-TO-HEAD  (Shopify / United States)")
    print("=" * 104)

    print(f"\n##### A. EQUAL AGE - first {EQUAL_AGE_DAYS} days of each flavour's own life")
    print(f"{'flavour':<30}{'orders':>9}{'customers':>11}{'gross $':>12}{'AOV':>8}"
          f"{'sub cust':>10}{'OTP cust':>10}{'sub % gross':>13}")
    rows_a = {}
    for label, cat, flav, d in FLAVOURS:
        r = list(bq.query(equal_age(cat, flav, d)).result())[0]
        rows_a[label] = r
        subpct = 100 * float(r.sub_gross) / float(r.gross) if r.gross else 0
        print(f"{label:<30}{r.orders:>9,}{r.customers:>11,}{r.gross:>12,.0f}{r.aov:>8.2f}"
              f"{r.sub_custs:>10,}{r.otp_custs:>10,}{subpct:>12.1f}%")

    print(f"\n\n##### B. TRADING NOW - {CURRENT_MONTH} (most recent complete month)")
    print(f"{'flavour':<30}{'orders':>9}{'customers':>11}{'gross $':>12}{'AOV':>8}"
          f"{'sub cust':>10}{'OTP cust':>10}{'disc %':>8}{'ret %':>7}")
    for label, cat, flav, d in FLAVOURS:
        r = list(bq.query(current(cat, flav)).result())[0]
        if not r.orders:
            print(f"{label:<30}{'no sales in month':>60}")
            continue
        print(f"{label:<30}{r.orders:>9,}{r.customers:>11,}{r.gross:>12,.0f}{r.aov:>8.2f}"
              f"{r.sub_custs:>10,}{r.otp_custs:>10,}{r.discount_rate:>8}{r.return_rate:>7}")

    print(f"\n\n##### C. ORDER-TYPE DETAIL at equal age (first {EQUAL_AGE_DAYS} days)")
    print(f"{'flavour':<30}{'sub orders':>12}{'sub gross':>12}{'sub AOV':>10}"
          f"{'OTP orders':>12}{'OTP gross':>12}{'OTP AOV':>10}")
    for label, *_ in FLAVOURS:
        r = rows_a[label]
        sub_aov = float(r.sub_gross) / r.sub_orders if r.sub_orders else 0
        otp_aov = float(r.otp_gross) / r.otp_orders if r.otp_orders else 0
        print(f"{label:<30}{r.sub_orders:>12,}{r.sub_gross:>12,.0f}{sub_aov:>10.2f}"
              f"{r.otp_orders:>12,}{r.otp_gross:>12,.0f}{otp_aov:>10.2f}")


if __name__ == "__main__":
    main()
