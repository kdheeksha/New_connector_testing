/**
 * Builds the "All KPI Sheet Gummies" dashboard tab.
 *
 * Mirrors the structure of "All KPI Sheet Gels":
 *   row 3  TRIPLE WHALE super-banner        row 6  BigQuery column names (HIDDEN)
 *   row 4  section banners (yellow)         row 7+ data
 *   row 5  column headers (dark green)      freeze: 4 cols x 5 rows
 *
 * Reads from the BigQuery extract tab and maps columns by the hidden row 6 names,
 * so column order in the extract does not matter.
 *
 * Run buildGummiesDashboard() from Extensions > Apps Script.
 */

const CFG = {
  EXTRACT : "All_KPIs_Date_Level_Gummies",   // BigQuery extract tab
  TARGET  : "All KPI Sheet Gummies",         // tab this script creates
  HEADER_ROW: 5, MAP_ROW: 6, DATA_ROW: 7, FIRST_COL: 2,
  C: { banner:"#FFDC60", header:"#285234", headerText:"#FFFFFF",
       avg:"#FFDC60", green:"#A5D05A", data:"#FFFFFF", mapRow:"#000000" }
};

// [label, bigquery_column, number_format, width]  — starts at column B
const COLS = [
  ["Day", "", "@", 0],
  ["Date", "date", "M/d/yyyy", 0],
  ["Marketplace", "store_name", "@", 0],
  ["Total Sales", "Total_Sales", "\"$\"#,##0", 0],
  ["Website Sales", "Website_Sales", "\"$\"#,##0", 14],
  ["Amazon Sales", "Amazon_Sales", "\"$\"#,##0", 14],
  ["TikTok Sales", "Tiktok_Sales", "\"$\"#,##0", 13],
  ["Walmart Sales", "Walmart_Sales", "\"$\"#,##0", 15],
  ["Target Sales", "Target_Sales", "\"$\"#,##0", 0],
  ["DSP Sales", "DSP_Sales", "\"$\"#,##0", 11],
  ["NTB Sales Percentage", "NTB_Sales_Perc", "0.0%", 22],
  ["Total Spend", "Total_Spend", "\"$\"#,##0", 0],
  ["Website Spend", "Website_Spend", "\"$\"#,##0", 15],
  ["Website TOF Spend", "Website_TOF_Spend", "\"$\"#,##0", 20],
  ["Website Spend without TOF", "Website_Spend_w_o_TOF", "\"$\"#,##0", 28],
  ["Meta Spend without TOF", "Meta_Spend_w_o_TOF", "\"$\"#,##0", 24],
  ["Meta TOF Spend", "Meta_TOF_Spend", "\"$\"#,##0", 17],
  ["YouTube Spend without TOF", "YouTube_Spend_w_o_TOF", "\"$\"#,##0", 28],
  ["YouTube TOF Spend", "YouTube_TOF_Spend", "\"$\"#,##0", 20],
  ["Google S & S Spend", "Google_S_S_Spend", "\"$\"#,##0", 20],
  ["Google\n(856-088-0398 \u0411\u0410\u0414\u042b (\u041c\u0425\u0418))", "Google_AdSpend", "\"$\"#,##0", 28],
  ["Google Search Spend", "Google_Search_Spend", "\"$\"#,##0", 22],
  ["Google Shopping Spend", "Google_Shopping_Spend", "\"$\"#,##0", 24],
  ["Google Pmax Spend", "Google_Pmax_Spend", "\"$\"#,##0", 20],
  ["Amazon Spend", "Amazon_Spend", "\"$\"#,##0", 16],
  ["TikTok Spend", "TikTok_Spend", "\"$\"#,##0", 14],
  ["TikTok Spend GMV Max", "TikTok_Spend_GMV_Max", "\"$\"#,##0", 24],
  ["TikTok Spend Campaign", "TikTok_Spend_Campaign", "\"$\"#,##0", 24],
  ["TikTok TOF Spend", "TikTok_TOF_Spend", "\"$\"#,##0", 18],
  ["Walmart Spend", "Walmart_Spend", "\"$\"#,##0", 17],
  ["DSP Spend", "DSP_Spend", "\"$\"#,##0", 0],
  ["DTC NCPA", "DTC_NCPA", "\"$\"#,##0", 0],
  ["TOF DTC NCPA", "TOF_DTC_NCPA", "\"$\"#,##0", 16],
  ["Blended CAC", "Blended_CAC", "\"$\"#,##0", 14],
  ["Meta CAC First Touch 7D", "Meta_CAC_First_Touch_7D", "\"$\"#,##0", 25],
  ["Meta CAC Last Touch 7D", "Meta_CAC_Last_Touch_7D", "\"$\"#,##0", 25],
  ["Meta CAC Triple Attribution 7D", "Meta_CAC_Triple_Att_7D", "\"$\"#,##0", 30],
  ["Meta In-App CPA", "Meta_In_App_CPA", "\"$\"#,##0", 17],
  ["Meta NCP First Click", "Meta_NCP_First_Click", "#,##0", 20],
  ["Meta NCP Last Click", "Meta_NCP_Last_Click", "#,##0", 20],
  ["Meta NCP Triple Attribution 7D", "Meta_NCP_Triple_Att_7D", "#,##0", 30],
  ["Meta In-App Purchases", "Meta_In_App_Purchases", "#,##0", 23],
  ["Meta NCP New Orders Shopify Ratio", "Meta_NCP_New_Orders_Shopify_Ratio", "0.0%", 36],
  ["Meta In-App Purchases Orders Shopify Ratio", "Meta_In_App_Purchases_Orders_Shopify_Ratio", "0.0%", 44],
  ["Meta Spend Total Website Spend", "Meta_Spend_Total_Website_Spend", "0.0%", 32],
  ["Meta NCP In-App Purchases Ratio", "Meta_NCP_In_App_Purchases_Ratio", "0.00%", 34],
  ["Google CAC First Touch 7D", "Google_CAC_First_Touch_7D", "\"$\"#,##0", 27],
  ["Google CAC Last Touch 7D", "Google_CAC_Last_Touch_7D", "\"$\"#,##0", 27],
  ["Google CAC Triple Attribution 7D", "Google_CAC_Triple_Att_7D", "\"$\"#,##0", 33],
  ["DG First Touch 7D", "DG_First_Touch_7D", "\"$\"#,##0", 18],
  ["DG Last Touch 7D", "DG_Last_Touch_7D", "\"$\"#,##0", 18],
  ["DG Triple Attribution 7D", "DG_Triple_Att_7D", "\"$\"#,##0", 24],
  ["Prospecting First Touch 7D", "Prospecting_First_Touch_7D", "\"$\"#,##0", 27],
  ["Prospecting Last Touch 7D", "Prospecting_Last_Touch_7D", "\"$\"#,##0", 27],
  ["Prospecting Triple Attribution 7D", "Prospecting_Triple_Att_7D", "\"$\"#,##0", 32],
  ["Brand First Touch 7D", "Brand_First_Touch_7D", "\"$\"#,##0", 21],
  ["Brand Last Touch 7D", "Brand_Last_Touch_7D", "\"$\"#,##0", 21],
  ["Brand Triple Attribution 7D", "Brand_Triple_Att_7D", "\"$\"#,##0", 27],
  ["Website TACOS", "Website_TACOS", "0.0%", 16],
  ["Amazon TACOS", "Amazon_TACOS", "0.0%", 16],
  ["TikTok TACOS", "TikTok_TACOS", "0.0%", 15],
  ["aMER", "aMER", "#,##0.00", 0],
  ["MER", "MER", "#,##0.00", 0],
  ["NTB aMER", "NTB_aMER", "#,##0.00", 0],
  ["SNS NTB Sales", "SNS_NTB_Sales", "\"$\"#,##0", 16],
  ["NON SNS NTB Sales", "NON_SNS_NTB_Sales", "\"$\"#,##0", 20],
  ["SNS NTB Orders", "SNS_NTB_Orders", "#,##0", 17],
  ["NON SNS NTB Orders", "NON_SNS_NTB_Orders", "#,##0", 22],
  ["Total Sales Website", "Total_Sales_Website", "\"$\"#,##0", 20],
  ["First-Time Customer Net Sales", "First_Time_Customer_Net_Sales", "\"$\"#,##0", 30],
  ["First-Time Customer Sales", "First_Time_Customer_Sales", "\"$\"#,##0", 26],
  ["Returning Customer Sales", "Returning_Customer_Sales", "\"$\"#,##0", 26],
  ["Total Customers", "Total_Customers", "#,##0", 17],
  ["First-Time Customers", "First_Time_Customers", "#,##0", 22],
  ["Returning Customers", "Returning_Customers", "#,##0", 22],
  ["New Orders", "New_Orders", "#,##0", 17],
  ["Returning Orders", "Returning_Orders", "#,##0", 20],
  ["Shopify Orders", "Shopify_Orders", "#,##0", 16],
  ["Walmart Orders", "Walmart_Orders", "#,##0", 18],
  ["Amazon Orders", "Amazon_Orders", "#,##0", 16],
  ["TikTok Orders", "TikTok_Orders", "#,##0", 14],
  ["Target Orders", "Target_Orders", "#,##0", 0],
  ["Amazon AOV", "Amazon_AOV", "\"$\"#,##0", 14],
  ["TikTok AOV", "TikTok_AOV", "\"$\"#,##0", 0],
  ["Walmart AOV", "Walmart_AOV", "\"$\"#,##0", 14],
  ["Target AOV", "Target_AOV", "\"$\"#,##0", 0],
  ["N AOV Net Sales", "N_AOV_Net_Sales", "\"$\"#,##0", 17],
  ["N AOV", "N_AOV", "\"$\"#,##0", 11],
  ["R AOV", "R_AOV", "\"$\"#,##0", 11],
  ["ACOS", "ACOS", "0.0%", 0],
  ["TACOS", "TACOS_Website", "0.0%", 14],
  ["Returns", "Returns", "#,##0", 12],
  ["Return Rate Percentage", "Return_Rate_Perc", "0.0%", 24],
  ["MER Website", "MER_Website", "#,##0.00", 14],
  ["CPC", "CPC", "#,##0.00", 5],
  ["Visitors", "Visitors", "#,##0", 8],
  ["Sessions ", "Sessions", "#,##0", 10],
  ["ATC", "ATC", "#,##0", 6],
  ["ATC Percentage", "ATC_Perc", "0.00%", 16],
  ["ATC to PU Percentage", "ATC_to_PU_Perc", "0.00%", 22],
  ["Initiated Check Out", "Initiated_Check_Out", "#,##0", 19],
  ["Completed Checkout ", "Completed_Check_Out", "#,##0", 22],
  ["IC to PU Percentage", "IC_to_PU_Perc", "0.00%", 20],
  ["ATC to IC Percentage", "ATC_to_IC_Perc", "0.00%", 21],
  ["Active Subscribers", "Active_Subscribers", "#,##0", 0],
  ["New Subscribers Recharge", "New_Subscribers_Recharge", "#,##0", 27],
  ["Churned Subscribers", "Churned_Subscribers", "#,##0", 21],
  ["Reactivated Subscribers", "Reactivated_Subscribers", "#,##0", 24],
  ["Net Gain Loss", "Net_Gain_Loss", "#,##0", 14],
  ["Average Subscriptions per Active Subscriber", "Avg_Subscriptions_per_Active_Subscriber", "#,##0", 44],
  ["Average Orders per Active Subscriber", "Avg_Orders_per_Active_Subscriber", "#,##0", 37],
  ["Average Active Days per Subscriber", "Avg_Active_Days_per_Subscriber", "#,##0", 36],
  ["Discount per Order", "Discount_Per_Order", "\"$\"#,##0.00", 19],
  ["Return Amount per Order", "Return_Amount_Per_Order", "\"$\"#,##0.00", 25],
  ["Shipping Charge per Order", "Shipping_Charge_Per_Order", "\"$\"#,##0.00", 27],
  ["Tax per Order", "Tax_Per_Order", "\"$\"#,##0.00", 14]
];

