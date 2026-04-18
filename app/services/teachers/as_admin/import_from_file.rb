require "roo"

module Teachers
  module AsAdmin
    class ImportFromFile
      HEADERS = {
        "ФИО" => :name,
        "СНИЛС" => :snils,
        "ID в 1С" => :external_id
      }.freeze

      Result = Struct.new(:created, :skipped, :failed, keyword_init: true) do
        def total
          created.size + skipped.size + failed.size
        end
      end

      Error = Struct.new(:row, :messages, keyword_init: true)
      Skip  = Struct.new(:row, :reason, keyword_init: true)

      def self.call(file_path:, extension:)
        new(file_path: file_path, extension: extension).call
      end

      def initialize(file_path:, extension:)
        @file_path = file_path
        @extension = extension.to_s.downcase.delete(".")
      end

      def call
        created = []
        skipped = []
        failed = []

        parse_rows.each_with_index do |row_data, idx|
          row_number = idx + 2 # header is row 1

          if row_data.values.all?(&:blank?)
            next
          end

          if row_data[:name].blank?
            failed << Error.new(row: row_number, messages: ["ФИО не указано"])
            next
          end

          snils = Snils.normalize(row_data[:snils])
          if snils.blank?
            failed << Error.new(row: row_number, messages: ["СНИЛС не указан"])
            next
          end
          unless snils.match?(/\A\d{11}\z/)
            failed << Error.new(row: row_number, messages: ["СНИЛС должен содержать 11 цифр"])
            next
          end

          encrypted = Snils.encrypt(snils)
          if Teacher.exists?(encrypted_snils: encrypted)
            skipped << Skip.new(row: row_number, reason: "Преподаватель с таким СНИЛС уже существует")
            next
          end

          teacher = Teacher.new(
            name: row_data[:name].to_s.strip,
            snils: snils,
            external_id: row_data[:external_id].presence,
            origin: :manual,
            kind: :common
          )

          if teacher.save
            created << teacher
          else
            failed << Error.new(row: row_number, messages: teacher.errors.full_messages)
          end
        end

        Result.new(created: created, skipped: skipped, failed: failed)
      end

      private

      def parse_rows
        spreadsheet = open_spreadsheet
        sheet = spreadsheet.sheet(0)
        header_row = sheet.row(1).map { |c| c.to_s.strip }
        column_map = HEADERS.each_with_object({}) do |(title, key), memo|
          idx = header_row.index(title)
          memo[key] = idx if idx
        end

        raise ArgumentError, "Не найдены обязательные колонки: #{missing_columns(column_map).join(", ")}" if missing_columns(column_map).any?

        last_row = sheet.last_row
        return [] if last_row.nil? || last_row < 2

        (2..last_row).map do |i|
          row = sheet.row(i)
          {
            name: cell_value(row[column_map[:name]]),
            snils: cell_value(row[column_map[:snils]]),
            external_id: cell_value(row[column_map[:external_id]])
          }
        end
      end

      def missing_columns(column_map)
        required = [:name, :snils]
        required.select { |k| column_map[k].nil? }.map { |k| HEADERS.key(k) }
      end

      def cell_value(raw)
        return nil if raw.nil?
        return raw.to_i.to_s if raw.is_a?(Float) && raw == raw.to_i
        raw.to_s.strip.presence
      end

      def open_spreadsheet
        case @extension
        when "xlsx" then Roo::Excelx.new(@file_path)
        when "csv"  then Roo::CSV.new(@file_path)
        else
          raise ArgumentError, "Неподдерживаемый формат: #{@extension}"
        end
      end
    end
  end
end
