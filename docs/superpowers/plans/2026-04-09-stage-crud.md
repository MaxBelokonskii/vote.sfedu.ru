# Stage CRUD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Full admin CRUD for stages with dynamic question creation, semester selection, scale/truncation toggles, and soft delete with confirmation.

**Architecture:** Server-rendered Slim forms with Stimulus controllers for dynamic fields. Migration adds `deleted_at` to stages. Model gets validations, scopes, soft delete. Stimulus replaces Sprockets admin.js via Vite entrypoint.

**Tech Stack:** Rails 7.2, Slim, Stimulus 3, Vite, Tailwind CSS 3

---

## File Map

| Action | Path | Purpose |
|--------|------|---------|
| Create | `db/migrate/XXXX_add_deleted_at_to_stages.rb` | Add soft delete column |
| Modify | `app/models/stage.rb` | Validations, scopes, soft_delete! |
| Modify | `app/controllers/admin/stages_controller.rb` | Full CRUD actions |
| Create | `app/views/admin/stages/new.html.slim` | New stage page |
| Create | `app/views/admin/stages/edit.html.slim` | Edit stage page |
| Create | `app/views/admin/stages/_form.html.slim` | Shared form partial |
| Modify | `app/views/admin/stages/index.html.slim` | Filter by active |
| Modify | `app/views/admin/stages/show.html.slim` | Display details + edit/delete |
| Create | `app/frontend/admin/controllers/toggle_fields_controller.js` | Show/hide scale & truncation |
| Create | `app/frontend/admin/controllers/new_question_controller.js` | Add/remove question fieldsets |
| Create | `app/frontend/admin/controllers/confirm_modal_controller.js` | Delete confirmation |
| Create | `app/frontend/entrypoints/admin.js` | Stimulus application init |
| Modify | `app/views/layouts/admin.html.slim` | Replace Sprockets JS with Vite |
| Modify | `spec/factories/stage_factory.rb` | Add deleted trait |
| Create | `spec/models/stage_spec.rb` | Model validations & scopes |

---

### Task 1: Migration — add deleted_at to stages

**Files:**
- Create: `db/migrate/XXXX_add_deleted_at_to_stages.rb`

- [ ] **Step 1: Generate migration**

Run: `bin/rails generate migration AddDeletedAtToStages deleted_at:datetime`

- [ ] **Step 2: Run migration**

Run: `bin/rails db:migrate`
Expected: Column `deleted_at` added to `stages` table.

- [ ] **Step 3: Commit**

```bash
git add db/migrate/*_add_deleted_at_to_stages.rb db/schema.rb
git commit -m "Add deleted_at column to stages for soft delete"
```

---

### Task 2: Stage model — validations, scopes, soft delete

**Files:**
- Modify: `app/models/stage.rb`
- Modify: `spec/factories/stage_factory.rb`
- Create: `spec/models/stage_spec.rb`

- [ ] **Step 1: Write model specs**

