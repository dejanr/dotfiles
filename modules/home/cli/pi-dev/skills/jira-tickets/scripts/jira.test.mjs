import { test } from 'node:test';
import assert from 'node:assert/strict';
import { connection, createClient, redact, run, validateUpdate } from './jira.mjs';

const env = {
  JIRA_SITE: 'https://example.atlassian.net',
  JIRA_EMAIL: 'user@example.com',
  JIRA_API_TOKEN: 'test-only-secret',
  JIRA_TOKEN_TYPE: 'scoped',
  JIRA_CLOUD_ID: '885940eb-9c52-48ae-bc77-21be8e48d472',
  JIRA_PROJECT: 'CTF',
};

function response(data, status = 200, headers = {}) {
  return new Response(status === 204 ? null : JSON.stringify(data), { status, headers });
}

function mocked(results, payload = { fields: { summary: 'Approved summary' } }) {
  const calls = [];
  const delays = [];
  return {
    calls, delays,
    dependencies: {
      fetchFn: async (url, options) => {
        calls.push({ url, ...options });
        const next = results.shift();
        if (next instanceof Error) throw next;
        assert.ok(next, 'Unexpected API request');
        return next;
      },
      sleepFn: async delay => { delays.push(delay); },
      readFileFn: async () => JSON.stringify(payload),
    },
  };
}

const updateArgs = ['update', 'CTF-7441', '/tmp/approved.json', '--approved', '--expected-updated', 'reviewed-time'];

test('scoped tokens use the gateway and email-based Basic authentication', () => {
  const config = connection(env);
  assert.equal(config.base, `https://api.atlassian.com/ex/jira/${env.JIRA_CLOUD_ID}`);
  assert.equal(config.authorization, `Basic ${Buffer.from(`${env.JIRA_EMAIL}:${env.JIRA_API_TOKEN}`).toString('base64')}`);
});

test('unscoped tokens use the site rather than the gateway', () => {
  assert.equal(connection({ ...env, JIRA_TOKEN_TYPE: 'unscoped', JIRA_CLOUD_ID: undefined }).base, env.JIRA_SITE);
});

test('connection requires credentials, a token type, and a valid scoped cloud ID', () => {
  for (const key of ['JIRA_SITE', 'JIRA_EMAIL', 'JIRA_API_TOKEN', 'JIRA_TOKEN_TYPE', 'JIRA_CLOUD_ID']) {
    assert.throws(() => connection({ ...env, [key]: undefined }));
  }
  assert.throws(() => connection({ ...env, JIRA_TOKEN_TYPE: 'bearer' }));
  assert.throws(() => connection({ ...env, JIRA_CLOUD_ID: '../other-site' }));
});

test('connection rejects unsafe or browser URLs', () => {
  for (const site of ['http://example.atlassian.net', 'https://evil.example', 'https://example.atlassian.net.evil.example',
    'https://user:password@example.atlassian.net', 'https://example.atlassian.net/jira/', 'https://example.atlassian.net?token=123']) {
    assert.throws(() => connection({ ...env, JIRA_SITE: site }));
  }
});

test('help does not need credentials or network access', async () => {
  assert.match(await run(['--help'], {}), /Usage:/);
});

test('check probes identity and project independently without returning account data', async () => {
  const mock = mocked([response({ message: 'Unauthorized; scope does not match' }, 401), response({ key: 'CTF' })]);
  const result = await run(['check'], env, mock.dependencies);
  assert.equal(result.ok, false);
  assert.equal(result.writeAccessTested, false);
  assert.equal(result.probes[0].ok, false);
  assert.equal(result.probes[1].status, 200);
  assert.equal(mock.calls.length, 2);
  assert.equal(mock.delays.length, 0);
});

test('view selects fields, preserves raw ADF, and blocks redirects', async () => {
  const description = { type: 'doc', version: 1, content: [{ type: 'paragraph', content: [{ type: 'text', text: 'Ticket text' }] }] };
  const mock = mocked([response({ key: 'CTF-7441', fields: { description } })]);
  const result = await run(['view', 'ctf-7441', '--fields', 'summary,description,updated'], env, mock.dependencies);
  assert.deepEqual(result.issue.fields.description, description);
  assert.equal(result.url, 'https://example.atlassian.net/browse/CTF-7441');
  assert.equal(new URL(mock.calls[0].url).searchParams.get('fields'), 'summary,description,updated');
  assert.equal(mock.calls[0].redirect, 'error');
  assert.ok(mock.calls[0].signal instanceof AbortSignal);
});

