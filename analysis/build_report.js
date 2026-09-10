const fs = require("fs");
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType,
  Table, TableRow, TableCell, WidthType, ShadingType, BorderStyle,
  LevelFormat, PageOrientation,
} = require("docx");

const INK = "1B2A27";
const ACCENT = "1F4E45";
const RULE = "C9D4D1";
const HEAD_FILL = "1F4E45";
const ZEBRA = "EFF3F2";
const BODY = "Calibri";
const DISPLAY = "Georgia";

const CONTENT_W = 9360; // Letter, 1" margins

const t = (text, opts = {}) => new TextRun({ text, font: BODY, size: 21, color: INK, ...opts });

const para = (text, opts = {}) =>
  new Paragraph({
    spacing: { after: 160, line: 276 },
    children: [t(text, opts)],
    ...(opts.alignment ? { alignment: opts.alignment } : {}),
  });

const h1 = (text) =>
  new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 360, after: 160 },
    children: [new TextRun({ text, font: DISPLAY, size: 30, bold: true, color: ACCENT })],
  });

const h2 = (text) =>
  new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 280, after: 120 },
    children: [new TextRun({ text, font: DISPLAY, size: 25, bold: true, color: INK })],
  });

const bullet = (text) =>
  new Paragraph({ numbering: { reference: "dots", level: 0 }, spacing: { after: 100 }, children: [t(text)] });

const caption = (text) =>
  new Paragraph({
    spacing: { before: 60, after: 260 },
    children: [new TextRun({ text, font: BODY, size: 17, italics: true, color: "5C6B68" })],
  });

const cell = (text, w, { bold = false, header = false, align = AlignmentType.LEFT, fill = null } = {}) =>
  new TableCell({
    width: { size: w, type: WidthType.DXA },
    shading: header
      ? { type: ShadingType.CLEAR, fill: HEAD_FILL, color: "auto" }
      : fill
      ? { type: ShadingType.CLEAR, fill, color: "auto" }
      : undefined,
    margins: { top: 90, bottom: 90, left: 120, right: 120 },
    children: [
      new Paragraph({
        alignment: align,
        spacing: { after: 0 },
        children: [
          new TextRun({
            text,
            font: BODY,
            size: 19,
            bold: bold || header,
            color: header ? "FFFFFF" : INK,
          }),
        ],
      }),
    ],
  });

function table(widths, headers, rows, aligns) {
  const al = aligns || widths.map((_, i) => (i === 0 ? AlignmentType.LEFT : AlignmentType.RIGHT));
  return new Table({
    columnWidths: widths,
    width: { size: CONTENT_W, type: WidthType.DXA },
    borders: {
      top: { style: BorderStyle.SINGLE, size: 2, color: RULE },
      bottom: { style: BorderStyle.SINGLE, size: 2, color: RULE },
      left: { style: BorderStyle.NONE },
      right: { style: BorderStyle.NONE },
      insideHorizontal: { style: BorderStyle.SINGLE, size: 2, color: RULE },
      insideVertical: { style: BorderStyle.NONE },
    },
    rows: [
      new TableRow({
        tableHeader: true,
        children: headers.map((hh, i) => cell(hh, widths[i], { header: true, align: al[i] })),
      }),
      ...rows.map((r, ri) =>
        new TableRow({
          children: r.map((c, i) =>
            cell(String(c), widths[i], {
              align: al[i],
              bold: i === 0,
              fill: ri % 2 === 1 ? ZEBRA : null,
            })
          ),
        })
      ),
    ],
  });
}

