import openpyxl
from openpyxl.styles import Font, Alignment, PatternFill, Border, Side
from openpyxl.formatting.rule import FormulaRule
from openpyxl.utils import get_column_letter

# Self-contained: all three grids live in data/ as TSV, so this script
# regenerates the workbook from the repo with no external dependency.
#   data/client_grid.tsv  the client's Equip LTV analysis, carried over
#                         unchanged from their workbook
#   data/before_lim.tsv   output of sql/10_before_logic_lim.sql
#   data/lim_full.tsv     output of sql/09_production_lim.sql
DATA = 'data'
OUT  = 'Equip cohort validation - before vs after.xlsx'

COHORTS = ['2025-09','2025-10','2025-11','2025-12','2026-01','2026-02',
           '2026-03','2026-04','2026-05','2026-06','2026-07']
# row anchors, identical on both tabs
SEC = [('LIFETIME — all customers','All customers', 4),
       ('ACQUIRED ON OTP','OTP', 48),
       ('ACQUIRED ON SUBSCRIPTION','Subscription', 92)]
# offsets from section start
OURS, CLIENT, DIFF = 3, 17, 31      # data rows begin here

import os

def load_grid(name):
    g = {}
    for ln in open(os.path.join(DATA, name)):
        p = ln.rstrip('\n').split('\t')
        vals = [float(x) for x in p[3:]]
        vals += [None] * (11 - len(vals))
        g.setdefault(p[0], {})[p[1]] = (int(p[2]), vals)
    return g

client = load_grid('client_grid.tsv')
before = load_grid('before_lim.tsv')

# ---- the new LIM "After" grid ----
after  = load_grid('lim_full.tsv')

# ---- styling ----
H1   = Font(bold=True, size=13, color='18181B')
H2   = Font(bold=True, size=11, color='27272A')
SUB  = Font(italic=True, size=9, color='52525B')
HDR  = Font(bold=True, size=10, color='FFFFFF')
NOTE = Font(size=9, color='52525B')
HDRF = PatternFill('solid', fgColor='3F3F46')
SECF = PatternFill('solid', fgColor='EFEFF1')
thin = Side(style='thin', color='D4D4D8')
BOX  = Border(top=thin, bottom=thin, left=thin, right=thin)

# Conditional-formatting fills are DIFFERENTIAL styles (dxf), and Excel
# paints those from the pattern's bgColor, not fgColor. A dxf written as
# solid+fgColor renders as nothing at all. The colour also needs the
# full 8-digit ARGB: a 6-digit value gets a 00 alpha prefix, i.e. fully
# transparent. Earlier versions of this sheet had both faults, which is
# why the colour coding never appeared.
GREEN = PatternFill(bgColor='FFD1FADF')
AMBER = PatternFill(bgColor='FFFEF0C7')
RED   = PatternFill(bgColor='FFFEE4E2')
GREENF = Font(color='FF05603A', size=10)
AMBERF = Font(color='FF93370D', size=10)
REDF   = Font(color='FF912018', size=10, bold=True)

def block(ws, base, label, data, numfmt='#,##0.00'):
    ws.cell(base, 1, label).font = H2
    hr = base + 1
    ws.cell(hr, 1, 'Acquisition Month').font = HDR
    ws.cell(hr, 1).fill = HDRF
    ws.cell(hr, 2, 'Customers').font = HDR; ws.cell(hr, 2).fill = HDRF
    for j in range(11):
        c = ws.cell(hr, 3 + j, 'M%d' % j); c.font = HDR; c.fill = HDRF
        c.alignment = Alignment(horizontal='center')
    for i, co in enumerate(COHORTS):
        r = hr + 1 + i
        ws.cell(r, 1, co).border = BOX
        n, vals = data[co]
        cc = ws.cell(r, 2, n); cc.number_format = '#,##0'; cc.border = BOX
        for j in range(11):
            c = ws.cell(r, 3 + j, vals[j])
            c.number_format = numfmt; c.border = BOX

def diffblock(ws, base, ours_row0, client_row0):
    ws.cell(base, 1,
      '% Diff  =  (ours − client) ÷ client      [green ≤2%  ·  amber 2–5%  ·  red >5%]').font = H2
    hr = base + 1
    ws.cell(hr, 1, 'Acquisition Month').font = HDR; ws.cell(hr, 1).fill = HDRF
    ws.cell(hr, 2, 'Customers').font = HDR; ws.cell(hr, 2).fill = HDRF
    for j in range(11):
        c = ws.cell(hr, 3 + j, 'M%d' % j); c.font = HDR; c.fill = HDRF
        c.alignment = Alignment(horizontal='center')
    for i, co in enumerate(COHORTS):
        r = hr + 1 + i
        ws.cell(r, 1, co).border = BOX
        for j in range(12):                      # customers + M0..M10
            col = get_column_letter(2 + j)
            c = ws.cell(r, 2 + j)
            c.value = '=IFERROR((%s%d-%s%d)/%s%d,"")' % (
                col, ours_row0 + i, col, client_row0 + i, col, client_row0 + i)
            c.number_format = '+0.00%;-0.00%;0.00%'
            c.border = BOX
    rng = 'B%d:M%d' % (hr + 1, hr + 11)
    # absolute-value bands; order matters, first match wins
    ws.conditional_formatting.add(rng, FormulaRule(
        formula=['AND(ISNUMBER(B%d),ABS(B%d)>0.05)' % (hr+1, hr+1)],
        fill=RED, font=REDF, stopIfTrue=True))
    ws.conditional_formatting.add(rng, FormulaRule(
        formula=['AND(ISNUMBER(B%d),ABS(B%d)>0.02)' % (hr+1, hr+1)],
        fill=AMBER, font=AMBERF, stopIfTrue=True))
    ws.conditional_formatting.add(rng, FormulaRule(
        formula=['ISNUMBER(B%d)' % (hr+1)], fill=GREEN, font=GREENF))

