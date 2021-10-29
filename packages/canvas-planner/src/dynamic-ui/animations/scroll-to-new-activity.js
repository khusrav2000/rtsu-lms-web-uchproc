/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import Animation from '../animation'
import {loadPastUntilNewActivity} from '../../actions/loading-actions'

export class ScrollToNewActivity extends Animation {
  fixedElement() {
    return this.app().fixedElementForItemScrolling()
  }

  findNaiAboveScreen() {
    const nais = this.registry().getAllNewActivityIndicatorsSorted()
    return nais.reverse().find(indicator => {
      return this.animator().isAboveScreen(
        indicator.component.getScrollable(),
        this.manager().totalOffset()
      )
    })
  }

  uiDidUpdate() {
    const nai = this.findNaiAboveScreen()
    if (nai) {
      this.maintainViewportPositionOfFixedElement()
      this.animator().focusElement(nai.component.getFocusable())
      this.animator().scrollTo(nai.component.getScrollable(), this.manager().totalOffset())
    } else {
      this.animator().scrollToTop()
      this.store().dispatch(loadPastUntilNewActivity())
    }
  }
}