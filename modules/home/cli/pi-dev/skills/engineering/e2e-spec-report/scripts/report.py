import argparse
import csv
import hashlib
import html
import io
import json
import os
from pathlib import Path
import re
import tempfile
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote, urlsplit

ASSETS = Path(__file__).resolve().parent.parent / "assets"
PUBLIC_FILES = {"report.html", "report.md", "inventory.csv", "inventory.json", "specification.feature", "sources.html"}


def text(value, label):
    if not isinstance(value, str) or not value.strip() or re.search(r"[\x00-\x1f\x7f]", value):
        raise ValueError(f"{label} must be a nonempty single-line string")
    return value


def source_path(root, name):
    text(name, "source file")
    relative = Path(name)
    if relative.is_absolute() or ".." in relative.parts:
        raise ValueError(f"Source must be relative to repoRoot: {name}")
    candidate = (root / relative).resolve()
    if not candidate.is_relative_to(root) or not candidate.is_file():
        raise ValueError(f"Missing or escaping source file: {name}")
    return candidate


def strings(value, label):
    if not isinstance(value, list):
        raise ValueError(f"{label} must be an array")
    return [text(item, label) for item in value]


def validate(data):
    if not isinstance(data, dict) or type(data.get("version")) is not int or data["version"] != 1:
        raise ValueError("Expected inventory version 1")
    for field in ["files", "declarations", "cases"]:
        if field not in data:
            raise ValueError(f"{field} must be present, even when empty")
    for field in ["files", "declarations", "registrations", "registrationReviews", "unresolved", "cases"]:
        if not isinstance(data.get(field, []), list):
            raise ValueError(f"{field} must be an array")
    if not isinstance(data.get("snapshot", ""), str):
        raise ValueError("snapshot must be a string")
    text(data.get("title"), "title")
    root = Path(text(data.get("repoRoot"), "repoRoot"))
    if not root.is_absolute() or not root.is_dir():
        raise ValueError("repoRoot must be an existing absolute directory")
    root = root.resolve()
    scope = (root / text(data.get("scope"), "scope")).resolve()
    if not scope.is_relative_to(root) or not scope.is_dir():
        raise ValueError("scope must be a directory within repoRoot")
    sources = {}
    contents = {}

    def reference(source):
        if not isinstance(source, dict):
            raise ValueError("Expected a source object")
        name = source.get("file")
        if name not in contents:
            contents[name] = source_path(root, name).read_text().splitlines()
        lines = contents[name]
        line = source.get("line")
        if type(line) is not int or not 1 <= line <= len(lines):
            raise ValueError(f"Invalid source line: {name}:{line}")
        key = f"{name}:{line}"
        sources[key] = {"file": name, "line": line, "lines": lines}
        return key

    file_names = set()
    for entry in data.get("files", []):
        name = entry["file"]
        source_path(root, name)
        if name in file_names:
            raise ValueError(f"Duplicate file: {name}")
        file_names.add(name)
        text(entry.get("review"), f"File review for {name}")
    declarations = {}
    for declaration in data.get("declarations", []):
        identifier = text(declaration.get("id"), "declaration id")
        if identifier in declarations:
            raise ValueError(f"Duplicate declaration: {identifier}")
        if declaration["source"]["file"] not in file_names:
            raise ValueError(f"Declaration source needs a files review: {identifier}")
        reference(declaration["source"])
        if not isinstance(declaration.get("titleExpression"), str) or not declaration["titleExpression"].strip():
            raise ValueError("titleExpression must be a nonempty source expression")
        if declaration.get("status") not in {"declared", "skipped"}:
            raise ValueError(f"Invalid declaration status: {identifier}")
        declarations[identifier] = declaration
    registrations = {entry["id"]: entry for entry in data.get("registrations", [])}
    if len(registrations) != len(data.get("registrations", [])):
        raise ValueError("Duplicate registration id")
    for entry in registrations.values():
        reference(entry["source"])
    unresolved = {}
    for item in data.get("unresolved", []):
        identifier = text(item.get("id"), "unresolved id")
        if identifier in unresolved or identifier not in declarations.keys() | registrations.keys():
            raise ValueError(f"Unknown or duplicate unresolved item: {identifier}")
        unresolved[identifier] = text(item.get("reason"), "unresolved reason")
    reviewed = set()
    for review in data.get("registrationReviews", []):
        identifier = review.get("id")
        if identifier not in registrations or identifier in reviewed:
            raise ValueError(f"Unknown or duplicate registration review: {identifier}")
        text(review.get("resolution"), "registration resolution")
        reviewed.add(identifier)
    if registrations.keys() - reviewed - unresolved.keys():
        raise ValueError("Every registration candidate needs a review or unresolved reason")
    seen_ids, seen_titles, represented = set(), set(), set()
    for case in data.get("cases", []):
        identifier = text(case.get("id"), "case id")
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]*", identifier) or identifier in seen_ids:
            raise ValueError(f"Invalid or duplicate case id: {identifier}")
        seen_ids.add(identifier)
        declaration = declarations.get(case.get("declaration"))
        if not declaration:
            raise ValueError(f"Unknown declaration for {identifier}")
        represented.add(case["declaration"])
        for field in ["title", "given", "when", "then"]:
            text(case.get(field), f"{identifier}.{field}")
        for field in ["suite", "conditions", "notes"]:
            strings(case.get(field, []), f"{identifier}.{field}")
        if not isinstance(case.get("parameters", {}), dict):
            raise ValueError(f"Parameters must be an object: {identifier}")
        if case.get("status") not in {"declared", "skipped"}:
            raise ValueError(f"Invalid case status: {identifier}")
        if declaration["status"] == "skipped" and case["status"] != "skipped":
            raise ValueError(f"Inherited skip lost: {identifier}")
        title_key = (declaration["source"]["file"], tuple(case.get("suite", [])), case["title"])
        if title_key in seen_titles:
            raise ValueError(f"Duplicate case title within suite: {identifier}")
        seen_titles.add(title_key)
        for evidence in case.get("evidence", []):
            reference(evidence)
    missing = declarations.keys() - represented - unresolved.keys()
    if missing:
        raise ValueError("Declarations without cases or unresolved reasons: " + ", ".join(sorted(missing)))
    return declarations, sources


