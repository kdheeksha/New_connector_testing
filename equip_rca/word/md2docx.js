const fs = require('fs');
const d = require('docx');
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, Table, TableRow, TableCell,
  WidthType, ShadingType, BorderStyle, AlignmentType, LevelFormat, PageOrientation
} = d;

const USABLE = 9360;            // 12240 letter - 2*1440 margins
const MONO = 'Consolas';

// ---------- inline markdown -> TextRun[] ----------
// Single left-to-right scan. Code spans are consumed atomically, so a `*`
// or `**` inside backticks stays literal; bold/italic are toggles, so they
// may legitimately open before a code span and close after it.
function inline(text, base = {}) {
  const runs = [];
  let bold = false, italics = false, buf = '';
  const flush = () => {
    if (!buf) return;
    runs.push(new TextRun({ ...base, text: buf, bold: bold || base.bold, italics }));
    buf = '';
  };
  let i = 0;
  while (i < text.length) {
    const c = text[i];
    if (c === '`') {
      const j = text.indexOf('`', i + 1);
      if (j > i) {
        flush();
        runs.push(new TextRun({
          ...base, text: text.slice(i + 1, j),
          bold: bold || base.bold, italics, font: MONO, size: 17,
        }));
        i = j + 1; continue;
      }
    } else if (c === '*' && text[i + 1] === '*') {
      flush(); bold = !bold; i += 2; continue;
    } else if (c === '*') {
      flush(); italics = !italics; i += 1; continue;
    }
    buf += c; i += 1;
  }
  flush();
  return runs.length ? runs : [new TextRun({ ...base, text: '' })];
}

function codeLines(lines) {
  return lines.map(l => new Paragraph({
    children: [new TextRun({ text: l || ' ', font: MONO, size: 16 })],
    spacing: { before: 0, after: 0, line: 240 },
    shading: { type: ShadingType.CLEAR, fill: 'F4F4F5' },
  }));
}

function splitRow(line) {
  let s = line.trim();
  if (s.startsWith('|')) s = s.slice(1);
  if (s.endsWith('|')) s = s.slice(0, -1);
  return s.split('|').map(c => c.trim());
}

function buildTable(rows) {
  const header = rows[0];
  const body = rows.slice(2);          // rows[1] is the --- separator
  const n = header.length;

  // weight columns by longest cell, clamped so one long column can't starve the rest
  const w = [];
  for (let i = 0; i < n; i++) {
    let m = header[i].length;
    for (const r of body) m = Math.max(m, (r[i] || '').length);
    w.push(Math.min(Math.max(m, 6), 60));
  }
  const tot = w.reduce((a, b) => a + b, 0);
  const cols = w.map(x => Math.floor(USABLE * x / tot));
  cols[n - 1] = USABLE - cols.slice(0, -1).reduce((a, b) => a + b, 0);

  const border = { style: BorderStyle.SINGLE, size: 2, color: 'D4D4D8' };
  const borders = { top: border, bottom: border, left: border, right: border };

  const mk = (cells, isHead) => new TableRow({
    tableHeader: isHead,
    children: cells.map((c, i) => new TableCell({
      width: { size: cols[i], type: WidthType.DXA },
      borders,
      shading: isHead ? { type: ShadingType.CLEAR, fill: 'EFEFF1' } : undefined,
      margins: { top: 60, bottom: 60, left: 100, right: 100 },
      children: [new Paragraph({
        children: inline(c, isHead ? { bold: true } : {}),
        spacing: { before: 0, after: 0 },
      })],
    })),
  });

  return new Table({
    columnWidths: cols,
    width: { size: USABLE, type: WidthType.DXA },
    rows: [mk(header, true), ...body.map(r => {
      while (r.length < n) r.push('');
      return mk(r.slice(0, n), false);
    })],
  });
}

