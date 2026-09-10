"""Analysis 1 - is a flavour launch incremental, or does it redistribute demand?

Launch revenue splits into two parts:

  * revenue from customers whose first-ever order is the launch order.
    Unambiguously incremental.
  * revenue from customers who already bought from TrueSeaMoss. This is the
    ambiguous half - it is only incremental if those customers spent MORE in
    total than they otherwise would have, rather than simply swapping one
    flavour for another.

The second part is settled with a difference-in-differences against a control
group of customers who were equally active in the launch window but did not
buy the launch flavour. Comparing adopters to all existing customers would be
badly biased: adopters bought something by construction, so they are active by
definition. Requiring the control to have ordered in the same window removes
that. Both groups are then stratified into quintiles by pre-period spend so a
richer adopter base cannot masquerade as a launch effect.

Windows are 60 days pre and 60 days post, which is the widest span with
complete data for all three launches.
"""

from common import COHORT, LAUNCHES, client, scope_filter

PRE_DAYS = 60
POST_DAYS = 60
BUCKETS = 5

# Calibration for the difference-in-differences. Customers who buy any given
# flavour are more engaged than those who do not, so some of the measured lift
# is selection rather than launch effect. Running the identical design on
# long-established flavours - where no launch occurred - measures that floor,
# which is then subtracted from each launch estimate.
# (category, flavour, pseudo-launch date)
PLACEBOS = [
    ("Gel", "Mango, Pineapple", "2026-06-15"),
    ("Gel", "Ashwagandha", "2026-06-15"),
    ("Gel", "Soursop", "2026-03-20"),
]


def decomposition_query(category, flavour, launch_date, horizon):
    """Split launch-flavour revenue by whether the customer predates the launch.

    Classifying on `date = acquisition_date` would be wrong here: a customer
    acquired two weeks into the launch window who then reorders looks
    "existing" on their second order, even though all of their revenue is
    launch-driven acquisition. Membership is therefore decided by first-ever
    order date against the launch date, which is the same population the
    difference-in-differences below operates on.
    """
    return f"""
    WITH first_order AS (
      SELECT customer_id, MIN(date) AS first_date
      FROM {COHORT}
      WHERE {scope_filter()} AND customer_id IS NOT NULL AND customer_id <> ''
      GROUP BY 1
    ),
    lines AS (
      SELECT b.customer_id, b.order_id, b.total_sales,
             f.first_date < DATE '{launch_date}' AS pre_existing
      FROM {COHORT} b
      LEFT JOIN first_order f ON f.customer_id = b.customer_id
      WHERE {scope_filter('b')}
        AND b.master_product_category = '{category}'
        AND b.component_sku_flavour_name = '{flavour}'
        AND b.date >= DATE '{launch_date}'
        AND b.date < DATE_ADD(DATE '{launch_date}', INTERVAL {horizon} DAY)
    )
    SELECT
      COUNT(DISTINCT order_id) AS orders,
      ROUND(SUM(total_sales), 0) AS gross_sales,
      COUNT(DISTINCT IF(NOT pre_existing, customer_id, NULL)) AS new_customers,
      ROUND(SUM(IF(NOT pre_existing, total_sales, 0)), 0) AS new_customer_sales,
      COUNT(DISTINCT IF(pre_existing, customer_id, NULL)) AS existing_customers,
      ROUND(SUM(IF(pre_existing, total_sales, 0)), 0) AS existing_customer_sales
    FROM lines
    """


