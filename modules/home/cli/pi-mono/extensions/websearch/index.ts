/**
 * Web Search Extension
 *
 * Searches the web using Exa AI API.
 * Requires EXA_API_KEY environment variable.
 */

import { type ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Container, Text } from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";
import type { Exa } from "exa-js";

function getApiKey(): string | undefined {
  return process.env.EXA_API_KEY;
}

function getBaseUrl(): string | undefined {
  return process.env.EXA_ENDPOINT_URL;
}

interface SearchResult {
  title: string;
  url: string;
  author?: string;
  publishedDate?: string;
  text: string;
}

interface WebSearchDetails {
  query: string;
  results: SearchResult[];
  error?: boolean;
}

const DESCRIPTION = `Search the web using Exa AI - performs real-time web searches and returns content from relevant websites.

Usage notes:
- Provides up-to-date information beyond knowledge cutoff
- Supports live crawling modes: 'fallback' (use cached, crawl if unavailable) or 'preferred' (prioritize live)
- Search types: 'auto' (balanced), 'fast' (quick), 'deep' (comprehensive)
- Configurable result count and context length for LLM optimization`;

const WebSearchParams = Type.Object({
  query: Type.String({ description: "Web search query" }),
  numResults: Type.Optional(
    Type.Number({
      description: "Number of search results to return (default: 8)",
    }),
  ),
  livecrawl: Type.Optional(
    Type.Union([Type.Literal("fallback"), Type.Literal("preferred")], {
      description:
        "Live crawl mode - 'fallback': use cached first, 'preferred': prioritize live (default: 'fallback')",
    }),
  ),
  type: Type.Optional(
    Type.Union(
      [Type.Literal("auto"), Type.Literal("fast"), Type.Literal("deep")],
      {
        description:
          "Search type - 'auto': balanced (default), 'fast': quick, 'deep': comprehensive",
      },
    ),
  ),
  contextMaxCharacters: Type.Optional(
    Type.Number({
      description: "Maximum characters for context (default: 10000)",
    }),
  ),
});

const PREVIEW_TEXT_LENGTH = 200;
const PREVIEW_RESULTS = 2;
const DEFAULT_NUM_RESULTS = 8;
const DEFAULT_CONTEXT_MAX = 10000;

