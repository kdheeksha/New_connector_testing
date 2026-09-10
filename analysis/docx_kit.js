/**
 * Shared docx building blocks for the TrueSeaMoss analysis reports.
 * Both reports use the same house style, so the styling lives here.
 */
const {
  Paragraph, TextRun, HeadingLevel, AlignmentType,
  Table, TableRow, TableCell, WidthType, ShadingType, BorderStyle, LevelFormat,
} = require("docx");

const INK = "1B2A27";
const ACCENT = "1F4E45";
const RULE = "C9D4D1";
const HEAD_FILL = "1F4E45";
const ZEBRA = "EFF3F2";
const MUTED = "5C6B68";
const BODY = "Calibri";
const DISPLAY = "Georgia";
const CONTENT_W = 9360; // US Letter with 1" margins

const t = (text, opts = {}) =>
  new TextRun({ text, font: BODY, size: 21, color: INK, ...opts });

const para = (text, opts = {}) =>
  new Paragraph({ spacing: { after: 160, line: 276 }, children: [t(text, opts)] });

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
  new Paragraph({
    numbering: { reference: "dots", level: 0 },
    spacing: { after: 100 },
    children: [t(text)],
  });

const caption = (text) =>
  new Paragraph({
    spacing: { before: 60, after: 260 },
    children: [new TextRun({ text, font: BODY, size: 17, italics: true, color: MUTED })],
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
            text, font: BODY, size: 19,
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

const numbering = {
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
};

const pageProps = {
  page: {
    size: { width: 12240, height: 15840 },
    margin: { top: 1440, bottom: 1440, left: 1440, right: 1440 },
  },
};

function titleBlock({ eyebrow, title, dek, meta }) {
  const out = [
    new Paragraph({
      spacing: { after: 60 },
      children: [new TextRun({ text: eyebrow, font: BODY, size: 17, bold: true, color: ACCENT, characterSpacing: 40 })],
    }),
    new Paragraph({
      spacing: { after: 100 },
      children: [new TextRun({ text: title, font: DISPLAY, size: 44, bold: true, color: INK })],
    }),
    new Paragraph({
      border: { bottom: { style: BorderStyle.SINGLE, size: 8, color: ACCENT, space: 8 } },
      spacing: { after: 240 },
      children: [new TextRun({ text: dek, font: BODY, size: 22, color: MUTED })],
    }),
  ];
  meta.forEach(([k, v], i) =>
    out.push(
      new Paragraph({
        spacing: { after: i === meta.length - 1 ? 300 : 40 },
        children: [t(k + ": ", { bold: true }), t(v)],
      })
    )
  );
  return out;
}

module.exports = { t, para, h1, h2, bullet, caption, cell, table, numbering, pageProps, titleBlock,
                   INK, ACCENT, MUTED, BODY, DISPLAY, CONTENT_W };