Create `spec/models/stage_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Stage do
  describe "validations" do
    it "is valid with all required attributes" do
      stage = build(:stage, :with_semester, :with_questions)
      expect(stage).to be_valid
    end

    it "requires starts_at" do
      stage = build(:stage, starts_at: nil)
      expect(stage).not_to be_valid
      expect(stage.errors[:starts_at]).to be_present
    end

    it "requires ends_at" do
      stage = build(:stage, ends_at: nil)
      expect(stage).not_to be_valid
      expect(stage.errors[:ends_at]).to be_present
    end

    it "requires ends_at to be after starts_at" do
      stage = build(:stage, starts_at: 1.day.from_now, ends_at: 1.day.ago)
      expect(stage).not_to be_valid
      expect(stage.errors[:ends_at]).to be_present
    end

    it "requires at least one semester" do
      stage = build(:stage, :with_questions)
      expect(stage).not_to be_valid
      expect(stage.errors[:semesters]).to be_present
    end

    it "requires at least one question" do
      stage = build(:stage, :with_semester)
      expect(stage).not_to be_valid
      expect(stage.errors[:questions]).to be_present
    end

    it "requires scale_max > scale_min when with_scale is true" do
      stage = build(:stage, :with_semester, :with_questions, with_scale: true, scale_min: 10, scale_max: 5)
      expect(stage).not_to be_valid
      expect(stage.errors[:scale_max]).to be_present
    end

    it "does not validate scale when with_scale is false" do
      stage = build(:stage, :with_semester, :with_questions, with_scale: false, scale_min: 10, scale_max: 5)
      expect(stage).to be_valid
    end

    it "requires lower_participants_limit >= 0" do
      stage = build(:stage, :with_semester, :with_questions, lower_participants_limit: -1)
      expect(stage).not_to be_valid
      expect(stage.errors[:lower_participants_limit]).to be_present
    end
  end

  describe "scopes" do
    let!(:active_stage) { create(:stage, :with_semester, :with_questions) }
    let!(:deleted_stage) { create(:stage, :with_semester, :with_questions, :deleted) }

    it ".active returns only non-deleted stages" do
      expect(Stage.active).to include(active_stage)
      expect(Stage.active).not_to include(deleted_stage)
    end

    it ".deleted returns only soft-deleted stages" do
      expect(Stage.deleted).to include(deleted_stage)
      expect(Stage.deleted).not_to include(active_stage)
    end
  end

  describe "#soft_delete!" do
    it "sets deleted_at timestamp" do
      stage = create(:stage, :with_semester, :with_questions)
      expect { stage.soft_delete! }.to change { stage.deleted_at }.from(nil)
      expect(stage.deleted_at).to be_within(1.second).of(Time.current)
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/models/stage_spec.rb`
Expected: Failures — validations and scopes not yet implemented.

- [ ] **Step 3: Update stage factory**

Replace `spec/factories/stage_factory.rb` with:

```ruby
FactoryBot.define do
  factory :stage do
    starts_at { Time.current - 1.week }
    ends_at { Time.current + 1.week }
    lower_participants_limit { 0 }
    scale_min { 6 }
    scale_max { 10 }
    lower_truncation_percent { 5 }
    upper_truncation_percent { 5 }
    with_scale { false }
    with_truncation { false }

    trait :with_questions do
      transient do
        questions_count { 5 }
      end

      after(:create) do |stage, evaluator|
        stage.questions << build_list(:question, evaluator.questions_count)
        stage.reload
      end
    end

    trait :with_semester do
      after(:create) do |stage, _|
        stage.semesters << build(:semester)
        stage.reload
      end
    end

    trait :deleted do
      deleted_at { Time.current }
    end
  end
end
```

- [ ] **Step 4: Implement model changes**

Replace `app/models/stage.rb` with:

```ruby
class Stage < ApplicationRecord
  has_and_belongs_to_many :semesters
  has_and_belongs_to_many :questions
  has_many :participations
  has_many :teachers_rosters, dependent: :destroy

  after_save :recalculate_scale_ladder!

  # Soft delete
  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  # Lifecycle
  scope :running, -> {
    now = Time.current
    active.where("stages.starts_at <= ?", now).where("stages.ends_at >= ?", now)
  }

  # Validations
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validates :lower_participants_limit, numericality: {greater_than_or_equal_to: 0}
  validate :ends_at_after_starts_at
  validate :at_least_one_semester
  validate :at_least_one_question
  validate :scale_max_greater_than_min, if: :with_scale?

  def self.upcoming
    active.where("stages.starts_at > ?", Time.current)
  end

  def self.past
    active.where("stages.ends_at < ?", Time.current)
  end

  def self.current
    running.first
  end

  def upcoming?
    Time.current < starts_at
  end

  def current?
    current_time = Time.current
    current_time.between?(starts_at, ends_at)
  end

  def past?
    ends_at < Time.current
  end

  def soft_delete!
    update_column(:deleted_at, Time.current)
  end

  def deleted?
    deleted_at.present?
  end

  def calculation_rule_klass
    CalculationRules::V2019Spring
  end

  def converted_scale_ladder
    return unless with_scale?
    calculation_rule_klass.converted_scale_ladder(stage: self)
  end

  def recalculate_scale_ladder!
    return unless with_scale?
    ladder = calculation_rule_klass.recalculate_scale_ladder!(stage: self)
    update_attribute(:scale_ladder, ladder)
  end

  private

  def ends_at_after_starts_at
    return if starts_at.blank? || ends_at.blank?
    errors.add(:ends_at, "должна быть позже даты начала") if ends_at <= starts_at
  end

  def at_least_one_semester
    errors.add(:semesters, "необходимо выбрать хотя бы один семестр") if semesters.empty?
  end

  def at_least_one_question
    errors.add(:questions, "необходимо выбрать хотя бы один вопрос") if questions.empty?
  end

  def scale_max_greater_than_min
    return if scale_min.blank? || scale_max.blank?
    errors.add(:scale_max, "должна быть больше минимальной оценки") if scale_max <= scale_min
  end
end
```

