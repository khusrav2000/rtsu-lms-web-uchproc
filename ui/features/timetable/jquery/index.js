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
import $ from 'jquery'
import '../jquery-ui/min'
import axios from 'axios'
import I18n from 'i18n!account_course_user_search'

// const axios = require('axios')

let filterData = []
let saved = true
let group_id = 0

$(document).ready(function() {
  let current_event

  getFilterData()

  $('#fak').change(function() {
    const index = $(this).prop('selectedIndex')
    let options = ''
    filterData[index].specialties.map(element => {
      options += "<option value=''>" + element.code + '</option>'
    })
    $('#spec').html(options)
    $('#spec').change()
  })

  $('#spec').change(function() {
    const spec_index = $(this).prop('selectedIndex')
    const fak_index = $('#fak').prop('selectedIndex')
    console.log(fak_index)
    let options = ''
    filterData[fak_index].specialties[spec_index].kurses.map(element => {
      options += "<option value=''>" + element.code + '</option>'
    })
    $('#cours').html(options)
    $('#cours').change()
  })

  $('#cours').change(function() {
    const cours_index = $(this).prop('selectedIndex')
    const fak_index = $('#fak').prop('selectedIndex')
    const spec_index = $('#spec').prop('selectedIndex')
    console.log(fak_index, spec_index, cours_index)
    let options = ''
    filterData[fak_index].specialties[spec_index].kurses[cours_index].groups.map(element => {
      options += "<option value=''>" + element.code + '</option>'
    })
    $('#group').html(options)
  })

  async function getTimetable() {
    const fak_index = $('#fak').prop('selectedIndex')
    const spec_index = $('#spec').prop('selectedIndex')
    const cours_index = $('#cours').prop('selectedIndex')
    const group_index = $('#group').prop('selectedIndex')
    group_id =
      filterData[fak_index].specialties[spec_index].kurses[cours_index].groups[group_index].id
    if (group_id) {
      let res
      let events = ''
      axios
        .get('/api/v1/timetable/' + group_id)
        .then(function(response) {
          console.log(response)
          console.log('group_id: ' + group_id)
          const courses = response.data.courses
          const timetable = response.data.timetable
          $.map(timetable, function(day, i) {
            $.map(day, function(item, j) {
              $('#day' + (i + 1))
                .children()
                .eq(item.time - 1)
                .html(
                  `<div
                       timetable_id =    "${item.timetable_id}"
                       data-teachers = '` +
                    JSON.stringify(item.teachers) +
                    `'
                       teacher_id =       "${item.teachers[0].teacher_id}"
                       course_name =     "${item.course_name}"
                       class_type =      "${item.class_type}"
                       classroom_number= "${item.classroom_number}"
                       course_id=        "${item.course_id}"
                       class=\'task task--primary\'> <strong>
                      ${item.course_name}
                      </strong> [<i>
                      ${item.teachers[0].teacher_name}
                      </i>]
                    </div>`
                )
            })
          })

          $.map(courses, function(item, i) {
            for (var i = 0; i < item.credit_number - item.in_timetable; i++) {
              if (!item.class_type) {
                item.class_type = 0
              }
              if (!item.classroom_number) {
                item.classroom_number = 0
              }
              events +=
                `<div
                   timetable_id=0
                   data-teachers = '` +
                JSON.stringify(item.teachers) +
                `'
                   teacher_id = "${item.teachers[0].teacher_id}"
                   course_name= "${item.course_name}"
                   class_type=  0
                   classroom_number= " "
                   course_id= ${item.course_id}
                   class=\'task task--primary\'> <strong>
                  ${item.course_name}
                  </strong> [<i>
                   ${item.teachers[0].teacher_name}
                  </i>] </div>`
            }
          })
          $('#events').html(events)

          $('.task').dblclick(function() {
            // console.log($(this).attr('lesson_type'))
            // console.log($(this).attr('data'))
            current_event = $(this)
            let options = ''
            $(this)
              .data('teachers')
              .map(item => {
                options += `<option value="${item.teacher_id}">` + item.teacher_name + '</option>'
              })
            // console.log($(this).data('teachers'))
            // console.log($(this).data('teachers')[0])
            $('#dialog-teachers').html(options)
            $(`#dialog-teachers option[value="${$(this).attr('teacher_id')}"]`).attr(
              'selected',
              true
            )
            $('#dialog-course-name').val($(this).attr('course_name'))
            $('#dialog-select').val($(this).attr('class_type'))
            $('#dialog-classroom-number').val($(this).attr('classroom_number'))
            $('#dialog').dialog({
              width: 500,
              modal: true,
              resizable: false
            })
            return false
          })
        })
        .catch(function(error) {
          // handle error
          console.log(error)
        })
        .then(function() {
          // always executed
        })
    }
  }

  $(function() {
    $('.sortable')
      .sortable({
        connectWith: '.sortable',
        cursor: 'move',
        appendTo: 'body',
        receive(event, ui) {
          if ($(this).children().length > 1 && $(this).hasClass('event-container')) {
            $(ui.sender).sortable('cancel')
          } else {
            saved = false
          }
        }
      })
      .disableSelection()
  })

  function saveTimetable() {
    console.log('Save')
    const events = []
    for (let j = 1; j < 8; j++) {
      const obj = $('#day' + j).children()
      $.map(obj, function(item, i) {
        if ($(item).children().length > 0) {
          const event = $(item)
            .children()
            .eq(0)
          events.push({
            timetable_id: $(event).attr('timetable_id'),
            teacher_id: $(event).attr('teacher_id'),
            week_day: j,
            time: i,
            course_id: $(event).attr('course_id'),
            classroom_number: $(event).attr('classroom_number'),
            class_type: parseInt($(event).attr('class_type'))
          })
          // console.log($(event).attr('course_name') + $(event).attr('teacher_name'))
        }
      })
    }
    console.log('Events: ', events)
    if (events.length !== 0 && group_id) {
      axios
        .post('/api/v1/timetable/' + group_id, {
          data: events
        })
        .then(function(response) {
          console.log(response.data)
          $.flashMessage(I18n.t('Timetable saved'))
          saved = true
          eraseTimetable()
          getTimetable()
        })
        .catch(function(error) {
          $.flashError(I18n.t('Timetable not saved'))
          console.log(error)
        })
    }
  }

  async function getFilterData() {
    axios
      .get('/api/v1/uchproc/all/faculties/specialties/kurs/groups')
      .then(function(response) {
        // handle success
        filterData = response.data.faculties
        let options = ''
        filterData.map(element => {
          options += "<option value=''>" + element.code + '</option>'
        })
        $('#fak').html(options)
        $('#fak').change()
        $('#filter-button').removeAttr('disabled')
        console.log(response)
      })
      .catch(function(error) {
        // handle error
        console.log(error)
      })
      .then(function() {
        // always executed
      })
  }

  // Errase timetable fields
  function eraseTimetable() {
    $('.event-container').html('')
    $('#events').html('')
  }
  // Actions with unsaved data
  function confirmSave() {
    $('#save-confirm-dialog').dialog({
      width: 400,
      modal: true,
      resizable: false
    })
    $('#save-confirm-dialog').dialog('open')
  }

  $('#btnCancel').click(function() {
    $('#dialog').dialog('close')
  })

  $('#btnSubmit').click(function() {
    console.log(current_event.attr('course_name'))
    current_event.attr('class_type', $('#dialog-select').prop('selectedIndex'))
    current_event.attr('teacher_name', $('#dialog-teachers option:selected').text())
    current_event.attr('teacher_id', $('#dialog-teachers').val())
    current_event.attr('classroom_number', $('#dialog-classroom-number').val())
    saved = false
    $('#dialog').dialog('close')
  })

  $('#filter-button').click(function() {
    if (saved) {
      eraseTimetable()
      getTimetable()
    } else {
      confirmSave()
    }
  })
  $('#btnSave').click(function() {
    if (!saved) {
      saveTimetable()
    } else {
      $.flashError(I18n.t('No changes in timetable'))
    }
  })
  // Confirm modal buttons
  $('#btn-no-save').click(function() {
    eraseTimetable()
    getTimetable()
    saved = true
    $('#save-confirm-dialog').dialog('close')
  })

  $('#btn-confirm-save').click(function() {
    saveTimetable()
    $('#save-confirm-dialog').dialog('close')
  })
})
