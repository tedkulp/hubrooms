$ ->
  $('#create-channel').on 'submit', (e) ->
    e.preventDefault()
    e.stopPropagation()

    name = $('#channel-name').val()
    if !name? or name == '' or !name.match(/^[^\/]+\/[^\/]+$/)
      alert 'Please enter a valid repository name in the format of "user/repo".'
    else
      window.location.href = "/#{name}"
