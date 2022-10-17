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

import I18n from 'i18n!AccounntsTray'
import React from 'react'
import {bool, arrayOf, shape, string} from 'prop-types'
import {View} from '@instructure/ui-layout'
import {Heading, List, Spinner} from '@instructure/ui-elements'
import {Link} from '@instructure/ui-link'

export default function JournalsTray({journals, hasLoaded}) {
  return (
    <View as="div" padding="medium">
      <Heading level="h3" as="h2">
        {I18n.t('Journals')}
      </Heading>
      <hr role="presentation" />
      <List variant="unstyled" margin="small 0" itemSpacing="small">
        {hasLoaded ? (
          journals
            .map(journal => (
              <List.Item key={journal.html_url}>
                <Link isWithinText={false} href={`${journal.html_url}`}>
                  {journal.name}
                </Link>
              </List.Item>
            ))
            .concat([
              <List.Item key="hr">
                <hr role="presentation" />
              </List.Item>,
              <List.Item key="all">
                <Link isWithinText={false} href="/journals">
                  {I18n.t('All Journals')}
                </Link>
              </List.Item>
            ])
        ) : (
          <List.Item>
            <Spinner size="small" renderTitle={I18n.t('Loading')} />
          </List.Item>
        )}
      </List>
    </View>
  )
}

JournalsTray.propTypes = {
  journals: arrayOf(
    shape({
      html_url: string.isRequired,
      name: string.isRequired
    })
  ).isRequired,
  hasLoaded: bool.isRequired
}

JournalsTray.defaultProps = {
  journals: []
}
