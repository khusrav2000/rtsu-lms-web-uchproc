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
import {isEmpty} from 'lodash'
import Faculties from './components/Faculties'
import Specialties from './components/Specialties'
import Kurses from './components/Kurses'
import Groups from './components/Groups'
import LoadingIndicator from '@canvas/loading-indicator'
import HeaderActions from './actions/UchprocMainFilterActions'
import axios from 'axios'

export default class MainFilterIndex extends React.Component {
  componentDidMount() {
    this.unsubscribe = this.props.store.subscribe(this.handleStateChange)
    this.props.store.dispatch(HeaderActions.loadingData())
    axios.get('/api/v1/uchproc/main_filter').then(res => {
      this.props.store.dispatch(HeaderActions.gotData(res.data))
    })
  }

  constructor(props) {
    super(props)
    this.state = {
      header: props.store.getState().header
    }
  }

  handleStateChange = () => {
    this.setState({header: this.props.store.getState().header})
  }

  render() {
    const {data, isLoading} = this.state.header
    if (!isEmpty(data.faculties) && !isLoading) {
      return (
        <div className="uchproc-main-filter-grid">
          <div className="grid-item">
            <Faculties {...this.props} />
          </div>
          <div className="grid-item">
            <Specialties {...this.props} />
          </div>
          <div className="grid-item">
            <Kurses {...this.props} />
          </div>
          <div className="grid-item">
            <Groups {...this.props} />
          </div>
        </div>
      )
    } else {
      return <LoadingIndicator />
    }
  }
}
