"""Replace the person data of the HL7 v2 test messages with synthetic values.

  python3 Scripts/anonymize-test-messages.py FILE_OR_DIR...

The example messages come from public implementation guides, but their
patients, relatives, guarantors, and insured persons look real. In PID, PD1,
MRG, NK1, GT1, and IN1, this script replaces names with synthetic names,
identifiers, dates of birth, addresses, telephone numbers, and e-mail
addresses with deterministic characters of the same length and case.
Separators, escapes, coded components (identifier types, assigning
authorities, name and address types, states, countries), and every other
segment are kept, so each message keeps its structure. The same original
value always gives the same replacement, which keeps cross-references
between segments and messages consistent. Run it once per message: it
replaces whatever values it finds.
"""
import hashlib
import os
import sys

FAMILY = ["SYNTHETIC", "SAMPLE", "EXEMPLAR", "TESTCASE", "FICTIVE", "MODEL", "DEMO", "PLACEHOLDER"]
GIVEN = ["ALEX", "SAM", "CAMILLE", "DOMINIQUE", "CHARLIE", "ROBIN", "JORDAN", "MORGAN"]
SYNTHETIC = set(FAMILY + GIVEN)

# Data type of each person field, by segment and field number (1-based).
FIELDS = {
    "PID": {2: "CX", 3: "CX", 4: "CX", 5: "XPN", 6: "XPN", 7: "TS", 9: "XPN", 11: "XAD", 13: "XTN",
            14: "XTN", 18: "CX", 19: "ID", 20: "ID", 21: "CX"},
    "PD1": {},
    "MRG": {1: "CX", 2: "CX", 3: "CX", 4: "CX", 5: "CX", 6: "CX", 7: "XPN"},
    "NK1": {2: "XPN", 4: "XAD", 5: "XTN", 6: "XTN", 30: "XPN", 31: "XTN", 32: "XAD", 33: "CX", 37: "ID"},
    "GT1": {2: "CX", 3: "XPN", 4: "XPN", 5: "XAD", 6: "XTN", 7: "XTN", 8: "TS", 12: "ID", 19: "CX"},
    "IN1": {16: "XPN", 18: "TS", 19: "XAD", 36: "ID", 49: "CX"},
}
# Components kept, by data type (1-based): coded values that are not personal.
KEPT = {
    "CX": {2, 3, 4, 5, 6, 7, 8},  # check digit, scheme, authority, type, facility, dates
    "XPN": {4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14},  # suffix, prefix, degree, types, dates
    "XAD": {4, 6, 7, 8, 9, 10, 11, 12, 13, 14},  # state, country, types, county, dates
    "XTN": {2, 3, 5, 8, 9, 10, 11, 12},  # use and equipment codes, country, extension
    "TS": set(),
    "ID": set(),
}


def digest(value):
    return hashlib.sha256(value.encode("utf-8")).digest()


def scramble(value):
    """Same length and character classes, deterministic, never the original."""
    if not value or value.startswith("\\"):
        return value
    seed = digest(value)
    out = []
    for index, char in enumerate(value):
        byte = seed[index % len(seed)] ^ index
        if char.isdigit():
            out.append(str((byte + int(char) + 1) % 10))
        elif "A" <= char <= "Z":
            out.append(chr(ord("A") + (byte + ord(char) + 1) % 26))
        elif "a" <= char <= "z":
            out.append(chr(ord("a") + (byte + ord(char) + 1) % 26))
        else:
            out.append(char)
    return "".join(out)


def name(value, choices):
    if not value or value.upper() in SYNTHETIC:
        return value
    pick = choices[digest(value)[0] % len(choices)]
    return pick if value.isupper() else pick.capitalize()


def date(value):
    """A date of birth in 1970-1999, keeping the precision and any time."""
    digits = value[:8]
    if len(digits) < 4 or not digits.isdigit():
        return scramble(value)
    seed = digest(value)
    synthetic = "%04d%02d%02d" % (1970 + seed[0] % 30, 1 + seed[1] % 12, 1 + seed[2] % 28)
    return synthetic[: len(digits)] + value[len(digits):]


def component(kind, number, value, sub):
    if number in KEPT[kind] or not value:
        return value
    if kind == "XPN" and number in (1, 2, 3):
        choices = FAMILY if number == 1 else GIVEN
        # FN: surname & own surname prefix & own surname & ...: rename the surname only.
        parts = value.split(sub)
        parts[0] = name(parts[0], choices)
        return sub.join(parts)
    if kind == "TS":
        return date(value)
    return sub.join(scramble(part) for part in value.split(sub))


def field(kind, value, separators):
    component_separator, repetition, escape, sub = separators
    repetitions = []
    for repeated in value.split(repetition):
        components = repeated.split(component_separator)
        components = [component(kind, number, part, sub) for number, part in enumerate(components, start=1)]
        repetitions.append(component_separator.join(components))
    return repetition.join(repetitions)


def segment(line, separators, field_separator):
    fields = line.split(field_separator)
    rules = FIELDS.get(fields[0])
    if not rules:
        return line
    for number, kind in rules.items():
        if number < len(fields):
            fields[number] = field(kind, fields[number], separators)
    return field_separator.join(fields)


def anonymize(text):
    out = []
    separators = ("^", "~", "\\", "&")
    field_separator = "|"
    for line in text.splitlines(keepends=True):
        body = line.rstrip("\r\n")
        ending = line[len(body):]
        stripped = body.lstrip()
        if stripped.startswith("MSH") and len(stripped) > 8:
            field_separator = stripped[3]
            encoding = stripped[4:8]
            separators = (encoding[0], encoding[1], encoding[2], encoding[3])
        else:
            # A segment may follow carriage returns inside one physical line.
            body = "\r".join(segment(part, separators, field_separator) for part in body.split("\r"))
        out.append(body + ending)
    return "".join(out)


def files(arguments):
    for argument in arguments:
        if os.path.isdir(argument):
            for root, _, names in os.walk(argument):
                for entry in sorted(names):
                    if entry.endswith((".txt", ".hl7")):
                        yield os.path.join(root, entry)
        else:
            yield argument


def main():
    changed = 0
    for path in files(sys.argv[1:]):
        with open(path, "rb") as handle:
            original = handle.read().decode("latin-1")
        result = anonymize(original)
        if result != original:
            with open(path, "wb") as handle:
                handle.write(result.encode("latin-1"))
            changed += 1
    print("anonymized %d files" % changed)


if __name__ == "__main__":
    main()