def tab(wb, title, heading, strap, ours):
    ws = wb.create_sheet(title)
    ws.freeze_panes = 'B1'
    ws.column_dimensions['A'].width = 20
    for j in range(12):
        ws.column_dimensions[get_column_letter(2 + j)].width = 11
    ws.cell(1, 1, heading).font = H1
    ws.cell(2, 1, strap).font = SUB
    for sect, bucket, base in SEC:
        ws.cell(base, 1, sect).font = H1
        ws.cell(base, 1).fill = SECF
        block(ws, base + 1, 'Cohorts Dashboard (ours)', ours[bucket])
        block(ws, base + 15, 'Equip LTV analysis (client)', client[bucket])
        diffblock(ws, base + 29, base + OURS, base + CLIENT)
    return ws

wb = openpyxl.Workbook(); wb.remove(wb.active)

tab(wb, 'Before logic', 'BEFORE — revenue by acquisition type',
    "Current production logic. A customer's whole lifetime sits in the bucket they were ACQUIRED in.",
    before)

tab(wb, 'After logic', 'AFTER — attribution fixed, Faire included',
    'Sub-acquired customers stay Subscription; OTP-acquired switch at their first subscription order '
    'and do not switch back; M0 stays in the acquisition bucket. Faire customers and revenue included.',
    after)

NOTES = [
 'Notes',
 'Cumulative LTR PER CUSTOMER. Dollars = this value x the Customers column.',
 '% Diff = (ours - client) / client. NOTE: this is the OPPOSITE SIGN to earlier versions of this '
   'sheet, which used (client - ours). It now matches the RCA document. A negative % means we are BELOW the client.',
 'Colour scale is on the ABSOLUTE difference: GREEN within 2%, AMBER 2-5%, RED beyond 5%.',
 '% Diff cells are live formulas and calculate when opened in Excel.',
 '',
 'SOURCES - both tabs come from LineItemMaster, so only the logic differs between them.',
 '  Before tab: sql/10_before_logic_lim.sql - acquisition bucket for life, no Faire.',
 '  After tab:  sql/09_production_lim.sql   - attribution fixed, Faire included.',
 '  Both were validated against the earlier OrderLinesMaster + ReturnLinesMaster build, which they '
   'reproduce to within 0.08% across all 11 cohorts and both buckets. LineItemMaster is simply those '
   'two tables combined, so this is a change of source, not of method.',
 '  Cross-check that holds in the data: the two tabs have IDENTICAL customer counts before 2026-02, '
   'and from 2026-02 the After tab is higher by exactly the Faire retailers - +17 Feb, +33 Mar, '
   '+25 Apr, +37 May, +33 Jun, +46 Jul. Subscription M0 is identical on both tabs in every cohort, '
   'because every Faire order is OTP.',
 '',
 'METHOD',
 'LTR = gross sales - item discounts + shipping - shipping tax, net of returns. Shopify only; test '
   'orders and gift cards excluded; founding-order revenue bucket "TT New" (TikTok) excluded.',
 'The $0 founding-order rule removes a 2026-07-09 free-product promotion (936 customers in July).',
 'The Customers column differs between tabs: the After tab adds Faire retailers, who are excluded '
   'from the presentation layer by a channel filter and so appear in neither table.',
 'October 2026 is a partial month and is excluded, so the last month shown varies by cohort.',
 'Client rows are from Cohorts_Dashboard_Complete_Validation_Sheet "Month View", identical on both tabs.',
 '',
 'RESULT',
 'Before: 102 of 198 cells are more than 5% out, worst 51.1%, mean 9.7%.',
 'After: NO cell above 5%, worst 3.6%, mean 0.94% across all 198 cells (1.11% if measured only '
   'at each cohort-s latest month, which is the figure quoted in the RCA document).',
 'The attribution rule was chosen by scoring four variants across all eleven cohorts, not on March alone.',
 '',
 'OPEN',
 'Roughly 115 customers across the non-July cohorts are classified OTP by us and Subscription by the '
   'client. 0.10% of base. No exclusion rule can fix a classification difference.',
 '465 of the 936 July customers removed have a second order. Believed to be a second $0 promotional '
   'item rather than a real purchase. Unconfirmed.',
 'LineItemMaster currently adds refunded shipping on return rows instead of subtracting it - an '
   'upstream sign error raised with the DE team. The After tab is built with that shipping ignored, '
   'which matches the OrderLinesMaster build. When the fix lands, expect March M4 to move about '
   '-425 (OTP) and -1,046 (Subscription).',
 'Nobody has confirmed which model the live dashboard reads, and the published figures these were '
   'originally checked against came from our own brief, not a dashboard read.',
]
ws = wb.create_sheet('Notes')
ws.column_dimensions['A'].width = 130
for i, t in enumerate(NOTES, start=1):
    c = ws.cell(i, 1, t)
    c.font = H1 if i == 1 else (H2 if t.isupper() and t else NOTE)
    c.alignment = Alignment(wrap_text=True, vertical='top')

wb.save(OUT)
print('wrote', OUT)