// [banner text, start col, end col]
const SECTIONS = [
  ["SALES", 5, 12],
  ["SPEND", 13, 35],
  ["TRIPLE WHALE", 36, 50],
  ["DEMAND GEN", 51, 53],
  ["S&S | PROSPECTING", 54, 56],
  ["S&S | BRAND", 57, 59],
  ["TACOS", 60, 65],
  ["AMAZON", 66, 69],
  ["CUSTOMERS", 70, 76],
  ["ORDERS", 77, 83],
  ["AOV", 84, 87],
  ["WEBSITE", 88, 105],
  ["SUBSCRIPTION - RECHARGE", 106, 113],
  ["RELATIVE METRICS", 114, 117]
];

function buildGummiesDashboard() {
  const ss = SpreadsheetApp.getActive();
  const src = ss.getSheetByName(CFG.EXTRACT);
  if (!src) throw new Error('Extract tab not found: "' + CFG.EXTRACT + '"');

  // --- read extract: row1 = title, row2 = headers, row3+ = data ---
  const raw  = src.getDataRange().getValues();
  if (raw.length < 3) throw new Error("Extract has no data rows yet.");
  const srcHead = raw[1].map(h => String(h).trim());
  const srcRows = raw.slice(2).filter(r => String(r[0]).trim() !== "");
  const idx = {};
  srcHead.forEach((h, i) => { if (h) idx[h] = i; });

  // --- recreate target tab ---
  const old = ss.getSheetByName(CFG.TARGET);
  if (old) ss.deleteSheet(old);
  const sh = ss.insertSheet(CFG.TARGET, ss.getNumSheets());

  const nCols = COLS.length, lastCol = CFG.FIRST_COL + nCols - 1;
  const nRows = srcRows.length, lastRow = CFG.DATA_ROW + nRows - 1;
  if (sh.getMaxColumns() < lastCol) sh.insertColumnsAfter(sh.getMaxColumns(), lastCol - sh.getMaxColumns());
  if (sh.getMaxRows()    < lastRow) sh.insertRowsAfter(sh.getMaxRows(), lastRow - sh.getMaxRows());

  // --- row 5 headers + row 6 map ---
  sh.getRange(CFG.HEADER_ROW, CFG.FIRST_COL, 1, nCols).setValues([COLS.map(c => c[0])]);
  sh.getRange(CFG.MAP_ROW,    CFG.FIRST_COL, 1, nCols).setValues([COLS.map(c => c[1])]);

  // --- section banners (row 4) + Triple Whale super-banner (row 3) ---
  SECTIONS.forEach(s => {
    const r = sh.getRange(4, s[1], 1, s[2] - s[1] + 1);
    r.merge().setValue(s[0]).setBackground(CFG.C.banner)
     .setFontWeight("bold").setFontSize(14)
     .setHorizontalAlignment("center").setVerticalAlignment("middle");
  });
  sh.getRange(3, 36, 1, 24).merge().setValue("TRIPLE WHALE").setBackground(CFG.C.banner)
    .setFontWeight("bold").setFontSize(14)
    .setHorizontalAlignment("center").setVerticalAlignment("middle");

  // --- build data block, mapped by row-6 names ---
  const out = srcRows.map(row => COLS.map(c => {
    if (!c[1]) return "";                              // column B (Day) = formula, filled below
    const i = idx[c[1]];
    if (i === undefined) return "";                    // column missing from extract
    let v = row[i];
    if (c[1] === "date") {                             // "L7 AVG" stays text, real dates become dates
      const str = String(v).trim();
      return /^\d{4}-\d{2}-\d{2}$/.test(str) ? new Date(str + "T00:00:00") : str;
    }
    return (v === null || v === "") ? "" : v;
  }));
  if (nRows) sh.getRange(CFG.DATA_ROW, CFG.FIRST_COL, nRows, nCols).setValues(out);

  // --- column B: day-of-week (passes "L7 AVG" etc. straight through) ---
  if (nRows) {
    sh.getRange(CFG.DATA_ROW, 2, nRows, 1).setFormulas(
      Array.from({length: nRows}, (_, k) =>
        ['=IF(C' + (CFG.DATA_ROW + k) + '="","",IFERROR(TEXT(C' + (CFG.DATA_ROW + k) + ',"dddd"),C' + (CFG.DATA_ROW + k) + '))']));
  }

  // --- header styling ---
  sh.getRange(CFG.HEADER_ROW, CFG.FIRST_COL, 1, nCols)
    .setBackground(CFG.C.header).setFontColor(CFG.C.headerText)
    .setFontWeight("bold").setFontSize(12)
    .setHorizontalAlignment("center").setVerticalAlignment("middle").setWrap(true);
  sh.getRange(CFG.MAP_ROW, CFG.FIRST_COL, 1, nCols)
    .setBackground(CFG.C.mapRow).setFontColor(CFG.C.mapRow).setNumberFormat("@");

  // --- number formats + widths, per column ---
  COLS.forEach((c, k) => {
    const col = CFG.FIRST_COL + k;
    if (nRows) sh.getRange(CFG.DATA_ROW, col, nRows, 1).setNumberFormat(c[2]);
    sh.setColumnWidth(col, c[3] > 0 ? Math.round(c[3] * 7) : 110);
  });

  // --- row colours: AVG rows yellow, date rows green ---
  if (nRows) {
    const bB = [], bD = [];
    srcRows.forEach(r => {
      const isAvg = String(r[0]).indexOf("AVG") > -1;
      bB.push([isAvg ? CFG.C.avg : CFG.C.green, isAvg ? CFG.C.avg : CFG.C.green]);
      bD.push([CFG.C.green]);
    });
    sh.getRange(CFG.DATA_ROW, 2, nRows, 2).setBackgrounds(bB);   // B:C
    sh.getRange(CFG.DATA_ROW, 4, nRows, 1).setBackgrounds(bD);   // D
    sh.getRange(CFG.DATA_ROW, 5, nRows, nCols - 3).setBackground(CFG.C.data);
    sh.getRange(CFG.DATA_ROW, 2, nRows, 3).setFontWeight("bold");
  }

  // --- borders, alignment, freeze, sizes ---
  sh.getRange(CFG.HEADER_ROW, CFG.FIRST_COL, nRows + 2, nCols)
    .setBorder(true, true, true, true, true, true, "#000000", SpreadsheetApp.BorderStyle.SOLID)
    .setHorizontalAlignment("center");
  sh.setFrozenRows(CFG.HEADER_ROW);
  sh.setFrozenColumns(4);
  sh.hideRows(CFG.MAP_ROW);
  [2, 3, 4].forEach(r => sh.setRowHeight(r, 35));
  sh.setRowHeight(CFG.HEADER_ROW, 45);
  sh.setColumnWidth(1, 30);

  SpreadsheetApp.getActive().toast(nRows + " rows written to " + CFG.TARGET, "Done", 8);
}

/** Re-pull data only, leaving all formatting intact. */
function refreshGummiesData() { buildGummiesDashboard(); }
