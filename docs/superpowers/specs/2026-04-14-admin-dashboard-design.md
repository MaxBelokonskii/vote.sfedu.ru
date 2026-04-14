# Admin Dashboard Design

**Date:** 2026-04-14
**Branch:** `feature/admin-dashboard`
**Goal:** Replace the admin home page with a full-featured dashboard showing KPIs, current stage progress, active polls, recent surveys, activity dynamics, and data-quality checks.

## Current State

- `Admin::BaseController#index` renders `admin/base/index.html.slim` — simple welcome message
- No metrics, no charts, no overview of activity

## Architecture

### Controller

Rewire `Admin::BaseController#index` (or extract to `Admin::DashboardController`) to call a metrics service and render sections.

Prefer extracting: `Admin::DashboardController#show` with route `get "/admin" => "dashboard#show"` as admin root. This keeps `BaseController` purely shared logic (layout, authorization).

### Service: `Admin::DashboardMetrics`

Single plain Ruby object that collects all metrics. Exposes a hash or reader methods for each section. Wrapped in `Rails.cache.fetch("admin_dashboard_metrics", expires_in: 5.minutes)` to avoid heavy queries on every refresh.

```ruby
class Admin::DashboardMetrics
  def self.call
    Rails.cache.fetch("admin_dashboard_metrics", expires_in: 5.minutes) do
      new.call
    end
  end

  def call
    {
      kpi: kpi_metrics,
      current_stage: current_stage_section,
      polls: active_polls_section,
      surveys: recent_surveys_section,
      participation_trend: participation_trend_30d,
      teacher_kinds: teacher_kinds_distribution,
      data_quality: data_quality_checks,
      user_activity: user_activity_section
    }
  end

  # ... private methods per metric
end
```

## Metrics Detail

### 1. KPI Cards (top)

| Metric | Source |
|--------|--------|
| Студенты | `Student.count` |
| Преподаватели | `Teacher.active.count`, with manual count `Teacher.active.origin_manual.count` as subtitle |
| Текущая стадия | `Stage.current` (name/dates + participations count), "нет активной" if nil |
| Активные голосования | `Poll.not_archived.where("starts_at <= ? AND ends_at >= ?", now, now).count` |
| Опросы | `Survey.count`, subtitle active (active_until >= today) |
| Администраторы | `User.where(role: :admin).count` |

### 2. Current Stage Section

If `Stage.current` exists:
- Name (derived) + dates
- Expected participations: `Student.count * teachers_rosters_count_per_stage` — or simpler: show actual count
- **Actual participations**: `stage.participations.count`
- **Unique students participated**: `stage.participations.distinct.count(:student_id)`
- **Unique teachers evaluated**: `stage.participations.distinct.count(:teacher_id)`
- **Progress bar** by faculty: using existing `Stages::ProgressReportByFaculties` query (already builds faculty rows)
- **Teachers with insufficient responses**: count where `participations.count < stage.lower_participants_limit`
- Link to stage show page

Else: placeholder "Нет активной стадии" + link to create new stage.

### 3. Active Polls Section

For each active poll (max 5):
- Name, dates
- Progress bar: total votes across all options
- Top-3 options with percentages (using `poll.options.order(votes DESC).limit(3)`)
- Link to poll show page

If no active polls: skip section.

### 4. Recent Surveys Section

Last 5 surveys by `created_at DESC`:
- Title, creator (user.name or email), answered count, active_until
- Link to survey show (if exists for admin — actually surveys are managed by teachers, link to public path or skip)

Simpler: show list of 5 recent surveys as read-only info.

### 5. Participation Trend (Chart)

Line chart, 30-day window:
- X-axis: day
- Y-axis: participations count

```ruby
Participation.where("created_at >= ?", 30.days.ago)
  .group("DATE(created_at)")
  .order("DATE(created_at)")
  .count
```

Result: `{Date.new(2026,3,15) => 42, Date.new(2026,3,16) => 55, ...}`

Fill gaps with zeros for days without data — do in Ruby for chart smoothness.

### 6. Teacher Kinds Distribution (Donut Chart)

```ruby
Teacher.active.group(:kind).count
# => {"common" => 450, "physical_education" => 30, "foreign_language" => 40}
```

### 7. Data Quality Checks

