/*
 * Copyright (C) 2020 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
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

import React from 'react'

class PostAttendance extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      disabled: true
    }
  }

  postAttendance(grp, kvd, data) {
    fetch('http://localhost:2222/api/v1/?uri="isustd/attendance/group/' + grp + '/kvd/' + kvd + '"')
      .then(response => response.json())
      .then(data => {
        this.setState({journal: data, isLoading: false})
      })
      .catch(err => console.error(this.props.url, err.toString()))
  }

  render() {
    if (this.props.disabled)
      return (
        <button variant="primary" onClick={() => alert(this.props.attendance)}>
          {' '}
          Cохранить{' '}
        </button>
      )
    return (
      <button variant="primary" disabled>
        {' '}
        Cохранить{' '}
      </button>
    )
  }
}
export default PostAttendance
