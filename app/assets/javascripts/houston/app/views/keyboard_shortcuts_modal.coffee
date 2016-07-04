class @KeyboardShortcutsModal

  constructor: ->
    @template = HandlebarsTemplates['keyboard_shortcuts']
    @shortcuts = [
        keys: ['n', 't']
        name: 'New Ticket'
      ,
        keys: ['R', 't']
        name: 'Refresh Tickets'

      ,
        keys: ['G']
        name: 'Go to...'

      ,
        keys: ['g', 'p']
        name: 'Go to Projects'
      ,
        keys: ['g', 'q']
        name: 'Go to Pull Requests'
      ,
        keys: ['g', 't', 'r']
        name: 'Go to Testing Report'
      ,
        keys: ['g', 'n', 't']
        name: 'Go to New Ticket'
      ,
        keys: ['g', 'u']
        name: 'Go to Users'

      ,
        keys: ['?']
        name: 'Keyboard shortcuts'
    ]

  show: ->
    $modal = $(@template(shortcuts: @shortcuts)).modal()
    $modal.on 'hidden', -> $modal.remove()
