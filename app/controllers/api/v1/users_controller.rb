class Api::V1::UsersController < Api::V1::OauthBasedApiController

  # include OSU::Roar
  

  # doorkeeper_for :all

  # resource_description do
  #   api_versions "v1"
  #   short_description 'TBD'
  #   description <<-EOS
  #     TBD
  #   EOS
  # end
# debugger
#{json_schema(Api::V1::UserRepresenter, include: :readable) if false}        
  api :GET, '/users/:id', 'Gets the specified User'
  description <<-EOS
    
  EOS
  def show
    debugger
    head :ok
    # debugger
    # rest_get(User, params[:id])
  end

  def search

  end


end