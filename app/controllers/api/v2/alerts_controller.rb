class API::V2::AlertsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_filter :login_required


  def login_required
    head :unauthorized unless logged_in? || valid_key?(params[:key])
  end

  def index
    tweet_mentions = StreamPost.view_mentions(query: current_username,
                                              mentions_only: true).map {|p| p.decorate.to_hash }
    forum_mentions = Forum.view_mentions(query: current_username,
                                              mentions_only: true).map {|p| p.decorate.to_meta_hash }
    announcements = Announcement.valid_announcements.map { |x| x.decorate.to_hash }
    unread_seamail = current_user.seamails(unread: true).map{|m| m.decorate.to_meta_hash }

    unless params[:no_reset]
      current_user.reset_last_viewed_alerts
      current_user.save!
    end
    render_json tweet_mentions: tweet_mentions, forum_mentions: forum_mentions,
                announcements: announcements, unread_seamail: unread_seamail
  end

  def check
    render_json status: 'ok', user: current_user.decorate.alerts_meta
  end
end
