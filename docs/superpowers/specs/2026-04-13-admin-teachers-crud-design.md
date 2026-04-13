# Admin Teachers CRUD Design

**Date:** 2026-04-13
**Branch:** `feature/admin-teachers-crud`
**Goal:** Allow admins to manually add teachers not present in 1C, with SNILS and other data needed for result export. Mark teachers by origin (imported vs manual). Only manually-created teachers can be edited or deleted.

## Current State

- `Admin::TeachersController` has only `index` and `show`
- `Teacher` model has `name`, `external_id`, `snils`, `encrypted_snils`, `kind` (enum), `enabled`, `stale_external_id`
- All teachers come from 1C via SOAP sync
- No way to add a teacher manually through the UI

## Model Changes

### Migration

Add two columns to `teachers`:
- `origin` (string, not null, default `"imported"`)
- `deleted_at` (datetime, nullable)

Existing rows get `origin: "imported"` by default.

### Teacher model

```ruby
enum origin: {imported: "imported", manual: "manual"}, _prefix: :origin

scope :active, -> { where(deleted_at: nil) }
scope :deleted, -> { where.not(deleted_at: nil) }

validates :name, presence: true
validates :snils, format: {with: /\A\d{11}\z/, allow_blank: true, message: "должен содержать 11 цифр"}
validates :snils, presence: true, if: :origin_manual?

def soft_delete!
  update_column(:deleted_at, Time.current)
end

def deleted?
  deleted_at.present?
end

def editable_by_admin?
  origin_manual?
end

# Update ransackable_attributes to include :origin
```

## Controller

```ruby
class Admin::TeachersController < Admin::BaseController
  load_and_authorize_resource

  before_action :ensure_manual, only: [:edit, :update, :destroy]

  def index
    @q = Teacher.active.ransack(params[:q])
    @teachers = paginate_entries(@q.result).order(id: :asc)
  end

  def show
    @results = Stage.all.map { |stage|
      {stage: stage, results: stage.calculation_rule_klass.new(@teacher, stage).call}
    }
  end

  def new
    @teacher = Teacher.new(origin: :manual, kind: :common)
  end

  def create
    @teacher = Teacher.new(teacher_params.merge(origin: :manual))
    if @teacher.save
      @teacher.encrypt_snils! if @teacher.snils.present?
      redirect_to admin_teacher_path(@teacher), notice: "Преподаватель создан"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @teacher.update(teacher_params)
      @teacher.encrypt_snils! if @teacher.snils.present?
      redirect_to admin_teacher_path(@teacher), notice: "Преподаватель обновлён"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @teacher.soft_delete!
    redirect_to admin_teachers_path, notice: "Преподаватель удалён"
  end

  private

  def teacher_params
    params.require(:teacher).permit(:name, :kind, :snils, :external_id)
  end

  def ensure_manual
    return if @teacher.editable_by_admin?
    redirect_to admin_teacher_path(@teacher), alert: "Импортированных из 1С преподавателей нельзя редактировать через UI"
  end
end
```

## Views

### Index

- New button "Новый преподаватель" → `new_admin_teacher_path`
- Column "Источник" — badge: "Из 1С" (gray) for `imported`, "Создан вручную" (emerald) for `manual`
- "Редактировать" link only for manual (conditional)

### Show

- Origin badge near name (blue: imported, green: manual)
- Buttons "Редактировать" / "Удалить" only for `editable_by_admin?`
- For imported: hint "Импортировано из 1С. Редактирование недоступно."
- Delete uses `confirm-modal` Stimulus controller

### New / Edit

- Wraps `_form.html.slim`
- Back link to teachers index

### Form partial

Fields:
- `name` — text, required
- `kind` — select (общий / физкультура / иностранный язык)
- `snils` — text, placeholder "11 цифр без пробелов", hint "Обязателен для выгрузки результатов"
- `external_id` — text, optional, hint "Только если известен"

Display errors summary at top.

## Scope Filtering

All listing places that iterate `Teacher` should respect soft delete. Since the admin index already uses `Teacher.active`, but external callers (e.g., `Ability`, queries, reports) may still see deleted teachers. For Part 1 scope: only admin index is filtered. Other consumers unchanged (can be follow-up).

## Ransack

Add `origin` and `kind` to `Teacher.ransackable_attributes`.

## Factory

Add `:manual` trait and `:deleted` trait to `spec/factories/teacher_factory.rb` (create if missing).

## Tests

Model specs:
- `origin` defaults to `imported`
- `snils` required when origin is manual
- `snils` format validation
- `soft_delete!` sets `deleted_at`
- `editable_by_admin?` returns true only for manual
- `.active` / `.deleted` scopes

Controller/request specs not required for v1 (can follow up).

## Views — UI detail

Sidebar navigation already has "Преподаватели". Need to add "Новый преподаватель" button at top-right of index.

Confirm-modal reused from existing Stimulus controller.

## Out of scope

- Bulk import of manually-created teachers
- Restoring soft-deleted teachers via UI (can be done via console)
- Merging imported and manual records
