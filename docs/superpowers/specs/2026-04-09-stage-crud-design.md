# Stage CRUD Design

**Date:** 2026-04-09
**Branch:** `feature/stage-creation-form`
**Goal:** Full CRUD for stages in admin panel — create, read, edit, update, soft-delete with confirmation.

## Current State

- Stage model exists with fields: starts_at, ends_at, scale/truncation params, scale_ladder
- HABTM relationships: semesters (via semesters_stages), questions (via questions_stages)
- Admin controller has only index and show actions
- No form for creating or editing stages — managed via console/DB
- No soft delete — no deleted_at column

## Model Changes

### Stage

**New column:** `deleted_at` (datetime, nullable, default nil)

**Scopes:**
- `active` — `where(deleted_at: nil)`
- `deleted` — `where.not(deleted_at: nil)`

**Method:**
- `soft_delete!` — `update!(deleted_at: Time.current)`

**Validations:**
- `starts_at` — presence
- `ends_at` — presence
- `ends_at > starts_at` — custom validation
- At least one semester — custom validation
- At least one question — custom validation
- `scale_max > scale_min` — only when `with_scale` is true
- `lower_participants_limit >= 0`

**Scope integration:** All existing class methods (`current`, `active`, `upcoming`, `past`) must filter by `deleted_at: nil`. The existing `self.active` scope already exists and means "currently running" — rename it to `self.running` and use `active` for "not soft-deleted". Then:
- `self.upcoming` — `active.where("starts_at > ?", Time.current)`
- `self.past` — `active.where("ends_at < ?", Time.current)`
- `self.running` — `active.where("starts_at <= ? AND ends_at >= ?", now, now)`
- `self.current` — `running.first`

## Controller: Admin::StagesController

Full RESTful actions:

| Action | Purpose |
|--------|---------|
| `index` | List `Stage.active.order(starts_at: :desc)` |
| `show` | Display stage details + questions + semesters + params. XLSX export (existing) |
| `new` | Render form with defaults |
| `create` | Create stage + attach semesters/questions + create new questions |
| `edit` | Render form with existing data |
| `update` | Update stage + sync semesters/questions + create new questions |
| `destroy` | Soft delete with `soft_delete!`, redirect to index |

### Strong Params

```ruby
def stage_params
  params.require(:stage).permit(
    :starts_at, :ends_at,
    :lower_participants_limit,
    :with_scale, :scale_min, :scale_max,
    :with_truncation, :lower_truncation_percent, :upper_truncation_percent,
    semester_ids: [],
    question_ids: [],
    new_questions_attributes: [:text, :max_rating]
  )
end
```

### Create/Update Logic

1. Extract `new_questions_attributes` from params
2. Create new Question records from `new_questions_attributes`
3. Merge their IDs into `question_ids`
4. Build/update Stage with remaining params (including semester_ids, question_ids)
5. Save — HABTM sync happens automatically via `question_ids=` and `semester_ids=`

## Form: `_form.html.slim`

Three sections in a single partial, shared between new and edit.

### Section 1: Dates & Semesters

- `starts_at` — datetime_select or text field with date picker
- `ends_at` — datetime_select or text field with date picker
- Semesters — collection of checkboxes from `Semester.all`, rendered as cards/chips. Each shows `semester.full_title` (e.g., "осенний семестр 2024/2025").

### Section 2: Questions

- Existing questions — checkboxes from `Question.all`. Each shows `question.text`.
- "Создать новый вопрос" button — Stimulus controller `new-question` appends a fieldset with:
  - `text` (text input, required)
  - `max_rating` (number input, default 10)
  - "Удалить" button to remove the fieldset
- Multiple new questions can be added before form submission.

### Section 3: Parameters

- `lower_participants_limit` — number field, always visible
- `with_scale` checkbox — Stimulus controller `toggle-fields` shows/hides:
  - `scale_min` (number)
  - `scale_max` (number)
