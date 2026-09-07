# my* Suite API Reference

> Generated from 1,598 server functions across 27 applications.
> All endpoints use POST method with JSON body. Authentication via session cookie or Bearer token.

## Table of Contents
- [myjira (Port 3001)](#myjira-port-3001)
- [myconf (Port 3100)](#myconf-port-3100)
- [mybitbucket (Port 3002)](#mybitbucket-port-3002)
- [mycrowd (Port 8080)](#mycrowd-port-8080)
- [myportal (Port 3004)](#myportal-port-3004)
- [myservicedesk (Port 3006)](#myservicedesk-port-3006)
- [myopsgenie (Port 3005)](#myopsgenie-port-3005)
- [mysearch (Port 3021)](#mysearch-port-3021)
- [myflow (Port 3020)](#myflow-port-3020)
- [myforms (Port 3025)](#myforms-port-3025)
- [myrovo (Port 3010)](#myrovo-port-3010)
- [myanalytics (Port 3011)](#myanalytics-port-3011)
- [mymarketplace (Port 3012)](#mymarketplace-port-3012)
- [mytrello (Port 3016)](#mytrello-port-3016)
- [mychat (Port 3015)](#mychat-port-3015)
- [mycompass (Port 3007)](#mycompass-port-3007)
- [mycalendars (Port 3008)](#mycalendars-port-3008)
- [mystatuspage (Port 8090)](#mystatuspage-port-8090)
- [mybamboo (Port 3003)](#mybamboo-port-3003)
- [myalign (Port 3013)](#myalign-port-3013)
- [mynotifications (Port 3014)](#mynotifications-port-3014)
- [mydiscovery (Port 3017)](#mydiscovery-port-3017)
- [myatlas (Port 3018)](#myatlas-port-3018)
- [myjam (Port 3022)](#myjam-port-3022)
- [myrunbook (Port 3023)](#myrunbook-port-3023)
- [mytimesheets (Port 3024)](#mytimesheets-port-3024)

---

## myjira (Port 3001)
Issue tracker with JQL search, boards, workflows, and automation.

### Issues
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/CreateIssue` | Required | project_key, issue_type, summary, description | Issue | Create new issue |
| `POST /api/GetIssue` | Required | key (String) | Issue | Get issue by key |
| `POST /api/UpdateIssue` | Required | key, summary, description, status | Issue | Update issue |
| `POST /api/DeleteIssue` | Required | key (String) | bool | Delete issue |
| `POST /api/ListIssues` | Required | project_key, filters | Vec<Issue> | List issues with JQL |
| `POST /api/SearchIssues` | Required | jql (String) | SearchResult | JQL search |

### Projects
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListProjects` | Required | — | Vec<Project> | List all projects |
| `POST /api/CreateProject` | Admin | key, name, description | Project | Create project |
| `POST /api/DeleteProject` | Admin | key (String) | bool | Delete project |

### Gantt Chart
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/GetGanttData` | Required | project_key (String) | GanttData | Get Gantt chart data |

### Boards & Workflows
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListBoards` | Required | project_key | Vec<Board> | List boards |
| `POST /api/GetBoard` | Required | id (Uuid) | Board | Get board details |
| `POST /api/MoveIssue` | Required | key, column, position | bool | Move issue on board |

---

## myconf (Port 3100)
Knowledge base with pages, spaces, and real-time collaboration.

### Pages
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/CreatePage` | Required | space_key, title, body | Page | Create page |
| `POST /api/GetPage` | Required | space_key, slug | Page | Get page |
| `POST /api/UpdatePage` | Required | space_key, slug, body | Page | Update page |
| `POST /api/DeletePage` | Required | space_key, slug | bool | Delete page |
| `POST /api/SearchPages` | Required | query (String) | Vec<Page> | Full-text search |

### Spaces
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListSpaces` | Required | — | Vec<Space> | List spaces |
| `POST /api/CreateSpace` | Admin | key, name, description | Space | Create space |

---

## mybitbucket (Port 3002)
Git hosting with PRs, code review, and CI/CD integration.

### Repositories
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListRepos` | Required | project_key | Vec<Repo> | List repositories |
| `POST /api/CreateRepo` | Admin | project_key, slug, name | Repo | Create repository |
| `POST /api/DeleteRepo` | Admin | project_key, slug | bool | Delete repository |

### Pull Requests
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListPRs` | Required | project_key, slug, filters | Vec<PR> | List pull requests |
| `POST /api/CreatePR` | Required | project_key, slug, source, target, title | PR | Create PR |
| `POST /api/MergePR` | Required | project_key, slug, number | bool | Merge PR |

---

## mycrowd (Port 8080)
Identity provider with SSO, user management, and secrets.

### Users
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListUsers` | Admin | — | Vec<User> | List users |
| `POST /api/CreateUser` | Admin | username, email, password | User | Create user |
| `POST /api/DeleteUser` | Admin | id (Uuid) | bool | Delete user |
| `POST /api/GetUserStats` | Admin | — | (i64, i64, i64) | Active/inactive/admin counts |

### Groups
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListGroups` | Admin | — | Vec<Group> | List groups |
| `POST /api/CreateGroup` | Admin | name, description | Group | Create group |
| `POST /api/GetGroupCount` | Admin | — | i64 | Total groups |

### Secrets
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListSecrets` | Admin | — | Vec<SecretMeta> | List secrets (no values) |
| `POST /api/CreateSecret` | Admin | name, kind, value | SecretMeta | Create secret |

---

## myportal (Port 3004)
Suite portal with app tiles, status widget, and activity feed.

### Portal
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/GetPortal` | Required | — | PortalData | Full portal data |
| `POST /api/GetMyWork` | Required | — | MyWorkData | Per-user work items |
| `POST /api/GetPortalStats` | Admin | — | (i64, i64, usize) | Users/sessions/apps |
| `POST /api/GetSystemHealth` | Admin | — | Vec<(String, String, i64)> | Service health |

### Admin
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/GetAuditLog` | Admin | limit (Option<i64>) | Vec<(String, String, String, String)> | Audit entries |
| `POST /api/GetRecentLogins` | Admin | limit (Option<i64>) | Vec<(String, String)> | Recent logins |

---

## mysearch (Port 3021)
Global search across all suite applications.

### Search
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/GlobalSearch` | Required | query (String) | SearchResponse | Full-text search |
| `POST /api/SearchSuggestions` | Required | prefix (String) | Vec<String> | Autocomplete |
| `POST /api/TrendingSearches` | Required | limit (Option<i32>) | Vec<(String, i32)> | Popular queries |

### Logs
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/GetLogEntries` | Required | source, level, limit | Vec<LogEntry> | Query logs |
| `POST /api/GetLogStats` | Required | — | Vec<LogStatRow> | Log statistics |
| `POST /api/ClearOldLogs` | Admin | days (i32) | i64 | Purge old logs |

---

## myflow (Port 3020)
Automation engine with rules, triggers, and actions.

### Rules
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListRules` | Required | — | Vec<RuleView> | List rules |
| `POST /api/CreateRule` | Required | RuleInput | RuleView | Create rule |
| `POST /api/DuplicateRule` | Required | id (String) | RuleView | Duplicate rule |
| `POST /api/ExportRule` | Required | id (String) | String | Export as JSON |
| `POST /api/ImportRule` | Required | json (String) | RuleView | Import from JSON |

### Executions
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListExecutions` | Required | rule_id (Option<String>) | Vec<ExecutionView> | List executions |
| `POST /api/ExecutionStats` | Required | — | (i64, i64, i64, i64) | Total/success/error/pending |
| `POST /api/FailedExecutions` | Required | limit (Option<i32>) | Vec<ExecutionView> | Recent failures |

---

## myforms (Port 3025)
Form builder with submissions and analytics.

### Forms
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListForms` | Required | — | Vec<Form> | List forms |
| `POST /api/CreateForm` | Required | slug, title, description, fields | Form | Create form |
| `POST /api/DuplicateForm` | Required | id (String) | Form | Duplicate form |
| `POST /api/SearchForms` | Required | query (String) | Vec<Form> | Search by title |

### Submissions
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListSubmissions` | Required | form_id (String) | Vec<Submission> | List submissions |
| `POST /api/FormStats` | Required | form_id (String) | (i64, i64, i64) | Total/24h/7d counts |
| `POST /api/ExportSubmissionsCsv` | Required | form_id (String) | String | CSV export |

---

## myrovo (Port 3010)
AI assistant with LLM agent and tool execution.

### Conversations
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListConversations` | Required | — | Vec<ConversationView> | List conversations |
| `POST /api/CreateConversation` | Required | title (String) | ConversationView | Create conversation |
| `POST /api/RenameConversation` | Required | id, title | ConversationView | Rename |
| `POST /api/ExportConversation` | Required | id (Uuid) | String | Export as JSON |
| `POST /api/ClearConversation` | Required | id (Uuid) | bool | Clear messages |

### Messages
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/SendMessage` | Required | conversation_id, text | String | Send message (AI response) |
| `POST /api/ConversationStats` | Required | — | (i64, i64) | Conversations/messages count |

---

## myanalytics (Port 3011)
BI dashboards with SQL widgets and DORA metrics.

### Dashboards
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListDashboards` | Required | — | Vec<Dashboard> | List dashboards |
| `POST /api/CreateDashboard` | Admin | title (String) | Dashboard | Create dashboard |
| `POST /api/DashboardStats` | Required | — | (i64, i64) | Dashboards/widgets count |

### Reports
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListReportTemplates` | Required | — | Vec<ReportTemplateInfo> | List templates |
| `POST /api/ListReportCategories` | Required | — | Vec<String> | List categories |
| `POST /api/RunReport` | Required | template_id, params | ReportResult | Run report |

---

## mytrello (Port 3016)
Kanban boards with cards, lists, and real-time updates.

### Boards
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListMyBoards` | Required | — | Vec<Board> | List boards |
| `POST /api/CreateBoard` | Required | title, description, visibility | Board | Create board |
| `POST /api/DuplicateBoard` | Required | board_id (Uuid) | Board | Duplicate board |
| `POST /api/BoardStats` | Required | — | (i64, i64, i64) | Boards/lists/cards |

### Cards
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/CreateCard` | Required | board_id, list_id, title | Card | Create card |
| `POST /api/MoveCard` | Required | card_id, list_id, position | Card | Move card |

---

## myopsgenie (Port 3005)
Alerts, incidents, on-call schedules, and escalations.

### Alerts
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListAlerts` | Required | filters | Vec<AlertDto> | List alerts |
| `POST /api/AcknowledgeAlert` | Required | alert_id, note | AlertDto | Acknowledge |
| `POST /api/ResolveAlert` | Required | alert_id, note | AlertDto | Resolve |
| `POST /api/AlertStats` | Required | — | (i64, i64, Vec<(String, i64)>) | Total/open/by-priority |

---

## myservicedesk (Port 3006)
Service desk with requests, SLA, and assets.

### Requests
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/CreateRequest` | Required | subject, description, priority | Request | Create request |
| `POST /api/GetRequest` | Required | id (Uuid) | Request | Get request |
| `POST /api/ListRequests` | Required | filters | Vec<Request> | List requests |

### Customer Portal (Public)
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/GetPublicRequestStatus` | Public | request_id (String) | PublicRequestDto | Check status |
| `POST /api/SubmitPublicRequest` | Public | subject, description, email | Request | Submit request |

---

## mystatuspage (Port 8090)
Status page with services, components, and incidents.

### Status
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/GetStatusPage` | Public | — | StatusPageData | Public status |
| `POST /api/GetStatusStats` | Admin | — | (i64, i64, i64, i64) | Services/components/incidents/monitors |
| `POST /api/GetMonitorStats` | Admin | — | (i64, i64, i64, i64) | Total/active/healthy/unhealthy |
| `POST /api/GetIncidentStats` | Admin | — | (i64, i64, i64, i64) | Total/open/resolved/24h |

---

## mycompass (Port 3007)
Service catalog with components, scorecards, and dependencies.

### Components
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListComponents` | Required | — | Vec<Component> | List components |
| `POST /api/CreateComponent` | Admin | name, type, owner | Component | Create component |

---

## mycalendars (Port 3008)
Team calendars with events, recurrence, and leaves.

### Events
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/CreateEvent` | Required | calendar_id, title, start, end | Event | Create event |
| `POST /api/ListEventsExpanded` | Required | calendar_id, range | Vec<Event> | List expanded |

---

## mynotifications (Port 3014)
Notification hub with inbox, channels, and rules.

### Notifications
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListNotifications` | Required | limit, before_id | Vec<Notification> | List notifications |
| `POST /api/MarkRead` | Required | id (i64) | bool | Mark as read |
| `POST /api/NotificationStats` | Required | — | (i64, i64, Vec<(String, i64)>) | Total/unread/by-source |

---

## mychat (Port 3015)
Team messenger with channels, DMs, and real-time messaging.

### Channels
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListChannels` | Required | — | Vec<Channel> | List channels |
| `POST /api/CreateChannel` | Required | name, title, is_private | Channel | Create channel |

### Messages
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/SendMessage` | Required | channel_id, body | Message | Send message |
| `POST /api/SearchMessages` | Required | query, channel_id | Vec<Message> | Search messages |

---

## mybamboo (Port 3003)
CI/CD with pipelines, builds, and deployments.

### Pipelines
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListPipelines` | Required | — | Vec<Pipeline> | List pipelines |
| `POST /api/CreatePipeline` | Admin | name, repo_url, yaml | Pipeline | Create pipeline |
| `POST /api/RunPipeline` | Admin | id, ref | Build | Trigger build |

---

## myalign (Port 3013)
Jira Align with programs, epics, and roadmaps.

### Programs
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListPrograms` | Required | — | Vec<Program> | List programs |
| `POST /api/CreateProgram` | Admin | name, description | Program | Create program |
| `POST /api/DuplicateProgram` | Admin | id (Uuid) | Program | Duplicate program |
| `POST /api/ExportProgram` | Required | id (Uuid) | String | Export as JSON |
| `POST /api/ProgramHealthCheck` | Required | id (Uuid) | (i64, i64, i64, f64) | Health metrics |

---

## mydiscovery (Port 3017)
Idea funnel with scoring, votes, and roadmap.

### Ideas
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListIdeas` | Required | filters | Vec<Idea> | List ideas |
| `POST /api/CreateIdea` | Required | title, description | Idea | Create idea |
| `POST /api/VoteIdea` | Required | id (Uuid) | bool | Vote for idea |

---

## myatlas (Port 3018)
Async team updates with project status and digests.

### Projects
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListProjects` | Required | — | Vec<Project> | List projects |
| `POST /api/CreateProject` | Admin | name, team | Project | Create project |

---

## myjam (Port 3022)
Collaborative whiteboard with items, connectors, and real-time.

### Boards
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListBoards` | Required | — | Vec<BoardSummary> | List boards |
| `POST /api/CreateBoard` | Required | name, template, visibility | Board | Create board |
| `POST /api/DuplicateBoard` | Required | board_id (Uuid) | Board | Duplicate board |
| `POST /api/BoardStats` | Required | — | (i64, i64) | Boards/items count |

---

## myrunbook (Port 3023)
Incident runbooks with steps, timers, and escalations.

### Runbooks
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/ListRunbooks` | Required | category, severity | Vec<Runbook> | List runbooks |
| `POST /api/CreateRunbook` | Admin | name, description, category, severity | Runbook | Create runbook |
| `POST /api/DuplicateRunbook` | Required | id (String) | Runbook | Duplicate runbook |

### Runs
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/StartRun` | Required | runbook_id, context_json | Run | Start run |
| `POST /api/RunStats` | Required | — | (i64, i64, i64, i64) | Total/active/completed/aborted |

---

## mytimesheets (Port 3024)
Time tracking with entries, reports, and approvals.

### Entries
| Endpoint | Auth | Parameters | Returns | Description |
|----------|------|------------|---------|-------------|
| `POST /api/CreateEntry` | Required | task_id, minutes, date | Entry | Create entry |
| `POST /api/ListEntries` | Required | date_from, date_to | Vec<Entry> | List entries |

---

## Common Patterns

### Authentication
- **Session cookie**: Set via `POST /api/LoginLocal` or OIDC SSO
- **Bearer token**: `Authorization: Bearer <token>` for API access
- **HMAC webhook**: `X-Hub-Signature-256: sha256=<hex>` for server-to-server

### Error Responses
- `400` — Validation error
- `401` — Authentication required
- `403` — Insufficient permissions
- `404` — Resource not found
- `409` — Conflict (duplicate)
- `429` — Rate limited
- `500` — Internal error (masked)

### Pagination
- `limit` parameter (default 20, max 100)
- `before_id` for cursor-based pagination
- `offset` for offset-based pagination

### Rate Limiting
- Public endpoints: 10 req/sec per IP
- Authenticated: configurable per app
- Webhook endpoints: separate limits
