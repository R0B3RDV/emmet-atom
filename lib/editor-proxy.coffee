{Point} = require 'atom'
emmet = require '../vendor/emmet-core'
utils = emmet.require("utils")
tabStops = emmet.require("tabStops")

module.exports =
  setupContext: (@editorView) ->
    @indentation = @editorView.getEditor().getTabText()
    emmet.require("resources").setVariable("indentation", @indentation)
    @syntax = @getSyntax()

  # Fetches the character indexes of the selected text.
  #
  # Returns an {Object} with `start` and `end` properties.
  getSelectionRange: ->
    range = @editorView.getEditor().getSelection().getBufferRange()
    return {
      start: @editorView.getEditor().getBuffer().characterIndexForPosition(range.start),
      end: @editorView.getEditor().getBuffer().characterIndexForPosition(range.end)
    }

  # Creates a selection from the `start` to `end` character indexes.
  #
  # If `end` is ommited, this method should place a caret at the `start` index.
  #
  # start - A {Number} representing the starting character index
  # end - A {Number} representing the ending character index
  createSelection: (start, end) ->
    @editorView.getEditor().getSelection().setBufferRange
      start: @editorView.getEditor().getBuffer().positionForCharacterIndex(start)
      end: @editorView.getEditor().getBuffer().positionForCharacterIndex(end)

  # Fetches the current line's start and end indexes.
  #
  # Returns an {Object} with `start` and `end` properties
  getCurrentLineRange: ->
    row = @editorView.getEditor().getCursor().getBufferRow()
    lineLength = @editorView.lineLengthForBufferRow(row)
    index = @editorView.getEditor().getBuffer().characterIndexForPosition({row: row, column: 0})
    return {
      start: index,
      end: index + lineLength
    }

  # Returns the current caret position.
  getCaretPos: ->
    row = @editorView.getEditor().getCursor().getBufferRow()
    column = @editorView.getEditor().getCursor().getBufferColumn()
    return @editorView.getEditor().getBuffer().characterIndexForPosition( {row: row, column: column} )

  # Sets the current caret position.
  setCaretPos: (index) ->
    pos = @editorView.getEditor().getBuffer().positionForCharacterIndex(index)
    @editorView.getEditor().getSelection().clear()
    @editorView.getEditor().setCursorBufferPosition pos

  # Returns the current line.
  getCurrentLine: ->
    row = @editorView.getEditor().getCursor().getBufferRow()
    return @editorView.getEditor().lineForBufferRow(row)

  # Replace the editor's content (or part of it, if using `start` to
  # `end` index).
  #
  # If `value` contains `caret_placeholder`, the editor puts a caret into
  # this position. If you skip the `start` and `end` arguments, the whole target's
  # content is replaced with `value`.
  #
  # If you pass just the `start` argument, the `value` is placed at the `start` string
  # index of thr current content.
  #
  # If you pass both `start` and `end` arguments, the corresponding substring of
  # the current target's content is replaced with `value`.
  #
  # value - A {String} of content you want to paste
  # start - The optional start index {Number} of the editor's content
  # end - The optional end index {Number} of the editor's content
  # noIdent - An optional {Boolean} which, if `true`, does not attempt to auto indent `value`
  replaceContent: (value, start, end, noIndent) ->
    if !end?
      end = if !start? then @getContent().length else start
    start = 0 unless start?

    # # indent new value
    unless noIndent
      value = utils.padString(value, utils.getLinePaddingFromPosition(@getContent(), start))

    # find new caret position
    tabstopData = tabStops.extract(value,
      escape: (ch) ->
        return ch
    )
    value = tabstopData.text
    firstTabStop = tabstopData.tabstops[0]

    if firstTabStop
      firstTabStop.start += start
      firstTabStop.end += start
    else
      firstTabStop =
        start: value.length + start
        end: value.length + start

    range = @editorView.getEditor().getSelection().getBufferRange()
    range.start = Point.fromObject(@editorView.getEditor().getBuffer().positionForCharacterIndex(start))
    range.end = Point.fromObject(@editorView.getEditor().getBuffer().positionForCharacterIndex(end))

    @editorView.getEditor().getBuffer().change(range, value)

    range.start = Point.fromObject(@editorView.getEditor().getBuffer().positionForCharacterIndex(firstTabStop.start))
    range.end = Point.fromObject(@editorView.getEditor().getBuffer().positionForCharacterIndex(firstTabStop.end))

    @editorView.getEditor().getSelection().setBufferRange(range)

  # Returns the editor content.
  getContent: ->
    return @editorView.getEditor().getText()

  # Returns the editor's syntax mode.
  getSyntax: ->
    grammar = @editorView.getEditor().getGrammar().name
    if /^CSS/.test(grammar)
      return "css"
    else if /^SCSS/.test(grammar)
      return "scss"
    else if /^LESS/.test(grammar)
      return "less"
    else if /^XML|XSL/.test(grammar)
      return "xml"
    else if /^HTML/.test(grammar)
      return "html"
    else
      return null

  # Returns the current output profile name
  #
  # See emmet.setupProfile for more information.
  getProfileName: ->
    return @editorView.getEditor().getGrammar().name

  # Returns the currently selected text.
  getSelection: ->
    return @editorView.getEditor().getSelectedText()

  # Returns the current editor's file path
  getFilePath: ->
    # is there a better way to get this?
    return @editorView.getEditor().buffer.file.path

  prompt: (message) ->
    # does nothing. currently breaks decoding base64 URLs
