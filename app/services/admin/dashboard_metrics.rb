module Admin
  class DashboardMetrics
    CACHE_KEY = "admin_dashboard_metrics"
    CACHE_TTL = 5.minutes

    def self.call
      Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) { new.call }
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

    private

    def current_stage
      @current_stage ||= Stage.current
    end

    def kpi_metrics
      {
        students_count: Student.count,
        teachers_count: Teacher.active.count,
        manual_teachers_count: Teacher.active.origin_manual.count,
        students_participated: current_stage_student_participation,
        active_polls_count: Poll.not_archived.active.count,
        surveys_count: Survey.count,
        active_surveys_count: Survey.where("active_until >= ?", Date.current).count
      }
    end

    def current_stage_section
      return nil unless current_stage

      participations = current_stage.participations
      unique_students = participations.distinct.count(:student_id)
      unique_teachers = participations.distinct.count(:teacher_id)

      teachers_below_limit = participations
        .group(:teacher_id)
        .having("COUNT(*) < ?", current_stage.lower_participants_limit)
        .count
        .size

      {
        id: current_stage.id,
        starts_at: current_stage.starts_at,
        ends_at: current_stage.ends_at,
        participations_count: participations.count,
        unique_students: unique_students,
        unique_teachers: unique_teachers,
        teachers_below_limit: teachers_below_limit,
        lower_participants_limit: current_stage.lower_participants_limit,
        by_faculty: faculty_breakdown(current_stage)
      }
    end

    def faculty_breakdown(stage)
      faculty_ids = Faculty.pluck(:id, :name)
      student_counts = GradeBook.group(:faculty_id).distinct.count(:student_id)
      participant_counts = Participation
        .where(stage: stage)
        .joins(student: :grade_books)
        .group("grade_books.faculty_id")
        .distinct
        .count("participations.student_id")

      faculty_ids.map do |id, name|
        students_count = student_counts[id] || 0
        participants = participant_counts[id] || 0
        {
          name: name,
          students_count: students_count,
          participants_count: participants,
          coverage: students_count.positive? ? (participants * 100.0 / students_count).round(1) : 0
        }
      end.sort_by { |row| -row[:coverage] }
    end

    def active_polls_section
      Poll.not_archived.active
        .includes(:options)
        .limit(5)
        .map { |poll| poll_summary(poll) }
    end

    def poll_summary(poll)
      total_votes = poll.answers.count
      options = poll.options.map do |option|
        votes = option.answers.count
        {
          text: option.title,
          votes: votes,
          percentage: total_votes.positive? ? (votes * 100.0 / total_votes).round(1) : 0
        }
      end.sort_by { |o| -o[:votes] }.first(3)

      {
        id: poll.id,
        name: poll.name,
        starts_at: poll.starts_at,
        ends_at: poll.ends_at,
        total_votes: total_votes,
        top_options: options
      }
    end

    def recent_surveys_section
      Survey.order(created_at: :desc).limit(5).map do |survey|
        {
          id: survey.id,
          title: survey.title,
          passcode: survey.passcode,
          active_until: survey.active_until,
          respondents_count: survey.answers.distinct.count(:user_id),
          creator_name: survey.user&.name.presence || survey.user&.email || "—"
        }
      end
    end

    def participation_trend_30d
      start_date = 30.days.ago.to_date
      raw = Participation.where("created_at >= ?", start_date.beginning_of_day)
        .group(Arel.sql("DATE(created_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Moscow')"))
        .count

      (start_date..Date.current).map do |date|
        {date: date, count: raw[date] || 0}
      end
    end

    def teacher_kinds_distribution
      counts = Teacher.active.group(:kind).count
      {
        common: counts["common"] || 0,
        physical_education: counts["physical_education"] || 0,
        foreign_language: counts["foreign_language"] || 0
      }
    end

    def data_quality_checks
      checks = [
        {
          label: "Студенты без зачётных книжек",
          count: Student.without_grade_books.length,
          level: :warning
        },
        {
          label: "Преподаватели без СНИЛС",
          count: Teacher.active.where(encrypted_snils: [nil, ""]).count,
          level: :critical
        },
        {
          label: "Преподаватели с устаревшим ID в 1С",
          count: Teacher.active.where.not(stale_external_id: nil).count,
          level: :warning
        }
      ]

      if current_stage
        checks << {
          label: "Преподаватели без оценок в текущей стадии",
          count: teachers_without_participations_in(current_stage),
          level: :warning
        }
      end

      checks
    end

    def teachers_without_participations_in(stage)
      total_teachers = stage.teachers_rosters.distinct.count(:teacher_id)
      teachers_with_participations = stage.participations.distinct.count(:teacher_id)
      [total_teachers - teachers_with_participations, 0].max
    end

    def user_activity_section
      {
        sign_ins_7d: User.where("last_sign_in_at >= ?", 7.days.ago).count,
        sign_ins_30d: User.where("last_sign_in_at >= ?", 30.days.ago).count,
        total_users: User.count
      }
    end

    def current_stage_student_participation
      return {count: 0, total: Student.count, stage_active: false} unless current_stage

      {
        count: current_stage.participations.distinct.count(:student_id),
        total: Student.count,
        stage_active: true
      }
    end
  end
end
