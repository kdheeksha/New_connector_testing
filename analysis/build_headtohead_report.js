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
          eyebrow: "TRUESEAMOSS  ·  FLAVOUR HEAD-TO-HEAD",
          title: "Gel against electrolyte, flavour by flavour",
          dek: "Which SKUs are performing, and how differently the two formats sell",
          meta: [
            ["Scope", "Shopify, United States. Data through 10 September 2026."],
            ["Gels", "Raspberry/Watermelon (15 Jun 2026) and Peach/Pear (20 Mar 2026) — the two newest gel flavours."],
            ["Electrolytes", "Mango/Pineapple, Melon/Watermelon, Banana/Strawberry and Lemon/Lime — all launched 4 Jul 2025."],
            ["Source", "daton-project · sku_cohort_base."],
          ],
        }),

        h1("A note on what could and could not be compared"),
        para(
          "The intent was to set new gel flavours against new electrolyte flavours. That comparison cannot be made, " +
          "because there is no new electrolyte flavour. All four electrolyte flavours were published to the Shopify " +
          "storefront on the same day, 19 June 2025, as a single category launch. Nothing has launched in " +
          "electrolytes in the fourteen months since."
        ),
        para(
          "This is a genuine launch rather than an artefact of the data — Shopify history in this model runs back to " +
          "September 2022, and electrolytes ramp from zero. It is worth noting that the four flavours were live for " +
          "fifteen days before recording a single sale, first selling on 4 July 2025. Every window in this report is " +
          "measured from first sale rather than publish date, so it captures trading life rather than shelf life."
        ),
        para(
          "So the comparison here is between the two newest gel flavours and the four established electrolyte " +
          "flavours, measured two ways. The first holds every flavour to the first 87 days of its own life, so a " +
          "2025 launch can be judged against a 2026 launch without winning simply by being older. The second is " +
          "current trading, which is what the ranking looks like in the P&L today."
        ),

        h1("1.  At equal age — the first 87 days of each flavour"),
        table(
          [2360, 1080, 1180, 1300, 860, 1000, 900, 680],
          ["Flavour", "Orders", "Customers", "Gross", "AOV", "Sub custs", "OTP custs", "Sub %"],
          [
            ["Gel · Raspberry/Watermelon", "41,306", "28,027", "$1,109,751", "$26.87", "27,518", "2,708", "99.2%"],
            ["Gel · Peach/Pear", "17,621", "13,518", "$468,501", "$26.59", "12,927", "1,384", "93.4%"],
            ["Elec · Mango/Pineapple", "7,098", "4,867", "$187,873", "$26.47", "4,070", "1,376", "78.4%"],
            ["Elec · Melon/Watermelon", "5,323", "3,742", "$131,325", "$24.67", "3,257", "813", "81.8%"],
            ["Elec · Banana/Strawberry", "3,220", "2,229", "$78,687", "$24.44", "1,942", "504", "80.3%"],
            ["Elec · Lemon/Lime", "2,755", "1,889", "$66,650", "$24.19", "1,639", "434", "80.7%"],
          ]
        ),
        caption("Sub % is subscription revenue as a share of that flavour's gross over the same 87-day window."),
        para(
          "Gel launches outperform electrolyte launches by a wide margin. Over the equivalent first 87 days, " +
          "Raspberry/Watermelon sold 5.9 times what the strongest electrolyte flavour managed, and even Peach/Pear " +
          "— the weaker of the two gels — sold 2.5 times as much. The gap is in order volume, not basket size."
        ),

        h1("2.  Trading now — August 2026"),
        table(
          [2360, 1080, 1180, 1300, 860, 1000, 900, 680],
          ["Flavour", "Orders", "Customers", "Gross", "AOV", "Sub custs", "OTP custs", "Ret %"],
          [
            ["Gel · Raspberry/Watermelon", "17,593", "17,322", "$474,964", "$27.00", "17,065", "1,462", "7.4%"],
            ["Gel · Peach/Pear", "16,729", "16,394", "$452,295", "$27.04", "16,150", "1,408", "7.5%"],
            ["Elec · Mango/Pineapple", "9,151", "9,014", "$236,782", "$25.87", "8,442", "1,031", "5.0%"],
            ["Elec · Melon/Watermelon", "5,573", "5,477", "$136,355", "$24.47", "5,271", "470", "4.6%"],
            ["Elec · Banana/Strawberry", "3,415", "3,359", "$82,456", "$24.15", "3,222", "285", "4.9%"],
            ["Elec · Lemon/Lime", "2,139", "2,102", "$51,485", "$24.07", "2,004", "204", "4.9%"],
          ]
        ),
        bullet(
          "The two newest gel flavours between them turned over $927,259 in August, against $507,078 from all four " +
          "electrolyte flavours combined. Two gel SKUs are outselling the entire electrolyte range by 1.8 to one."
        ),
        bullet(
          "Raspberry/Watermelon leads on every volume measure, though Peach/Pear is close behind — $474,964 against " +
          "$452,295 — despite Raspberry/Watermelon having launched three months later."
        ),
        bullet(
          "Mango/Pineapple is the clear leader within electrolytes at $236,782, roughly as much as the other three " +
          "electrolyte flavours put together."
        ),
        bullet(
          "Gels return at noticeably higher rates: 7.4% and 7.5%, against 4.6% to 5.0% across electrolytes. Roughly " +
          "one and a half times the return rate, consistently, and worth understanding."
        ),

        h1("3.  One-time versus subscription — the formats behave differently"),
        para(
          "This is the sharpest structural difference between the two formats, and it is not a small one."
        ),
        table(
          [2360, 1180, 1300, 1000, 1180, 1300, 1040],
          ["Flavour", "Sub orders", "Sub gross", "Sub AOV", "OTP orders", "OTP gross", "OTP AOV"],
          [
            ["Gel · Raspberry/Watermelon", "40,407", "$1,101,375", "$27.26", "2,851", "$8,377", "$2.94"],
            ["Gel · Peach/Pear", "16,622", "$437,596", "$26.33", "1,526", "$30,906", "$20.25"],
            ["Elec · Mango/Pineapple", "5,972", "$147,211", "$24.65", "1,480", "$40,662", "$27.47"],
            ["Elec · Melon/Watermelon", "4,589", "$107,384", "$23.40", "886", "$23,941", "$27.02"],
            ["Elec · Banana/Strawberry", "2,744", "$63,199", "$23.03", "573", "$15,487", "$27.03"],
            ["Elec · Lemon/Lime", "2,353", "$53,772", "$22.85", "486", "$12,878", "$26.50"],
          ]
        ),
        caption("First 87 days of each flavour's own life."),
        h2("Electrolytes recruit genuine one-time buyers; gels do not"),
        para(
          "Across all four electrolyte flavours, one-time orders average between $26.50 and $27.47 — at or slightly " +
          "above their own subscription order value. These are full-price retail purchases by people choosing to buy " +
          "once. One-time purchase accounts for around a fifth of electrolyte launch revenue."
        ),
        para(
          "Gels behave differently. Subscription takes 93% to 99% of gel launch revenue, and one-time purchase is " +
          "marginal. The two formats are effectively being sold through different mechanisms: electrolytes support " +
          "a real trial-and-repeat path, gels are almost entirely a subscription product."
        ),
        h2("The Raspberry/Watermelon one-time figure is an anomaly, not a pattern"),
        para(
          "Raspberry/Watermelon's one-time orders average $2.94, against $20.25 for the other new gel and roughly " +
          "$27 for every electrolyte flavour. Because the electrolyte flavours show healthy, full-price one-time " +
          "orders, this cannot be explained by how the business classifies one-time purchases in general."
        ),
        para(
          "It is specific to this flavour and almost certainly means its one-time volume is samples, single-serve " +
          "units or gift-with-purchase rather than jars — 2,851 orders producing $8,377. This should be confirmed " +
          "in Shopify before Raspberry/Watermelon's one-time numbers are quoted anywhere."
        ),

        h1("4.  Which SKU is performing better"),
        h2("Best overall: Gel Raspberry/Watermelon"),
        para(
          "It leads on orders, customers and revenue on both the equal-age and current-trading views, carries the " +
          "highest order value of the six at $27.00, and reached that position three months faster than Peach/Pear. " +
          "Its only weak spot is a 7.4% return rate."
        ),
        h2("Best electrolyte: Mango/Pineapple"),
        para(
          "At $236,782 in August it is worth about as much as the other three electrolyte flavours combined, and it " +
          "carries the highest electrolyte order value at $25.87. It is also the only electrolyte flavour with " +
          "meaningful one-time volume, at 1,031 one-time customers in the month."
        ),
        h2("Format beats flavour"),
        para(
          "The spread between the best and worst electrolyte flavour is real but modest. The spread between formats " +
          "is far larger: the weakest new gel outsold the strongest electrolyte by two and a half times at equal age. " +
          "Where a flavour is launched matters more than which flavour it is."
        ),

        h1("5.  What to do with this"),
        bullet(
          "Gel is where launch volume comes from. If the objective is scale, new flavours belong in gel; the " +
          "electrolyte format has not produced a launch near gel's numbers."
        ),
        bullet(
          "Electrolytes are worth protecting for a different reason: they are the only format recruiting real " +
          "one-time buyers at full price, which is the entry point subscription-only products lack."
        ),
        bullet(
          "Electrolytes are overdue a launch. Fourteen months without a new flavour, in the format that carries the " +
          "one-time trade, is the clearest gap in the range."
        ),
        bullet(
          "Investigate the gel return rate. At roughly 1.5 times the electrolyte rate and consistent across both new " +
          "gel flavours, this looks like a format-level issue rather than a flavour problem."
        ),
        bullet(
          "Confirm the Raspberry/Watermelon one-time classification in Shopify before those figures go any further."
        ),

        h1("Notes"),
        bullet(
          "All four electrolyte flavours share a publish date of 19 June 2025 and a first-sale date of 4 July 2025, " +
          "so their equal-age windows are identical and their comparison with each other is exact."
        ),
        bullet(
          "Launch dates are measured from first sale but have been validated against Shopify's own published_at " +
          "field. Cranberry matches exactly; Peach/Pear published one day earlier than its first sale; " +
          "Raspberry/Watermelon four days earlier; the electrolyte range fifteen days earlier."
        ),
        bullet(
          "87 days is the age of the newest gel launch and therefore the widest window available for a complete " +
          "like-for-like comparison across all six flavours."
        ),
        bullet(
          "August 2026 is used for current trading because September is incomplete at the time of writing."
        ),
        bullet(
          "All figures are Shopify, United States, and revenue-based. Margin is unavailable until COGS arrives with " +
          "the Version 2 contribution-margin work, so no profitability ranking is offered here."
        ),
      ],
    },
  ],
});

Packer.toBuffer(doc).then((buf) => {
  fs.writeFileSync("/home/user/New_connector_testing/analysis/TrueSeaMoss_Gel_vs_Electrolyte_Headtohead.docx", buf);
  console.log("written");
});
