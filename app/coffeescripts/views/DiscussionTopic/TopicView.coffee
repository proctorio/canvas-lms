define [
  'i18n!discussions'
  'jquery'
  'Backbone'
  'underscore'
  'compiled/models/DiscussionTopic'
  'compiled/views/DiscussionTopic/EntriesView'
  'compiled/views/DiscussionTopic/EntryView'
  'jst/discussions/_reply_form'
  'compiled/discussions/Reply'
  'compiled/widget/assignmentRubricDialog'
  'compiled/util/wikiSidebarWithMultipleEditors'
  'jquery.instructure_misc_helpers' #scrollSidebar
  'str/htmlEscape'
], (I18n, $, Backbone, _, DiscussionTopic, EntriesView, EntryView, replyTemplate, Reply, assignmentRubricDialog, htmlEscape) ->

  class TopicView extends Backbone.View

    events:
      ##
      # Only catch events for the top level "add reply" form,
      # EntriesView handles the clicks for the other replies
      'click #discussion_topic .discussion-reply-form [data-event]': 'handleEvent'
      'click .add_root_reply': 'addRootReply'
      'click .discussion_locked_toggler': 'toggleLocked'
      'click .toggle_due_dates': 'toggleDueDates'

    els:
      '.add_root_reply': '$addRootReply'
      '#discussion_topic': '$topic'
      '.due_date_wrapper': '$dueDates'

    initialize: ->
      @model.set 'id', ENV.DISCUSSION.TOPIC.ID
      # overwrite cid so Reply::getModelAttributes gets the right "go to parent" link
      @model.cid = 'main'
      @model.set 'canAttach', ENV.DISCUSSION.PERMISSIONS.CAN_ATTACH
      @filterModel = @options.filterModel
      @filterModel.on 'change', @hideIfFiltering

    hideIfFiltering: =>
      if @filterModel.hasFilter()
        @$topic.addClass 'hidden'
      else
        @$topic.removeClass 'hidden'

    afterRender: ->
      super
      $.scrollSidebar() if $(document.body).is('.with-right-side')
      assignmentRubricDialog.initTriggers()
      @$el.toggleClass 'side_comment_discussion', !ENV.DISCUSSION.THREADED

    filter: @::afterRender

    toggleLocked: (event) ->
      # this is weird but Topic.coffee was not set up to talk to the API for CRUD
      locked = $(event.currentTarget).data('mark-locked')
      topic = new DiscussionTopic(id: ENV.DISCUSSION.TOPIC.ID)
      # get rid of the /view on /api/vl/courses/x/discusison_topics/x/view
      topic.url = ENV.DISCUSSION.ROOT_URL.replace /\/view/m, ''
      topic.save({locked: locked}).done -> window.location.reload()

    toggleDueDates: (event) ->
      event.preventDefault()
      @$dueDates.toggleClass('hidden')
      $(event.currentTarget).text if @$dueDates.hasClass('hidden')
        I18n.t('show_due_dates', 'Show Due Dates')
      else
        I18n.t('hide_due_dates', 'Hide Due Dates')

    ##
    # Adds a root level reply to the main topic
    #
    # @api private
    addReply: (event) ->
      event?.preventDefault()
      unless @reply?
        @reply = new Reply this, topLevel: true, focus: true
        @reply.on 'edit', => @$addRootReply?.hide()
        @reply.on 'hide', => @$addRootReply?.show()
        @reply.on 'save', (entry) => @trigger 'addReply', entry
      @model.set 'notification', ''
      @reply.edit()

    addReplyAttachment: EntryView::addReplyAttachment

    removeReplyAttachment: EntryView::removeReplyAttachment

    ##
    # Handles events for declarative HTML. Right now only catches the reply
    # form allowing EntriesView to handle its own events
    handleEvent: (event) ->
      # get the element and the method to call
      el = $ event.currentTarget
      method = el.data 'event'
      @[method]? event, el

    render: ->
      # erb renders most of this
      if ENV.DISCUSSION.PERMISSIONS.CAN_REPLY
        html = replyTemplate @model.toJSON()
        @$('.entry_content:first').append html
      super
    format: (attr, value) ->
      if attr is 'notification'
        value
      else
        htmlEscape value

    addRootReply: (event) ->
      $el = @$ event.currentTarget
      target = $('#discussion_topic .discussion-reply-form')
      @addReply event
      $('html, body').animate scrollTop: target.offset().top - 100


