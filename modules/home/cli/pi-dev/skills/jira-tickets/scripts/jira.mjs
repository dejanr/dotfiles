import { readFile } from 'node:fs/promises';
import { parseArgs } from 'node:util';
import { setTimeout as sleep } from 'node:timers/promises';

const help = `Usage: node jira.mjs check
       node jira.mjs view KEY [--fields summary,description,status,updated]
       node jira.mjs search 'JQL' [--fields summary,status,updated] [--limit 50]
       node jira.mjs update KEY payload.json --approved --expected-updated TIMESTAMP

Environment: JIRA_SITE, JIRA_EMAIL, JIRA_TOKEN_TYPE (scoped|unscoped),
             JIRA_CLOUD_ID (scoped only), JIRA_PROJECT (check only), JIRA_API_TOKEN.
Updates require prior approval of the exact payload. Writes are never retried.`;

export function redact(message, env) {
  let text = String(message);
  const token = env.JIRA_API_TOKEN;
  if (token) {
    const credentials = Buffer.from(`${env.JIRA_EMAIL}:${token}`).toString('base64');
    for (const secret of [credentials, token]) text = text.replaceAll(secret, '[REDACTED]');
  }
  return text;
}

export function connection(env) {
  for (const key of ['JIRA_SITE', 'JIRA_EMAIL', 'JIRA_API_TOKEN', 'JIRA_TOKEN_TYPE']) {
    if (!env[key]?.trim()) throw new Error(`${key} is required.`);
  }
  const site = new URL(env.JIRA_SITE);
  if (site.protocol !== 'https:' || !site.hostname.endsWith('.atlassian.net') ||
      site.username || site.password || site.port || site.pathname !== '/' || site.search || site.hash) {
    throw new Error('JIRA_SITE must be an HTTPS Atlassian Cloud site without a path or credentials.');
  }
  let base;
  if (env.JIRA_TOKEN_TYPE === 'scoped') {
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(env.JIRA_CLOUD_ID ?? '')) {
      throw new Error('Scoped tokens require a valid JIRA_CLOUD_ID.');
    }
    base = `https://api.atlassian.com/ex/jira/${env.JIRA_CLOUD_ID}`;
  } else if (env.JIRA_TOKEN_TYPE === 'unscoped') {
    base = site.origin;
  } else {
    throw new Error('JIRA_TOKEN_TYPE must be scoped or unscoped.');
  }
  return {
    base,
    site: site.origin,
    authorization: `Basic ${Buffer.from(`${env.JIRA_EMAIL}:${env.JIRA_API_TOKEN}`).toString('base64')}`,
  };
}

function retryDelay(response, attempt) {
  const value = response.headers.get('retry-after');
  if (!value) return 500 * 2 ** attempt;
  const seconds = Number(value);
  const milliseconds = Number.isFinite(seconds) ? seconds * 1000 : Date.parse(value) - Date.now();
  return Number.isFinite(milliseconds) && milliseconds >= 0 && milliseconds <= 5000 ? milliseconds : null;
}

export function createClient(env, { fetchFn = fetch, sleepFn = sleep } = {}) {
  const config = connection(env);
  async function request(path, { method = 'GET', body, readOnly = method === 'GET' } = {}) {
    if (!path.startsWith('/rest/api/3/')) throw new Error('Unsupported Jira API path.');
    for (let attempt = 0; ; attempt++) {
      let response;
      let text;
      try {
        response = await fetchFn(config.base + path, {
          method,
          headers: { Authorization: config.authorization, Accept: 'application/json', 'Content-Type': 'application/json' },
          body: body === undefined ? undefined : JSON.stringify(body),
          redirect: 'error',
          signal: AbortSignal.timeout(20_000),
        });
        text = await response.text();
      } catch {
        if (readOnly && attempt < 2) {
          await sleepFn(500 * 2 ** attempt);
          continue;
        }
        throw new Error(readOnly ? 'Jira read failed after bounded retries.' :
          'Jira write outcome is uncertain. Read the issue before resubmitting; no write retry occurred.');
      }
      if (readOnly && attempt < 2 && [429, 502, 503, 504].includes(response.status)) {
        const delay = retryDelay(response, attempt);
        if (delay !== null) {
          await sleepFn(delay);
          continue;
        }
      }
      let data;
      try { data = text ? JSON.parse(text) : null; } catch { data = null; }
      if (!response.ok) {
        const details = data && typeof data === 'object'
          ? Object.fromEntries(['message', 'errorMessages', 'errors', 'code'].filter(key => key in data).map(key => [key, data[key]]))
          : {};
        const uncertain = !readOnly && response.status >= 500
          ? ' Write outcome may be uncertain; read the issue before resubmitting.' : '';
        throw new Error(redact(`Jira HTTP ${response.status}: ${JSON.stringify(details)}${uncertain}`, env));
      }
      if (response.status !== 204 && data === null) throw new Error('Jira returned an invalid JSON response.');
      return data;
    }
  }
  return { request, site: config.site };
}

function issueKey(value) {
  if (!/^[A-Z][A-Z0-9_]*-[1-9][0-9]*$/i.test(value ?? '')) throw new Error('A valid issue key is required.');
  return value.toUpperCase();
}

function fieldsList(value) {
  const fields = value.split(',').map(field => field.trim());
  if (fields.some(field => !/^[A-Za-z][A-Za-z0-9_]*$/.test(field))) throw new Error('Select explicit, comma-separated field IDs.');
  return [...new Set(fields)];
}

