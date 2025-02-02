# frozen_string_literal: true

#
# Copyright (C) 2014 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#
require_relative "../../api_spec_helper"

describe Quizzes::QuizExtensionsController, type: :request do
  before :once do
    course_factory
    @quiz = @course.quizzes.create!(title: "quiz")
    @quiz.published_at = Time.now
    @quiz.workflow_state = "available"
    @quiz.save!
    @student = student_in_course(course: @course, active_all: true).user
  end

  describe "POST /api/v1/courses/:course_id/quizzes/:quiz_id/extensions (create)" do
    def api_create_quiz_extension(quiz_extension_params, opts = {})
      api_call(:post,
               "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/extensions",
               { controller: "quizzes/quiz_extensions",
                 action: "create",
                 format: "json",
                 course_id: @course.id.to_s,
                 quiz_id: @quiz.id.to_s },
               { quiz_extensions: quiz_extension_params },
               { "Accept" => "application/vnd.api+json" },
               opts)
    end

    context "as a student" do
      it "is unauthorized" do
        quiz_extension_params = [
          { user_id: @student.id, extra_attempts: 2 },
        ]
        raw_api_call(:post,
                     "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/extensions",
                     { controller: "quizzes/quiz_extensions",
                       action: "create",
                       format: "json",
                       course_id: @course.id.to_s,
                       quiz_id: @quiz.id.to_s },
                     { quiz_extensions: quiz_extension_params },
                     { "Accept" => "application/vnd.api+json" })
        assert_forbidden
      end
    end

    context "as a teacher" do
      before :once do
        @student1 = @student
        @student2 = student_in_course(course: @course, active_all: true).user
        @teacher  = teacher_in_course(course: @course, active_all: true).user
      end

      it "extends attempts for a existing submission" do
        quiz_submission = @quiz.generate_submission(@student1)
        quiz_submission.grants_right?(@teacher, :add_attempts)

        quiz_extension_params = [
          { user_id: @student1.id, extra_attempts: 2 }
        ]
        res = api_create_quiz_extension(quiz_extension_params)
        expect(res["quiz_extensions"][0]["extra_attempts"]).to eq 2
      end

      it "extends attempts for a new submission" do
        quiz_extension_params = [
          { user_id: @student1.id, extra_attempts: 2 }
        ]
        res = api_create_quiz_extension(quiz_extension_params)
        expect(res["quiz_extensions"][0]["extra_attempts"]).to eq 2
      end

      it "extends attempts for multiple students" do
        quiz_extension_params = [
          { user_id: @student1.id, extra_attempts: 2 },
          { user_id: @student2.id, extra_attempts: 3 }
        ]
        res = api_create_quiz_extension(quiz_extension_params)
        expect(res["quiz_extensions"][0]["extra_attempts"]).to eq 2
        expect(res["quiz_extensions"][1]["extra_attempts"]).to eq 3
      end
    end
  end
end
