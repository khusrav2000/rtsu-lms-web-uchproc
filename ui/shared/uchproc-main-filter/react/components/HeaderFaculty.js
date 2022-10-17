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

export default class HeaderFaculty extends React.Component {
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
      <div className="point-journal-faculty">
        <div className="journal_header_item-header">Faculty</div>
        {this.state.faculties.map((faculty, index) => (
          // eslint-disable-next-line jsx-a11y/click-events-have-key-events,jsx-a11y/no-static-element-interactions
          <div
            className={
              index === this.state.activeFaculty
                ? 'header-item-item header-item-item-selected'
                : 'header-item-item'
            }
            id={`fac_${faculty.id}`}
            onClick={() => this.selectFaculty(index)}
          >
            {faculty.code}
          </div>
        ))}
      </div>
    )
  }
}
