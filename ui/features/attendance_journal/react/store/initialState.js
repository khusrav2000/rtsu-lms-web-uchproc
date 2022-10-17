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
import mainFilterInitialState from '@canvas/uchproc-main-filter/react/store/UchprocMainFilterInitialState'

export default {
  header: mainFilterInitialState,
  activeKvdID: 0,
  activeGrpID: 0,
  topicsKol: 0,
  coursesLoading: false,
  topicKvd: 0,
  journalKvd: 0,
  topicCnzap: 0,
  attendance: {
    header: [],
    body: []
  },
  reloadTopics: false,
  activeTopic: 0
}
