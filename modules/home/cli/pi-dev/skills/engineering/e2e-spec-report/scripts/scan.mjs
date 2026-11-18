import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';

const ignored = new Set(['node_modules', '.git', 'dist', 'build', 'coverage', 'playwright-report', 'test-results']);

function filesUnder(folder) {
  return fs.readdirSync(folder, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name)).flatMap(entry => {
    const target = path.join(folder, entry.name);
    if (entry.isSymbolicLink() || ignored.has(entry.name)) return [];
    if (entry.isDirectory()) return filesUnder(target);
    return /\.(spec|e2e|smoke|test)\.[cm]?[jt]sx?$/.test(entry.name) ? [target] : [];
  });
}

export async function compilerFor(folder, explicit, files) {
  const candidates = explicit ? [path.resolve(explicit)] : [];
  if (!explicit) {
    for (const directory of new Set([folder, ...(files ?? filesUnder(folder)).map(file => path.dirname(file))])) {
      try {
        candidates.push(createRequire(path.join(directory, '__skill_resolve__.cjs')).resolve('typescript'));
      } catch {}
    }
  }
  if (!candidates.length) throw new Error('TypeScript compiler not found. Pass --typescript /path/to/typescript.js; no packages are installed automatically.');
  const imported = await import(pathToFileURL(candidates[0]).href);
  return imported.default ?? imported;
}

export function scan(folder, repoRoot, ts) {
  const root = fs.realpathSync(repoRoot);
  const scope = fs.realpathSync(folder);
  const relative = file => path.relative(root, file).split(path.sep).join('/');
  if (relative(scope).startsWith('../') || relative(scope) === '..') throw new Error('Folder must be inside --repo.');
  const result = { version: 1, title: path.basename(scope) + ' E2E specification', repoRoot: root, scope: relative(scope) || '.', snapshot: '', files: [], declarations: [], registrations: [], registrationReviews: [], unresolved: [], cases: [] };
  for (const file of filesUnder(scope)) {
    const text = fs.readFileSync(file, 'utf8');
    const source = ts.createSourceFile(file, text, ts.ScriptTarget.Latest, true);
    const aliases = new Set();
    const imports = [];
    for (const statement of source.statements) {
      if (!ts.isImportDeclaration(statement)) continue;
      const bindings = statement.importClause?.namedBindings;
      const module = statement.moduleSpecifier.text;
      imports.push({ module, bindings: bindings?.getText(source) ?? '' });
      if (!['@jest/globals', 'node:test'].includes(module) && bindings && ts.isNamedImports(bindings)) {
        for (const binding of bindings.elements) {
          if ((binding.propertyName ?? binding.name).text === 'test') aliases.add(binding.name.text);
        }
      }
      if (module === '@playwright/test' && bindings && ts.isNamespaceImport(bindings)) aliases.add(bindings.name.text + '.test');
    }
    function findAliases(node) {
      if (ts.isVariableDeclaration(node) && ts.isIdentifier(node.name) && node.initializer && ts.isCallExpression(node.initializer)) {
        const expression = node.initializer.expression.getText(source);
        if ([...aliases].some(alias => expression === alias + '.extend')) aliases.add(node.name.text);
      }
      ts.forEachChild(node, findAliases);
    }
    findAliases(source);
    const entry = { file: relative(file), imports, review: '' };
    result.files.push(entry);
    function location(node) {
      const position = source.getLineAndCharacterOfPosition(node.getStart(source));
      return { file: entry.file, line: position.line + 1, column: position.character + 1 };
    }
    function visit(node, suites = [], loops = []) {
      let currentSuites = suites;
      let currentLoops = loops;
      if (ts.isForOfStatement(node)) currentLoops = [...loops, { binding: node.initializer.getText(source), expression: node.expression.getText(source) }];
      if (ts.isCallExpression(node)) {
        const expression = node.expression.getText(source);
        const callback = node.arguments.find(argument => ts.isArrowFunction(argument) || ts.isFunctionExpression(argument));
        const alias = [...aliases].sort((a, b) => b.length - a.length).find(name => expression === name || expression.startsWith(name + '.'));
        const method = alias ? expression.slice(alias.length) : undefined;
        if (callback && alias && ['', '.skip', '.only', '.fixme', '.fail'].includes(method)) {
          const sourceLocation = location(node);
          result.declarations.push({ id: `${sourceLocation.file}:${sourceLocation.line}:${sourceLocation.column}`, source: sourceLocation, modifier: method, titleExpression: node.arguments[0].getText(source), suites, loops, status: ['.skip', '.fixme'].includes(method) || suites.some(suite => suite.skipped) ? 'skipped' : 'declared' });
          return;
        }
        if (callback && alias && /^\.describe(?:\.(?:parallel|serial))?(?:\.(?:skip|only|fixme))?$/.test(method)) {
          currentSuites = [...suites, { titleExpression: node.arguments[0].getText(source), skipped: method.endsWith('.skip') || method.endsWith('.fixme') }];
        }
        if (callback && ts.isPropertyAccessExpression(node.expression) && node.expression.name.text === 'forEach') {
          currentLoops = [...loops, { binding: callback.parameters.map(parameter => parameter.getText(source)).join(', '), expression: node.expression.expression.getText(source) }];
        }
        if (!alias && node.arguments.some(argument => aliases.has(argument.getText(source)))) {
          const sourceLocation = location(node);
          result.registrations.push({ id: `${sourceLocation.file}:${sourceLocation.line}:${sourceLocation.column}`, source: sourceLocation, expression: expression, review: '' });
        }
      }
      ts.forEachChild(node, child => visit(child, currentSuites, currentLoops));
    }
    visit(source);
    entry.directDeclarations = result.declarations.filter(declaration => declaration.source.file === entry.file).length;
  }
  return result;
}

async function main(args) {
  if (!args.length || args.includes('--help')) {
    console.log('Usage: node scan.mjs <folder> --repo <repository-root> [--typescript <typescript.js>] [--output <new-manifest.json>]');
    return;
  }
  const folder = path.resolve(args[0]);
  const options = {};
  for (let index = 1; index < args.length; index += 2) {
    if (!['--repo', '--typescript', '--output'].includes(args[index]) || !args[index + 1]) throw new Error('Unknown or incomplete option: ' + args[index]);
    options[args[index].slice(2)] = args[index + 1];
  }
  if (!options.repo) throw new Error('--repo is required.');
  const ts = await compilerFor(folder, options.typescript);
  const manifest = scan(folder, options.repo, ts);
  const json = JSON.stringify(manifest, null, 2) + '\n';
  if (options.output) {
    fs.writeFileSync(options.output, json, { flag: 'wx' });
    console.log(JSON.stringify({ manifest: path.resolve(options.output), files: manifest.files.length, directDeclarations: manifest.declarations.length, registrationCandidates: manifest.registrations.length }));
  } else process.stdout.write(json);
}

if (process.argv[1] && pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url) {
  main(process.argv.slice(2)).catch(error => { console.error(error.message); process.exitCode = 1; });
}
