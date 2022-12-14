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
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import I18n from 'i18n!account_course_user_search'
import {Button} from '@instructure/ui-buttons'
import React from 'react'
import {func, number, element, arrayOf, object, bool} from 'prop-types'
import update from 'immutability-helper'
import axios from 'axios'

const FLOAT_POINT = /^[0-9]{0,2}[.]{0,1}[0-9]{0,2}$/
let MAX_POINTS = [
  12.5, // MAX_POINT
  2.0, // MAX_LECTURE_ATT_POINT
  1.0, // MAX_PRACTICAL_ATT_POINT
  1.0, // MAX_PRACTICAL_ACT_POINT
  2.0, // MAX_KMDRO_ATT_POINT
  3.5, // MAX_KMDROL_ACT_POINT
  6.0 // MAX_KMD_POINT
]
export default class UpdateWeekPointModal extends React.Component {
  static propTypes = {
    weekNumber: number.isRequired,
    children: element.isRequired,
    weekPoints: arrayOf(object).isRequired,
    journalHeader: object.isRequired,
    afterSave: func.isRequired,
    courseID: number.isRequired,
    isEditable: bool.isRequired
  }

  constructor(props) {
    super(props)
    this.state = {
      open: false,
      weekPoints: props.weekPoints,
      activeRow: 0,
      activeColumn: 1,
      activeSaveButton: true
    }
    console.log(this.state.weekPoints)
    MAX_POINTS = [props.journalHeader.max_week_point]
  }

  componentDidMount() {
    // myFocusRef.current.focus()
  }

  close = () => {
    this.setState({open: false, weekPoints: this.props.weekPoints})
  }

  onSubmit = () => {
    this.setState({activeSaveButton: false})
    console.log('asdasd', this.state.weekPoints)
    axios({
      url: `/api/v1/courses/${this.props.courseID}/point_journal`,
      method: 'POST',
      data: {
        week_number: this.props.weekNumber,
        students_points: this.state.weekPoints
      }
    })
      .then(response => {
        $.flashMessage(I18n.t('Points for week saved successfully!'))
        this.setState({open: false, activeSaveButton: true})
        if (this.props.afterSave) this.props.afterSave(response.data)
      })
      .catch(error => {
        $.flashError('Something went wrong saving week points.')
        this.setState({activeSaveButton: true})
      })
  }

  onFocusRow(row, column, event) {
    this.setState({activeRow: row, activeColumn: column})
    // event.target.select()
  }

  onKeyPress(event, row, column) {
    if (event.key === 'ArrowDown') {
      this.setState(prevState => {
        let newState = prevState
        const rowsCount = prevState.weekPoints.length
        const prevActiveRow = prevState.activeRow
        newState = update(newState, {
          activeRow: {$set: (prevActiveRow + 1) % rowsCount}
        })
        return newState
      })
      const rowsCount = this.state.weekPoints.length
      row = (row + 1) % rowsCount
    } else if (event.key === 'ArrowUp') {
      this.setState(prevState => {
        let newState = prevState
        const rowsCount = prevState.weekPoints.length
        const prevActiveRow = prevState.activeRow
        newState = update(newState, {
          activeRow: {$set: (prevActiveRow - 1 + rowsCount) % rowsCount}
        })
        return newState
      })
      const rowsCount = this.state.weekPoints.length
      row = (row - 1 + rowsCount) % rowsCount
    }
    const inputPoint = document.getElementById(`point_${row}_${column}`)
    inputPoint.focus()
  }

