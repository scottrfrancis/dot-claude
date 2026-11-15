# Announcing Project Action Items to Beaufort

Beaufort, on hasami, is Scott's chief of staff. It keeps one list of everything he owes across
projects and clients. Each project still owns its `ACTION_ITEMS.md` and every detail in it.
Beaufort holds a headline, a short summary and a link back, and never the details (ADR-0001,
decision 5, in the beaufort repo).

A project agent that adds or finds one of Scott's open items announces it to Beaufort through
the `beaufort` MCP server. All writes to Scott's mail, calendars and TODO list go through that
server.

## What to announce

- Open items that Scott owns, alone or with someone else. Blocked and waiting items count.
- Announce an item when you create it. The first time you work in a project whose items have
  never been announced, announce its open items in one pass.

Leave out:

- items owned only by someone else;
- done and dropped items;
- items the project file already links to Beaufort (it cites a `BL-` id);
- anything from Scott's employer's systems or its clients' work. Beaufort excludes those
  domains, and the project should not route around that.

## How

Call `todo_add` on the `beaufort` MCP server.

| Field | Rule |
|---|---|
| `project` | The project's short, stable name: usually the repo name, lower case. 1 to 64 of `A-Z a-z 0-9 . _ -` |
| `item_id` | The item's own stable id from the project file, such as `AI-177`. If items have no ids, add them to the project file first. Never derive an id from the item's text: text changes, and the id is what dedupes |
| `headline` | One line, at most 200 characters, no `\|`. It should make sense in a list without opening the project |
| `summary` | One line, at most 500 characters, no `\|`. What done looks like, or what it waits on |
| `link` | An `http(s)` URL to the item or its file, such as the GitHub blob URL. Leave it empty for repos with no web view |
| `due` | `YYYY-MM-DD`, only when the item has a date |
| `request_id` | `<project>:<item_id>` |

Beaufort dedupes on project and item id. Announcing the same item twice returns the existing
`BL-` id with `created: false`, so a retry after a dropped connection is safe.

After a successful call, write the `BL-` id next to the item in the project file ("Beaufort
BL-293"). That marks it as announced for the next agent.

## What stays in the project

Sources, transcripts, decisions, client data and working notes stay in the project. The headline
and summary are for Scott's own list: write them so a client would not mind seeing them there.
For export-controlled client work (ITAR), the headline and summary carry no technical content at
all.

## Limits of the current server

There is no update or close tool yet. A new due date, a status change or a closed item does not
reach Beaufort. When an announced item closes, say so in the project file and tell Scott, so the
`BL-` item can be closed by hand.

## Connecting

The server is LAN only. Each host's Claude Code registers it at user scope as `beaufort`, with
that host's own client token. Tokens and their scopes are issued by Scott. If the server is not
in `claude mcp list`, ask him rather than borrowing another host's token.