test('search follows enhanced-search tokens and stops at the requested result limit', async () => {
  const mock = mocked([
    response({ issues: [{ key: 'CTF-1' }], isLast: false, nextPageToken: 'page-two' }),
    response({ issues: [{ key: 'CTF-2' }], isLast: false, nextPageToken: 'page-three' }),
  ]);
  const result = await run(['search', 'project = CTF', '--limit', '2'], env, mock.dependencies);
  assert.equal(result.issues.length, 2);
  assert.equal(result.truncated, true);
  assert.equal(result.nextPageToken, 'page-three');
  assert.ok(mock.calls.every(call => call.url.endsWith('/rest/api/3/search/jql') && call.method === 'POST'));
  assert.equal(JSON.parse(mock.calls[1].body).nextPageToken, 'page-two');
  assert.equal(JSON.parse(mock.calls[1].body).maxResults, 1);
});

test('search reports complete results, including an empty final page', async () => {
  const mock = mocked([response({ issues: [], isLast: true })]);
  assert.deepEqual(await run(['search', 'project = CTF'], env, mock.dependencies), { issues: [], truncated: false });
});

test('search fails rather than silently truncating broken pagination', async () => {
  const mock = mocked([
    response({ issues: [], isLast: false, nextPageToken: 'same' }),
    response({ issues: [], isLast: false, nextPageToken: 'same' }),
  ]);
  await assert.rejects(run(['search', 'project = CTF'], env, mock.dependencies), /missing or repeated/);
  const missing = mocked([response({ issues: [], isLast: false })]);
  await assert.rejects(run(['search', 'project = CTF'], env, missing.dependencies), /missing or repeated/);
});

test('invalid arguments fail without network access', async () => {
  const mock = mocked([]);
  for (const args of [['view', '../CTF-1'], ['view', 'CTF-1', '--fields', '*all'], ['search', ''],
    ['search', 'project = CTF', '--limit', '0'], ['search', 'project = CTF', '--limit', '1001'],
    ['search', 'project = CTF', '--limit', 'NaN'], ['view', 'CTF-1', '--approved'], ['unknown'], ['toString']]) {
    await assert.rejects(run(args, env, mock.dependencies));
  }
  assert.equal(mock.calls.length, 0);
});

test('transient read errors retry at most twice', async () => {
  const mock = mocked([response({}, 503), response({}, 502), response({ key: 'CTF-1' })]);
  await run(['view', 'CTF-1'], env, mock.dependencies);
  assert.deepEqual(mock.delays, [500, 1000]);
  assert.equal(mock.calls.length, 3);
  const exhausted = mocked([response({}, 503), response({}, 503), response({}, 503)]);
  await assert.rejects(run(['view', 'CTF-1'], env, exhausted.dependencies), /HTTP 503/);
  assert.equal(exhausted.calls.length, 3);
});

test('read-only search POSTs retry, but long Retry-After delays do not retry early', async () => {
  const mock = mocked([response({}, 429, { 'Retry-After': '1' }), response({ issues: [], isLast: true })]);
  await run(['search', 'project = CTF'], env, mock.dependencies);
  assert.deepEqual(mock.delays, [1000]);
  const longDelay = mocked([response({}, 429, { 'Retry-After': '60' })]);
  await assert.rejects(run(['view', 'CTF-1'], env, longDelay.dependencies), /HTTP 429/);
  assert.equal(longDelay.calls.length, 1);
});

test('network read failures retry, while malformed responses and permanent errors do not', async () => {
  const mock = mocked([new Error('offline'), response({ key: 'CTF-1' })]);
  await run(['view', 'CTF-1'], env, mock.dependencies);
  assert.equal(mock.calls.length, 2);
  for (const failure of [new Response('<html>login</html>'), response({}, 403)]) {
    const permanent = mocked([failure]);
    await assert.rejects(run(['view', 'CTF-1'], env, permanent.dependencies));
    assert.equal(permanent.calls.length, 1);
  }
});