  onKeyUp(event, row, column) {
    const inputPoint = document.getElementById(`point_${row}_${column}`)
    if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
      inputPoint.select()
    }
  }

  onChange(event, row, column) {
    if (!this.props.isEditable) {
      return
    }
    const newValue = event.target.value
    this.setState(prevState => {
      let newState = prevState
      if (!FLOAT_POINT.test(newValue)) {
        return newState
      }
      if (column == 0) {
        newState = update(newState, {
          weekPoints: {[row]: {weekPoint: {point: {$set: newValue}}}}
        })
      } else {
        newState = update(newState, {
          weekPoints: {[row]: {weekPoint: {divided: this.chaneInputState(newValue)[column - 1]}}}
        })
      }
      return newState
    })
  }

  chaneInputState(newValue) {
    return [
      {lecture_att: {$set: newValue}},
      {practical_att: {$set: newValue}},
      {practical_act: {$set: newValue}},
      {KMDRO_att: {$set: newValue}},
      {KMDRO_act: {$set: newValue}},
      {KMD: {$set: newValue}}
    ]
  }

  getColumnValue(row) {
    return [
      {value: this.state.weekPoints[row].weekPoint.divided.lecture_att},
      {value: this.state.weekPoints[row].weekPoint.divided.practical_att},
      {value: this.state.weekPoints[row].weekPoint.divided.practical_act},
      {value: this.state.weekPoints[row].weekPoint.divided.KMDRO_att},
      {value: this.state.weekPoints[row].weekPoint.divided.KMDRO_act},
      {value: this.state.weekPoints[row].weekPoint.divided.KMD}
    ]
  }

  onBlur(row, column) {
    if (column == 0) {
      this.setState(prevState => {
        const point = Math.min(parseFloat(prevState.weekPoints[row].weekPoint.point), MAX_POINTS[0])
        return update(prevState, {
          weekPoints: {
            [row]: {
              weekPoint: {
                point: {$set: point.toFixed(2).toString()}
              }
            }
          }
        })
      })
      return
    }
    let value = parseFloat(this.getColumnValue(row)[column - 1].value)
    if (Number.isNaN(value)) {
      value = 0.0
    }
    let point = this.getColumnValue(row).reduce((prevValue, currentValue) => {
      let cValue = parseFloat(currentValue.value)
      if (Number.isNaN(cValue)) {
        cValue = 0.0
      }
      return prevValue + cValue
    }, 0.0)
    point -= value
    value = Math.min(MAX_POINTS[0] - point, MAX_POINTS[column], value)
    point += value
    this.setState(prevState => {
      return update(prevState, {
        weekPoints: {
          [row]: {
            weekPoint: {
              point: {$set: point.toFixed(2).toString()},
              divided: this.chaneInputState(value.toFixed(2).toString())[column - 1]
            }
          }
        }
      })
    })
  }

  modalBodyByTotal() {
    return (
      <table className="table table-bordered table-sm table-hover table-point-registration">
        <thead>
          <tr>
            <th>{I18n.t('Sum')}</th>
            <th>{I18n.t('Student full name')}</th>
            <th>{I18n.t('Record book number')}</th>
          </tr>
        </thead>
        <tbody>
          {this.state.weekPoints.map((row, index) => (
            <tr>
              <td>
                <input
                  id={`point_${index}_${0}`}
                  type="text"
                  onKeyDown={event => this.onKeyPress(event, index, 0)}
                  onKeyUp={event => this.onKeyUp(event, index, 0)}
                  maxLength="5"
                  value={row.weekPoint.point}
                  onFocus={event => this.onFocusRow(index, 0, event)}
                  onChange={event => this.onChange(event, index, 0)}
                  onBlur={() => this.onBlur(index, 0)}
                />
              </td>
              <td className="student-information-align">{row.name}</td>
              <td className="student-information-align">{row.recordBook}</td>
            </tr>
          ))}
        </tbody>
      </table>
    )
  }

  render() {
    return (
      <span>
        <Modal
          label={`${I18n.t('Point Registration')} ${I18n.t('Week')} ${this.props.weekNumber}`}
          onDismiss={this.close}
          open={this.state.open}
          size="large"
        >
          <Modal.Body>{this.modalBodyByTotal()}</Modal.Body>
          <Modal.Footer>
            <Button onClick={this.close}>{I18n.t('Cancel')}</Button> &nbsp;
            <Button
              onClick={this.onSubmit}
              variant="primary"
              interaction={
                this.state.activeSaveButton && this.props.isEditable ? 'enabled' : 'disabled'
              }
            >
              {I18n.t('Save')}
            </Button>
          </Modal.Footer>
        </Modal>
        {React.Children.map(this.props.children, child =>
          // when you click whatever is the child element to this, open the modal
          React.cloneElement(child, {
            onClick: (...args) => {
              if (child.props.onClick) child.props.onClick(...args)
              this.setState({open: true})
            }
          })
        )}
      </span>
    )
  }
}