export function validateUpdate(payload) {
  if (!payload || typeof payload !== 'object' || Array.isArray(payload) ||
      Object.keys(payload).length !== 1 || !payload.fields || typeof payload.fields !== 'object' || Array.isArray(payload.fields)) {
    throw new Error('Update payload must contain only a fields object.');
  }
  const fields = Object.keys(payload.fields);
  if (!fields.length) throw new Error('Update payload has no changed fields.');
  fieldsList(fields.join(','));
  if ('status' in payload.fields) throw new Error('Status changes require the transitions API.');
  const description = payload.fields.description;
  if ('description' in payload.fields && description !== null &&
      (!description || description.type !== 'doc' || description.version !== 1 || !Array.isArray(description.content))) {
    throw new Error('Description must be an ADF document or null.');
  }
  return fields;
}

export async function run(args, env = process.env, dependencies = {}) {
  if (!args.length || args[0] === '--help' || args[0] === '-h') return help;
  const [command, ...rest] = args;
  const optionSets = {
    check: {},
    view: { fields: { type: 'string' } },
    search: { fields: { type: 'string' }, limit: { type: 'string' } },
    update: { approved: { type: 'boolean' }, 'expected-updated': { type: 'string' } },
  };
  if (!Object.hasOwn(optionSets, command)) throw new Error(help);
  const { values, positionals } = parseArgs({ args: rest, options: optionSets[command], allowPositionals: true });
  const expectedCount = { check: 0, view: 1, search: 1, update: 2 }[command];
  if (positionals.length !== expectedCount) throw new Error(help);
  if (command === 'update' && (!values.approved || !values['expected-updated'])) {
    throw new Error('Updates require --approved and --expected-updated after review and explicit user approval.');
  }
  const { request, site } = createClient(env, dependencies);
  const view = (key, fields) => request(`/rest/api/3/issue/${key}?fields=${encodeURIComponent(fields.join(','))}`);

  if (command === 'check') {
    if (!/^[A-Z][A-Z0-9_]*$/i.test(env.JIRA_PROJECT ?? '')) throw new Error('JIRA_PROJECT is required for check.');
    const probes = [];
    for (const [name, path] of [['identity', '/rest/api/3/myself'], ['project', `/rest/api/3/project/${env.JIRA_PROJECT}`]]) {
      try {
        await request(path);
        probes.push({ name, ok: true, status: 200 });
      } catch (error) {
        probes.push({ name, ok: false, error: redact(error.message, env) });
      }
    }
    return { ok: probes.every(probe => probe.ok), probes, writeAccessTested: false };
  }

  if (command === 'view') {
    const key = issueKey(positionals[0]);
    const fields = fieldsList(values.fields ?? 'summary,description,status,issuetype,project,updated');
    return { url: `${site}/browse/${key}`, issue: await view(key, fields) };
  }

  if (command === 'search') {
    if (!positionals[0].trim()) throw new Error('An explicit JQL query is required.');
    const limit = Number(values.limit ?? 50);
    if (!Number.isSafeInteger(limit) || limit < 1 || limit > 1000) throw new Error('--limit must be between 1 and 1000.');
    const fields = fieldsList(values.fields ?? 'summary,status,issuetype,project,updated');
    const issues = [];
    const seen = new Set();
    let nextPageToken;
    let complete = false;
    for (let page = 0; issues.length < limit; page++) {
      if (page >= 100) throw new Error('Search exceeded 100 pages; narrow the JQL query.');
      const data = await request('/rest/api/3/search/jql', {
        method: 'POST', readOnly: true,
        body: { jql: positionals[0], fields, maxResults: Math.min(100, limit - issues.length), ...(nextPageToken ? { nextPageToken } : {}) },
      });
      if (!Array.isArray(data?.issues)) throw new Error('Invalid Jira search response.');
      issues.push(...data.issues.slice(0, limit - issues.length));
      complete = data.isLast === true;
      nextPageToken = data.nextPageToken;
      if (complete) break;
      if (!nextPageToken || seen.has(nextPageToken)) throw new Error('Search pagination token is missing or repeated.');
      seen.add(nextPageToken);
    }
    return { issues, truncated: !complete, ...(complete ? {} : { nextPageToken }) };
  }

  const key = issueKey(positionals[0]);
  const payload = JSON.parse(await (dependencies.readFileFn ?? readFile)(positionals[1], 'utf8'));
  const changedFields = validateUpdate(payload);
  const current = await view(key, ['updated']);
  if (current?.fields?.updated !== values['expected-updated']) {
    throw new Error('Issue changed since review. Read the current issue and obtain approval again.');
  }
  await request(`/rest/api/3/issue/${key}`, { method: 'PUT', body: payload });
  try {
    return { url: `${site}/browse/${key}`, issue: await view(key, [...new Set([...changedFields, 'updated'])]) };
  } catch {
    throw new Error('Jira accepted the update, but verification failed. Read the issue; do not repeat the write.');
  }
}

if (import.meta.main) {
  try {
    const result = await run(process.argv.slice(2));
    console.log(typeof result === 'string' ? result : JSON.stringify(result, null, 2));
    if (result?.ok === false) process.exitCode = 1;
  } catch (error) {
    console.error(redact(error.message, process.env));
    process.exitCode = 1;
  }
}