def source_anchor(source):
    key = f'{source["file"]}:{source["line"]}'
    return "source-" + hashlib.sha256(key.encode()).hexdigest()[:20]


def source_link(source):
    return "sources.html#" + source_anchor(source)


def scenario(case):
    return f'Scenario: {case["title"]}\n  Given {case["given"]}\n  When {case["when"]}\n  Then {case["then"]}'


def feature(data, declarations):
    result = [f'Feature: {data["title"]}', "  Source-derived documentation; no step definitions are supplied.", "  Status and original CI tags are metadata, not execution directives.", "  Tests were not executed by this report generator.", ""]
    result.insert(1, f'  Documented scenarios: {len(data["cases"])}; unresolved items: {len(data.get("unresolved", []))}.')
    for item in data.get('unresolved', []):
        result.insert(-1, f'  Unresolved {item["id"]}: {item["reason"]}')
    for file in dict.fromkeys(declarations[case["declaration"]]["source"]["file"] for case in data["cases"]):
        result.extend([f"  Rule: {file}", ""])
        for case in data["cases"]:
            source = declarations[case["declaration"]]["source"]
            if source["file"] != file:
                continue
            result.extend([f'    Scenario: {case["title"]}', f'      Inventory ID: {case["id"]}', f'      Source: {file}:{source["line"]}', f'      Status: {case["status"]}'])
            for label, items in [("Group", case.get("suite", [])), ("Execution condition", case.get("conditions", [])), ("Comparison note", case.get("notes", []))]:
                result.extend(f"      {label}: {item}" for item in items)
            result.extend([f'      Given {case["given"]}', f'      When {case["when"]}', f'      Then {case["then"]}', ""])
    return "\n".join(result) + "\n"


def csv_report(data, declarations):
    output = io.StringIO(newline="")
    columns = ["id", "declaration", "file", "line", "suite", "originalTitle", "titleExpression", "parameters", "status", "given", "when", "then", "conditions", "notes", "evidence"]
    writer = csv.DictWriter(output, fieldnames=columns)
    writer.writeheader()
    for case in data["cases"]:
        declaration = declarations[case["declaration"]]
        row = {key: case.get(key, "") for key in ["id", "declaration", "status", "given", "when", "then"]}
        row.update({key: declaration["source"][key] for key in ["file", "line"]})
        row.update(originalTitle=case["title"], titleExpression=declaration["titleExpression"])
        row.update({key: json.dumps(case.get(key, {} if key == "parameters" else []), ensure_ascii=False) for key in ["suite", "parameters", "conditions", "notes", "evidence"]})
        writer.writerow(row)
    return output.getvalue()


def fenced(content):
    length = max([2, *[len(match) for match in re.findall(r"`+", content)]]) + 1
    fence = "`" * length
    return f"{fence}gherkin\n{content}\n{fence}"


