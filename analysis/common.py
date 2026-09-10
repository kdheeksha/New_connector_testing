"""Shared config for the TrueSeaMoss flavour-launch analyses.

Scope is Shopify / United States throughout, per the agreed analysis scope.
Launch dates are derived from first observed sale — TrueSeaMoss keeps no
launch calendar, so these are proxies and should be reconciled against
Shopify product publish dates before anything is published externally.
"""

from google.cloud import bigquery
from google.oauth2 import service_account

PROJECT = "daton-project"
PRESENTATION = f"{PROJECT}.trueseamoss_5363_prod_presentation_datashare"
STAGING = f"{PROJECT}.trueseamoss_5363_prod_staging_datashare"
COHORT = f"`{PRESENTATION}.sku_cohort_base`"

STORE = "United States"
PLATFORM = "shopify"

# (label, category, flavour, launch_date)
LAUNCHES = [
    ("Cranberry", "Gel", "Cranberry", "2025-12-09"),
    ("Peach/Pear", "Gel", "Peach, Pear", "2026-03-20"),
    ("Raspberry/Watermelon", "Gel", "Raspberry, Watermelon", "2026-06-15"),
]

DATA_FLOOR = "2020-01-01"  # table contains a 1969-12-31 sentinel row


def client():
    creds = service_account.Credentials.from_service_account_file(
        "/home/user/New_connector_testing/service_account.json"
    )
    return bigquery.Client(project=PROJECT, credentials=creds)


def scope_filter(alias=""):
    p = f"{alias}." if alias else ""
    return (
        f"{p}store_name = '{STORE}' AND {p}platform_name = '{PLATFORM}' "
        f"AND {p}date >= '{DATA_FLOOR}'"
    )
