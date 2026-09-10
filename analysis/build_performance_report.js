const fs = require("fs");
const { Document, Packer } = require("docx");
const K = require("./docx_kit");
const { para, h1, h2, bullet, caption, table, numbering, pageProps, titleBlock } = K;

const doc = new Document({
  numbering,
  sections: [
    {
      properties: pageProps,
      children: [
        ...titleBlock({
          eyebrow: "TRUESEAMOSS  ·  RECENT GEL LAUNCHES",
          title: "How the recent gel launches are trading",
          dek: "Volume, order value, subscription mix and customer mix since launch",
          meta: [
            ["Scope", "Shopify, United States. Data through 10 September 2026."],
            ["Subject", "Gel Raspberry/Watermelon, launched 15 June 2026 — the only recent gel launch on Shopify."],
            ["Benchmarks", "Gel Peach/Pear (20 Mar 2026) and Gel Cranberry (9 Dec 2025), the two previous gel launches."],
            ["Source", "daton-project · sku_cohort_base."],
          ],
        }),

        h1("Which launches this covers"),
        para(
          "Only one of these three flavours is genuinely new. Raspberry/Watermelon is 87 days old at the time of " +
          "writing. Peach/Pear is approaching six months and Cranberry is nine months old — both are established " +
          "products rather than launches, and they appear here because a single launch cannot be judged in isolation. " +
          "They provide the comparison that makes Raspberry/Watermelon's numbers meaningful."
        ),
        table(
          [2600, 1800, 1300, 2000, 1660],
          ["Flavour", "Launched", "Age", "Role in this report", "Gross to date"],
          [
            ["Raspberry/Watermelon", "15 Jun 2026", "87 days", "Subject", "$1,110,054"],
            ["Peach/Pear", "20 Mar 2026", "174 days", "Benchmark", "$1,650,115"],
            ["Cranberry", "9 Dec 2025", "275 days", "Benchmark", "$481,856"],
          ]
        ),
        para(
          "No gel flavour has launched on Shopify since 15 June 2026. The only other Shopify first-sales in the past " +
          "twelve months are immaterial — a Gift Bergamot at $335 and a Gummies Ashwagandha at $3,605. The genuinely " +
          "newest products in the business are the Sparkling Drink flavours launched 14–15 August 2026, but those sell " +
          "on TikTok and Amazon only and have no Shopify presence, so they fall outside this report's scope."
        ),

        h1("At a glance"),
        para(
          "Life-to-date performance. Because the three flavours launched in different quarters, these totals are not " +
          "a ranking — Peach/Pear leads on revenue largely because it has been selling three months longer than " +
          "Raspberry/Watermelon. The like-for-like comparison follows in the next section."
        ),
        table(
          [2160, 1180, 1240, 1400, 900, 900, 800, 780],
          ["Flavour", "Orders", "Customers", "Gross", "AOV", "Units/ord", "Disc %", "Ret %"],
          [
            ["Cranberry", "18,133", "8,225", "$481,856", "$26.57", "1.04", "42.3%", "6.0%"],
            ["Peach/Pear", "61,167", "35,493", "$1,650,115", "$26.98", "1.03", "37.3%", "5.4%"],
            ["Raspberry/Watermelon", "41,316", "28,029", "$1,110,054", "$26.87", "1.03", "35.1%", "5.8%"],
          ]
        ),

        h2("Like-for-like: first 60 days of each launch"),
        para(
          "Held to the same 60-day window, the ranking inverts. Raspberry/Watermelon sold three times what " +
          "Peach/Pear did and more than ten times Cranberry over the equivalent period."
        ),
        table(
          [2160, 1180, 1240, 1400, 900, 900, 800, 780],
          ["Flavour", "Orders", "Customers", "Gross", "AOV", "Units/ord", "Disc %", "Ret %"],
          [
            ["Cranberry", "2,333", "1,797", "$62,882", "$26.95", "1.06", "43.4%", "7.7%"],
            ["Peach/Pear", "8,317", "6,186", "$225,690", "$27.14", "1.04", "43.9%", "3.0%"],
            ["Raspberry/Watermelon", "24,929", "18,951", "$665,700", "$26.70", "1.02", "35.3%", "4.3%"],
          ]
        ),
        para(
          "Order value is remarkably stable. Every flavour sits between $26.57 and $27.14, at almost exactly one " +
          "unit per order, on both views. New flavours are neither commanding a premium nor being bought in larger " +
          "quantities — they simply substitute into the same single-jar order shape the category already has."
        ),

        h1("Momentum"),
        para(
          "The three flavours are at different points in their life, and only one of them is fading."
        ),
        table(
          [1500, 1300, 1400, 1300, 1400, 1230, 1230],
          ["Month", "Cranberry orders", "Gross", "Peach/Pear orders", "Gross", "R/W orders", "Gross"],
          [
            ["2025-12", "1,042", "$31,051", "—", "—", "—", "—"],
            ["2026-01", "785", "$18,286", "—", "—", "—", "—"],
            ["2026-02", "2,481", "$64,787", "—", "—", "—", "—"],
            ["2026-03", "2,671", "$69,187", "1,368", "$38,867", "—", "—"],
            ["2026-04", "2,507", "$64,154", "3,515", "$93,531", "—", "—"],
            ["2026-05", "3,072", "$80,262", "8,188", "$217,948", "—", "—"],
            ["2026-06", "2,655", "$68,976", "11,151", "$293,408", "4,440", "$116,028"],
            ["2026-07", "1,704", "$45,546", "14,653", "$391,035", "13,024", "$345,054"],
            ["2026-08", "1,154", "$31,650", "16,729", "$452,295", "17,593", "$474,964"],
            ["2026-09 *", "298", "$7,956", "5,970", "$163,031", "6,467", "$174,008"],
          ]
        ),
        caption("* September covers 1–10 September only, roughly one third of the month."),
        bullet(
          "Cranberry peaked in May 2026 at $80,262 and has fallen every month since — August was $31,650, " +
          "under 40% of peak. It is in clear decline and warrants a decision on whether to support or retire it."
        ),
        bullet(
          "Peach/Pear is still climbing five months in, reaching $452,295 in August with no sign of a plateau."
        ),
        bullet(
          "Raspberry/Watermelon overtook Peach/Pear in August ($474,964 against $452,295) despite launching three " +
          "months later, and the first ten days of September keep it ahead. It is the fastest-scaling launch of the three."
        ),

        h1("One-time purchase versus subscription"),
        para(
          "This is the most pronounced pattern in the data. New flavours are sold almost entirely into " +
          "subscriptions, and the share rises with each successive launch."
        ),
        table(
          [2160, 1500, 1100, 1300, 1400, 900, 1000],
          ["Flavour", "Order type", "Orders", "Customers", "Gross", "AOV", "% gross"],
          [
            ["Cranberry", "Subscription", "17,636", "7,901", "$471,142", "$26.71", "97.8%"],
            ["", "One-time", "1,826", "1,531", "$10,714", "$5.87", "2.2%"],
            ["Peach/Pear", "Subscription", "59,255", "34,595", "$1,623,203", "$27.39", "98.4%"],
            ["", "One-time", "4,976", "4,453", "$26,913", "$5.41", "1.6%"],
            ["Raspberry/Watermelon", "Subscription", "40,409", "27,520", "$1,101,421", "$27.26", "99.2%"],
            ["", "One-time", "2,859", "2,714", "$8,633", "$3.02", "0.8%"],
          ]
        ),
        para(
          "Subscription accounts for 97.8% to 99.2% of launch revenue, and the newest flavour is the most " +
          "subscription-weighted of the three. One-time purchase is, in revenue terms, close to irrelevant to a " +
          "new flavour launch."
        ),
        h2("The one-time AOV needs checking"),
        para(
          "One-time orders average between $3.02 and $5.87, against roughly $27 on subscription — a fifth to an " +
          "eighth of the subscription order value, on what should be the same jar of gel. That gap is too large to " +
          "be a pricing difference."
        ),
        para(
          "The likely explanations are that one-time volume is predominantly samples, single-serve sachets or " +
          "gift-with-purchase items rather than retail jars, or that promotional and add-on lines are being " +
          "classified as one-time orders. Either way it is worth confirming in Shopify before this split is " +
          "reported externally, because as it stands the one-time figures do not describe a normal retail purchase."
        ),

        h1("Who is buying"),
        para(
          "Split by whether the customer existed before the flavour launched."
        ),
        table(
          [2160, 2000, 1300, 1200, 1500, 1200],
          ["Flavour", "Segment", "Customers", "Orders", "Gross", "AOV"],
          [
            ["Cranberry", "Acquired at/after launch", "6,988", "15,327", "$406,468", "$26.52"],
            ["", "Pre-existing customer", "1,237", "2,806", "$75,387", "$26.87"],
            ["Peach/Pear", "Acquired at/after launch", "33,619", "57,480", "$1,548,232", "$26.94"],
            ["", "Pre-existing customer", "1,874", "3,687", "$101,883", "$27.63"],
            ["Raspberry/Watermelon", "Acquired at/after launch", "26,375", "38,880", "$1,041,506", "$26.79"],
            ["", "Pre-existing customer", "1,654", "2,436", "$68,549", "$28.14"],
          ]
        ),
        bullet(
          "Newly acquired customers dominate every launch, supplying 84% to 94% of revenue. Pre-existing " +
          "customer counts are strikingly flat across all three at roughly 1,200 to 1,900, regardless of launch size."
        ),
        bullet(
          "Pre-existing customers spend slightly more per order in every case, and the gap widens with each launch " +
          "— $28.14 against $26.79 on Raspberry/Watermelon."
        ),

        h1("Discounting and returns"),
        para(
          "Discount runs between 35.1% and 42.3% of gross sales across the three flavours — high in absolute terms, " +
          "and consistent with a subscription model where the subscribe-and-save rate is the standard price rather " +
          "than a promotion. It is nonetheless the largest single deduction in the launch P&L and should be read as " +
          "a structural feature, not a launch tactic."
        ),
        para(
          "The trend is favourable: discount rate falls with each successive launch, from 43.4% on Cranberry's " +
          "first 60 days to 35.3% on Raspberry/Watermelon's. The newest and largest launch is also the least " +
          "discounted, which suggests the scale is not being bought with price."
        ),
        para(
          "Returns sit between 5.4% and 6.0% life-to-date. Cranberry's first 60 days ran hottest at 7.7%, against " +
          "3.0% for Peach/Pear and 4.3% for Raspberry/Watermelon over the same stage."
        ),

        h1("What to take from this"),
        bullet(
          "Raspberry/Watermelon is the strongest launch on every like-for-like measure: most volume, lowest " +
          "discount rate, highest subscription share, and it overtook a flavour with a three-month head start."
        ),
        bullet(
          "Cranberry needs a decision. Nine months in, it is down to under 40% of its peak month and is the most " +
          "heavily discounted and most returned of the three."
        ),
        bullet(
          "Order value is not a lever. AOV and units per order are effectively constant across flavours and time, " +
          "so launch outcomes are driven by order volume alone."
        ),
        bullet(
          "Launches are a subscription acquisition mechanism. With 98–99% of revenue subscription-borne, a new " +
          "flavour should be planned as a subscription recruitment and retention play, not as a trial or impulse product."
        ),
        bullet(
          "Confirm the one-time purchase classification in Shopify before this split is shared outside the team."
        ),

        h1("Notes"),
        bullet(
          "Launch dates are measured from first observed sale and validated against Shopify's published_at field. " +
          "Cranberry matches exactly; Peach/Pear was published one day before its first sale; Raspberry/Watermelon " +
          "was published 11 June 2026 and sat live for four days before its first order."
        ),
        bullet(
          "Cranberry's figures begin in December 2025 and Peach/Pear's in March 2026 because those are their launch " +
          "months. Only Raspberry/Watermelon is a recent launch; the other two are included as benchmarks."
        ),
        bullet(
          "September 2026 figures cover 1–10 September only and are not comparable to full months."
        ),
        bullet(
          "All figures are Shopify, United States, and revenue-based. Margin is not available until COGS arrives " +
          "with the Version 2 contribution-margin work."
        ),
        bullet(
          "Discount rate is item discount as a share of gross sales; return rate is refunds attributed to the " +
          "return date, per the agreed KPI definitions."
        ),
      ],
    },
  ],
});

Packer.toBuffer(doc).then((buf) => {
  fs.writeFileSync("/home/user/New_connector_testing/analysis/TrueSeaMoss_New_Launch_Performance.docx", buf);
  console.log("written");
});
