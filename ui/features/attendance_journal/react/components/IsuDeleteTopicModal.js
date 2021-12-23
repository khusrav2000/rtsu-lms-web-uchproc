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
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import I18n from 'i18n!account_course_user_search'
import {Button} from '@instructure/ui-buttons'
import React from 'react'
import update from 'immutability-helper'
import axios from 'axios'
import {func, number} from 'prop-types'
import JournalActions from '../actions/JournalActions'

export default class IsuDeleteTopicModal extends React.Component {
  static propTypes = {
    id: number.isRequired,
    afterDelete: func.isRequired
  }

  constructor(props) {
    super(props)
    this.state = {
      show: false,
      close: false
    }
  }

  close = () => {
    console.log('CLOSE')
    this.setState({open: false})
  }

  open = () => {
    console.log('OPEN')
    this.setState({open: true})
  }

  /*topicAttendanceIsEmpty(journal) {
    console.log('index ', this.props.index)
    let res = true
    journal.map((item, i) => {
      if (item.cposes[this.props.index] != ' ' && item.cposes[this.props.index] != '') res = false
    })
    return res
  }*/

  onSubmit = () => {
    //if (this.topicAttendanceIsEmpty(this.props.store.getState().journal.attendance.body)) {
      axios({
        url: `/api/v1/isutema/${this.props.id}`,
        method: 'DELETE'
      })
        .then(response => {
          console.log('Reeeesss', response)
          $.flashMessage(I18n.t('Topic delete successfully'))
          this.setState({open: false}, function() {
            // const cnzap = this.props.store.getState().journal.topicCnzap - 1
            // this.props.store.dispatch(JournalActions.setTopicCnzap(cnzap))
            this.close
            this.props.afterDelete(this.props.index)
          })
        })
        .catch(error => {
          $.flashError(I18n.t("Can't delete topic"))
        })
    /*} else {
      $.flashError(I18n.t('Topic attendance not empty!'))
      this.close
    }*/
  }

  render() {
    return (
      <span>
        <Modal
          label={`${I18n.t('Please confirm deletion')} `}
          onDismiss={this.close}
          open={this.state.open}
          size="large"
        >
          <Modal.Body></Modal.Body>
          <Modal.Footer>
            <Button onClick={this.close}>{I18n.t('Cancel')}</Button> &nbsp;
            <Button onClick={this.onSubmit} variant="primary">
              {I18n.t('Confirm')}
            </Button>
          </Modal.Footer>
        </Modal>
        {React.Children.map(this.props.children, child =>
          // when you click whatever is the child element to this, open the modal
          React.cloneElement(child, {
            onClick: (...args) => {
              if (child.props.onClick) child.props.onClick(...args)
              this.setState({open: true})
            }
          })
        )}
      </span>
    )
  }
}
