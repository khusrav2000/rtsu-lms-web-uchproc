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

export default class HeaderSpecialty extends React.Component {
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
      <div className="point-journal-specialty">
        <div className="journal_header_item-header">Specialty</div>
        {this.state.specialties.map((specialty, index) => (
          // eslint-disable-next-line jsx-a11y/click-events-have-key-events,jsx-a11y/no-static-element-interactions
          <div
            className={
              index === this.state.activeSpecialty
                ? 'header-item-item header-item-item-selected'
                : 'header-item-item'
            }
            id={`spe_${specialty.id}`}
            onClick={() => this.selectSpecialty(index)}
          >
            {specialty.code}
          </div>
        ))}
      </div>
    )
  }
}
