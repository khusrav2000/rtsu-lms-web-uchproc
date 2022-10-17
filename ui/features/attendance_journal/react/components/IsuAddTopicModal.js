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
import axios from 'axios'
import JournalActions from '../actions/JournalActions'

export default class IsuAddTopicModal extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      show: false,
      close: false,
      errors: '',
      isLoading: false,
      fields: props.fields,
      activeSaveButton: true
    }
  }

  componentDidMount() {
    this.setState({fields: this.props.fields})
  }

  handleValidation() {
    const topic = this.state.fields
    const obsh = topic.lek + topic.sem + topic.prak + topic.kmd + topic.lab
    let errors = ''
    let formIsValid = true
    if (obsh < 1) {
      formIsValid = false
      errors = I18n.t('Nomber of topic hours must be > 0')
    }
    const mx = 5
    if (
      topic.lek < 0 ||
      topic.lek > mx ||
      topic.sem < 0 ||
      topic.sem > mx ||
      topic.prak < 0 ||
      topic.prak > mx ||
      topic.lab < 0 ||
      topic.lab > mx ||
      topic.kmd < 0 ||
      topic.kmd > mx
    ) {
      errors = I18n.t('Hours must be in interval [0-5]')
      formIsValid = false
    }
    if (typeof topic.tema !== 'undefined') {
      if (topic.tema.trim().length < 5) {
        errors = I18n.t('Name is invalid!')
        formIsValid = false
      }
    }
    this.setState({errors})
    return formIsValid
  }

  close = () => {
    this.setState({open: false})
  }

  open = () => {
    this.setState({open: true})
  }

  onSubmit = () => {
    this.setState({activeSaveButton: false})
    const fields = this.state.fields
    const obsh =
      parseInt(fields.lek) +
      parseInt(fields.sem) +
      parseInt(fields.prak) +
      parseInt(fields.kmdro) +
      parseInt(fields.lab)
    fields.obsh = obsh
    if (this.handleValidation() === true) {
      if (this.props.type === 'CREATE') {
        const requestData = this.state.fields
        // requestData.cnzap = this.props.store.getState().journal.topicCnzap
        requestData.cnzap = 0
        // console.log(this.props.store.getState().journal.activeKvdID)
        this.setState({open: false}, function() {
          axios({
            url: '/api/v1/isutema/' + this.props.store.getState().journal.activeKvdID,
            method: 'POST',
            data: {
              topic: requestData
            }
          })
            .then(response => {
              $.flashMessage(I18n.t('Topic add successfull'))
              const cnzap = this.props.store.getState().journal.topicCnzap + 1
              this.setState({open: false, isLoading: false}, function() {
                this.props.store.dispatch(JournalActions.setTopicCnzap(cnzap))
              })
              if (this.props.afterSave) this.props.afterSave()
            })
            .catch(error => {
              if (error.response) {
                $.flashError(I18n.t('Topic not created'))
              }
            })
        })
      } else {
        this.setState({open: false}, function() {
          axios({
            url: `/api/v1/isutema/${this.props.id}`,
            method: 'PUT',
            data: {
              topic: this.state.fields
            }
          })
            .then(response => {
              $.flashMessage(I18n.t('Topic updated successfully'))
              this.setState({open: false})
              this.props.afterUpdate()
            })
            .catch(error => {
              $.flashError(I18n.t('Topic not updated'))
            })
        })
      }
    } else {
      $.flashWarning(I18n.t('The form was completed incorrectly'))
    }
  }

  onChange(e, field) {
    const fields = this.state.fields
    if (field !== 'tema') fields[field] = parseInt(e.target.value)
    else fields[field] = e.target.value
    this.setState({fields})
  }

  render() {
    return (
      <span>
        <Modal
          label={this.props.type === 'CREATE' ? I18n.t('Create topic') : I18n.t('Edit topic')}
          onDismiss={this.close}
          open={this.state.open}
          size="large"
        >
          <Modal.Body>
            <div>
              <form
                id="topic-form"
                className="fluid"
                onSubmit={this.onSubmit}
                className="attendance-journal-modal"
              >
                <div className="form-group">
                  <label htmlFor="recipient-name" className="col-form-label">
                    {I18n.t('Topic name :')}
                  </label>
                  <input
                    type="text"
                    className="form-control tema-name"
                    id="recipient-name"
                    onChange={event => this.onChange(event, 'tema')}
                    value={this.state.fields.tema}
                    required
                  />
                </div>
                <div className="form-group">
                  <table className="table table-sm table-hover table-bordered">
                    <thead>
                      <tr>
                        <th scope="col">{I18n.t('Lecture')}</th>
                        <th scope="col">{I18n.t('Seminar')}</th>
                        <th scope="col">{I18n.t('Practical')}</th>
                        <th scope="col">{I18n.t('Laboratory')}</th>
                        <th scope="col">{I18n.t('KMDRO')}</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr>
                        <td>
                          <input
                            type="number"
                            className="number"
                            onChange={event => this.onChange(event, 'lek')}
                            value={this.state.fields.lek}
                            id="quantity"
                            name="quantity"
                            min="0"
                            max="8"
                            height="25px"
                            className="m-0 p-1 w-100"
                            defaultValue="0"
                          />
                        </td>
                        <td>
                          <input
                            type="number"
                            className="number"
                            onChange={event => this.onChange(event, 'sem')}
                            value={this.state.fields.sem}
                            id="quantity2"
                            name="quantity2"
                            min="0"
                            height="25px"
                            className="m-0 p-1 w-100"
                            defaultValue="0"
                            max="5"
                          />
                        </td>
                        <td>
                          <input
                            type="number"
                            className="number"
                            onChange={event => this.onChange(event, 'prak')}
                            value={this.state.fields.prak}
                            id="quantity3"
                            name="quantity3"
                            min="0"
                            height="25px"
                            className="m-0 p-1 w-100"
                            defaultValue="0"
                            max="5"
                          />
                        </td>
                        <td>
                          <input
                            type="number"
                            className="number"
                            onChange={event => this.onChange(event, 'lab')}
                            value={this.state.fields.lab}
                            id="quantity4"
                            name="quantity4"
                            min="0"
                            height="25px"
                            className="m-0 p-1 w-100"
                            defaultValue="0"
                            max="5"
                          />
                        </td>
                        <td>
                          <input
                            type="number"
                            className="number"
                            onChange={event => this.onChange(event, 'kmd')}
                            value={this.state.fields.kmd}
                            id="quantity5"
                            name="quantity5"
                            min="0"
                            height="25px"
                            className="m-0 p-1 w-100"
                            defaultValue="0"
                            max="5"
                          />
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </form>
            </div>
          </Modal.Body>
          <Modal.Footer>
            <Button onClick={this.close}>{I18n.t('Cancel')}</Button> &nbsp;
            <Button
              onClick={this.onSubmit}
              variant="primary"
              interaction={this.state.activeSaveButton ? 'enabled' : 'disabled'}
            >
              {I18n.t('Save')}
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
