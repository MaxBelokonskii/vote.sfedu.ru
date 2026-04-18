require "rails_helper"

RSpec.describe Poll::FacultyParticipant do
  describe "associations" do
    it "belongs to poll and faculty" do
      poll = create(:poll)
      faculty = create(:faculty)
      fp = Poll::FacultyParticipant.create!(poll: poll, faculty: faculty)

      expect(fp.poll).to eq(poll)
      expect(fp.faculty).to eq(faculty)
    end
  end

  it "makes faculty available through poll" do
    poll = create(:poll)
    faculty = create(:faculty)
    Poll::FacultyParticipant.create!(poll: poll, faculty: faculty)

    expect(poll.faculties.reload).to include(faculty)
  end
end
