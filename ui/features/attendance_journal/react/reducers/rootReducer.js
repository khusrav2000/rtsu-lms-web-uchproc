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

import initialState from '../store/initialState'
import {combineReducers} from 'redux'
import mainFilterListHandles from '@canvas/uchproc-main-filter/react/reducers/UchprocMainFilterReducer'

const journalListHandler = {
  SET_ACTIVE_GRP_ID(state, action) {
    return {
      ...state,
      activeGrpID: action.activeGrpID
    }
  },
  SET_ACTIVE_KVD_ID(state, action) {
    return {
      ...state,
      activeKvdID: action.activeKvdID
    }
  },
  SET_TOPICS_KOL(state, action) {
    return {
      ...state,
      topicsKol: action.topicsKol
    }
  },
  SET_COURSES_LOADING(state, action) {
    return {
      ...state,
      coursesLoading: action.coursesLoading
    }
  },
  SET_TOPIC_CNZAP(state, action) {
    return {
      ...state,
      topicCnzap: action.topicCnzap
    }
  },
  SET_ATTENDANCE(state, action) {
    return {
      ...state,
      attendance: action.attendance
    }
  },
  SET_ACTIVE_TOPIC(state, action) {
    return {
      ...state,
      activeTopic: action.activeTopic
    }
  },
  RELOAD_TOPICS(state, action) {
    return {
      ...state,
      reloadTopics: action.reloadTopics
    }
  }
}

const makeReducer = handlerList => (state = initialState, action) => {
  const handler = handlerList[action.type]
  if (handler) return handler({...state}, action)
  return state
}

export default combineReducers({
  header: makeReducer(mainFilterListHandles),
  journal: makeReducer(journalListHandler)
})
