# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_04_07_190210) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "answers", force: :cascade do |t|
    t.bigint "question_id"
    t.bigint "stage_id"
    t.bigint "teacher_id"
    t.integer "ratings", array: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["question_id"], name: "index_answers_on_question_id"
    t.index ["ratings"], name: "index_answers_on_ratings", using: :gin
    t.index ["stage_id"], name: "index_answers_on_stage_id"
    t.index ["teacher_id"], name: "index_answers_on_teacher_id"
  end

  create_table "data_migrations", primary_key: "version", id: :string, force: :cascade do |t|
  end

  create_table "faculties", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "aliases", default: [], array: true
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.string "value"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "grade_books", force: :cascade do |t|
    t.bigint "student_id"
    t.bigint "faculty_id"
    t.string "major", null: false
    t.string "external_id", null: false
    t.integer "grade_num", null: false
    t.string "group_num", null: false
    t.integer "time_type", default: 0, null: false
    t.integer "grade_level", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["faculty_id"], name: "index_grade_books_on_faculty_id"
    t.index ["student_id"], name: "index_grade_books_on_student_id"
  end

  create_table "participations", force: :cascade do |t|
    t.bigint "stage_id"
    t.bigint "student_id"
    t.bigint "teacher_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["stage_id"], name: "index_participations_on_stage_id"
    t.index ["student_id"], name: "index_participations_on_student_id"
    t.index ["teacher_id"], name: "index_participations_on_teacher_id"
  end

  create_table "poll_answers", force: :cascade do |t|
    t.bigint "poll_id"
    t.bigint "poll_option_id"
    t.index ["poll_id"], name: "index_poll_answers_on_poll_id"
    t.index ["poll_option_id"], name: "index_poll_answers_on_poll_option_id"
  end

  create_table "poll_faculty_participants", force: :cascade do |t|
    t.bigint "poll_id"
    t.bigint "faculty_id"
    t.index ["faculty_id"], name: "index_poll_faculty_participants_on_faculty_id"
    t.index ["poll_id"], name: "index_poll_faculty_participants_on_poll_id"
  end

  create_table "poll_options", force: :cascade do |t|
    t.bigint "poll_id"
    t.string "title", null: false
    t.string "description"
    t.text "image_data"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["poll_id"], name: "index_poll_options_on_poll_id"
  end

  create_table "poll_participations", force: :cascade do |t|
    t.bigint "poll_id"
    t.bigint "student_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["poll_id"], name: "index_poll_participations_on_poll_id"
    t.index ["student_id"], name: "index_poll_participations_on_student_id"
  end

  create_table "polls", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "starts_at", precision: nil, null: false
    t.datetime "ends_at", precision: nil, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "archived_at", precision: nil
  end

  create_table "questions", force: :cascade do |t|
    t.string "text", null: false
    t.integer "max_rating", default: 10, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "questions_stages", id: false, force: :cascade do |t|
    t.bigint "stage_id"
    t.bigint "question_id"
    t.index ["question_id"], name: "index_questions_stages_on_question_id"
    t.index ["stage_id"], name: "index_questions_stages_on_stage_id"
  end

  create_table "semesters", force: :cascade do |t|
    t.integer "year_begin"
    t.integer "year_end"
    t.integer "kind"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "semesters_stages", id: false, force: :cascade do |t|
    t.bigint "semester_id"
    t.bigint "stage_id"
    t.index ["semester_id"], name: "index_semesters_stages_on_semester_id"
    t.index ["stage_id"], name: "index_semesters_stages_on_stage_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "stage_attendees", force: :cascade do |t|
    t.bigint "student_id"
    t.bigint "stage_id"
    t.integer "choosing_status", default: 0, null: false
    t.integer "fetching_status", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["stage_id"], name: "index_stage_attendees_on_stage_id"
    t.index ["student_id"], name: "index_stage_attendees_on_student_id"
  end

  create_table "stages", force: :cascade do |t|
    t.datetime "starts_at", precision: nil, null: false
    t.datetime "ends_at", precision: nil, null: false
    t.integer "lower_participants_limit", default: 10, null: false
    t.integer "scale_min", default: 6, null: false
    t.integer "scale_max", default: 10, null: false
    t.integer "lower_truncation_percent", default: 5, null: false
    t.integer "upper_truncation_percent", default: 5, null: false
    t.string "scale_ladder", array: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "with_scale", default: true, null: false
    t.boolean "with_truncation", default: true, null: false
  end

  create_table "students", force: :cascade do |t|
    t.string "external_id", null: false
    t.string "name"
    t.boolean "enabled", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["external_id"], name: "index_students_on_external_id"
  end

  create_table "students_teachers_relations", force: :cascade do |t|
    t.bigint "student_id"
    t.bigint "teacher_id"
    t.bigint "semester_id"
    t.string "disciplines", array: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "choosen", default: false, null: false
    t.string "origin"
    t.bigint "stage_id"
    t.index ["semester_id"], name: "index_students_teachers_relations_on_semester_id"
    t.index ["stage_id"], name: "index_students_teachers_relations_on_stage_id"
    t.index ["student_id"], name: "index_students_teachers_relations_on_student_id"
    t.index ["teacher_id"], name: "index_students_teachers_relations_on_teacher_id"
  end

  create_table "survey_answers", force: :cascade do |t|
    t.bigint "survey_id", null: false
    t.bigint "survey_question_id", null: false
    t.bigint "survey_option_id", null: false
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["survey_id"], name: "index_survey_answers_on_survey_id"
    t.index ["survey_option_id"], name: "index_survey_answers_on_survey_option_id"
    t.index ["survey_question_id"], name: "index_survey_answers_on_survey_question_id"
    t.index ["user_id"], name: "index_survey_answers_on_user_id"
  end

  create_table "survey_options", force: :cascade do |t|
    t.bigint "survey_question_id"
    t.string "text"
    t.boolean "custom", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["survey_question_id"], name: "index_survey_options_on_survey_question_id"
  end

  create_table "survey_questions", force: :cascade do |t|
    t.bigint "survey_id", null: false
    t.string "text"
    t.boolean "required", default: true, null: false
    t.boolean "multichoice", default: false, null: false
    t.boolean "free_answer", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["survey_id"], name: "index_survey_questions_on_survey_id"
  end

  create_table "survey_sharings", force: :cascade do |t|
    t.bigint "survey_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["survey_id"], name: "index_survey_sharings_on_survey_id"
    t.index ["user_id"], name: "index_survey_sharings_on_user_id"
  end

  create_table "surveys", force: :cascade do |t|
    t.bigint "user_id"
    t.boolean "private", default: true, null: false
    t.boolean "anonymous", default: true, null: false
    t.string "title", null: false
    t.string "passcode", null: false
    t.date "active_until", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_surveys_on_user_id"
  end

  create_table "teachers", force: :cascade do |t|
    t.string "external_id"
    t.string "name"
    t.string "snils"
    t.boolean "enabled", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "kind", default: 0
    t.string "encrypted_snils"
    t.string "stale_external_id"
    t.index ["external_id"], name: "index_teachers_on_external_id"
  end

  create_table "teachers_rosters", force: :cascade do |t|
    t.bigint "stage_id"
    t.bigint "teacher_id"
    t.string "kind"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["kind"], name: "index_teachers_rosters_on_kind"
    t.index ["stage_id"], name: "index_teachers_rosters_on_stage_id"
    t.index ["teacher_id"], name: "index_teachers_rosters_on_teacher_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "identity_url", null: false
    t.string "nickname", null: false
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.integer "role", default: 0, null: false
    t.string "kind_type"
    t.bigint "kind_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.bigint "teacher_id"
    t.bigint "student_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["identity_url"], name: "index_users_on_identity_url", unique: true
    t.index ["kind_type", "kind_id"], name: "index_users_on_kind_type_and_kind_id"
    t.index ["student_id"], name: "index_users_on_student_id"
    t.index ["teacher_id"], name: "index_users_on_teacher_id"
  end

  add_foreign_key "answers", "questions"
  add_foreign_key "answers", "stages"
  add_foreign_key "answers", "teachers"
  add_foreign_key "grade_books", "faculties"
  add_foreign_key "grade_books", "students"
  add_foreign_key "participations", "stages"
  add_foreign_key "participations", "students"
  add_foreign_key "participations", "teachers"
  add_foreign_key "poll_answers", "poll_options"
  add_foreign_key "poll_answers", "polls"
  add_foreign_key "poll_faculty_participants", "faculties"
  add_foreign_key "poll_faculty_participants", "polls"
  add_foreign_key "poll_options", "polls"
  add_foreign_key "poll_participations", "polls"
  add_foreign_key "poll_participations", "students"
  add_foreign_key "questions_stages", "questions"
  add_foreign_key "questions_stages", "stages"
  add_foreign_key "semesters_stages", "semesters"
  add_foreign_key "semesters_stages", "stages"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "stage_attendees", "stages"
  add_foreign_key "stage_attendees", "students"
  add_foreign_key "students_teachers_relations", "semesters"
  add_foreign_key "students_teachers_relations", "students"
  add_foreign_key "students_teachers_relations", "teachers"
  add_foreign_key "survey_answers", "survey_options"
  add_foreign_key "survey_answers", "survey_questions"
  add_foreign_key "survey_answers", "surveys"
  add_foreign_key "survey_answers", "users"
  add_foreign_key "survey_questions", "surveys"
  add_foreign_key "survey_sharings", "surveys"
  add_foreign_key "survey_sharings", "users"
  add_foreign_key "surveys", "users"
  add_foreign_key "users", "students"
  add_foreign_key "users", "teachers"
end
