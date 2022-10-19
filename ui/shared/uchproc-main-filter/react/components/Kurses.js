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
import HeaderActions from '../actions/UchprocMainFilterActions'
import I18n from 'i18n!UchprocMainFilter'

export default class Kurses extends React.Component {
  constructor(props) {
    super(props)
    const {data, activeFaculty, activeSpecialty, activeKurs} = props.store.getState().header
    this.state = {
      kurses: data.faculties[activeFaculty].specialties[activeSpecialty].years,
      activeKurs
    }
  }

  componentDidMount() {
    this.unsubscribe = this.props.store.subscribe(this.handleStateChange)
  }

  handleStateChange = () => {
    const {data, activeFaculty, activeSpecialty, activeKurs} = this.props.store.getState().header
    this.setState({
      kurses: data.faculties[activeFaculty].specialties[activeSpecialty].years,
      activeKurs
    })
  }

  selectKurs(index) {
    this.props.store.dispatch(HeaderActions.selectKurs(index))
  }

  render() {
    return (
      <table className="table-bordered table-hover table-sm">
        <thead>
          <th>{I18n.t('Kurses')}</th>
        </thead>
        <tbody>
          {this.state.kurses.map((kurs, index) => (
            <tr
              className={index === this.state.activeKurs ? 'selected' : ''}
              id={`krs_${kurs.id}`}
              onClick={() => this.selectKurs(index)}
            >
              <td>{kurs.code}</td>
            </tr>
          ))}
        </tbody>
      </table>
    )
  }
}
