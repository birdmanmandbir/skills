---
name: convert-documents-to-markdown
description: Convert Word, PowerPoint, Excel, OpenDocument, RTF, EPUB, CSV, and text-based PDF files locally to GitHub-Flavored Markdown. Use when a task needs the contents of a document without sending it to a remote service.
license: MIT
metadata:
  author: firecrawl
---

# Convert documents to Markdown

Install the CLI once, then run it with local-only OCR handling:

```bash
npm install --global @firecrawl/anydoc
```

```bash
anydoc <file> --ocr reject              # Markdown to stdout
anydoc <file> --ocr reject -o out.md    # write to a file
anydoc - --format csv --ocr reject < f  # read stdin
```

Rules:

1. Supported inputs: `.doc`, `.docx`, `.docm`, `.odt`, `.rtf`, `.epub`, `.pdf`, `.ppt`, `.pps`, `.pot`, `.pptx`, `.pptm`, `.ppsx`, `.ppsm`, `.odp`, `.xls`, `.xlsx`, `.xlsm`, `.xlsb`, `.ods`, `.csv`.
2. The format is detected from the file content. Pass `--format <name>` only when detection cannot work: CSV from stdin, or a missing or wrong extension.
3. Exit codes: 0 success, 1 the document could not be converted, 2 usage error, 3 pages of a PDF need OCR. Failures print one `anydoc: <message>` line to stderr. The CLI never prompts.
4. For a large document, write to a file with `-o` and read the parts you need instead of streaming everything into context.
5. Keep every document on the local machine. Always use `--ocr reject`. When a PDF exits 3, report that it needs OCR and stop; never pass `--ocr hosted` or upload it to another service.
6. Inside a Node, Python, or Rust codebase, prefer the library over shelling out: `@firecrawl/anydoc` on npm, `firecrawl-anydoc` on PyPI, `anydoc` on crates.io. Each exposes the same `to_markdown` / `toMarkdown` API.