- [ ] **Step 5: Run tests**

Run: `bundle exec rspec spec/models/stage_spec.rb`
Expected: All tests pass.

- [ ] **Step 6: Run linter**

Run: `bundle exec standardrb app/models/stage.rb spec/models/stage_spec.rb spec/factories/stage_factory.rb --fix`

- [ ] **Step 7: Commit**

```bash
git add app/models/stage.rb spec/models/stage_spec.rb spec/factories/stage_factory.rb
git commit -m "Add validations, scopes, and soft delete to Stage model"
```

---

### Task 3: Setup Stimulus via Vite for admin

**Files:**
- Create: `app/frontend/entrypoints/admin.js`
- Create: `app/frontend/admin/controllers/index.js`
- Modify: `app/views/layouts/admin.html.slim`
- Modify: `package.json` (via yarn add)

- [ ] **Step 1: Install Stimulus**

Run: `yarn add @hotwired/stimulus`

- [ ] **Step 2: Create Stimulus application entrypoint**

Create `app/frontend/admin/controllers/index.js`:

```javascript
import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Controllers will be registered here as they are created
import ToggleFieldsController from "./toggle_fields_controller"
import NewQuestionController from "./new_question_controller"
import ConfirmModalController from "./confirm_modal_controller"

application.register("toggle-fields", ToggleFieldsController)
application.register("new-question", NewQuestionController)
application.register("confirm-modal", ConfirmModalController)

export { application }
```

Create placeholder controllers so the import doesn't fail:

Create `app/frontend/admin/controllers/toggle_fields_controller.js`:
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  toggle(event) {
    const checked = event.target.checked
    this.containerTarget.classList.toggle("hidden", !checked)
    this.containerTarget.querySelectorAll("input, select").forEach((input) => {
      input.disabled = !checked
    })
  }
}
```

Create `app/frontend/admin/controllers/new_question_controller.js`:
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]
  static values = { index: { type: Number, default: 0 } }

  add() {
    const html = this.templateTarget.innerHTML.replace(/NEW_INDEX/g, this.indexValue)
    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.indexValue++
  }

  remove(event) {
    event.target.closest("[data-new-question-target='entry']").remove()
  }
}
```

Create `app/frontend/admin/controllers/confirm_modal_controller.js`:
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }
}
```

- [ ] **Step 3: Create admin Vite entrypoint**

Create `app/frontend/entrypoints/admin.js`:

```javascript
import "../admin/controllers/index"
```

- [ ] **Step 4: Update admin layout to use Vite**

Replace line 22 in `app/views/layouts/admin.html.slim`:

Replace:
```slim
    = javascript_include_tag :admin
    = yield :javascript
```

With:
```slim
    = vite_javascript_tag 'admin'