// ---------- block parser ----------
function parse(md) {
  const lines = md.replace(/\r/g, '').split('\n');
  const out = [];
  let i = 0;
  let para = [];
  let quote = [];

  const flushPara = () => {
    if (!para.length) return;
    out.push(new Paragraph({
      children: inline(para.join(' ')),
      spacing: { before: 0, after: 140, line: 276 },
    }));
    para = [];
  };
  const flushQuote = () => {
    if (!quote.length) return;
    out.push(new Paragraph({
      children: inline(quote.join(' '), { size: 19, color: '52525B' }),
      indent: { left: 360 },
      border: { left: { style: BorderStyle.SINGLE, size: 12, color: 'A1A1AA', space: 8 } },
      spacing: { before: 60, after: 160, line: 264 },
    }));
    quote = [];
  };

  while (i < lines.length) {
    const line = lines[i];

    if (/^```/.test(line)) {
      flushPara(); flushQuote();
      const buf = [];
      i++;
      while (i < lines.length && !/^```/.test(lines[i])) buf.push(lines[i++]);
      i++;
      out.push(...codeLines(buf));
      out.push(new Paragraph({ text: '', spacing: { after: 120 } }));
      continue;
    }

    if (/^\|/.test(line) && i + 1 < lines.length && /^\|[\s:|-]+\|?\s*$/.test(lines[i + 1])) {
      flushPara(); flushQuote();
      const rows = [];
      while (i < lines.length && /^\|/.test(lines[i])) rows.push(splitRow(lines[i++]));
      out.push(buildTable(rows));
      out.push(new Paragraph({ text: '', spacing: { after: 160 } }));
      continue;
    }

    const h = line.match(/^(#{1,4})\s+(.*)$/);
    if (h) {
      flushPara(); flushQuote();
      const lvl = [HeadingLevel.TITLE, HeadingLevel.HEADING_1,
                   HeadingLevel.HEADING_2, HeadingLevel.HEADING_3][h[1].length - 1];
      out.push(new Paragraph({
        children: inline(h[2]),
        heading: lvl,
        spacing: { before: h[1].length <= 2 ? 320 : 220, after: 120 },
      }));
      i++; continue;
    }

    if (/^(---|\*\*\*|___)\s*$/.test(line)) {
      flushPara(); flushQuote();
      out.push(new Paragraph({
        text: '',
        border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: 'D4D4D8', space: 1 } },
        spacing: { before: 80, after: 200 },
      }));
      i++; continue;
    }

    // A list item may wrap over several source lines (lazy continuation).
    // Swallow the indented follow-on lines into the same item, or an italic
    // or bold span that opens on one line and closes on the next gets split
    // across two paragraphs.
    const isNewBlock = (l) =>
      l === undefined || l.trim() === '' || /^```/.test(l) || /^\|/.test(l) ||
      /^#{1,4}\s/.test(l) || /^(---|\*\*\*|___)\s*$/.test(l) ||
      /^[-*]\s+/.test(l) || /^\d+\.\s+/.test(l) || /^>\s?/.test(l);

    const takeItem = (first) => {
      const buf = [first];
      i++;
      while (!isNewBlock(lines[i])) buf.push(lines[i++].trim());
      return buf.join(' ');
    };

    const bullet = line.match(/^[-*]\s+(.*)$/);
    if (bullet) {
      flushPara(); flushQuote();
      out.push(new Paragraph({
        children: inline(takeItem(bullet[1])),
        bullet: { level: 0 },
        spacing: { before: 0, after: 80, line: 276 },
      }));
      continue;
    }

    const num = line.match(/^(\d+)\.\s+(.*)$/);
    if (num) {
      flushPara(); flushQuote();
      out.push(new Paragraph({
        children: inline(takeItem(num[2])),
        numbering: { reference: 'ol', level: 0 },
        spacing: { before: 0, after: 80, line: 276 },
      }));
      continue;
    }

    const q = line.match(/^>\s?(.*)$/);
    if (q) {
      flushPara();
      if (q[1].trim() === '') flushQuote(); else quote.push(q[1]);
      i++; continue;
    }

    if (line.trim() === '') { flushPara(); flushQuote(); i++; continue; }

    flushQuote();
    para.push(line.trim());
    i++;
  }
  flushPara(); flushQuote();
  return out;
}

// ---------- main ----------
const [, , src, dest] = process.argv;
const md = fs.readFileSync(src, 'utf8');

const doc = new Document({
  numbering: {
    config: [{
      reference: 'ol',
      levels: [{
        level: 0, format: LevelFormat.DECIMAL, text: '%1.',
        alignment: AlignmentType.START,
        style: { paragraph: { indent: { left: 460, hanging: 260 } } },
      }],
    }],
  },
  styles: {
    default: {
      document: { run: { font: 'Calibri', size: 21 } },
      title:     { run: { font: 'Calibri', size: 40, bold: true, color: '18181B' } },
      heading1:  { run: { font: 'Calibri', size: 30, bold: true, color: '18181B' } },
      heading2:  { run: { font: 'Calibri', size: 25, bold: true, color: '27272A' } },
      heading3:  { run: { font: 'Calibri', size: 22, bold: true, color: '3F3F46' } },
    },
  },
  sections: [{
    properties: {
      page: {
        size: { width: 12240, height: 15840, orientation: PageOrientation.PORTRAIT },
        margin: { top: 1080, bottom: 1080, left: 1440, right: 1440 },
      },
    },
    children: parse(md),
  }],
});

Packer.toBuffer(doc).then(b => { fs.writeFileSync(dest, b); console.log('wrote', dest, b.length, 'bytes'); });
