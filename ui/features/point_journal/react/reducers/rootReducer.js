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

const courseListHandler = {
  LOADING_COURSES(state, action) {
    return {
      ...state,
      isLoading: true,
      activeGroupID: action.activeGroupID,
      activeCourse: 0
    }
  },
  GOT_COURSES(state, action) {
    return {
      ...state,
      isLoading: false,
      courses: action.courses,
      loadingSuccess: true
    }
  },
  SELECT_COURSE(state, action) {
    return {
      ...state,
      activeCourse: action.position
    }
  },
  ERROR_LOADING_COURSES(state, action) {
    return {
      ...state,
      loadingSuccess: false,
      isLoading: false
    }
  }
}

const pointsListHandler = {
  LOADING_JOURNAL_DATA(state, action) {
    return {
      ...state,
      isLoading: true,
      activeCourseID: action.activeCourseID
    }
  },
  GOT_JOURNAL_DATA(state, action) {
    return {
      ...state,
      isLoading: false,
      loadingSuccess: true,
      points: action.points,
      journalHeader: action.header
    }
  },
  ERROR_LOADING_JOURNAL_DATA(state, action) {
    return {
      ...state,
      isLoading: false,
      loadingSuccess: false
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
  course: makeReducer(courseListHandler),
  journal: makeReducer(pointsListHandler)
})
