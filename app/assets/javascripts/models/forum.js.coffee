Twitarr.ForumMeta = Ember.Object.extend
  id: null
  subject: null
  posts: null
  timestamp: null

Twitarr.ForumMeta.reopenClass
  list: ->
    $.getJSON('forums').then (data) =>
      Ember.A(@create(meta)) for meta in data.forum_meta

Twitarr.Forum = Ember.Object.extend
  id: null
  subject: null
  posts: []
  timestamp: null

  objectize: (->
    @set('posts', Ember.A(Twitarr.ForumPost.create(post)) for post in @get('posts'))
  ).on('init')

Twitarr.Forum.reopenClass
  get: (id) ->
    $.getJSON("forums/#{id}").then (data) =>
      @create(data.forum)

  new_post: (forum_id, text, photos) ->
    $.post('forums/new_post', { forum_id: forum_id, text: text, photos: photos }).then (data) =>
      data.forum_post = Twitarr.ForumPost.create(data.forum_post) if data.forum_post?
      data

  new_forum: (subject, text, photos) ->
    $.post('forums', { subject: subject, text: text, photos: photos }).then (data) =>
      data.forum_meta = Twitarr.ForumMeta.create(data.forum_meta) if data.forum_meta?
      data

Twitarr.ForumPost = Ember.Object.extend
  photos: []

  objectize: (->
    @set('photos', Ember.A(Twitarr.Photo.create(photo) for photo in @get('photos')))
  ).on('init')
