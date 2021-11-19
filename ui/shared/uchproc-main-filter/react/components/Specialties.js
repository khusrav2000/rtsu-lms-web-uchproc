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

export default class Specialties extends React.Component {
  constructor(props) {
    super(props)
    const {data, activeFaculty, activeSpecialty} = props.store.getState().header
    this.state = {
      specialties: data.faculties[activeFaculty].specialties,
      activeSpecialty
    }
  }

  componentDidMount() {
    this.unsubscribe = this.props.store.subscribe(this.handleStateChange)
  }

  handleStateChange = () => {
    const {data, activeFaculty, activeSpecialty} = this.props.store.getState().header
    this.setState({specialties: data.faculties[activeFaculty].specialties, activeSpecialty})
  }

  selectSpecialty(index) {
    this.props.store.dispatch(HeaderActions.selectSpecialty(index))
  }

  render() {
    return (
      <table className="table-bordered table-hover table-sm">
        <thead>
          <th>{I18n.t('Specialties')}</th>
        </thead>
        <tbody>
          {this.state.specialties.map((specialty, index) => (
            <tr
              className={index === this.state.activeSpecialty ? 'selected' : ''}
              id={`spe_${specialty.id}`}
              onClick={() => this.selectSpecialty(index)}
            >
              <td title={specialty.name}>{specialty.code}</td>
            </tr>
          ))}
        </tbody>
      </table>
    )
  }
}