def markdown_report(data, declarations):
    result = [f'# {data["title"]}', "", f'{len(data["cases"])} expanded cases; {len(declarations)} declaration families.', "", "Source-derived, not independent acceptance requirements. Tests were not executed.", "", "[HTML comparison](report.html) · [CSV](inventory.csv) · [Gherkin](specification.feature)", ""]
    if data.get("unresolved"):
        result.extend(["## Incomplete inventory", ""])
        result.extend(f'- {item["id"]}: {item["reason"]}' for item in data["unresolved"])
    for case in data["cases"]:
        source = declarations[case["declaration"]]["source"]
        result.extend([f'## {case["id"]}', "", f'Source: [{source["file"]}:{source["line"]}]({source_link(source)})', f'Status: {case["status"]}', "", fenced(scenario(case)), ""])
        for label, items in [("Group", case.get("suite", [])), ("Execution condition", case.get("conditions", [])), ("Comparison note", case.get("notes", []))]:
            result.extend(f"{label}: {item}\n" for item in items)
    return "\n".join(result)


def html_page(title, body, interactive=False):
    css = (ASSETS / "report.css").read_text()
    script = "<script>" + (ASSETS / "report.js").read_text() + "</script>" if interactive else ""
    return f'<!doctype html>\n<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>{html.escape(title)}</title><style>{css}</style></head><body data-view="gherkin"><header><strong>{html.escape(title)}</strong><a href="inventory.csv" download>CSV</a><a href="specification.feature" download>Gherkin</a><a href="report.md" download>Markdown</a></header><main>{body}</main><footer>Source inspection only · Tests were not executed</footer>{script}</body></html>\n'


def html_report(data, declarations):
    escape = html.escape
    count = len(data["cases"])
    skipped = sum(case["status"] == "skipped" for case in data["cases"])
    parts = [f'<h1>{escape(data["title"])}</h1><p><strong>{count} expanded cases · {len(declarations)} declaration families · {skipped} statically skipped cases</strong></p>', '<p>Behavior follows the test implementation, not an independent product specification. Original titles and Given/When/Then text are preserved across every export. No executable step definitions are supplied.</p>', f'<p class="meta">Scope: {escape(data["scope"])} · Snapshot: {escape(data.get("snapshot") or "not supplied")}</p>']
    if data.get("unresolved"):
        items = "".join(f'<li>{escape(item["id"])}: {escape(item["reason"])}</li>' for item in data["unresolved"])
        parts.append(f'<aside class="notice"><strong>Incomplete inventory: unresolved cases/registrations</strong><ul>{items}</ul><p>The total above counts documented cases, not unknown variants.</p></aside>')
    parts.append(f'<div class="toolbar"><input id="search" type="search" aria-label="Search scenarios" placeholder="Search title, source, Given/When/Then…"><span><span id="visible-count">{count}</span> visible</span><button data-view="gherkin" aria-pressed="true">Gherkin</button><button data-view="comparison" aria-pressed="false">Comparison</button></div>')
    parts.append('<details><summary>Discovery and registration ledger</summary><ul>')
    parts.extend(f'<li><code>{escape(entry["file"])}</code>: {escape(entry["review"])}</li>' for entry in data["files"])
    parts.extend(f'<li>Registration <code>{escape(review["id"])}</code>: {escape(review["resolution"])}</li>' for review in data.get("registrationReviews", []))
    parts.append('</ul></details>')
    for case in data["cases"]:
        source = declarations[case["declaration"]]["source"]
        badge = 'badge skipped' if case["status"] == 'skipped' else 'badge'
        parts.append(f'<article class="case" id="{case["id"]}"><h2>{escape(case["id"])}</h2><p class="meta">{escape(" > ".join(case.get("suite", [])))}</p><p><a href="{source_link(source)}">{escape(source["file"])}:{source["line"]}</a> <span class="{badge}">{case["status"]}</span></p>')
        code = escape(scenario(case))
        code = re.sub(r"^( *)(Scenario:|Given|When|Then)(?= |$)", r'\1<span class="keyword">\2</span>', code, flags=re.M)
        parts.append(f'<pre class="gherkin"><code>{code}</code></pre>')
        cells = ''.join(f'<td>{escape(case[key])}</td>' for key in ['title', 'given', 'when', 'then'])
        parts.append(f'<table class="comparison"><thead><tr><th>Original title</th><th>Given</th><th>When</th><th>Then</th></tr></thead><tbody><tr>{cells}</tr></tbody></table>')
        for label, items in [("Execution condition", case.get("conditions", [])), ("Comparison note", case.get("notes", []))]:
            parts.extend(f'<p><strong>{label}:</strong> {escape(item)}</p>' for item in items)
        if case.get("evidence"):
            links = ', '.join(f'<a href="{source_link(ref)}">{escape(ref["file"])}:{ref["line"]}</a>' for ref in case["evidence"])
            parts.append('<p class="meta">Evidence: ' + links + '</p>')
        parts.append('</article>')
    return html_page(data['title'], ''.join(parts), interactive=True)