def did_query(category, flavour, launch_date):
    """Stratified difference-in-differences panel, aggregated by spend quintile."""
    return f"""
    WITH first_order AS (
      SELECT customer_id, MIN(date) AS first_date
      FROM {COHORT}
      WHERE {scope_filter()} AND customer_id IS NOT NULL AND customer_id <> ''
      GROUP BY 1
    ),
    existing AS (
      SELECT customer_id FROM first_order WHERE first_date < DATE '{launch_date}'
    ),
    -- everyone who was ACTIVE in the adoption window, flagged by whether
    -- their activity included the launch flavour
    active AS (
      SELECT
        b.customer_id,
        MAX(IF(b.master_product_category = '{category}'
               AND b.component_sku_flavour_name = '{flavour}', 1, 0)) AS adopted
      FROM {COHORT} b
      JOIN existing e ON e.customer_id = b.customer_id
      WHERE {scope_filter('b')}
        AND b.date >= DATE '{launch_date}'
        AND b.date < DATE_ADD(DATE '{launch_date}', INTERVAL {POST_DAYS} DAY)
      GROUP BY 1
    ),
    pre AS (
      SELECT b.customer_id, SUM(b.total_sales) AS spend
      FROM {COHORT} b
      JOIN active a ON a.customer_id = b.customer_id
      WHERE {scope_filter('b')}
        AND b.date >= DATE_SUB(DATE '{launch_date}', INTERVAL {PRE_DAYS} DAY)
        AND b.date < DATE '{launch_date}'
      GROUP BY 1
    ),
    post AS (
      SELECT b.customer_id, SUM(b.total_sales) AS spend
      FROM {COHORT} b
      JOIN active a ON a.customer_id = b.customer_id
      WHERE {scope_filter('b')}
        AND b.date >= DATE '{launch_date}'
        AND b.date < DATE_ADD(DATE '{launch_date}', INTERVAL {POST_DAYS} DAY)
      GROUP BY 1
    ),
    panel AS (
      SELECT
        a.customer_id, a.adopted,
        COALESCE(pre.spend, 0) AS pre_spend,
        COALESCE(post.spend, 0) AS post_spend
      FROM active a
      LEFT JOIN pre ON pre.customer_id = a.customer_id
      LEFT JOIN post ON post.customer_id = a.customer_id
    ),
    bucketed AS (
      SELECT *, NTILE({BUCKETS}) OVER (ORDER BY pre_spend) AS pre_bucket
      FROM panel
    )
    SELECT
      pre_bucket, adopted,
      COUNT(*) AS customers,
      ROUND(AVG(pre_spend), 2) AS avg_pre,
      ROUND(AVG(post_spend), 2) AS avg_post
    FROM bucketed
    GROUP BY 1, 2
    ORDER BY 1, 2
    """


def run_did(bq, label, category, flavour, launch_date, verbose=True):
    rows = list(bq.query(did_query(category, flavour, launch_date)).result())
    by_bucket = {}
    for r in rows:
        by_bucket.setdefault(r.pre_bucket, {})[r.adopted] = r

    if verbose:
        print(f"\n{label}  -  launched {launch_date}   "
              f"[{PRE_DAYS}d pre vs {POST_DAYS}d post, pre-launch customers only]")
        print("-" * 96)
        print(f"{'quintile':<10}{'adopters':>10}{'control':>10}"
              f"{'adopt Δ':>12}{'control Δ':>12}{'DiD/cust':>11}{'incremental $':>15}")

    total_incremental = 0.0
    total_adopters = 0
    for b in sorted(by_bucket):
        pair = by_bucket[b]
        if 1 not in pair or 0 not in pair:
            continue
        t, c = pair[1], pair[0]
        t_delta = float(t.avg_post) - float(t.avg_pre)
        c_delta = float(c.avg_post) - float(c.avg_pre)
        did = t_delta - c_delta
        incremental = did * t.customers
        total_incremental += incremental
        total_adopters += t.customers
        if verbose:
            print(f"Q{b:<9}{t.customers:>10,}{c.customers:>10,}"
                  f"{t_delta:>12,.2f}{c_delta:>12,.2f}{did:>11,.2f}{incremental:>15,.0f}")

    per_cust = total_incremental / total_adopters if total_adopters else 0
    if verbose:
        print(f"{'TOTAL':<10}{total_adopters:>10,}{'':>10}{'':>12}{'':>12}"
              f"{per_cust:>11,.2f}{total_incremental:>15,.0f}")
    return total_incremental, total_adopters, per_cust


