import copy
import csv
from html.parser import HTMLParser
import io
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest
from urllib.error import HTTPError
from urllib.request import Request, urlopen

from report import build, validate


class GherkinBlocks(HTMLParser):
    def __init__(self):
        super().__init__()
        self.active = False
        self.blocks = []

    def handle_starttag(self, tag, attrs):
        if tag == 'pre' and dict(attrs).get('class') == 'gherkin':
            self.active = True
            self.blocks.append('')

    def handle_endtag(self, tag):
        if tag == 'pre':
            self.active = False

    def handle_data(self, content):
        if self.active:
            self.blocks[-1] += content


class ReportTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        source = self.root / 'specs/example.spec.ts'
        source.parent.mkdir()
        source.write_text("test('example', async () => {});\nhelper();\n")
        self.data = {
            'version': 1, 'title': 'Example <script>title</script>',
            'repoRoot': str(self.root), 'scope': 'specs', 'snapshot': 'abc123 dirty',
            'files': [{'file': 'specs/example.spec.ts', 'review': 'Playwright entry inspected.'}],
            'declarations': [{'id': 'decl-1', 'source': {'file': 'specs/example.spec.ts', 'line': 1},
                              'titleExpression': "'original'", 'status': 'declared'}],
            'registrations': [], 'registrationReviews': [], 'unresolved': [],
            'cases': [{'id': 'CASE-001.1', 'declaration': 'decl-1',
                       'title': ' original | `name` <script>alert(1)</script> @tag ',
                       'suite': ['Desktop'], 'status': 'declared', 'parameters': {'brand': 'example'},
                       'given': 'A cart contains "é", <script> and |.',
                       'when': 'Save once, then reopen.',
                       'then': 'The stored value matches.',
                       'conditions': ['Only in the selected environment.'],
                       'notes': ['The title overstates the assertion.'],
                       'evidence': [{'file': 'specs/example.spec.ts', 'line': 2}]}],
        }

    def render(self, data=None):
        result = build(self.data if data is None else data, self.root / 'output')
        return Path(result['directory'])

    def test_exports_keep_exact_titles_and_steps(self):
        directory = self.render()
        rows = list(csv.DictReader(io.StringIO((directory / 'inventory.csv').read_text())))
        case = self.data['cases'][0]
        self.assertEqual(rows[0]['originalTitle'], case['title'])
        feature = (directory / 'specification.feature').read_text()
        markdown = (directory / 'report.md').read_text()
        parser = GherkinBlocks()
        rendered = (directory / 'report.html').read_text()
        parser.feed(rendered)
        for key, keyword in [('given', 'Given'), ('when', 'When'), ('then', 'Then')]:
            self.assertEqual(rows[0][key], case[key])
            self.assertIn(f'      {keyword} {case[key]}\n', feature)
            self.assertIn(f'  {keyword} {case[key]}', markdown)
            self.assertIn(f'  {keyword} {case[key]}', parser.blocks[0])
        self.assertEqual(json.loads((directory / 'inventory.json').read_text()), self.data)
        self.assertNotIn('<script>alert(1)</script>', rendered)
        self.assertIn('&lt;script&gt;alert(1)&lt;/script&gt;', rendered)
        self.assertIn('Snapshot: abc123 dirty', rendered)
        self.assertIn('Source inspection only', rendered)

    def test_missing_declaration_cannot_be_silently_omitted(self):
        self.data['cases'] = []
        with self.assertRaisesRegex(ValueError, 'without cases'):
            self.render()
        self.assertFalse((self.root / 'output').exists())

    def test_unresolved_variants_produce_an_explicit_partial_report(self):
        self.data['cases'] = []
        self.data['unresolved'] = [{'id': 'decl-1', 'reason': 'Runtime-only data source.'}]
        result = build(self.data, self.root / 'output')
        self.assertFalse(result['completeLedger'])
        self.assertEqual(result['unresolved'], 1)
        self.assertIn('Incomplete inventory', (self.root / 'output/report.html').read_text())
        self.assertIn('Unresolved decl-1: Runtime-only data source.', (self.root / 'output/specification.feature').read_text())

    def test_every_file_and_registration_need_review(self):
        self.data['files'][0]['review'] = ''
        with self.assertRaisesRegex(ValueError, 'review'):
            validate(self.data)
        self.data['files'][0]['review'] = 'Inspected.'
        self.data['registrations'] = [{'id': 'registry', 'source': {'file': 'specs/example.spec.ts', 'line': 2}}]
        with self.assertRaisesRegex(ValueError, 'registration candidate'):
            validate(self.data)
        self.data['registrationReviews'] = [{'id': 'registry', 'resolution': 'No additional tests.'}]
        validate(self.data)

    def test_static_skips_survive_expansion(self):
        self.data['declarations'][0]['status'] = 'skipped'
        with self.assertRaisesRegex(ValueError, 'Inherited skip'):
            validate(self.data)
        self.data['cases'][0]['status'] = 'skipped'
        directory = self.render()
        self.assertIn('1 statically skipped', (directory / 'report.html').read_text())
        self.assertIn('Status: skipped', (directory / 'specification.feature').read_text())

    def test_duplicate_ids_and_duplicate_titles_are_rejected(self):
        self.data['cases'].append(copy.deepcopy(self.data['cases'][0]))
        with self.assertRaisesRegex(ValueError, 'duplicate case id'):
            validate(self.data)
        self.data['cases'][1]['id'] = 'CASE-002'
        with self.assertRaisesRegex(ValueError, 'Duplicate case title'):
            validate(self.data)
        self.data['cases'][1]['suite'] = ['Mobile']
        validate(self.data)

    def test_invalid_sources_and_step_injection_are_rejected(self):
        original = copy.deepcopy(self.data)
        for file, line in [('../escape.spec.ts', 1), ('/absolute.spec.ts', 1), ('specs/example.spec.ts', 1000)]:
            self.data = copy.deepcopy(original)
            self.data['declarations'][0]['source'] = {'file': file, 'line': line}
            self.data['files'][0]['file'] = file
            with self.assertRaises(ValueError):
                validate(self.data)
        self.data = original
        self.data['cases'][0]['given'] = 'One step.\nThen injected step.'
        with self.assertRaisesRegex(ValueError, 'single-line'):
            validate(self.data)

    def test_source_symlink_cannot_escape_repository(self):
        with tempfile.TemporaryDirectory() as outside:
            target = Path(outside) / 'secret.ts'
            target.write_text('secret')
            (self.root / 'specs/link.ts').symlink_to(target)
            self.data['files'][0]['file'] = 'specs/link.ts'
            with self.assertRaisesRegex(ValueError, 'escaping'):
                validate(self.data)

    def test_build_never_overwrites_existing_output(self):
        directory = self.render()
        before = (directory / 'inventory.json').read_text()
        with self.assertRaises(FileExistsError):
            build(self.data, directory)
        self.assertEqual((directory / 'inventory.json').read_text(), before)

    def test_case_batches_use_the_same_canonical_model(self):
        inventory = self.root / 'manifest.json'
        batch = self.root / 'cases.json'
        batch.write_text(json.dumps(self.data['cases']))
        self.data['cases'] = []
        inventory.write_text(json.dumps(self.data))
        result = subprocess.run([sys.executable, str(Path(__file__).with_name('report.py')), 'build',
                                 str(inventory), '--cases', str(batch), '--outdir', str(self.root / 'output')],
                                check=True, capture_output=True, text=True)
        self.assertEqual(json.loads(result.stdout)['cases'], 1)

    def test_server_only_serves_artifacts_and_binds_loopback(self):
        directory = self.render()
        (directory / 'secret.txt').write_text('not public')
        process = subprocess.Popen([sys.executable, str(Path(__file__).with_name('report.py')),
                                    'serve', str(directory), '--port', '0'],
                                   stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        try:
            state = json.loads(process.stdout.readline())
            self.assertTrue(state['url'].startswith('http://127.0.0.1:'))
            base = state['url'].removesuffix('report.html')
            with urlopen(state['url']) as response:
                self.assertEqual(response.status, 200)
            with urlopen(Request(base + 'specification.feature', method='HEAD')) as response:
                self.assertEqual(response.status, 200)
            for blocked in ['secret.txt', 'server.json', 'server.log', '%2e%2e/secret.txt']:
                with self.assertRaises(HTTPError) as error:
                    urlopen(base + blocked)
                self.assertEqual(error.exception.code, 404)
                error.exception.close()
            outside = self.root / 'outside.html'
            outside.write_text('private')
            (directory / 'sources.html').unlink()
            (directory / 'sources.html').symlink_to(outside)
            with self.assertRaises(HTTPError) as error:
                urlopen(base + 'sources.html')
            error.exception.close()
        finally:
            process.terminate()
            process.wait(timeout=5)
            process.stdout.close()


if __name__ == '__main__':
    unittest.main()