function formatResultsAsText(results: SearchResult[]): string {
  return results
    .map((r) => {
      let header = `Title: ${r.title}\nURL: ${r.url}`;
      if (r.author) header += `\nAuthor: ${r.author}`;
      if (r.publishedDate) header += `\nDate: ${r.publishedDate}`;
      return `${header}\n\n${r.text}`;
    })
    .join("\n\n---\n\n");
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "websearch",
    label: "Web Search",
    description: DESCRIPTION,
    parameters: WebSearchParams,

    async execute(_toolCallId, params, onUpdate, _ctx, signal) {
      const apiKey = getApiKey();
      if (!apiKey) {
        return {
          content: [
            { type: "text" as const, text: "Error: EXA_API_KEY not set" },
          ],
          details: {
            query: params.query,
            results: [],
            error: true,
          } as WebSearchDetails,
        };
      }

      const {
        query,
        numResults = DEFAULT_NUM_RESULTS,
        livecrawl = "fallback",
        type = "auto",
        contextMaxCharacters = DEFAULT_CONTEXT_MAX,
      } = params;

      onUpdate?.({
        content: [{ type: "text", text: `Searching: ${query}...` }],
        details: { query, results: [] } as WebSearchDetails,
      });

      try {
        let ExaCtor: typeof Exa;
        try {
          const exaModule = (await import("exa-js")) as unknown as {
            Exa?: typeof Exa;
            default?: typeof Exa;
          };
          ExaCtor =
            exaModule.Exa ??
            exaModule.default ??
            (exaModule as unknown as typeof Exa);
        } catch (error) {
          const message =
            error instanceof Error ? error.message : String(error);
          return {
            content: [
              {
                type: "text" as const,
                text: `Error: failed to load exa-js (${message})`,
              },
            ],
            details: { query, results: [], error: true } as WebSearchDetails,
          };
        }

        const baseUrl = getBaseUrl();
        const exa = baseUrl
          ? new ExaCtor(apiKey, baseUrl)
          : new ExaCtor(apiKey);

        const response = await exa.searchAndContents(query, {
          numResults,
          type,
          livecrawl,
          text: { maxCharacters: contextMaxCharacters },
        });

        if (signal?.aborted) {
          return {
            content: [{ type: "text" as const, text: "Search cancelled" }],
            details: { query, results: [] } as WebSearchDetails,
          };
        }

        const results: SearchResult[] = response.results.map((r) => ({
          title: r.title || "Untitled",
          url: r.url,
          author: r.author || undefined,
          publishedDate: r.publishedDate || undefined,
          text: r.text || "",
        }));

        if (results.length === 0) {
          return {
            content: [
              {
                type: "text" as const,
                text: "No search results found. Try a different query.",
              },
            ],
            details: { query, results: [] } as WebSearchDetails,
          };
        }

        return {
          content: [
            { type: "text" as const, text: formatResultsAsText(results) },
          ],
          details: { query, results } as WebSearchDetails,
        };
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        return {
          content: [{ type: "text" as const, text: `Error: ${message}` }],
          details: { query, results: [], error: true } as WebSearchDetails,
        };
      }
    },

    renderCall(params, theme) {
      let text = theme.fg("toolTitle", theme.bold("websearch "));
      text += theme.fg("accent", params.query || "");
      if (params.type && params.type !== "auto") {
        text += theme.fg("dim", ` [${params.type}]`);
      }
      if (params.numResults) {
        text += theme.fg("dim", ` (${params.numResults} results)`);
      }
      return new Text(text, 0, 0);
    },

    renderResult(result, { expanded, isPartial }, theme) {
      const details = result.details as WebSearchDetails | undefined;

      if (details?.error) {
        const text = result.content[0];
        return new Text(
          theme.fg("error", text?.type === "text" ? text.text : "Error"),
          0,
          0,
        );
      }

      const results: SearchResult[] = details?.results ?? [];

      if (results.length === 0) {
        if (isPartial) return new Text(theme.fg("muted", "Searching..."), 0, 0);
        return new Text(theme.fg("muted", "No results found."), 0, 0);
      }

      const container = new Container();

      container.addChild(
        new Text(
          theme.fg("success", "✓ ") +
            theme.fg("muted", `${results.length} results`),
          0,
          0,
        ),
      );

      const maxResults = expanded
        ? results.length
        : Math.min(PREVIEW_RESULTS, results.length);

      for (let i = 0; i < maxResults; i++) {
        const r = results[i];
        if (!r) continue;

        container.addChild(
          new Text("\n" + theme.fg("dim", theme.bold(r.title)), 0, 0),
        );

        let meta = theme.fg("dim", theme.underline(r.url));
        if (r.author) meta += theme.fg("dim", ` · ${r.author}`);
        if (r.publishedDate)
          meta += theme.fg("dim", ` · ${r.publishedDate.split("T")[0]}`);
        container.addChild(new Text(meta, 0, 0));

        if (r.text) {
          if (expanded) {
            container.addChild(new Text(theme.fg("dim", r.text), 0, 0));
          } else if (r.text.length > PREVIEW_TEXT_LENGTH) {
            const truncated = r.text.slice(0, PREVIEW_TEXT_LENGTH) + "...";
            container.addChild(new Text(theme.fg("dim", truncated), 0, 0));
          } else {
            container.addChild(new Text(theme.fg("dim", r.text), 0, 0));
          }
        }
      }

      const hiddenResults = results.length - maxResults;
      const expandHint =
        theme.fg("dim", "ctrl+o") + theme.fg("muted", " expand");

      if (!expanded && hiddenResults > 0) {
        container.addChild(
          new Text(
            theme.fg("dim", `\n... ${hiddenResults} more, `) + expandHint,
            0,
            0,
          ),
        );
      } else if (
        !expanded &&
        results.some((r) => r.text.length > PREVIEW_TEXT_LENGTH)
      ) {
        container.addChild(new Text(theme.fg("dim", "\n") + expandHint, 0, 0));
      }

      return container;
    },
  });
}
