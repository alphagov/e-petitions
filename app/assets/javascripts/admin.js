import $ from 'jquery'
import rails from 'jquery-ujs'
import autoLogout from './admin/auto-logout'
import editLock from './admin/edit-lock'
import autoSave from './admin/auto-save'

import CharacterCounter from './modules/character-counter'

rails($)
autoLogout($)
editLock($)

window.jQuery = $
window.$ = $

$().ready(function() {
  $('select[data-autosubmit]')
    .change(function() {
      $(this).closest('form').submit()
    })

  $('input[data-autosubmit]')
    .change(function() {
      $(this).closest('form').submit()
    })
})

$().ready(function() {
  $('textarea[data-max-length]').each(function(index, textarea) {
    new CharacterCounter(textarea)
  })
})

$().ready(function() {
  autoSave($)
})
