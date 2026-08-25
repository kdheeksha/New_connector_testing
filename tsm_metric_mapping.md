# TSM Metric → Connector Query Mapping

All 20 Google Sheet metrics and how each one is derived from the 4 Daton queries.

## How to read the BQ tables

| Daton Query | BQ Table (example name) | Key filter columns |
|---|---|---|
| Query 1 | `tsm_meta_pixel` | `channel='facebook-ads'`, `model`, `attribution_window` |
| Query 2 | `tsm_google_pixel` | `channel='google-ads'`, `model`, `attribution_window` |
| Query 3 | `tsm_google_segments_pixel` | `segment`, `model`, `attribution_window` |
| Query 4 | `tsm_meta_inapp` | (flat, one row per date) |

---

## Meta metrics (Sheet columns → BQ filter)

| Sheet column | Table | model | attribution_window | Value column | Source |
|---|---|---|---|---|---|
| `triple_whale_meta_cac_first_touch_7d` | — | — | — | — | ❌ Manual entry only — Clicks & Views not in TVF for this account |
| `triple_whale_meta_cac_last_touch_7d` | — | — | — | — | ❌ Manual entry only — Last Click not in TVF for this account |
| `triple_whale_meta_cac_triple_att_7d` | tsm_meta_pixel | `Triple Attribution` | `lifetime` | `nccpa` | ✅ Connector |
| `triple_whale_meta_ncp_firt_click` *(typo in source)* | — | — | — | — | ❌ Manual entry only — Clicks & Views not in TVF for this account |
| `triple_whale_meta_ncp_lat_click` *(typo in source)* | — | — | — | — | ❌ Manual entry only — Last Click not in TVF for this account |
| `triple_whale_meta_ncp_triple_att_7d` | tsm_meta_pixel | `Triple Attribution` | `lifetime` | `total_ncp` | ✅ Connector |
| `meta_inapp_purchases` | tsm_meta_inapp | — | — | `meta_inapp_purchases` | ✅ Connector |
| `meta_in_app_cpa` | tsm_meta_inapp | — | — | `meta_in_app_cpa` | ✅ Connector |

Source: `ads_table.conversions` — Meta's normalized platform-reported purchase count. Not onsite_purchases, not the actions array. Verified Aug 1 2026: spend $207,561.88 / conversions 2,530 / CPA $82.04.

### Meta 28-day equivalents
| Metric | model | attribution_window |
|---|---|---|
| Meta CAC first-touch 28d | `Clicks & Views` | `28_days` |
| Meta CAC last-touch 28d | `Last Click` | `28_days` |
| Meta CAC triple-att 28d | `Triple Attribution` | `28_days` |
| Meta NCP first-touch 28d | `Clicks & Views` | `28_days` |
| Meta NCP last-touch 28d | `Last Click` | `28_days` |
| Meta NCP triple-att 28d | `Triple Attribution` | `28_days` |

---

## Google metrics (Sheet columns → BQ filter)

| Sheet column | Table | model | attribution_window | Value column |
|---|---|---|---|---|
| `triple_whale_google_cac_first_touch_7d` | tsm_google_pixel | `First Click` | `lifetime` | `nccpa` |
| `triple_whale_google_cac_last_touch_7d` | tsm_google_pixel | `Last Click` | `7_days` | `nccpa` |
| `triple_whale_google_cac_triple_att_7d` | tsm_google_pixel | `Triple Attribution` | `lifetime` | `nccpa` |

> Note: "first_touch_7d" in the sheet name is misleading — the validated match
> uses `attribution_window = 'lifetime'` for First Click on Google. The `7d`
> in the column name refers to the reporting period, not the attribution window.

### Google 28-day equivalents
| Metric | model | attribution_window |
|---|---|---|
| Google CAC first-touch 28d | `First Click` | `28_days` |
| Google CAC last-touch 28d | `Last Click` | `28_days` |
| Google CAC triple-att 28d | `Triple Attribution` | `28_days` |

---

## Google Campaign Segment metrics (Brand / DG / Prospecting)

All 9 sheet metrics come from `tsm_google_segments_pixel`, filtered by `segment`.

| Sheet column | segment | model | attribution_window | Value |
|---|---|---|---|---|
| `brand_first_touch_7d` | `Brand` | `First Click` | `lifetime` | `nccpa` |
| `brand_last_touch_7d` | `Brand` | `Last Click` | `7_days` | `nccpa` |
| `brand_triple_att_7d` | `Brand` | `Triple Attribution` | `lifetime` | `nccpa` |
| `dg_first_touch_7d` | `DG` | `First Click` | `lifetime` | `nccpa` |
| `dg_last_touch_7d` | `DG` | `Last Click` | `7_days` | `nccpa` |
| `dg_triple_att_7d` | `DG` | `Triple Attribution` | `lifetime` | `nccpa` |
| `prospecting_first_touch_7d` | `Prospecting` | `First Click` | `lifetime` | `nccpa` |
| `prospecting_last_touch_7d` | `Prospecting` | `Last Click` | `7_days` | `nccpa` |
| `prospecting_triple_att_7d` | `Prospecting` | `Triple Attribution` | `lifetime` | `nccpa` |

### Segment 28-day equivalents
Same structure — replace `attribution_window` with `28_days` for the relevant model.

---

## Validation status

| Metric group | Status |
|---|---|
| Meta Clicks & Views (7d) | ❌ Not available — model not enabled for this account in Triple Whale |
| Meta Last Click (7d) | ❌ Not available — model not enabled for this account in Triple Whale |
| Meta Triple Attribution (lifetime) | ✅ Validated |
| Google First Click (lifetime window) | ✅ Validated (avg gap 0.38%, max 0.97%) |
| Google Last Click (7d) | ✅ Validated |
| Google Triple Attribution (lifetime) | ✅ Validated |
| Brand FC / LC / TA | ✅ Validated |
| DG FC / LC / TA | ✅ Validated (LC volatility = 0-3 orders/day, expected) |
| Prospecting FC / LC / TA | ✅ Validated (sheet shows 0 — team stopped entering; SQL correct) |
| 28-day windows | ⏳ Pending first connector run |
| meta_inapp_purchases / meta_in_app_cpa | ✅ Validated — ads_table.conversions |

---

## Security reminder

The GCP service account key (key ID starting `5854c5c6...`) for
`trueseamoss-service-account@daton-project.iam.gserviceaccount.com`
was exposed during this session. **Rotate/delete this key in GCP IAM immediately
before activating the connector in production.**
