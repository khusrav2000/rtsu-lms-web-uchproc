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
import {isEmpty} from 'lodash'
import JournalActions from '../actions/JournalActions'
import axios from 'axios'
import LoadingIndicator from '@canvas/loading-indicator'
// import KeyboardEventHandler from 'react-keyboard-event-handler'
import UpdateWeekPointModal from './UpdateWeekPointModal'
import {Button} from '@instructure/ui-buttons'
import I18n from 'i18n!PointJournal'

export default class JournalPoints extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      points: props.store.getState().journal.points,
      journalHeader: props.store.getState().journal.header,
      isLoading: props.store.getState().journal.isLoading,
      loadingSuccess: props.store.getState().journal.loadingSuccess,
      activeCourseID: props.store.getState().journal.activeCourseID,
      showFirstRatingWeeks: props.showFirstRatingWeeks,
      showSecondRatingWeeks: props.showFirstRatingWeeks
    }
    if (props.showFirstRatingWeeks) {
      this.setState({showFirstRatingWeeks: props.showFirstRatingWeeks})
    }
    if (props.showSecondRatingWeeks) {
      this.setState({showSecondRatingWeeks: props.showSecondRatingWeeks})
    }
  }

  componentDidMount() {
    this.unsubscribe = this.props.store.subscribe(this.handleStateChange)
    if (this.props.courseId) {
      this.updateJournalWithCourseId(this.props.courseId)
    }
  }

  handleStateChange = () => {
    const {points, journalHeader, isLoading, activeCourseID, loadingSuccess} =
      this.props.store.getState().journal
    this.setState({
      points,
      journalHeader,
      isLoading,
      loadingSuccess,
      activeCourseID
    })
    if (!this.props.courseId) {
      const isLoadingCourse = this.props.store.getState().course.isLoading
      if (isLoadingCourse) {
        if (!isEmpty(points)) {
          this.props.store.dispatch(JournalActions.gotJournalData([], {}))
        }
        this.setState({isLoading: true})
      }
      this.updateJournal(this.props.store.getState().course, activeCourseID)
    }
  }

  updateJournalWithCourseId(courseId) {
    // courseId = 48782
    this.props.store.dispatch(JournalActions.loadingJournalData(courseId))
    axios
      .get('/api/v1/courses/' + courseId.toString() + '/point_journal')
      .then(res => {
       
        this.props.store.dispatch(JournalActions.gotJournalData(res.data.students, res.data.header))
      })
      .catch(() => {
        this.props.store.dispatch(JournalActions.errorLoadingJournalData())
      })
  }

  updateJournal(course, activeCourseID) {
    const {courses, activeCourse} = course
    const isLoadingCourse = course.isLoading
    if (!isEmpty(courses) && !isLoadingCourse) {
      const selectedCourseId = courses[activeCourse].point_id
      // const selectedCourseId = 48782
      if (selectedCourseId !== activeCourseID) {
        this.props.store.dispatch(JournalActions.loadingJournalData(selectedCourseId))
        axios
          .get('/api/v1/courses/' + selectedCourseId.toString() + '/point_journal')
          .then(res => {
            console.log(res.data.header)
            this.props.store.dispatch(
              JournalActions.gotJournalData(res.data.students, res.data.header)
            )
          })
          .catch(() => {
            this.props.store.dispatch(JournalActions.errorLoadingJournalData())
          })
      }
    }
  }

  afterPointRegistrationSave = responseData => {
    this.props.store.dispatch(
      JournalActions.gotJournalData(responseData.points, responseData.header)
    )
  }

  weekPoints(rating, index) {
    return this.state.points.map(row => {
      if (rating === 'FIRST_RATING') {
        return {
          name: row.name,
          studentId: row.id,
          recordBook: row.record_book,
          weekPoint: row.first_rating[index]
        }
      } else {
        return {
          name: row.name,
          studentId: row.id,
          recordBook: row.record_book,
          weekPoint: row.second_rating[index]
        }
      }
    })
  }

  changeShowRatingWeeksState(ratingNumber) {
    console.log('CLICK RATING NUMBER!!!')
    if (ratingNumber === 1) {
      this.setState(prevState => {
        return {showFirstRatingWeeks: !prevState.showFirstRatingWeeks}
      })
    } else if (ratingNumber === 2) {
      this.setState(prevState => {
        return {showSecondRatingWeeks: !prevState.showSecondRatingWeeks}
      })
    }
  }

  tableHead() {
    console.log("12312312312")
    console.log(this.state.journalHeader.rating.first)
    const firstRating = this.state.journalHeader.rating.first
    const secondRating = this.state.journalHeader.rating.second
    return (
      <tr>
        <th>
          <Button size="small" disabled variant="ghost">
            №
          </Button>
        </th>
        <th>
          <Button size="small" disabled variant="ghost">
            {I18n.t('Full name')}
          </Button>
        </th>
        {this.state.showFirstRatingWeeks &&
          firstRating.map((week, index) => (
            <th>
              <UpdateWeekPointModal
                weekNumber={week.number}
                weekPoints={this.weekPoints('FIRST_RATING', index)}
                journalHeader={this.state.journalHeader}
                afterSave={this.afterPointRegistrationSave}
                courseID={this.state.activeCourseID}
                isEditable={week.is_editable}
              >
                <Button size="small" variant={week.is_editable ? 'success' : 'ghost'}>
                  {week.number}
                </Button>
              </UpdateWeekPointModal>
            </th>
          ))}
        <th>
          <Button
            size="small"
            variant="ghost"
            onClick={() => this.changeShowRatingWeeksState(1)}
            color="success"
          >
            {I18n.t('sumR1')}
          </Button>
        </th>
        {this.state.showSecondRatingWeeks &&
          secondRating.map((week, index) => (
            <th>
              <UpdateWeekPointModal
                weekNumber={week.number}
                weekPoints={this.weekPoints('SECOND_RATING', index)}
                journalHeader={this.state.journalHeader}
                afterSave={this.afterPointRegistrationSave}
                courseID={parseInt(this.state.activeCourseID, 10)}
                isEditable={week.is_editable}
              >
                <Button size="small" variant={week.is_editable ? 'success' : 'ghost'}>
                  {week.number}
                </Button>
              </UpdateWeekPointModal>
            </th>
          ))}
        <th>
          <Button
            size="small"
            variant="ghost"
            onClick={() => this.changeShowRatingWeeksState(2)}
            color="success"
          >
            {I18n.t('sumR2')}
          </Button>
        </th>
        <th>
          <Button size="small" disabled variant="ghost">
            {I18n.t('exam')}
          </Button>
        </th>
        <th>
          <Button size="small" disabled variant="ghost">
            {I18n.t('exam-fx')}
          </Button>
        </th>
        <th>
          <Button size="small" disabled variant="ghost">
            {I18n.t('exam-f')}
          </Button>
        </th>
        <th>
          <Button size="small" disabled variant="ghost">
            {I18n.t('total')}
          </Button>
        </th>
        <th>
          <Button size="small" disabled variant="ghost">
            {I18n.t('asses(E)')}
          </Button>
        </th>
        <th>
          <Button size="small" disabled variant="ghost">
            {I18n.t('asses(W)')}
          </Button>
        </th>
        <th>
          <Button size="small" disabled variant="ghost">
            {I18n.t('assess')}
          </Button>
        </th>
      </tr>
    )
  }

  tableRow(row, index) {
    const firstRating = row.first_rating
    const secondRating = row.second_rating
    return (
      <tr>
        <td className="row-number">{index + 1}</td>
        <td className="full_name">{row.name}</td>
        {this.state.showFirstRatingWeeks &&
          firstRating.map(week => (
            <td>
              <input type="text" value={week.point.toFixed(2)} />
            </td>
          ))}
        <td>
          <input type="text" value={row.first_rating_sum.toFixed(2)} />
        </td>
        {this.state.showSecondRatingWeeks &&
          secondRating.map(week => (
            <td>
              <input type="text" value={week.point.toFixed(2)} />
            </td>
          ))}
        <td>
          <input type="text" value={row.second_rating_sum.toFixed(2)} />
        </td>
        
      </tr>
    )
  }

  keyPress = event => {
    console.log(event)
    console.log('KEY PRESS')
  }

  render() {
    if (!isEmpty(this.state.points) && !this.state.isLoading && this.state.loadingSuccess) {
      return (
        <table className="table-bordered table-sm table-hover table-journal-points">
          <thead>{this.tableHead()}</thead>
          <tbody>{this.state.points.map((row, index) => this.tableRow(row, index))}</tbody>
        </table>
      )
    } else if (!this.state.loadingSuccess) {
      return <div>SERVER ERROR</div>
    } else if (isEmpty(this.state.points) && !this.state.isLoading) {
      return <div>EMPTY DATA</div>
    } else {
      return <LoadingIndicator />
    }
  }
}
