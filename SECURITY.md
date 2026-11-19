# Security Policy

HL7Swift parses untrusted input (HL7 v2 messages, MLLP streams, FHIR JSON,
CDA XML) and exchanges it over the network, with or without TLS. Security
reports are welcome and are handled privately until a fix is available.

## Supported versions

| Version | Supported |
| --- | --- |
| `main` and the latest release | ✓ |
| Earlier releases | ✗ |

## Reporting a vulnerability

Do not open a public issue. Use one of these private channels:

- GitHub: **Security → Report a vulnerability** on
  [OPALE-dev/HL7Swift](https://github.com/OPALE-dev/HL7Swift/security/advisories/new);
- email: rw@opale.pro.

Please include the affected revision, the platform, and a minimal reproducer.
Do not attach messages or documents that contain patient data: reduce the
input to a synthetic case, or describe how to build one.

You can expect an acknowledgement within five working days. Once a fix is
available, it is released with a GitHub Security Advisory that credits the
reporter, unless you prefer to stay anonymous.

## Scope

In scope:

- crashes, hangs, or unbounded resource use when reading malformed messages,
  MLLP frames, FHIR resources, or CDA documents;
- XML external entity or DTD processing in the CDA parser;
- TLS configuration or certificate validation defects in MLLP and HTTP
  clients;
- FHIR server primitives that leak data across the callbacks of another
  principal, or follow links outside the configured base;
- patient values copied into diagnostics or logs.

Out of scope: the `HL7Client`, `HL7Server`, and `HL7Router` command-line tools
deployed without access control or network isolation. They are demonstrators,
not hardened interfaces.

HL7Swift is not a medical device and must not be used for diagnosis.
