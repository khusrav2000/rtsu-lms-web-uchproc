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

const mainFilterListHandles = {
  // eslint-disable-next-line no-unused-vars
  LOADING_DATA(state, action) {
    return {
      ...state,
      isLoading: true
    }
  },
  GOT_DATA(state, action) {
    return {
      ...state,
      data: action.data,
      isLoading: false
    }
  },
  SELECT_FACULTY(state, action) {
    return {
      ...state,
      activeFaculty: action.position,
      activeSpecialty: 0,
      activeKurs: 0,
      activeGroup: 0
    }
  },
  SELECT_SPECIALTY(state, action) {
    return {
      ...state,
      activeSpecialty: action.position,
      activeKurs: 0,
      activeGroup: 0
    }
  },
  SELECT_KURS(state, action) {
    return {
      ...state,
      activeKurs: action.position,
      activeGroup: 0
    }
  },
  SELECT_GROUP(state, action) {
    return {
      ...state,
      activeGroup: action.position
    }
  }
}
export default mainFilterListHandles
