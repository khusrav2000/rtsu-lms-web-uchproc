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
import MainFilterIndex from '@canvas/uchproc-main-filter/react/index'
import configureStore from './store/configureStore'
import initialState from './store/initialState'
import IsuPredmet from './components/IsuPredmet'
import IsuTema from './components/IsuTema'
import IsuJournal from './components/IsuJournal'
import IsuAddTopicModal from './components/IsuAddTopicModal'
import JournalActions from './actions/JournalActions'
import I18n from 'i18n!account_course_user_search'

const store = configureStore(initialState)
const props = {
  store
}
export default class AttendanceJournalIndex extends React.Component {
  afterTopicSave = () => {
    const reloadTopics = store.getState().journal.reloadTopics
    store.dispatch(JournalActions.reloadTopics(!reloadTopics))
    // const journal = store.getState().journal.attendance
    // journal.header = [true].concat(journa.header)
    // console.log('New Header', journal.header)
    // store.dispatch(JournalActions.setAttendance(journal))
  }

  render() {
    return (
      <div className="">
        <div className="row attendance-journal-body">
          <div className="row row-1">
            <div className="col component-uchproc-base uchproc_tables mainfilter-container">
              <MainFilterIndex {...props} />
            </div>
            <div className="col attendance-courses-topics">
              <div className="attendance-predmet-container">
                <IsuPredmet {...props} />
              </div>
            </div>
          </div>
          <div className="row row-2">
            <IsuJournal {...props} />
          </div>
        </div>
      </div>
    )
  }
}