test('errors redact both the token and encoded credentials and omit unrelated response data', async () => {
  const encoded = Buffer.from(`${env.JIRA_EMAIL}:${env.JIRA_API_TOKEN}`).toString('base64');
  assert.equal(redact(`${encoded} ${env.JIRA_API_TOKEN}`, env), '[REDACTED] [REDACTED]');
  const mock = mocked([response({ message: env.JIRA_API_TOKEN, errors: { auth: encoded }, unrelated: 'private-value' }, 403)]);
  await assert.rejects(run(['view', 'CTF-1'], env, mock.dependencies), error => {
    assert.ok(!error.message.includes(env.JIRA_API_TOKEN));
    assert.ok(!error.message.includes(encoded));
    assert.ok(!error.message.includes('private-value'));
    return true;
  });
});

test('updates require the approval flag and reviewed timestamp before any request', async () => {
  const mock = mocked([]);
  for (const args of [['update', 'CTF-1', 'payload.json'], ['update', 'CTF-1', 'payload.json', '--approved'],
    ['update', 'CTF-1', 'payload.json', '--expected-updated', 'reviewed-time']]) {
    await assert.rejects(run(args, env, mock.dependencies), /require --approved/);
  }
  assert.equal(mock.calls.length, 0);
});

test('update payloads accept only changed fields and preserve ADF', () => {
  for (const payload of [null, [], {}, { fields: {} }, { fields: [], update: {} },
    { fields: { summary: 'Title' }, extra: true }, { fields: { status: { id: '1' } } }, { fields: { description: 'plain text' } }]) {
    assert.throws(() => validateUpdate(payload));
  }
  const description = { type: 'doc', version: 1, content: [] };
  assert.deepEqual(validateUpdate({ fields: { description } }), ['description']);
  assert.deepEqual(validateUpdate({ fields: { description: null } }), ['description']);
});

test('stale review timestamps prevent writes', async () => {
  const mock = mocked([response({ fields: { updated: 'new-time' } })]);
  await assert.rejects(run(updateArgs, env, mock.dependencies), /changed since review/);
  assert.equal(mock.calls.length, 1);
  assert.equal(mock.calls[0].method, 'GET');
});

test('approved updates send exactly the payload once and fetch changed fields for verification', async () => {
  const payload = { fields: { summary: 'Approved summary', description: { type: 'doc', version: 1, content: [] } } };
  const mock = mocked([
    response({ fields: { updated: 'reviewed-time' } }), response(null, 204),
    response({ key: 'CTF-7441', fields: { ...payload.fields, updated: 'saved-time' } }),
  ], payload);
  const result = await run(updateArgs, env, mock.dependencies);
  assert.equal(mock.calls[1].method, 'PUT');
  assert.deepEqual(JSON.parse(mock.calls[1].body), payload);
  assert.equal(new URL(mock.calls[2].url).searchParams.get('fields'), 'summary,description,updated');
  assert.deepEqual(result.issue.fields.description, payload.fields.description);
  assert.equal(mock.calls.filter(call => call.method === 'PUT').length, 1);
});

test('write failures and rate limits never retry', async () => {
  for (const failure of [new Error('timeout'), response({}, 503), response({}, 429, { 'Retry-After': '1' })]) {
    const mock = mocked([response({ fields: { updated: 'reviewed-time' } }), failure]);
    await assert.rejects(run(updateArgs, env, mock.dependencies));
    assert.equal(mock.calls.filter(call => call.method === 'PUT').length, 1);
    assert.equal(mock.delays.length, 0);
  }
});

test('failed verification after a successful write clearly reports that the update was accepted', async () => {
  const mock = mocked([response({ fields: { updated: 'reviewed-time' } }), response(null, 204), response({}, 403)]);
  await assert.rejects(run(updateArgs, env, mock.dependencies), /accepted the update, but verification failed/);
  assert.equal(mock.calls.filter(call => call.method === 'PUT').length, 1);
});

test('the client rejects paths outside Jira REST v3', async () => {
  await assert.rejects(createClient(env).request('https://evil.example'), /Unsupported/);
});
