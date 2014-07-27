class ForumsController < ApplicationController

  def index
    render_json forum_meta: [{
                                   id: 1,
                                   subject: 'subject a',
                                   posts: 3,
                                   timestamp: DateTime.now
                               }, {
                                   id: 2,
                                   subject: 'subject b',
                                   posts: 5,
                                   timestamp: DateTime.now
                               }]
  end

  def show
    render_json forum: {
        id: params[:id],
        subject: 'hi',
        posts: [
            {
                id: 1,
                author: 'steve',
                text: 'some text',
                timestamp: DateTime.now
            }, {
                id: 2,
                author: 'dave',
                text: 'more text',
                timestamp: DateTime.now
            }
        ]
    }
  end

  def create
    response = { id: 123, text: params[:text], author: current_username, timestamp: DateTime.now }
    render_json forum_post: response
  end

end