```

- [ ] **Step 5: Verify admin layout loads**

Run: `bin/vite dev` and open `http://localhost:3000/admin/stages` in browser.
Expected: Page loads, Stimulus initializes (check console for no errors).

- [ ] **Step 6: Commit**

```bash
git add app/frontend/admin/ app/frontend/entrypoints/admin.js app/views/layouts/admin.html.slim package.json yarn.lock
git commit -m "Setup Stimulus via Vite for admin area"
```

---

### Task 4: Admin controller — full CRUD actions

**Files:**
- Modify: `app/controllers/admin/stages_controller.rb`

- [ ] **Step 1: Implement controller**

Replace `app/controllers/admin/stages_controller.rb` with:

```ruby
class Admin::StagesController < Admin::BaseController
  load_and_authorize_resource

  def index
    @stages = Stage.active.order(starts_at: :desc)
  end

  def show
    respond_to do |format|
      format.html {}
      format.xlsx do
        io_string = Stages::ProgressReport.run!(stage: @stage)
        send_data(
          io_string,
          filename: "ВыгрузкаПоФакультетам-#{I18n.l(Time.current, format: :slug)}.xlsx",
          disposition: "attachment",
          type: Mime::Type.lookup_by_extension(:xlsx)
        )
      end
    end
  end

  def new
    @stage = Stage.new(
      lower_participants_limit: 10,
      scale_min: 6,
      scale_max: 10,
      lower_truncation_percent: 5,
      upper_truncation_percent: 5,
      with_scale: true,
      with_truncation: true
    )
    load_form_collections
  end

  def create
    @stage = Stage.new(stage_params.except(:new_questions_attributes))
    create_and_attach_new_questions
    if @stage.save
      redirect_to admin_stage_path(@stage), notice: "Стадия успешно создана"
    else
      load_form_collections
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form_collections
  end

  def update
    @stage.assign_attributes(stage_params.except(:new_questions_attributes))
    create_and_attach_new_questions
    if @stage.save
      redirect_to admin_stage_path(@stage), notice: "Стадия успешно обновлена"
    else
      load_form_collections
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @stage.soft_delete!
    redirect_to admin_stages_path, notice: "Стадия удалена"
  end

  private

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

  def load_form_collections
    @semesters = Semester.order(year_begin: :desc, kind: :asc)
    @questions = Question.order(:text)
  end

  def create_and_attach_new_questions
    new_attrs = stage_params[:new_questions_attributes]
    return if new_attrs.blank?

    new_attrs.each_value do |attrs|
      next if attrs[:text].blank?
      question = Question.create!(text: attrs[:text], max_rating: attrs[:max_rating] || 10)
      @stage.questions << question
    end
  end
end
```

- [ ] **Step 2: Run linter**

Run: `bundle exec standardrb app/controllers/admin/stages_controller.rb --fix`

- [ ] **Step 3: Commit**

```bash
git add app/controllers/admin/stages_controller.rb
git commit -m "Implement full CRUD actions in Admin::StagesController"
```

---

### Task 5: Form partial — _form.html.slim

**Files:**
- Create: `app/views/admin/stages/_form.html.slim`
- Create: `app/views/admin/stages/new.html.slim`
- Create: `app/views/admin/stages/edit.html.slim`

- [ ] **Step 1: Create form partial**

Create `app/views/admin/stages/_form.html.slim`:

