import api from '../../api/request';

export default {
  index: (stageId) => api.get(`/api/students_api/stages/${stageId}/teachers.json`),
  rosterIndex: (stageId) => api.get(`/api/students_api/stages/${stageId}/roster.json`),
  newFeedback: (stageId, teacherId) => api.get(`/api/students_api/stages/${stageId}/teachers/${teacherId}/feedback.json`),
  leaveFeedback: (stageId, teacherId, answers) => api.post(
    `/api/students_api/stages/${stageId}/teachers/${teacherId}/feedback.json`,
    { feedback: { answers } }
  ),
  refreshTeachers: (stageId) => api.post(`/api/students_api/stages/${stageId}/teachers/refresh`)
};
