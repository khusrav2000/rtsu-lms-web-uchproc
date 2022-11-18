/*
 * Copyright (C) 2020 - present Istiqlolsoft, Inc.
 *
 * This file is part of Uchproc canvas.
 *
 * Uchproc canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 4 of the License.
 *
 * Uchproc canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import axios from 'axios'
import LoadingIndicator from '@canvas/loading-indicator'
import JournalActions from '../actions/JournalActions'
import I18n from 'i18n!account_course_user_search'

class IsuPredmet extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      grp: 0,
      subjects: [],
      kvd: 0,
      isLoading: false
    }
  }

  componentDidMount() {
    this.unsubscribe = this.props.store.subscribe(this.handleStateChange)
  }

  handleStateChange = () => {
    const {data, activeFaculty, activeSpecialty, activeKurs, activeGroup} =
      this.props.store.getState().header
    const grpID =
      data.faculties[activeFaculty].specialties[activeSpecialty].years[activeKurs].groups[
        activeGroup
      ].id
    if (this.state.grp !== grpID) {
      this.setState(
        {
          isLoading: true,
          grp: grpID
        },
        function () {
          this.loadSubjects(grpID)
        }
      )
    }
  }

  loadSubjects(grp) {
    // console.log("Loading Subjects with GroupID: "+grp)
    axios
      .get('/api/v1/uchproc/group/' + grp + '/attendance_journal/courses')
      .then(res => {
        this.setState({subjects: res.data, kvd: res.data[0].attendance_id, isLoading: false})
        // console.log('------------Subjects loaded successfull--------',this.state.subjects)
        this.props.store.dispatch(JournalActions.setActiveKvdID(this.state.kvd))
      })
      .catch(() => {
        //  console.error(this.props.url, err.toString())
        alert('Не удалось загрузить данные')
        this.setState({isLoading: false})
      })
  }

  _subjectClick(id) {
    this.props.store.dispatch(JournalActions.setActiveKvdID(id))
    this.setState({
      kvd: id
    })
  }

  emptyRows() {
    const rows = []
    console.log('subjects length: ' + this.state.subjects.length)
    for (let i = this.state.subjects.length; i < 7; i++) {
      rows.push(
        <div className="row predmet-line">
          <div className="col name" />
          <div className="col teacher" />
          <div className="col other" />
        </div>
      )
    }
    return rows
  }

  render() {
    if (this.state.subjects.length === 0 || this.state.isLoading) return <LoadingIndicator />
    return (
      <div>
        <table className="table-bordered table-hover table-sm table-journal-courses">
          <thead>
            <tr>
              <th className="course-name-column">{I18n.t('Course name')}</th>
              <th className="teacher-column">{I18n.t('Teachers')}</th>
              <th className="credit-column">{I18n.t('Credit number')}</th>
            </tr>
          </thead>
          <tbody>
            {this.state.subjects.map(item => (
              <tr
                className={item.attendance_id === this.state.kvd ? 'selected' : ''}
                onClick={this._subjectClick.bind(this, item.attendance_id)}
              >
                <td className="course-name-column">{item.course_name.trim()}</td>
                <td className="teacher-column">{item.teacher_name.trim()}</td>
                <td className="credit-column">{item.credits_count}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    )
  }
}
export default IsuPredmet