```slim
= form_with model: [:admin, @stage], class: "space-y-8" do |f|

  / Ошибки валидации
  - if @stage.errors.any?
    .bg-red-50.border.border-red-200.rounded-lg.p-4.mb-6
      h3.text-red-800.font-semibold.text-sm.mb-2 Ошибки при сохранении:
      ul.list-disc.pl-5.text-red-700.text-sm
        - @stage.errors.full_messages.each do |message|
          li = message

  / Секция 1: Основное
  .bg-white.rounded-xl.border.border-gray-200.p-6
    h2.text-lg.font-semibold.text-gray-900.mb-4 Даты и семестры

    .grid.grid-cols-1.md_grid-cols-2.gap-6
      div
        = f.label :starts_at, "Дата начала", class: "block text-sm font-medium text-gray-700 mb-1"
        = f.datetime_local_field :starts_at, class: "w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus_ring-2 focus_ring-primary focus_border-primary outline-none"
      div
        = f.label :ends_at, "Дата окончания", class: "block text-sm font-medium text-gray-700 mb-1"
        = f.datetime_local_field :ends_at, class: "w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus_ring-2 focus_ring-primary focus_border-primary outline-none"

    .mt-6
      p.text-sm.font-medium.text-gray-700.mb-3 Семестры
      .flex.flex-wrap.gap-3
        - @semesters.each do |semester|
          label.flex.items-center.gap-2.px-4.py-2.rounded-lg.border.border-gray-200.cursor-pointer.hover_bg-gray-50.transition-colors.duration-200.text-sm class=(f.object.semester_ids.include?(semester.id) ? "bg-primary-50 border-primary" : "")
            = f.check_box :semester_ids, { multiple: true, checked: f.object.semester_ids.include?(semester.id) }, semester.id, nil
            = semester.full_title.capitalize

  / Секция 2: Вопросы
  .bg-white.rounded-xl.border.border-gray-200.p-6
    h2.text-lg.font-semibold.text-gray-900.mb-4 Критерии оценивания

    / Существующие вопросы
    - if @questions.any?
      .space-y-2.mb-6
        - @questions.each do |question|
          label.flex.items-center.gap-3.px-4.py-3.rounded-lg.border.border-gray-200.cursor-pointer.hover_bg-gray-50.transition-colors.duration-200 class=(f.object.question_ids.include?(question.id) ? "bg-primary-50 border-primary" : "")
            = f.check_box :question_ids, { multiple: true, checked: f.object.question_ids.include?(question.id) }, question.id, nil
            .flex-1
              span.text-sm.font-medium.text-gray-900 = question.text
              span.text-xs.text-gray-500.ml-2 (макс. оценка: #{question.max_rating})

    / Новые вопросы (Stimulus)
    div data-controller="new-question"
      div data-new-question-target="list"

      template data-new-question-target="template"
        .flex.items-start.gap-3.p-4.rounded-lg.border.border-dashed.border-gray-300.bg-gray-50.mb-3 data-new-question-target="entry"
          .flex-1.space-y-3
            div
              label.block.text-sm.font-medium.text-gray-700.mb-1 Текст вопроса
              input type="text" name="stage[new_questions_attributes][NEW_INDEX][text]" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus_ring-2 focus_ring-primary focus_border-primary outline-none" placeholder="Введите текст вопроса" required="required"
            div
              label.block.text-sm.font-medium.text-gray-700.mb-1 Макс. оценка
              input type="number" name="stage[new_questions_attributes][NEW_INDEX][max_rating]" value="10" min="1" class="w-24 rounded-lg border border-gray-300 px-3 py-2 text-sm focus_ring-2 focus_ring-primary focus_border-primary outline-none"
          button.shrink-0.mt-6.px-3.py-2.text-sm.text-red-600.hover_bg-red-50.rounded-lg.transition-colors.duration-200.border-0.bg-transparent.cursor-pointer type="button" data-action="new-question#remove" Удалить

      button.inline-flex.items-center.gap-2.px-4.py-2.text-sm.font-medium.text-primary.border.border-primary.rounded-lg.hover_bg-primary-50.transition-colors.duration-200.cursor-pointer.bg-transparent type="button" data-action="new-question#add"
        | + Создать новый вопрос

  / Секция 3: Параметры
  .bg-white.rounded-xl.border.border-gray-200.p-6
    h2.text-lg.font-semibold.text-gray-900.mb-4 Параметры

    .mb-6
      = f.label :lower_participants_limit, "Минимум участников", class: "block text-sm font-medium text-gray-700 mb-1"
      = f.number_field :lower_participants_limit, min: 0, class: "w-32 rounded-lg border border-gray-300 px-3 py-2 text-sm focus_ring-2 focus_ring-primary focus_border-primary outline-none"

    / Шкалирование
    div.mb-6 data-controller="toggle-fields"
      label.flex.items-center.gap-2.cursor-pointer.mb-3
        = f.check_box :with_scale, data: { toggle_fields_target: "checkbox", action: "toggle-fields#toggle" }
        span.text-sm.font-medium.text-gray-700 Включить шкалирование
      .pl-6 data-toggle-fields-target="container" class=(f.object.with_scale? ? "" : "hidden")
        .grid.grid-cols-2.gap-4.max-w-xs
          div
            = f.label :scale_min, "Мин. оценка", class: "block text-sm font-medium text-gray-700 mb-1"
            = f.number_field :scale_min, disabled: !f.object.with_scale?, class: "w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus_ring-2 focus_ring-primary focus_border-primary outline-none"
          div
            = f.label :scale_max, "Макс. оценка", class: "block text-sm font-medium text-gray-700 mb-1"
            = f.number_field :scale_max, disabled: !f.object.with_scale?, class: "w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus_ring-2 focus_ring-primary focus_border-primary outline-none"

    / Обрезка
    div data-controller="toggle-fields"
      label.flex.items-center.gap-2.cursor-pointer.mb-3
        = f.check_box :with_truncation, data: { toggle_fields_target: "checkbox", action: "toggle-fields#toggle" }
        span.text-sm.font-medium.text-gray-700 Включить обрезку
      .pl-6 data-toggle-fields-target="container" class=(f.object.with_truncation? ? "" : "hidden")
        .grid.grid-cols-2.gap-4.max-w-xs
          div
            = f.label :lower_truncation_percent, "Нижний порог (%)", class: "block text-sm font-medium text-gray-700 mb-1"
            = f.number_field :lower_truncation_percent, min: 0, max: 50, disabled: !f.object.with_truncation?, class: "w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus_ring-2 focus_ring-primary focus_border-primary outline-none"
          div
            = f.label :upper_truncation_percent, "Верхний порог (%)", class: "block text-sm font-medium text-gray-700 mb-1"
            = f.number_field :upper_truncation_percent, min: 0, max: 50, disabled: !f.object.with_truncation?, class: "w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus_ring-2 focus_ring-primary focus_border-primary outline-none"

  / Кнопки
  .flex.items-center.gap-3
    = f.submit (f.object.persisted? ? "Сохранить" : "Создать стадию"), class: "px-6 py-2.5 bg-primary text-white rounded-lg hover_bg-primary-700 transition-colors duration-200 text-sm font-medium cursor-pointer border-0"
    = link_to "Отмена", (f.object.persisted? ? admin_stage_path(f.object) : admin_stages_path), class: "px-6 py-2.5 text-gray-600 bg-gray-100 rounded-lg hover_bg-gray-200 transition-colors duration-200 text-sm font-medium no-underline"
```

