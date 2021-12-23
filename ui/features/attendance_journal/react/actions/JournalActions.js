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

export default {
  setActiveGrpID(id) {
    return {
      type: 'SET_ACTIVE_GRP_ID',
      activeGrpID: id
    }
  },
  setActiveKvdID(id) {
    return {
      type: 'SET_ACTIVE_KVD_ID',
      activeKvdID: id
    }
  },
  setTopicsKol(kol) {
    return {
      type: 'SET_TOPICS_KOL',
      topicsKol: kol
    }
  },
  setCoursesLoading(h) {
    return {
      type: 'SET_COURSES_LOADING',
      coursesLoading: h
    }
  },
  setTopicCnzap(cnzap) {
    return {
      type: 'SET_TOPIC_CNZAP',
      topicCnzap: cnzap
    }
  },
  setAttendance(data) {
    return {
      type: 'SET_ATTENDANCE',
      attendance: data
    }
  },
  setActiveTopic(num) {
    return {
      type: 'SET_ACTIVE_TOPIC',
      activeTopic: num
    }
  },
  reloadTopics(data) {
    return {
      type: 'RELOAD_TOPICS',
      reloadTopics: data
    }
  }
}
