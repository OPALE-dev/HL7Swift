# Changelog

## Unreleased — 2026-10-13

- No HL7 v2 XSDs or imported mapping CSVs are distributed in library resources.
  `HL7()` is resource-free and installs handwritten native working models.
  No application-supplied specification directory is accepted or needed.
- New `ER7Message` value API supports custom delimiters, Unicode, explicit null,
  long repetitions, edits, escape handling and connector parsing policies.
  Declared and interpreted versions remain separate.
- New original/enhanced-phase ACK builder supports AA/AE/AR/CA/CE/CR without
  artefacts; the application chooses the phase and persistence contract.
- New `MLLPConnection` async API checks ACK correlation, handles deadlines and
  cancellation, and closes uncertain exchanges. Raw framing codecs are public.
  Standard client TLS configurations verify trust and hostname.
- New `FHIRR4RESTClient` async API supports CRUD, full search Bundles, bounded
  pagination, capabilities, history, vread, batch/transaction, version metadata
  and OperationOutcome errors through an injectable HTTP transport.
- Added positional v2 clinical projections and CDA patients, nested sections
  and plain-text narration with XML byte/depth limits.
- `V2MessageBuilder` and `V2NativeValidator` provide native clinical construction
  and scoped connector checks without schema artefacts.
- `HL7CodeGen` exports native working-model symbols to an explicit output directory.
- Fixed Unicode and repeated-segment lookup in the historical parser, removed
  message-body transport logging, and corrected Linux imports/file-size access.

Migration and limitations: [ER7](Documentation/ER7.md),
[MLLP](Documentation/MLLP.md), [FHIR REST](Documentation/FHIR_REST.md),
[clinical projections](Documentation/CLINICAL_PROJECTIONS.md).
Full profile conformance, clinical workflows and automatic patient reconciliation
are not implied by these API additions. Worklist/MPPS services belong to the PACS.