- [ ] **Step 2: Create new.html.slim**

Create `app/views/admin/stages/new.html.slim`:

```slim
.mb-6
  h1.text-2xl.font-bold.text-gray-900 Новая стадия
  p.text-gray-500.text-sm.mt-1 Заполните параметры стадии анкетирования.

= render "form"
```

- [ ] **Step 3: Create edit.html.slim**

Create `app/views/admin/stages/edit.html.slim`:

```slim
.mb-6
  h1.text-2xl.font-bold.text-gray-900 Редактирование стадии
  p.text-gray-500.text-sm.mt-1 Рейтинг НПР с #{l(@stage.starts_at, format: :only_date)} по #{l(@stage.ends_at, format: :only_date)}

= render "form"
```

- [ ] **Step 4: Commit**

```bash
git add app/views/admin/stages/new.html.slim app/views/admin/stages/edit.html.slim app/views/admin/stages/_form.html.slim
git commit -m "Add stage form partial with new/edit views"
```

---

### Task 6: Update index and show views

**Files:**
- Modify: `app/views/admin/stages/index.html.slim`
- Modify: `app/views/admin/stages/show.html.slim`

- [ ] **Step 1: Update index**

Replace `app/views/admin/stages/index.html.slim` with:

```slim
.mb-8
  .flex.flex-col.md_flex-row.items-start.md_items-center.justify-between.gap-4.mb-6
    div
      h1.text-2xl.font-bold.text-gray-900 Стадии анкетирования
      p.text-gray-500.text-sm.mt-1 Управление стадиями, статистика участия и результаты.
    = link_to "Новая стадия", new_admin_stage_path, class: "inline-flex items-center px-4 py-2 bg-primary text-white rounded-lg hover_bg-primary-700 transition-colors duration-200 text-sm font-medium no-underline"

- if @stages.any?
  .space-y-3
    - @stages.each do |stage|
      .p-5.bg-white.rounded-xl.border.border-gray-200.hover_shadow-md.hover_border-gray-300.transition-all.duration-200.group
        .flex.items-center.justify-between
          div
            = link_to admin_stage_path(stage), class: "no-underline" do
              h5.text-base.font-semibold.text-gray-900.group-hover_text-primary.transition-colors.duration-200 Рейтинг НПР с #{l(stage.starts_at, format: :only_date)} по #{l(stage.ends_at, format: :only_date)}
            p.text-sm.text-gray-500.mt-1 = stage_semesters_list(stage).capitalize
          .flex.items-center.gap-3
            - if stage.current?
              span.shrink-0.inline-flex.items-center.px-3.py-1.rounded-full.text-xs.font-semibold.bg-emerald-100.text-emerald-700 Активная
            - elsif stage.upcoming?
              span.shrink-0.inline-flex.items-center.px-3.py-1.rounded-full.text-xs.font-semibold.bg-amber-100.text-amber-700 Предстоящая
            - else
              span.shrink-0.inline-flex.items-center.px-3.py-1.rounded-full.text-xs.font-semibold.bg-gray-100.text-gray-500 Завершена
            = link_to "Редактировать", edit_admin_stage_path(stage), class: "text-sm text-primary hover_underline no-underline"
- else
  .text-center.py-12
    p.text-gray-500 Стадии пока не созданы
```

