/*
 * Copyright (C) 2020 - present Istiqlolsoft, Inc.
 *
 * This file is part of Uchproc canvas.
 *
 * Uchproc canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import I18n from 'i18n!PointJournal'
import React from 'react'
import CourseActions from '../actions/CourseActions'
import axios from 'axios'
import {isEmpty} from 'lodash'
import LoadingIndicator from '@canvas/loading-indicator'

export default class CoursesForm extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      courses: props.store.getState().course.courses,
      isLoading: props.store.getState().course.isLoading,
      activeCourse: props.store.getState().course.activeCourse,
      loadingSuccess: props.store.getState().course.loadingSuccess
    }
  }

  componentDidMount() {
    this.unsubscribe = this.props.store.subscribe(this.handleStateChange)
  }

  handleStateChange = () => {
    const {
      courses,
      isLoading,
      activeGroupID,
      activeCourse,
      loadingSuccess
    } = this.props.store.getState().course
    this.setState({
      courses,
      isLoading,
      activeCourse,
      loadingSuccess
    })
    this.updateCourses(this.props.store.getState().header, activeGroupID, loadingSuccess)
  }

  updateCourses(header, activeGroupId) {
    const {data, activeFaculty, activeSpecialty, activeKurs, activeGroup, isLoading} = header
    if (!isEmpty(data) && !isLoading) {
      const selectedGroupId =
        data.faculties[activeFaculty].specialties[activeSpecialty].kurses[activeKurs].groups[
          activeGroup
        ].id

      if (selectedGroupId !== activeGroupId) {
        this.props.store.dispatch(CourseActions.loadingCourses(selectedGroupId))
        axios
          .get('/api/v1/uchproc/group/' + selectedGroupId.toString() + '/last/courses')
          .then(res => {
            this.props.store.dispatch(CourseActions.gotCourses(res.data, selectedGroupId))
          })
          .catch(() => {
            this.props.store.dispatch(CourseActions.errorLoadingCourses())
          })
      }
    }
  }

  selectCourse(index) {
    this.props.store.dispatch(CourseActions.selectCourse(index))
  }

  render() {
    const {isLoading, activeCourse, loadingSuccess} = this.state
    if (!isLoading && loadingSuccess) {
      return (
        <div>
          <table className="table-bordered table-hover table-sm table-journal-courses">
            <thead>
              <tr>
                <th className="course-name-column">{I18n.t('Course name')}</th>
                <th className="date-column">{I18n.t('Date')}</th>
                <th className="teacher-column">{I18n.t('Teachers')}</th>
              </tr>
            </thead>
            <tbody>
              {this.state.courses.map((course, index) => (
                <tr
                  className={index === activeCourse ? 'selected' : ''}
                  onClick={() => this.selectCourse(index)}
                >
                  <td className="course-name-column">{course.course_name}</td>
                  <td className="date-column">{course.start_date}</td>
                  <td className="teacher-column">{course.teacher_name}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )
    } else if (!isLoading) {
      return <div>SERVER ERROR</div>
    } else {
      return <LoadingIndicator />
    }
  }
}
