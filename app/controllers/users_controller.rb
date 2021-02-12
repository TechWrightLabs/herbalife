class UsersController < ApplicationController
  def create
    user = User.new first_name: params[:user][:name].split(' ').first, last_name: params[:user][:name].split(' ').last, partner: params[:user][:partner], agreed_to_terms: params[:user][:agreed_to_terms]

    if user.save
      user.generate_certificate

      redirect_to thanks_path(id: user.id)
    else
      redirect_to root_path, alert: 'Agree to the Terms before submitting!'
    end
  end
end