- [ ] **Step 2: Update show**

Replace `app/views/admin/stages/show.html.slim` with:

```slim
.mb-6.flex.items-start.justify-between
  div
    h1.text-2xl.font-bold.text-gray-900 Рейтинг НПР с #{l(@stage.starts_at, format: :only_date)} по #{l(@stage.ends_at, format: :only_date)}
    p.text-sm.text-gray-500.mt-1 = stage_semesters_list(@stage).capitalize
  .flex.items-center.gap-2
    = link_to "Редактировать", edit_admin_stage_path(@stage), class: "px-4 py-2 text-sm font-medium text-primary border border-primary rounded-lg hover_bg-primary-50 transition-colors duration-200 no-underline"
    div data-controller="confirm-modal"
      button.px-4.py-2.text-sm.font-medium.text-red-600.border.border-red-300.rounded-lg.hover_bg-red-50.transition-colors.duration-200.cursor-pointer.bg-transparent type="button" data-action="confirm-modal#open"
        | Удалить
      dialog.rounded-xl.border.border-gray-200.shadow-xl.p-0.backdrop_bg-black.backdrop_bg-opacity-40 data-confirm-modal-target="dialog"
        .p-6
          h3.text-lg.font-semibold.text-gray-900.mb-2 Подтверждение удаления
          p.text-sm.text-gray-600.mb-6 Вы уверены, что хотите удалить эту стадию? Данные не будут потеряны, стадия будет скрыта.
          .flex.justify-end.gap-3
            button.px-4.py-2.text-sm.font-medium.text-gray-600.bg-gray-100.rounded-lg.hover_bg-gray-200.transition-colors.cursor-pointer.border-0 type="button" data-action="confirm-modal#close" Отмена
            = button_to "Да, удалить", admin_stage_path(@stage), method: :delete, class: "px-4 py-2 text-sm font-medium text-white bg-red-600 rounded-lg hover_bg-red-700 transition-colors cursor-pointer border-0"

/ Критерии оценивания
.bg-white.rounded-xl.border.border-gray-200.p-6.mt-6
  h3.text-lg.font-semibold.text-gray-900.mb-3 Критерии оценивания
  - if @stage.questions.any?
    .space-y-2
      - @stage.questions.each do |question|
        .flex.items-center.justify-between.px-4.py-3.rounded-lg.bg-gray-50
          span.text-sm.font-medium.text-gray-900 = question.text
          span.text-xs.text-gray-500 макс. оценка: #{question.max_rating}
  - else
    p.text-sm.text-gray-500 Критерии не назначены

/ Параметры
.bg-white.rounded-xl.border.border-gray-200.p-6.mt-6
  h3.text-lg.font-semibold.text-gray-900.mb-3 Параметры

  .grid.grid-cols-1.md_grid-cols-3.gap-4.text-sm
    div
      span.text-gray-500 Мин. участников:
      span.font-medium.text-gray-900.ml-1 = @stage.lower_participants_limit

    div
      span.text-gray-500 Шкалирование:
      - if @stage.with_scale?
        span.font-medium.text-gray-900.ml-1 #{@stage.scale_min} — #{@stage.scale_max}
      - else
        span.text-gray-400.ml-1 выключено

    div
      span.text-gray-500 Обрезка:
      - if @stage.with_truncation?
        span.font-medium.text-gray-900.ml-1 #{@stage.lower_truncation_percent}% / #{@stage.upper_truncation_percent}%
      - else
        span.text-gray-400.ml-1 выключена

/ Отчёты
.bg-white.rounded-xl.border.border-gray-200.overflow-hidden.mt-6
  .px-4.py-3.bg-gray-50.border-b.border-gray-200.font-medium.text-sm Выгрузка по факультетам
  .p-4
    p.text-sm.text-gray-600.mb-3 Выгружает информацию о количестве участников по каждому факультету.
    = link_to "Скачать", admin_stage_path(@stage, format: :xlsx), class: "inline-flex items-center px-4 py-2 bg-primary text-white rounded-lg hover_bg-primary-700 transition-colors text-sm font-medium no-underline"
```

