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
          eyebrow: "TRUESEAMOSS  ·  FLAVOUR LAUNCH ANALYSIS",
          title: "Do new flavour launches grow the business?",
          dek: "Three gel launches measured at 30, 60 and 90 days — and tested for whether the revenue was real",
          meta: [
            ["Scope", "Shopify, United States. Data through 10 September 2026."],
            ["Launches", "Cranberry (9 Dec 2025), Peach/Pear (20 Mar 2026), Raspberry/Watermelon (15 Jun 2026)."],
          ],
        }),

        // ---------- Bottom line ----------
        h1("Bottom line"),
        bullet(
          "Launches grow the business. 80% to 93% of launch revenue came from customers who had never bought " +
          "before. Across the three launches that is 41,284 new customers and $1.74m in the first 90 days."
        ),
        bullet(
          "Nothing was cannibalised. Redistribution measured $0 on all three launches. Existing customers who " +
          "adopted a new flavour spent more in total, not the same money moved sideways."
        ),
        bullet(
          "Launches pay for themselves within 60 days, returning 1.55 to 1.91 times the cost of acquiring a " +
          "customer that month. On revenue, not margin."
        ),
        bullet(
          "Which flavour you launch barely matters. Value per customer varies 4% across the three launches. " +
          "Customer volume varies 620%. Reach is the lever, not flavour selection."
        ),

        // ---------- What this does ----------
        h1("What this report does"),
        para(
          "Each launch is indexed to its own day zero and measured at 30, 60 and 90 days, so a December launch " +
          "can be compared with a June one without winning on age alone. Revenue is then split by whether the " +
          "buyer existed before the launch, and the pre-existing portion is tested against a control group of " +
          "customers who were equally active but did not buy the new flavour."
        ),

        // ---------- 30/60/90 ----------
        h1("1.  The launches at 30, 60 and 90 days"),
        table(
          [2260, 1300, 1300, 1400, 1250, 1850],
          ["Launch", "T+30", "T+60", "T+90", "Growth 30→90", "New customers T+90"],
          [
            ["Cranberry", "$46,183", "$62,882", "$134,069", "2.9×", "2,771"],
            ["Peach/Pear", "$91,447", "$225,689", "$498,234", "5.4×", "12,732"],
            ["Raspberry/Watermelon", "$260,113", "$665,700", "$1,110,054", "4.3×", "25,781"],
          ]
        ),
        caption("Cumulative gross sales. Raspberry/Watermelon's T+90 covers 88 of 90 days, as data ends 10 September."),
        bullet(
          "Raspberry/Watermelon is the benchmark: 8.3× Cranberry and 2.2× Peach/Pear at the same age, and it got " +
          "there three months faster."
        ),
        bullet(
          "Order value and customer quality are identical across all three — AOV $26.57 to $26.87, repeat purchase " +
          "within 60 days 68.3% to 70.9%. The launches differ only in how many customers they reached."
        ),

        // ---------- Where revenue came from ----------
        h1("2.  Where the revenue came from"),
        table(
          [2260, 1500, 1700, 1200, 1500, 1200],
          ["Launch", "Gross (60d)", "New customers", "Share", "Pre-existing", "Share"],
          [
            ["Cranberry", "$62,882", "$50,029", "79.6%", "$12,853", "20.4%"],
            ["Peach/Pear", "$225,690", "$188,531", "83.5%", "$37,158", "16.5%"],
            ["Raspberry/Watermelon", "$665,700", "$619,892", "93.1%", "$45,807", "6.9%"],
          ]
        ),
        para(
          "New customers dominate, and increasingly so — the newest launch drew 93% of its revenue from people " +
          "who had never bought before. Only the small pre-existing slice, 7% to 20%, could possibly be " +
          "redistributed demand. That is what the next section tests."
        ),

        // ---------- Incrementality ----------
        h1("3.  Was the pre-existing slice incremental?"),
        para(
          "Adopters are compared against customers who ordered in the same window but did not buy the new flavour, " +
          "matched on prior spend. Because people who buy any flavour are more engaged than those who do not, the " +
          "same test was run on three established flavours to measure that bias: it is worth $9.68 per customer, " +
          "and is subtracted below."
        ),
        table(
          [2260, 1150, 1250, 1350, 1500, 1850],
          ["Launch", "Adopters", "Raw lift", "Adjusted lift", "Adjusted total", "Redistributed"],
          [
            ["Cranberry", "362", "+$57.95", "+$48.28", "$17,476", "$0"],
            ["Peach/Pear", "927", "+$53.29", "+$43.61", "$40,426", "$0"],
            ["Raspberry/Watermelon", "1,233", "+$51.92", "+$42.25", "$52,091", "$0"],
          ]
        ),
        caption("Lift is extra spend per adopter over 60 days versus the control. Placebo baseline of $9.68 already removed."),
        para(
          "In every case the adjusted lift is larger than what those customers spent on the new flavour itself — " +
          "$52,091 against $45,807 on Raspberry/Watermelon, for example. They did not swap spend across from other " +
          "flavours; they added the new one and spent more besides. A new flavour re-engages the existing base as " +
          "well as recruiting a new one."
        ),

        // ---------- Payback ----------
        h1("4.  Do launches pay back?"),
        para(
          "What each acquired customer went on to spend in 60 days, against what it cost to acquire a customer " +
          "that month. Windows are equalised — acquired in the first 28 days, each observed 60 days — because " +
          "Raspberry/Watermelon is recent enough that unequal windows would understate it badly."
        ),
        table(
          [2260, 1300, 1400, 1300, 1200, 1250, 1250],
          ["Launch", "Acquired", "Rev / customer", "2nd order", "CAC", "× CAC", "× NCPA"],
          [
            ["Cranberry", "1,187", "$108.83", "67.7%", "$57.22", "1.90×", "1.24×"],
            ["Peach/Pear", "2,391", "$104.67", "70.7%", "$67.66", "1.55×", "1.11×"],
            ["Raspberry/Watermelon", "8,586", "$104.87", "68.1%", "$55.03", "1.91×", "1.39×"],
          ]
        ),
        caption("CAC period-matched to each launch month, from All_KPIs_Monthly_Performance (Gels, US)."),
        para(
          "All three clear blended acquisition cost inside 60 days. Against the stricter cost per new paid customer " +
          "the margin narrows to 1.11–1.39×. These are revenue figures, so profit payback runs longer and cannot be " +
          "settled until Version 2 COGS lands."
        ),

        // ---------- Conclusions ----------
        h1("5.  Conclusions"),
        h2("Launches work, and they are repeatable"),
        para(
          "Three launches, three different quarters, three different flavours — and near-identical unit economics: " +
          "$104.67 to $108.83 revenue per customer, 67.7% to 70.7% second-order rate, $26.57 to $26.87 AOV. " +
          "This is a channel with predictable returns, not a series of individual bets."
        ),
        h2("Reach is the only lever that moved"),
        para(
          "Value per acquired customer varied by 4% across the three launches. Customer volume varied by 620% — " +
          "8,586 against 1,187 on equalised windows. Raspberry/Watermelon delivered $975,985 more than Cranberry " +
          "at T+90 running the same playbook. The variable was how many people the launch reached, not which " +
          "flavour was in the jar."
        ),
        h2("Cannibalisation is not a real risk here"),
        para(
          "Zero redistribution across three launches. Portfolio-conflict concerns should not gate launch decisions, " +
          "and the existing range does not need protecting from new flavours."
        ),
        h2("What to do"),
        bullet(
          "Budget launches as acquisition, not merchandising. Target new-to-brand customers and cost per " +
          "acquisition; stop debating share shift between flavours."
        ),
        bullet(
          "Spend the planning effort on launch reach and media weight rather than flavour selection — that is " +
          "where the 620% sits."
        ),
        bullet(
          "Grade the next launch against Raspberry/Watermelon: $260,113 at T+30, $665,700 at T+60, $1.11m at T+90."
        ),
        bullet(
          "Revisit payback when Version 2 COGS arrives. At 1.11–1.39× NCPA on revenue, the profit answer is not yet certain."
        ),

        // ---------- Caveats ----------
        h1("Caveats"),
        bullet(
          "Revenue-based throughout. Margin KPIs are Version 2, pending COGS from 1C and Y-sell."
        ),
        bullet(
          "Launch dates come from first sale, validated against Shopify's published_at. Cranberry matches exactly; " +
          "Peach/Pear is one day out; Raspberry/Watermelon was live four days before its first order."
        ),
        bullet(
          "Difference-in-differences shows association, not causation. The placebo strengthens it but this is not " +
          "a controlled experiment."
        ),
        bullet(
          "Cranberry's 362 adopters is a small base — treat its per-customer figures as indicative."
        ),
        bullet(
          "Shopify and United States only. The August 2026 Sparkling Drink launch is excluded as it sells on " +
          "TikTok and Amazon only."
        ),
      ],
    },
  ],
});

Packer.toBuffer(doc).then((buf) => {
  fs.writeFileSync("/home/user/New_connector_testing/analysis/TrueSeaMoss_Flavour_Launch_Analysis.docx", buf);
  console.log("written");
});
