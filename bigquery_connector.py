"""BigQuery connector using a service account JSON key file."""

import json
import os
from google.cloud import bigquery
from google.oauth2 import service_account


SERVICE_ACCOUNT_FILE = os.path.join(os.path.dirname(__file__), "service_account.json")


def get_client(key_file: str = SERVICE_ACCOUNT_FILE) -> bigquery.Client:
    """Return an authenticated BigQuery client."""
    credentials = service_account.Credentials.from_service_account_file(
        key_file,
        scopes=["https://www.googleapis.com/auth/bigquery"],
    )
    with open(key_file) as f:
        project = json.load(f)["project_id"]
    return bigquery.Client(credentials=credentials, project=project)


def list_datasets(client: bigquery.Client) -> list[str]:
    """Return dataset IDs visible to the service account."""
    return [ds.dataset_id for ds in client.list_datasets()]


def run_query(client: bigquery.Client, sql: str) -> list[dict]:
    """Execute a SQL query and return rows as dicts."""
    return [dict(row) for row in client.query(sql).result()]


if __name__ == "__main__":
    client = get_client()
    print(f"Connected to project: {client.project}")

    datasets = list_datasets(client)
    if datasets:
        print(f"Datasets ({len(datasets)}):")
        for ds in datasets:
            print(f"  - {ds}")
    else:
        print("No datasets found (service account may have restricted access).")

    # Quick sanity-check query — works without any dataset permissions
    rows = run_query(client, "SELECT 1 AS ping")
    print(f"Test query result: {rows}")