- `with_truncation` checkbox — same toggle pattern shows/hides:
  - `lower_truncation_percent` (number)
  - `upper_truncation_percent` (number)

When checkboxes are unchecked, hidden fields are disabled (not submitted) to avoid validation on hidden values.

## Stimulus Controllers

### `toggle-fields`

Toggles visibility and disabled state of a target container based on a checkbox.

**Usage:**
```slim
div data-controller="toggle-fields"
  = f.check_box :with_scale, data: { toggle_fields_target: "checkbox", action: "toggle-fields#toggle" }
  div data-toggle-fields-target="container" class=(f.object.with_scale? ? "" : "hidden")
    = f.number_field :scale_min
    = f.number_field :scale_max
```

### `new-question`

Manages dynamic addition/removal of new question fieldsets.

**Behavior:**
- "Создать новый вопрос" button appends a new fieldset from a `<template>` element
- Each fieldset has index-based names: `stage[new_questions_attributes][0][text]`, `...[0][max_rating]`
- "Удалить" button removes the fieldset
- Counter increments to ensure unique indices

### `confirm-modal`

Simple confirmation dialog before destructive actions.

**Behavior:**
- Delete button opens a modal/dialog with "Вы уверены?" text
- "Да, удалить" confirms — submits DELETE request
- "Отмена" closes the modal
- Implemented via native `<dialog>` element or a hidden div toggled by Stimulus

## Soft Delete Confirmation Flow

1. User clicks "Удалить стадию" button on show or edit page
2. Stimulus `confirm-modal` controller opens modal
3. User confirms — form with `method: :delete` submits to `destroy` action
4. Controller calls `@stage.soft_delete!`
5. Redirect to `admin_stages_path` with flash notice "Стадия удалена"

## Views

### index.html.slim (modify existing)

- Add "Новая стадия" button linking to `new_admin_stage_path`
- Add "Редактировать" link per stage row
- Stage list uses `Stage.active` (soft-deleted stages hidden)

### show.html.slim (modify existing)

- Display all stage fields: dates, semesters list, questions list, parameters
- "Редактировать" button → `edit_admin_stage_path`
- "Удалить" button → triggers confirm-modal

### new.html.slim (create)

- Page title "Новая стадия"
- Render `_form` partial

### edit.html.slim (create)

- Page title "Редактирование стадии"
- Render `_form` partial

### _form.html.slim (create)

- Full form as described above

## Stimulus Setup

Stimulus is not yet in the project. Needs to be added:
- `yarn add @hotwired/stimulus`
- Create `app/frontend/entrypoints/admin.js` Vite entrypoint that initializes Stimulus application and registers controllers
- Place controllers in `app/frontend/admin/controllers/`
- Update admin layout to use `vite_javascript_tag 'admin'` instead of `javascript_include_tag :admin`

This replaces Sprockets-based `admin.js` with Vite-based entrypoint for the admin area, which also sets up the path for future Vue migration.

## File Structure

```
app/frontend/
├── admin/
│   └── controllers/
│       ├── toggle_fields_controller.js
│       ├── new_question_controller.js
│       └── confirm_modal_controller.js
├── entrypoints/
│   └── admin.js                    # New: Stimulus application init
app/views/admin/stages/
├── index.html.slim                 # Modify: add action buttons
├── show.html.slim                  # Modify: display all fields + delete button
├── new.html.slim                   # Create
├── edit.html.slim                  # Create
└── _form.html.slim                 # Create
app/controllers/admin/
└── stages_controller.rb            # Modify: add new/create/edit/update/destroy
app/models/
└── stage.rb                        # Modify: add validations, scopes, soft_delete!
db/migrate/
└── XXXXXX_add_deleted_at_to_stages.rb  # Create
```

## Testing

- Model specs: validations, scopes (active, deleted, running), soft_delete! method
- Request/controller specs: each CRUD action, soft delete behavior, new question creation
- Factory: update stage factory with new traits