const doc = new Document({
  numbering: {
    config: [
      {
        reference: "dots",
        levels: [
          {
            level: 0,
            format: LevelFormat.BULLET,
            text: "•",
            alignment: AlignmentType.LEFT,
            style: { paragraph: { indent: { left: 360, hanging: 220 } } },
          },
        ],
      },
    ],
  },
  sections: [
    {
      properties: {
        page: {
          size: { width: 12240, height: 15840, orientation: PageOrientation.PORTRAIT },
          margin: { top: 1440, bottom: 1440, left: 1440, right: 1440 },
        },
      },
      children: [
        // ---------- Title block ----------
        new Paragraph({
          spacing: { after: 60 },
          children: [
            new TextRun({ text: "TRUESEAMOSS  ·  FLAVOUR LAUNCH ANALYSIS", font: BODY, size: 17, bold: true, color: ACCENT, characterSpacing: 40 }),
          ],
        }),
        new Paragraph({
          spacing: { after: 100 },
          children: [
            new TextRun({ text: "Do new flavour launches grow the business?", font: DISPLAY, size: 44, bold: true, color: INK }),
          ],
        }),
        new Paragraph({
          border: { bottom: { style: BorderStyle.SINGLE, size: 8, color: ACCENT, space: 8 } },
          spacing: { after: 240 },
          children: [
            new TextRun({
              text: "Three newly launched gel flavours, tested for incremental revenue against a matched control",
              font: BODY, size: 22, color: "5C6B68",
            }),
          ],
        }),
        new Paragraph({
          spacing: { after: 40 },
          children: [
            t("Scope: ", { bold: true }),
            t("Shopify, United States. Data through 10 September 2026."),
          ],
        }),
        new Paragraph({
          spacing: { after: 40 },
          children: [
            t("Subject: ", { bold: true }),
            t("Gel Cranberry (9 Dec 2025), Gel Peach/Pear (20 Mar 2026), Gel Raspberry/Watermelon (15 Jun 2026)."),
          ],
        }),
        new Paragraph({
          spacing: { after: 300 },
          children: [
            t("Source: ", { bold: true }),
            t("daton-project · sku_cohort_base, the same model behind the Power BI cohort views."),
          ],
        }),

        // ---------- Summary ----------
        h1("Summary"),
        para(
          "New flavour launches at TrueSeaMoss are acquisition events, not merchandising events. " +
          "Across all three launches examined, between 80% and 93% of launch revenue came from customers " +
          "who had never bought from TrueSeaMoss before. The remaining slice, from customers who already " +
          "existed, was additive rather than substitutive."
        ),
        para(
          "We found no detectable redistribution in any of the three launches. Existing customers who adopted " +
          "a new flavour did not swap spend away from the flavours they already bought; they spent more in total " +
          "than comparable customers who did not adopt."
        ),
        para(
          "Every launch paid back on a revenue basis inside 60 days, returning 1.55 to 1.91 times the blended " +
          "cost of acquisition prevailing in its own launch month. Against the stricter cost per new paid customer, " +
          "the margin is thinner, at 1.11 to 1.39 times."
        ),
        para(
          "Most consequentially: once observation windows are equalised, the three launches are almost " +
          "indistinguishable in unit economics, despite differing sevenfold in size. Flavour choice did not drive " +
          "launch outcomes. Reach did."
        ),

        // ---------- Section 1 ----------
        h1("1.  The three launches, compared at equal age"),
        para(
          "TrueSeaMoss keeps no launch calendar, so each launch date is derived from the first observed sale of " +
          "that flavour. Indexing every launch to its own day zero allows launches from different calendar months " +
          "to be compared on equal footing."
        ),
        table(
          [2760, 2200, 2200, 2200],
          ["", "Cranberry", "Peach/Pear", "Raspberry/Watermelon"],
          [
            ["Launch date", "9 Dec 2025", "20 Mar 2026", "15 Jun 2026"],
            ["Gross sales, T+30", "$46,183", "$91,447", "$260,113"],
            ["Gross sales, T+60", "$62,882", "$225,689", "$665,700"],
            ["Gross sales, T+90", "$134,069", "$498,234", "$1,110,054"],
            ["New customers, T+90", "2,771", "12,732", "25,781"],
            ["New-to-brand share, T+30", "78.4%", "78.7%", "90.7%"],
            ["Average order value", "$26.76", "$26.57", "$26.87"],
            ["Repeat purchase within 60 days", "69.6%", "70.9%", "68.3%"],
          ]
        ),
        caption(
          "Raspberry/Watermelon's T+90 window ends 12 September 2026; data runs to 10 September, so that figure covers 88 of 90 days."
        ),
        h2("What stands out"),
        bullet(
          "Raspberry/Watermelon is decisively the strongest launch — 2.2 times Peach/Pear and 8.3 times Cranberry " +
          "at the same age. Peach/Pear has earned more in absolute lifetime revenue only because it is three months older."
        ),
        bullet(
          "Repeat rate is near-identical across all three launches (68–71%). Launch size varies eightfold, but the " +
          "quality of the customers acquired does not. Launches differ in how many customers they pull, not how good those customers are."
        ),
        bullet(
          "Average order value is flat at roughly $26–27 across every launch. No launch bought its volume through " +
          "larger baskets or heavier discounting."
        ),

        // ---------- Section 2 ----------
        h1("2.  Where launch revenue comes from"),
        para(
          "Launch revenue divides into two parts. Revenue from customers whose first ever order is the launch order " +
          "is unambiguously incremental. Revenue from customers who already bought from TrueSeaMoss is the ambiguous " +
          "part: it only counts as growth if those customers spent more in total than they otherwise would have, " +
          "rather than simply swapping one flavour for another."
        ),
        para(
          "Membership is decided by first-ever order date against the launch date. This matters: classifying on the " +
          "acquisition-day flag instead would treat a customer acquired two weeks into the launch window as " +
          "“pre-existing” the moment they reorder. On a business where 62% of first orders are subscriptions, " +
          "that misclassification is large, and it inflates the apparent redistributed share."
        ),
        table(
          [2160, 1440, 1600, 1000, 1600, 1560],
          ["Launch", "Gross", "New-customer $", "New %", "Pre-existing $", "Pre-exist %"],
          [
            ["Cranberry", "$62,882", "$50,029", "79.6%", "$12,853", "20.4%"],
            ["Peach/Pear", "$225,690", "$188,531", "83.5%", "$37,158", "16.5%"],
            ["Raspberry/Watermelon", "$665,700", "$619,892", "93.1%", "$45,807", "6.9%"],
          ]
        ),
        caption("First 60 days of each launch. Shopify, United States."),
        para(
          "The ambiguous slice is therefore small — between 7% and 20% of launch revenue — and it has shrunk with " +
          "each successive launch."
        ),

        // ---------- Section 3 ----------
        h1("3.  Is that remaining slice incremental?"),
        para(
          "To test it, each launch's adopters are compared against a control group of customers who were equally " +
          "active in the same window but did not buy the launch flavour. Comparing adopters against all existing " +
          "customers would be badly biased, because adopters bought something by construction and are therefore " +
          "active by definition. Requiring the control to have ordered in the same window removes that. Both groups " +
          "are then split into quintiles by prior spend, so a wealthier adopter base cannot masquerade as a launch effect."
        ),
        para(
          "The measure is a difference-in-differences: how much the adopters' total spend changed from the 60 days " +
          "before the launch to the 60 days after, minus the same change for the control."
        ),
        table(
          [3360, 3000, 3000],
          ["Launch", "Adopters", "Difference-in-differences, per customer"],
          [
            ["Cranberry", "362", "+$57.95"],
            ["Peach/Pear", "927", "+$53.29"],
            ["Raspberry/Watermelon", "1,233", "+$51.92"],
          ]
        ),
        h2("Placebo calibration"),
        para(
          "Customers who buy any given flavour are more engaged than those who do not, so part of that lift is " +
          "selection rather than launch effect. To measure that floor, the identical design was run on three " +
          "long-established flavours, where no launch occurred and any measured effect must be selection."
        ),
        table(
          [3360, 3000, 3000],
          ["Established flavour (control)", "Adopters", "Difference-in-differences, per customer"],
          [
            ["Mango, Pineapple", "47,720", "+$8.90"],
            ["Ashwagandha", "20,146", "+$9.69"],
            ["Soursop", "8,985", "+$10.44"],
            ["Selection baseline (mean)", "—", "+$9.68"],
          ]
        ),
        para(
          "The selection floor is real but small. The launch flavours run five to six times above it, which is what " +
          "gives the result its credibility: the effect is far too large to be explained by engaged customers alone."
        ),

        h2("Result"),
        para(
          "Subtracting the selection baseline from each launch's measured lift gives the adjusted incremental figure below."
        ),
        table(
          [2160, 1300, 1600, 1500, 1400, 1400],
          ["Launch", "Adj. / cust", "Adj. incremental", "Pre-existing $", "Redistributed", "True incremental"],
          [
            ["Cranberry", "+$48.28", "$17,476", "$12,853", "$0", "$62,882"],
            ["Peach/Pear", "+$43.61", "$40,426", "$37,158", "$0", "$225,689"],
            ["Raspberry/Watermelon", "+$42.25", "$52,091", "$45,807", "$0", "$665,699"],
          ]
        ),
        para(
          "In every case the adjusted incremental lift exceeds what those customers actually spent on the new flavour. " +
          "Existing customers who adopted did not move spend across from other flavours — they added the new flavour " +
          "to what they were already buying, and spent somewhat more besides. Redistribution is therefore zero within " +
          "the limits of what this method can detect."
        ),

        // ---------- Section 4 ----------
        h1("4.  Do launches pay back?"),
        para(
          "Proving a launch is incremental does not establish that it was worth doing. To test that, each launch is " +
          "measured on what the customers it acquired went on to spend — on anything, not only the launch flavour — " +
          "against the cost of acquiring a customer in that same month, taken from TrueSeaMoss's own monthly KPI view."
        ),
        para(
          "Windows must be equalised for this comparison to mean anything. Raspberry/Watermelon is recent enough that " +
          "its later-acquired customers have only weeks of history, which drags its averages down for reasons that " +
          "have nothing to do with the launch. Every launch below is therefore measured identically: customers " +
          "acquired in the first 28 days, each observed for 60 days."
        ),
        table(
          [2160, 1200, 1240, 1240, 1000, 1280, 1240],
          ["Launch", "Acquired", "Rev / cust", "2nd order", "Blended CAC", "× CAC", "× NCPA"],
          [
            ["Cranberry", "1,187", "$108.83", "67.7%", "$57.22", "1.90×", "1.24×"],
            ["Peach/Pear", "2,391", "$104.67", "70.7%", "$67.66", "1.55×", "1.11×"],
            ["Raspberry/Watermelon", "8,586", "$104.87", "68.1%", "$55.03", "1.91×", "1.39×"],
          ]
        ),
        caption(
          "Blended CAC and DTC NCPA are period-matched to each launch month, from All_KPIs_Monthly_Performance (Gels, United States)."
        ),
        para(
          "All three clear blended acquisition cost inside 60 days. Against DTC NCPA — the stricter measure, and " +
          "arguably the right one for launches, since these are new paid customers — the margin narrows to between " +
          "1.11 and 1.39 times. These are revenue figures, not margin, so true profit payback takes longer than 60 " +
          "days and cannot be settled until COGS lands with the Version 2 contribution-margin work."
        ),

        // ---------- Section 5 ----------
        h1("5.  Conclusions"),
        h2("Launches grow the business; they do not move demand around"),
        para(
          "Between 80% and 93% of launch revenue comes from customers who had never bought before, and the small " +
          "pre-existing slice is additive. Cannibalisation did not occur in any of the three launches and should not " +
          "be treated as a gating risk in launch decisions."
        ),
        h2("Flavour choice does not drive launch economics — reach does"),
        para(
          "This is the most actionable finding. On equalised windows the three launches are almost identical per " +
          "customer: $104.67 to $108.83 in 60-day revenue, and a second-order rate between 67.7% and 70.7%. A spread " +
          "of under 4% across three different flavours launched in three different quarters. Yet Raspberry/Watermelon " +
          "acquired 7.2 times as many customers as Cranberry."
        ),
        para(
          "The flavour, in other words, did not determine the return. The scale of the launch did. Effort spent " +
          "deliberating which flavour to launch next is better spent on how much reach the launch is given."
        ),
        h2("A new flavour acts as a re-engagement trigger, not merely a product"),
        para(
          "In all three launches the adjusted incremental lift exceeded what adopters actually spent on the new " +
          "flavour itself. Existing customers who tried it did not only add it to their basket; they raised their " +
          "overall spend beyond it. A launch appears to reactivate the existing base as well as recruit a new one."
        ),
        h2("Recommendation"),
        bullet(
          "Treat flavour launches as a standing acquisition channel with predictable unit economics, not as " +
          "individual portfolio bets."
        ),
        bullet(
          "Shift the decision from which flavour to launch toward how much media and merchandising support each " +
          "launch receives, since that is the variable the data shows moving outcomes."
        ),
        bullet(
          "Grade future launches against Raspberry/Watermelon's curve — $260,113 at T+30 and $665,700 at T+60 — " +
          "rather than against absolute revenue, which flatters older launches."
        ),
        bullet(
          "Revisit the payback conclusion once Version 2 COGS is available. The revenue-basis result is positive, " +
          "but the margin against NCPA is thin enough that the profit answer could differ."
        ),

        // ---------- Section 6 ----------
        h1("6.  Method notes and limitations"),
        bullet(
          "Launch dates are first-sale proxies. They should be reconciled against Shopify product publish dates; a " +
          "soft launch ahead of promotion would shift every T+30 figure."
        ),
        bullet(
          "All figures are revenue-based. Margin and contribution KPIs are Version 2 deliverables pending COGS from " +
          "1C and Y-sell, so no profit-level conclusion is drawn here."
        ),
        bullet(
          "Difference-in-differences identifies association, not causation. The placebo calibration materially " +
          "strengthens the result but does not make it a controlled experiment."
        ),
        bullet(
          "Cranberry's adopter base is small (362 customers). Its per-customer figure should be read as indicative."
        ),
        bullet(
          "Scope is Shopify and the United States only. The August 2026 Sparkling Drink launch is excluded because " +
          "it sells on TikTok and Amazon only, with no Shopify presence."
        ),
        bullet(
          "Payback in Section 4 counts everything an acquired customer spent in their first 60 days, not only the " +
          "launch flavour, since the launch is credited with the customer rather than the single product."
        ),
        bullet(
          "Observation windows are equalised in Section 4 but not in Section 1, where T+30/60/90 are cumulative by " +
          "construction. Comparing raw per-customer averages across launches of different ages without equalising " +
          "understates the most recent launch substantially."
        ),
        bullet(
          "Established flavours appear in this analysis solely as placebo controls. They are not the subject of the study."
        ),
      ],
    },
  ],
});

Packer.toBuffer(doc).then((buf) => {
  fs.writeFileSync("/home/user/New_connector_testing/analysis/TrueSeaMoss_Flavour_Launch_Analysis.docx", buf);
  console.log("written");
});