- [ ] **Step 3: Commit**

```bash
git add app/views/admin/stages/index.html.slim app/views/admin/stages/show.html.slim
git commit -m "Update stage index and show views with CRUD actions"
```

---

### Task 7: Verify everything works end-to-end

- [ ] **Step 1: Start servers**

Run: `foreman start -f Procfile.dev`

- [ ] **Step 2: Test create flow**

1. Open `http://localhost:3000/admin/stages`
2. Click "Новая стадия"
3. Fill dates, select semesters, select questions, click "Создать новый вопрос" to add one
4. Toggle scale and truncation on/off
5. Submit

Expected: Stage created, redirected to show page with all data.

- [ ] **Step 3: Test edit flow**

1. From show page, click "Редактировать"
2. Change dates, add/remove semesters and questions
3. Submit

Expected: Stage updated, redirected to show with changes.

- [ ] **Step 4: Test delete flow**

1. From show page, click "Удалить"
2. Confirm in modal
3. Expected: Redirected to index, stage no longer visible

- [ ] **Step 5: Run linter on all changed files**

Run: `bundle exec standardrb app/controllers/admin/stages_controller.rb app/models/stage.rb --fix`

- [ ] **Step 6: Run all tests**

Run: `bundle exec rspec`
Expected: All tests pass, including new stage_spec.rb.

- [ ] **Step 7: Final commit if any fixes**

```bash
git add -A
git commit -m "Fix issues from end-to-end testing"
```
