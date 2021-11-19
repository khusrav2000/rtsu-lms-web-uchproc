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
import CoursesForm from './components/CoursesForm'
import MainFilterIndex from '@canvas/uchproc-main-filter/react/index'
import configureStore from './store/configureStore'
import initialState from './store/initialState'
import JournalPoints from './components/JournalPoints'

const store = configureStore(initialState)
const props = {
  store
}
export default class PointJournalIndex extends React.Component {
  render() {
    return (
      <table className="table-component">
        <tbody>
          <tr>
            <td className="component-uchproc-base uchproc_tables">
              <MainFilterIndex {...props} />
            </td>
            <td className="component-uchproc-courses uchproc_tables">
              <CoursesForm {...props} />
            </td>
          </tr>
          <tr>
            <td className="component-uchproc-journal uchproc_tables">
              <JournalPoints {...props} showFirstRatingWeeks showSecondRatingWeeks />
            </td>
          </tr>
        </tbody>
      </table>
    )
  }
}
