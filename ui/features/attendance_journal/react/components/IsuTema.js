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
import I18n from 'i18n!account_course_user_search'
import LoadingIndicator from  '@canvas/loading-indicator'
import IsuAddTopicModal from './IsuAddTopicModal'
import JournalActions from '../actions/JournalActions.js'
import IsuDeleteTopicModal from './IsuDeleteTopicModal'

class IsuTema extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      refresh: false,
      activeKvdID: 0,
      topics: [],
      header: [],
      isLoading: true,
      fields: {tema: '', lek: 0, sem: 0, prak: 0, kmd: 0, lab: 0, obsh: 0},
      editingRow: -1,
      reloadTopics: this.props.store.getState().journal.reloadTopics,
      selectedTopic: 0
    }
  }

  componentDidMount() {
    this.unsubscribe = this.props.store.subscribe(this.handleStateChange)
  }

  handleStateChange = () => {
    //  console.log(this.state.activeKvdID, this.props.store.getState().journal.activeKvdID)
    if (
      this.state.activeKvdID !== this.props.store.getState().journal.activeKvdID &&
      !this.props.store.getState().journal.coursesLoading
    ) {
      this.setState(
        {activeKvdID: this.props.store.getState().journal.activeKvdID, isLoading: true},
        function() {
          this.loadTopics(this.props.store.getState().journal.activeKvdID)
        }
      )
    }
    if (this.state.reloadTopics != this.props.store.getState().journal.reloadTopics) {
      this.setState(
        {reloadTopics: this.props.store.getState().journal.reloadTopics, isLoading: true},
        function() {
          this.loadTopics(this.state.activeKvdID)
        }
      )
    }
  }

  loadTopics(kvd) {
    // console.log("Loading Topics with KvdID: "+ kvd)
    axios
      .get('/api/v1/isutema/' + kvd)
      .then(res => {
        if (res.data.body.length > 0) {
          this.setState({topics: res.data.body, isLoading: false, header: res.data.header})
          const cnzap = parseInt(this.state.topics[0].cnzap) + 1
          // console.log("Cnzap: " + cnzap)
          this.props.store.dispatch(JournalActions.setTopicCnzap(cnzap))
          // console.log("Topics downloaded successful", this.state.topics)
          // console.log("-----Topics header----", this.state.header)
        } else {
          this.setState({topics: [], isLoading: false})
          this.props.store.dispatch(JournalActions.setTopicCnzap(1))
        }
      })
      .catch(err => console.error(this.props.url, err.toString()))
  }

  afterDelete = index => {
    // console.log('NewIndex ',newIndex)
    const newTopics = this.state.topics
    newTopics.splice(index, 1)
    const newHeader = this.state.header
    newHeader.splice(index, 1)
    const journal = this.props.store.getState().journal.attendance
    journal.header = newHeader
    this.setState(
      {
        header: newHeader,
        topics: newTopics,
        refresh: !this.state.refresh,
        editingRow: -1
      },
      function() {
        this.props.store.dispatch(JournalActions.setAttendance(journal))
      }
    )
  }

  afterUpdate = () => {
    this.setState(
      {
        isLoadnig: true
      },
      function() {
        this.loadTopics(this.state.activeKvdID)
      }
    )
  }

  topicClick(num) {
    this.props.store.dispatch(JournalActions.setActiveTopic(num))
    this.setState({
      selectedTopic: num
    })
  }

  fillrow(item, index) {
    const res = []
    res.push(<div className="col other">{item.cnzap}</div>)
    res.push(<div className="col data">{item.dtzap}</div>)
    res.push(
      <div className="col tema">
        {' '}
        <span className="tema-text" title={item.tema}>
          {item.tema}
        </span>
      </div>
    )
    res.push(<div className="col other">{item.kol_lek}</div>)
    res.push(<div className="col other">{item.kol_sem}</div>)
    res.push(<div className="col other">{item.kol_prak}</div>)
    res.push(<div className="col other">{item.kol_lab}</div>)
    res.push(<div className="col other">{item.kol_kmd}</div>)
    res.push(<div className="col other">{item.kol_obsh}</div>)
    if (this.state.header[index]) {
      res.push(
        <div className="col actions">
          <IsuAddTopicModal
            fields={{
              tema: item.tema,
              lek: item.kol_lek,
              sem: item.kol_sem,
              prak: item.kol_prak,
              kmd: item.kol_kmd,
              lab: item.kol_lab,
              obsh: item.kol_obsh
            }}
            type="UPDATE"
            id={item.isu_tema_id}
            afterUpdate={this.afterUpdate}
          >
            <a className="no-hover" href="#" title="Edit topic">
              <i className="icon-edit standalone-icon" aria-hidden="true" />
            </a>
          </IsuAddTopicModal>
          <IsuDeleteTopicModal
            id={item.isu_tema_id}
            afterDelete={this.afterDelete}
            index={index}
            store={this.props.store}
          >
            <a href="#" className="delete_term_link no-hover" title="Удалить тему">
              <i className="icon-trash standalone-icon" aria-hidden="true" />
            </a>
          </IsuDeleteTopicModal>
        </div>
      )
    } else {
      res.push(<div className="col actions" />)
    }
    return res
  }

  render() {
    if (this.state.isLoading) return <LoadingIndicator />
    if (this.state.topics.length == 0) {
      return <h2>{I18n.t('Topic empty')}</h2>
    }
    return (
      <div className="container">
        <div className="row header">
          <div className="col other">№</div>
          <div className="col data">{I18n.t('Date')}</div>
          <div className="col tema">{I18n.t('Topic')}</div>
          <div className="col other">{I18n.t('lek')}</div>
          <div className="col other">{I18n.t('sem')}</div>
          <div className="col other">{I18n.t('prak')}</div>
          <div className="col other">{I18n.t('lab')}</div>
          <div className="col other">{I18n.t('kmd')}</div>
          <div className="col other">{I18n.t('mu')}</div>
          <div className="col actions">{I18n.t('Actions')}</div>
        </div>
        <div className="body p-0">
          {this.state.topics.map((item, i) => {
            return (
              <div
                className={i == this.selectedTopic ? 'row selectedTopic' : 'row'}
                onClick={this.topicClick.bind(this, i)}
              >
                {this.fillrow(item, i)}
              </div>
            )
          })}
        </div>
      </div>
    )
  }
}

export default IsuTema
