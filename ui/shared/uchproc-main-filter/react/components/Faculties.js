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

export default class Faculties extends React.Component {
  constructor(props) {
    super(props)
    const {data, activeFaculty} = props.store.getState().header
    this.state = {
      faculties: data.faculties,
      activeFaculty
    }
  }

  componentDidMount() {
    this.unsubscribe = this.props.store.subscribe(this.handleStateChange)
  }

  handleStateChange = () => {
    const {data, activeFaculty} = this.props.store.getState().header
    this.setState({faculties: data.faculties, activeFaculty})
  }

  selectFaculty(index) {
    this.props.store.dispatch(HeaderActions.selectFaculty(index))
  }

  render() {
    return (
      <table className="table-bordered table-hover table-sm">
        <thead>
          <th>{I18n.t('Faculties')}</th>
        </thead>
        <tbody>
          {this.state.faculties.map((faculty, index) => (
            <tr
              className={index === this.state.activeFaculty ? 'selected' : ''}
              id={`fac_${faculty.id}`}
              onClick={() => this.selectFaculty(index)}
            >
              <td title={faculty.name}>{faculty.code}</td>
            </tr>
          ))}
        </tbody>
      </table>
    )
  }
}