def sources_report(data, sources):
    parts = ['<h1>Source evidence</h1><p>Excerpts around cited lines; not the entire repository.</p>']
    for source in sources.values():
        start = max(0, source['line'] - 4)
        stop = min(len(source['lines']), source['line'] + 5)
        excerpt = '\n'.join(f'{index + 1}: {source["lines"][index]}' for index in range(start, stop))
        parts.append(f'<section id="{source_anchor(source)}"><h2>{html.escape(source["file"])}:{source["line"]}</h2><pre>{html.escape(excerpt)}</pre></section>')
    return html_page(data['title'] + ' — source evidence', ''.join(parts))


def build(data, output=None):
    declarations, sources = validate(data)
    directory = Path(output) if output else Path(tempfile.mkdtemp(prefix='e2e-spec-report-'))
    if output:
        directory.mkdir(mode=0o700, parents=True, exist_ok=False)
    artifacts = {
        'report.html': html_report(data, declarations),
        'report.md': markdown_report(data, declarations),
        'specification.feature': feature(data, declarations),
        'inventory.csv': csv_report(data, declarations),
        'inventory.json': json.dumps(data, ensure_ascii=False, indent=2) + '\n',
        'sources.html': sources_report(data, sources),
    }
    for name, content in artifacts.items():
        (directory / name).write_text(content)
    return {'directory': str(directory.resolve()), 'cases': len(data['cases']), 'declarations': len(declarations), 'unresolved': len(data.get('unresolved', [])), 'completeLedger': not data.get('unresolved')}


def handler_for(directory):
    class ReportHandler(SimpleHTTPRequestHandler):
        extensions_map = {**SimpleHTTPRequestHandler.extensions_map, '.feature': 'text/plain; charset=utf-8'}

        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=str(directory), **kwargs)

        def allowed(self):
            name = unquote(urlsplit(self.path).path)
            name = 'report.html' if name == '/' else name.removeprefix('/')
            target = directory / name
            if name not in PUBLIC_FILES or not target.resolve().is_relative_to(directory) or not target.is_file():
                self.send_error(404)
                return False
            self.path = '/' + name
            return True

        def do_GET(self):
            if self.allowed():
                super().do_GET()

        def do_HEAD(self):
            if self.allowed():
                super().do_HEAD()

    return ReportHandler


def serve(directory, port=0):
    directory = Path(directory).resolve()
    if not all((directory / name).is_file() for name in PUBLIC_FILES):
        raise ValueError('Expected a generated report directory')
    with ThreadingHTTPServer(('127.0.0.1', port), handler_for(directory)) as server:
        state = {'url': f'http://127.0.0.1:{server.server_port}/report.html', 'pid': os.getpid(), 'directory': str(directory)}
        (directory / 'server.json').write_text(json.dumps(state) + '\n')
        print(json.dumps(state), flush=True)
        server.serve_forever()


def main():
    parser = argparse.ArgumentParser(description='Validate and render source-derived E2E specifications; no test execution.')
    commands = parser.add_subparsers(dest='command', required=True)
    builder = commands.add_parser('build', help='Render an agent-reviewed JSON inventory')
    builder.add_argument('inventory', type=Path)
    builder.add_argument('--cases', type=Path, action='append', default=[], help='JSON case array; repeat for batches; inventory cases must be empty')
    builder.add_argument('--outdir', type=Path, help='New directory; defaults to a private OS temp directory')
    server = commands.add_parser('serve', help='Serve generated files only, on loopback')
    server.add_argument('directory', type=Path)
    server.add_argument('--port', type=int, default=0, help='0 chooses a free port')
    args = parser.parse_args()
    try:
        if args.command == 'build':
            data = json.loads(args.inventory.read_text())
            if args.cases:
                if data.get('cases'):
                    raise ValueError('Keep inventory cases empty when using --cases batches')
                data['cases'] = []
                for batch in args.cases:
                    cases = json.loads(batch.read_text())
                    if not isinstance(cases, list):
                        raise ValueError(f'Expected a JSON case array in {batch}')
                    data['cases'].extend(cases)
            print(json.dumps(build(data, args.outdir)))
        else:
            serve(args.directory, args.port)
    except (ValueError, OSError, KeyError, TypeError) as error:
        parser.exit(2, f'Error: {error}\n')


if __name__ == '__main__':
    main()