def placebo_baseline(bq):
    """Mean per-customer DiD across established flavours - the selection floor."""
    print("\n\n### Step 2b - placebo calibration")
    print("    identical design run on established flavours with no launch event;")
    print("    whatever lift shows up here is selection, not launch effect")
    print("-" * 96)
    print(f"{'flavour':<28}{'window':<14}{'adopters':>10}{'DiD/cust':>12}")
    per_cust_values = []
    for category, flavour, date in PLACEBOS:
        _, adopters, per_cust = run_did(bq, flavour, category, flavour, date, verbose=False)
        per_cust_values.append(per_cust)
        print(f"{flavour:<28}{date:<14}{adopters:>10,}{per_cust:>12,.2f}")
    baseline = sum(per_cust_values) / len(per_cust_values)
    print(f"{'BASELINE (mean)':<28}{'':<14}{'':>10}{baseline:>12,.2f}")
    return baseline


def main():
    bq = client()
    print("=" * 96)
    print("ANALYSIS 1 - INCREMENTAL vs REDISTRIBUTED  (Shopify / United States)")
    print("=" * 96)

    print("\n### Step 1 - where does launch revenue come from? (first 60 days)")
    print("-" * 96)
    print(f"{'launch':<24}{'gross $':>12}{'new cust':>10}{'new $':>12}"
          f"{'new %':>8}{'exist cust':>12}{'exist $':>12}{'exist %':>9}")
    decomp = {}
    for label, category, flavour, launch_date in LAUNCHES:
        r = list(bq.query(decomposition_query(category, flavour, launch_date, POST_DAYS)).result())[0]
        new_pct = 100 * r.new_customer_sales / r.gross_sales if r.gross_sales else 0
        exist_pct = 100 * r.existing_customer_sales / r.gross_sales if r.gross_sales else 0
        decomp[label] = r
        print(f"{label:<24}{r.gross_sales:>12,.0f}{r.new_customers:>10,}"
              f"{r.new_customer_sales:>12,.0f}{new_pct:>7.1f}%{r.existing_customers:>12,}"
              f"{r.existing_customer_sales:>12,.0f}{exist_pct:>8.1f}%")

    print("\n\n### Step 2 - is the existing-customer half incremental?")
    print("    (difference-in-differences vs equally-active non-adopters,")
    print("     stratified by pre-period spend)")

    verdicts = {}
    for label, category, flavour, launch_date in LAUNCHES:
        _, adopters, per_cust = run_did(bq, label, category, flavour, launch_date)
        verdicts[label] = (adopters, per_cust)

    baseline = placebo_baseline(bq)

    print("\n\n### Step 3 - verdict  (placebo-adjusted)")
    print("-" * 96)
    print(f"{'launch':<24}{'DiD/cust':>10}{'adj/cust':>10}{'adj incr $':>13}"
          f"{'existing $':>13}{'redistributed':>15}{'true incr. $':>15}")
    for label, _, _, _ in LAUNCHES:
        r = decomp[label]
        existing = float(r.existing_customer_sales)
        adopters, per_cust = verdicts[label]
        adj_per_cust = per_cust - baseline
        adj_incremental = adj_per_cust * adopters
        # the incremental share cannot exceed what these customers actually
        # spent on the flavour; anything above that is basket expansion beyond
        # the launch itself and is not counted toward launch revenue
        incr_capped = max(min(adj_incremental, existing), 0.0)
        redistributed = existing - incr_capped
        true_incr = float(r.new_customer_sales) + incr_capped
        print(f"{label:<24}{per_cust:>10,.2f}{adj_per_cust:>10,.2f}{adj_incremental:>13,.0f}"
              f"{existing:>13,.0f}{redistributed:>15,.0f}{true_incr:>15,.0f}")


if __name__ == "__main__":
    main()
