# ``CDA``

Read the header, patients, and sections of HL7 CDA R2 documents.

## Overview

``CDAParser`` reads a CDA R2 document securely and reports what it checked:

```swift
import CDA

let result = CDAParser().parseWithReport(xml)
print(result.document?.title as Any)
print(result.report.outcome) // indeterminate for an extracted envelope
```

`parseWithReport(_:)` returns a ``CDAParseResult`` with the extracted envelope,
when there is one, and an `HL7DiagnosticReport` (from `HL7Core`). The throwing
`parse(_:)` remains available.

### Patients and sections

``CDADocument`` exposes `recordTargets` (identifiers, names, birth time,
administrative gender) and `sections` in document order. Each section keeps
its identifiers and template ids, code, title, narrative text, and number of
direct entries; `parentIndex` gives the hierarchy. Reading follows CDA paths
and namespaces, so foreign XML trees cannot inject an identity or a section.

`narrativeText` is a plain-text projection for display. No executable HTML is
rendered, and internal references, styles, and tables are not reproduced in
full. Keep the original XML for traceability, signatures, and structured
entries.

### Security

The `cda.xml`, `cda.root-name`, `cda.namespace`, and `cda.xml-security` stages
are `complete` once a document without a DTD, whose `ClinicalDocument` root is
in the [`urn:hl7-org:v3`](https://www.hl7.org/cda/stds/core/StructureDefinition-ClinicalDocument.html)
namespace, has been read. External entity resolution is disabled; DTDs found
in the usual XML encodings and entity declarations reported by the parser are
refused. This filter is deliberately conservative: it may also refuse a
literal `<!DOCTYPE` in a comment or CDATA section. Documents are limited to
16 MiB and 128 levels by default.

### Limits

`cda.envelope` stays `incomplete`: the model covers part of the header only.
`cda.schema`, `cda.templates`, and `cda.narrative` stay `notRun`. Malformed
XML, a wrong root name or namespace, or a forbidden declaration produce an
error diagnostic that copies neither the content nor the raw parser error. The
report is not a CDA R2 qualification.

## Topics

### Parsing

- ``CDAParser``
- ``CDAParseResult``
- ``CDADocument``
