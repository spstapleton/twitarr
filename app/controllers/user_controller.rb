require 'bcrypt'
require 'json'

class UserController < ApplicationController

  layout 'login'

  def login
    user = User.get params[:username]
    if user.nil?
      @error = 'User does not exist.'
      render :login_page
    elsif user.status != User::ACTIVE_STATUS || user.empty_password?
      @error = 'User account has been disabled.'
      render :login_page
    elsif !user.correct_password(params[:password])
      @error = 'Invalid username or password.'
      render :login_page
    else
      login_user(user)
      user.update_last_login.save
      redirect_to :root
    end
  end

  def login_page
  end

  def new
    new_username = params[:new_username].downcase
    @user = User.new username: new_username, display_name: new_username,
                     is_admin: false, status: User::ACTIVE_STATUS, email: params[:email],
                     security_question: params[:security_question], security_answer: params[:security_answer]
    if !@user.valid?
      render :create_user
    elsif User.where(username: new_username).exists?
      @user.errors.add :username, 'already exists.'
      render :create_user
    elsif params[:new_password].length < 6
      @user.errors.add :password, 'must be at least six characters long.'
      render :create_user
    elsif params[:new_password] != params[:new_password2]
      @user.errors.add :password, 'does not match.'
      render :create_user
    else
      @user.set_password params[:new_password]
      @user.update_last_login.save
      login_user(@user)
      redirect_to "/#/help"
    end
  end

  def security_question
    @user = User.where(username: params[:username].downcase).first
    if @user.nil?
      @error = 'User does not exist.'
      render :forgot_password
    end
  end

  def security_answer
    @user = User.where(username: params[:username].downcase).first
    if @user.nil?
      @error = 'User does not exist.'
      render :forgot_password
    end
    if params[:security_answer].downcase.strip != @user.security_answer ||
        params[:email].strip != @user.email
      sleep 30.seconds.to_i
      @error = 'Email or security answer did not match.'
      render :security_question and return
    end
    @user.set_password User::RESET_PASSWORD
    @user.save!
    @error = 'Password has been reset to "seamonkey"'
    render :login_page
  end

  def save_profile
    return unless logged_in!

    if params[:new_password] && params[:current_password]
      unless current_user.correct_password(params[:current_password])
        render_json(status: 'Current password does not match.')
        return
      end
      current_user.set_password params[:new_password]
      puts "Changing #{current_username}'s password."
    end

    current_user.email = params[:email]
    current_user.display_name = params[:display_name]
    current_user.room_number = params[:room_number]
    current_user.real_name = params[:real_name]
    current_user.email_public = params[:email_public?]
    current_user.save
    if (current_user.invalid?)
      render_json status: current_user.errors.full_messages.join('\n')
    else
      render_json status: 'ok'
    end
  end

  def username
    if logged_in?
      if current_user.nil?
        # this is a special case - need to log the current user out
        logout_user
        return render_json status: 'User does not exist.'
      end
      return render_json status: 'User account has been disabled.' if current_user.status != User::ACTIVE_STATUS || current_user.password.nil?
      current_user.update_last_login.save
      return render_json status: 'ok',
                         user: current_user.decorate.self_hash,
                         need_password_change: current_user.correct_password(User::RESET_PASSWORD),
                         is_read_only: false
    end
    render_json status: 'logout'
  end

  def logout
    logout_user
    render_json status: 'ok'
  end

  def autocomplete
    search_string = params[:string].downcase
    render_json names:
                    User.or(
                        { username: /^#{search_string}/ },
                        { display_name: /^#{search_string}/i },
                        { '$text' => { '$search' => search_string } })
                    .map { |x| { username: x.username, display_name: x.display_name } }
  end

  def show
    show_username = User.format_username params[:username]
    render_json status: 'User does not exist.' and return unless User.exist?(show_username)
    render_json status: 'ok', user: User.get(show_username).decorate.public_hash.merge(
        {
            recent_tweets: StreamPost.where(author: show_username).desc(:timestamp).limit(10).map { |x| x.decorate.to_hash(current_username) }
        })
  end

end