List of issues (count + link):
- Students without grade_books: `Student.without_grade_books.count` (existing scope)
- Teachers without SNILS (can't be exported): `Teacher.active.where(encrypted_snils: [nil, ""]).count`
- Teachers with stale_external_id: `Teacher.active.where.not(stale_external_id: nil).count`
- On current stage: teachers with zero participations: `current_stage.teachers_rosters.joins(...).where(...).count` — but skip if no current stage

Each item is color-coded: amber if > 0, emerald if zero.

### 8. User Activity

- Sign-ins in last 7 days: `User.where("last_sign_in_at >= ?", 7.days.ago).count`
- Sign-ins in last 30 days: `User.where("last_sign_in_at >= ?", 30.days.ago).count`
- Total sign-ins across all users: `User.sum(:sign_in_count)` (optional, can skip)

## Frontend

### Chart.js Integration

Install via yarn: `yarn add chart.js`

Add to `app/frontend/entrypoints/admin.js`:
```js
import { Chart, registerables } from "chart.js"
Chart.register(...registerables)
```

Create Stimulus controller `chart_controller.js`:
```js
import { Controller } from "@hotwired/stimulus"
import { Chart } from "chart.js"

export default class extends Controller {
  static values = {
    type: String,   // "line" | "doughnut" | "bar"
    data: Object,   // Chart.js data config
    options: Object // Chart.js options
  }

  connect() {
    this.chart = new Chart(this.element.getContext("2d"), {
      type: this.typeValue,
      data: this.dataValue,
      options: this.optionsValue
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
```

Register in `app/frontend/admin/controllers/index.js`.

Usage in Slim:
```slim
canvas.w-full data-controller="chart" data-chart-type-value="line" data-chart-data-value=data_json.to_json data-chart-options-value=options_json.to_json
```

### Views

- Create `app/views/admin/dashboard/show.html.slim` — main template with sections
- Partials for each section: `_kpi_cards.html.slim`, `_current_stage.html.slim`, `_polls.html.slim`, `_surveys.html.slim`, `_participation_chart.html.slim`, `_teacher_kinds_chart.html.slim`, `_data_quality.html.slim`, `_user_activity.html.slim`

### Styling

- KPI cards: `bg-white rounded-xl border border-gray-200 p-6`, number `text-3xl font-bold text-gray-900`, label `text-sm text-gray-500`
- Progress bars: `bg-gray-200 rounded-full overflow-hidden h-2` + inner `bg-primary`
- Color palette for statuses:
  - Emerald: green indicators
  - Amber: warnings
  - Red: critical data quality issues
- Grid layout: `grid grid-cols-1 md_grid-cols-2 lg_grid-cols-3 gap-4`

## Routes

Change:
```ruby
namespace :admin do
  root to: "dashboard#show"  # was "base#index"
  # ... other resources unchanged
end
```

## File Structure

```
app/
├── controllers/admin/
│   └── dashboard_controller.rb          # new
├── services/admin/
│   └── dashboard_metrics.rb             # new
├── frontend/admin/controllers/
│   └── chart_controller.js              # new
├── views/admin/dashboard/
│   ├── show.html.slim                   # new
│   └── _kpi_cards.html.slim             # new
│   └── _current_stage.html.slim
│   └── _polls.html.slim
│   └── _surveys.html.slim
│   └── _participation_chart.html.slim
│   └── _teacher_kinds_chart.html.slim
│   └── _data_quality.html.slim
│   └── _user_activity.html.slim
└── helpers/admin/
    └── dashboard_helper.rb              # formatting helpers (number_with_delimiter, percentage, progress color)
```

Remove: `app/controllers/admin/base_controller.rb#index` action + view `admin/base/index.html.slim` (or keep as redirect).

## Tests

- Service spec: `Admin::DashboardMetrics` returns expected structure with empty DB and with seeded data
- Request spec: `GET /admin` returns 200 for admin, 403 for non-admin
- Skip view specs (Slim rendering is stable)

## Cache Invalidation

Initial 5-minute TTL is sufficient. No active invalidation on mutations — dashboard shows "snapshot" view. If needed later, add cache bust in mutating controllers.

## Out of Scope

- Real-time updates
- User-configurable widgets
- Historical trends beyond 30 days
- Export dashboard as PDF/Excel
- Filtering by date range (dashboard is "now" snapshot)
