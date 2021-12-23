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
import axios from 'axios'
import LoadingIndicator from  '@canvas/loading-indicator'
import JournalActions from '../actions/JournalActions'
import I18n from 'i18n!account_course_user_search'
import {Tray} from '@instructure/ui-tray'
import {IconXSolid} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {Heading, Text} from '@instructure/ui-elements'
import {Flex, View} from '@instructure/ui-layout'
import IsuAddTopicModal from './IsuAddTopicModal'
import DataGrid from 'react-data-grid'
import 'react-data-grid/dist/react-data-grid.css'
import update from 'immutability-helper'
import IsuDeleteTopicModal from './IsuDeleteTopicModal'

class IsuJournal extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      isTopicTrayOpen: false,
      activeKvdID: 0,
      journal: {
        header: [],
        body: []
      },
      activeTopic: null,
      activeTopicIndex: 0,
      topics: [],
      topicsLoading: true,
      journalLoading: true,
      attendance: {
        kvd_id: 0,
        grp_id: 0
      },
      selectedColumn: -1,
      reload: this.props.store.getState().journal.reloadTopics,
      oldNumbersLen: 100,
      columns: [],
      rows: [],
      changedPositions: null
    }

    // const xPosition = 0
    // const yPosition = 0
    // const positionIsSelect = false
    // const selectedRowPosition = -1
  }

  componentDidMount() {
    this.unsubscribe = this.props.store.subscribe(this.handleStateChange)
    if (this.props.courseID) {
      this.props.store.dispatch(JournalActions.setActiveKvdID(this.props.courseID))
    }
    document.addEventListener('keydown', event => {
      if (event.keyCode === 27) {
        this.closeTopicTray()
      }
      // do something
    })
  }

  handleStateChange = () => {
    this.closeTopicTray()
    if (
      this.state.activeKvdID !== this.props.store.getState().journal.activeKvdID &&
      !this.props.store.getState().journal.coursesLoading
    ) {
      this.setState(
        {
          activeKvdID: this.props.store.getState().journal.activeKvdID,
          journalLoading: true,
          topicsLoading: true
        },
        function() {
          // this.loadJournal(this.props.store.getState().journal.activeKvdID)
          this.loadTopics(this.props.store.getState().journal.activeKvdID)
        }
      )
    }
    console.log('reload state = ', this.state.reload)
    if (this.state.reload !== this.props.store.getState().journal.reloadTopics) {
      console.log('dromad')
      this.setState(
        {
          reload: this.props.store.getState().journal.reloadTopics,
          journalLoading: true,
          topicsLoading: true
        },
        function() {
          // this.loadJournal(this.state.activeKvdID)
          this.loadTopics(this.state.activeKvdID)
        }
      )
    }
  }

  afterUpdate = () => {
    this.setState(
      {
        journalLoading: true,
        topicsLoading: true
      },
      function() {
        this.loadTopics(this.state.activeKvdID)
        this.loadJournal(this.state.activeKvdID)
      }
    )
    this.closeTopicTray()
  }

  afterDelete = () => {
    this.setState(
      {
        journalLoading: true,
        topicsLoading: true
      },
      function() {
        this.loadTopics(this.state.activeKvdID)
        this.loadJournal(this.state.activeKvdID)
      }
    )
    this.closeTopicTray()
  }

  loadJournal(kvd) {
    const data = this.state.attendance
    data.kvd_id = kvd
    this.setState({
      attendance: data,
      changedPositions: null,
      oldNumbersLen: 100,
      columns: [],
      rows: [],
      selectedColumn: -1
    })
    // console.log("Loading journal with KvdID: " + kvd +"and GroupID: " + grp)
    axios
      .get('/api/v1/student/attendance/kvd/' + kvd)
      .then(res => {
        console.log('journal ', res.data)
        this.setState({journal: res.data, journalLoading: false})
        this.props.store.dispatch(JournalActions.setAttendance(res.data))
        this.columnDate()
      })
      .catch(err => console.error(this.props.url, err.toString()))
  }

  loadTopics(kvd) {
    axios
      .get('/api/v1/isutema/' + kvd)
      .then(res => {
        this.setState({topics: res.data.body, topicsLoading: false})
        this.loadJournal(this.props.store.getState().journal.activeKvdID)
      })
      .catch(err => console.error(this.props.url, err.toString()))
  }

  saveAttendance() {
    const data = []
    if (this.state.changedPositions) {
      this.state.changedPositions.attendance.forEach(student => {
        const arr = []
        student.data.forEach(cposis => {
          arr.push({
            topicNumber: cposis.topicNumber,
            value: cposis.value
          })
        })
        data.push({id: student.id, data: arr})
      })
    }
    if (data.length < 1) {
      $.flashError(I18n.t('Journal is not changed!'))
    } else {
      axios({
        url: '/api/v1/student/attendance/' + this.props.store.getState().journal.activeKvdID,
        method: 'PUT',
        data: {
          attendance: data
        }
      })
        .then(response => {
          // console.log(response)
          // alert("Journal Saved")
          $.flashMessage(I18n.t('Journal Saved'))
          this.setState({
            changedPositions: null
          })
        })
        .catch(error => {
          $.flashError(I18n.t('Journal not saved'))
        })
    }
  }

  openTopicTray(index) {
    console.log('Open tray')
    this.removeSelectedTopic(this.state.activeTopicIndex)
    /* this.setState({
      activeTopic: this.state.topics[index],
      activeTopicIndex: index,
      isTopicTrayOpen: true
    }) */

    this.setState(prevState => {
      const topic = prevState.topics[index]
      return update(prevState, {
        activeTopicIndex: {$set: index},
        isTopicTrayOpen: {$set: true},
        activeTopic: {$set: topic},
        columns: {
          [index + 3]: {
            name: {
              $set: (
                <div
                  className="header_date_part selected"
                  onClick={() => this.openTopicTray(index)}
                >
                  <div className="row date">
                    <text className="povorot">{topic.dtzap}</text>
                  </div>
                  <div className="row number_date">
                    <text
                      className={
                        topic.cnzap.length <= 1
                          ? 'number_date_text_edini number_date_text'
                          : topic.cnzap.length <= 2
                          ? 'number_date_text_desya number_date_text'
                          : 'number_date_text_sotny number_date_text'
                      }
                    >
                      {topic.cnzap}
                    </text>
                  </div>
                </div>
              )
            }
          }
        }
      })
    })
  }

  removeSelectedTopic(index) {
    if (!this.state.activeTopic) {
      return
    }
    this.setState(prevState => {
      const topic = prevState.topics[index]
      return update(prevState, {
        columns: {
          [index + 3]: {
            name: {
              $set: (
                <div className="header_date_part" onClick={() => this.openTopicTray(index)}>
                  <div className="row date">
                    <text className="povorot">{topic.dtzap}</text>
                  </div>
                  <div className="row number_date">
                    <text
                      className={
                        topic.cnzap.length <= 1
                          ? 'number_date_text_edini number_date_text'
                          : topic.cnzap.length <= 2
                          ? 'number_date_text_desya number_date_text'
                          : 'number_date_text_sotny number_date_text'
                      }
                    >
                      {topic.cnzap}
                    </text>
                  </div>
                </div>
              )
            }
          }
        }
      })
    })
  }

  closeTopicTray() {
    console.log('close tray')
    this.setState({isTopicTrayOpen: false})
  }

  loadTopicTray() {
    const topic = this.state.activeTopic
    console.log('topic', topic)
    let edit = ''
    let remove = ''
    // console.log('Topic: ', this.state.topics)
    // console.log('index: ', this.state.activeTopicIndex)
    if (topic) {
      const LESSON_TYPES = [
        {name: I18n.t('Lecture'), count: topic.kol_lek},
        {
          name: I18n.t('Seminar'),
          count: topic.kol_sem
        },
        {
          name: I18n.t('Practical'),
          count: topic.kol_prak
        },
        {name: I18n.t('Laboratory'), count: topic.kol_lab},
        {
          name: I18n.t('KMDRO'),
          count: topic.kol_kmd
        },
        {name: I18n.t('Total'), count: topic.kol_obsh}
      ]
      if (this.state.journal.header[this.state.activeTopicIndex]) {
        console.log('true true true!! ')
        edit = (
          <IsuAddTopicModal
            key={`topic_${topic.cnzap}`}
            fields={{
              tema: topic.tema,
              lek: topic.kol_lek,
              sem: topic.kol_sem,
              prak: topic.kol_prak,
              kmd: topic.kol_kmd,
              lab: topic.kol_lab,
              obsh: topic.kol_obsh
            }}
            type="UPDATE"
            id={topic.isu_tema_id}
            afterUpdate={this.afterUpdate}
          >
            <a className="no-hover" href="#" title={I18n.t('Edit')}>
              <i className="icon-edit standalone-icon" aria-hidden="true" />
            </a>
          </IsuAddTopicModal>
        )
        remove = (
          <IsuDeleteTopicModal
            key={`topic_${topic.cnzap}`}
            id={topic.isu_tema_id}
            afterDelete={this.afterDelete}
          >
            <a className="no-hover" href="#" title={I18n.t('Delete')}>
              <i className="icon-trash standalone-icon" aria-hidden="true" />
            </a>
          </IsuDeleteTopicModal>
        )
        console.log('omadddd!!! ')
      }
      return (
        <Tray
          open={this.state.isTopicTrayOpen}
          label={I18n.t('Topic')}
          size="small"
          placement="end"
        >
          <Button
            variant="icon"
            size="small"
            margin="small 0 0 xx-small"
            onClick={() => this.closeTopicTray()}
          >
            <IconXSolid title={I18n.t('Close')} />
          </Button>
          <View as="div" padding="small small x-large small">
            <Heading level="h3" as="h2" margin="0 0 medium 0">
              {I18n.t('Topic')}
            </Heading>

            <View className="ic-permissions_role_tray" as="div" padding="0 0 medium 0">
              <Heading as="h3">
                <Text weight="bold">{topic.tema}</Text>
              </Heading>
              {edit}
              {' '}
              {remove}
              <hr aria-hidden="true" />
              {LESSON_TYPES.map(element => (
                <span className="lesson_type">
                  <View as="div">
                    <Flex justifyItems="space-between">
                      <Flex.Item>
                        <Text weight="bold" lineHeight="fit" size="small">
                          {element.name}
                        </Text>
                      </Flex.Item>
                      <Flex.Item>
                        <Text weight="bold" lineHeight="fit" size="small">
                          {element.count}
                        </Text>
                      </Flex.Item>
                    </Flex>
                  </View>
                  <hr aria-hidden="true" />
                </span>
              ))}
            </View>
          </View>
        </Tray>
      )
    } else {
      return ''
    }
  }

  columnDate() {
    const body = this.state.journal.body
    const bodyLength = body.length
    const date = 'date'
    const column = [
      {
        key: 'number',
        name: (
          <div className="header-number-style">
            <p>№</p>
          </div>
        ),
        frozen: true,
        width: 10,
        minWidth: 30
      },
      {
        key: 'name',
        name: (
          <div className="header-fio-style">
            <p>{I18n.t('Full name')}</p>
          </div>
        ),
        resizable: true,
        frozen: true,
        minWidth: 300
      },
      {
        key: 'id',
        name: (
          <div className="header-id-style">
            <p>{I18n.t('Student ID')}</p>
          </div>
        ),
        width: 120,
        minWidth: 30
      }
    ]
    const row = []
    let currentIndex = 3
    for (let index = 1; index <= this.state.topics.length; index++) {
      const currentDate = date + index
      column[currentIndex] = {
        key: currentDate,
        name: (
          <div className="header_date_part" onClick={() => this.openTopicTray(index - 1)}>
            <div className="row date">
              <text className="povorot">{this.state.topics[index - 1].dtzap}</text>
            </div>
            <div className="row number_date">
              <text
                className={
                  this.state.topics[index - 1].cnzap.length <= 1
                    ? 'number_date_text_edini number_date_text'
                    : this.state.topics[index - 1].cnzap.length <= 2
                    ? 'number_date_text_desya number_date_text'
                    : 'number_date_text_sotny number_date_text'
                }
              >
                {this.state.topics[index - 1].cnzap}
              </text>
            </div>
          </div>
        ),
        width: 40,
        minWidth: 40
      }

      currentIndex++
    }
    for (
      let index = this.state.topics.length + 1;
      index < this.state.topics.length + 1 + this.state.oldNumbersLen;
      index++
    ) {
      const currentDate = date + index
      column[currentIndex] = {
        key: currentDate,
        name: (
          <div className="header-empty-topics">
            <text className="empty-topics"> </text>
          </div>
        ),
        width: 40,
        minWidth: 40
      }
      currentIndex++
    }

    for (let index = 0; index < bodyLength; index++) {
      row.push({
        id: <div className="id-style">{this.state.journal.body[index].kzc}</div>,
        number: <div className="number-style">{index + 1}</div>,
        name: (
          <div className="fio-style">
            <p className="fio-padding">{this.state.journal.body[index].nst}</p>
          </div>
        )
      })
      const numbersLength = this.state.topics.length
      for (let index1 = 0; index1 < numbersLength; index1++) {
        const currentDate = date + (index1 + 1)
        if (this.state.journal.header[index1]) {
          row[index][currentDate] = (
            <div className="cposis-style">
              <p className="cpo_can_change">{this.state.journal.body[index].cposes[index1]}</p>
            </div>
          )
        } else {
          row[index][currentDate] = (
            <div className="cposis-style">
              <p className="cpo_can_not_change">{this.state.journal.body[index].cposes[index1]}</p>
            </div>
          )
        }
      }
    }
    this.setState({columns: column, rows: row})
  }

  saveChanges() {
    const changes = this.state.changedPositions
    if (changes[0].attendance.length > 0 && changes[0].attendance[0].data[0].topicNumber === -1) {
      changes[0].attendance.pop()
    }
    console.log(changes)
  }

  afterTopicSave = () => {
    const reloadTopics = this.props.store.getState().journal.reloadTopics
    this.props.store.dispatch(JournalActions.reloadTopics(!reloadTopics))
    // const journal = store.getState().journal.attendance
    // journal.header = [true].concat(journa.header)
    // console.log('New Header', journal.header)
    // store.dispatch(JournalActions.setAttendance(journal))
  }

  navbarBottom() {
    return (
      <nav className="navbarr fixed-bottom-second">
        <div className="_bottom">
          <div className="navbar-button_save">
            <button
              type="button"
              onClick={this.saveAttendance.bind(this, this.state.attendance)}
              className="btn btn-primary navbar-button"
            >
              {I18n.t('Save')}
            </button>
          </div>
          <div className="navbar-arrow">
            <div />
          </div>
          <div className="navbar-notice">
            <text className="navbar-notice-text">
              {I18n.t("Don't forget to save your actions!")}
            </text>
          </div>
          <div className="navbar-button_new_topic">
            <IsuAddTopicModal
              fields={{tema: '', lek: 0, sem: 0, prak: 0, kmd: 0, lab: 0, obsh: 0}}
              type="CREATE"
              afterSave={this.afterTopicSave}
              {...this.props}
            >
              <button type="button" className="btn btn-primary add-topic-button">
                {I18n.t('New topic')}
              </button>
            </IsuAddTopicModal>
          </div>
        </div>
      </nav>
    )
  }

  nextCposy(cposy) {
    if (cposy === ' ' || cposy === '') return 'н'
    else if (cposy === 'н') return 'х'
    else if (cposy === 'х') return 'и'
    else if (cposy === 'и') return 'б'
    return ' '
  }

  onCellSelected = ({rowIdx, idx}) => {
    if (this.state.journal.header[idx - 3] === true) {
      this.positionIsSelect = true
      this.xPosition = rowIdx
      this.yPosition = idx - 3
    } else {
      this.positionIsSelect = false
    }
    if (this.state.selectedColumn !== idx - 3) {
      this.setState({selectedColumn: idx - 3})
    }
    // this.updateColumnDate()
  }

  handleKeyPressAll = event => {
    if (event.key === ' ') {
      const x = this.xPosition
      const y = this.yPosition
      const isUse = this.positionIsSelect
      if (isUse === true) {
        if (this.state.journal.header[y]) {
          this.setState(
            prevState => {
              const cposes = prevState.journal.body[x].cposes
              cposes[y] = this.nextCposy(cposes[y])
              const currentDate = 'date' + (y + 1)
              return update(prevState, {
                journal: {
                  body: {
                    [x]: {
                      cposes: {$set: cposes}
                    }
                  }
                },
                rows: {
                  [x]: {
                    [currentDate]: {
                      $set: (
                        <div className="cposis-style">
                          <p className="cpo_can_change">{cposes[y]}</p>
                        </div>
                      )
                    }
                  }
                }
              })
            },
            function() {
              this.updateJournalData(x, y)
            }
          )
        }
      }
      event.preventDefault()
    }
  }

  updateJournalData(x, y) {
    let changes = this.state.changedPositions
    let isMinusOne = false,
      isNotAviable = true
    const headerLength = this.state.journal.header.length
    let changesLength = 0
    if (changes) {
      changesLength = changes.attendance.length
    } else {
      isNotAviable = false
      isMinusOne = true
    }
    for (let index = 0; index < changesLength; index++) {
      if (x === changes.attendance[index].stroke) {
        // console.log("2-0");
        const dataXIndexLength = changes.attendance[index].data.length
        let workElseOfIf = false

        for (let index1 = 0; index1 < dataXIndexLength; index1++) {
          if (changes.attendance[index].data[index1].topicNumber === headerLength - y) {
            // console.log("2-1");
            isNotAviable = false
            changes.attendance[index].data[index1] = {
              value: this.state.journal.body[x].cposes[y],
              topicNumber: headerLength - y
            }
            workElseOfIf = true
            break
          }
        }

        if (workElseOfIf === true) {
          break
        }
        // console.log("2-2");
        isNotAviable = false
        changes.attendance[index].data.push({
          value: this.state.journal.body[x].cposes[y],
          topicNumber: headerLength - y
        })
        workElseOfIf = true
        break
      }
    }
    if (isMinusOne === true) {
      // console.log(1);
      changes = {
        attendance: [
          {
            id: this.state.journal.body[x].isu_std_attendance_id,
            stroke: x,
            data: [
              {
                value: this.state.journal.body[x].cposes[y],
                topicNumber: headerLength - y
              }
            ]
          }
        ]
      }
    } else if (isNotAviable === true) {
      // console.log(3);
      changes.attendance.push({
        id: this.state.journal.body[x].isu_std_attendance_id,
        stroke: x,
        data: [
          {
            value: this.state.journal.body[x].cposes[y],
            topicNumber: headerLength - y
          }
        ]
      })
    }

    this.setState({changedPositions: changes})
  }

  render() {
    console.log('render! ')
    if (this.state.journalLoading || this.state.topicsLoading) return <LoadingIndicator />
    if (this.state.journal.body.length === 0) return <h2>Journal is empty!</h2>

    return (
      <div className="width-100">
        <div>
          <div
            className="journal-data-grid"
            onKeyDown={e => {
              this.handleKeyPressAll(e)
            }}
            tabIndex="0"
          >
            <DataGrid
              ref={node => (this.grid = node)}
              columns={this.state.columns}
              rows={this.state.rows}
              rowKey="id"
              headerRowHeight={110}
              rowHeight={35}
              onSelectedCellChange={this.onCellSelected}
            />
          </div>
          <div className="bottom">{this.navbarBottom()}</div>
        </div>
        <div id="addTopicModal" />
        {this.loadTopicTray()}
      </div>
    )
  }
}
export default IsuJournal
