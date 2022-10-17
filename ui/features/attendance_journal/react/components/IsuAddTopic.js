/*
 * Copyright (C) 2020 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React, {Component} from 'react'

export default class IsuAddTopicForm extends Component {
  constructor(props) {
    super(props)

    this.state = {
      show: false,
      close: false,
      fields: {lek: 0, sem: 0, prak: 0, kmdro: 0, lab: 0}
    }
  }

  handleValidation() {
    const fields = this.state.fields
    const errors = {}
    let formIsValid = true
    if (fields.lek + fields.sem + fields.prak + fields.kmdro + fields.lab < 1) {
      formIsValid = false
    }
    this.setState({errors})
    return formIsValid
  }

  contactSubmit(e) {
    e.preventDefault()

    if (this.handleValidation()) {
      alert('Тема успешно добавлена!')
      this.setState({show: false})
    } else {
      alert('Сумма часов должно быть больше 0.')
    }
  }

  handleChange(field, e) {
    const fields = this.state.fields
    fields[field] = e.target.value
    this.setState({fields})
  }

  render() {
    return (
      <div>
        <Button variant="primary" onClick={() => this.setState({show: true})}>
          {' '}
          Новая тема{' '}
        </Button>
        <Modal show={this.state.show} animation size="lg" className="" shadow-lg border>
          <Modal.Header className="bg-success text-white text-center py-1">
            <Modal.Title className="text-center">
              <h5>Добавление новой темы</h5>
            </Modal.Title>
          </Modal.Header>
          <Modal.Body className="py-0 px-5 border">
            <div>
              <form id="topic-form" className="fluid" onSubmit={this.contactSubmit.bind(this)}>
                <div className="form-group">
                  <label htmlFor="recipient-name" className="col-form-label">
                    Название темы:
                  </label>
                  <input
                    type="text"
                    className="form-control "
                    id="recipient-name"
                    onChange={this.handleChange.bind(this, 'name')}
                    value={this.state.fields.name}
                    required
                  />
                </div>
                <div className="form-group">
                  <table className="table table-sm table-hover table-bordered">
                    <thead>
                      <tr>
                        <th scope="col">Лек </th>
                        <th scope="col">Сем </th>
                        <th scope="col">Амал </th>
                        <th scope="col">Лаб </th>
                        <th scope="col">кмдро</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr>
                        <td>
                          <input
                            type="number"
                            onChange={this.handleChange.bind(this, 'lek')}
                            value={this.state.fields.lek}
                            id="quantity"
                            name="quantity"
                            min="0"
                            max="8"
                            height="25px"
                            className="m-0 p-1 w-100"
                            max="8"
                            defaultValue="0"
                          />
                        </td>
                        <td>
                          <input
                            type="number"
                            onChange={this.handleChange.bind(this, 'sem')}
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
                            onChange={this.handleChange.bind(this, 'prak')}
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
                            onChange={this.handleChange.bind(this, 'lab')}
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
                            onChange={this.handleChange.bind(this, 'kmdro')}
                            value={this.state.fields.kmdro}
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
          <Modal.Footer className="py-1 d-flex justify-content-center">
            <Button variant="outline-secondary" onClick={() => this.setState({show: false})}>
              Отмена
            </Button>
            <button type="submit" form="topic-form" className="btn btn-outline-success">
              Cохранить
            </button>
          </Modal.Footer>
        </Modal>
      </div>
    )
  }
}
